#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

void main ()
{   
    vec2 uv = gl_FragCoord.xy / screenSize;

    vec2 sampleDir = (mix(vec2(0.5), uv, 500.0 / (500.0 + CHROMATIC_ABERRATION)) - uv) * rcp(CHROMATIC_ABERRATION_SAMPLES);
    vec2 samplePos = uv + sampleDir * blueNoise(gl_FragCoord.xy).r;

    vec3 integratedData = vec3(0.0);

    for (int i = 0; i < CHROMATIC_ABERRATION_SAMPLES; i++, samplePos += sampleDir)
    {
        integratedData += texture(colortex10, samplePos).rgb;
    }
    
    color = vec4(integratedData * rcp(CHROMATIC_ABERRATION_SAMPLES), 1.0);
}