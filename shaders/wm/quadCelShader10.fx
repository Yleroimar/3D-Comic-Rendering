///////////////////////////////////////////////////////////////////////////////////////////////////
// quadCelShader.fx (HLSL)
// Brief: Cel shading algorithms
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////////
//     ____     _    ____  _               _           
//    / ___|___| |  / ___|| |__   __ _  __| | ___ _ __ 
//   | |   / _ \ |  \___ \| '_ \ / _` |/ _` |/ _ \ '__|
//   | |__|  __/ |   ___) | | | | (_| | (_| |  __/ |   
//    \____\___|_|  |____/|_| |_|\__,_|\__,_|\___|_|   
//                                                     
///////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides alorithms for cel shading of surfaces.
//
// UNFINISHED, DROPPED
//
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "quadCommon.fxh"



float4 celSurfaces1Frag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRendeTex(loc);

    // if the pixel is transparent, we're not gonna modify it.
    if (renderTex.a == 0.0) return renderTex;
    
    float3 diffuseColor = loadDiscreteDiffuseColor(loc);
    // float3 specularColor = loadSpecularColor(loc);

    // float3 light = diffuseColor + specularColor;
    float3 light = diffuseColor;
    
    float3 color = loadRender(renderTex);

    return float4(renderTex.rgb * intensity, 1.0);
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