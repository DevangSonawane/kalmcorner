#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;          // float slots 0,1: size in logical px of the drawn rect
uniform sampler2D uSharp;    // sampler 0: the scene
uniform sampler2D uDirty;    // sampler 1: blurred scene with the dirt baked in (opaque)
uniform sampler2D uMask;     // sampler 2: clean amount in R (1 = clean)

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec3 sharp = texture(uSharp, uv).rgb;
  vec3 dirty = texture(uDirty, uv).rgb;
  float clean = texture(uMask, uv).r;

  float cover = smoothstep(0.0, 0.85, 1.0 - clean);      // dirt remaining
  vec3 col = mix(sharp, dirty, cover);

  // faint bright wet rim where the cloth just passed
  float rim = smoothstep(0.35, 0.5, clean) * (1.0 - smoothstep(0.5, 0.65, clean));
  col += rim * 0.05;

  fragColor = vec4(col, 1.0);
}