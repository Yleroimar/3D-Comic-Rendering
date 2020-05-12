///////////////////////////////////////////////////////////////////////////////////////////////////
// quadSurfaceShading10.fx (HLSL)
// Brief: Shading of surfaces in the style of Water Memory.
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////////
//                    __                        _               _ _             
//    ___ _   _ _ __ / _| __ _  ___ ___     ___| |__   __ _  __| (_)_ __   __ _ 
//   / __| | | | '__| |_ / _` |/ __/ _ \   / __| '_ \ / _` |/ _` | | '_ \ / _` |
//   \__ \ |_| | |  |  _| (_| | (_|  __/   \__ \ | | | (_| | (_| | | | | | (_| |
//   |___/\__,_|_|  |_|  \__,_|\___\___|   |___/_| |_|\__,_|\__,_|_|_| |_|\__, |
//                                                                        |___/ 
///////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides algorithms for surface shading such as:
// 1.- Making the light discrete based on light intensity [WM]
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "quadLighting10.fx"


// VARIABLES
float gShadingSaturationWeight = 1.0;



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

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

    float3 shadedColor = shadedSurfaceColor(renderTex.rgb, loadDiscreteDiffuseTex(loc));

    // multiplied with alpha to account for transparency.
    return float4(shadedColor.rgb * renderTex.a, renderTex.a);
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                

technique11 shadeSurfaces {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, shadeSurfacesFrag()));
    }
};