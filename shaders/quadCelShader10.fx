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
// This shader provides alorithms for cel shading.
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"
#include "include\\quadColorTransform.fxh"

// TEXTURES
//Texture2D gColorTex;
Texture2D gEdgeTex;
Texture2D gDepthTex;
Texture2D gNormalsTex;
Texture2D gSpecularTex;
Texture2D gDiffuseTex;


// VARIABLES

// Outline Shading
float edgePower = 0.1;
float edgeMultiplier = 10.0;

// Surface Shading
float surfaceThresholdHigh = 0.9;
float surfaceThresholdMid = 0.5;
float transitionHighMid = 0.025;
float transitionMidLow = 0.025;

float surfaceHighIntensity = 1.1;
float surfaceMidIntensity = 0.7;
float surfaceLowIntensity = 0.5;

float diffuseCoefficient = 0.6;
float specularCoefficient = 0.4;

float specularPower = 1.0;


float3 ambientColor = float3(0.5, 0.5, 0.5);


float3 RGBtoHSL(float3 rgb) {
    float M = max(max(rgb.r, rgb.g), rgb.b);
    float m = min(min(rgb.r, rgb.g), rgb.b);

    float c = M - m;

    float h = 0.0;

    if (c != 0.0) {
        if (M == rgb.r)
            h = mod((rgb.g - rgb.b) / c, 6.0);
        else if (M == rgb.g)
            h = (rgb.b - rgb.r) / c + 2.0;
        else if (M == rgb.b)
            h = (rgb.r - rgb.g) / c + 4.0;
    }

    h = 60.0 * h;

    float l = 0.5 * (M + m);

    float s = l == 0.0 || l == 1.0 ? 0 : (c / (1.0 - abs(2.0 * l - 1.0)));

    return float3(h, s, l);
}


float3 HSLtoRGB(float3 hsl) {
    float c = (1 - abs(2.0 * hsl.z - 1.0)) * hsl.y;

    float h = hsl.x / 60.0;

    float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));

    float3 rgb = float3(c, x, 0.0);

    if (5 < h) rgb = float3(c, 0.0, x);
    else if (4 < h) rgb = float3(x, 0.0, c);
    else if (3 < h) rgb = float3(0.0, x, c);
    else if (2 < h) rgb = float3(0.0, c, x);
    else if (1 < h) rgb = float3(x, c, 0.0);

    float m = hsl.z - 0.5 * c;

    return rgb + m;
}


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



//     __ _           _ _                                                  _     
//    / _(_)_ __   __| (_)_ __   __ _     _ __   ___  _ __ _ __ ___   __ _| |___ 
//   | |_| | '_ \ / _` | | '_ \ / _` |   | '_ \ / _ \| '__| '_ ` _ \ / _` | / __|
//   |  _| | | | | (_| | | | | | (_| |   | | | | (_) | |  | | | | | | (_| | \__ \
//   |_| |_|_| |_|\__,_|_|_| |_|\__, |   |_| |_|\___/|_|  |_| |_| |_|\__,_|_|___/
//                              |___/                                            
// Finding normalmap from depthmap. [unfinished: does the job partially]
float4 findNormals1(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0);

    Texture2D sourceTex = gDepthTex;
    int stepSize = 1;

    float dx = sourceTex.Load(loc - int3(stepSize, 0, 0)).r - sourceTex.Load(loc + int3(stepSize, 0, 0)).r;
    float dy = sourceTex.Load(loc + int3(0, stepSize, 0)).r - sourceTex.Load(loc - int3(0, stepSize, 0)).r;

    float2 gradient = float2(dx, dy);

    float3 normalShift = float3(gradient, 0.0f);
    float3 surfaceNormal = float3(0.0, 0.0, 1.0f);
    float3 normal = normalize(surfaceNormal - normalShift);
    /*
    float3 normal = normalize(surfaceNormal - mul(float4(normalShift, 0.0f), gWVP).rgb);
    */

    return float4(normal, 1.0);
    /*
    return float4(sourceTex.Load(loc).rgb, 1.0);
    */
}



//     ____     _     ___        _   _ _                 
//    / ___|___| |   / _ \ _   _| |_| (_)_ __   ___  ___ 
//   | |   / _ \ |  | | | | | | | __| | | '_ \ / _ \/ __|
//   | |__|  __/ |  | |_| | |_| | |_| | | | | |  __/\__ \
//    \____\___|_|   \___/ \__,_|\__|_|_|_| |_|\___||___/
//                                                       
// applies CelOutlines on to gColorTex. Uses gEdgeTex texture of found edges.
float4 celOutlines1Frag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float3 renderTex = gColorTex.Load(loc).rgb;
    float3 edgeTex = gEdgeTex.Load(loc).rgb;

    float darken = edgeTex.r;
    darken = edgeMultiplier * pow(darken, edgePower);

    return float4(renderTex - darken.xxx, 1.0);
}



//     ____     _     ____              __                     
//    / ___|___| |   / ___| _   _ _ __ / _| __ _  ___ ___  ___ 
//   | |   / _ \ |   \___ \| | | | '__| |_ / _` |/ __/ _ \/ __|
//   | |__|  __/ |    ___) | |_| | |  |  _| (_| | (_|  __/\__ \
//    \____\___|_|   |____/ \__,_|_|  |_|  \__,_|\___\___||___/
//                                                             
// Contributor: Oliver Vainumäe
// Idea originates from https://github.com/mchamberlain/Cel-Shader/blob/master/shaders/celShader.frag
float4 celSurfaces1Frag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);
    float4 specularTex = gSpecularTex.Load(loc);
    float4 diffuseTex = gDiffuseTex.Load(loc);

    float diffuse = diffuseTex.r;
    float spec = specularTex.r;
    spec = dot(spec, specularPower);

    float intensity = diffuseCoefficient * diffuse + specularCoefficient * spec;

    float high2midMin = surfaceThresholdHigh - 0.5 * transitionHighMid;
    float mid2lowMin = surfaceThresholdMid - 0.5 * transitionMidLow;

    if (intensity > surfaceThresholdHigh + 0.5 * transitionHighMid)
        intensity = surfaceHighIntensity;
    else if (intensity > high2midMin)
        intensity = lerp(surfaceMidIntensity, surfaceHighIntensity,
                        (intensity - high2midMin) / transitionHighMid);
    else if (intensity > surfaceThresholdMid + 0.5 * transitionMidLow)
        intensity = surfaceMidIntensity;
    else if (intensity > mid2lowMin)
        intensity = lerp(surfaceLowIntensity, surfaceMidIntensity,
                        (intensity - mid2lowMin) / transitionMidLow);
    else
        intensity = surfaceLowIntensity;

    float3 color = renderTex.rgb;

    color = rgb2hsv2(color);

    /*
    if (color.z > 0.5) {
        if (color.y > 0.75)
            return float4(1.0, 1.0, 0.0, 1.0);

        return float4(1.0, 0.0, 0.0, 1.0);
    }

    if (color.y > 0.75)
        return float4(0.0, 1.0, 0.0, 1.0);
    */

    color.y = color.y * intensity;
    color.z = color.z * intensity;

    color = hsv2rgb(color);

    return float4(color, 1.0);
    //return float4(renderTex.rgb * intensity, 1.0);
}


// Just a simple fragment shader to place the gColorTex on top of a white background.
float4 fixBackgroundFrag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);
    float depth = gDepthTex.Load(loc).r;

    if (length(renderTex.rgb) == 0.0f && depth >= 1.0f)
        return float4(1.0f, 1.0f, 1.0f, 1.0f);

    return float4(renderTex.rgb, 1.0);
}


// Just a simple fragment shader to output the input texture
// I use it to debug: I can move the contents of one target to the other target
float4 displayFrag(vertexOutput i) : SV_Target{
    return gColorTex.Load(int3(i.pos.xy, 0));
}


float4 clampTestFrag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0);

    float3 normal = gNormalsTex.Load(loc).rgb;

    if (length(normal) < 0.01) return float4(0.0, 0.0, 0.0, 1.0);

    float3 v = float3(0.0, 0.0, 1.0);

    return float4(1.0 - pow(dot(normal, v), 0.1), 0.0, 0.0, 1.0);
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                
technique11 findNormalsFromDepth {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, findNormals1()));
    }
};

technique11 celOutlines1 {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, celOutlines1Frag()));
    }
};

technique11 celSurfaces1 {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, celSurfaces1Frag()));
    }
};

technique11 fixBackground {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, fixBackgroundFrag()));
    }
};

technique11 display {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, displayFrag()));
    }
};

technique11 celClampTest {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, clampTestFrag()));
    }
};


