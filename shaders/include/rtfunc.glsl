RayHitInfo hitResult = miss(maxDist);

ray.origin += voxelOffset;
ray.direction = vec3(ray.direction.x < 0.0 ? -1.0 : 1.0, ray.direction.y < 0.0 ? -1.0 : 1.0, ray.direction.z < 0.0 ? -1.0 : 1.0) * max(abs(ray.direction), vec3(0.0001));

vec3 delta = abs(1.0 / ray.direction);
vec3 rayStep = sign(ray.direction);
ivec3 voxel = halfVoxelVolumeSize + ivec3(floor(ray.origin));
vec3 sideDist = delta * abs(ray.origin - floor(ray.origin + max(vec3(0), rayStep)));
vec3 tint = vec3(1.0);

#ifdef RT_SHADOW
    if (all(greaterThan(delta, vec3(1024.0)))) return vec3(0.0);
    bool alphaBlend = true;
#else
    if (all(greaterThan(delta, vec3(1024.0)))) return hitResult;
#endif

uint boxTestCount, triangleTestCount;
uint octreeLevel = 6u;

for (boxTestCount = 0u, triangleTestCount = 0u; triangleTestCount < 1024u && boxTestCount < 256u && all(greaterThan(voxel, ivec3(0))) && all(lessThan(voxel, voxelVolumeSize)); boxTestCount++) 
{   
    if (octreeLevel == 0u || isLeaf(voxel, octreeLevel)) {
        while (octreeLevel < 6u && isLeaf(voxel, octreeLevel + 1u)) octreeLevel++;
    } else {
        while (octreeLevel > 0u && !isLeaf(voxel, octreeLevel)) octreeLevel--;
    }

    if (octreeLevel == 0u) 
    {
        uint nextTriangle = getVoxel(voxel);

        while (nextTriangle != END_MARKER)
        {   
            triangleTestCount++;

            BVHTriangle tr = unpackTriangle(allTriangles.list[nextTriangle]);
            nextTriangle = tr.next;

            vec3 normal = cross(tr.tangent, tr.bitangent);

            float determinant = -dot(ray.direction, normal);
            if (useBackFaceCulling && tr.doBackFaceCulling && determinant < 0.00001 || abs(determinant) < 0.00001) continue;

            float invDet = rcp(determinant);
            vec3 ao = ray.origin - tr.pos;
            float dist = dot(normal, ao) * invDet;

            if (dist >= hitResult.dist || dist < 0.0 || (tr.isTranslucent && ivec3(floor(ray.origin + ray.direction * dist - normal * 0.00005)) + halfVoxelVolumeSize != voxel)) continue;

            vec3 uv = vec3(invDet * cross(ao, ray.direction) * mat2x3(tr.bitangent, -tr.tangent), 1.0);
            uv.z = dot(uv, vec3(-1.0, -1.0, 1.0));

            if (tr.isQuad ? floor(uv.xy) == vec2(0.0) : floor(uv.xyz) == vec3(0.0)) 
            {   
                vec4 albedo;
                vec2 texcoord = mat3x2(tr.uv0, tr.uv1, tr.uv2) * uv;

                if (tr.textureIndex != 4095u)
                {
                    TextureKey tk = allTextures.keys[tr.textureIndex];
                    ivec2 texelCoord = ivec2(vec2(uvec2(1u) << uvec2(tk.bounds >> 28u, (tk.bounds >> 24u) & 15u)) * texcoord);
                    albedo = unpackUnorm4x8(allTextures.data[(tk.bounds & 16777215u) + texelCoord.x + texelCoord.y * (1u << (tk.bounds >> 28u))]);
                } else albedo = textureLod(shadowtex0, texcoord, 0.0);

                #ifndef RT_SHADOW
                    albedo.rgb *= tr.color;
                #endif

                if (tr.isTranslucent) albedo = vec4(albedo.a > 0.1 ? albedo : vec4(0.5, 0.5, 0.5, 0.1));

                if (albedo.a > 0.1 || tr.isTranslucent) 
                {   
                    if (alphaBlend && tr.isTranslucent && any(greaterThan(tint, vec3(0.05))))
                    {   
                        #if defined RT_SHADOW && defined WATER_CAUSTICS
                            if (tr.blockId == 10100) {
                                vec3 waveNormal = getWaterWaveNormalTex(ray.origin + ray.direction * dist - voxelOffset + cameraPosition).xzy;

                                tint *= waterTransmittance(min(16.0, dist)) * exp(WATER_CAUSTICS_STRENGTH * ray.direction.y * 32.0 * log(dist + 1.0) * (dot(ray.direction, normalize(waveNormal)) - ray.direction.y));
                            } else {
                                tint *= mix(vec3(1.0), pow(albedo.rgb, vec3(2.2)), albedo.a);
                            }
                        #else
                            tint *= mix(vec3(1.0), pow(albedo.rgb, vec3(2.2)), albedo.a);
                        #endif
                    } else {
                        #ifdef RT_SHADOW
                            return vec3(0.0);
                        #else
                            hitResult.dist = dist;
                            hitResult.albedo = albedo;
                            hitResult.blockId = tr.blockId;
                            #ifdef SPECULAR_MAPPING
                                hitResult.specularData = tr.textureIndex == 4095u ? textureLod(shadowtex1, texcoord, 0.0) : vec4(0.0);
                            #endif
                            hitResult.normal = normal;
                            hitResult.hit = true;
                        #endif
                    }
                }
            }
        }
    }
    
    if (minOf(sideDist + 0.001 * delta * abs(hitResult.normal)) > hitResult.dist) break;

    vec3 nodeSideDist = sideDist + delta * abs(((voxel >> octreeLevel) << octreeLevel) + max(ivec3(0), (ivec3(rayStep) << octreeLevel) - 1) - voxel);
    float nodeDist = minOf(nodeSideDist);
    ivec3 nextPos = halfVoxelVolumeSize + ivec3(floor(ray.origin + ray.direction * nodeDist + 0.5 * rayStep * vec3(equal(nodeSideDist, vec3(nodeDist)))));

    sideDist += delta * abs(voxel - nextPos);
    voxel = nextPos;
}

#ifdef RT_SHADOW
    return tint;
#else      
    hitResult.normal = -sign(dot(ray.direction, hitResult.normal)) * normalize(hitResult.normal);

    #ifdef IPBR
        applyIntegratedSpecular(hitResult.albedo.rgb, hitResult.specularData, hitResult.blockId);
    #endif

    hitResult.albedo = vec4(pow(tint * hitResult.albedo.rgb, vec3(2.2)), hitResult.albedo.a);
    
    applySpecularMap(hitResult.specularData, hitResult.albedo.rgb, hitResult.F0, hitResult.roughness, hitResult.emission);

    return hitResult;
#endif