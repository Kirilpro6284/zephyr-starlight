#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/text.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

void main ()
{   

vec4 sharpen = vec4(0.0);

        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                float sampleWeight = exp(-length(vec2(x, y)));       
   sharpen += vec4(sampleWeight * texelFetch(colortex10, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb, sampleWeight);
            }
        }

vec4 SHARP = mix(texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0),sharpen, -SHARPENING);
    
    color = SHARP;
}
