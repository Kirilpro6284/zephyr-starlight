#ifndef INCLUDE_IRCACHE
    #define INCLUDE_IRCACHE

    uint packCachePos (ivec4 pos) 
    {
        pos &= ivec4(511, 511, 511, 31);
        return (pos.x << 23) | (pos.y << 14) | (pos.z << 5) | (pos.w);
    }

    ivec4 unpackCachePos (uint pack)
    {
        ivec4 result = ivec4(pack >> 23, pack >> 14, pack >> 5, pack) & ivec4(511, 511, 511, 31);
        return ((result - ivec4((cameraPositionInt >> max(0, result.w - 2)) << max(0, 2 - result.w), 0) + ivec4(256, 256, 256, 0)) & ivec4(511, 511, 511, 31)) + ivec4((cameraPositionInt >> max(0, result.w - 2)) << max(0, 2 - result.w), 0) - ivec4(256, 256, 256, 0);
    }

    uint hashCachePos (ivec4 pos)
    {
        return (uint(pos.x) * 73856093) ^ (uint(pos.y) * 19349663) ^ (uint(pos.z) * 83492791) ^ (uint(pos.w) * 51655181);
    }

    uint selectLOD (vec3 pos)
    {
        return uint(clamp(0.5 * log2(lengthSquared(pos)) - log2(IRCACHE_CASCADE_RES / 16.0), 0.0, 15.0));
    }

    IrradianceSum irradianceCache (vec3 pos, vec3 normal, uint rank)
    {   
        uint lod = selectLOD(pos);
        ivec4 voxelPos = ivec4(((cameraPositionInt >> max(0, int(lod) - 2)) << max(0, 2 - int(lod))) + ivec3(floor(exp2(2.0 - float(lod)) * (vec3(cameraPositionInt & ((1u << max(0, int(lod) - 2)) - 1u)) + cameraPositionFract + pos) + normal * 0.475)), lod);

        uint packedPos = packCachePos(voxelPos);
        uint hashedPos = hashCachePos(voxelPos);

        if (packedPos == 0u) return IrradianceSum(vec3(0.0), vec3(0.0));

        uvec3 packedOrigin = uvec3(256.0 * fract(exp2(2.0 - float(lod)) * (cameraPosition + pos) + normal * 0.475));
        uvec2 packedNormal = uvec2(14.0 * octEncode(normal) + 0.5);

        for (uint attempt = 0u; attempt < uint(IRCACHE_PROBE_ATTEMPTS); attempt++)
        {   
            uint index = (hashedPos + attempt * attempt) % IRCACHE_VOXEL_ARRAY_SIZE;

            if (ircache.entries[index].packedPos == packedPos && ircache.entries[index].radiance != IRCACHE_INV_MARKER) {
                if (atomicMin(ircache.entries[index].rank, rank + 1u) >= rank + 1u) {
                    if (atomicExchange(ircache.entries[index].lastFrame, frameCounter) != frameCounter) {
                        ircache.entries[index].traceOrigin = (packedOrigin.x << 24u) | (packedOrigin.y << 16u) | (packedOrigin.z << 8u) | (packedNormal.x << 4u) | (packedNormal.y);
                    }
                }

                return IrradianceSum(SECONDARY_GI_BRIGHTNESS * unpackHalf4x16(ircache.entries[index].radiance).rgb, unpack3x10(ircache.entries[index].direct));
            }
        }

        for (uint attempt = 0u; attempt < uint(IRCACHE_PROBE_ATTEMPTS); attempt++)
        {   
            uint index = (hashedPos + attempt * attempt) % IRCACHE_VOXEL_ARRAY_SIZE;

            if (atomicCompSwap(ircache.entries[index].packedPos, 0u, packedPos) == 0u) {
                ircache.entries[index].traceOrigin = (packedOrigin.x << 24u) | (packedOrigin.y << 16u) | (packedOrigin.z << 8u) | (packedNormal.x << 4u) | (packedNormal.y);
                ircache.entries[index].rank = rank + 1u;
                ircache.entries[index].lastFrame = frameCounter;
                break;
            }
        }

        return IrradianceSum(vec3(0.0), vec3(0.0));
    }

    IrradianceSum irradianceCacheSmooth (vec3 pos, vec3 normal, uint rank, vec2 rand)
    {
        float scale = exp2(float(selectLOD(pos)) - 2.0);

        float theta = TWO_PI * rand.x;
        vec3 dir = tbnNormal(normal) * vec3(scale * (1.0 - sqrt(1.0 - sqrt(rand.y))) * vec2(sin(theta), cos(theta)), 0.0);

        return irradianceCache(pos + dir * min(1.0, TraceGenericRay(Ray(pos + normal * 0.003, dir), 1.0, false, false).dist - 0.001), normal, rank);
    }

    IrradianceSum irradianceCacheView (vec3 pos, vec3 normal)
    {   
        uint lod = selectLOD(pos);
        ivec4 voxelPos = ivec4(((cameraPositionInt >> max(0, int(lod) - 2)) << max(0, 2 - int(lod))) + ivec3(floor(exp2(2.0 - float(lod)) * (vec3(cameraPositionInt & ((1u << max(0, int(lod) - 2)) - 1u)) + cameraPositionFract + pos) + normal * 0.475)), lod);

        uint hashedPos = hashCachePos(voxelPos);
        uint packedPos = packCachePos(voxelPos);

        for (uint attempt = 0u; attempt < uint(IRCACHE_PROBE_ATTEMPTS); attempt++)
        {   
            uint index = (hashedPos + attempt * attempt) % IRCACHE_VOXEL_ARRAY_SIZE;

            if (ircache.entries[index].packedPos == packedPos && ircache.entries[index].radiance != uvec2(0u)) {
                return IrradianceSum(unpackHalf4x16(ircache.entries[index].radiance).rgb, unpack3x10(ircache.entries[index].direct));
            }
        }

        return IrradianceSum(vec3(0.0), vec3(0.0));
    }

#endif