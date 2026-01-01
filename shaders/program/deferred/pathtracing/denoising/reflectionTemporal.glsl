#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/spaceConversion.glsl"

#include "/include/text.glsl"

/* DRAWBUFFERS:4 */
layout (location = 0) out vec4 filteredData;

void main ()
{   
    uint state = (uint(gl_FragCoord.x) >> 1) + (uint(gl_FragCoord.y) >> 1) * uint(viewWidth / 2.0) + uint(viewWidth / 2.0) * uint(viewHeight / 2.0) * (frameCounter & 1023u);
    ivec2 offset = checkerOffsets2x2[frameCounter & 3];

    float depth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;
    filteredData = vec4(0.0, 0.0, 0.0, 1.0);

    if (depth == 1.0) return;

    vec4 playerPos = gbufferModelViewProjectionInverse * vec4(vec3(gl_FragCoord.xy * texelSize, depth) * 2.0 - 1.0 - vec3(taaOffset, 0.0), 1.0);
    playerPos.xyz /= playerPos.w;
    playerPos.xyz += cameraVelocity;

    DeferredMaterial mat = unpackMaterialData(ivec2(gl_FragCoord.xy));

    if (mat.roughness > REFLECTION_ROUGHNESS_THRESHOLD) return;

    if ((ivec2(gl_FragCoord.xy) & 1) == ivec2(offset)) 
    {
        filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy) >> 1, 0);
    }
    else
    {
        filteredData = vec4(0.0, 0.0, 0.0, texelFetch(colortex2, ivec2(gl_FragCoord.xy) >> 1, 0).w);
    }

    vec4 prevUv = gbufferPreviousModelViewProjection * vec4(playerPos.xyz + normalize(playerPos.xyz - cameraVelocity - screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 0.0)).xyz) * filteredData.w, 1.0);
    prevUv.xyz = (prevUv.xyz / prevUv.w + vec3(taaOffsetPrev, 0.0)) * 0.5 + 0.5;

    vec4 lastFrame;

    if (floor(prevUv.xy) == vec2(0.0) && prevUv.w > 0.0)
    {   
        lastFrame = texBilinearDepthReject(colortex4, colortex0, mat.geoNormal * dot(mat.geoNormal, playerPos.xyz), prevUv.xy, renderSize);
    }
    else
    {
        lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
    }

     if (any(isnan(lastFrame))) lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
     
    filteredData.rgb = mix(lastFrame.rgb, filteredData.rgb, rcp(lastFrame.w));
    filteredData.w = min(lastFrame.w + 1.0, (filteredData.w > (REFLECTION_MAX_RT_DISTANCE / 2.0) || mat.roughness < 0.003) ? min(4, PT_REFLECTION_ACCUMULATION_LIMIT) : PT_REFLECTION_ACCUMULATION_LIMIT);
}