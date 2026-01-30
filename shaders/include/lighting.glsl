#ifndef INCLUDE_LIGHTING
    #define INCLUDE_LIGHTING

    IrradianceSum sampleReflectionLighting (vec3 playerPos, vec3 normal, vec2 rand, float gradient)
    {
        vec3 sampleUv = playerToScreenPos(playerPos);
        ivec2 sampleTexel = ivec2(sampleUv.xy * renderSize);

        float weight = exp(-32.0 * lengthSquared(playerPos - screenToPlayerPos(vec3(sampleUv.xy, texelFetch(depthtex1, sampleTexel, 0).x)).xyz)) 
                     * (1.0 - smoothstep(gradient, 0.5, abs(sampleUv.x - 0.5))) 
                     * (1.0 - smoothstep(gradient, 0.5, abs(sampleUv.y - 0.5)));

        IrradianceSum screen = IrradianceSum(vec3(0.0), vec3(0.0));
        IrradianceSum cache  = IrradianceSum(vec3(0.0), vec3(0.0));

        #ifdef DIFFUSE_HALF_RES
            if (weight > 0.001) screen = IrradianceSum(texelFetch(colortex12, sampleTexel >> 1, 0).rgb, texelFetch(colortex5, sampleTexel, 0).rgb);
        #else
            if (weight > 0.001) screen = IrradianceSum(texelFetch(colortex12, sampleTexel, 0).rgb, texelFetch(colortex5, sampleTexel, 0).rgb);
        #endif

        if (weight < 0.999) {
            #ifdef SMOOTH_IRCACHE
                cache = irradianceCacheSmooth(playerPos, normal, 0u, rand);
            #else
                cache = irradianceCache(playerPos, normal, 0u);
            #endif
            
            #ifdef REFLECTION_PER_PIXEL_SHADOWS
                if (dot(normal, shadowDir) > -0.0001) cache.directIrradiance = TraceShadowRay(Ray(playerPos, sampleSunDir(shadowDir, rand)), 1024.0, true).rgb;
            #endif
        }

        return IrradianceSum(mix(cache.diffuseIrradiance / SECONDARY_GI_BRIGHTNESS, screen.diffuseIrradiance, weight), mix(cache.directIrradiance, screen.directIrradiance, weight));
    }

#endif