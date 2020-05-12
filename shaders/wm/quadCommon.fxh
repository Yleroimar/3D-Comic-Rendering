///////////////////////////////////////////////////////////////////////////////////////////////////
// quadCommon.fxh (HLSL)
// Brief: Common utility shader elements for Water Memory in MNPR
// Contributors: Oliver Vainumäe
///////////////////////////////////////////////////////////////////////////////////////////////////
//                          _
//     __ _ _   _  __ _  __| |       ___ ___  _ __ ___  _ __ ___   ___  _ __
//    / _` | | | |/ _` |/ _` |_____ / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \| '_ \
//   | (_| | |_| | (_| | (_| |_____| (_| (_) | | | | | | | | | | | (_) | | | |
//    \__, |\__,_|\__,_|\__,_|      \___\___/|_| |_| |_|_| |_| |_|\___/|_| |_|
//       |_|
///////////////////////////////////////////////////////////////////////////////////////////////////
// This shader file provides utility variables, structs, vertex shader and functions to aid
// the development of quad operations of Water Memory style in MNPR
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"


// TEXTURES
Texture2D gEdgeLocationTex;
Texture2D gDiscreteDiffuseTex;



//    _                 _ _                __                         _ _             
//   | | ___   __ _  __| (_)_ __   __ _   / /__  __ _ _ __ ___  _ __ | (_)_ __   __ _ 
//   | |/ _ \ / _` |/ _` | | '_ \ / _` | / / __|/ _` | '_ ` _ \| '_ \| | | '_ \ / _` |
//   | | (_) | (_| | (_| | | | | | (_| |/ /\__ \ (_| | | | | | | |_) | | | | | | (_| |
//   |_|\___/ \__,_|\__,_|_|_| |_|\__, /_/ |___/\__,_|_| |_| |_| .__/|_|_|_| |_|\__, |
//                                |___/                        |_|              |___/ 

float loadOverlapRangeCtrl(float4 edgeCtrlTex) { return edgeCtrlTex.b; }
float loadOverlapRangeCtrl(int3 loc) { return loadOverlapRangeCtrl(loadEdgeCtrlTex(loc)); }


float loadOverlapFalloffCtrl(float4 abstractCtrlTex) { return abstractCtrlTex.b; }
float loadOverlapFalloffCtrl(int3 loc) {
    return loadOverlapFalloffCtrl(loadAbstractCtrlTex(loc));
}


float loadColorEdgeCtrl(float4 abstractCtrl) { return abstractCtrl.r; }
float loadColorEdgeCtrl(int3 loc) { return loadColorEdgeCtrl(loadAbstractCtrlTex(loc)); }


float loadHatchCtrl(float4 pigmentCtrlTex) { return pigmentCtrlTex.g; }
float loadHatchCtrl(int3 loc) { return loadHatchCtrl(loadPigmentCtrlTex(loc)); }


float loadEdge(float4 edgeTex) { return edgeTex.r; }
float loadEdge(int3 loc) { return loadEdge(loadEdgeTex(loc)); }


float4 loadEdgeLocationTex(int3 loc) { return gEdgeLocationTex.Load(loc); }
float4 loadEdgeLocationTex(int3 loc, int dx, int dy) {
    return loadEdgeLocationTex(loc + int3(dx, dy, 0));
}
float2 loadEdgeUv(int3 loc) { return loadEdgeLocationTex(loc).xy; }
int3 loadEdgeLoc(int3 loc) { return uv2loc(loadEdgeUv(loc).xy); }
int2 loadEdgeScreen(int3 loc) { return uv2screen(loadEdgeUv(loc).xy); }


float4 loadDiscreteDiffuseTex(int3 loc) { return gDiscreteDiffuseTex.Load(loc); }
float3 loadDiscreteDiffuseColor(int3 loc) { return loadDiscreteDiffuseTex(loc).rgb; }



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

float thresholdValue(float value, float threshold) { return value < threshold ? 0.0 : 1.0; }