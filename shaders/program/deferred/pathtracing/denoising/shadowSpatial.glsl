
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

    const vec2 kernel[4] = vec2[4](
        vec2(2.0, -2.0),
        vec2(2.0, 2.0),
        vec2(-8.0, 8.0),
        vec2(8.0, 8.0)
    );

    void main ()
    {   
        ivec2 texel = ivec2(gl_FragCoord.xy);
        float depth = texelFetch(depthtex1, texel, 0).x;

        if (depth == 1.0) 
        {
            filteredData = texelFetch(colortex2, texel, 0);
            return;
        }
        
        #if FILTER_PASS > 1
            float dither = blueNoise(gl_FragCoord.xy).x;
        #endif

        vec4 currData = texelFetch(colortex2, texel, 0);
        float currLum = sqr(luminance(currData.rgb));
        #ifdef NORMAL_MAPPING
            vec3 geoNormal = octDecode(unpack2x8(texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).x >> 16u));
        #else
            vec3 geoNormal = octDecode(unpack2x8(texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).x));
        #endif
        vec4 currPos = screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, depth));

		vec2 sampleDir = kernel[FILTER_PASS];
        float temporalWeight = (isnan(currData.w) ? 0.0 : clamp(currData.w, 0.0, 8.0)) * sqrt(min(4, SHADOW_SAMPLES));
        vec4 samples = vec4(0.0);
        float weights = 0.0;

        #if FILTER_PASS < 2
            vec2 samplePos = gl_FragCoord.xy - sampleDir;
            for (int i = 0; i < 5; i++, samplePos += sampleDir * 0.5) 
        #else
            vec2 samplePos = gl_FragCoord.xy + (0.5 * dither - 1.0) * sampleDir;
            for (int i = 0; i < 4; i++, samplePos += sampleDir * 0.5) 
        #endif
        {
            ivec2 sampleCoord = ivec2(samplePos);

            if (clamp(sampleCoord, ivec2(0), ivec2(renderSize) - 1) != sampleCoord) continue;

            vec4 sampleData = texelFetch(colortex2, sampleCoord, 0);
            vec3 samplePos = screenToPlayerPos(vec3((sampleCoord + 0.5) * texelSize, texelFetch(depthtex1, sampleCoord, 0).x)).xyz;

            float sampleWeight = exp(-temporalWeight * (
                  DENOISER_DEPTH_WEIGHT * abs(dot(geoNormal, currPos.xyz - samplePos.xyz))
                + 0.25 * length(sampleDir) * pow(abs(sqr(luminance(sampleData.rgb)) - currLum), 0.2))
            );

            weights += sampleWeight;
            samples += sampleWeight * sampleData;
        }

        if (weights > 0.001 && !any(isnan(filteredData))) filteredData = samples / weights;
        else filteredData = currData;
    }