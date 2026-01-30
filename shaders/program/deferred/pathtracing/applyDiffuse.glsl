#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/atmosphere.glsl"
#include "/include/brdf.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/ircache.glsl"
#include "/include/text.glsl"

#ifdef DIFFUSE_HALF_RES
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
    
    color = vec4(0.0);

    if (depth == 1.0) return;

    vec3 currPos = screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, depth)).xyz;
    DeferredMaterial mat = unpackMaterialData(texel);

    vec3 diffuseIrradiance = upsampleRadiance(currPos, mat.geoNormal, mat.textureNormal);

    #ifdef DEBUG_IRCACHE
        if (!hideGUI) diffuseIrradiance = irradianceCacheView(currPos, mat.geoNormal).diffuseIrradiance;
    #endif

    if (mat.roughness <= REFLECTION_ROUGHNESS_THRESHOLD) diffuseIrradiance *= 1.0 - schlickFresnel(mat.F0, dot(mat.textureNormal, normalize(screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 0.0)).xyz - currPos)));

    color.rgb = EXPONENT_BIAS * mat.albedo.rgb * diffuseIrradiance;
}