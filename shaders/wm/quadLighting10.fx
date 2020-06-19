/////////////////////////////////////////////////////////////////////////////////////////
// quadLighting10.fx (HLSL)
// Brief: Including the negative light for wider diffuse light range.
// Contributors: Oliver Vainumäe
/////////////////////////////////////////////////////////////////////////////////////////
//    _ _       _     _   _             
//   | (_) __ _| |__ | |_(_)_ __   __ _ 
//   | | |/ _` | '_ \| __| | '_ \ / _` |
//   | | | (_| | | | | |_| | | | | (_| |
//   |_|_|\__, |_| |_|\__|_|_| |_|\__, |
//        |___/                   |___/ 
/////////////////////////////////////////////////////////////////////////////////////////
// This shader provides the algorithm for transforming diffuse to include negative light.
/////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"

Texture2D gDiffuseTex;

// VARIABLES
float positiveScale = 1.0; // The length of the range given for positive diffuse

//                           _   _                   _ _  __  __                
//    _ __   ___  __ _  __ _| |_(_)_   _____      __| (_)/ _|/ _|_   _ ___  ___ 
//   | '_ \ / _ \/ _` |/ _` | __| \ \ / / _ \    / _` | | |_| |_| | | / __|/ _ \
//   | | | |  __/ (_| | (_| | |_| |\ V /  __/   | (_| | |  _|  _| |_| \__ \  __/
//   |_| |_|\___|\__, |\__,_|\__|_| \_/ \___|    \__,_|_|_| |_|  \__,_|___/\___|
//               |___/                                                          
// Contributor: Oliver Vainumäe
// Includes the negative diffuse in areas of 0 positive diffuse
float4 includeNegativesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    // The length of the range given for negative diffuse
    float negativeScale = 1.0 - positiveScale;

    float4 diffuseTex = gDiffuseTex.Load(loc);

    // transforming the positive diffuse higher
    float3 color = negativeScale + positiveScale * diffuseTex.rgb;

    // in case there is no positive diffuse, negative diffuse is used
    if (length(diffuseTex.rgb) == 0) {
        float value = negativeScale - negativeScale * diffuseTex.a;

        // negative diffuse has no color
        color = float3(value, value, value);
    }

    return float4(color, 1.0);
}


technique11 includeNegatives {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, includeNegativesFrag()));
    }
};