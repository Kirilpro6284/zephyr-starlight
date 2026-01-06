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

    vec2 uv = gl_FragCoord.xy / screenSize;

    color.r = mix(texture(colortex10, mix(vec2(0.5), uv, 500.0 / (500.0 + 2 * CHROMATIC_ABERRATION))).r, sharpen.r, -SHARPENING);
    color.g = mix(texture(colortex10, mix(vec2(0.5), uv, 500.0 / (500.0 + CHROMATIC_ABERRATION))).g, sharpen.g, -SHARPENING);
    color.b = mix(texture(colortex10, uv).b,sharpen.b, -SHARPENING);
    color.a = 0.0;
}