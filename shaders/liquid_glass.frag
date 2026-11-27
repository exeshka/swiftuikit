// Liquid glass plate (iOS 26 look), pass 1 of 2 (pass 2 is an engine blur
// composed after this shader, see RenderLiquidGlass).
//
// * rim lens, fitted to native glass: pixels closer than `bezel` to the edge
//   show the content from about `bezel` deep (displaced inward along the normal,
//   smoothstep falloff), so the rim is a stretched copy of the interior;
// * per-channel dispersion at the rim;
// * tone map fitted to native glass (gray ramp + six color swatches, max error
//   ~2 levels): luminance Y' = lift + gain * Y (Rec.709), chroma * constant;
// * pixels outside the shape are shaded as their projection onto the rim, so
//   the blur that follows does not pull the surroundings into the plate.
// The specular hairline is drawn on top by the render object (cheap strokes).
#include <flutter/runtime_effect.glsl>

const int MAX_PLATES = 32;

uniform vec2 uSize;               // engine: size of the backdrop texture
uniform float uCount;             // number of plates in this pass (1..8)
uniform vec4 uRects[MAX_PLATES];  // plate rects in texture pixels: x, y, w, h
uniform vec4 uPlate[MAX_PLATES];  // radius px, bezel px, small-plate material share 0..1, px per pt
uniform float uRefraction;        // displacement multiplier (1 = native-like plateau)
uniform float uDispersion;        // 0..1, relative channel split
uniform float uMagnify;           // <1 magnifies the center slightly
uniform float uSaturation;        // chroma multiplier after the tone map
uniform float uToneLift;          // large plates: luminance of black (0..1)
uniform float uToneGain;          // large plates: luminance slope
uniform vec4 uTint;               // rgb + alpha of an extra tint
uniform float uSpecular;          // rim hairline intensity
uniform float uMorphK;            // smooth-union radius in px (0: plates stay separate)
uniform float uLightMode;         // 1: light appearance (measured on native light glass)
uniform vec4 uHi[MAX_PLATES];     // per plate: press highlight 0..1, touch offset from the plate center (pt) x, y
uniform float uHdr;               // peak of highlights in SDR-white units (1: SDR, up to 1.25 on BGR10_XR)
uniform float uBlur;              // gaussian blur sigma in texture px (0: none); done here, no extra engine pass
uniform vec4 uTints[MAX_PLATES];  // per-plate tint rgba (blended across merged plates)
uniform float uFade;              // 0..1: how much of the glass is shown (the flat plate under it shows through the rest)
uniform vec4 uMelt[MAX_PLATES];   // per plate: y = radius of the bottom corners in px (-1: same as the top ones); x = 1 when the plate melts with a neighbour it interacts with (smooth union, radius uMorphK), 0 = stays a shape of its own
uniform vec4 uCorners2[MAX_PLATES]; // per plate: x / y scale the top-left / bottom-left corner radius (0: unset = 1)
uniform sampler2D uTex;

out vec4 fragColor;

// Native glass has two materials (measured on uniform gray backdrops): plates
// with min side >= ~68 pt are a plain affine tone map (lift + gain * Y); smaller
// plates follow this adaptive curve, which flips to light glass over very
// bright content. Knots: backdrop luma -> glass luma.
const int KN = 21;
const float KX[21] = float[21](0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50,
                                0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.875, 0.89, 1.0);
const float KY[21] = float[21](0.0745, 0.0863, 0.098, 0.1176, 0.1412, 0.1647, 0.2118, 0.2471, 0.2902, 0.3294, 0.3451,
                                0.3608, 0.3725, 0.3804, 0.3882, 0.4, 0.4118, 0.4196, 0.43, 0.965, 0.992);

// Light appearance, small plates: dark glass only over very dark content, then
// light glass (measured on native).
const int LN = 13;
const float LX[13] = float[13](0.0, 0.10, 0.14, 0.16, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0);
const float LY[13] = float[13](0.0745, 0.098, 0.115, 0.65, 0.667, 0.71, 0.749, 0.8, 0.863, 0.906, 0.941, 0.973, 0.992);

float toneSmallLight(float v) {
  v = clamp(v, 0.0, 1.0);
  for (int i = 0; i < LN - 1; i++) {
    if (v <= LX[i + 1]) {
      float t = (v - LX[i]) / (LX[i + 1] - LX[i]);
      return mix(LY[i], LY[i + 1], t);
    }
  }
  return LY[LN - 1];
}

float toneSmall(float v) {
  v = clamp(v, 0.0, 1.0);
  for (int i = 0; i < KN - 1; i++) {
    if (v <= KX[i + 1]) {
      float t = (v - KX[i]) / (KX[i + 1] - KX[i]);
      return mix(KY[i], KY[i + 1], t);
    }
  }
  return KY[KN - 1];
}

// Dark glass for Y <= 0.875 (measured), continued with a gentle slope; light glass is a near-white affine map.
float toneSmallDark(float v) {
  v = clamp(v, 0.0, 1.0);
  if (v > KX[KN - 3]) return KY[KN - 3] + (v - KX[KN - 3]) * 0.4;
  return toneSmall(v);
}
float toneSmallBright(float v) { return 0.80 + 0.19 * clamp(v, 0.0, 1.0); }


vec3 grab(vec2 p, vec2 texel) {
  return texture(uTex, p * texel).rgb;
}

// A backdrop texel is usable when it is inside the texture and opaque. A plate that hangs over the edge of the screen (a page
// slid aside by a drawer, a sheet, a scrolled list) has no backdrop there: the rim samples content from ~bezel inside the plate,
// which for the part near the edge lies beyond the texture and read black (or transparent garbage) instead of the page.
bool backdropValid(vec2 p) {
  if (p.x < 0.5 || p.y < 0.5 || p.x > uSize.x - 0.5 || p.y > uSize.y - 0.5) return false;
  return texture(uTex, p / uSize).a > 0.5;
}

// Gaussian blur by 40 quasi-random taps (R2 sequence, Rayleigh radii, unit sigma); any prefix is well spread, so
// smaller blurs use fewer taps. Equivalent to blurring the backdrop and then sampling it where the lens points.
const int TAPS_N = 40;
const vec2 TAPS[40] = vec2[40](
  vec2(-1.1774, 0.0000),
  vec2(0.6944, 0.3259),
  vec2(-0.0993, -0.1195),
  vec2(0.4280, 1.6462),
  vec2(0.2221, -1.1902),
  vec2(-0.4675, 0.6503),
  vec2(0.2129, -0.1187),
  vec2(-1.7468, 0.1222),
  vec2(1.1608, 0.4488),
  vec2(-0.5766, -0.6030),
  vec2(0.1007, 0.2998),
  vec2(0.2064, -1.7925),
  vec2(-0.6722, 1.0879),
  vec2(0.7261, -0.4742),
  vec2(-0.3724, 0.0524),
  vec2(1.7788, 0.5485),
  vec2(-0.9719, -0.8838),
  vec2(0.3455, 0.8309),
  vec2(0.0192, -0.4283),
  vec2(-0.8942, 1.7027),
  vec2(1.0754, -0.8148),
  vec2(-0.9118, 0.1939),
  vec2(0.4640, 0.1083),
  vec2(-1.5629, -1.2333),
  vec2(0.6200, 1.2391),
  vec2(-0.0242, -0.9642),
  vec2(-0.2094, 0.4769),
  vec2(1.5557, -1.3597),
  vec2(-1.3676, 0.3924),
  vec2(0.9840, 0.1582),
  vec2(-0.4648, -0.3168),
  vec2(1.0947, 1.8523),
  vec2(-0.1385, -1.4545),
  vec2(-0.3469, 0.9686),
  vec2(0.4247, -0.4270),
  vec2(-2.1156, 0.7705),
  vec2(1.4945, 0.1342),
  vec2(-0.9164, -0.5349),
  vec2(0.3635, 0.5272),
  vec2(-0.3894, -2.3415)
);

// Low-frequency luma around p (24 wide taps): small plates choose dark or light glass from the area, not per pixel.
// per-pixel rotation of the tap pattern (interleaved gradient noise): turns the coherent aliasing of thin features into
// fine uncorrelated grain (a few percent of the contrast, then compressed by the tone map)
mat2 tapRot(vec2 origin) {
  // One rotation per 8x8 pixel block (hash of the block id): inside a block all pixels read nearly the same texels, so the
  // texture cache keeps working (a per-pixel angle made phone GPUs ~4x slower), while the aliasing of thin features
  // still decorrelates from block to block into a fine mosaic of grain instead of coherent dotted lines.
  // blocks are counted from the plate's (pixel-snapped) corner, not from the screen: a plate that moves over its backdrop
  // (a page sliding, a drawer) carries its grain pattern with it instead of re-rolling the dice under every pixel
  vec2 b = floor((FlutterFragCoord().xy - origin) / 8.0);
  float a = 6.2831853 * fract(52.9829189 * fract(dot(b, vec2(0.06711056, 0.00583715))));
  float c = cos(a), s = sin(a);
  return mat2(c, s, -s, c);
}

// returns (mean luma, std of luma) over 32 fixed wide taps; fixed (not rotated) taps make the estimate vary smoothly
// across the plate instead of flipping pixel by pixel
const int WIDE_N = 10;  // was 32, then 16: a low-frequency estimate does not need more (phone GPU cost)
vec2 lumaWide(vec2 p, vec2 texel, float sigmaPx) {
  float acc = 0.0;
  float acc2 = 0.0;
  float wsum = 0.0;
  for (int i = 0; i < WIDE_N; i++) {
    vec2 q = clamp(p + TAPS[i] * sigmaPx * 1.30, vec2(0.5), uSize - vec2(0.5));
    vec4 t = texture(uTex, q * texel);
    float y = dot(t.rgb, vec3(0.2126, 0.7152, 0.0722));
    acc += y;
    acc2 += y * y;
    wsum += t.a;
  }
  float w = max(wsum, 1.0);
  float m = acc / w;
  return vec2(m, sqrt(max(acc2 / w - m * m, 0.0)));
}

vec3 blurGrab(vec2 p, vec2 texel, vec2 origin) {
  if (uBlur < 0.6) return grab(p, texel);
  // tap counts were 12/24/40; the engine prefilter already takes most of the sigma, so fewer taps suffice (phone GPU cost)
  int n = uBlur < 3.0 ? 8 : (uBlur < 8.0 ? 12 : 16);
  // finite sets undersample the tail: rescale so the effective sigma matches
  float sc = n == 8 ? 1.32 : (n == 12 ? 1.26 : 1.21);
  mat2 R = tapRot(origin);
  vec3 acc = vec3(0.0);
  float wsum = 0.0;
  for (int i = 0; i < TAPS_N; i++) {
    if (i >= n) break;
    vec2 q = clamp(p + R * TAPS[i] * uBlur * sc, vec2(0.5), uSize - vec2(0.5));
    // taps that land where there is no backdrop (past the edge of the screen) count for nothing instead of darkening the mean
    vec4 t = texture(uTex, q * texel);
    acc += t.rgb;
    wsum += t.a;
  }
  return wsum > 0.001 ? acc / wsum : grab(p, texel);
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 texel = 1.0 / uSize;

  // Smooth union of all plates' signed distances (morphing: neighbours closer
  // than uMorphK melt into one shape, like GlassEffectContainer(spacing:)).
  // Params (bezel, small flag, center) come from the nearest plate.
  float best = 1e9;
  vec4 rect = uRects[0];
  vec4 plate = uPlate[0];
  float dU = 1e9;
  vec2 nU = vec2(0.0, -1.0);
  vec2 bq = vec2(0.0);
  vec2 bp = vec2(0.0);
  vec4 hiv = vec4(0.0);
  vec4 tintv = vec4(0.0);
  vec4 sumT = vec4(0.0);
  float sumW = 0.0;
  float dH = 1e9;       // hard minimum over the plates that do NOT melt (they keep their own shape)
  vec2 nH = vec2(0.0, -1.0);
  float mm = 1e9;       // smallest signed distance so far: the smooth union is accumulated relative to it
  vec2 sumN = vec2(0.0);
  for (int i = 0; i < MAX_PLATES; i++) {
    if (float(i) >= uCount) break;
    vec2 h = uRects[i].zw * 0.5;
    vec2 c = uRects[i].xy + h;
    vec2 p = pos - c;
    // far from this plate's box: it can neither cover the pixel nor visibly pull the smooth union (weight < 2e-4)
    vec2 qc = abs(p) - h;
    if (max(qc.x, qc.y) > (uMorphK > 0.5 && uMelt[i].x > 0.5 ? uMorphK * 3.0 + 2.0 : 2.0)) continue;
    // top corners use the plate's radius, the bottom ones uMelt[i].y when it is set (>= 0): a sheet has the screen's radius at its
    // bottom and its own at the top
    float rTop = min(abs(uPlate[i].x), min(h.x, h.y));
    float rBottom = uMelt[i].y >= 0.0 ? min(uMelt[i].y, min(h.x, h.y)) : rTop;
    // uMelt.z / uMelt.w scale the top-right / bottom-right corner (0: unset = 1): a morphing plate need not be symmetric
    float sTR = uMelt[i].z > 0.0 ? uMelt[i].z : 1.0;
    float sBR = uMelt[i].w > 0.0 ? uMelt[i].w : 1.0;
    float sTL = uCorners2[i].x > 0.0 ? uCorners2[i].x : 1.0;
    float sBL = uCorners2[i].y > 0.0 ? uCorners2[i].y : 1.0;
    float r = p.y > 0.0 ? (p.x > 0.0 ? rBottom * sBR : rBottom * sBL) : (p.x > 0.0 ? rTop * sTR : rTop * sTL);
    r = min(r, min(h.x, h.y));
    vec2 q = abs(p) - (h - vec2(r));
    float di;
    vec2 ni;
    if (uPlate[i].x < 0.0) {
      // circle plate dragged into an ellipse: approximate distance to the ellipse (iq) and its gradient as the normal
      vec2 ab = max(h, vec2(1.0));
      float k0 = length(p / ab);
      vec2 g = p / (ab * ab);
      float k1 = length(g);
      di = k1 > 1e-6 ? k0 * (k0 - 1.0) / k1 : -min(ab.x, ab.y);
      ni = k1 > 1e-6 ? g / k1 : vec2(0.0, -1.0);
    } else {
      di = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
      if (q.x > 0.0 || q.y > 0.0) {
        ni = normalize(sign(p) * max(q, 0.0));
      } else {
        ni = (q.x > q.y) ? vec2(sign(p.x), 0.0) : vec2(0.0, sign(p.y));
      }
    }
    if (di < best) { hiv = uHi[i]; tintv = uTints[i]; best = di; rect = uRects[i]; plate = uPlate[i]; bq = q; bp = p; }
    if (uMorphK > 0.5 && uMelt[i].x > 0.5) {
      // exponential smooth-min: weights w_i = exp(-a d_i), a = 2.77 / k. Accumulated relative to the smallest distance
      // (log-sum-exp): the weight of the nearest plate is 1 and the others are <= 1, so nothing overflows. Raw exp(-a d) is
      // exp(100+) in the middle of a plate once k is small (a morph that is fading in or out): float infinity, then 0 * inf =
      // NaN, and the interior of every plate in the group turned black for a frame or two.
      float a = 2.77 / uMorphK;
      if (di < mm) {
        float f = exp(-a * (mm - di));
        sumW *= f;
        sumT *= f;
        sumN *= f;
        mm = di;
      }
      float w = exp(-a * (di - mm));
      sumW += w;
      sumT += w * vec4(uTints[i].rgb * uTints[i].a, uTints[i].a);
      sumN += w * ni;
    } else if (di < dH) {
      dH = di; nH = ni;
    }
  }
  dU = dH;
  nU = nH;
  if (sumW > 0.0) {
    // the melting plates form one smooth shape; a plate that does not melt only wins where it is nearer than that shape
    float dM = mm - log(max(sumW, 1e-30)) * uMorphK / 2.77;
    if (dM <= dH) {
      dU = dM;
      tintv = vec4(sumT.rgb / max(sumT.a, 1e-6), sumT.a / max(sumW, 1e-30));
      nU = normalize(sumN + vec2(1e-6));
    }
  }
  vec2 half_ = rect.zw * 0.5;
  vec2 center = rect.xy + half_;
  float d = dU;
  float uBezel = plate.y;

  vec2 n = nU;

  float dRaw = d;
  // outside every plate: nothing to draw, skip the lens, the blur taps and the tone map (bars/lists group sparse plates)
  if (dRaw > 0.75) { fragColor = vec4(0.0); return; }
  // outside: project onto the rim
  vec2 pp = pos;
  if (d > 0.0) { pp = pos - n * d; d = 0.0; }

  float depth = -d;
  float t = clamp(depth / uBezel, 0.0, 1.0);
  float ss = t * t * (3.0 - 2.0 * t);

  vec2 magnified = center + (pp - center) * uMagnify;
  // Native glass shows no content from within ~bezel of the rim: the rim zone
  // is filled with the content at depth ~bezel (stretched along the normal).
  vec2 disp = -n * (uBezel * uRefraction * (1.0 - ss));

  // where the displaced sample would fall outside the backdrop (a plate over the edge of the screen), read under the pixel itself
  if (!backdropValid(magnified + disp)) disp = pp - magnified;

  float k = uDispersion;
  vec3 col;
  if (k > 0.001) {
    col.r = grab(magnified + disp * (1.0 + k), texel).r;
    col.g = grab(magnified + disp, texel).g;
    col.b = grab(magnified + disp * (1.0 - k), texel).b;
  } else {
    col = blurGrab(magnified + disp, texel, floor(rect.xy + 0.5));
  }

  float Y = dot(col, vec3(0.2126, 0.7152, 0.0722));
  // two materials (see the head of the file): plate.z is the share of the small-plate one (1 small .. 0 large), blended over a
  // range of sizes so a plate that grows does not pop from one to the other
  float Yt = uToneLift + uToneGain * Y;
  if (plate.z > 0.001) {
    float YtSmall;
    if (uLightMode > 0.5) {
      YtSmall = toneSmallLight(Y);
    } else {
      // mode (dark/light glass) from the area around the pixel (~18 pt, 24 taps; switch at 0.91..0.97: a white grid with black lines averages ~0.86 and stays dark, as in native), tone from the local luma
      // uniform backdrops flip at ~0.89 (measured); a busy one (grid, text) needs a brighter mean to count as light
      vec2 ms = lumaWide(magnified + disp, texel, 18.0 * plate.w);
      float thr = 0.89 + 0.40 * ms.y;
      YtSmall = mix(toneSmallDark(Y), toneSmallBright(Y), smoothstep(thr - 0.02, thr + 0.03, ms.x));
    }
    Yt = mix(Yt, YtSmall, plate.z);
  }
  col = vec3(Yt) + (col - vec3(Y)) * uSaturation;
  col = clamp(col, 0.0, 1.0);
  col = mix(col, tintv.rgb, tintv.a + uTint.a * 0.0);  // uTint (global) is superseded by uTints; kept so uniform indices stay put
  // press highlight of interactive glass: ~16% white over the plate (measured)
  // gaussian around the touch, sigma (pt) in hiv.w: ~65 for plates up to ~104 pt (0.35 at 30 pt, 0.15 at 63 pt from the
  // finger on a toolbar capsule), ~300 for big ones (flat: 0.81 at 140 pt)
  float rr = length(pos - (center + hiv.yz * plate.w)) / (max(hiv.w, 1.0) * plate.w);
  float fall = exp(-rr * rr);
  col = mix(col, vec3(uHdr), 0.16 * hiv.x * fall);

  // specular hairline (lit from the top): normal-dependent, fades downwards
  float pxPt = plate.w;
  float dp = depth / pxPt;                                   // depth in pt
  float line = smoothstep(0.15, 0.45, dp) * (1.0 - smoothstep(0.85, 1.25, dp));
  float lit = 0.08 + 0.92 * pow(clamp((1.0 - n.y) * 0.5, 0.0, 1.0), 1.4);     // top 1, sides ~0.4, bottom ~0.08
  float ty = clamp((pos.y - rect.y) / rect.w, 0.0, 1.0);
  // pressed small plates get a bright ring all around (native: hi > 1 only for small plates)
  float ring = 0.45 * smoothstep(1.0, 2.6, hiv.x);
  float tintW = clamp(tintv.a * 2.9, 0.0, 1.0);  // tinted glass: coloured rim instead of the white hairline
  col = mix(col, vec3(uHdr), line * (1.0 - tintW) * (lit * (1.0 - 0.55 * ty) * 0.30 * uSpecular + ring));
  // tinted glass: the rim is a bright edge in the tint's hue (screen blend, fades over ~1 pt from the very edge)
  float tintS = clamp(tintv.a * 2.9, 0.0, 1.0);
  float edge = 1.0 - smoothstep(0.0, 1.6, dp);
  vec3 ringTint = clamp(tintv.rgb, 0.0, 1.0) * 0.70 * (0.35 + 0.65 * lit) * uSpecular;
  col = vec3(1.0) - (vec3(1.0) - col) * (vec3(1.0) - ringTint * (edge * tintS));

  // transparent outside the shape (the backdrop beneath shows through),
  // anti-aliased edge
  float cover = clamp(0.5 - dRaw, 0.0, 1.0);
  fragColor = vec4(col * cover, cover) * uFade;
}
