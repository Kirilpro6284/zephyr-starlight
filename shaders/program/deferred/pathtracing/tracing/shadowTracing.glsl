#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/heitz.glsl"
#include "/include/octree.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/brdf.glsl"
#include "/include/ircache.glsl"
#include "/include/spaceConversion.glsl"

layout (rgba16f) uniform image2D colorimg2;
layout (local_size_x = 8, local_size_y = 4) in;

#ifdef SHADOW_HALF_RES
    #if TAA_UPSCALING_FACTOR == 100
        const vec2 workGroupsRender = vec2(0.5, 0.5);
    #elif TAA_UPSCALING_FACTOR == 75
        const vec2 workGroupsRender = vec2(0.375, 0.375);
    #elif TAA_UPSCALING_FACTOR == 50
        const vec2 workGroupsRender = vec2(0.25, 0.25);
    #endif
#else
    #if TAA_UPSCALING_FACTOR == 100
        const vec2 workGroupsRender = vec2(1.0, 1.0);
    #elif TAA_UPSCALING_FACTOR == 75
        const vec2 workGroupsRender = vec2(0.75, 0.75);
    #elif TAA_UPSCALING_FACTOR == 50
        const vec2 workGroupsRender = vec2(0.5, 0.5);
    #endif
#endif

void main ()
{
    uint state = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * uint(renderSize.x) + uint(renderSize.x) * uint(renderSize.y) * (frameCounter & 1023u);
    #ifdef SHADOW_HALF_RES
        ivec2 texel = 2 * ivec2(gl_GlobalInvocationID.xy) + checker2x2(frameCounter);
    #else
        ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    #endif

    float depth = texelFetch(depthtex1, texel, 0).x;

    if (depth == 1.0) {
        imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 0.0, 0.0, 1.0));
        return;
    }

    DeferredMaterial mat = unpackMaterialData(texel);

    if (dot(mat.geoNormal, shadowDir) > -0.0001) {
        vec2 uv = (vec2(texel) + 0.5) * texelSize;
        
        Ray shadowRay;
        shadowRay.origin = screenToPlayerPos(vec3(uv, depth)).xyz + mat.geoNormal * 0.005;

        if (mat.isHand) {
            shadowRay.origin += 0.5 * playerLookVector;
        }

        vec3 shadowMask = vec3(0.0);

        for (int i = 0; i < SHADOW_SAMPLES; i++) {
            shadowRay.direction = sampleSunDir(shadowDir, 
                #if NOISE_METHOD == 1
                    vec2(heitzSample(ivec2(gl_GlobalInvocationID.xy), frameCounter, 2 * i), heitzSample(ivec2(gl_GlobalInvocationID.xy), frameCounter, 2 * i + 1))
                #else
                    vec2(randomValue(state), randomValue(state))
                #endif
            );
            shadowMask += TraceShadowRay(shadowRay, 1024.0, true).rgb;
        }

        shadowMask *= rcp(SHADOW_SAMPLES);

        imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(shadowMask, 1.0));
    } else imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 0.0, 0.0, 1.0));
}