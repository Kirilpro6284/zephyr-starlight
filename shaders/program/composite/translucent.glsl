#include "/include/uniforms.glsl"
#include "/include/checker.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/octree.glsl"
#include "/include/raytracing.glsl"
#include "/include/textureData.glsl"
#include "/include/brdf.glsl"
#include "/include/irc.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/textureSampling.glsl"
#include "/include/atmosphere.glsl"
#include "/include/heitz.glsl"

/* DRAWBUFFERS:7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
    color = texelFetch(colortex7, texel, 0);

    if (texelFetch(depthtex1, texel, 0).r == depth) return;
    
    TranslucentMaterial mat = unpackTranslucentMaterial(texel);

    vec3 rayColor = vec3(0.0);

    vec4 rayPos = screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, depth));
    vec3 rayDir = normalize(rayPos.xyz - screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, 0.000001)).xyz);
    Ray ray = Ray(rayPos.xyz + mat.normal * 0.003, reflect(rayDir, mat.normal));

    RayHitInfo rt = TraceRay(ray, 1024.0, true, true);

    rayColor += rt.albedo.rgb * rt.emission;

    vec3 hitPos = ray.origin + rt.dist * ray.direction;
    vec3 hitUv = playerToScreenPos(hitPos);
    ivec2 hitTexel = ivec2(hitUv.xy * renderSize);

    if (rt.hit) {
        if (floor(hitUv.xy) == vec2(0.0) && lengthSquared(hitPos - screenToPlayerPos(vec3(hitUv.xy, texelFetch(depthtex1, hitTexel, 0).x)).xyz) < 0.0025) {
            rayColor += max(rt.albedo.rgb, rt.F0) * texelFetch(colortex12, hitTexel, 0).rgb;
            rayColor += getLightTransmittance(shadowDir) * lightBrightness * texelFetch(colortex5, hitTexel, 0).rgb * evalCookBRDF(shadowDir, ray.direction, max(0.1, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);
        } else {
            #ifdef SMOOTH_IRC
                float theta = TWO_PI * heitzSample(ivec2(gl_FragCoord.xy), frameCounter, 0);
                float phi = heitzSample(ivec2(gl_FragCoord.xy), frameCounter, 1);

                vec3 dir = tbnNormal(rt.normal) * vec3((1.0 - sqrt(1.0 - sqrt(phi))) * vec2(sin(theta), cos(theta)), 0.0);

                IRCResult q = queryIRC(hitPos + dir * min1(TraceRay(Ray(hitPos + rt.normal * 0.003, dir), 1.0, false, false).dist - 0.001), rt.normal, 0u);
            #else
                IRCResult q = queryIRC(hitPos, rt.normal, 0u);
            #endif

            rayColor += max(rt.albedo.rgb, rt.F0) * q.diffuseIrradiance;
            rayColor += getLightTransmittance(shadowDir) * lightBrightness * q.directIrradiance * evalCookBRDF(shadowDir, ray.direction, max(0.1, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);
        }
    } else {
        rayColor += rt.albedo.rgb * sampleSkyView(ray.direction);
    }

    color = vec4(mix(color.rgb * mat.albedo.rgb, rayColor, schlickFresnel(vec3(GLASS_REFLECTANCE), -dot(rayDir, mat.normal))), 1.0);
}