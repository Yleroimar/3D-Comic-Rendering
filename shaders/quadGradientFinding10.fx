////////////////////////////////////////////////////////////////////////////////////
// quadGradientFinding10.fx (HLSL)
// Brief: Gradient vector finding algorithms
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////
//                        _ _            _        __ _           _ _             
//     __ _ _ __ __ _  __| (_) ___ _ __ | |_     / _(_)_ __   __| (_)_ __   __ _ 
//    / _` | '__/ _` |/ _` | |/ _ \ '_ \| __|   | |_| | '_ \ / _` | | '_ \ / _` |
//   | (_| | | | (_| | (_| | |  __/ | | | |_    |  _| | | | | (_| | | | | | (_| |
//    \__, |_|  \__,_|\__,_|_|\___|_| |_|\__|   |_| |_|_| |_|\__,_|_|_| |_|\__, |
//    |___/                                                                |___/ 
////////////////////////////////////////////////////////////////////////////////////
// This shader provides algorithms for gradient vector finding such as:
// 1.- Gradient vector finding with seperated 3x3 kernel with corners [WM]
// 2.- Gradient vector finding with seperated 3x3 kernel with corners (sampled) [WM]
////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"
#include "include\\quadColorTransform.fxh"

Texture2D gValueTex;


//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float chooseChannel(float4 color) { return color.r; }

float sampleAt(float2 uv) { return chooseChannel(gValueTex.Sample(gSampler, uv)); }
float sampleAt(float2 uv, int dx, int dy) { return sampleAt(uv + gTexel * float2(dx, dy)); }

float loadAt(int3 loc) { return chooseChannel(gValueTex.Load(loc)); }
float loadAt(int3 loc, int dx, int dy) { return loadAt(loc + int3(dx, dy, 0)); }



float2 getGradientSampled(float2 uv) {
    float right = sampleAt(uv, 1, 0);
    float left = sampleAt(uv, -1, 0);
    float down = sampleAt(uv, 0, 1);
    float up = sampleAt(uv, 0, -1);

    float topRight = sampleAt(uv, 1, -1);
    float topLeft = sampleAt(uv, -1, -1);
    float downRight = sampleAt(uv, 1, 1);
    float downLeft = sampleAt(uv, -1, 1);

    float xGradient = (right + 0.5 * (topRight + downRight))
                        - (left + 0.5 * (topLeft + downLeft));

    float yGradient = (down + 0.5 * (downRight + downLeft))
                        - (up + 0.5 * (topRight + topLeft));

    float2 gradient = float2(xGradient, yGradient);

    return normalize(gradient);
}

//                        _ _            _        __ _           _ _             
//     __ _ _ __ __ _  __| (_) ___ _ __ | |_     / _(_)_ __   __| (_)_ __   __ _ 
//    / _` | '__/ _` |/ _` | |/ _ \ '_ \| __|   | |_| | '_ \ / _` | | '_ \ / _` |
//   | (_| | | | (_| | (_| | |  __/ | | | |_    |  _| | | | | (_| | | | | | (_| |
//    \__, |_|  \__,_|\__,_|_|\___|_| |_|\__|   |_| |_|_| |_|\__,_|_|_| |_|\__, |
//    |___/                                                                |___/ 
// Contributor: Oliver Vainumäe
// Finds the gradient vectors based on gValueTex (sampled)
float2 gradientTowardsEdgeSampledFrag(vertexOutputSampler i) : SV_Target {
    return getGradientSampled(i.uv);
}



float2 getGradient(int3 loc) {
    float right = loadAt(loc, 1, 0);
    float left = loadAt(loc, -1, 0);
    float down = loadAt(loc, 0, 1);
    float up = loadAt(loc, 0, -1);

    float topRight = loadAt(loc, 1, -1);
    float topLeft = loadAt(loc, -1, -1);
    float downRight = loadAt(loc, 1, 1);
    float downLeft = loadAt(loc, -1, 1);

    float xGradient = (right + 0.5 * (topRight + downRight))
                        - (left + 0.5 * (topLeft + downLeft));

    float yGradient = (down + 0.5 * (downRight + downLeft))
                        - (up + 0.5 * (topRight + topLeft));

    float2 gradient = float2(xGradient, yGradient);

    return normalize(gradient);
}

//                        _ _            _        __ _           _ _             
//     __ _ _ __ __ _  __| (_) ___ _ __ | |_     / _(_)_ __   __| (_)_ __   __ _ 
//    / _` | '__/ _` |/ _` | |/ _ \ '_ \| __|   | |_| | '_ \ / _` | | '_ \ / _` |
//   | (_| | | | (_| | (_| | |  __/ | | | |_    |  _| | | | | (_| | | | | | (_| |
//    \__, |_|  \__,_|\__,_|_|\___|_| |_|\__|   |_| |_|_| |_|\__,_|_|_| |_|\__, |
//    |___/                                                                |___/ 
// Contributor: Oliver Vainumäe
// Finds the gradient vectors based on gValueTex
float2 gradientTowardsEdgeFrag(vertexOutput i) : SV_Target {
    return getGradient(int3(i.pos.xy, 0));
}


// Just a debug
// this is for debugging and for getting a good illustration of vector angles
float3 gradientTowardsEdgeDebugFrag(vertexOutput i) : SV_Target {
    float2 gradient = getGradient(int3(i.pos.xy, 0));

    float angle = atan(gradient.y / gradient.x);

    angle = angle / PI * 180 + 360;

    if (gradient.x < 0.0)
        angle += 180;
        
    angle %= 360;

    float3 hsv = float3(angle, 1.0, 1.0);
    float3 rgb = hsv2rgb(hsv);

    return rgb;
}

technique11 gradientTowardsEdgeSampled {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, gradientTowardsEdgeSampledFrag()));
    }
};

technique11 gradientTowardsEdge {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, gradientTowardsEdgeFrag()));
        // SetPixelShader(CompileShader(ps_5_0, gradientTowardsEdgeDebugFrag()));
    }
};