#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/ircache.glsl"
#include "/include/atmosphere.glsl"
#include "/include/brdf.glsl"
#include "/include/spaceConversion.glsl"

#include "/include/text.glsl"

#define SKY_RED 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SKY_GREEN 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SKY_BLUE 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{   
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;

    if (depth != 1.0) {
        color = texelFetch(colortex7, texel, 0);
        return;
    }

    vec2 uv = gl_FragCoord.xy * texelSize;

    #ifdef DIMENSION_END
        color = vec4(0.0);
    #else
        color.rgb = pow(texelFetch(colortex10, texel, 0).rgb, vec3(2.2)) + mix(calcSkyColor(normalize(screenToPlayerPos(vec3(uv, 0.9)).xyz - screenToPlayerPos(vec3(uv, 0.1)).xyz), sunDir, blueNoise(gl_FragCoord.xy).x), vec3(SUN_RED,SUN_GREEN,SUN_BLUE)*0.15, 0.5);
    #endif
}