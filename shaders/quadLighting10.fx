#include "include\\quadCommon.fxh"

Texture2D gDiffuseTex;

float positiveScale = 1.0; //0.5;


float4 includeNegativesFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float negativeScale = 1.0 - positiveScale;

    float4 diffuseTex = gDiffuseTex.Load(loc);

    float3 color = negativeScale + positiveScale * diffuseTex.rgb;

    if (length(diffuseTex.rgb) == 0) {
        float value = negativeScale - negativeScale * diffuseTex.a;

        color = float3(value, value, value);
    }

    return float4(color, 1.0);
}


technique11 includeNegatives {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, includeNegativesFrag()));
    }
};