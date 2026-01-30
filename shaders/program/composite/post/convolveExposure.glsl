#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

layout (local_size_x = 256) in;
const ivec3 workGroups = ivec3(1, 1, 1);

shared float averageLuminance[512];

void main ()
{
    for (int i = 0; i < 2; i++) {
        averageLuminance[gl_LocalInvocationID.x * 2 + i] = clamp(luminance(texelFetch(colortex10, ivec2(screenSize * R2(512 * (frameCounter & 7) + 2 * gl_LocalInvocationID.x + i)), 0).rgb), 0.0015, 0.04);
    }

    barrier();

    for (int i = 0; i < 9; i++) {
        uint index = ((2 * gl_LocalInvocationID.x) & ~((1 << (i + 1)) - 1)) + (1 << i) - 1;
        uint offset = 1 + (gl_LocalInvocationID.x & ((1 << i) - 1));

        averageLuminance[index + offset] += averageLuminance[index];

        barrier();
    }

    if (gl_LocalInvocationID.x == 0) renderState.globalLuminance = mix(renderState.globalLuminance, averageLuminance[511] / 512.0, ADAPTATION_SPEED);
}