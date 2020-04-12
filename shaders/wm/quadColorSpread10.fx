#include "..\\include\\quadCommon.fxh"

Texture2D gDiffuseTex;
Texture2D gDepthTex;
Texture2D gSpreadControl;

int3 getOffsetLoc(int3 loc, int i, int j) {
    return loc + int3(i, j, 0);
}

float getDistanceBetween(int3 loc1, int3 loc2) {
    return length(loc1 - loc2);
}


float4 testFrag(vertexOutput i) : SV_Target {
    int3 loc = int3(i.pos.xy, 0);

    float4 localColor = gColorTex.Load(loc);
    float localDepth = gDepthTex.Load(loc).r;

    if (localColor.a == 0.0) return float4(localColor.rgb, localColor.a);

    int radius = 10;

    float3 collectedColor = float3(localColor.rgb);

    int pixels = 0;

    [unroll(20)]
    for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {
            int3 loc2 = getOffsetLoc(loc, i, j);

            float distance = getDistanceBetween(loc, loc2);

            if (radius < distance) continue;
            
            float depth2 = gDepthTex.Load(loc2).r;

            // if the other pixel is in front then skip
            if (depth2 < localDepth) continue;

            float4 color2 = gColorTex.Load(loc2);

            if (color2.a == 0.0) continue;

            collectedColor += color2.rgb;
            pixels++;
        }
    }
    
    return float4(collectedColor / float(pixels), 1.0);
}


technique11 testTech {
    pass p0 {
        SetVertexShader(CompileShader(vs_5_0, quadVert()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, testFrag()));
    }
};