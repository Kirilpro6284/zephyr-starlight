#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/checker.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/spaceConversion.glsl"

#include "/include/text.glsl"

/* RENDERTARGETS: 6 */
layout (location = 0) out vec4 history;

void main ()
{   
    ivec2 srcTexel = ivec2(TAAU_RENDER_SCALE * gl_FragCoord.xy);
    vec2 dstTexel = gl_FragCoord.xy;

    //ivec2 srcTexel = ivec2(floor(TAAU_RENDER_SCALE * (gl_FragCoord.xy + R2(frameCounter & 255u) - 0.5)));
    //vec2 dstTexel = floor(texelSize * screenSize * (vec2(srcTexel) + 0.5 - 0.5 * renderSize * taaOffset));

    vec2 coord = floor(gl_FragCoord.xy * pixelSize * renderSize - 0.499);
    bool isUnderSample = true;

    for (int i = frameCounter; i < frameCounter + 4; i++) {
        if (ivec2(screenSize * texelSize * (coord + vec2(i & 1, (i >> 1) & 1) + 0.5 + taaOffset * renderSize)) == ivec2(gl_FragCoord.xy)) {
            isUnderSample = false;
            break;
        }
    }

    vec4 currData = texelFetch(colortex7, srcTexel, 0) / EXPONENT_BIAS;
    vec2 uv = gl_FragCoord.xy / screenSize;

    float depth = 1.0;

    for (int x = -1; x <= 1; x++) 
		for (int y = -1; y <= 1; y++)
            #ifdef TAA_VIRTUAL_DEPTH
			    depth = min(depth, texelFetch(colortex13, clamp(srcTexel + ivec2(x, y), ivec2(0), ivec2(renderSize) - 1), 0).r);
            #else
                depth = min(depth, texelFetch(depthtex1, clamp(srcTexel + ivec2(x, y), ivec2(0), ivec2(renderSize) - 1), 0).r);
            #endif

    vec4 currPos = screenToPlayerPos(vec3(uv, depth));
    vec4 prevPos = projectAndDivide(gbufferPreviousModelViewProjection, depth == 1.0 ? currPos.xyz : (currPos.xyz + cameraVelocity));

    vec3 prevUv = (prevPos.xyz + vec3(taaOffset, 0.0)) * 0.5 + 0.5;
    vec4 color = currData;

    if (saturate(prevUv.xyz) == prevUv.xyz && prevPos.w > 0.0) 
    {
        vec4 prevData = texture(colortex6, prevUv.xy);
        vec3 colorMin = vec3(INFINITY);
        vec3 colorMax = vec3(-INFINITY);

        for (int x = -1; x <= 1; x++) 
			for (int y = -1; y <= 1; y++) {
                vec3 sampleData = texelFetch(colortex7, clamp(srcTexel + ivec2(x, y), ivec2(0), ivec2(renderSize) - 1), 0).rgb / EXPONENT_BIAS;

				colorMin = min(colorMin, sampleData);
				colorMax = max(colorMax, sampleData);
            }

        if (!any(isnan(prevData)))
        {
            float sampleWeight = isUnderSample ? 0.005 : 1.0;

            color = vec4(exp(mix(log(currData.rgb + 0.0001), log(clamp(prevData.rgb, colorMin, colorMax) + 0.0001), exp(-(16.0 * TAA_VARIANCE_WEIGHT * length(clamp(prevData.rgb, colorMin, colorMax) - prevData.rgb) + TAA_OFFCENTER_WEIGHT * (abs(fract(prevUv.x * screenSize.x) - 0.5) + abs(fract(prevUv.y * screenSize.y) - 0.5)))) * prevData.a / (prevData.a + sampleWeight))) - 0.0001, 1.0);
            history = vec4(color.rgb, min(prevData.a + sampleWeight, TAA_ACCUMULATION_LIMIT));
        } else history = vec4(currData.rgb, TAA_ACCUMULATION_LIMIT);
    } else history = vec4(currData.rgb, 1.0);
}

/*
 vec2 coord = floor(gl_FragCoord.xy * pixelSize * renderSize - 0.499);
    ivec2 srcTexel = ivec2(coord); bool isUnderSample = true;

    for (int i = frameCounter; i < frameCounter + 4; i++) {
        ivec2 dstTexel = ivec2(screenSize * texelSize * (coord + vec2(i & 1, (i >> 1) & 1) + 0.5 + taaOffset * renderSize));

        if (dstTexel == ivec2(gl_FragCoord.xy)) {
            isUnderSample = false;
            srcTexel = ivec2(coord + vec2(i & 1, (i >> 1) & 1));
            break;
        }
    }
    */