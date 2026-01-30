#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/octree.glsl"
#include "/include/wave.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/brdf.glsl"
#include "/include/ircache.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 16, 16);

float worley (vec3 uv, int octave) 
{
    vec3 tex = uv * octave;
    ivec3 origin = ivec3(floor(tex + 0.5));

    float minDist = 10.0;

    for (int x = origin.x - 2; x < origin.x + 2; x++) {
        for (int y = origin.y - 2; y < origin.y + 2; y++) {
            for (int z = origin.z - 2; z < origin.z + 2; z++) {
                uint state = (x & (octave - 1)) + octave * (y & (octave - 1)) + octave * octave * (z & (octave - 1)) + 262144 * octave;

                vec3 s = vec3(x, y, z) + vec3(randomValue(state), randomValue(state), randomValue(state));

                minDist = min(minDist, lengthSquared(tex - s));
            }
        }
    }

    return exp(-2.4 * minDist);
}


void main ()
{
    vec3 uv = vec3(gl_GlobalInvocationID.xyz) * rcp(64.0) + rcp(128.0);

    float result = 0.0;

    for (int i = 2; i < 7; i++) {
        result += worley(uv, 1 << i) / (1 << (i - 1));
    }

    imageStore(imgWorley, ivec3(gl_GlobalInvocationID.xyz), vec4(result, 0.0, 0.0, 1.0));
}