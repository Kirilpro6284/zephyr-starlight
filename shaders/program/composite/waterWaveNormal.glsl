#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/octree.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/spaceConversion.glsl"

layout (rg32ui) uniform uimage2D colorimg1;
layout (local_size_x = 8, local_size_y = 8) in;

#if TAA_UPSCALING_FACTOR == 100
    const vec2 workGroupsRender = vec2(1.0, 1.0);
#elif TAA_UPSCALING_FACTOR == 75
    const vec2 workGroupsRender = vec2(0.75, 0.75);
#elif TAA_UPSCALING_FACTOR == 50
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#endif

void main ()
{
    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = texelSize * (vec2(texel) + 0.5);

    float depth        = texelFetch(depthtex0, texel, 0).r;
    float depth1       = texelFetch(depthtex1, texel, 0).r;

    if (depth1 == depth) return;

    TranslucentMaterial mat = unpackTranslucentMaterial(texel);

    if (mat.blockId != 10100) return;

    vec3 playerPos = screenToPlayerPos(vec3(uv, depth)).xyz;

    vec3 worldPos = cameraPosition + playerPos;
    vec3 normal = tbnNormal(mat.normal) * getWaterWaveNormal(worldPos);

    if (dot(screenToPlayerPos(vec3(uv, depth1)).xyz - playerPos, normal) < 0.0) imageStore(colorimg1, ivec2(gl_GlobalInvocationID.xy), uvec4(packUnorm4x8(mat.albedo), mat.blockId | (pack2x8(octEncode(normal)) << 16u), 0u, 1u));
}