////////////////////////////////////////////////////////////////////////////////////////////////////
// quadHatching10.fx (HLSL)
// Brief: Hatching operations for MNPR
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////////////////////
//    _           _       _     _             
//   | |__   __ _| |_ ___| |__ (_)_ __   __ _ 
//   | '_ \ / _` | __/ __| '_ \| | '_ \ / _` |
//   | | | | (_| | || (__| | | | | | | | (_| |
//   |_| |_|\__,_|\__\___|_| |_|_|_| |_|\__, |
//                                      |___/
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader file provides algorithms for hatching effects in MNPR
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"
#include "include\\quadColorTransform.fxh"

// TEXTURES
Texture2D gRenderTex;
Texture2D gDiffuseTex;
Texture2D gSpecularTex;
Texture2D gHatchCtrl;
Texture2D gSubstrateTex;
Texture2D gNormalsTex;


// VARIABLES
float gHatchMultiplier = 1.0;

float gTestingValue = 0.5;

float gThresholdColor = 0.35;
float gThresholdDiffuse = 1.0;



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }

float4 loadDiffuseTex(int3 loc) { return gDiffuseTex.Load(loc); }
float4 loadSpecularTex(int3 loc) { return gSpecularTex.Load(loc); }

float2 loadUVs(int3 loc) { return gNormalsTex.Load(loc).ba; }

float4 loadSubstrateTex(int3 loc) { return gSubstrateTex.Load(loc); }
float loadSubstrateHeight(int3 loc) { return loadSubstrateTex(loc).b; }

float loadHatchCtrl(int3 loc) { return gHatchCtrl.Load(loc).g; }


// float colorIntensity(float3 color) { return length(color); }
float colorLightness(float3 color) { return rgb2hsv2(color).z; }
float colorHatchingLightness(int3 loc) {
    float colorL = colorLightness(loadColorTex(loc).rgb);
    return colorL / gThresholdColor;
}

// float diffuseIntensity(float3 diffuseColor) { return length(diffuseColor); }
float diffuseLightness(float3 diffuseColor) { return rgb2hsv2(diffuseColor).z; }
float diffuseHatchingLightness(int3 loc) {
    float diffuseL = diffuseLightness(loadDiffuseTex(loc).rgb);
    return diffuseL / gThresholdDiffuse;
}

float specularIntensity(float3 specularColor) { return max(specularColor); }

float hatchingIntensity(int3 loc) {
    // specular is used to cancel the hatching
    float specular = specularIntensity(loadSpecularTex(loc).rgb);
    
    // substrate height sets the texture of the hatching
    float substrateHeight = loadSubstrateHeight(loc);

    // color and diffuse is used to choose where to place substrate texture
    float lightnessColor = colorHatchingLightness(loc);
    float lightnessDiffuse = diffuseHatchingLightness(loc);
    float lightness = min(1.0, min(lightnessColor, lightnessDiffuse));
    
    float hatchCtrl = loadHatchCtrl(loc);
    hatchCtrl = (1.0 + hatchCtrl) * gHatchMultiplier;

    //float strength = saturate(substrateHeight * hatchCtrl - lightness);
    //float strength = max(0, substrateHeight * hatchCtrl - lightness);
    float strength = substrateHeight * hatchCtrl - lightness;

    // multiplied with 2.5 for better practical balance
    return (1.0 - specular) * 2.5 * strength;// * hatchCtrl;
}


//    _           _       _     _             
//   | |__   __ _| |_ ___| |__ (_)_ __   __ _ 
//   | '_ \ / _` | __/ __| '_ \| | '_ \ / _` |
//   | | | | (_| | || (__| | | | | | | | (_| |
//   |_| |_|\__,_|\__\___|_| |_|_|_| |_|\__, |
//                                      |___/ 
// Contributor: Oliver Vainumäe
// Adds substrate-based hatching to the render
float4 hatchTestFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);
    
    if (renderTex.a == 0.0) return renderTex;

    float hatchIntensity = hatchingIntensity(loc);

    float3 outColor = lerp(renderTex.rgb, float3(0,0,0), saturate(hatchIntensity));

    return float4(outColor, renderTex.a);
}


// UNFINISHED, UNUSED
float4 hatchingUVsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 uvTex = loadUVs(loc);

    float light = length(loadDiffuseTex(loc).rgb);

    float modulus = 0.025;

    uvTex = uvTex % modulus;

    float intensity = 0.0;

    float factor = (uvTex.r + uvTex.g) % modulus;

    if (factor < 0.05 * modulus)
        intensity = 1.0 - factor / (0.05 * modulus);
    
    if (0.95 * modulus < factor)
        intensity = (1.0 - factor) / (0.05 * modulus);

    return float4(intensity.rrr, 1.0);
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                
// SUBSTRATE-BASED HATCHING [WM]
technique11 hatchTest {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, hatchTestFrag()));
    }
};

// UNFINISHED, UNUSED
technique11 hatchUVsTest {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, hatchingUVsFrag()));
    }
};
