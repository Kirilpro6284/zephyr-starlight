// Based on https://www.shadertoy.com/view/tdSSWz

#ifndef INCLUDE_WAVE
    #define INCLUDE_WAVE

    #define waterTransmittance(dist) exp(-vec3(WATER_ABSORPTION_R, WATER_ABSORPTION_G, WATER_ABSORPTION_B) * (dist))

    float noise (vec2 coord, float scale)
    {
        vec2 texel = coord * scale;

        float result = 0.0;

        for (int i = 0; i < 4; i++) {
            ivec2 offset = ivec2(i & 1, i >> 1);
            ivec2 sampleCoord = (ivec2(texel) + offset) & 65535;

            uint state = uint(sampleCoord.x) + 65536u * uint(sampleCoord.y);
            float sampleData = randomValue(state);

            result += sampleData * smoothstep(0.0, 1.0, 1.0 - abs(texel.x - floor(texel.x + offset.x))) 
                                 * smoothstep(0.0, 1.0, 1.0 - abs(texel.y - floor(texel.y + offset.y)));
        }

        return result;
    }

    #define NOISE_OCTAVES 4

    float fbm (vec2 coord)
    {
        float result = 0.0;

        for (int i = 0; i < NOISE_OCTAVES; i++) {
            result += exp2(-float(i)) * noise(coord, WATER_WAVE_FREQUENCY * exp2(float(i) * 0.7));
        }
        
        return result * 0.5;
    }

    float getWaterWaveHeight (vec3 worldPos)
    {
        vec3 coord = vec3(worldPos.xz, frameTimeCounter * WATER_WAVE_SPEED);

        float f1 = fbm(mat3x2(0.5, 1.6, 0.2, -0.9, 0.5, 0.6) * coord);
        float f2 = fbm(mat3x2(0.3, 1.8, -0.6, 0.9, -1.0, 0.1) * coord);

        return sqr(mix(f1, f2, 0.5));
    }

    vec3 getWaterWaveNormal (vec3 worldPos)
    {
        vec3 offsetCoord = worldPos + vec3(WATER_WAVE_SHARPNESS * getWaterWaveHeight(worldPos) / WATER_WAVE_FREQUENCY, 0.0, 0.0);

        float centerHeight = getWaterWaveHeight(offsetCoord);

        float dfdx = getWaterWaveHeight(offsetCoord + vec3(0.0005, 0.0, 0.0));
        float dfdz = getWaterWaveHeight(offsetCoord + vec3(0.0, 0.0, 0.0005));

        return vec3(rcp(0.0005) * (vec2(dfdx, dfdz) - centerHeight), rcp(WATER_WAVE_HEIGHT));
    }

    #ifndef STAGE_BEGIN
        vec3 getWaterWaveNormalTex (vec3 worldPos)
        {
            vec2 uv = fract(worldPos.xz * rcp(32.0) + 0.5);
            return vec3(texture(texCaustic, uv).rg, rcp(WATER_WAVE_HEIGHT));
        }
    #endif
    
#endif