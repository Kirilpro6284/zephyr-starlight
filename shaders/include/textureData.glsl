#ifndef INCLUDE_TEXTURE_DATA
    #define INCLUDE_TEXTURE_DATA

    #ifdef HASH_SAMPLER
        uint getTextureHash (void)
        {
            uint result = 0x59E6FD94u;
            uvec2 size = textureSize(HASH_SAMPLER, 0);

            for (int i = 3; i < TEXTURE_HASH_ENTRIES + 3; i++) {
                uint state = packUnorm4x8(R1(i) * texelFetch(HASH_SAMPLER, ivec2(R2(i) * size), 0)) * 747796405 + 2891336453;
                result ^= ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
            }

            return result;
        }
    #endif

    bool addTexture (uint hash, in uvec2 size, out uint keyIndex, out uint texOffset)
    {
        if (hash == allTextures.atlasHash) {
            keyIndex = 4095u;
            return false;
        }

        uvec2 logSize = uvec2(ceil(log2(vec2(size) - 0.5)));
        size = uvec2(1) << logSize;

        for (uint attempt = 0u; attempt < 4u; attempt++) {
            uint index = (hash + attempt * attempt) & 1023u;
            uint state = atomicCompSwap(allTextures.keys[index].hash, 0u, hash);     

            if (state == 0u) {
                texOffset = atomicAdd(allTextures.last, size.x * size.y) & 16777215u;
                allTextures.keys[index].bounds = (logSize.x << 28u) | (logSize.y << 24u) | texOffset;
                keyIndex = index;
                return true;
            } else if (state == hash) {
                keyIndex = index;
                return false;
            }
        }

        keyIndex = hash & 4095u;

        return false;
    }
#endif