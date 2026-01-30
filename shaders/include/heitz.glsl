#ifndef INCLUDE_HEITZ
    #define INCLUDE_HEITZ

    float heitzSample (ivec2 pixel, int sampleIndex, int sampleDimension)
    {
    
        // wrap arguments
        pixel = pixel & 127;
        sampleIndex = sampleIndex & 255;
        sampleDimension = sampleDimension & 255;

        // xor index based on optimized ranking
        int rankedSampleIndex = sampleIndex ^ heitzLayout.data[heitzOffsets[2] + sampleDimension + (pixel.x + pixel.y * 128) * 8];

        // fetch value in sequence
        int value = heitzLayout.data[heitzOffsets[0] + sampleDimension + rankedSampleIndex * 256];

        // If the dimension is optimized, xor sequence value based on optimized scrambling
        value = value ^ heitzLayout.data[heitzOffsets[1] + (sampleDimension % 8) + (pixel.x + pixel.y * 128) * 8];

        // convert to float and return
        return (value + R1(frameCounter)) / 256.0;
        
       // uint state = pixel.x + pixel.y * 8192 + 16777216 * sampleIndex + 268435456 * sampleDimension;
       // return randomValue(state);

    }

    vec3 randomDirBlueNoise (ivec2 pixel, int i)
    {
        float a0 = heitzSample(pixel, DIFFUSE_SAMPLES * frameCounter + i, 0) * 2.0 - 1.0;
        float a1 = heitzSample(pixel, DIFFUSE_SAMPLES * frameCounter + i, 1) * TWO_PI;

        float t = sqrt(1.0 - a0 * a0);

        return vec3(t * cos(a1), a0, t * sin(a1));
    }

    vec3 randomHemisphereDirBlueNoise (ivec2 pixel, vec3 normal, int i)
    {   
        vec3 dir = randomDirBlueNoise(pixel, i);
        return dir * sign(dot(dir, normal));
    }

#endif