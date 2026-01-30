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
#include "/include/atmosphere.glsl"
#include "/include/spaceConversion.glsl"

layout (rgba16f) uniform image2D colorimg2;
layout (local_size_x = 8, local_size_y = 8) in;

#ifdef DIFFUSE_HALF_RES
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
    uint state = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * uint(renderSize.x / 2.0) + uint(renderSize.x / 2.0) * uint(renderSize.y / 2.0) * (frameCounter & 1023u);
    #ifdef DIFFUSE_HALF_RES
        ivec2 offsetCoord = ivec2(gl_GlobalInvocationID.xy) * 2 + checker2x2(frameCounter);
    #else
        ivec2 offsetCoord = ivec2(gl_GlobalInvocationID.xy);
    #endif

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
    vec3 rayOrigin;

    if (mat.isHand) {
        rayOrigin = 0.5 * playerLookVector;
    } else {
        rayOrigin = screenToPlayerPos(vec3(uv, depth)).xyz;
    }
    
    Ray diffuseRay;

    diffuseRay.origin = rayOrigin + mat.geoNormal * 0.005;
    vec3 radiance = vec3(0.0);

    for (int i = 0; i < DIFFUSE_SAMPLES; i++) {
        #if SAMPLING_METHOD == 1
            #if NOISE_METHOD == 1
                diffuseRay.direction = normalize(mat.textureNormal + randomDirBlueNoise(ivec2(gl_GlobalInvocationID.xy), i));
            #else
                diffuseRay.direction = normalize(mat.textureNormal + randomDir(state));
            #endif

            float pdf = 2.0 / PI;
        #else
            #if NOISE_METHOD == 1
                diffuseRay.direction = randomHemisphereDirBlueNoise(ivec2(gl_GlobalInvocationID.xy), mat.geoNormal, i);
            #else
                diffuseRay.direction = randomHemisphereDir(mat.geoNormal, state);
            #endif

            float pdf = max(0.0, dot(mat.textureNormal, diffuseRay.direction));
        #endif

        RayHitInfo rt = TraceGenericRay(diffuseRay, DIFFUSE_MAX_RT_DISTANCE, true, true);

        if (rt.dist != DIFFUSE_MAX_RT_DISTANCE) {       
            vec3 hitPos = diffuseRay.origin + diffuseRay.direction * rt.dist;
			float distGradient = exp2(-floor(clamp(log2(length(hitPos)) - log2(IRCACHE_CASCADE_RES / 8.0), -1.0, 0.0))) * rt.dist * dot(mat.geoNormal, diffuseRay.direction);

            IrradianceSum query = irradianceCache(0.999 * hitPos, rt.normal, 0u);

            radiance += pdf * (rt.albedo.rgb * rt.emission + smoothstep(0.0, 0.5, distGradient) * max(MINIMUM_LIGHT * vec3(0.4, 0.5, 1.0), query.diffuseIrradiance * rt.albedo.rgb));

            vec3 dir = sampleSunDir(shadowDir, vec2(randomValue(state), randomValue(state)));

            if (dot(rt.normal, dir) > -0.0001) {
                vec3 sunlight = lightTransmittance(shadowDir) * pdf * lightBrightness * evalCookBRDF(normalize(shadowDir + rt.normal * 0.03125), diffuseRay.direction, max(0.2, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);

                #if SUNLIGHT_GI_QUALITY == 0
                    sunlight *= smoothstep(0.0, 0.75, distGradient) * query.directIrradiance;
                #elif SUNLIGHT_GI_QUALITY == 1
                    if (randomValue(state) > smoothstep(0.5, 1.0, distGradient) && (clamp(query.directIrradiance, vec3(0.01), vec3(0.99)) == query.directIrradiance)) {
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
                radiance += rt.albedo.rgb * pdf * sampleSkyView(diffuseRay.direction);
            }
        #endif
    }

    radiance *= rcp(DIFFUSE_SAMPLES);

    imageStore(colorimg2, ivec2(gl_GlobalInvocationID.xy), vec4(radiance, 1.0));
}