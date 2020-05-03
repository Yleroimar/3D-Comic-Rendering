#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gEdgeTex;


// VARIABLES


// FIXED VARIABLES
static const int cPaintedWidth = 20;
// static const int cPaintedWidth = 10;


//     __                  _   _                 
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___ 
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
// SIGMOID WEIGHT
float sigmoidWeight(float x) {
    float weight = 1.0 - x;  // inverse normalized gradient | 0...0,5...1...0,5...0

    // increase amplitude by 2 and shift by -1 | -1...0...1...0...-1 (so that 0,5 in the gradient is not 0
    weight = weight * 2.0 - 1.0;
    
    // square the weights(fractions) and multiply them by 0.5 to accentuate sigmoid
    weight = (-weight * abs(weight) * 0.5) + weight + 0.5;

    // possibly faster version?
    //return dot(float3(-weight, 2.0, 1.0 ),float3(abs(weight), weight, 1.0)) * 0.5;

    return weight;
}

float cosineWeight(float x) { return cos(x * PI / 2); }

float gaussianWeight(float x, float sigma) {
    //return pow((6.283185*sigma*sigma), -0.5) * exp((-0.5*x*x) / (sigma*sigma));
    return 0.15915 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

float linearWeight(float x) { return 1.0 - x; }



float getSigma(int kernelRadius) { return kernelRadius / 3; }

float getWeight(int stepNr, float sigma, int kernelRadius) {
    return gaussianWeight(stepNr, sigma);
    return linearWeight(stepNr / kernelRadius);
    return cosineWeight(stepNr / kernelRadius);
    return sigmoidWeight(stepNr / kernelRadius);
}



float getEdgeIntensity(float4 color) { return color.r; }

float4 sampleEdgeTex(float2 uv) { return gEdgeTex.Sample(gSampler, uv); }
float sampleEdgeIntensity(float2 uv) { return getEdgeIntensity(sampleEdgeTex(uv)); }

float4 loadEdgeTex(int3 loc) { return gEdgeTex.Load(loc); }
float loadEdgeIntensity(int3 loc) { return getEdgeIntensity(loadEdgeTex(loc)); }



float edgeBlurSampled(float2 uv, float2 dir) {
    int kernelRadius = max(1, cPaintedWidth);
    
    float sigma = getSigma(kernelRadius);
    float weight = getWeight(0, sigma, kernelRadius);

    float edgeGradient = sampleEdgeIntensity(uv) * weight;
    float normDivisor = weight;

    [unroll(20)]
    for (int o = 1; o <= kernelRadius; o++) {
        float offsetIntensity = sampleEdgeIntensity(uv - o * dir) 
                              + sampleEdgeIntensity(uv + o * dir);

        weight = getWeight(o, sigma, kernelRadius);

        edgeGradient += weight * offsetIntensity;
        normDivisor += weight * 2;
    }

    return edgeGradient / normDivisor;
}

float edgeBlur(int3 loc, int3 dir) {
    int kernelRadius = max(1, cPaintedWidth);
    
    float sigma = getSigma(kernelRadius);
    float weight = getWeight(0, sigma, kernelRadius);

    float edgeGradient = loadEdgeIntensity(loc) * weight;
    float normDivisor = weight;

    [unroll(20)]
    for (int o = 1; o <= kernelRadius; o++) {
        float offsetIntensity = loadEdgeIntensity(loc - o * dir) 
                              + loadEdgeIntensity(loc + o * dir);

        weight = getWeight(o, sigma, kernelRadius);

        edgeGradient += weight * offsetIntensity;
        normDivisor += weight * 2;
    }

    return edgeGradient / normDivisor;
}


//    _                _                _        _ 
//   | |__   ___  _ __(_)_______  _ __ | |_ __ _| |
//   | '_ \ / _ \| '__| |_  / _ \| '_ \| __/ _` | |
//   | | | | (_) | |  | |/ / (_) | | | | || (_| | |
//   |_| |_|\___/|_|  |_/___\___/|_| |_|\__\__,_|_|
//                                                 
float horizontalSampledFrag(vertexOutputSampler i) : SV_Target {
    return edgeBlurSampled(i.uv, gTexel * float2(1.0f, 0.0f));
}

float horizontalFrag(vertexOutput i) : SV_Target {
    return edgeBlur(int3(i.pos.xy, 0), int3(1, 0, 0));
}



//                   _   _           _ 
//   __   _____ _ __| |_(_) ___ __ _| |
//   \ \ / / _ \ '__| __| |/ __/ _` | |
//    \ V /  __/ |  | |_| | (_| (_| | |
//     \_/ \___|_|   \__|_|\___\__,_|_|
//                                     
float verticalSampledFrag(vertexOutputSampler i) : SV_Target {
    return edgeBlurSampled(i.uv, gTexel * float2(0.0f, 1.0f));
}

float verticalFrag(vertexOutput i) : SV_Target {
    return edgeBlur(int3(i.pos.xy, 0), int3(0, 1, 0));
}



//    _            _           _                       
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___ 
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|       
// Horizontal Blur
technique11 blurHsampled {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, horizontalSampledFrag()));
    }
};

technique11 blurH {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetPixelShader(CompileShader(ps_5_0, horizontalFrag()));
    }
};


// Vertical Blur
technique11 blurVsampled {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
        SetPixelShader(CompileShader(ps_5_0, verticalSampledFrag()));
    }
};

technique11 blurV {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetPixelShader(CompileShader(ps_5_0, verticalFrag()));
    }
};
