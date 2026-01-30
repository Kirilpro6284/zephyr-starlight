#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/checker.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/text.glsl"

#ifdef FULL_RES
    #ifdef TAA
        #define READ_FROM colortex6
    #else
        #define READ_FROM colortex7
    #endif
#endif

layout (rgba16f) uniform image2D SWAP_TO;
layout (local_size_x = 8, local_size_y = 8) in;

#if defined FULL_RES || TAA_UPSCALING_FACTOR == 100
    const vec2 workGroupsRender = vec2(1.0, 1.0);
#elif TAA_UPSCALING_FACTOR == 75
    const vec2 workGroupsRender = vec2(0.75, 0.75);
#elif TAA_UPSCALING_FACTOR == 50
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#endif

void main ()
{
    imageStore(SWAP_TO, ivec2(gl_GlobalInvocationID.xy), texelFetch(READ_FROM, ivec2(gl_GlobalInvocationID.xy), 0));
}