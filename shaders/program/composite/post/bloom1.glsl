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

	for (int x = -2; x <= 2; x++) {
		result += texelFetch(colortex12, ivec2(gl_FragCoord.xy) + ivec2(x, 0), 0).rgb * w[abs(x)];
		weights += w[abs(x)]; 
	}

	color.rgb = result / weights;
}