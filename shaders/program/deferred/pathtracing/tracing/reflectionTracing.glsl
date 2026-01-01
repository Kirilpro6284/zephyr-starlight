#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/heitz.glsl"
#include "/include/octree.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/brdf.glsl"
#include "/include/irc.glsl"
#include "/include/atmosphere.glsl"
#include "/include/spaceConversion.glsl"

layout (rgba16f) uniform image2D colorimg2;
layout (local_size_x = 8, local_size_y = 8) in;

#if TAA_UPSCALING_FACTOR == 100
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#elif TAA_UPSCALING_FACTOR == 75
    const vec2 workGroupsRender = vec2(0.375, 0.375);
#elif TAA_UPSCALING_FACTOR == 50
    const vec2 workGroupsRender = vec2(0.25, 0.25);
#endif

void main ()
{
    uint state = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * uint(renderSize.x / 2.0) + uint(renderSize.x / 2.0) * uint(renderSize.y / 2.0) * (frameCounter & 1023u);
    ivec2 offset = checkerOffsets2x2[frameCounter & 3];
    ivec2 offsetCoord = ivec2(gl_GlobalInvocationID.xy) * 2 + ivec2(offset);

    float depth = texelFetch(depthtex1, offsetCoord, 0).x;

    if (depth == 1.0) {
        imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 0.0, 0.0, 1.0));
        return;
    }

    DeferredMaterial mat = unpackMaterialData(offsetCoord);

    if (mat.roughness > REFLECTION_ROUGHNESS_THRESHOLD) {
        imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 0.0, 0.0, 1.0));
        return;
    }

    vec2 uv = (vec2(offsetCoord) + 0.5) * texelSize;
    vec4 playerPos = screenToPlayerPos(vec3(uv, depth));

    Ray specularRay;

    specularRay.origin = playerPos.xyz + mat.geoNormal * 0.005;
    
    vec3 radiance = vec3(0.0);
    float parallaxDepth = REFLECTION_MAX_RT_DISTANCE;

    for (int i = 0; i < REFLECTION_SAMPLES; i++) {
        specularRay.direction = sampleVNDF(normalize(playerPos.xyz - screenToPlayerPos(vec3(uv, 0.00001)).xyz), mat.textureNormal, mat.roughness, 
            #if NOISE_METHOD == 1
                vec2(heitzSample(ivec2(gl_GlobalInvocationID.xy), frameCounter, 2 * i), heitzSample(ivec2(gl_GlobalInvocationID.xy), frameCounter, 2 * i + 1))
            #else
                vec2(randomValue(state), randomValue(state))
            #endif
        );
        RayHitInfo rt = TraceRay(specularRay, REFLECTION_MAX_RT_DISTANCE, true, true);

        if (rt.dist != REFLECTION_MAX_RT_DISTANCE) {
            vec3 hitPos = specularRay.origin + rt.dist * specularRay.direction;
            vec3 hitUv = playerToScreenPos(hitPos);

            radiance += rt.albedo.rgb * rt.emission;

            vec3 diffuse, direct;

            if (floor(hitUv.xy) == vec2(0.0) && distance(hitPos, screenToPlayerPos(vec3(hitUv.xy, texelFetch(depthtex1, ivec2(hitUv.xy * renderSize), 0).x)).xyz) < 0.05) {
                diffuse = texelFetch(colortex3, ivec2(hitUv.xy * renderSize), 0).rgb;
                direct = texelFetch(colortex5, ivec2(hitUv.xy * renderSize), 0).rgb;
            } else {
                IRCResult query = queryIRC(specularRay.origin + specularRay.direction * rt.dist, rt.normal, 0u);

                diffuse = query.diffuseIrradiance;
                direct = query.directIrradiance;
            }

            radiance += rt.albedo.rgb * diffuse;

            if (dot(rt.normal, shadowDir) > 0.0) {
                radiance += getLightTransmittance(shadowDir) * lightBrightness * direct * evalCookBRDF(shadowDir, specularRay.direction, max(0.1, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);
            }
        } else {
            radiance += rt.albedo.rgb * sampleSkyView(specularRay.direction);
        }

        parallaxDepth = min(parallaxDepth, rt.dist);
    }
    
    radiance *= rcp(REFLECTION_SAMPLES);

    imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(4.0 * radiance, parallaxDepth));
}