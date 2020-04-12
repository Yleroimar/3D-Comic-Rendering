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
Texture2D gStylizationTex;
Texture2D gDepthTex;
Texture2D gDiffuseTex;
Texture2D gSpecularTex;
Texture2D gHatchCtrl;
Texture2D gSubstrateTex;

Texture2D gUVsTex;


// VARIABLES

float gTestingValue = 0.5;

float diffuseThreshold = 2.0; //0.85;
float darkThreshold = 0.15;


float colorHatchingIntensity(int3 loc) {
    float colorDarkness = length(gColorTex.Load(loc).rgb);

    return colorDarkness / darkThreshold;
}

float diffuseHatchingIntensity(int3 loc) {
    float diffuse = length(gDiffuseTex.Load(loc).rgb);

    return diffuse / diffuseThreshold;
}

float hatchingIntensity(int3 loc) {
    // specular is used to cancel the hatching
    float specular = max3(gSpecularTex.Load(loc).rgb);
    
    // substrate height sets the texture of the hatching
    // combined with hatching texture
    float substrateHeight = gSubstrateTex.Load(loc).b;

    float intensityColor = colorHatchingIntensity(loc);
    float intensityDiffuse = diffuseHatchingIntensity(loc);

    float intensity = min(1.0, min(intensityColor, intensityDiffuse));
    
    float hatchCtrl = gHatchCtrl.Load(loc).g;

    float strengthScale = gTestingValue;

    //float strength = saturate((substrateHeight - intensity) / strengthScale);

    float strength = saturate((substrateHeight - intensity) / strengthScale);

    return strength + strength * hatchCtrl;
}

float4 hatchTestFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    float4 colorTex = gStylizationTex.Load(loc);
    
    if (colorTex.a == 0.0) return colorTex;

    float intensity = hatchingIntensity(loc);

    float reversed = 1.0 - intensity;

    return float4(colorTex.rgb * reversed, colorTex.a);
}


float4 hatchingUVsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 uvTex = gUVsTex.Load(loc).ba;

    float light = length(gDiffuseTex.Load(loc).rgb);

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
