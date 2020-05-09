#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gRenderTex;
Texture2D gEdgeTex;
Texture2D gEdgeControlTex;
Texture2D gAbstractControlTex;
Texture2D gEdgeLocationTex;
Texture2D gNormalsTex; // alpha-channel for object IDs
Texture2D gDepthTex; // to identifty if overlapping color comes from behind or from in front

// VARIABLES
float gOverlapLimit = 40;
float gOverlapCtrlMultiplier = 20;

float gOverlapRange = 10.0;
float gOverlapPickDistance = 2.0;
float gOverlapFalloff = 0.5;
float gOverlapFalloffSpeed = 1.0;
float gOverlapDepthDifference = 1.0;



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

float4 loadEdgeTex(int3 loc) { return gEdgeTex.Load(loc); }
float loadEdge(float4 color) { return color.r; }
float loadEdge(int3 loc) { return loadEdge(loadEdgeTex(loc)); }

float2 loadEdgeUv(int3 loc) { return gEdgeLocationTex.Load(loc).xy; }
int3 loadEdgeLoc(int3 loc) { return uv2loc(gEdgeLocationTex.Load(loc).xy); }
int2 loadEdgeScreen(int3 loc) { return uv2screen(gEdgeLocationTex.Load(loc).xy); }

float4 loadEdgeCtrlTex(int3 loc) { return gEdgeControlTex.Load(loc); }
float loadCtrlRange(float4 edgeCtrlTex) { return edgeCtrlTex.b; }
float loadCtrlRange(int3 loc) { return loadCtrlRange(loadEdgeCtrlTex(loc)); }

float4 loadAbstractCtrlTex(int3 loc) { return gAbstractControlTex.Load(loc); }
float loadCtrlFalloff(float4 absCtrlTex) { return absCtrlTex.b; }
float loadCtrlFalloff(int3 loc) { return loadCtrlFalloff(loadAbstractCtrlTex(loc)); }

float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }

float loadObjectID(int3 loc) { return gNormalsTex.Load(loc).a; }
float loadDepth(int3 loc) { return gDepthTex.Load(loc).r; }


float sampleEdge(float2 uv, float du, float dv) {
    return gEdgeTex.Sample(gSampler, uv + float2(du, dv)).b;
}

float sampleEdgeDN(float2 uv, float du, float dv) {
    float4 cdns = gEdgeTex.Sample(gSampler, uv + float2(du, dv));
    return cdns.g + cdns.b;
}


float2 getGradient(float2 loc) {
    // get gradients
    float right = sampleEdge(loc, gTexel.x, 0.0);
    float left = sampleEdge(loc, -gTexel.x, 0.0);
    float down = sampleEdge(loc, 0.0, gTexel.y);
    float up = sampleEdge(loc, 0.0, -gTexel.y);

    float topRight = sampleEdge(loc, gTexel.x, -gTexel.y);
    float topLeft = sampleEdge(loc, -gTexel.x, -gTexel.y);
    float downRight = sampleEdge(loc, gTexel.x, gTexel.y);
    float downLeft = sampleEdge(loc, -gTexel.x, gTexel.y);

    // could be optimized for lower end devices by using bilinear filtering
    float uGradient = (right + 0.5 * (topRight + downRight))
                        - (left + 0.5 * (topLeft + downLeft));

    float vGradient = (down + 0.5 * (downRight + downLeft))
                        - (up + 0.5 * (topRight + topLeft));

    float2 gradient = float2(uGradient, vGradient);

    return normalize(gradient);
}


float2 getGradientDN(float2 loc) {
    // get gradients
    float right = sampleEdgeDN(loc, gTexel.x, 0.0);
    float left = sampleEdgeDN(loc, -gTexel.x, 0.0);
    float down = sampleEdgeDN(loc, 0.0, gTexel.y);
    float up = sampleEdgeDN(loc, 0.0, -gTexel.y);

    float topRight = sampleEdgeDN(loc, gTexel.x, -gTexel.y);
    float topLeft = sampleEdgeDN(loc, -gTexel.x, -gTexel.y);
    float downRight = sampleEdgeDN(loc, gTexel.x, gTexel.y);
    float downLeft = sampleEdgeDN(loc, -gTexel.x, gTexel.y);

    // could be optimized for lower end devices by using bilinear filtering
    float uGradient = (right + 0.5 * (topRight + downRight))
                        - (left + 0.5 * (topLeft + downLeft));

    float vGradient = (down + 0.5 * (downRight + downLeft))
                        - (up + 0.5 * (topRight + topLeft));

    float2 gradient = float2(uGradient, vGradient);

    return normalize(gradient);
}



//                      _                 
//   _____   _____ _ __| | __ _ _ __  ___ 
//  / _ \ \ / / _ \ '__| |/ _` | '_ \/ __|
// | (_) \ V /  __/ |  | | (_| | |_) \__ \
//  \___/ \_/ \___|_|  |_|\__,_| .__/|___/
//                             |_|        

float getOverlapIntensity(int3 loc, float distance, float range) {
    range = abs(range);

    float ctrlFalloff = max(loadCtrlFalloff(loc), 0.0);
    ctrlFalloff *= gOverlapFalloff;

    float falloffStart = ctrlFalloff * range;

    if (distance < falloffStart) return 1.0;

    float falloff = falloffValue(distance, range, falloffStart);
    float powered = pow(falloff, gOverlapFalloffSpeed);

    return powered;
}

float getDepthIntensity(int3 loc, int3 pickLoc, float range) {
    float depth = loadDepth(loc);
    float pickDepth = loadDepth(pickLoc);

    if (depth < pickDepth != 0.0 < range) return 0.0;

    // room for improvement:
    // if both locations want to take from each other,
    // then can choose to only pick from the color further away from viewer
    
    float depthDiff = abs(depth - pickDepth);

    if (gOverlapDepthDifference < depthDiff * 1000) return 1.0;

    return 0.0;
}

float4 overlapsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);

    float ctrlRange = loadCtrlRange(loc);
    ctrlRange *= gOverlapRange;

    if (ctrlRange <= 0.1) return renderTex;
    // if (ctrlRange <= 0.9) return renderTex;

    int3 edgeLoc = loadEdgeLoc(loc);

    if (edgeLoc.x < 0.0) return renderTex;
    // if (edgeLoc.x < 0.0) return float4(1.0, 0.0, 0.0, 1.0);

    float distance = length(edgeLoc.xy - loc.xy);

    if (abs(ctrlRange) < distance) return renderTex;

    float2 toEdge = normalize(float2(edgeLoc.xy - loc.xy));
    int3 pickLoc = offsetLoc(edgeLoc, gOverlapPickDistance * toEdge);
    float3 pickedColor = loadRenderTex(pickLoc).rgb;

    float depthIntensity = getDepthIntensity(loc, pickLoc, ctrlRange);
    float overlapIntensity = getOverlapIntensity(loc, distance, ctrlRange);
    float intensity = depthIntensity * overlapIntensity;
    float3 color = lerp(renderTex.rgb, pickedColor, saturate(intensity));

    return float4(color, 1.0);
}


float4 overlapsOldFrag(vertexOutputSampler i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 outColor = gColorTex.Load(loc);

    // get object ID to identify the neighbour.
    float oid = gNormalsTex.Load(loc).a;
    
    float gapsOverlaps = gEdgeControlTex.Load(loc).b;
    
    bool takeFromFront = gapsOverlaps < 0;
    gapsOverlaps = abs(gapsOverlaps);

    // make sure we are not considering emptiness,
    // make sure we are at an edge,
    // make sure overlap was desired here
    if (outColor.a < 0.1 || length(gEdgeTex.Load(loc).rgb) < 0.1
                || gapsOverlaps < (1.0 / gOverlapCtrlMultiplier))
        return outColor;
    

    float2 uv = i.uv;
    float2 gradient = getGradientDN(uv);

    float oid2 = oid;
    
    float maxIterations = min(gapsOverlaps * gOverlapCtrlMultiplier, gOverlapLimit);

    int index = 1;

    // TODO: gradient iteration binary increase
    [unroll(10)]
    for (index = 1; index < maxIterations; index++) {
        int3 loc2 = loc + int3(round(index * gradient), 0.0);

        oid2 = gNormalsTex.Load(loc2).a;

        // if ObjectIDs differ, then we've arrived on a new object
        if (oid2 != oid) break;
    }

    // do an additional iteration to avoid stopping on an edge
    // checking the accuracy of oid2 in for-loop might also help, somewhat
    index = min(++index, maxIterations);

    // arrived at the same object(group) return initial color
    if (oid2 == oid) return outColor;
    
    float2 uv2 = uv + index * (gradient * gTexel);
    int3 loc2 = loc + int3(round(index * gradient), 0.0);
    if (uv2.x < 0.0 || 1.0 < uv2.x || uv2.y < 0.0 || 1.0 < uv2.y) return outColor;

    // make sure that the overlap comes from front or back as requested
    float depth = gDepthTex.Load(loc).r;
    float depth2 = gDepthTex.Load(loc2).r;
    if (depth2 != depth && (depth2 < depth != takeFromFront)) return outColor;

    // finally do the overlapping
    float4 overlapColor = gColorTex.Sample(gSampler, uv2);

    float fadeStartDistance = 0.8 * maxIterations;

    float blendValue = index >= fadeStartDistance
        ? 1.0 - (index - fadeStartDistance) / (maxIterations - fadeStartDistance)
        : 1.0;

    outColor.rgb = lerp(outColor.rgb, overlapColor.rgb, blendValue);
    return outColor;
}


//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// OVERLAPS FOR SKETCHIER WATER MEMORY RENDERING
technique11 overlapsOld {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, overlapsOldFrag()));
    }
};

technique11 overlaps {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, overlapsFrag()));
    }
};