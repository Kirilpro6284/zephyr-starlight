#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/octree.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/ircache.glsl"
#include "/include/brdf.glsl"
#include "/include/atmosphere.glsl"

layout (local_size_x = 64) in;

#if IRCACHE_UPDATE_INTERVAL == 1
    #if IRCACHE_VOXEL_ARRAY_SIZE == 32768
        const ivec3 workGroups = ivec3(512, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
        const ivec3 workGroups = ivec3(768, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
        const ivec3 workGroups = ivec3(1024, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
        const ivec3 workGroups = ivec3(1536, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
        const ivec3 workGroups = ivec3(2048, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
        const ivec3 workGroups = ivec3(4096, 1, 1);
    #endif
#elif IRCACHE_UPDATE_INTERVAL == 2
    #if IRCACHE_VOXEL_ARRAY_SIZE == 32768
        const ivec3 workGroups = ivec3(256, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
        const ivec3 workGroups = ivec3(384, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
        const ivec3 workGroups = ivec3(512, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
        const ivec3 workGroups = ivec3(768, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
        const ivec3 workGroups = ivec3(1024, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
        const ivec3 workGroups = ivec3(2048, 1, 1);
    #endif
#elif IRCACHE_UPDATE_INTERVAL == 4
    #if IRCACHE_VOXEL_ARRAY_SIZE == 32768
        const ivec3 workGroups = ivec3(128, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
        const ivec3 workGroups = ivec3(192, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
        const ivec3 workGroups = ivec3(256, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
        const ivec3 workGroups = ivec3(384, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
        const ivec3 workGroups = ivec3(512, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
        const ivec3 workGroups = ivec3(1024, 1, 1);
    #endif
#elif IRCACHE_UPDATE_INTERVAL == 8
    #if IRCACHE_VOXEL_ARRAY_SIZE == 32768
        const ivec3 workGroups = ivec3(64, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
        const ivec3 workGroups = ivec3(96, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
        const ivec3 workGroups = ivec3(128, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
        const ivec3 workGroups = ivec3(192, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
        const ivec3 workGroups = ivec3(256, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
        const ivec3 workGroups = ivec3(512, 1, 1);
    #endif
#elif IRCACHE_UPDATE_INTERVAL == 16
    #if IRCACHE_VOXEL_ARRAY_SIZE == 32768
        const ivec3 workGroups = ivec3(32, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
        const ivec3 workGroups = ivec3(48, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
        const ivec3 workGroups = ivec3(64, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
        const ivec3 workGroups = ivec3(96, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
        const ivec3 workGroups = ivec3(128, 1, 1);
    #elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
        const ivec3 workGroups = ivec3(256, 1, 1);
    #endif
#endif

void main ()
{   
    uint index = gl_GlobalInvocationID.x + (frameCounter % IRCACHE_UPDATE_INTERVAL) * (IRCACHE_VOXEL_ARRAY_SIZE / IRCACHE_UPDATE_INTERVAL);

    IrcacheVoxel voxel = ircache.entries[index];
    uint state = gl_GlobalInvocationID.x + (frameCounter & 2047u) * IRCACHE_VOXEL_ARRAY_SIZE / IRCACHE_UPDATE_INTERVAL;

    if (voxel.packedPos == 0u || voxel.traceOrigin == 0u || frameCounter - voxel.lastFrame > 32u || voxel.lastFrame > frameCounter) {
        ircache.entries[index].traceOrigin = 0u;
        ircache.entries[index].rank = 128u;
        ircache.entries[index].lastFrame = 0u;
        ircache.entries[index].packedPos = 0u;
        ircache.entries[index].direct = 0u;
        ircache.entries[index].radiance = IRCACHE_INV_MARKER;
        return;
    }

    ivec4 voxelPos = unpackCachePos(voxel.packedPos);

    vec3 normal = octDecode(saturate(vec2(uvec2(voxel.traceOrigin >> 4u, voxel.traceOrigin) & 15u) * rcp(14.0)));
    vec3 playerPos = ((voxelPos.xyz << voxelPos.w) - (cameraPositionInt << 2)) / 4.0 - cameraPositionFract + exp2(voxelPos.w - 2.0) * ((uvec3(voxel.traceOrigin >> 24u, voxel.traceOrigin >> 16u, voxel.traceOrigin >> 8u) & 255u) * rcp(256.0) + rcp(512.0) - normal * 0.47);

    Ray ray; 
    
    ray.origin = playerPos;

    vec4 radiance = vec4(0.0);

    for (int i = 0; i < IRCACHE_SAMPLES; i++) {
        ray.direction = randomHemisphereDir(normal, state);

        RayHitInfo rt = TraceGenericRay(ray, IRCACHE_MAX_RT_DISTANCE, true, true);
        float cosTheta = dot(normal, ray.direction);

        if (rt.hit) {
            IrradianceSum query = irradianceCache(0.999 * (ray.origin + ray.direction * rt.dist), rt.normal, voxel.rank);
            radiance.rgb += cosTheta * (rt.albedo.rgb * (rt.emission + query.diffuseIrradiance) + lightTransmittance(sunDir) * lightBrightness * query.directIrradiance * evalCookBRDF(sunDir, ray.direction, max(0.2, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0));
        } 
        #ifndef DIMENSION_END
            else {
                radiance.rgb += cosTheta * calcSkyColor(ray.direction, sunDir, randomValue(state));
            }
        #endif
    }
    
    radiance.rgb *= rcp(IRCACHE_SAMPLES);

    if (any(isnan(radiance))) radiance = vec4(0.0);

    vec3 direct;

    if (dot(normal, shadowDir) > 0.0) direct = TraceShadowRay(Ray(ray.origin, sampleSunDir(shadowDir, vec2(randomValue(state), randomValue(state)))), 1024.0, true).rgb;
    else direct = voxel.radiance == IRCACHE_INV_MARKER ? vec3(0.0) : unpack3x10(voxel.direct);

    vec4 r = unpackHalf4x16(voxel.radiance);

    ircache.entries[index].direct = pack3x10(mix(unpack3x10(voxel.direct), direct, (r == vec4(-1.0)) ? 1.0 : rcp(max(16.0, 0.25 * frameRate))));
    ircache.entries[index].radiance = packHalf4x16(any(isnan(r)) ? vec4(0.0) : (r == vec4(-1.0)) ? radiance : mix(r, radiance, rcp(max(128.0, 2.0 * frameRate))));
}