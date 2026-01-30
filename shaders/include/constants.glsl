#ifndef INCLUDE_CONSTANTS
    #define INCLUDE_CONSTANTS
    
    const int noiseTextureResolution = 128;
    const int shadowMapResolution = 2048; // [256 512 1024 2048 4096]

    const float shadowDistanceRenderMul = 1.0;
    const float entityShadowDistanceMul = 0.5; // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    const float ambientOcclusionLevel = 0.0;
    const float shadowIntervalSize = 0.0;
    const float sunPathRotation = -60.0; // [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]
    const float shadowDistance = VOXELIZATION_DISTANCE;

    const float centerDepthHalflife = 2.0;

    const float lineWidth = 1.0;

    #if HAND_FOV > 0
        const float handScale = cos(radians(HAND_FOV) / 2.0) / sin(radians(HAND_FOV) / 2.0);
    #endif

    const ivec3 voxelVolumeSize = ivec3(2.0 * shadowDistance, min(256.0, 2.0 * shadowDistance - 64.0 * float(shadowDistance > 100.0)), 2.0 * shadowDistance);
    const ivec3 halfVoxelVolumeSize = voxelVolumeSize >> 1;

    #define END_MARKER 0x00ffffffu
    #define IRCACHE_INV_MARKER uvec2(3154164736u)

    // Color multiplier to avoid precision issues with dark colors
    #define EXPONENT_BIAS 64.0

    /*  
        const int colortex0Format =  RGB16F;         // previous frame normal + depth
        const int colortex1Format =  RG32UI;         // translucent material data
        const int colortex2Format =  RGBA16F;        // tracing output
        const int colortex3Format =  RGBA16F;        // diffuse temporal
        const int colortex4Format =  RGBA16F;        // reflection temporal
        const int colortex5Format =  RGBA16F;        // shadow temporal
        const int colortex6Format =  RGBA16F;        // TAA history
        const int colortex7Format =  R11F_G11F_B10F; // scene
        const int colortex8Format =  RG32UI;         // material data 0
        const int colortex10Format = RGBA16F;        // sun/moon geometry (gbuffers -> deferred), post-processing data (composite)
        const int colortex12Format = R11F_G11F_B10F; // filtered diffuse lighting (deferred), bloom tiles (composite)
        const int colortex13Format = R32F;           // reflection virtual depth buffer for TAA

        const int shadowcolor0Format = R8;
        const int shadowcolor1Format = R8;

        const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 0.0)
        const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0)
        const vec4 colortex13ClearColor = vec4(1.0, 0.0, 0.0, 1.0)

        const bool shadowtex0Nearest = true;
        const bool shadowtex1Nearest = true;

        const bool colortex0Clear = false;
        const bool colortex1Clear = false;
        const bool colortex2Clear = false;
        const bool colortex3Clear = false;
        const bool colortex4Clear = false;
        const bool colortex5Clear = false;
        const bool colortex6Clear = false;
        const bool colortex7Clear = true;
        const bool colortex8Clear = false;
        const bool colortex9Clear = false;
        const bool colortex10Clear = true;
        const bool colortex11Clear = false;
        const bool colortex12Clear = false;
        const bool colortex13Clear = true;
    */

    // https://discordapp.com/channels/237199950235041794/736928196162879510/1459984859312423152 <3

    #ifdef NORMAL_MAPPING
    /*
        const int colortex9Format = R32UI;   
    */   
    #else
    /*
        const int colortex9Format = R16UI; 
    */
    #endif

#endif