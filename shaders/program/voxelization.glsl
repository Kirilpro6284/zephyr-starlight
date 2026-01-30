#ifdef fsh

    #include "/include/uniforms.glsl"
    #include "/include/config.glsl"
    #include "/include/constants.glsl"
    #include "/include/common.glsl"
    #include "/include/pbr.glsl"
    #include "/include/main.glsl"

    flat in uint offset;

    void main ()
    {
        vec4 data = texelFetch(gtexture, ivec2(gl_FragCoord.xy), 0);
        allTextures.data[offset + uint(gl_FragCoord.x) + uint(gl_FragCoord.y) * (1u << uint(ceil(log2(float(textureSize(gtexture, 0).x) - 0.5))))] = packUnorm4x8(vec4(data.rgb, step(0.1, data.a)));
        discard;
    }

#endif

#ifdef gsh

    #define HASH_SAMPLER gtexture

    #include "/include/uniforms.glsl"
    #include "/include/config.glsl"
    #include "/include/constants.glsl"
    #include "/include/common.glsl"
    #include "/include/pbr.glsl"
    #include "/include/main.glsl"
    #include "/include/textureData.glsl"

    layout (triangles) in;
    layout (triangle_strip, max_vertices = 4) out;

    in VSOUT
    {
        vec2 texcoord;
        vec3 vertexColor;
        vec3 vertexPosition;
        ivec2 id;
    } vsout[3];

    flat out uint offset;

    void main ()
    {   
        #ifndef VOXELIZE_PLAYER
            if (entityId == 1002) return;
        #endif

        #ifndef GLOWING_ARMOR_TRIMS
            if (currentRenderedItemId == 87) return;
        #endif

        vec3 tangent = vsout[2].vertexPosition - vsout[1].vertexPosition;
        vec3 bitangent = vsout[0].vertexPosition - vsout[1].vertexPosition;

        vec3 normal = cross(tangent, bitangent);

        bool doBackFaceCull = vsout[0].id.x > 10000 && vsout[0].id.x < 65000;
        if (all(lessThan(abs(normal), vec3(0.00005))) || (doBackFaceCull && dot(normal, vec3(1.0, 0.5, 0.8)) < 0.0)) return;

        doBackFaceCull = doBackFaceCull || (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) || (entityId == 1002);

        normal = alignNormal(normal, 0.00005);

        vec3 minBounds = min(min(vsout[0].vertexPosition, vsout[1].vertexPosition), min(vsout[2].vertexPosition, vsout[1].vertexPosition + 0.99995 * (tangent + bitangent)));
        vec3 maxBounds = max(max(vsout[0].vertexPosition, vsout[1].vertexPosition), max(vsout[2].vertexPosition, vsout[1].vertexPosition + 0.99995 * (tangent + bitangent)));
        
        minBounds -= normal * 0.00005;
        maxBounds = max(minBounds, maxBounds - 0.00005);

        ivec3 voxelMin = halfVoxelVolumeSize + ivec3(floor(minBounds));
        ivec3 voxelMax = halfVoxelVolumeSize + ivec3(ceil(maxBounds));

        if (entityId != 1001 && all(greaterThanEqual(voxelMin, ivec3(0))) && all(lessThan(voxelMax, voxelVolumeSize + 1))) 
        {   
            #ifdef FORCE_TRIANGLE_TRACING
                bool isQuad = false;
            #else
                #ifdef STAGE_TERRAIN
                    bool isQuad = vsout[0].id.y == 0;
                #else
                    bool isQuad = true;
                #endif
            #endif

            BVHTriangle tri = BVHTriangle 
            (
                vsout[1].vertexPosition - 0.001 * (tangent + bitangent),
                tangent * 1.002,
                bitangent * 1.002,
                vsout[2].texcoord, 
                vsout[0].texcoord, 
                vsout[1].texcoord,
                4095u,
                0u,
                vsout[0].id.x,
                (vsout[2].vertexColor.rgb + vsout[0].vertexColor.rgb) * 0.5,
                isQuad,
                !doBackFaceCull,
                renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
            );

            uint hash = getTextureHash();
            ivec2 texSize = textureSize(gtexture, 0);
            uint texOffset;

            #ifndef VOXELIZE_ITEMS
                if (renderStage == MC_RENDER_STAGE_ENTITIES && hash == allTextures.atlasHash) return;
            #endif

            if (addTexture(hash, texSize, tri.textureIndex, texOffset)) {
                for (int i = 0; i < 4; i++) {
                    offset = texOffset;
                    gl_Position = vec4(ivec2(i & 1, i >> 1) * texSize / float(shadowMapResolution) * 2.0 - 1.0, 0.0, 1.0);

                    EmitVertex();
                }

                EndPrimitive();
            }

            float threshold = dot(abs(normal), vec3(0.5)) + 0.00005;

            for (int x = voxelMin.x; x < voxelMax.x; x++) {
                for (int y = voxelMin.y; y < voxelMax.y; y++) {
                    for (int z = voxelMin.z + (isQuad ? ((x & 1) ^ (y & 1) ^ (gl_PrimitiveIDIn & 1)) : 0); z < voxelMax.z; z += isQuad ? 2 : 1) {
                        if (abs(dot(normal, vsout[1].vertexPosition - vec3(x, y, z) + halfVoxelVolumeSize - 0.5)) < threshold) 
                        {
                            uint index = atomicAdd(allTriangles.last, 1u);
                            tri.next = addVoxel(ivec3(x, y, z), index);
                            allTriangles.list[index] = packTriangle(tri);
                        }
                    }
                }
            }

            voxelMin.x += voxelVolumeSize.x;
            voxelMax.x += voxelVolumeSize.x;

            for (int i = 0; i < 3; i++) {
                voxelMin = voxelMin >> 1;
                voxelMax = (voxelMax - 1) >> 1;

                for (int x = voxelMin.x; x <= voxelMax.x; x++) {
                    for (int y = voxelMin.y; y <= voxelMax.y; y++) {
                        for (int z = voxelMin.z + (isQuad && ((x & 1) ^ (y & 1) ^ (gl_PrimitiveIDIn & 1)) == 1 ? 1 : 0); z <= voxelMax.z; z += (1 + int(isQuad))) {
                            imageStore(voxelBufferLod, ivec3(x, y, z), uvec4(1u, 0u, 0u, 0u));
                        }
                    }
                }

                voxelMax += 1;
            }
        }
    }

#endif

#ifdef vsh

    attribute vec2 mc_Entity;

    #include "/include/uniforms.glsl"
    #include "/include/config.glsl"
    #include "/include/constants.glsl"
    #include "/include/common.glsl"
    #include "/include/pbr.glsl"
    #include "/include/main.glsl"
    #include "/include/textureData.glsl"

    out VSOUT
    {
        vec2 texcoord;
        vec3 vertexColor;
        vec3 vertexPosition;
        ivec2 id;
    } vsout;

    void main ()
    {   
        vec3 playerPos = voxelOffset + mat3(shadowModelViewInverse) * mat4x3(gl_ModelViewMatrix) * gl_Vertex;

        vsout.texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
        vsout.vertexColor = gl_Color.rgb;
        vsout.vertexPosition = floor(playerPos + 0.5) + (playerPos - floor(playerPos + 0.5)) * step(vec3(0.001), abs(playerPos - floor(playerPos + 0.5)));
        
        #ifdef STAGE_TERRAIN
            vsout.id = max(ivec2(0), ivec2(mc_Entity));
        #elif defined STAGE_ENTITIES
            vsout.id = ivec2(currentRenderedItemId == 0 ? entityId : currentRenderedItemId, 0);
        #elif defined STAGE_BLOCK_ENTITIES
            vsout.id = ivec2(blockEntityId, 0);
        #endif
    }

#endif