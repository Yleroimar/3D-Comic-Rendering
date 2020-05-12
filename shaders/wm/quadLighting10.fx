///////////////////////////////////////////////////////////////////////////////////////////////////
// quadLighting10.fx (HLSL)
// Brief: Includes algorithms for ligthing.
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////////
//    _ _       _     _   _             
//   | (_) __ _| |__ | |_(_)_ __   __ _ 
//   | | |/ _` | '_ \| __| | '_ \ / _` |
//   | | | (_| | | | | |_| | | | | (_| |
//   |_|_|\__, |_| |_|\__|_|_| |_|\__, |
//        |___/                   |___/ 
///////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides the algorithm for lighting such as:
// 1.- For including negative diffuse in the diffuse [WM]
// 2.- Tinting the discrete light based on light intensity [WM]
// 3.- Shading with tinting and desaturation in the style of Water Memory [WM]
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "quadCommon.fxh"
#include "..\\include\\quadColorTransform.fxh"



// VARIABLES
float positiveScale = 1.0; // The length of the range given for positive diffuse

float gSurfaceThresholdHigh = 0.9;
float gSurfaceThresholdMid = 0.5;

float gTransitionHighMid = 0.025;
float gTransitionMidLow = 0.025;

float gSurfaceHighIntensity = 1.1;
float gSurfaceMidIntensity = 0.7;
float gSurfaceLowIntensity = 0.5;


float3 gShadingTint = float3(1.0, 1.0, 1.0);
float gShadingTintWeight = 1.0;



// FIXED VARIABLES
static const int cHueModelPick = 0; // 0-HSV and 1-HSL



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

float3 toHueModel(float3 rgb) {
    return cHueModelPick == 0
        ? rgb2hsv2(rgb)
        : rgb2hsl(rgb);
}
float3 fromHueModel(float3 hueModelColor) {
    return cHueModelPick == 0
        ? hsv2rgb(hueModelColor)
        : hsl2rgb(hueModelColor);
}


float getColorIntensity(float3 color) { return toHueModel(color).z; }


float getDiscreteIntensity(float3 lightColor) {
    float intensity = getColorIntensity(lightColor);

    float thresholds[4] = {
        gSurfaceThresholdMid - 0.5 * gTransitionMidLow,
        gSurfaceThresholdMid + 0.5 * gTransitionMidLow,
        gSurfaceThresholdHigh - 0.5 * gTransitionHighMid,
        gSurfaceThresholdHigh + 0.5 * gTransitionHighMid
    };

    if (intensity > thresholds[3])
        return gSurfaceHighIntensity;
    
    if (intensity > thresholds[2])
        return lerp(gSurfaceMidIntensity, gSurfaceHighIntensity,
                    (intensity - thresholds[2]) / gTransitionHighMid);
    
    if (intensity > thresholds[1])
        return gSurfaceMidIntensity;
    
    if (intensity > thresholds[0])
        return lerp(gSurfaceLowIntensity, gSurfaceMidIntensity,
                    (intensity - thresholds[0]) / gTransitionMidLow);
    
    return gSurfaceLowIntensity;
}


float3 setLightLevel(float intensity, float3 lightRGB) {
    float3 hueModelColor = toHueModel(lightRGB);

    hueModelColor.z = intensity;

    return fromHueModel(hueModelColor);
}



//        _ _                   _           _ _       _     _   
//     __| (_)___  ___ _ __ ___| |_ ___    | (_) __ _| |__ | |_ 
//    / _` | / __|/ __| '__/ _ \ __/ _ \   | | |/ _` | '_ \| __|
//   | (_| | \__ \ (__| | |  __/ ||  __/   | | | (_| | | | | |_ 
//    \__,_|_|___/\___|_|  \___|\__\___|   |_|_|\__, |_| |_|\__|
//                                              |___/           
// Contributor: Oliver Vainumäe
// Makes the diffuse light have a look of light levels
float4 discreteLightFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);
    
    float3 light = loadDiffuseColor(loc);
    float intensity = getDiscreteIntensity(light);
    float3 discrete = setLightLevel(intensity, light);

    return float4(discrete, intensity);
}



//        _               _          _   _       _   _             
//    ___| |__   __ _  __| | ___    | |_(_)_ __ | |_(_)_ __   __ _ 
//   / __| '_ \ / _` |/ _` |/ _ \   | __| | '_ \| __| | '_ \ / _` |
//   \__ \ | | | (_| | (_| |  __/   | |_| | | | | |_| | | | | (_| |
//   |___/_| |_|\__,_|\__,_|\___|    \__|_|_| |_|\__|_|_| |_|\__, |
//                                                           |___/ 
// Contributor: Oliver Vainumäe
// Tints the shade in diffuse
float4 tintShadeFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 lightTex = loadDiscreteDiffuseTex(loc);
    float3 discreteLight = lightTex.rgb;
    float intensity = lightTex.a;

    float tintWeight = (1.0 - intensity) * gShadingTintWeight;
    float3 tinted = discreteLight + tintWeight * gShadingTint;
    tinted /= 1.0 + tintWeight;

    return float4(tinted, intensity);
}



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

    float4 diffuseTex = loadDiffuseTex(loc);

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



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                

technique11 discreteLight {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, discreteLightFrag()));
    }
};

technique11 tintShade {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, tintShadeFrag()));
    }
};

technique11 includeNegatives {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, includeNegativesFrag()));
    }
};