////////////////////////////////////////////////////////////////////////////////
// quadSurfaceShading10.fx (HLSL)
// Brief: Shading of surfaces in the style of Water Memory.
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////
//                    __                        _               _ _             
//    ___ _   _ _ __ / _| __ _  ___ ___     ___| |__   __ _  __| (_)_ __   __ _ 
//   / __| | | | '__| |_ / _` |/ __/ _ \   / __| '_ \ / _` |/ _` | | '_ \ / _` |
//   \__ \ |_| | |  |  _| (_| | (_|  __/   \__ \ | | | (_| | (_| | | | | | (_| |
//   |___/\__,_|_|  |_|  \__,_|\___\___|   |___/_| |_|\__,_|\__,_|_|_| |_|\__, |
//                                                                        |___/ 
////////////////////////////////////////////////////////////////////////////////
// This shader provides algorithms for surface shading such as:
// 1.- Making the light discrete based on light intensity [WM]
// 2.- Tinting the discrete light based on light intensity [WM]
// 3.- Shading with tinting and desaturation in the style of Water Memory [WM]
////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"
#include "..\\include\\quadColorTransform.fxh"

Texture2D gRenderTex;
Texture2D gDepthTex;
Texture2D gDiffuseTex;
Texture2D gSpecularTex;
Texture2D gLightTex;


// VARIABLES
float3 gShadingTint = float3(1.0, 1.0, 1.0);
float gShadingTintWeight = 1.0;
float gShadingSaturationWeight = 1.0;

float gSurfaceThresholdHigh = 0.9;
float gSurfaceThresholdMid = 0.5;

float gTransitionHighMid = 0.025;
float gTransitionMidLow = 0.025;

float gSurfaceHighIntensity = 1.1;
float gSurfaceMidIntensity = 0.7;
float gSurfaceLowIntensity = 0.5;

float gDiffuseCoefficient = 0.6;
float gSpecularCoefficient = 0.4;

float gSpecularPower = 1.0;


// FIXED VARIABLES
static const int cHueModelPick = 0; // 0-HSV and 1-HSL


//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float4 loadDiffuseTex(int3 loc) { return gDiffuseTex.Load(loc); }
float3 loadDiffuseColor(int3 loc) { return loadDiffuseTex(loc).rgb; }

float4 loadSpecularTex(int3 loc) { return gSpecularTex.Load(loc); }
float3 loadSpecularColor(int3 loc) { return loadSpecularTex(loc).rgb; }

float4 loadLightTex(int3 loc) { return gLightTex.Load(loc); }
float3 loadLightColor(int3 loc) { return loadLightTex(loc).rgb; }

float4 loadDepthTex(int3 loc) { return gDepthTex.Load(loc); }
float loadDepth(int3 loc) { return loadDepthTex(loc).r; }

float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }
float3 loadRender(int3 loc) { return loadRenderTex(loc).rgb; }

float3 toHueModel(float3 rgb) {
    if (cHueModelPick == 0) return rgb2hsv2(rgb);

    return rgb2hsl(rgb);
}
float3 fromHueModel(float3 hueModelColor) {
    if (cHueModelPick == 0) return hsv2rgb(hueModelColor);

    return hsl2rgb(hueModelColor);
}

float getColorIntensity(float3 color) { return toHueModel(color).z; }

float getDiscreteIntensity(float3 lightColor) {
    float intensity = getColorIntensity(lightColor);

    float high2midMax = gSurfaceThresholdHigh + 0.5 * gTransitionHighMid;
    if (intensity > high2midMax)
        return gSurfaceHighIntensity;
    
    float high2midMin = gSurfaceThresholdHigh - 0.5 * gTransitionHighMid;
    if (intensity > high2midMin)
        return lerp(gSurfaceMidIntensity, gSurfaceHighIntensity,
                    (intensity - high2midMin) / gTransitionHighMid);
    
    float mid2lowMax = gSurfaceThresholdMid + 0.5 * gTransitionMidLow;
    if (intensity > mid2lowMax)
        return gSurfaceMidIntensity;
    
    float mid2lowMin = gSurfaceThresholdMid - 0.5 * gTransitionMidLow;
    if (intensity > mid2lowMin)
        return lerp(gSurfaceLowIntensity, gSurfaceMidIntensity,
                    (intensity - mid2lowMin) / gTransitionMidLow);
    
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
float4 discreteLightFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    // float intensity2 = getColorIntensity(loadDiffuseColor(loc));
    // return float4(intensity2, intensity2, intensity2, intensity2);
    
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

    float4 lightTex = loadLightTex(loc);
    float3 discreteLight = lightTex.rgb;
    float intensity = lightTex.a;

    float depth = 1.0;
    // depth = loadDepth(loc);

    float tintWeight = (1.0 - intensity) * gShadingTintWeight * depth;
    float3 tinted = discreteLight + tintWeight * gShadingTint;
    tinted /= 1.0 + tintWeight;

    return float4(tinted, intensity);
}


float updateSaturationValue(float hueModelSaturation, float lightIntensity) {
    float darkIntensity = 1.0 - lightIntensity;

    float desaturationValue = darkIntensity * (1.0 - saturate(gShadingSaturationWeight));

    float saturationValue = 1.0 - desaturationValue;

    return hueModelSaturation * saturationValue;
}

float3 shadedSurfaceColor(float3 surfaceColor, float3 lightColor, float lightIntensity) {
    float3 hueModelColor = toHueModel(surfaceColor);

    hueModelColor.y = updateSaturationValue(hueModelColor.y, lightIntensity);

    surfaceColor = fromHueModel(hueModelColor);

    surfaceColor *= lightColor;

    return surfaceColor;
}
float3 shadedSurfaceColor(float3 surfaceColor, float4 lightTex) {
    return shadedSurfaceColor(surfaceColor, lightTex.rgb, lightTex.a);
}


//                      _ _           _   _             
//     __ _ _ __  _ __ | (_) ___ __ _| |_(_) ___  _ __  
//    / _` | '_ \| '_ \| | |/ __/ _` | __| |/ _ \| '_ \ 
//   | (_| | |_) | |_) | | | (_| (_| | |_| | (_) | | | |
//    \__,_| .__/| .__/|_|_|\___\__,_|\__|_|\___/|_| |_|
//         |_|   |_|                                    
// Contributor: Oliver Vainumäe
// Applies the shading to the surface using tinted discrete diffuse with desaturation
float4 shadeSurfacesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);

    if (renderTex.a == 0.0) return renderTex;

    float3 shadedColor = shadedSurfaceColor(renderTex.rgb, loadLightTex(loc));

    // multiplied with alpha to account for transparency.
    return float4(shadedColor.rgb * renderTex.a, renderTex.a);
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

technique11 shadeSurfaces {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, shadeSurfacesFrag()));
    }
};

