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

    if (depth < 0.7) {
        color = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0);
        return;
    }

    vec4 playerPos = screenToPlayerPos(vec3(uv, depth));
    
    #if DOF_FOCUS_MODE == 0
        vec4 focusPos  = screenToPlayerPos(vec3(uv, centerDepthSmooth));
        float radius = APERTURE_SIZE * abs(playerPos.w - focusPos.w) * gbufferProjection[0].x;
    #else
        float radius = APERTURE_SIZE * abs(playerPos.w - rcp(DOF_FOCUS_DISTANCE)) * gbufferProjection[0].x;
    #endif

    vec2 dither = blueNoise(gl_FragCoord.xy).rg;
    vec3 integratedData = vec3(0.0);

    for (int i = 0; i < DOF_SAMPLES; i++) {
        float theta = TWO_PI * (R1(i) + dither.x);

        integratedData += texelFetch(colortex10, ivec2(renderSize * saturate(uv + radius * sqrt((i + dither.y) * rcp(DOF_SAMPLES)) * vec2(cos(theta), aspectRatio * sin(theta)))), 0).rgb;
    }

    color = vec4(integratedData * rcp(DOF_SAMPLES), 1.0);
}