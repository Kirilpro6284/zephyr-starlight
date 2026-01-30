#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

#ifdef fsh

in VSOUT 
{
    vec4 vertexColor;
} vsout;

/* RENDERTARGETS: 8,9 */
layout (location = 0) out uvec4 colortex8Out;
layout (location = 1) out uvec4 colortex9Out;

void main ()
{
    if (any(greaterThan(gl_FragCoord.xy, screenSize))) discard;

    uvec4 data = packMaterialData(vsout.vertexColor.rgb, vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 0.1), 65000u, false);

    colortex8Out = data;
    colortex9Out = data.zwxy;
}

#endif

#ifdef vsh

in vec4 vaColor;
in vec3 vaPosition;
in vec3 vaNormal;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out VSOUT 
{
    vec4 vertexColor;
} vsout;

vec4 ftransformLine()
{
    vec4 lineDir = mat3x4(projectionMatrix) * mat3(modelViewMatrix) * vaNormal;

  	vec4 linePosStart = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
  	vec4 linePosEnd = linePosStart + lineDir;

    if (linePosStart.w <= 0.0) linePosStart -= (linePosStart.w - 0.00001) * vec4(lineDir.xyz / lineDir.w, 1.0);
    if (linePosEnd.w <= 0.0) linePosEnd += (linePosEnd.w - 0.00001) * vec4(lineDir.xyz / lineDir.w, 1.0);

 	vec3 ndc1 = linePosStart.xyz / linePosStart.w;
  	vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

  	vec2 lineScreenDirection = texelSize.y * normalize((ndc2.xy - ndc1.xy) * renderSize);
  	vec2 lineOffset = lineWidth * vec2(-lineScreenDirection.y, lineScreenDirection.x);
	
  	if (lineOffset.x < 0.0) {
    	lineOffset *= -1.0;
    }

  	if ((gl_VertexID & 1) == 0) {
        return vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
    } else {
        return vec4((ndc1 - vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
    }
}

void main ()
{   
    gl_Position = ftransformLine();

    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);
    gl_Position.xy += gl_Position.w * taaOffset;
    
    vsout.vertexColor = vaColor;
}

#endif