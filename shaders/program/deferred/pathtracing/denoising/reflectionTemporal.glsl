#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/text.glsl"

#ifdef REFLECTION_HALF_RES
    #define INDIRECT_LIGHTING_RES 2
#else
    #define INDIRECT_LIGHTING_RES 1
#endif

#include "/include/textureSampling.glsl"

/* RENDERTARGETS: 4 */
layout (location = 0) out vec4 filteredData;

void main ()
{   
    #ifdef REFLECTION_HALF_RES
        ivec2 offsetCoord = 2 * ivec2(gl_FragCoord.xy) + checker2x2(frameCounter);
        vec2 uv = (offsetCoord + 0.5) * texelSize;
    #else
        ivec2 offsetCoord = ivec2(gl_FragCoord.xy);
        vec2 uv = gl_FragCoord.xy * texelSize;
    #endif

    float depth = texelFetch(depthtex1, offsetCoord, 0).r;
    filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);

    if (depth == 1.0) return;

    DeferredMaterial mat = unpackMaterialData(offsetCoord);
    
    if (mat.roughness > REFLECTION_ROUGHNESS_THRESHOLD) return;

    vec4 playerPos = screenToPlayerPos(vec3(uv, depth));
    vec3 virtualPos = playerPos.xyz + step(0.125, filteredData.w) * normalize(playerPos.xyz - screenToPlayerPos(vec3(uv, 0.0)).xyz) * filteredData.w;

    vec4 prevUv = projectAndDivide(gbufferPreviousModelViewProjection, virtualPos + cameraVelocity);
    #if !defined TAA && defined TEMPORAL_PREFILTERING
        prevUv.xyz = (prevUv.xyz + vec3(texelSize * (R2(frameCounter & 7u) - 0.5), 0.0)) * 0.5 + 0.5;
    #else
        prevUv.xyz = (prevUv.xyz + vec3(taaOffsetPrev, 0.0)) * 0.5 + 0.5;
    #endif

    vec4 lastFrame;

    if (floor(prevUv.xy) == vec2(0.0) && prevUv.w > 0.0)
    {   
        lastFrame = sampleHistory(colortex4, playerPos.xyz, 
            #ifdef TEMPORAL_NORMAL_TOLERANCE
                mat.textureNormal,
            #else
                mat.geoNormal,
            #endif
        prevUv.xy, renderSize);
    }
    else
    {
        lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
    }

    if (any(isnan(lastFrame))) lastFrame = vec4(0.0, 0.0, 0.0, 1.0);

    filteredData.rgb = mix(lastFrame.rgb, filteredData.rgb, rcp(lastFrame.w));
    filteredData.w = min(lastFrame.w + 1.0, mat.roughness < 0.001 ? min(4, PT_REFLECTION_ACCUMULATION_LIMIT) : PT_REFLECTION_ACCUMULATION_LIMIT);
}