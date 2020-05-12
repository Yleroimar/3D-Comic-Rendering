/////////////////////////////////////////////////////////////////////////////////////////
// quadGapsOverlaps10.fx (HLSL)
// Brief: Creating smudging overlaps near the edges of the rendered image
// Contributors: Oliver Vainumäe
/////////////////////////////////////////////////////////////////////////////////////////
//                        _                 
//     _____   _____ _ __| | __ _ _ __  ___ 
//    / _ \ \ / / _ \ '__| |/ _` | '_ \/ __|
//   | (_) \ V /  __/ |  | | (_| | |_) \__ \
//    \___/ \_/ \___|_|  |_|\__,_| .__/|___/
//                               |_|        
/////////////////////////////////////////////////////////////////////////////////////////
// This shader provides the algorithms to produce smudging overlaps found in Water Memory
/////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gRenderTex;
Texture2D gEdgeControlTex;
Texture2D gAbstractControlTex;
Texture2D gEdgeLocationTex;
Texture2D gDepthTex; // to identifty if overlapping color comes from behind or from in front

// VARIABLES
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
float2 loadEdgeUv(int3 loc) { return gEdgeLocationTex.Load(loc).xy; }
int3 loadEdgeLoc(int3 loc) { return uv2loc(loadEdgeUv(loc).xy); }
int2 loadEdgeScreen(int3 loc) { return uv2screen(loadEdgeUv(loc).xy); }

float4 loadEdgeCtrlTex(int3 loc) { return gEdgeControlTex.Load(loc); }
float loadCtrlRange(float4 edgeCtrlTex) { return edgeCtrlTex.b; }
float loadCtrlRange(int3 loc) { return loadCtrlRange(loadEdgeCtrlTex(loc)); }

float4 loadAbstractCtrlTex(int3 loc) { return gAbstractControlTex.Load(loc); }
float loadCtrlFalloff(float4 absCtrlTex) { return absCtrlTex.b; }
float loadCtrlFalloff(int3 loc) { return loadCtrlFalloff(loadAbstractCtrlTex(loc)); }

float4 loadRenderTex(int3 loc) { return gRenderTex.Load(loc); }
float loadDepth(int3 loc) { return gDepthTex.Load(loc).r; }


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


//                      _                 
//   _____   _____ _ __| | __ _ _ __  ___ 
//  / _ \ \ / / _ \ '__| |/ _` | '_ \/ __|
// | (_) \ V /  __/ |  | | (_| | |_) \__ \
//  \___/ \_/ \___|_|  |_|\__,_| .__/|___/
//                             |_|        
// Contributor: Oliver Vainumäe
// -> Based on the gaps & overlaps model by Montesdeoca et al. 2017
//    [2017] Art-directed watercolor stylization of 3D animations in real-time
float4 overlapsFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 renderTex = loadRenderTex(loc);

    float ctrlRange = loadCtrlRange(loc);
    ctrlRange *= gOverlapRange;

    if (ctrlRange <= 0.1) return renderTex;

    int3 edgeLoc = loadEdgeLoc(loc);

    if (edgeLoc.x < 0.0) return renderTex;

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


//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// OVERLAPS FOR ADDING COLOR SMUDGING [WM]
technique11 overlaps {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, overlapsFrag()));
    }
};