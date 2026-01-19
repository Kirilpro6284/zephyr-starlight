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

// Vignette - Credits to Ippokratis -> https://www.shadertoy.com/view/lsKSWR

vec2 XY = gl_FragCoord.xy/screenSize.xy;

XY *= 1-XY.yx;

#if VIGNETTE==1.0
float vig = XY.x*XY.y * 15.0;
#elif VIGNETTE==0.0
float vig = 1.0;
#endif

vec4 vignette = min(vec4(vig), texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0));
    
    color = vignette;
}
