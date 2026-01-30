#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"

layout (
    local_size_x = 4, 
    local_size_y = 4, 
    local_size_z = 4
) in;

#if OCTREE_PASS == 4
    #if VOXELIZATION_DISTANCE == 32
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 64
        const ivec3 workGroups = ivec3(2, 2, 2);
    #elif VOXELIZATION_DISTANCE == 128
        const ivec3 workGroups = ivec3(4, 3, 4);
    #elif VOXELIZATION_DISTANCE == 192
        const ivec3 workGroups = ivec3(6, 4, 6);
    #elif VOXELIZATION_DISTANCE == 256
        const ivec3 workGroups = ivec3(8, 4, 8);
    #elif VOXELIZATION_DISTANCE == 512
        const ivec3 workGroups = ivec3(16, 4, 16);
    #endif
#elif OCTREE_PASS == 5
    #if VOXELIZATION_DISTANCE == 32
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 64
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 128
        const ivec3 workGroups = ivec3(2, 2, 2);
    #elif VOXELIZATION_DISTANCE == 192
        const ivec3 workGroups = ivec3(3, 2, 3);
    #elif VOXELIZATION_DISTANCE == 256
        const ivec3 workGroups = ivec3(4, 2, 4);
    #elif VOXELIZATION_DISTANCE == 512
        const ivec3 workGroups = ivec3(8, 2, 8);
    #endif
#elif OCTREE_PASS == 6
    #if VOXELIZATION_DISTANCE == 32
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 64
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 128
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 192
        const ivec3 workGroups = ivec3(2, 1, 2);
    #elif VOXELIZATION_DISTANCE == 256
        const ivec3 workGroups = ivec3(2, 1, 2);
    #elif VOXELIZATION_DISTANCE == 512
        const ivec3 workGroups = ivec3(4, 1, 4);
    #endif
#else
    #if VOXELIZATION_DISTANCE == 32
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 64
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 128
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 192
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 256
        const ivec3 workGroups = ivec3(1, 1, 1);
    #elif VOXELIZATION_DISTANCE == 512
        const ivec3 workGroups = ivec3(2, 1, 2);
    #endif
#endif

void main ()
{
    ivec3 voxel = ivec3(gl_GlobalInvocationID.xyz) + ivec3(voxelVolumeSize.x >> OCTREE_PASS, 0, 0);
    uint result = 0u;

    if (any(greaterThanEqual(gl_GlobalInvocationID.xyz, voxelVolumeSize >> OCTREE_PASS))) return;
    
    for (int x = voxel.x << 1; x <= (voxel.x << 1) + 1; x++)
        for (int y = voxel.y << 1; y <= (voxel.y << 1) + 1; y++)
            for (int z = voxel.z << 1; z <= (voxel.z << 1) + 1; z++)
                result |= imageLoad(voxelBufferLod, ivec3(x, y, z)).x;

    imageStore(voxelBufferLod, voxel, uvec4(result, 0u, 0u, 1u));
}