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

/* DRAWBUFFERS:3 */
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

    vec3 geoNormal = octDecode(unpack2x8(texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).x >> 16u));

    vec4 prevUv = projectAndDivide(gbufferPreviousModelViewProjection, playerPos.xyz);
    prevUv.xyz = (prevUv.xyz + vec3(taaOffsetPrev, 0.0)) * 0.5 + 0.5;

    vec4 lastFrame;

    if (floor(prevUv.xy) == vec2(0.0) && prevUv.w > 0.0)
    {   
        lastFrame = texBilinearDepthReject(colortex3, colortex0, geoNormal * dot(geoNormal, playerPos.xyz), prevUv.xy, renderSize);
    }
    else
    {
        lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
    }

    if ((ivec2(gl_FragCoord.xy) & 1) == ivec2(offset)) 
    {
        filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy) >> 1, 0);
    }
    else
    {
        filteredData = vec4(0.0);
    }

    lastFrame.w = max(1.0, lastFrame.w * min(1.0, exp(2.0 - 2.0 * playerPos.w * prevUv.w)));

    filteredData.rgb = mix(lastFrame.rgb, filteredData.rgb, rcp(lastFrame.w));
    filteredData.w = min(lastFrame.w + 1.0, PT_DIFFUSE_ACCUMULATION_LIMIT);
}