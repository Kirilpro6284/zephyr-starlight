#version 430 compatibility

#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

layout (local_size_x = 64) in;

const ivec3 workGroups = ivec3(131072, 1, 1);

void main ()
{   
    voxelBuffer.voxels[gl_GlobalInvocationID.x] = Voxel(0u, END_MARKER);
}