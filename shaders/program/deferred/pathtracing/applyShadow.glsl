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

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{   
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;

    color = texelFetch(colortex7, texel, 0);

    if (depth == 1.0) return;

    DeferredMaterial mat = unpackMaterialData(texel);

    vec3 brdf = evalCookBRDF(normalize(shadowDir + mat.geoNormal * 0.03125), normalize(screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, depth)).xyz - screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 0.0)).xyz), max(0.1, mat.roughness), mat.textureNormal, mat.albedo.rgb, mat.F0);

    //if (luminance(brdf) > 0.001) {
        color.rgb += EXPONENT_BIAS * texelFetch(colortex2, texel, 0).rgb * lightBrightness * brdf * lightTransmittance(shadowDir);
    //}
}