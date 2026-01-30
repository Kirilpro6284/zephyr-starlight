
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

    const vec2 kernel[8] = vec2[8](
        vec2(-2.0, 2.0),
        vec2(2.0, 2.0),
        vec2(0.0, 32.0),
        vec2(32.0, 0.0),
        vec2(-8.0, 8.0),
        vec2(8.0, 8.0),
        vec2(-16.0, 16.0),
        vec2(16.0, 16.0)
    );

    void main ()
    {   
        #ifdef DIFFUSE_HALF_RES
            ivec2 texel = 2 * ivec2(gl_FragCoord.xy) + checker2x2(frameCounter);
        #else
            ivec2 texel = ivec2(gl_FragCoord.xy);
        #endif
        
        float depth = texelFetch(depthtex1, texel, 0).x;

        if (depth == 1.0) 
        {
            filteredData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);
            return;
        }
        
        uint normalData = texelFetch(colortex9, texel, 0).r;

        vec4 currData = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0);
        float currLogLum = log2(currData.r + currData.g + currData.b);
        vec3 currNormal = octDecode(unpackExp4x8(normalData).zw);
        vec4 currPos = screenToPlayerPos(vec3((texel + 0.5) * texelSize, depth));

        #ifdef NORMAL_MAPPING
            vec3 geoNormal = octDecode(unpackExp4x8(normalData).xy);
        #else
            vec3 geoNormal = currNormal;
        #endif

        #if FILTER_PASS > 3
            float dither = blueNoise(gl_FragCoord.xy).x;
        #endif

		vec2 sampleDir = kernel[FILTER_PASS ^ (frameCounter & 1)];
        float temporalWeight = (isnan(currData.w) ? 0.0 : clamp(currData.w, 0.0, 64.0)) * sqrt(DIFFUSE_SAMPLES) * 0.5;
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
            #ifdef DIFFUSE_HALF_RES
                ivec2 sampleCoord = 2 * ivec2(samplePos) + checker2x2(frameCounter);
            #else
                ivec2 sampleCoord = ivec2(samplePos);
            #endif

            if (clamp(sampleCoord, ivec2(0), ivec2(renderSize) - 1) == sampleCoord) {
                #ifdef DIFFUSE_HALF_RES
                    vec4 sampleData = texelFetch(colortex2, ivec2(samplePos), 0);
                #else
                    vec4 sampleData = texelFetch(colortex2, sampleCoord, 0);
                #endif

                if (!any(isnan(sampleData))) {
                    vec3 sampleNormal = octDecode(unpack2x8(texelFetch(colortex9, sampleCoord, 0).x & 65535u));
                    vec3 posDiff = currPos.xyz - screenToPlayerPos(vec3((sampleCoord + 0.5) * texelSize, texelFetch(depthtex1, sampleCoord, 0).x)).xyz;

                    float sampleWeight = exp(-temporalWeight * (
                          DENOISER_NORMAL_WEIGHT * (-dot(sampleNormal, currNormal) * 0.5 + 0.5)
                        + DENOISER_DEPTH_WEIGHT * abs(dot(geoNormal, posDiff))
                        + 0.005 * DENOISER_SHARPENING * length(sampleDir) * abs(log2(sampleData.r + sampleData.g + sampleData.b) - currLogLum)
                        )
                    );

                    weights += sampleWeight;
                    samples += sampleWeight * sampleData;
                }
            }
        }

        if (weights > (0.00016 * temporalWeight)) filteredData = samples / weights;
        else filteredData = currData;
    }