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
#include "/include/ircache.glsl"
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

    if (luminance(mat.albedo) < 0.001) {
        imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 0.0, 0.0, 1.0));
        return;
    }

    vec2 uv = (vec2(offsetCoord) + 0.5) * texelSize;
    vec4 playerPos = screenToPlayerPos(vec3(uv, depth));

    Ray diffuseRay;

    diffuseRay.origin = playerPos.xyz + mat.geoNormal * 0.005;
    vec3 radiance = vec3(0.0);

    for (int i = 0; i < DIFFUSE_SAMPLES; i++) {
        #if NOISE_METHOD == 1
            diffuseRay.direction = randomHemisphereDirBlueNoise(ivec2(gl_GlobalInvocationID.xy), mat.geoNormal, i);
        #else
            diffuseRay.direction = randomHemisphereDir(mat.geoNormal, state);
        #endif

        RayHitInfo rt = TraceRay(diffuseRay, DIFFUSE_MAX_RT_DISTANCE, true, true);

        if (rt.dist != DIFFUSE_MAX_RT_DISTANCE) {        
            IRCResult query = irradianceCache(diffuseRay.origin + diffuseRay.direction * rt.dist, rt.normal, 0u);
            radiance += OUTGOING_RADIANCE_INTENSITY*max(0.0, dot(mat.textureNormal, diffuseRay.direction)) * (rt.albedo.rgb * rt.emission + query.diffuseIrradiance * smoothstep(rt.dist, 0.0, 1.0) * rt.albedo.rgb);

            vec3 dir = sampleSunDir(shadowDir, vec2(randomValue(state), randomValue(state)));

            if (dot(rt.normal, dir) > 0.0) {
                vec3 sunlight = vec3(SUN_RED,SUN_GREEN,SUN_BLUE)*getLightTransmittance(sunDir) * max(0.0, dot(mat.textureNormal, diffuseRay.direction)) * lightBrightness * evalCookBRDF(sunDir, diffuseRay.direction, max(0.1, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);

                #if SUNLIGHT_GI_QUALITY == 0
                    sunlight *= query.directIrradiance;
                #elif SUNLIGHT_GI_QUALITY == 1
                    if (randomValue(state) > smoothstep(0.75, 1.0, rt.dist) && (clamp(query.directIrradiance, vec3(0.01), vec3(0.99)) == query.directIrradiance)) {
                        sunlight *= TraceShadowRay(Ray(diffuseRay.origin + diffuseRay.direction * rt.dist + rt.normal * 0.003, dir), 1024.0, true).rgb;
                    } else {
                        sunlight *= query.directIrradiance;
                    }
                #elif SUNLIGHT_GI_QUALITY == 2
                    if (clamp(query.directIrradiance, vec3(0.01), vec3(0.99)) == query.directIrradiance) {
                        sunlight *= TraceShadowRay(Ray(diffuseRay.origin + diffuseRay.direction * rt.dist + rt.normal * 0.003, dir), 1024.0, true).rgb;
                    } else {
                        sunlight *= query.directIrradiance;
                    }
                #endif

                radiance += sunlight;
            }
        } 
        #ifndef DIMENSION_END
            else {
                radiance += rt.albedo.rgb * max(0.0, dot(mat.textureNormal, diffuseRay.direction)) * sampleSkyView(diffuseRay.direction);
            }
        #endif
    }

    radiance *= rcp(DIFFUSE_SAMPLES);

    imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(4.0 * radiance, 1.0));
}