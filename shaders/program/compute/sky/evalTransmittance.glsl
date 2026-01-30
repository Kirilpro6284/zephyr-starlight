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
#include "/include/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(4, 4, 16);

void main ()
{
    vec2 uv = linearStep(gl_GlobalInvocationID.xy * rcp(32.0) + rcp(64.0), rcp(64.0), 1.0 - rcp(64.0));

    float height = planetRadius + clamp(lift(uv.x, -4.0), 0.01, 0.99) * atmosphereHeight;
    vec3 dir = vec3(0.0, mix(-sqrt(1.0 - sqr(planetRadius / height)), 1.0, lift(uv.y, -16.0)), 0.0);
    dir.x = sqrt(1.0 - dir.y * dir.y);

    float hitDist = raySphere(Ray(vec3(0.0, height, 0.0), dir), planetRadius + atmosphereHeight).y;
    vec3 rayPos = vec3(0.0, height, 0.0) + rcp(128) * 0.5 * hitDist * dir;
    vec3 attenuation = vec3(0.0);

    for (int i = 0; i < 128; i++, rayPos += rcp(128) * hitDist * dir) {
        attenuation += getDensityAtPoint(rayPos);
    }

    imageStore(imgTransmittance, ivec2(gl_GlobalInvocationID.xy), vec4(sqrt(exp(-SCATTER_POINTS * rcp(128) * hitDist * (absorption * attenuation))), 1.0));
}