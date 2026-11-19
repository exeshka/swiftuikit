// One pass of a separable, variable-sigma gaussian blur used by the
// progressive blur. Run twice (horizontal then vertical) via
// ImageFilter.compose. The sigma depends only on the distance to the
// "strong" edge of the blur zone (the engine hands us the whole backdrop
// layer, so the zone rectangle is passed in explicitly): max at the edge, 0 at the inner
// side, with zero slope at both ends so no seam is visible.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // set by the engine: size of the input texture
uniform vec2 uDir;       // (1,0) horizontal pass, (0,1) vertical pass
uniform float uMaxSigma; // sigma in logical-pixel * pixelRatio units
uniform float uStrongAtBottom; // 1.0: strongest at bottom edge, 0.0: at top
uniform float uZoneTop;  // zone top in the filtered layer's pixels
uniform float uZoneH;    // zone height in pixels
uniform sampler2D uTex;

out vec4 fragColor;

// Cost control (phones throttled on the old 40 taps/side at 1.8 px): tap spacing grows with sigma. A gaussian sampled
// every ~0.15 sigma (0.42 left visible ghost copies of text at the strong edge), and the tap count stays
// small (<= 18 per side) at any sigma instead of growing linearly with it.
const int MAX_TAPS = 18;      // per side
const float STEP_MIN_PX = 1.8; // finest tap spacing (small sigma)
const float STEP_REL = 0.15;   // tap spacing relative to sigma

// Taps past the texture edge (the screen edge, where the blur is strongest): transparent there would pull the blur
// toward transparency, and clamping would repeat the edge row and leave text sharp. Mirroring the content back inside
// behaves like the content continuing past the edge, so the blur stays full strength right up to it.
vec2 refl(vec2 p, vec2 lo, vec2 hi) {
  p = mix(p, 2.0 * lo - p, step(p, lo));
  p = mix(p, 2.0 * hi - p, step(hi, p));
  return clamp(p, lo, hi);
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  float y = (pos.y - uZoneTop) / uZoneH;
  // Impeller runs this shader over the whole re-rasterized input (from the pass origin to the clip's bottom-right corner,
  // flutter/flutter#194832), not just over the clip. Outside the zone the result is clipped away anyway: skip the texture
  // read there (a small margin keeps the rows that the neighbouring taps of the second pass can reach).
  if (y < -0.02 || y > 1.02) { fragColor = vec4(0.0); return; }
  float t = mix(1.0 - y, y, uStrongAtBottom);   // 1 at the strong edge
  t = clamp(t, 0.0, 1.0);
  float e = t * t * (3.0 - 2.0 * t);
  float sigma = uMaxSigma * e;
  vec2 texel = 1.0 / uSize;
  vec4 c0 = texture(uTex, pos * texel);
  if (sigma < 0.35) { fragColor = c0; return; }
  // Adaptive tap count: only as many taps as the local sigma needs. Most of
  // the zone has a small sigma, so most pixels take far fewer than MAX_TAPS.
  float span = sigma * 2.2;
  float want = max(STEP_MIN_PX, sigma * STEP_REL);
  int n = int(min(float(MAX_TAPS), ceil(span / want)));
  float step = span / float(n);
  float inv = -0.5 / (sigma * sigma);
  vec2 lo = vec2(0.5);
  vec2 hi = uSize - vec2(0.5);
  vec4 acc = c0;
  float wsum = 1.0;
  for (int i = 1; i <= MAX_TAPS; i++) {
    if (i > n) break;
    float x = float(i) * step;
    float w = exp(inv * x * x);
    vec2 o = uDir * x;
    acc += w * (texture(uTex, refl(pos + o, lo, hi) * texel) + texture(uTex, refl(pos - o, lo, hi) * texel));
    wsum += 2.0 * w;
  }
  fragColor = acc / wsum;
}
