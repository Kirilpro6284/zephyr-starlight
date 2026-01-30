#ifndef INCLUDE_COMMON
    #define INCLUDE_COMMON

    #define rcp(x)       (1.0 / (x))
    #define max0(x)      max(x, 0.0)
    #define min1(x)      min(x, 1.0)
    #define saturate(x)  clamp(x, 0.0, 1.0)
    #define HALF_PI      1.57079632
    #define PI           3.14159265
    #define TWO_PI       6.28318530
    #define INFINITY     exp2(128.0)
    #define luminance(c) dot(c, vec3(0.2126, 0.7152, 0.0722))
    #define torad(x)     (0.01745329 * x)
    #define screenSize   vec2(viewWidth, viewHeight)

    vec4 gamma (vec4 color)
    {
        return vec4(pow(color.rgb, vec3(2.2)), color.a);
    }

    vec4 unpackHalf4x16 (uvec2 t)
    {
        return vec4(unpackHalf2x16(t.x), unpackHalf2x16(t.y));
    }

    uvec2 packHalf4x16 (vec4 t)
    {
        return uvec2(packHalf2x16(t.xy), packHalf2x16(t.zw));
    }

    float lift (float x, float a)
    {
        return x / (a * abs(x) + 1.0 - a);
    }
	
	float liftInverse (float x, float a)
    {
        return x * (1.0 - a) / (1.0 - abs(x) * a);
    }

    float linearStep (float x, float edge0, float edge1)
    {
        return saturate((x - edge0) / (edge1 - edge0));
    }

    vec2 linearStep (vec2 x, float edge0, float edge1)
    {
        return saturate((x - edge0) / (edge1 - edge0));
    }

    vec3 linearStep (vec3 x, float edge0, float edge1)
    {
        return saturate((x - edge0) / (edge1 - edge0));
    }

    float lengthSquared (vec3 v) 
    {
        return dot(v, v);
    }

    float lengthSquared (vec2 v) 
    {
        return dot(v, v);
    }

    float sqr (float x) 
    {
        return x * x;
    }

    vec3 sqr (vec3 x)
    {
        return x * x;
    }

    uint pack3x10 (vec3 t)
    {
        uvec3 result = uvec3(clamp(t * 1023.0, 0.0, 1023.0));
        return (result.x << 22u) | (result.y << 12u) | (result.z << 2u);
    }

    vec3 unpack3x10 (uint t)
    {
        return (uvec3(t >> 22u, t >> 12u, t >> 2u) & 1023u) * rcp(1023.0);
    }

    uint packExp4x8 (vec4 t) 
    {
        uvec4 result = uvec4(clamp(t * 254.0 + 0.5, 0.0, 254.0));
        return (result.x << 24u) | (result.y << 16u) | (result.z << 8u) | (result.w);
    }

    vec4 unpackExp4x8 (uint t) 
    {
        return (uvec4(t >> 24u, t >> 16u, t >> 8u, t) & 255u) * rcp(254.0);
    }

    uint pack4x6 (vec4 t)
    {
        uvec4 result = uvec4(clamp(t * 63.0 + 0.5, 0.0, 63.0));
        return (result.x << 26u) | (result.y << 20u) | (result.z << 14u) | (result.w << 8u);
    }

    vec4 unpack4x6 (uint t)
    {
        return (uvec4(t >> 26u, t >> 20u, t >> 14u, t >> 8u) & 63u) * rcp(63.0);
    }

    uint pack2x8 (vec2 t) 
    {
        uvec2 result = uvec2(clamp(t * 254.0 + 0.5, 0.0, 254.0));
        return (result.x << 8u) | (result.y);
    }

    vec2 unpack2x8 (uint t) 
    {
        return vec2(t >> 8u, t & 255u) * rcp(254.0);
    }

    uint pack2x16 (vec2 t) 
    {
        uvec2 result = uvec2(clamp(t * 65536.0 + 0.5, 0.0, 65535.0));
        return (result.x << 16u) | result.y;
    }

    vec2 unpack2x16 (uint t) 
    {
        return vec2(t >> 16u, t & 65535u) * rcp(65536.0);
    }

    uint pack2x16u (uvec2 t) 
    {
        return (t.x << 16u) | t.y;
    }

    uvec2 unpack2x16u (uint t) 
    {
        return uvec2(t >> 16u, t & 65535u);
    }

    // https://twitter.com/Stubbesaurus/status/937994790553227264

    vec2 octEncode (in vec3 n) 
    {
        n.xyz /= abs(n.x) + abs(n.y) + abs(n.z);
        float t = max0(-n.y);
        n.x += (n.x > 0.0) ? t : -t;
        n.z += (n.z > 0.0) ? t : -t;
        return n.xz * 0.5 + 0.5;
    }

    vec3 octDecode (in vec2 f)
    {
        f = f * 2.0 - 1.0;
 
        vec3 n = vec3(f.x, 1.0 - abs(f.x) - abs(f.y), f.y);
        float t = max0(-n.y);
        n.x += n.x >= 0.0 ? -t : t;
        n.z += n.z >= 0.0 ? -t : t;
        return normalize(n);
    }

    mat3 tbnNormalTangent (vec3 normal, vec4 tangent) 
    {
        return mat3(tangent.xyz, cross(tangent.xyz, normal) * sign(tangent.w), normal);
    }

    mat3 tbnNormal (vec3 normal) 
    {
        return tbnNormalTangent(normal, vec4(normalize(cross(normal, vec3(0.0, 1.0, (normal.y * normal.z) < 0.0 ? 1.0 : -1.0))), 1.0));
    }

    vec3 sampleSunDir (vec3 lightDir, vec2 dither)
    {
        return tbnNormal(lightDir) * vec3(SHADOW_SOFTNESS * sqrt(dither.y) * vec2(cos(TWO_PI * dither.x), sin(TWO_PI * dither.x)), 1.0);
    }

    float maxOf (vec3 t) 
    {
        return max(max(t.x, t.y), t.z);
    }

    float maxOf (vec4 t) 
    {
        return max(max(t.x, t.y), max(t.z, t.w));
    }

    float minOf (vec3 t) 
    {
        return min(min(t.x, t.y), t.z);
    }

    float minOf (vec4 t) 
    {
        return min(min(t.x, t.y), min(t.z, t.w));
    }

    vec3 alignNormal (vec3 normal, float eps) 
    {
        return normalize(normal * vec3(greaterThan(abs(normal), vec3(eps))));
    }

    float R1 (uint t)
    {
        return fract(t * 0.6180339);
    }

    vec2 R2 (uint t)
    {
        return fract(vec2(t) * vec2(0.2451223, 0.4301597));
    }

    vec3 R3 (uint t)
    {
        return fract(vec3(t) * vec3(0.8191725, 0.6710435, 0.5497004));
    }

    // https://discordapp.com/channels/237199950235041794/525510804494221312/1416364500591837216

    vec3 blueNoise (vec2 coord) 
    {
        return texelFetch(
            noisetex,
            ivec3(ivec2(coord) % 128, frameCounter % 64),
            0
        ).rgb;
    }

    // R2 sequence from
    // https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/

    vec3 blueNoise (vec2 coord, int i) 
    {
        const float g = 1.324717;

        return blueNoise(coord + 128.0 * fract(0.5 + i * rcp(vec2(g, g * g))));
    }

    mat2 rotate (float theta)
    {
        float cosTheta = cos(theta);
        float sinTheta = sin(theta);

        return mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    }

    vec3 dither11f (vec2 coord, vec3 color)
    {
        return color + (blueNoise(coord) - 0.5) * uintBitsToFloat(floatBitsToUint(max(vec3(0.000061035156), color)) & uvec3(0xff800000u)) * vec3(0.015625, 0.015625, 0.03125);
    }

    // Adapted from https://www.youtube.com/watch?v=Qz0KTGYJtUk&t=674s

    uint randomInt (inout uint state)
    {
        state = state * 747796405u + 2891336453u;
        uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
        return (result >> 22u) ^ result;
    }

    float randomValue (inout uint state) 
    {
        return randomInt(state) * rcp(4294967296.0);
    }

    float normalDist (inout uint state)
    {
        return sqrt(-log2(randomValue(state))) * cos(TWO_PI * randomValue(state));
    }

    vec3 randomDir (inout uint state)
    {	
        return normalize(vec3(normalDist(state), normalDist(state), normalDist(state)));
    }

    vec3 randomHemisphereDir (vec3 normal, inout uint state)
    {
        vec3 dir = randomDir(state);
        return dir * sign(dot(dir, normal));
    }

    uint packPosition (ivec3 pos) 
    {
        pos &= ivec3(2047, 1023, 2047);
        return (pos.x << 21) | (pos.y << 11) | (pos.z);
    }

    ivec3 unpackPosition (uint pack)
    {
        return ((ivec3(pack >> 21, pack >> 11, pack) - cameraPositionInt + ivec3(1024, 512, 1024)) & ivec3(2047, 1023, 2047)) + cameraPositionInt - ivec3(1024, 512, 1024);
    }

    uint hashPosition (ivec3 pos)
    {
        return (uint(pos.x) * 73856093) ^ (uint(pos.y) * 19349663) ^ (uint(pos.z) * 83492791);
    }

#endif