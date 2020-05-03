////////////////////////////////////////////////////////////////////////////////////////////////////
// quadGapsOverlaps10.fx (HLSL)
// Brief: Creating gaps and overlaps at the edges of the rendered image
// Contributors: Santiago Montesdeoca, Pierre B�nard
////////////////////////////////////////////////////////////////////////////////////////////////////
//                             _                        _                 
//     __ _  __ _ _ __  ___   | |    _____   _____ _ __| | __ _ _ __  ___ 
//    / _` |/ _` | '_ \/ __|  | |   / _ \ \ / / _ \ '__| |/ _` | '_ \/ __|
//   | (_| | (_| | |_) \__ \  | |  | (_) \ V /  __/ |  | | (_| | |_) \__ \
//    \__, |\__,_| .__/|___/  | |   \___/ \_/ \___|_|  |_|\__,_| .__/|___/
//    |___/      |_|          |_|                              |_|        
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader provides the algorithms to produce gaps and overlaps commonly found in illustrations
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"
#include "include\\quadColorTransform.fxh"

// TEXTURES
Texture2D gEdgeTex;
Texture2D gControlTex;
Texture2D gBlendingTex;
Texture2D gRenderSize;
Texture2D gNormalsTex; // alpha-channel for object IDs
Texture2D gDepthTex; // to identifty if overlapping color comes from behind or from in front


// VARIABLES
float3 gSubstrateColor = float3(1.0, 1.0, 1.0);
float gGORadius = 5;

float gOverlapLimitWM = 40;
float gOverlapCtrlMultiplierWM = 20;

// MRT
struct fragmentOutput {
    float4 colorOutput : SV_Target0;
    float alphaOutput : SV_Target1;
};



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//

// Contributor: Pierre B�nard
// rgb (red, green, blue) to ryb (red, yellow, blue) color space transformation
// -> Based on color mixing model by Chen et al. 2015
//    [2015] Wetbrush: GPU-based 3D Painting Simulation at the Bristle Level
float3 mixRYB2(float3 color1, float3 color2) {
    float3x3 M = float3x3(0.241, 0, 0, 0, 0.691, 0, 0, 0, 0.068);  // luminance matrix
    // measure RGB brightness of colors
    float b1 = luminance(color1);
    float b2 = luminance(color2);
    //float b1 = pow(dot(color1, mul(M, color1)), 0.5);
    //float b2 = pow(dot(color2, mul(M, color2)), 0.5);
    float bAvg = 0.5*(b1 + b2);
    // convert colors to RYB
    float3 ryb1 = rgb2ryb(color1);
    float3 ryb2 = rgb2ryb(color2);
    // mix colors in RYB space
    float3 rybOut = 0.5*(ryb1 + ryb2);
    // bring back to RGB to measure brightness
    float3 rgbOut = ryb2rgb(rybOut);
    // measure brightness of result
    //float b3 = pow(dot(rgbOut, mul(M, rgbOut)),0.5);
    float b3 = luminance(rgbOut);
    //modify ryb with brightness difference
    rybOut *= (bAvg / b3) * 0.9;  // reduced the brightness a bit

    //convert and send back
    return ryb2rgb(rybOut);
}


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



//                               ___                           _                 
//     __ _  __ _ _ __  ___     ( _ )       _____   _____ _ __| | __ _ _ __  ___ 
//    / _` |/ _` | '_ \/ __|    / _ \/\    / _ \ \ / / _ \ '__| |/ _` | '_ \/ __|
//   | (_| | (_| | |_) \__ \   | (_>  <   | (_) \ V /  __/ |  | | (_| | |_) \__ \
//    \__, |\__,_| .__/|___/    \___/\/    \___/ \_/ \___|_|  |_|\__,_| .__/|___/
//    |___/      |_|                                                  |_|        

// Contributor: Santiago Montesdeoca
// Creates the gaps and overlaps for sketchy illustrated rendering
// -> Based on the gaps & overlaps model by Montesdeoca et al. 2017
//    [2017] Art-directed watercolor stylization of 3D animations in real-time
fragmentOutput gapsOverlapsFrag(vertexOutputSampler i) : SV_Target {
    fragmentOutput result;
    int3 loc = int3(i.pos.xy, 0);

    float eEdges = gEdgeTex.Load(loc).b;
    float gapsOverlaps = gControlTex.Load(loc).b * gGORadius;  // edge control target fidelity (b)
    float blending = gBlendingTex.Load(loc).a;  // contains the blending mask
    
    float4 outColor = gColorTex.Load(loc);
    float mask = outColor.a;
    float goThreshold = 1.0 / gGORadius;

    // make sure we are not considering emptiness or blending
    if (mask>0.1 && blending < 0.01) {
        // make sure we are at an edge
        if (eEdges > 0.1) {

            // OVERLAPS
            if (gapsOverlaps > 0.1f) {
                // get gradients
                float2 gradient = getGradient(i.uv);
                float4 destColor = outColor;

                gradient = normalize(gradient);

                int o = 1;
                // find vector of gradient (to get neighboring color)
                [unroll(10)]
                for (o = 1; o < gGORadius; o++) {
                    if (gapsOverlaps < o) break;

                    destColor = gColorTex.Sample(gSampler, i.uv + o*(gradient*gTexel));

                    // check with destination color
                    if (length(destColor - outColor) > 0.33) {
                        // no overlap with substrateColor
                        if (length(destColor.rgb - gSubstrateColor) < 0.1) break;
                        
                        outColor.rgb = mixRYB2(outColor.rgb, destColor.rgb);
                        break;
                    }
                }
                
                // check if loop reached the max
                if (o == gGORadius) {
                    // means that gradient was reversed
                    //return float4(1.0, 0, 0, 1.0);
                    destColor = gColorTex.Sample(gSampler, i.uv + (-gradient*gTexel));
                    outColor.rgb = mixRYB2(outColor.rgb, destColor.rgb);
                }
            }


            // GAPS
            else if (gapsOverlaps < -0.1f) {
                // check if it is at an edge
                if (eEdges > goThreshold*2) {
                    //result.colorOutput = float4(0, 0, 0, 0);
                    result.colorOutput = float4(gSubstrateColor, outColor.a);
                    result.alphaOutput = 0.0;
                    return result;
                }

                // get gradients
                float right = gEdgeTex.Sample(gSampler, i.uv + float2(gTexel.x, 0)).b;
                float left = gEdgeTex.Sample(gSampler, i.uv + float2(-gTexel.x, 0)).b;
                float down = gEdgeTex.Sample(gSampler, i.uv + float2(0, gTexel.y)).b;
                float up = gEdgeTex.Sample(gSampler, i.uv + float2(0, -gTexel.y)).b;

                float topRight = gEdgeTex.Sample(gSampler, i.uv + float2(gTexel.x, -gTexel.y)).b;
                float topLeft = gEdgeTex.Sample(gSampler, i.uv + float2(-gTexel.x, -gTexel.y)).b;
                float downRight = gEdgeTex.Sample(gSampler, i.uv + float2(gTexel.x, gTexel.y)).b;
                float downLeft = gEdgeTex.Sample(gSampler, i.uv + float2(-gTexel.x, gTexel.y)).b;

                float uGradient = (right + 0.5*(topRight + downRight)) - (left + 0.5 * (topLeft + downLeft));
                float vGradient = (down + 0.5*(downRight + downLeft)) - (up + 0.5*(topRight + topLeft));
                float2 gradient = float2(uGradient, vGradient);

                // normalize gradient to check neighboring pixels
                gradient = normalize(gradient);
                [unroll(10)]
                for (int o = 1; o < gGORadius; o++) {
                    if (abs(gapsOverlaps) < o / gGORadius) {
                        //outColor.rgb = float3(gapsOverlaps, 0, 0);
                        break;
                    }
                    float destEdges = gEdgeTex.Sample(gSampler, i.uv + o*(gradient*gTexel)).b;
                    // check destionation edge
                    if (destEdges > goThreshold) {
                        outColor.rgb = gSubstrateColor;
                        break;
                    }
                }
            }
        }
    }

    result.colorOutput = float4(outColor);
    result.alphaOutput = outColor.a;

    return result;
}


fragmentOutput overlapsFrag(vertexOutputSampler i) : SV_Target {
    fragmentOutput result;
    int3 loc = int3(i.pos.xy, 0);

    float4 outColor = gColorTex.Load(loc);
    result.colorOutput = outColor;
    result.alphaOutput = outColor.a;

    // get object ID to identify the neighbour.
    float oid = gNormalsTex.Load(loc).a;
    
    float gapsOverlaps = gControlTex.Load(loc).b;
    
    bool takeFromFront = gapsOverlaps < 0;
    gapsOverlaps = abs(gapsOverlaps);

    // make sure we are not considering emptiness,
    // make sure we are at an edge,
    // make sure overlap was desired here
    if (outColor.a < 0.1 || length(gEdgeTex.Load(loc).rgb) < 0.1
                || gapsOverlaps < (1.0 / gOverlapCtrlMultiplierWM))
        return result;
    

    float2 uv = i.uv;
    float2 gradient = getGradientDN(uv);

    float oid2 = oid;
    
    float maxIterations = min(gapsOverlaps * gOverlapCtrlMultiplierWM, gOverlapLimitWM);

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
    if (oid2 == oid) return result;
    
    float2 uv2 = uv + index * (gradient * gTexel);
    int3 loc2 = loc + int3(round(index * gradient), 0.0);
    if (uv2.x < 0.0 || 1.0 < uv2.x || uv2.y < 0.0 || 1.0 < uv2.y) return result;

    // make sure that the overlap comes from front or back as requested
    float depth = gDepthTex.Load(loc).r;
    float depth2 = gDepthTex.Load(loc2).r;
    if (depth2 != depth && (depth2 < depth != takeFromFront)) return result;

    // finally do the overlapping
    float4 overlapColor = gColorTex.Sample(gSampler, uv2);

    float fadeStartDistance = 0.8 * maxIterations;

    float blendValue = index >= fadeStartDistance
        ? 1.0 - (index - fadeStartDistance) / (maxIterations - fadeStartDistance)
        : 1.0;

    outColor.rgb = lerp(outColor.rgb, overlapColor.rgb, blendValue);

    result.colorOutput = float4(outColor);
    return result;
}


//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// GAPS AND OVERLAPS FOR SKETCHIER RENDERING
technique11 gapsOverlaps {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, gapsOverlapsFrag()));
    }
}

// OVERLAPS FOR SKETCHIER WATER MEMORY RENDERING
technique11 overlapsWM {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, overlapsFrag()));
    }
}