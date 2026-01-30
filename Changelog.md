# v0.2

Changes over v0.1.3:
* Water rendering overhaul:
  * Added water wave normals
  * Implemented water caustics (approximated, not truly ray/path traced)
  * Snell's Window effect
* Added proper hardcoded/integrated specular. This means that a labPBR resource pack is no longer needed for the shaderpack to function properly! Note that hardcoded specular will override any specular maps provided by resource packs, so if you want to use a custom labPBR pack, disable Terrain > Integrated PBR > Hardcoded Specular
  * Full support for all light sources from 1.21.11
  * Only works well with vanilla or almost-vanilla packs
  * Modded light sources will not work by default. To add support for a block to emit light, add the block's ID to the group `block.3 =` in block.properties.
* Tweaked ambient (minimum) light color toward a blue-ish color
* Increased the range of option values in path tracing settings
* Implemented irradiance cache cascading (inspired by Kajiya renderer). This means the irradiance cache will get lower resolution with distance from the player, making it more usable in large scenes. This also allows for higher resolution near the player.
* New camera effect: bloom
* Added new options: 
  * Terrain > Integrated PBR > Glowing Ores
  * Terrain > Integrated PBR > Glowing Concrete Powder
  * Terrain > Integrated PBR > Glowing Redstone Block
  * Terrain > Integrated PBR > Glowing Lapis Block
  * Terrain > Integrated PBR > Glowing Armor Trims
  * Terrain > Integrated PBR > Mirror-Like Packed Ice
  * Terrain > Water > Wave Height
  * Terrain > Water > Wave Frequency
  * Terrain > Water > Wave Speed
  * Terrain > Water > Wave Sharpness
  * Terrain > Water > Water Caustics
  * Terrain > Water > Caustic Strength
  * Path Tracing > Diffuse/Reflections/Shadows > Half Res Trace: When enabled, global illumination will be rendered at a lower resolution (half on each axis), improving performance at the cost of blurrier lighting and more noise.
  * Diffuse Lighting > Secondary GI Intensity: This controls the intensity of secondary light bounces. Lower values will result in darker block light shadows.
  * Reflections > Screen Space Reuse: When enabled, the reflected ray will use the screen space lighting information if it's hit point happens to be visible to the primary camera. Otherwise, the lighting information from the irradiance cache is returned.
  * Shadows > Skip Clipping: Enabling this can greatly improve shadow quality, but will result in terrible ghosting. Should really only be used for screenshots.
  * Denoising > Prefiltering: Applies a low-radius spatial filter before temporal accumulation for better stability and less noise. Only works when TAA is disabled.
  * Denoising > Temporal Normal Tolerance: When enabled, the temporal filter will preserve normal detail in lighting and reflections better at the cost of noise/shimmering with detailed normal maps.
  * Irradiance Cache > Cascade Resolution: Sets the resolution of a single cascade of the irradiance cache. If you increase this, increase Voxel Array Size as well.
  * Irradiance Cache > Samples: The amount of rays used per entry on each irradiance cache update pass.
  * Post Processing > Bloom
  * Post Processing > Bloom Strength
* Fixes:
  * Fixed an issue with TAA that caused jittering in motion
  * Fixed a compile error on Linux + AMD
  * Fixed water refractions looking incorrect in some situations
  * Fixed color banding in dark areas
  * Fixed lines not being rendered correctly
  * Fixed issues with grass block sides on newer Minecraft versions

# v0.1.3

Changes over v0.1.2:
* Fixed an issue with temporal accumulation that caused dissoccluded areas to be noisier that expected
* Tweaked reflection spatial denoising to preserve reflection detail better
* Fixed incorrect fresnel in secondary reflection bounces
* Added glass & water refraction (disabled by default). Can be enabled at Terrain > Glass/Water Refraction
* Added new options: 
  * Reflections > Per Pixel Shadow Calculation. When enabled, an additional ray is used to calculate sharp shadows in reflections.
  * Diffuse Lighting > Sampling Method. Uniform distributes rays in a hemisphere-like distribution. Cosine Weighted emits more rays that are perpendicular-ish to the surface
* Added contact shadows to the player model
* Improved the look of sunlight on surfaces parallel to the sun direction (half-lambert-like shading)
* Improved sky view texture mapping for less artifacts
* Other small tweaks & improvements

# v0.1.2

Changes over v0.1.1:
* Fixed moonlight not casting GI
* Improved the look of GI when Sunlight GI Quality is set to 0
* Added new options: 
  * Atmospherics & Lighting > Sun Size: This is a multiplier for the size of the sun sprite in the sky.
  * Diffuse Lighting > Minimum Light: Adds some lighting in caves to improve visibility.
* Fixed NaN issue with reflection filtering
* Added recursive reflection tracing. The amount of reflection bounces can be configured at Reflections > Reflection Bounces
* Added smooth sunlight fade in/out during sunrise/sunset
* Implemented smooth transition between screen-space and irradiance cached lighting in reflections
* Added camera effects: motion blur & depth of field
* Improved shadow denoising

# v0.1.1

Changes over v0.1:
* Added basic water fog
* Improved diffuse temporal & spatial denoising
* Added new options:
  * Diffuse Lighting > Denoising Passes: The amount of denoising passes used for diffuse lighting.
  * Water Absorption: Controls the amount of water light absorption. Higher values make water more dense.
  * Water Reflectance: The strength of reflections on water.
  * Rayleigh Amount: The amount of rayleigh scattering in the atmosphere.
* Basic nether and end support
* Improved TAA on translucent surfaces
* Improved the look of the irradiance cache debug view