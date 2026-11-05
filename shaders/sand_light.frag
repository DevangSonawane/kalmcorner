#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // float slots 0,1: drawn size in logical px
uniform vec2 uTexel;       // float slots 2,3: 1 / height-texture size
uniform vec3 uSand;        // float slots 4,5,6: base sand color (0..1)
uniform float uStrength;   // float slot 7: relief strength (default 6.0)
uniform sampler2D uHeight; // sampler 0: height in R (0.5 flat)

out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;

  float hl = texture(uHeight, uv - vec2(uTexel.x, 0.0)).r;
  float hr = texture(uHeight, uv + vec2(uTexel.x, 0.0)).r;
  float hd = texture(uHeight, uv - vec2(0.0, uTexel.y)).r;   // y grows downward in uv
  float hu = texture(uHeight, uv + vec2(0.0, uTexel.y)).r;

  vec3 n = normalize(vec3((hl - hr) * uStrength, (hd - hu) * uStrength, 1.0));
  vec3 L = normalize(vec3(-0.55, -0.65, 0.52));              // light from the upper left
  float lit = dot(n, L) / L.z;                                // 1.0 on flat sand

  vec3 col = uSand * clamp(0.55 + 0.45 * lit, 0.35, 1.35);

  float g = hash(floor(frag));                                // fine static grain
  col *= 0.96 + 0.08 * g;
  col += step(0.997, hash(floor(frag) + 7.3)) * 0.05;         // rare glints

  fragColor = vec4(col, 1.0);
}