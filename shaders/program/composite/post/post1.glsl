#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/text.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

void main ()
{ 

vec2 uv = gl_FragCoord.xy / screenSize;

    color.r = texture(colortex10, mix(vec2(0.5), uv, 500.0 / (500.0 + 2 * CHROMATIC_ABERRATION))).r;
    color.g = texture(colortex10, mix(vec2(0.5), uv, 500.0 / (500.0 + CHROMATIC_ABERRATION))).g;
    color.b = texture(colortex10, uv).b;
    color.a = 1.0;
}