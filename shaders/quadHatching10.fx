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

// TEXTURES
Texture2D gRenderTex;
Texture2D gDepthTex;
Texture2D gDiffuseTex;
Texture2D gSpecularTex;
Texture2D gHatchCtrl;
Texture2D gSubstrateTex;
Texture2D gNormalsTex;


// VARIABLES
float gHatchMultiplier = 1.0;

float gTestingValue = 0.5;

float thresholdDiffuse = 2.0; //0.85;
float thresholdColor = 0.15;


float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }

float4 loadDiffuseTex(int3 loc) { return gDiffuseTex.Load(loc); }
float4 loadSpecularTex(int3 loc) { return gSpecularTex.Load(loc); }

float2 loadUVs(int3 loc) { return gNormalsTex.Load(loc).ba; }

float4 loadSubstrateTex(int3 loc) { return gSubstrateTex.Load(loc); }
float loadSubstrateHeight(int3 loc) { return loadSubstrateTex(loc).b; }

float loadHatchCtrl(int3 loc) { return gHatchCtrl.Load(loc).g; }


float colorIntensity(float3 color) { return length(color); }
float colorHatchingIntensity(int3 loc) {
    float colorLightness = colorIntensity(loadColorTex(loc).rgb);
    return colorLightness / thresholdColor;
}

float diffuseIntensity(float3 diffuseColor) { return length(diffuseColor); }
float diffuseHatchingIntensity(int3 loc) {
    float diffuse = diffuseIntensity(loadDiffuseTex(loc).rgb);
    return diffuse / thresholdDiffuse;
}

float specularIntensity(float3 specularColor) { return max(specularColor); }

float hatchingIntensity(int3 loc) {
    // specular is used to cancel the hatching
    float specular = specularIntensity(loadSpecularTex(loc).rgb);
    
    // substrate height sets the texture of the hatching
    float substrateHeight = loadSubstrateHeight(loc);

    // color and diffuse is used to choose where to place substrate texture
    float intensityColor = colorHatchingIntensity(loc);
    float intensityDiffuse = diffuseHatchingIntensity(loc);
    float intensity = min(1.0, min(intensityColor, intensityDiffuse));
    
    float hatchCtrl = loadHatchCtrl(loc);
    hatchCtrl = (1.0 + hatchCtrl) * gHatchMultiplier;

    float strength = saturate(substrateHeight * hatchCtrl - intensity);

    return 2.0 * strength * hatchCtrl;
}

float4 hatchTestFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);
    // return renderTex;
    
    if (renderTex.a == 0.0) return renderTex;

    float intensity = hatchingIntensity(loc);

    float renderColorIntensity = 1.0 - intensity;

    return float4(renderTex.rgb * renderColorIntensity, renderTex.a);
}


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

technique11 hatchTest {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, hatchTestFrag()));
    }
};

technique11 hatchUVsTest {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, hatchingUVsFrag()));
    }
};
