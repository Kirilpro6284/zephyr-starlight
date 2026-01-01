#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"

#include "/include/text.glsl"

/* DRAWBUFFERS:5 */
layout (location = 0) out vec4 filteredData;

void main ()
{   
    float depth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;

    filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);

    if (depth == 1.0) return;

    vec3 shadowMin = filteredData.rgb;
    vec3 shadowMax = filteredData.rgb;

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            if (abs(x) == -abs(y)) continue;

            vec3 sampleData = texelFetch(colortex2, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb;

            shadowMin = min(sampleData, shadowMin);
            shadowMax = max(sampleData, shadowMax);
        }
    }

    vec4 playerPos = gbufferModelViewProjectionInverse * vec4(vec3(gl_FragCoord.xy * texelSize, depth) * 2.0 - 1.0 - vec3(taaOffset, 0.0), 1.0);
    playerPos.xyz /= playerPos.w;
    playerPos.xyz += cameraVelocity;

    vec3 geoNormal = octDecode(unpack2x8(texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).x >> 16u));

    vec4 prevUv = gbufferPreviousModelViewProjection * vec4(playerPos.xyz, 1.0);
    prevUv.xyz = (prevUv.xyz / prevUv.w + vec3(taaOffsetPrev, 0.0)) * 0.5 + 0.5;

    vec4 lastFrame;

    if (floor(prevUv.xy) == vec2(0.0) && prevUv.w > 0.0)
    {   
        lastFrame = texBilinearDepthReject(colortex5, colortex0, geoNormal * dot(geoNormal, playerPos.xyz), prevUv.xy, renderSize);
    }
    else
    {
        lastFrame = vec4(0.0, 0.0, 0.0, 1.0);
    }

    if (any(isnan(lastFrame))) lastFrame = vec4(0.0, 0.0, 0.0, 1.0);

    lastFrame.w = max(1.0, lastFrame.w * min(1.0, exp(3.0 - 3.0 * playerPos.w * prevUv.w)));

    filteredData.rgb = mix(clamp(lastFrame.rgb, shadowMin, shadowMax), filteredData.rgb, rcp(lastFrame.w));
    filteredData.w = min(lastFrame.w + 1.0, PT_SHADOW_ACCUMULATION_LIMIT);
}