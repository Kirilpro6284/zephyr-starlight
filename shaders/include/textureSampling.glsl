#ifndef INCLUDE_TEXTURE_SAMPLING
    #define INCLUDE_TEXTURE_SAMPLING
    
    #include "/include/checker.glsl"

    #ifdef INDIRECT_LIGHTING_RES
        vec4 sampleHistory (in sampler2D tex, in vec3 currPos, in vec3 normal, in vec2 uv, in vec2 texSize)
        {   
            vec2 texel = ((uv * texSize
                #if INDIRECT_LIGHTING_RES == 2
                    - checker2x2(frameCounter - 1)
                #elif INDIRECT_LIGHTING_RES == 4
                    - checker4x4(frameCounter - 1)
                #endif
            ) - 0.5) * rcp(INDIRECT_LIGHTING_RES);

            vec4 samples = vec4(0.0);
            float weights = 0.0;

            for (int i = 0; i < 4; i++) {
                ivec2 offset = ivec2(i & 1, i >> 1);
                ivec2 sampleCoord = ivec2(texel) + offset;
                ivec2 sampleTexel = sampleCoord * INDIRECT_LIGHTING_RES
                    #if INDIRECT_LIGHTING_RES == 2
                        + checker2x2(frameCounter - 1)
                    #elif INDIRECT_LIGHTING_RES == 4
                        + checker4x4(frameCounter - 1)
                    #endif
                    ;
                
                if (clamp(sampleTexel, ivec2(0), ivec2(renderSize) - 1) != sampleTexel) continue;

                vec4 sampleData = texelFetch(tex, sampleCoord, 0);

                float sampleWeight = exp(
                    -64.0 * length(normal * dot(normal, currPos + cameraVelocity) - texelFetch(colortex0, sampleTexel, 0).rgb)
                )
                    * (1.0 - abs(texel.x - floor(texel.x + offset.x))) 
                    * (1.0 - abs(texel.y - floor(texel.y + offset.y)));

                samples += sampleWeight * sampleData;
                weights += sampleWeight;
            }

            if (weights > 0.0001 && !any(isnan(samples))) return samples / weights;
            else return vec4(0.0, 0.0, 0.0, 1.0);
        }

        vec3 upsampleRadiance (vec3 currPos, vec3 geoNormal, vec3 textureNormal)
        {   
            #if INDIRECT_LIGHTING_RES == 1
                return texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0).rgb;
            #else
                vec2 uv = gl_FragCoord.xy * rcp(INDIRECT_LIGHTING_RES) - 0.5;
                vec3 radiance = vec3(0.0);
                float weights = 0.0;

                for (int i = 0; i < 4; i++) {
                    ivec2 offset = ivec2(i & 1, i >> 1);
                    ivec2 sampleCoord = ivec2(uv) + offset;
                    ivec2 texel = INDIRECT_LIGHTING_RES * sampleCoord 
                        #if INDIRECT_LIGHTING_RES == 2
                            + checker2x2(frameCounter)
                        #elif INDIRECT_LIGHTING_RES == 4
                            + checker4x4(frameCounter)
                        #endif
                    ;

                    vec3 sampleNormal = octDecode(unpack2x8(texelFetch(colortex9, texel, 0).x & 65535u));
                    vec3 sampleData = texelFetch(colortex2, sampleCoord, 0).rgb;

                    float sampleWeight = exp(-1.0 * (
                        + 16.0 * abs(dot(currPos.xyz - screenToPlayerPos(vec3(vec2(texel + 0.5) * texelSize, texelFetch(depthtex1, texel, 0).x)).xyz, geoNormal))
                        + 4.0  * (-dot(sampleNormal, textureNormal) * 0.5 + 0.5)
                    ))
                        * (1.0 - abs(uv.x - floor(uv.x + offset.x))) 
                        * (1.0 - abs(uv.y - floor(uv.y + offset.y)));

                    radiance += sampleWeight * sampleData;
                    weights += sampleWeight;
                }

                if (weights > 0.0001 && !any(isnan(radiance))) return radiance / weights;
                else return vec3(0.0);
            #endif
        }
    #endif

    vec4 cubic (float v)
    {
        vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
        vec4 s = n * n * n;
        float x = s.x;
        float y = s.y - 4.0 * s.x;
        float z = s.z - 4.0 * s.y + 6.0 * s.x;
        float w = 6.0 - x - y - z;
        return vec4(x, y, z, w) * rcp(6.0);
    }

    vec4 texBicubic (sampler2D sampler, vec2 texCoords, vec2 texSize)
    {
        vec2 invTexSize = 1.0 / texSize;
   
        texCoords = texCoords * texSize - 0.5;

        vec2 fxy = fract(texCoords);
        texCoords -= fxy;

        vec4 xcubic = cubic(fxy.x);
        vec4 ycubic = cubic(fxy.y);

        vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;
    
        vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
        vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;
    
        offset *= invTexSize.xxyy;
    
        vec4 sample0 = texture(sampler, offset.xz);
        vec4 sample1 = texture(sampler, offset.yz);
        vec4 sample2 = texture(sampler, offset.xw);
        vec4 sample3 = texture(sampler, offset.yw);

        float sx = s.x / (s.x + s.y);
        float sy = s.z / (s.z + s.w);

        return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx),sy);
    }

#endif