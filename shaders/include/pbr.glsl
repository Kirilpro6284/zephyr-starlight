#ifndef INCLUDE_PBR
    #define INCLUDE_PBR

    void applySpecularMap (vec4 specularData, inout vec3 albedo, out vec3 f0, out float roughness, out float emission) 
    {
        roughness = pow(1.0 - specularData.r, 2.0);
        emission = EMISSION_BRIGHTNESS * (specularData.a < 254.5 / 255.0 ? specularData.a * 255.0 / 254.0 : 0.0);

        int reflectanceValue = int(specularData.g * 255.0 + 0.5);
        float metallic;

        if (reflectanceValue < 230) {
            f0 = mix(vec3(0.04), vec3(1.0), specularData.g);
            metallic = 0.0;
        } else {
            f0 = albedo;
            metallic = float(roughness <= REFLECTION_ROUGHNESS_THRESHOLD);
        }

        albedo *= (1.0 - metallic);
    }

    void applyIntegratedSpecular (inout vec3 albedo, inout vec4 specularData, in uint blockId) {
        float albedoLum = luminance(albedo);
        blockId = blockId % 10000;

        if (blockId == 0) {
            specularData.r = 0.4 * albedoLum * albedoLum;
            specularData.g = 0.035 * albedoLum;
            specularData.a = 0.0;
            
            return;
        }

        if (blockId < 64) {
            if (blockId < 32) {
                if (blockId < 16) {
                    if (blockId < 8) {
                        if (blockId < 4) {
                            if (blockId > 1) {
                                if (blockId < 3) {
                                    specularData.a = pow(dot(albedo.rgb, vec3(0.11, 0.29, 0.60)), 2.7) * 120.0 / 255.0;
                                    albedo.rgb *= mix(vec3(0.49, 0.61, 1.0), vec3(1.0), albedoLum);
                                    albedo.rgb *= albedoLum;
                                } else {
                                    specularData.a = pow(dot(albedo.rgb, vec3(0.14, 0.37, 0.70)), 1.8) * 110.0 / 255.0;
                                    albedo.rgb *= mix(vec3(0.96, 0.61, 0.72), vec3(1.0), albedoLum);
                                }
                            }
                        } else {
                            if (blockId < 6) {
                                if (blockId < 5) {
                                    specularData.a = pow(dot(albedo.rgb, vec3(0.25, 0.22, 0.80)), 1.6) * 98.0 / 255.0;
                                    albedo.rgb *= mix(vec3(0.97, 0.65, 0.70), vec3(1.0), albedoLum);
                                } else {
                                    specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 5.0) * 1000.0, 5.0, 250.0) / 255.0;
                                    albedo.rgb *= vec3(0.98, 0.78, 0.58);
                                }
                            } else {
                                if (blockId < 7) {
                                    specularData.a = max(0.008, pow(dot(albedo.rgb, vec3(0.28, 0.66, 0.0)), 2.6) * 80.0 / 255.0);
                                    albedo.rgb *= smoothstep(0.0, 0.3, albedoLum);
                                } else {
                                    specularData.a = max(0.008, pow(dot(albedo.rgb, vec3(0.54, 0.0, 0.34)), 4.5) * 220.0 / 255.0);
                                    albedo.rgb *= smoothstep(0.0, 0.24, albedoLum);
                                }
                            }
                        }
                    } else {
                        if (blockId < 12) {
                            if (blockId < 10) {
                                if (blockId < 9) {
                                    specularData.a = max(0.008, pow(0.8 * dot(albedo.rgb, vec3(0.45, 0.53, 0.49)), 6.0) * 25.0 / 255.0);
                                    albedo.rgb *= max(0.75, albedoLum);
                                    albedo.rgb = mix(vec3(albedoLum), albedo.rgb, 2.0);
                                } else {
                                    specularData.a = max(0.008, pow(0.8 * dot(albedo.rgb, vec3(0.45, 0.53, 0.49)), 3.0) * 80.0 / 255.0);
                                }
                            } else {
                                if (blockId < 11) {
                                    specularData.a = saturate(albedo.r - albedo.g - 0.2) * 120.0 / 255.0;
                                } else {
                                    specularData.a = max(0.008, pow(0.8 * dot(albedo.rgb, vec3(0.31, 0.53, 0.49)), 2.3) * 155.0 / 255.0);
                                    albedo.rgb *= mix(vec3(0.6, 0.41, 0.3), vec3(1.0), albedoLum);
                                }
                            }
                        } else {
                            if (blockId < 14) {
                                if (blockId < 13) {
                                    if (albedo.g > 0.56 || (albedo.b < 0.2 && albedo.g < 0.145)) {
                                        specularData.a = pow(dot(albedo.rgb, vec3(0.45, 0.53, 0.59)), 3.4) * 20.0 / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.86, 0.6);
                                    } else {
                                        specularData.r = albedo.r * 0.7 + 0.3;
                                        specularData.g = 1.0;
                                    }
                                } else {
                                    if (albedo.b < 0.2 || albedo.g > 0.6) {
                                        specularData.a = pow(dot(albedo.rgb, vec3(0.45, 0.53, 0.59)), 3.4) * 20.0 / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.87, 0.64);
                                    } else {
                                        specularData.r = albedo.r * 0.7 + 0.3;
                                        specularData.g = 1.0;
                                    }
                                }
                            } else {
                                if (blockId < 15) {
                                    if (albedo.r > 0.56 || (albedo.g - albedo.b) < 0.03) {
                                        specularData.a = max(0.008, pow(dot(albedo.rgb, vec3(0.45, 0.53, 0.59)), 3.4) * 15.0 / 255.0);
                                        albedo.rgb *= vec3(0.98, 0.85, 0.6);
                                    }
                                } else {
                                    if (albedo.r > 0.56 || (albedo.g - albedo.b) < 0.03) {
                                        specularData.a = max(0.008, pow(dot(albedo.rgb, vec3(0.45, 0.53, 0.59)), 3.4) * 8.0 / 255.0);
                                        albedo.rgb *= vec3(0.98, 0.85, 0.6);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (blockId < 24) {
                        if (blockId < 20) {
                            if (blockId < 18) {
                                if (blockId < 17) {
                                    specularData.a = min(pow(dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 3.0) * 210.0, 250.0) / 255.0;
                                    albedo.rgb *= vec3(0.98, 0.89, 0.8);
                                } else {
                                    specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.3, 0.48, 0.80)), 5.0) * 240.0, 5.0, 250.0) / 255.0;
                                    albedo.rgb *= mix(vec3(0.53, 0.61, 1.0), vec3(1.0), 0.7 * albedoLum);
                                }
                            } else {
                                if (blockId < 19) {
                                    specularData.a = step(0.8, albedo.g) * 150.0 / 255.0;
                                } else {
                                    if (albedo.g > 0.5) {
                                        specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 5.0) * 1500.0, 5.0, 250.0) / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.64, 0.40);
                                    }
                                }
                            }
                        } else {
                            if (blockId < 22) {
                                if (blockId < 21) {
                                    if (albedo.b < 0.3 || albedo.g > 0.56) {
                                        specularData.a = pow(dot(albedo.rgb, vec3(0.45, 0.53, 0.59)), 3.8) * 30.0 / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.85, 0.6);
                                    } else {
                                        specularData.r = albedoLum * 0.7 + 0.3;
                                        specularData.g = 1.0;
                                    }
                                } else {
                                    if (albedo.b > 0.5) {
                                        specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.3, 0.48, 0.80)), 5.0) * 240.0, 5.0, 250.0) / 255.0;
                                        albedo.rgb *= mix(vec3(0.53, 0.61, 1.0), vec3(1.0), 0.7 * albedoLum);
                                    }
                                }
                            } else {
                                if (blockId < 23) {
                                    if (albedo.b > 0.6) {
                                        specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.3, 0.48, 0.80)), 5.0) * 240.0, 5.0, 250.0) / 255.0;
                                        albedo.rgb *= mix(vec3(0.53, 0.61, 1.0), vec3(1.0), 0.7 * albedoLum);
                                    } else {
                                        specularData.r = max(albedoLum * 0.7 + 0.17, 0.51);
                                        specularData.g = 1.0;
                                    }
                                } else {
                                    if (albedo.g > 0.325) {
                                        specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 5.0) * 1000.0, 5.0, 250.0) / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.78, 0.58);
                                    }
                                }
                            }
                        }
                    } else {
                        if (blockId < 28) {
                            if (blockId < 26) {
                                if (blockId < 25) {
                                    if (albedo.r > 0.43 || albedo.g < 0.105) {
                                        specularData.a = 0.4 * (albedo.r > 0.43 ? sqr(albedoLum) : albedoLum);
                                    }
                                } else {
                                    if (albedo.r > 0.45) {
                                        specularData.a = 3.0 * pow(dot(albedo.rgb, vec3(0.1, 0.14, 0.175)), 2.0);
                                        albedo.rgb *= mix(vec3(1.0, 0.84, 0.70), vec3(1.0), 0.35 * albedoLum);
                                    }
                                }
                            } else {
                                if (blockId < 27) {
                                    if (albedo.r > 0.45 || (albedo.g > 0.4 && albedo.r < 0.4)) {
                                        specularData.a = 3.0 * pow(dot(albedo.rgb, vec3(0.1, 0.14, 0.175)), 2.0);
                                        if (albedo.r > 0.45) albedo.rgb *= mix(vec3(1.0, 0.84, 0.70), vec3(1.0), 0.35 * albedoLum);
                                    }
                                } else {
                                    if (albedo.r > 0.4) {
                                        specularData.a = 0.2;
                                        albedo.b *= 0.7;
                                    }
                                }
                            }
                        } else {
                            if (blockId < 30) {
                                if (blockId < 29) {
                                    specularData.a = 0.1 * albedoLum;
                                } else {
                                    if ((albedo.b - 0.7 * albedo.r) > 0.31) {
                                        specularData.a = 0.7;
                                        albedo.g *= 0.6;
                                    }
                                }
                            } else {
                                if (blockId < 31) {
                                    if (albedo.g > 0.29) {
                                        specularData.a = 0.4 * sqr(albedoLum);
                                        albedo.g *= 0.8;
                                    }
                                } else {
                                    specularData.a = pow(max(0.0, dot(albedo.rgb, vec3(-0.9, 0.2, 0.4))), 2.1) * 200.0 / 255.0;
                                    if (specularData.a > 0.007) {
                                        albedo.g *= 0.9;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (blockId < 48) {
                    if (blockId < 40) {
                        if (blockId < 36) {
                            if (blockId < 34) {
                                if (blockId < 33) {
                                    if (albedo.r > 0.7) {
                                        specularData.a = pow(dot(albedo.rgb, vec3(0.9, 0.23, 0.11)), 2.1) * 140.0 / 255.0;
                                        albedo.rgb = mix(vec3(0.3, 0.06, 0.02), albedo.rgb, 0.5 * albedoLum);
                                    }
                                } else {
                                    #ifdef GLOWING_REDSTONE_BLOCK
                                        specularData.a = 0.2 * albedo.r * albedo.r * albedo.r;
                                        albedo.rgb = mix(albedo.rgb, vec3(1.0), 0.1 * albedo.r);
                                    #endif
                                }
                            } else {
                                if (blockId < 35) {
                                    if (albedo.b > 0.4) {
                                        specularData.a = 0.14;
                                    }
                                } else {
                                    specularData.a = 0.17 * max(0.2, sqr(albedoLum));
                                }
                            }
                        } else {
                            if (blockId < 38) {
                                if (blockId < 37) {
                                    specularData.a = pow(dot(albedo.rgb, vec3(0.5, 0.18, 0.34)), 3.2) * 110.0 / 255.0;
                                } else {
                                    if (albedo.r > 0.89) {
                                        specularData.a = pow(dot(albedo.rgb, vec3(0.9, 0.23, 0.11)), 2.1) * 90.0 / 255.0;
                                        albedo.rgb = mix(vec3(0.3, 0.06, 0.02), albedo.rgb, 0.5 * albedoLum);
                                    }
                                }
                            } else {
                                if (blockId < 39) {
                                    if (albedo.r > 0.4 || albedo.b > 0.56) {
                                        specularData.a = 0.3 * albedoLum;
                                        albedo *= vec3(1.0, 0.92, 0.86);
                                    } else {
                                        specularData.r = albedo.b * 0.5 + 0.6;
                                        specularData.g = 1.0;
                                    }
                                } else {
                                    specularData.r = albedo.r * 0.7 + 0.3;
                                    specularData.g = 1.0;
                                }
                            }
                        }
                    } else {
                        if (blockId < 44) {
                            if (blockId < 42) {
                                if (blockId < 41) {
                                    specularData.r = max(albedo.r * 0.6 + albedo.g * 0.2 + 0.26, 0.55);
                                    specularData.g = 1.0;
                                } else {
                                    specularData.r = albedo.b * albedo.b * albedo.b * 0.8 + 0.2;
                                    specularData.g = albedo.b * albedo.b * 0.2;
                                }
                            } else {
                                if (blockId < 43) {
                                    specularData.r = max(albedoLum * 0.7 + 0.17, 0.51);
                                    specularData.g = 1.0;
                                    albedo *= albedoLum * 0.6 + 0.4;
                                } else {
                                    specularData.r = albedo.b * 0.5 + 0.6;
                                    specularData.g = 1.0;
                                }
                            }
                        } else {
                            if (blockId < 46) {
                                if (blockId < 45) {
                                    #ifdef MIRROR_PACKED_ICE
                                        specularData.rg = vec2(1.0);
                                        albedo.rgb = vec3(1.0);
                                    #else
                                        specularData.r = albedo.b * albedo.b * 0.6 + 0.2;
                                        specularData.g = albedo.b * albedo.b * 0.2;
                                    #endif
                                } else {
                                    specularData.r = albedoLum * 0.7 + 0.25;
                                    specularData.g = albedoLum * 0.3;
                                }
                            } else {
                                if (blockId < 47) {
                                    specularData.r = albedoLum * 0.5 + 0.6;
                                    specularData.g = albedoLum * 0.08;
                                } else {
                                    specularData.r = albedoLum * 0.4 + 0.5;
                                    specularData.g = 1.0;
                                }
                            }
                        }
                    }
                } else {
                    if (blockId < 56) {
                        if (blockId < 52) {
                            if (blockId < 50) {
                                if (blockId < 49) {
                                    if (albedo.r > 0.5) {
                                        specularData.a = 0.35;
                                        albedo.rgb *= vec3(1.0, 0.87, 0.84);
                                    }
                                } else {
                                    if (albedo.r > 0.49) {
                                        specularData.a = sqr(albedo.r - 0.49) * 0.75;
                                    }
                                }
                            } else {
                                if (blockId < 51) {
                                    if (albedo.b > 0.4) {
                                        specularData.a = sqr(albedo.b - 0.4) * 0.6;
                                    }
                                } else {
                                    if (albedo.r > 0.5) {
                                        specularData.a = min(pow(dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 3.0) * 210.0, 250.0) / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.89, 0.8);
                                    }
                                }
                            }
                        } else {
                            if (blockId < 54) {
                                if (blockId < 53) {
                                    if (albedo.b > 0.6) {
                                        specularData.a = sqr(sqr(albedo.b)) * 0.2;
                                    }
                                } else {
                                    if (albedo.r > 0.6) {
                                        specularData.a = 0.2;
                                    }
                                }
                            } else {
                                if (blockId < 55) {
                                    if (albedo.r > 0.75) {
                                        specularData.a = albedo.r - 0.75;
                                    }
                                } else {
                                    if ((albedo.r - 0.3 * albedo.b) > 0.87) {
                                        specularData.a = 0.6;
                                    }
                                }
                            }
                        }
                    } else {
                        if (blockId < 60) {
                            if (blockId < 58) {
                                if (blockId < 57) {
                                    if (albedo.r > 0.6) {
                                        specularData.a = 0.2;
                                    } else {
                                        specularData.a = sqr(sqr(smoothstep(0.3, 1.0, albedo.b))) * 60.0 / 255.0;
                                    }
                                } else {
                                    if (albedo.r > 0.79) {
                                        specularData.a = 0.15;
                                        albedo.g *= 0.7;
                                    }
                                }
                            } else {
                                if (blockId < 59) {
                                    specularData.a = smoothstep(0.02, 1.0, albedo.g * albedo.b);
                                } else {
                                    specularData.a = smoothstep(0.22, 1.0, albedo.r - albedo.b);
                                }
                            }
                        } else {
                            if (blockId < 62) {
                                if (blockId < 61) {
                                    specularData.a = albedo.r * 0.5 - albedo.b * 0.306;
                                    specularData.r = min(albedo.r * 0.5 + 0.6, 0.96);
                                    specularData.g = albedo.g * 0.8 - 0.4;
                                    albedo.g *= 0.75;
                                } else {
                                    specularData.r = min(albedo.r * 0.5 + 0.6, 0.96);
                                    specularData.g = albedo.g * 0.8 - 0.4;
                                }
                            } else {
                                if (blockId < 63) {
                                    specularData.a = albedo.b * 0.6 + 0.05;
                                } else {
                                    specularData.a = 0.04;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (blockId < 96) {
                if (blockId < 80) {
                    if (blockId < 72) {
                        if (blockId < 68) {
                            if (blockId < 66) {
                                if (blockId < 65) {
                                    if (albedo.g > 0.8) specularData.a = 0.02 + albedo.g - albedo.b * 0.95;
                                } else {
                                    if ((albedo.g - albedo.r) > 0.5) specularData.a = 0.4;
                                } 
                            } else {
                                if (blockId < 67) {
                                    specularData.a = smoothstep(0.15, 0.6, sqr(albedoLum)) * 0.12;
                                } else {
                                    if ((albedo.r - 1.4 * albedo.b) > 0.07) specularData.a = smoothstep(0.07, 0.8, albedo.r);
                                }  
                            } 
                        } else {
                            if (blockId < 70) {
                                if (blockId < 69) {
                                    if (albedo.g > 0.2) specularData.a = albedo.g;
                                } else {
                                    specularData.a = smoothstep(0.01, 0.1, dot(albedo, vec3(0.005, 0.05, 0.01)));
                                } 
                            } else {
                                if (blockId < 71) {
                                    #ifdef GLOWING_ORES
                                        specularData.a = (maxOf(albedo) - minOf(albedo) - 0.12) * 70.0 / 255.0;
                                    #endif
                                } else {
                                    #ifdef GLOWING_ORES
                                        specularData.a = step(0.26, albedo.g) * 40.0 / 255.0;
                                    #endif
                                } 
                            } 
                        } 
                    } else {
                        if (blockId < 76) {
                            if (blockId < 74) {
                                if (blockId < 73) {
                                    if (abs(albedo.r - albedo.g) > 0.15 || albedo.g > 0.65) {
                                        specularData.a = clamp(pow(0.7 * dot(albedo.rgb, vec3(0.5, 0.58, 0.66)), 5.0) * 1000.0, 5.0, 250.0) / 255.0;
                                        albedo.rgb *= vec3(0.98, 0.78, 0.58);
                                    }
                                } else {
                                    #ifdef GLOWING_CONCRETE_POWDER
                                        specularData.a = max(0.008, albedoLum - 0.2);
                                    #endif

                                    specularData.r = 0.14;
                                    specularData.g = 0.3 * albedoLum * albedoLum;
                                } 
                            } else {
                                if (blockId < 75) {
                                    #ifdef GLOWING_LAPIS_BLOCK
                                        specularData.a = albedo.g * 0.7 - 0.1;
                                        albedo.g *= 0.76;
                                    #endif
                                } else {
                                    if (albedo.g > 0.5) {
                                        specularData.a = albedo.r - 0.1;
                                    }
                                } 
                            } 
                        } else {
                            if (blockId < 78) {
                                if (blockId < 77) {
                                    if (abs(albedo.r - albedo.b) < 0.04) {
                                        specularData.a = albedo.r * 0.6 - 0.1;
                                    } else {
                                        specularData.r = max(albedo.r * 0.6 + albedo.g * 0.2 + 0.26, 0.55);
                                        specularData.g = 1.0;
                                    }
                                } else {
                                    if (abs(albedo.r - albedo.b) < 0.04) {
                                        specularData.a = albedo.r * 0.4 - 0.1;
                                    }
                                } 
                            } else {
                                if (blockId < 79) {
                                    if (abs(albedo.r - albedo.b) < 0.12) {
                                        specularData.a = albedo.r * 0.2 - 0.04;
                                    }
                                } else {
                                    if (albedo.b < 0.15 || albedo.r > 0.54) {
                                        specularData.a = max(0.007, albedo.r * 0.05);
                                    }
                                } 
                            } 
                        } 
                    }
                } else {
                    if (blockId < 88) {
                        if (blockId < 84) {
                            if (blockId < 82) {
                                if (blockId < 81) {
                                    if ((albedo.b < 0.15 || albedo.r > 0.54) && albedo.g < 0.64) {
                                        specularData.a = max(0.008, albedo.r * 0.09);
                                        albedo.rgb = mix(vec3(albedoLum), albedo.rgb, 0.75);
                                    }
                                } else {
                                    if (albedo.g > 0.5) {
                                        specularData.a = albedo.r - 0.1;
                                    } else {
                                        specularData.r = max(albedo.r * 0.6 + albedo.g * 0.2 + 0.26, 0.55);
                                        specularData.g = 1.0;
                                    }
                                } 
                            } else {
                                if (blockId < 83) {
                                    specularData.r = max(albedo.r * 0.6 + 0.35, 0.65);
                                    specularData.g = 0.03 * albedoLum + 0.03;
                                } else {
                                    if (albedo.r > 0.7 && albedo.g > 0.53) {
                                        specularData.a = 0.4;
                                    }
                                } 
                            } 
                        } else {
                            if (blockId < 86) {
                                if (blockId < 85) {
                                    albedo = vec3(1.0);
                                    specularData = vec4(1.0, 1.0, 0.0, 0.0);
                                } else {
                                    specularData.r = 0.25 * albedoLum * albedoLum;
                                    specularData.g = 0.015 * albedoLum;
                                    specularData.a = 0.0;
                                } 
                            } else {
                                if (blockId < 87) {
                                    if (albedo.r > 0.5) {
                                        specularData.a = 0.1 * albedo.b * albedo.b;
                                    }
                                } else {
                                    #ifdef GLOWING_ARMOR_TRIMS
                                        specularData.a = max(0.008, 0.12 * albedoLum * albedoLum);
                                    #endif
                                } 
                            } 
                        } 
                    } else {
                        if (blockId < 92) {
                            if (blockId < 90) {
                                if (blockId < 89) {
                                    specularData.a = 0.5;
                                } else {
                                    specularData.r = 0.72 * albedoLum * albedoLum;
                                    specularData.g = 0.07 * albedoLum;
                                    specularData.a = 0.0;
                                } 
                            } else {
                                if (blockId < 91) {
                                    if (albedo.b > 0.25) {
                                        specularData.a = 0.1 * albedoLum * albedoLum;
                                        albedo.rgb *= albedoLum;
                                    }
                                } else {
                                    
                                } 
                            } 
                        } else {
                            if (blockId < 94) {
                                if (blockId < 93) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 95) {

                                } else {
                                    
                                } 
                            }  
                        } 
                    } 
                }
            } else {
                if (blockId < 112) {
                    if (blockId < 104) {
                        if (blockId < 100) {
                            if (blockId < 98) {
                                if (blockId < 97) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 99) {

                                } else {
                                    
                                } 
                            }  
                        } else {
                            if (blockId < 102) {
                                if (blockId < 101) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 103) {

                                } else {
                                    
                                } 
                            }  
                        } 
                    } else {
                        if (blockId < 108) {
                            if (blockId < 106) {
                                if (blockId < 105) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 107) {

                                } else {
                                    
                                } 
                            }  
                        } else {
                            if (blockId < 110) {
                                if (blockId < 109) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 111) {

                                } else {
                                    
                                } 
                            }  
                        } 
                    }
                } else {
                    if (blockId < 120) {
                        if (blockId < 116) {
                            if (blockId < 114) {
                                if (blockId < 113) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 115) {

                                } else {
                                    
                                } 
                            }  
                        } else {
                            if (blockId < 118) {
                                if (blockId < 117) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 119) {

                                } else {
                                    
                                } 
                            }  
                        } 
                    } else {
                        if (blockId < 124) {
                            if (blockId < 122) {
                                if (blockId < 121) {

                                } else {
                                    
                                } 
                            } else {
                                if (blockId < 123) {

                                } else {
                                    
                                } 
                            }  
                        } else {
                            if (blockId < 126) {
                                if (blockId < 125) {

                                } else {
                                    
                                } 
                            } else {
                                 if (blockId < 127) {

                                } else {
                                    
                                } 
                            }  
                        } 
                    } 
                }
            }  
        }

        albedo = saturate(albedo);
        specularData = saturate(specularData);
    }

#endif