#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/atmosphere.glsl"
#include "/include/brdf.glsl"
#include "/include/spaceConversion.glsl"

#include "/include/text.glsl"

/* RENDERTARGETS: 7,13 */
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 virtualDepth;

void main ()
{   
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;
    virtualDepth = vec4(depth, 0.0, 0.0, 1.0);

    if (depth != 1.0) {
        color = texelFetch(colortex7, texel, 0);
        return;
    }

    vec2 uv = gl_FragCoord.xy * texelSize;

    #ifndef DIMENSION_OVERWORLD
        color = vec4(0.0);
    #else
        color.rgb = EXPONENT_BIAS * (pow(texelFetch(colortex10, texel, 0).rgb, vec3(2.2)) + calcSkyColor(normalize(screenToPlayerPos(vec3(uv, 0.9)).xyz - screenToPlayerPos(vec3(uv, 0.1)).xyz), sunDir, blueNoise(gl_FragCoord.xy).x));
    #endif
}