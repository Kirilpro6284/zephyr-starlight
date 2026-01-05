#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/brdf.glsl"
#include "/include/text.glsl"
#include "/include/atmosphere.glsl"
#include "/include/spaceConversion.glsl"

layout (location = 0) out vec4 color;

vec3 ACESFilm(vec3 x)
{
return clamp((x*(CONTRAST*x+SHADOW_OFFSET))/(x*(HIGHLIGHT_SCALE*x+MIDTONE_SLOPE)+TOE_OFFSET),0.0,1.0);
}

void main ()
{   
    #ifdef RT_TRACING_EYE
        color.rgb = pow(TraceRay(Ray(vec3(0.0), normalize(screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 1.0)).xyz)), 1024.0, true, true).albedo.rgb, vec3(1.0 / 2.2));
        color.a = 1.0;
    #else
        color = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0);
        color.rgb = mix(vec3(luminance(color.rgb)), color.rgb, SATURATION);

        vec4 sharpen = vec4(0.0);

        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                float sampleWeight = exp(-length(vec2(x, y)));

                sharpen += vec4(sampleWeight * texelFetch(colortex10, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb, sampleWeight);
            }
        }

        #ifdef DYNAMIC_EXPOSURE
            float exposure = EXPOSURE_OFFSET + 4.0 *exp(0.005 / renderState.globalLuminance);
        #else
            float exposure = MANUAL_EXPOSURE;
        #endif

        color.rgb = mix(pow(ACESFilm(1.0 - exp(-exposure * color.rgb)).rgb, vec3(1.0 / 2.2)), pow(1.0 - exp(-exposure * sharpen.rgb / sharpen.w), vec3(1.0 / 2.2)), -SHARPENING) + blueNoise(gl_FragCoord.xy) * rcp(255.0) - rcp(510.0);
        color.a = 1.0;
    #endif
/*
    #define FONT_SIZE 2 // [1 2 3 4 5 6 7 8]
	
	beginText(ivec2(gl_FragCoord.xy / FONT_SIZE), ivec2(20, viewHeight / FONT_SIZE - 20));
	text.fgCol = vec4(vec3(1.0), 1.0);
	text.bgCol = vec4(vec3(0.0), 0.0);
	
    printIvec3(imageSize(voxelBufferLod));

	endText(color.rgb);
*/
}
