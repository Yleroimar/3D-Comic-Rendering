///////////////////////////////////////////////////////////////////////////////////////////////////
// quadGradientFinding10.fx (HLSL)
// Brief: Iterating gradient vectors to find details.
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////////
//                        _ _            _       _ _                 _   _             
//     __ _ _ __ __ _  __| (_) ___ _ __ | |_    (_) |_ ___ _ __ __ _| |_(_)_ __   __ _ 
//    / _` | '__/ _` |/ _` | |/ _ \ '_ \| __|   | | __/ _ \ '__/ _` | __| | '_ \ / _` |
//   | (_| | | | (_| | (_| | |  __/ | | | |_    | | ||  __/ | | (_| | |_| | | | | (_| |
//    \__, |_|  \__,_|\__,_|_|\___|_| |_|\__|   |_|\__\___|_|  \__,_|\__|_|_| |_|\__, |
//    |___/                                                                      |___/ 
///////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides algorithms for iterating gradient vectors such as:
// 1.- Finding closest edge location using gradient vector of blurred edges target (UV) [WM]
// 2.- _,_ (sampled gradient)
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "quadCommon.fxh"



// TEXTURES
Texture2D gGradientTex;



// FIXED GLOBAL VARIABLES
static const float2 noEdge = float2(-1.0, -1.0);

static const int cEdgeIterations = 20;



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float2 sampleGradient(float2 uv) { return gGradientTex.Sample(gSampler, uv).rg; }
float2 loadGradient(int3 loc) { return gGradientTex.Load(loc).rg; }


float2 iterateToEdgeUv(int3 loc, float2 gradient) {
    float2 locF = loc.xy;
    int3 loc2 = loc;
    float edge = loadEdge(loc);

    const int iterations = cEdgeIterations;

    [unroll(min(iterations, 20))]
    for (int i = 1; i <= iterations; i++) {
        float edge = loadEdge(loc2);

        if (0.5 < edge)
            return screen2uv(loc2);

        loc2 = offsetLoc(loc, i * gradient);
    }

    // if we got here, we didn't reach any edge.
    return noEdge;
}


float2 startIterationUv(int3 loc, float2 gradient) {
    // if gradient is too small, then no edge is nearby.
    if (length(gradient) < 0.5) return noEdge;
    
    float2 edgeUv = iterateToEdgeUv(loc, gradient);

    //if (0.5 < loadEdge(loc)) return float2(1.0, 1.0);

    return edgeUv;
}


//    _ _                 _           _                     _            
//   (_) |_ ___ _ __ __ _| |_ ___    | |_ ___       ___  __| | __ _  ___ 
//   | | __/ _ \ '__/ _` | __/ _ \   | __/ _ \     / _ \/ _` |/ _` |/ _ \
//   | | ||  __/ | | (_| | ||  __/   | || (_) |   |  __/ (_| | (_| |  __/
//   |_|\__\___|_|  \__,_|\__\___|    \__\___/     \___|\__,_|\__, |\___|
//                                                            |___/      
// Contributor: Oliver Vainumäe
// Iterates to the closest edge based on the gradient vector of blurred edges target

float2 edgeUvLocationsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 gradient = loadGradient(loc);

    return startIterationUv(loc, gradient);
}


float2 edgeUvLocationsSampledFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 gradient = sampleGradient(loc);

    return startIterationUv(loc, gradient);
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|                

technique11 edgeUvLocations {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeUvLocationsFrag()));
    }
};

technique11 edgeUvLocationsSampled {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeUvLocationsSampledFrag()));
    }
};