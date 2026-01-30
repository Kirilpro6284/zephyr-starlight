#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"

#ifdef fsh

in VSOUT 
{
    vec2 texcoord;
    vec3 vertexColor;
    flat uint blockId;
} vsout;

/* RENDERTARGETS: 1 */
layout (location = 0) out uvec4 colortex1Out;

void main ()
{
    if (any(greaterThan(gl_FragCoord.xy, screenSize))) discard;
    
    vec4 albedo = texture(gtexture, vsout.texcoord) * vec4(vsout.vertexColor, 1.0);

    colortex1Out = uvec4(packUnorm4x8(albedo.a > 0.1 ? albedo : vec4(0.5, 0.5, 0.5, 0.1)), vsout.blockId, 0u, 1u);
}

#endif

#ifdef vsh

attribute vec2 mc_Entity;

out VSOUT 
{
    vec2 texcoord;
    vec3 vertexColor;
    flat uint blockId;
} vsout;

void main ()
{   
    gl_Position = ftransform();
    
    #if defined STAGE_HAND && HAND_FOV > 0   
        gl_Position.xy *= handScale / gl_ProjectionMatrix[1].y;
    #endif
    
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);
    gl_Position.xy += gl_Position.w * taaOffset;

    vsout.texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    vsout.vertexColor = gl_Color.rgb;
    vsout.blockId = (pack2x8(octEncode(alignNormal(transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal, 0.01))) << 16u) |
    #ifdef STAGE_HAND
        (currentRenderedItemId & 16383u) | 0x00004000u;
    #else
        uint(mc_Entity.x) & 16383u;
    #endif

    #ifdef STAGE_WEATHER
        gl_Position = vec4(-1.0);
    #endif
}

#endif