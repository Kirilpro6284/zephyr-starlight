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

// Credits to spleenstealer --> https://www.shadertoy.com/view/dsGGWW

vec2 uv = gl_FragCoord.xy*2./screenSize.xy-vec2(1.);
  float scaling = 1.5;
    float d=length(uv/scaling);
    float z = sqrt(1.0 - d * d);
    float r = atan(d, z) / 3.14159;
    float phi = atan(uv.y, uv.x);

 #if FISHEYE==1.0  
    uv = screenSize*(vec2(r*cos(phi)+.5,r*sin(phi)+.5)*scaling)-(screenSize.xy/4.0-vec2(1.));
#else
uv = gl_FragCoord.xy;
#endif

vec4 screen = texelFetch(colortex10, ivec2(uv), 0);

vec4 fisheye = screen;
    
    color = fisheye;
}