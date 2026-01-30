#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/atmosphere.glsl"
#include "/include/brdf.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/text.glsl"

#ifdef REFLECTION_HALF_RES
    #define INDIRECT_LIGHTING_RES 2
#else
    #define INDIRECT_LIGHTING_RES 1
#endif

#include "/include/textureSampling.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{   
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;

    color = texelFetch(colortex7, texel, 0);

    if (depth == 1.0) return;

    DeferredMaterial mat = unpackMaterialData(texel);
    color.rgb += EXPONENT_BIAS * EMISSION_BRIGHTNESS * mat.albedo.rgb * mat.emission;

    if (mat.roughness > REFLECTION_ROUGHNESS_THRESHOLD) return;

    vec3 currPos = screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, depth)).xyz;
    vec3 reflectedIrradiance = upsampleRadiance(currPos, mat.geoNormal, mat.textureNormal);

    color.rgb += EXPONENT_BIAS * reflectedIrradiance * schlickFresnel(mat.F0, dot(mat.textureNormal, normalize(screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 0.0)).xyz - currPos)));
}