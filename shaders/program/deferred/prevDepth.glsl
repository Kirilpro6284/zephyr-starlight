#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"
#include "/include/spaceConversion.glsl"
#include "/include/text.glsl"

/* RENDERTARGETS: 0 */
layout (location = 0) out vec4 depth;

void main () 
{   
    vec4 normalData = unpackExp4x8(texelFetch(colortex9, ivec2(gl_FragCoord.xy), 0).x);

    #if defined TEMPORAL_NORMAL_TOLERANCE || !defined NORMAL_MAPPING
        vec3 normal = octDecode(normalData.zw);
    #else
        vec3 normal = octDecode(normalData.xy);
    #endif

    vec3 pos = screenToPlayerPos(vec3(gl_FragCoord.xy * texelSize, texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x)).xyz;

    depth = vec4(normal * dot(normal, pos), 1.0);
}