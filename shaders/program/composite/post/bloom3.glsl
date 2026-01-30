#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"
#include "/include/textureSampling.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

void main() {
	vec2 uv = gl_FragCoord.xy / screenSize;
	vec3 bloom = vec3(0.0);

	for (int i = 0; i < 8; i++) {
		bloom += texBicubic(colortex12, uintBitsToFloat((126 - i) << 23) * (uv + 1), screenSize).rgb;
	}

	if (any(isnan(bloom))) bloom = vec3(0.0);

	color.rgb = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0).rgb + bloom * BLOOM_STRENGTH;
}