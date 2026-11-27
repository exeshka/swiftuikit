// The edge lens of glass over its own content (the rows of a menu): inside a rounded rectangle (the plate, four radii) the content
// within `uBezel` of the edge is read from deeper inside along the normal, so it is stretched towards the rim as under a native
// liquid-glass plate (measured: a ~14 pt band, rows and icons smeared along the normal). Outside the rounded rectangle the output
// is transparent, so the shader also cuts the content by the plate's contour. Used with ImageFilter.shader over a child that is
// exactly the plate's size.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // set by the engine: size of the input texture (px)
uniform vec4 uRadii;    // corner radii in px: top-left, top-right, bottom-right, bottom-left
uniform float uBezel;   // width of the lens band in px
uniform float uStrength; // 0..1
uniform sampler2D uTex;

out vec4 fragColor;

float sdf(vec2 p, vec2 h, vec4 r) {
  float rr = p.x < 0.0 ? (p.y < 0.0 ? r.x : r.w) : (p.y < 0.0 ? r.y : r.z);
  rr = min(rr, min(h.x, h.y));
  vec2 q = abs(p) - h + rr;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rr;
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 h = uSize * 0.5;
  vec2 p = pos - h;
  float d = sdf(p, h, uRadii);
  if (d > 0.5) {
    fragColor = vec4(0.0);
    return;
  }
  float depth = -d;
  const float e = 1.0;
  vec2 n = normalize(vec2(
    sdf(p + vec2(e, 0.0), h, uRadii) - sdf(p - vec2(e, 0.0), h, uRadii),
    sdf(p + vec2(0.0, e), h, uRadii) - sdf(p - vec2(0.0, e), h, uRadii)) + vec2(1e-6));
  float t = clamp(depth / max(uBezel, 1.0), 0.0, 1.0);
  float s = t * t * (3.0 - 2.0 * t);
  vec2 src = pos - n * uBezel * (1.0 - s) * uStrength;
  vec4 c = texture(uTex, src / uSize);
  fragColor = c * clamp(0.5 - d, 0.0, 1.0);
}
