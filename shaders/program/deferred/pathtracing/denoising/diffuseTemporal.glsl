
#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/text.glsl"

#ifdef DIFFUSE_HALF_RES
    #define INDIRECT_LIGHTING_RES 2
#else
    #define INDIRECT_LIGHTING_RES 1
#endif

#include "/include/textureSampling.glsl"

/* RENDERTARGETS: 3 */
layout (location = 0) out vec4 filteredData;

void main ()
{   
    #ifdef DIFFUSE_HALF_RES
        ivec2 offsetCoord = 2 * ivec2(gl_FragCoord.xy) + checker2x2(frameCounter);
        vec2 uv = (offsetCoord + 0.5) * texelSize;
    #else
        ivec2 offsetCoord = ivec2(gl_FragCoord.xy);
        vec2 uv = gl_FragCoord.xy * texelSize;
    #endif

    float depth = texelFetch(depthtex1, offsetCoord, 0).r;
    filteredData = vec4(0.0, 0.0, 0.0, 1.0);

    if (depth == 1.0) return;

    vec4 playerPos = screenToPlayerPos(vec3(uv, depth));
    vec4 normalData = unpackExp4x8(texelFetch(colortex9, offsetCoord, 0).x);

    #if defined TEMPORAL_NORMAL_TOLERANCE || !defined NORMAL_MAPPING
        vec3 normal = octDecode(normalData.zw);
    #else
        vec3 normal = octDecode(normalData.xy);
    #endif
    
    vec4 prevUv = projectAndDivide(gbufferPreviousModelViewProjection, playerPos.xyz + cameraVelocity);
    #if !defined TAA && defined TEMPORAL_PREFILTERING
        prevUv.xyz = (prevUv.xyz + vec3(texelSize * (R2(frameCounter & 63u) - 0.5), 0.0)) * 0.5 + 0.5;
    #else
        prevUv.xyz = (prevUv.xyz + vec3(taaOffsetPrev, 0.0)) * 0.5 + 0.5;
    #endif

    vec4 lastFrame;

    if (floor(prevUv.xy) == vec2(0.0) && prevUv.w > 0.0)
    {   
        lastFrame = sampleHistory(colortex3, playerPos.xyz, normal, prevUv.xy, renderSize);
    }
    else
    {
        lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
    }

    filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);

    lastFrame.w = mix(1.0, lastFrame.w, min(1.0, exp(2.0 - 2.0 * playerPos.w * prevUv.w)));

    filteredData.rgb = mix(lastFrame.rgb, filteredData.rgb, rcp(lastFrame.w));
    filteredData.w = min(lastFrame.w + 1.0, PT_DIFFUSE_ACCUMULATION_LIMIT);
}