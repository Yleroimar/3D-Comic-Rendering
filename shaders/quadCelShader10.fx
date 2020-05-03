////////////////////////////////////////////////////////////////////////////////////////////////////
// quadCelShader.fx (HLSL)
// Brief: Cel shading algorithms
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////////////////////
//     ____     _    ____  _               _           
//    / ___|___| |  / ___|| |__   __ _  __| | ___ _ __ 
//   | |   / _ \ |  \___ \| '_ \ / _` |/ _` |/ _ \ '__|
//   | |__|  __/ |   ___) | | | | (_| | (_| |  __/ |   
//    \____\___|_|  |____/|_| |_|\__,_|\__,_|\___|_|   
//                                                     
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides alorithms for cel shading of surfaces.
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"
#include "include\\quadColorTransform.fxh"

// TEXTURES
Texture2D gSpecularTex;
Texture2D gDiffuseTex;
Texture2D gLightTex;


// VARIABLES
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
static const int cHueModelPick = 1;


//float4 desaturateColorWithShadows(vertexOutput i) : SV_Target{
//    int3 loc = int3(i.pos.xy, 0);
//
//    float3 renderTex = gColorTex.Load(loc).rgb;
//    float3 diffuseTex = gDiffuseTex.Load(loc).rgb;
//    float3 specularTex = gSpecularTex.Load(loc).rgb;
//
//    float3 remainder = RGBtoHSV(renderTex);
//
//    float3 color = remainder;
//
//    return float4(color, 1.0);
//}

float4 loadDiffuseTex(int3 loc) { return gDiffuseTex.Load(loc); }
float3 loadDiffuseColor(int3 loc) { return loadDiffuseTex(loc).rgb; }
float4 loadSpecularTex(int3 loc) { return gSpecularTex.Load(loc); }
float3 loadSpecularColor(int3 loc) { return loadSpecularTex(loc).rgb; }
float4 loadLightTex(int3 loc) { return gLightTex.Load(loc); }
float3 loadLightColor(int3 loc) { return loadLightTex(loc).rgb; }

float3 toHueModel(float3 rgb) {
    switch (cHueModelPick) {
        case 0: return rgb2hsv2(rgb);
    }

    return rgb2hsl(rgb);
}
float3 fromHueModel(float3 hueModelColor) {
    switch (cHueModelPick) {
        case 0: return hsv2rgb(hueModelColor);
    }

    return hsl2rgb(hueModelColor);
}

float getColorIntensity(float3 color) { return toHueModel(color).z; }

float getDiscreteIntensity(float3 diffuseColor, float3 specularColor) {
    float diffuse = getColorIntensity(diffuseColor);
    float specular = getColorIntensity(specularColor);
    specular = pow(specular, gSpecularPower);

    float intensity = gDiffuseCoefficient * diffuse
                    + gSpecularCoefficient * specular;

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


float3 setLightBrightness(float intensity, float3 lightRGB) {
    float3 hueModelColor = toHueModel(lightRGB);

    hueModelColor.z = intensity;

    return fromHueModel(hueModelColor);
}


float4 discreteLightFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    // get light value
    float3 diffuseColor = loadDiffuseColor(loc);
    float3 specularColor = loadSpecularColor(loc);

    float3 light = diffuseColor + specularColor;

    float intensity = getDiscreteIntensity(diffuseColor, specularColor);

    return float4(setLightBrightness(intensity, light), 1.0);
}


float3 shadeColorHSV(float intensity, float3 light, float3 color) {
    // set the intensity of light
    light = rgb2hsv2(light);
    light.z = intensity;
    light = hsv2rgb(light);

    color = rgb2hsv2(color);

    // still need to change value
    // color.y *= intensity;
    color.z *= intensity;

    color.y *= min(1.0, 1.5 * intensity);
    /* color.z *= min(1.0, 1.1 * intensity); */

    color = hsv2rgb(color);

    // tried brightening the light color
    /* light = rgb2hsv2(light);
    //light.y = 1.0;
    light.z = 1.0;
    light = hsv2rgb(light); */

    color *= light;

    return color;
}


float3 shadeColorHSL(float intensity, float3 light, float3 color) {
    // set the intensity of light
    light = rgb2hsl(light);
    light.z = intensity;
    light = hsl2rgb(light);

    color = rgb2hsl(color);

    // still need to change value
    // color.y *= intensity;
    color.z *= intensity;

    color.y *= min(1.0, 1.5 * intensity);
    /* color.z *= min(1.0, 1.1 * intensity); */

    color = hsl2rgb(color);

    // tried brightening the light color
    /* light = rgb2hsv2(light);
    //light.y = 1.0;
    light.z = 1.0;
    light = hsv2rgb(light); */

    color *= light;

    return color;
}


float3 shadeColor(float intensity, float3 light, float3 color) {
    return shadeColorHSV(intensity, light, color);
    // return shadeColorHSL(intensity, light, color);
}


float4 shadeSurfacesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);

    // if the pixel is transparent, we're not gonna modify it.
    if (renderTex.a == 0.0) return renderTex;
    
    float4 lightTex = gLightTex.Load(loc);

    float3 light = lightTex.rgb;
    float intensity = getColorIntensity(light);
    float3 color = renderTex.rgb;

    return float4(shadeColor(intensity, light, color), renderTex.a);
}


float4 celSurfaces1Frag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = gColorTex.Load(loc);

    // if the pixel is transparent, we're not gonna modify it.
    if (renderTex.a == 0.0) return renderTex;
    
    float3 diffuseColor = loadDiffuseColor(loc);
    float3 specularColor = loadSpecularColor(loc);

    float3 light = diffuseColor + specularColor;

    float intensity = getDiscreteIntensity(diffuseColor, specularColor);
    
    // to HSV; desaturate, darken; back to RGB; * lightColor
    float3 color = renderTex.rgb;

    return float4(shadeColor(intensity, light, color), renderTex.a);
    //return float4(renderTex.rgb * intensity, 1.0);
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                
technique11 celSurfaces1 {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, celSurfaces1Frag()));
    }
};

technique11 discreteLight {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, discreteLightFrag()));
    }
};

technique11 shadeSurfaces {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, shadeSurfacesFrag()));
    }
};