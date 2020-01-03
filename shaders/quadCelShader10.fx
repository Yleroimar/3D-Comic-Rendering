////////////////////////////////////////////////////////////////////////////////////////////////////
// quadCelShader.fx (HLSL)
// Brief: Cel shading algorithms
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////////////////////
//             _                                      _             _       _   _             
//     ___  __| | __ _  ___     _ __ ___   __ _ _ __ (_)_ __  _   _| | __ _| |_(_) ___  _ __  
//    / _ \/ _` |/ _` |/ _ \   | '_ ` _ \ / _` | '_ \| | '_ \| | | | |/ _` | __| |/ _ \| '_ \ 
//   |  __/ (_| | (_| |  __/   | | | | | | (_| | | | | | |_) | |_| | | (_| | |_| | (_) | | | |
//    \___|\__,_|\__, |\___|   |_| |_| |_|\__,_|_| |_|_| .__/ \__,_|_|\__,_|\__|_|\___/|_| |_|
//               |___/                                 |_|                                    
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides alorithms for cel shading.
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"

// TEXTURES
//Texture2D gColorTex;
Texture2D gDepthTex;
Texture2D gNormalTex;


// VARIABLES
/*
float3 gSubstrateColor = float3(1.0, 1.0, 1.0);
float gEdgeIntensity = 1.0;
*/



//                        _ _            _                _                 
//     __ _ _ __ __ _  __| (_) ___ _ __ | |_      ___  __| | __ _  ___  ___ 
//    / _` | '__/ _` |/ _` | |/ _ \ '_ \| __|    / _ \/ _` |/ _` |/ _ \/ __|
//   | (_| | | | (_| | (_| | |  __/ | | | |_    |  __/ (_| | (_| |  __/\__ \
//    \__, |_|  \__,_|\__,_|_|\___|_| |_|\__|    \___|\__,_|\__, |\___||___/
//    |___/                                                 |___/           

// Contributor: Oliver Vainumäe
// [WC] - Modifies the color at the edges using previously calculated edge gradients
// -> Based on the gaps & overlaps model by Montesdeoca et al. 2017
//    [2017] Art-directed watercolor stylization of 3D animations in real-time
float4 celOutlines1Frag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);
    float4 depthTex = gDepthTex.Load(loc);
    float4 normalTex = gNormalTex.Load(loc);

    /*
    float ctrlIntensity = gControlTex.Load(loc).r;  // edge control target (r)

    // calculate edge intensity
    if (ctrlIntensity > 0) {
        ctrlIntensity *= 5;
    }
    float paintedIntensity = 1 + ctrlIntensity;
    float dEdge = edgeBlur.x * gEdgeIntensity * paintedIntensity;


    // EDGE MODULATION
    // get rid of edges with color similar to substrate
    dEdge = lerp(0.0, dEdge, saturate(length(renderTex.rgb - gSubstrateColor)*5.0));
    // get rid of edges at bleeded areas
    dEdge = lerp(0.0, dEdge, saturate(1.0 - (edgeBlur.y*3.0)));

    // color modification model
    float density = 1.0 + dEdge;
    float3 darkenedEdgeCM = pow(renderTex.rgb, density);
    */

    // return float4(depthTex.rgb, 1.0);
    return float4(normalTex.rgb, 1.0);
}

/*
float4 strongEdgesWMFrag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);
    float2 edgeBlur = gEdgeTex.Load(loc).ga;
    float ctrlIntensity = gControlTex.Load(loc).r;  // edge control target (r)

    // calculate edge intensity
    if (ctrlIntensity > 0) {
        ctrlIntensity *= 100;
    }
    float paintedIntensity = 1 + ctrlIntensity;
    float dEdge = edgeBlur.x * gEdgeIntensity * paintedIntensity;

    // color modification model
    float density = 1.0 + dEdge;
    float3 darkenedEdgeCM = pow(renderTex.rgb, density);

    return float4(darkenedEdgeCM, renderTex.a);
}


float4 testOutputWMFrag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);

    return renderTex;
}
*/



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                
technique11 celOutlines1 {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, celOutlines1Frag()));
    }
};


/*
technique11 strongEdgesWM {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, strongEdgesWMFrag()));
    }
}


technique11 testOutputWM {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, testOutputWMFrag()));
    }
};
*/