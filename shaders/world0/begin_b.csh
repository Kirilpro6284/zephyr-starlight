#version 430 compatibility

#define HASH_SAMPLER shadowtex0

#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureData.glsl"

layout (local_size_x = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

void main ()
{   
    allTriangles.last = 0u;
    allTextures.last = 0u;
    allTextures.atlasHash = getTextureHash();
}