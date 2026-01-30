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
#include "/include/spaceConversion.glsl"
#include "/include/textureSampling.glsl"
#include "/include/atmosphere.glsl"
#include "/include/heitz.glsl"
#include "/include/lighting.glsl"
#include "/include/text.glsl"

layout (r11f_g11f_b10f) uniform image2D colorimg7;
layout (r32f) uniform image2D colorimg13;

layout (local_size_x = 8, local_size_y = 8) in;

#if TAA_UPSCALING_FACTOR == 100
    const vec2 workGroupsRender = vec2(1.0, 1.0);
#elif TAA_UPSCALING_FACTOR == 75
    const vec2 workGroupsRender = vec2(0.75, 0.75);
#elif TAA_UPSCALING_FACTOR == 50
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#endif

// TODO : rewrite this mess

void main ()
{
    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = texelSize * (vec2(texel) + 0.5);

    float depth        = texelFetch(depthtex0, texel, 0).r;
    float depth1       = texelFetch(depthtex1, texel, 0).r;
    vec4 color         = texelFetch(colortex7, texel, 0) / EXPONENT_BIAS;
    float virtualDepth = texelFetch(colortex13, texel, 0).r;
    
    if (depth1 == depth) {
        if (isEyeInWater == 1) {
            color.rgb *= waterTransmittance(distance(screenToPlayerPos(vec3(uv, depth)).xyz, vec3(screenToPlayerPos(vec3(uv, 0.0)))));
            imageStore(colorimg7, ivec2(gl_GlobalInvocationID.xy), EXPONENT_BIAS * color);
        }
        
        return;
    }
    
    TranslucentMaterial mat = unpackTranslucentMaterial(texel);

    vec3 rayColor = vec3(0.0);

    vec3 rayPos = screenToPlayerPos(vec3(uv, depth)).xyz;

    if (mat.isHand) {
        rayPos += 0.5 * playerLookVector;
    }

    vec3 rayDir = normalize(rayPos - screenToPlayerPos(vec3(uv, 0.000001)).xyz);
    Ray ray = Ray(rayPos + mat.normal * 0.01, reflect(rayDir, mat.normal));

    RayHitInfo rt = TraceGenericRay(ray, REFLECTION_MAX_RT_DISTANCE, true, true);

    if (rt.hit) {
        IrradianceSum r = sampleReflectionLighting(ray.origin + rt.dist * ray.direction, rt.normal, blueNoise(vec2(texel)).rg, 0.3);

        rayColor += rt.albedo.rgb * rt.emission + rt.albedo.rgb * r.diffuseIrradiance + lightTransmittance(shadowDir) * lightBrightness * r.directIrradiance * evalCookBRDF(normalize(shadowDir + rt.normal * 0.03125), ray.direction, max(0.1, rt.roughness), rt.normal, rt.albedo.rgb, rt.F0);
    } else {
        rayColor += rt.albedo.rgb * sampleSkyView(ray.direction);
    }

    if (isEyeInWater == 1) rayColor.rgb *= waterTransmittance(rt.dist);
    
    #ifdef WATER_REFRACTION
        float waterOpticalDepth = 0.0;
    #else
        float waterOpticalDepth = distance(rayPos.xyz, screenToPlayerPos(vec3(uv, depth1)).xyz);
    #endif

    #if defined GLASS_REFRACTION || defined WATER_REFRACTION
        vec3 throughput = vec3(0.25);
        vec3 refractColor = vec3(0.0);

        if (
            #if defined GLASS_REFRACTION && defined WATER_REFRACTION
                mat.blockId == 99 || mat.blockId == 10100
            #elif defined GLASS_REFRACTION
                mat.blockId == 99
            #else
                mat.blockId == 10100
            #endif
        ) { 
            Ray refractRay = Ray(rayPos - mat.normal * 0.01, refract(rayDir, mat.normal, mat.blockId == 10100 ? (isEyeInWater == 1 ? WATER_IOR : rcp(WATER_IOR)) : rcp(GLASS_IOR)));

            if (refractRay.direction != vec3(0.0)) 
            {
                bool medium = true;

                for (int i = 0; i < REFRACTION_BOUNCES; i++) {
                    RayHitInfo refraction = TraceGenericRay(refractRay, 1024.0, true, i == (REFRACTION_BOUNCES - 1));
                    
                    #ifdef WATER_REFRACTION
                        if (mat.blockId == 10100 && i == 0) waterOpticalDepth += refraction.dist;
                    #endif

                    if (refraction.hit) {
                        vec3 hitPos = refractRay.origin + refractRay.direction * refraction.dist;
                        vec3 nextDir = refract(refractRay.direction, refraction.normal, refraction.blockId == 10100 ? (medium ? WATER_IOR : rcp(WATER_IOR)) : (medium ? GLASS_IOR : rcp(GLASS_IOR)));

                        if (
                            (!mat.isHand && medium && nextDir == vec3(0.0) && mat.blockId == 99) || 
                            #if defined GLASS_REFRACTION && defined WATER_REFRACTION
                                refraction.blockId == 99 || refraction.blockId == 10100
                            #elif defined GLASS_REFRACTION
                                refraction.blockId == 99
                            #else
                                refraction.blockId == 10100
                            #endif
                        ) {
                            if (nextDir == vec3(0.0)) {
                                refractRay.origin = hitPos + refraction.normal * 0.005;
                                refractRay.direction = reflect(refractRay.direction, refraction.normal);
                                throughput *= 1.45;
                            } else {
                                refractRay.origin = hitPos - refraction.normal * 0.005;
                                refractRay.direction = nextDir;
                                throughput *= mix(vec3(1.0), refraction.albedo.rgb, GLASS_OPACITY);
                                medium = !medium;
                            }
                        } else {
                            IrradianceSum r = sampleReflectionLighting(hitPos, refraction.normal, blueNoise(vec2(texel)).rg, 0.45);

                            refractColor += throughput * (refraction.albedo.rgb * refraction.emission + refraction.albedo.rgb * r.diffuseIrradiance + lightTransmittance(shadowDir) * lightBrightness * r.directIrradiance * evalCookBRDF(normalize(shadowDir + refraction.normal * 0.03125), refractRay.direction, refraction.roughness, refraction.normal, refraction.albedo.rgb, refraction.F0));
                        }
                    } else {
                        refractColor += throughput * sampleSkyView(refractRay.direction);
                        break;
                    }
                }
            }
        } else {
            refractColor = color.rgb;
        }
    #else
        vec3 refractColor = color.rgb;
    #endif

    vec3 transmittance;

    if (mat.blockId == 10100) transmittance = waterTransmittance(min(8.0, waterOpticalDepth));
    else transmittance = mix(vec3(1.0), mat.albedo.rgb, GLASS_OPACITY);

    if (isEyeInWater == 1) {
        vec3 viewTransmittance = waterTransmittance(distance(screenToPlayerPos(vec3(uv, depth)).xyz, vec3(screenToPlayerPos(vec3(uv, 0.0)))));

        rayColor.rgb *= viewTransmittance;
        refractColor.rgb *= viewTransmittance;
    }

    imageStore(colorimg13, texel, vec4(max(virtualDepth, rt.hit ? playerToScreenPos(rayPos.xyz + rayDir * rt.dist).z : 0.0), 0.0, 0.0, 1.0));
    imageStore(colorimg7, texel, vec4(EXPONENT_BIAS * mix(
        refractColor.rgb * transmittance, 
        rayColor, 
        ((isEyeInWater == 1 && mat.blockId == 10100) ? vec3(refract(rayDir, mat.normal, WATER_IOR) == vec3(0.0) ? 1.0 : 0.0) : schlickFresnel(vec3(mat.blockId == 10100 ? WATER_REFLECTANCE : GLASS_REFLECTANCE), -dot(rayDir, mat.normal)))
    ), 1.0));
}