
    #include "/include/uniforms.glsl"
    #include "/include/checker.glsl"
    #include "/include/config.glsl"
    #include "/include/constants.glsl"
    #include "/include/common.glsl"
    #include "/include/pbr.glsl"
    #include "/include/main.glsl"
    #include "/include/textureSampling.glsl"
    #include "/include/spaceConversion.glsl"

    #include "/include/text.glsl"

    /* RENDERTARGETS: 2 */
    layout (location = 0) out vec4 filteredData;

    const vec2 kernel[6] = vec2[6](
        vec2(2.0, -2.0),
        vec2(2.0, 2.0),
        vec2(16.0, 0.0),
        vec2(0.0, 16.0),
        vec2(9.0, 9.0),
        vec2(-9.0, 9.0)
    );
    
    void main ()
    {   
        #ifdef REFLECTION_HALF_RES
            ivec2 texel = 2 * ivec2(gl_FragCoord.xy) + checker2x2(frameCounter);
        #else
            ivec2 texel = ivec2(gl_FragCoord.xy);
        #endif

        float depth = texelFetch(depthtex1, texel, 0).x;
        filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);

        if (depth == 1.0) return;
        
        DeferredMaterial mat = unpackMaterialData(texel);
        vec4 currData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);
        float currLogLum = log2(currData.r + currData.g + currData.b);

        if (mat.roughness > REFLECTION_ROUGHNESS_THRESHOLD || mat.roughness < 0.003) return;
        
        #if FILTER_PASS > 3
            float dither = blueNoise(gl_FragCoord.xy).r;
        #endif

        vec4 currPos = projectAndDivide(gbufferModelViewProjectionInverse, vec3((texel + 0.5) * texelSize, depth) * 2.0 - 1.0 - vec3(taaOffset, 0.0));

		vec2 sampleDir = kernel[FILTER_PASS ^ (frameCounter & 1)];
        float temporalWeight = (isnan(currData.w) ? 0.0 : clamp(currData.w, 0.0, 32.0)) * sqrt(REFLECTION_SAMPLES);
        vec4 samples = vec4(0.0);
        float weights = 0.0;

        #if FILTER_PASS < 4 
            vec2 samplePos = gl_FragCoord.xy - sampleDir;
            for (int i = 0; i < 5; i++, samplePos += 0.5 * sampleDir) 
        #else
            vec2 samplePos = gl_FragCoord.xy + (dither * 0.66 - 1.0) * sampleDir;
            for (int i = 0; i < 3; i++, samplePos += 0.66 * sampleDir) 
        #endif
        {
            #ifdef REFLECTION_HALF_RES
                ivec2 sampleCoord = 2 * ivec2(samplePos) + checker2x2(frameCounter);
            #else
                ivec2 sampleCoord = ivec2(samplePos);
            #endif

            if (clamp(sampleCoord, ivec2(0), ivec2(renderSize) - 1) == sampleCoord) {
                #ifdef REFLECTION_HALF_RES
                    vec4 sampleData = texelFetch(colortex2, ivec2(samplePos), 0);
                #else
                    vec4 sampleData = texelFetch(colortex2, sampleCoord, 0);
                #endif

                if (!any(isnan(sampleData))) {
                    vec3 sampleNormal = octDecode(unpackExp4x8(texelFetch(colortex9, sampleCoord, 0).r).zw);
                    float sampleRoughness = sqr(1.0 - unpackUnorm4x8(texelFetch(colortex8, sampleCoord, 0).g).g);
                    vec3 samplePos = screenToPlayerPos(vec3((sampleCoord + 0.5) * texelSize, texelFetch(depthtex1, sampleCoord, 0).x)).xyz;

                    float sampleWeight = exp(-temporalWeight * (
                          DENOISER_DEPTH_WEIGHT * abs(dot(mat.geoNormal, currPos.xyz - samplePos.xyz))
                        + DENOISER_NORMAL_WEIGHT * (-dot(sampleNormal, mat.textureNormal) * 0.5 + 0.5)
                        + abs(mat.roughness - sampleRoughness)
                        + 0.0065 * exp(-16.0 * mat.roughness) * length(sampleDir) * abs(log2(sampleData.r + sampleData.g + sampleData.b) - currLogLum)
                        )
                    );

                    weights += sampleWeight;
                    samples += sampleWeight * sampleData;
                }
            }
        }

        if (weights > 0.0008 && !any(isnan(filteredData))) filteredData = samples / weights;
        else filteredData = currData;
    }