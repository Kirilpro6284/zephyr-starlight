#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/common.glsl"
#include "/include/pbr.glsl"
#include "/include/main.glsl"

/* RENDERTARGETS: 12 */
layout (location = 0) out vec4 color;

const float[3] w = float[3](0.3134375, 0.189843360, 0.046349696);

void main() {
	vec3 result = vec3(0.0);
	float weights = 0.0;

	for (int y = -2; y <= 2; y++) {
		result += texelFetch(colortex12, ivec2(gl_FragCoord.xy) + ivec2(0, y), 0).rgb * w[abs(y)];
		weights += w[abs(y)]; 
	}

	color.rgb = result / weights;
}