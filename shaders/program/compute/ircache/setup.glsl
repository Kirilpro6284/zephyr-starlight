#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

layout (local_size_x = 64) in;

#if IRCACHE_VOXEL_ARRAY_SIZE == 32768
    const ivec3 workGroups = ivec3(512, 1, 1);
#elif IRCACHE_VOXEL_ARRAY_SIZE == 49152
    const ivec3 workGroups = ivec3(768, 1, 1);
#elif IRCACHE_VOXEL_ARRAY_SIZE == 65536
    const ivec3 workGroups = ivec3(1024, 1, 1);
#elif IRCACHE_VOXEL_ARRAY_SIZE == 98304
    const ivec3 workGroups = ivec3(1536, 1, 1);
#elif IRCACHE_VOXEL_ARRAY_SIZE == 131072
    const ivec3 workGroups = ivec3(2048, 1, 1);
#elif IRCACHE_VOXEL_ARRAY_SIZE == 262144
    const ivec3 workGroups = ivec3(4096, 1, 1);
#endif

void main ()
{   
    ircache.entries[gl_GlobalInvocationID.x] = IrcacheVoxel(0u, 0u, 128u, 0u, 0u, 0u, IRCACHE_INV_MARKER);
}