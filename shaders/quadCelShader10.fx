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

// TEXTURES
//Texture2D gColorTex;
Texture2D gDepthTex;
Texture2D gNormalTex;
Texture2D gSpecularTex;
Texture2D gDiffuseTex;

/*
struct appData2 {
	float3 vertex 		: POSITION;
	float3 normal		: NORMAL;
};

struct vertexOutput2 {
    float4 pos : SV_POSITION;
    float4 vNormal : NORMAL;
};
*/


// VARIABLES
/*
float3 gSubstrateColor = float3(1.0, 1.0, 1.0);
float gEdgeIntensity = 1.0;
*/


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

/*
// I was about to try to get normals from the entire scene,
// but couldn't find a way to render the entire scene with a custom shader
vertexOutput2 vs(appData2 v) {
    vertexOutput2 o;
    
    o.pos = mul(float4(v.vertex, 1.0f), gWVP);
    o.vNormal = normalize(mul(float4(v.normal, 1.0f), gWVP));

    return o;
}
*/



//     ____     _     ___        _   _ _                 
//    / ___|___| |   / _ \ _   _| |_| (_)_ __   ___  ___ 
//   | |   / _ \ |  | | | | | | | __| | | '_ \ / _ \/ __|
//   | |__|  __/ |  | |_| | |_| | |_| | | | | |  __/\__ \
//    \____\___|_|   \___/ \__,_|\__|_|_|_| |_|\___||___/
//                                                       

// Contributor: Oliver Vainumäe

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
    return float4(depthTex.rgb, 1.0);
}



//     ____     _     ____              __                     
//    / ___|___| |   / ___| _   _ _ __ / _| __ _  ___ ___  ___ 
//   | |   / _ \ |   \___ \| | | | '__| |_ / _` |/ __/ _ \/ __|
//   | |__|  __/ |    ___) | |_| | |  |  _| (_| | (_|  __/\__ \
//    \____\___|_|   |____/ \__,_|_|  |_|  \__,_|\___\___||___/
//                                                             
// Contributor: Oliver Vainumäe

float4 celSurfaces1Frag(vertexOutput i) : SV_Target{
    int3 loc = int3(i.pos.xy, 0); // coordinates for loading

    // get pixel values
    float4 renderTex = gColorTex.Load(loc);
    float4 depthTex = gDepthTex.Load(loc);
    float4 normalTex = gNormalTex.Load(loc);
    float4 specularTex = gSpecularTex.Load(loc);
    float4 diffuseTex = gDiffuseTex.Load(loc);

    float diffuse = diffuseTex.r;
    float spec = specularTex.r;
    spec = max(dot(spec, 30.0f), 0.0f);
    spec = 1.0f * spec;

    float intensity = 0.6 * diffuse + 0.4 * spec;
    //float intensity = spec;

    if (intensity > 0.9)
 		intensity = 1.1;
 	else if (intensity > 0.5)
 		intensity = 0.7;
 	else
 		intensity = 0.5;

    // return float4(depthTex.rgb, 1.0);
    return float4(renderTex.rgb * intensity, 1.0);
    // return float4(0.1 * diffuseTex.rgb, 1.0);
    // return float4(spec, spec, spec, 1.0);
    // return float4(renderTex.rgb, 1.0);
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