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
float gEdgePower = 0.1;
float gEdgeMultiplier = 10.0;

// Surface Shading
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
    darken = gEdgeMultiplier * pow(darken, gEdgePower);

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
    spec = dot(spec, gSpecularPower);

    float intensity = gDiffuseCoefficient * diffuse + gSpecularCoefficient * spec;

    float high2midMin = gSurfaceThresholdHigh - 0.5 * gTransitionHighMid;
    float mid2lowMin = gSurfaceThresholdMid - 0.5 * gTransitionMidLow;

    if (intensity > gSurfaceThresholdHigh + 0.5 * gTransitionHighMid)
        intensity = gSurfaceHighIntensity;
    else if (intensity > high2midMin)
        intensity = lerp(gSurfaceMidIntensity, gSurfaceHighIntensity,
                        (intensity - high2midMin) / gTransitionHighMid);
    else if (intensity > gSurfaceThresholdMid + 0.5 * gTransitionMidLow)
        intensity = gSurfaceMidIntensity;
    else if (intensity > mid2lowMin)
        intensity = lerp(gSurfaceLowIntensity, gSurfaceMidIntensity,
                        (intensity - mid2lowMin) / gTransitionMidLow);
    else
        intensity = gSurfaceLowIntensity;

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
technique11 celSurfaces1 {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, celSurfaces1Frag()));
    }
};

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


