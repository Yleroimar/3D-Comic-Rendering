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



// EDGE MANIPULATIONS


float2 placeUVsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float edge = loadEdge(loc);

    if (edge < 0.5) return float2(-1.0, -1.0);

    return screen2uv(loc);
}


float dilateEdgeFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    return loadEdge(loc);

    /* const int kernelWidth = cEdgeDilateKernelWidth;
    const int kernelWidthHalf = kernelWidth / 2;
    const int kernelSize = kernelWidth * kernelWidth;

    [unroll(kernelSize)]
    for (int i = 0; i < kernelSize; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i,
                                    kernelWidth, kernelWidthHalf, kernelSize);

        float edge = loadEdge(loc2);

        if (0.5 < edge) return edge;
    }

    return 0.0; */
}


float thresholdValue(float value, float threshold) { return value < threshold ? 0.0 : 1.0; }

float thresholdEdgesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 edgeTex = loadEdgeTex(loc);

    edgeTex.r = thresholdValue(edgeTex.r, gEdgeThreshold);

    return edgeTex.r;
}


float edgePickerFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 edgeTex = loadEdgeTex(loc);

    float colorCtrl = loadColorEdgeCtrl(loc);
    edgeTex.r *= colorCtrl;

    return max(edgeTex);
}



int2 findClosestDepthNeighbour(int3 loc) {
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

    return closest.xy;
}

float4 fixEdgeCtrlFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    /* float4 ctrlTexTemp = loadEdgeCtrlTex(loc);
    if (0.5 < loadEdge(loc))
        ctrlTexTemp.b = 0.25;
    else ctrlTexTemp.b = 0.0;
    return ctrlTexTemp; */

    /* float edge = loadEdge(loc);

    if (edge < 0.5) return loadEdgeCtrlTex(loc); */

    int3 from = int3(findClosestDepthNeighbour(loc), 0);

    float4 ctrlTex = loadEdgeCtrlTex(from);
    
    /* if (0.5 < loadEdge(loc))
        ctrlTex.b = 0.25;
    else ctrlTex.b = 0.0; */

    return ctrlTex;
}



float2 iterateToEdgeSampled(float2 uv, float2 gradient) {
    float2 uv2 = uv;
    float edge = sampleEdge(uv2);

    const int iterations = cEdgeIterations;

    [unroll(iterations % 20)]
    for (int i = 1; i <= iterations; i++) {
        if (0.5 < edge) return uv2;

        uv2 = uv + screen2uv(i * gradient);
        edge = sampleEdge(uv2);
    }

    // if we got here, we didn't reach any edge.
    return float2(-1.0, -1.0);
}

float2 edgeUvLocationsSampledFrag(vertexOutputSampler i) : SV_Target {
    float2 uv = i.uv;

    float2 gradient = sampleGradient(uv);

    // if gradient is too small, then no edge is nearby.
    if (length(gradient) < 0.5) return float2(-1.0, -1.0);
    
    float2 edgeUv = iterateToEdgeSampled(uv, gradient);

    return edgeUv;
}

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

    if (0.5 < loadEdge(loc)) return float2(1.0, 1.0);

    return edgeUv;
}



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
        float distance = length(locEF - loc);

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


float getEdgeRange(float ctrlWidth) {
    if (0 < ctrlWidth)
        ctrlWidth *= 8;

    return gEdgeWidth * (1.0 + ctrlWidth);
}

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



float4 averageEdgeIntensityFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 localEdgeTex = loadEdgeTex(loc);

    return localEdgeTex;

    /* if (localEdgeTex.a < 0.5) return localEdgeTex;

    int pixels = 0;
    float intensitySum = 0;

    [unroll(9)]
    for (int i = 0; i < 9; i++) {
        int3 loc2 = kernelOffsetLoc(loc, i, 3, 1, 9);

        float4 edgeTex = loadEdgeTex(loc2);

        if (edgeTex.a < 0.5) continue;

        float intensity = edgeTex.r;

        pixels++;
        intensitySum += intensity;
    }

    float averageIntensity = intensitySum / pixels;

    return float4(averageIntensity, 0.0, 0.0, 1.0); */
}




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
    // if (8.0 < distance) return renderTex;
    // return float4(0.0, 0.0, 0.0, 0.0);

    float substrateHeight = loadSubstrateHeight(loc);

    float intensity = getApplyingIntensity(distance, edgeRadius,
                                           substrateHeight,
                                           ctrlIntensity);
    
    // float3 color = renderTex.rgb * (1.0 - saturate(intensity));
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

technique11 edgeUvLocationsSampled {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, edgeUvLocationsSampledFrag()));
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

technique11 averageEdgeIntensity {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, averageEdgeIntensityFrag()));
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