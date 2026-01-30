#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/spaceConversion.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

vec2 clipAABB (vec2 origin, vec2 dir, vec2 boxMin, vec2 boxMax) 
{
    vec2 t2 = max((boxMin - origin) / dir, (boxMax - origin) / dir);

    return dir * saturate(min(t2.x, t2.y));
}

void main ()
{   
    vec2 uv = gl_FragCoord.xy / screenSize;
    #ifdef TAA_VIRTUAL_DEPTH
        float depth = texelFetch(colortex13, ivec2(gl_FragCoord.xy), 0).r;
    #else
        float depth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;
    #endif

    vec3 playerPos = screenToPlayerPos(vec3(uv, depth)).xyz;
    vec4 prevUv = projectAndDivide(gbufferPreviousModelViewProjection, (depth == 1.0 || depth < 0.7) ? playerPos : (playerPos + cameraVelocity));
    vec2 prevTexel = screenSize * (prevUv.xy * 0.5 + 0.5);

    if (prevUv.w > 0.0) {
        vec3 integratedData = vec3(0.0);
        vec2 sampleDir = clipAABB(gl_FragCoord.xy, prevTexel - gl_FragCoord.xy, vec2(0.0), vec2(screenSize)) * rcp(MOTION_BLUR_SAMPLES) * MOTION_BLUR_STRENGTH;
        vec2 samplePos = gl_FragCoord.xy + sampleDir * blueNoise(gl_FragCoord.xy).r;

        for (int i = 0; i < MOTION_BLUR_SAMPLES; i++, samplePos += sampleDir)
        {
            integratedData += texelFetch(colortex10, ivec2(samplePos), 0).rgb;
        }

        color = vec4(integratedData * rcp(MOTION_BLUR_SAMPLES), 1.0);
    } else {
        color = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0);
    }
}