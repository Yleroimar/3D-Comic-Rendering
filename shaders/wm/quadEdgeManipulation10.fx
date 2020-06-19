///////////////////////////////////////////////////////////////////////////////////////////////
// quadEdgeManipulation10.fx (HLSL)
// Brief: Edge manipulation algorithms for Water Memory
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////
//             _                                      _             _       _   _             
//     ___  __| | __ _  ___     _ __ ___   __ _ _ __ (_)_ __  _   _| | __ _| |_(_) ___  _ __  
//    / _ \/ _` |/ _` |/ _ \   | '_ ` _ \ / _` | '_ \| | '_ \| | | | |/ _` | __| |/ _ \| '_ \ 
//   |  __/ (_| | (_| |  __/   | | | | | | (_| | | | | | |_) | |_| | | (_| | |_| | (_) | | | |
//    \___|\__,_|\__, |\___|   |_| |_| |_|\__,_|_| |_|_| .__/ \__,_|_|\__,_|\__|_|\___/|_| |_|
//               |___/                                 |_|                                    
///////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides alorithms for edge manipulation such as:
// 1.- Setting edge pixel value as the pixel's UV position [WM]
// 2.- Dilating  [WM]
// 2.- RGBDNO edge-detection combining into Red channel [WM]
// 3.- Edge-detection thresholding [WM]
// 4.- Edge-related controls target dilating, based on depth [WM]
// 5.- Iterating to closest edge using gradient vector of blurred edges target [WM]
// 6.- Dilating closest edge location based on proximity [WM]
// 7.- Removing edge location pixels that are too far from edge (DEBUG) [WM]
// 8.- Setting the intensity of edges based on ctrl from edge location (DEBUG) [WM]
// 9.- Applying the edges using edge ctrl target and edge locations [WM]
///////////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gRenderTex;
Texture2D gEdgeTex;
Texture2D gGradientTex;
Texture2D gEdgeLocationTex;
Texture2D gEdgeControlTex;
Texture2D gAbstractControlTex;
Texture2D gDepthTex;
Texture2D gSubstrateTex;


// VARIABLES
float gEdgeIntensity = 1.0;
float gEdgeWidth = 1.0;
float gEdgeThreshold = 0.5;
float gEdgeFalloffStart = 0.1;
float gEdgeTextureIntensity = 4;

// FIXED GLOBAL VARIABLES
float4 noEdge = float4(0.0, 0.0, 0.0, 0.0);
float4 nullValue = float4(0.0, 0.0, 0.0, 0.0);

static const int cEdgeDilateKernelWidth = 3;
static const int cCtrlFixKernelWidth = 5;
static const int cDilateKernelWidth = 5;
static const int cEdgeIterations = 20;




//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float4 loadEdgeLocationTex(int3 loc) { return gEdgeLocationTex.Load(loc); }
float4 loadEdgeLocationTex(int3 loc, int dx, int dy) {
    return loadEdgeLocationTex(loc + int3(dx, dy, 0));
}

float4 loadEdgeCtrlTex(int3 loc) { return gEdgeControlTex.Load(loc); }

float4 loadColorEdgeCtrlTex(int3 loc) { return gAbstractControlTex.Load(loc); }
float loadColorEdgeCtrl(int3 loc) { return loadColorEdgeCtrlTex(loc).r; }

float sampleEdge(float2 uv) { return gEdgeTex.Sample(gSampler, uv).r; }
float4 loadEdgeTex(int3 loc) { return gEdgeTex.Load(loc); }
float loadEdge(int3 loc) { return loadEdgeTex(loc).r; }

float2 sampleGradient(float2 uv) { return gGradientTex.Sample(gSampler, uv).rg; }
float2 loadGradient(int3 loc) { return gGradientTex.Load(loc).rg; }

float loadDepth(int3 loc) { return gDepthTex.Load(loc).r; }

float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }
float4 loadSubstrateTex(int3 loc) { return gSubstrateTex.Load(loc); }
float4 loadSubstrateHeight(int3 loc) { return loadSubstrateTex(loc).b; }


float thresholdValue(float value, float threshold) { return value < threshold ? 0.0 : 1.0; }


float getEdgeRange(float ctrlWidth) {
    if (0 < ctrlWidth)
        ctrlWidth *= 8;

    return gEdgeWidth * (1.0 + ctrlWidth);
}




//             _                _                            
//    ___  ___| |_      ___  __| | __ _  ___     _   ___   __
//   / __|/ _ \ __|    / _ \/ _` |/ _` |/ _ \   | | | \ \ / /
//   \__ \  __/ |_    |  __/ (_| | (_| |  __/   | |_| |\ V / 
//   |___/\___|\__|    \___|\__,_|\__, |\___|    \__,_| \_/  
//                                |___/                      
// Contributor: Oliver Vainumäe
// Sets the edge pixel value as the pixel's UV position
float2 placeUVsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float edge = loadEdge(loc);

    if (edge < 0.5) return float2(-1.0, -1.0);

    return screen2uv(loc);
}


//        _ _ _       _                    _            
//     __| (_) | __ _| |_ ___      ___  __| | __ _  ___ 
//    / _` | | |/ _` | __/ _ \    / _ \/ _` |/ _` |/ _ \
//   | (_| | | | (_| | ||  __/   |  __/ (_| | (_| |  __/
//    \__,_|_|_|\__,_|\__\___|    \___|\__,_|\__, |\___|
//                                           |___/      
// Contributor: Oliver Vainumäe
// Dilates the the edge
float dilateEdgeFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    const int kernelWidth = cEdgeDilateKernelWidth;
    const int kernelWidthHalf = kernelWidth / 2;
    const int kernelSize = kernelWidth * kernelWidth;

    [unroll(kernelSize)]
    for (int i = 0; i < kernelSize; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i,
                                    kernelWidth, kernelWidthHalf, kernelSize);

        float edge = loadEdge(loc2);

        if (0.5 < edge) return edge;
    }

    return 0.0;
}


//                        _     _                         _                 
//     ___ ___  _ __ ___ | |__ (_)_ __   ___      ___  __| | __ _  ___  ___ 
//    / __/ _ \| '_ ` _ \| '_ \| | '_ \ / _ \    / _ \/ _` |/ _` |/ _ \/ __|
//   | (_| (_) | | | | | | |_) | | | | |  __/   |  __/ (_| | (_| |  __/\__ \
//    \___\___/|_| |_| |_|_.__/|_|_| |_|\___|    \___|\__,_|\__, |\___||___/
//                                                          |___/           
// Contributor: Oliver Vainumäe
// Combines the 4 edge-types into Red channel by taking max
// color-based edges (red) are multiplied with a ctrl weight
float edgePickerFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 edgeTex = loadEdgeTex(loc);

    float colorCtrl = loadColorEdgeCtrl(loc);
    edgeTex.r *= max(0, colorCtrl);

    return max(edgeTex);
}



//    _   _                   _           _     _              _                 
//   | |_| |__  _ __ ___  ___| |__   ___ | | __| |     ___  __| | __ _  ___  ___ 
//   | __| '_ \| '__/ _ \/ __| '_ \ / _ \| |/ _` |    / _ \/ _` |/ _` |/ _ \/ __|
//   | |_| | | | | |  __/\__ \ | | | (_) | | (_| |   |  __/ (_| | (_| |  __/\__ \
//    \__|_| |_|_|  \___||___/_| |_|\___/|_|\__,_|    \___|\__,_|\__, |\___||___/
//                                                               |___/           
// Contributor: Oliver Vainumäe
// Thresholds edge intensities to output edges as binary values
float thresholdEdgesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 edgeTex = loadEdgeTex(loc);

    edgeTex.r = thresholdValue(edgeTex.r, gEdgeThreshold);

    return edgeTex.r;
}


//             _                     _        _         _ _ _       _       
//     ___  __| | __ _  ___      ___| |_ _ __| |     __| (_) | __ _| |_ ___ 
//    / _ \/ _` |/ _` |/ _ \    / __| __| '__| |    / _` | | |/ _` | __/ _ \
//   |  __/ (_| | (_| |  __/   | (__| |_| |  | |   | (_| | | | (_| | ||  __/
//    \___|\__,_|\__, |\___|    \___|\__|_|  |_|    \__,_|_|_|\__,_|\__\___|
//               |___/                                                      
// Contributor: Oliver Vainumäe
// Takes the edge-related control values from the neighbor depth-wise closest to the viewer
int3 findClosestDepthNeighbour(int3 loc) {
    int3 closest = loc;
    float depth = loadDepth(loc);

    const int kernelWidth = cCtrlFixKernelWidth;
    const int kernelWidthHalf = kernelWidth / 2;
    const int kernelSize = kernelWidth * kernelWidth;

    [unroll(kernelSize)]
    for (int i = 0; i < kernelSize; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i,
                                    kernelWidth, kernelWidthHalf, kernelSize);

        float depth2 = loadDepth(loc2);

        if (depth < depth2) continue;

        closest = loc2;
        depth = depth2;
    }

    return closest;
}

float4 fixEdgeCtrlFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    /* if (edge < 0.5) return loadEdgeCtrlTex(loc); */

    int3 from = findClosestDepthNeighbour(loc);

    return loadEdgeCtrlTex(from);
}



//    _ _                 _           _                     _            
//   (_) |_ ___ _ __ __ _| |_ ___    | |_ ___       ___  __| | __ _  ___ 
//   | | __/ _ \ '__/ _` | __/ _ \   | __/ _ \     / _ \/ _` |/ _` |/ _ \
//   | | ||  __/ | | (_| | ||  __/   | || (_) |   |  __/ (_| | (_| |  __/
//   |_|\__\___|_|  \__,_|\__\___|    \__\___/     \___|\__,_|\__, |\___|
//                                                            |___/      
// Contributor: Oliver Vainumäe
// Iterates to the closest edge based on the gradient vector of blurred edges target
float2 iterateToEdge(int3 loc, float2 gradient) {
    float2 locF = loc.xy;
    float edge = loadEdge(loc);

    const int iterations = cEdgeIterations;

    [unroll(iterations % 20)]
    for (int i = 1; i <= iterations; i++) {
        if (0.5 < edge) return screen2uv(locF);

        locF = loc.xy + i * gradient;
        edge = loadEdge(int3(round(locF), 0));
    }

    // if we got here, we didn't reach any edge.
    return float2(-1.0, -1.0);
}

float2 edgeUvLocationsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 gradient = loadGradient(loc);

    // if gradient is too small, then no edge is nearby.
    if (length(gradient) < 0.5) return float2(-1.0, -1.0).xy;
    
    float2 edgeUv = iterateToEdge(loc, gradient);

    //if (0.5 < loadEdge(loc)) return float2(1.0, 1.0);

    return edgeUv;
}


//        _ _ _       _                    _                _            
//     __| (_) | __ _| |_ ___      ___  __| | __ _  ___    | | ___   ___ 
//    / _` | | |/ _` | __/ _ \    / _ \/ _` |/ _` |/ _ \   | |/ _ \ / __|
//   | (_| | | | (_| | ||  __/   |  __/ (_| | (_| |  __/   | | (_) | (__ 
//    \__,_|_|_|\__,_|\__\___|    \___|\__,_|\__, |\___|   |_|\___/ \___|
//                                           |___/                       
// Contributor: Oliver Vainumäe
// Dilates edge locations based on location values from neighbors and the location proximity
float2 getClosestEdgeLocation(int3 loc) {
    float2 closest = float2(-1.0, -1.0);
    float minDistance = 10000; // a big number for a start

    // float2 locF = loc.xy;

    const int kernelWidth = cDilateKernelWidth;
    const int kernelWidthHalf = kernelWidth / 2;
    const int kernelSize = kernelWidth * kernelWidth;

    for (int i = 0; i < kernelSize; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i,
                                    kernelWidth, kernelWidthHalf, kernelSize);

        float2 location = loadEdgeLocationTex(loc2).rg;

        if (location.x < 0.0) continue;
        
        float2 locEF = uv2screen(location);
        float distance = length(locEF - loc.xy);

        if (minDistance < distance) continue;
        
        closest = location;
        minDistance = distance;
    }

    return closest;
}

float2 getNearbyEdgeLocation(int3 loc) {
    const int kernelWidth = cDilateKernelWidth;
    const int kernelWidthHalf = kernelWidth / 2;
    const int kernelSize = kernelWidth * kernelWidth;

    for (int i = 0; i < kernelSize; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i,
                                    kernelWidth, kernelWidthHalf, kernelSize);

        float2 location = loadEdgeLocationTex(loc2).rg;

        if (0.0 <= location.x)
            return location;
    }

    return float2(-1.0, -1.0);
}

float2 dilateEdgeLocationsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    /* float2 local = loadEdgeLocationTex(loc);

    // no need to dilate at already found location areas.
    if (0.0 <= local.x) return local; */

    // float2 closest = getNearbyEdgeLocation(loc);
    float2 closest = getClosestEdgeLocation(loc);

    return closest;
}



//                                           __                      _      
//    _ __ ___ _ __ ___   _____   _____     / _| __ _ _ __     _ __ (_)_  __
//   | '__/ _ \ '_ ` _ \ / _ \ \ / / _ \   | |_ / _` | '__|   | '_ \| \ \/ /
//   | | |  __/ | | | | | (_) \ V /  __/   |  _| (_| | |      | |_) | |>  < 
//   |_|  \___|_| |_| |_|\___/ \_/ \___|   |_|  \__,_|_|      | .__/|_/_/\_\
//                                                            |_|           
// Contributor: Oliver Vainumäe
// Removes the edge location pixels that are already too far based on edge range
//  Used for debugging
float2 removeFarPixelsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 edgeUv = loadEdgeLocationTex(loc);

    if (edgeUv.x < 0.0) return float2(-1.0, -1.0);

    int2 edgeLoc = uv2screen(edgeUv);

    float4 ctrl = loadEdgeCtrlTex(int3(edgeLoc, 0));
    // float4 ctrl = loadEdgeCtrlTex(loc);
    float ctrlWidth = ctrl.g;

    float edgeRange = getEdgeRange(ctrlWidth);

    // the distance comparison has to be done in screen-space, not UV-space,
    // because in UV-space the distance is horizontally longer.
    if (edgeRange < length(edgeLoc - loc.xy)) return float2(-1.0, -1.0);

    return edgeUv;
}


//             _                _       _                 _ _         
//     ___  __| | __ _  ___    (_)_ __ | |_ ___ _ __  ___(_) |_ _   _ 
//    / _ \/ _` |/ _` |/ _ \   | | '_ \| __/ _ \ '_ \/ __| | __| | | |
//   |  __/ (_| | (_| |  __/   | | | | | ||  __/ | | \__ \ | |_| |_| |
//    \___|\__,_|\__, |\___|   |_|_| |_|\__\___|_| |_|___/_|\__|\__, |
//               |___/                                          |___/ 
// Contributor: Oliver Vainumäe
// Sets the edge intensity based on ctrl from edge location
//  Used for debugging
float4 edgeIntensityFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float2 edgeUv = loadEdgeLocationTex(loc).rg;

    if (edgeUv.x < 0.0) return nullValue;

    int3 edgeLoc = uv2loc(edgeUv);

    /* float4 ctrlTex = loadEdgeCtrlTex(edgeLoc);

    float intensity = 1.0;
    float ctrlIntensity = ctrlTex.r;

    if (ctrlIntensity < 0.0)
        intensity -= saturate(-ctrlIntensity); */

    return float4(gEdgeIntensity, 0.0, 0.0, 1.0);
}



//                      _                    _                 
//     __ _ _ __  _ __ | |_   _      ___  __| | __ _  ___  ___ 
//    / _` | '_ \| '_ \| | | | |    / _ \/ _` |/ _` |/ _ \/ __|
//   | (_| | |_) | |_) | | |_| |   |  __/ (_| | (_| |  __/\__ \
//    \__,_| .__/| .__/|_|\__, |    \___|\__,_|\__, |\___||___/
//         |_|   |_|      |___/                |___/           
// Contributor: Oliver Vainumäe
// Applies the edges using edge locations target.
//  Out-of-range pixels are filtered out and intensities are accounted for
//   based on the edge ctrl target at the pointed edge location.
float getDistanceIntensity(float distance, float edgeRadius) {
    float falloffStart = gEdgeFalloffStart * edgeRadius;
    return falloffValue(distance, edgeRadius, falloffStart);
}

float getApplyingIntensity(float distance, float edgeRadius,
                           float substrateHeight,
                           float ctrlIntensity) {
    float distanceIntensity = getDistanceIntensity(distance, edgeRadius);

    float controlledIntensity = (1.0 + ctrlIntensity) * gEdgeIntensity;
    float threshold = max(0.0, 1.0 - 0.5 * controlledIntensity);

    float substrateHeightExcess = substrateHeight * distanceIntensity - threshold;

    if (substrateHeightExcess < 0.0) return 0.0;

    return gEdgeTextureIntensity * controlledIntensity * substrateHeightExcess;
}

float4 applyEdgesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);

    float2 edgeUv = loadEdgeLocationTex(loc).xy;

    // if no edge is detected to be nearby
    if (edgeUv.x < 0.0) return renderTex;

    int3 edgeLoc = uv2loc(edgeUv);

    float4 ctrl = loadEdgeCtrlTex(edgeLoc);
    float ctrlWidth = ctrl.g;
    float ctrlIntensity = ctrl.r;

    float edgeRadius = getEdgeRange(ctrlWidth);
    float distance = length(loc.xy - edgeLoc.xy);

    float substrateHeight = loadSubstrateHeight(loc);

    float intensity = getApplyingIntensity(distance, edgeRadius,
                                           substrateHeight,
                                           ctrlIntensity);
    
    float3 color = lerp(renderTex.rgb, float3(0.0, 0.0, 0.0), intensity);

    return float4(color, 1.0);
}





//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|       
technique11 placeUVs {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, placeUVsFrag()));
    }
};

technique11 dilateEdge {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, dilateEdgeFrag()));
    }
};

technique11 thresholdEdges {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, thresholdEdgesFrag()));
    }
};

technique11 edgePicker {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgePickerFrag()));
    }
};

technique11 fixEdgeCtrl {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, fixEdgeCtrlFrag()));
    }
};

technique11 edgeUvLocations {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeUvLocationsFrag()));
    }
};

technique11 dilateEdgeLocations {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, dilateEdgeLocationsFrag()));
    }
};

technique11 removeFarPixels {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, removeFarPixelsFrag()));
    }
};

technique11 edgeIntensity {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeIntensityFrag()));
    }
};

technique11 applyEdges {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, applyEdgesFrag()));
    }
};




// DEBUGGING
float4 edgeLocationDebugFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 edgeLocationTex = loadEdgeLocationTex(loc);

    float2 edgeUv = screen2uv(edgeLocationTex.rg);
    
    return float4(edgeUv, edgeLocationTex.ba);
}

technique11 edgeLocationDebug {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeLocationDebugFrag()));
    }
};