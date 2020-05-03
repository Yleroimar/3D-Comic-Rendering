////////////////////////////////////////////////////////////////////////////////////////////////////
// quadStyleLoad10.fx (HLSL)
// Brief: loading render targets for the style
// Contributors: Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////////////////////
//        _         _            _                 _ 
//    ___| |_ _   _| | ___      | | ___   __ _  __| |
//   / __| __| | | | |/ _ \_____| |/ _ \ / _` |/ _` |
//   \__ \ |_| |_| | |  __/_____| | (_) | (_| | (_| |
//   |___/\__|\__, |_|\___|     |_|\___/ \__,_|\__,_|
//            |___/
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader loads the required elements for future stylization in Water Memory style in MNPR
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gHatchingTex;


//
struct FragmentOutput { float4 hatchingOutput : SV_Target0; };


// Contributors: Oliver Vainumäe
FragmentOutput adjustLoadFrag(vertexOutputSampler i) {
	FragmentOutput result;
    int3 loc = int3(i.pos.xy, 0);  // coordinates for loading texels

	// get proper UVS
	/*
    float2 uv = i.uv * (gScreenSize / gSubstrateTexDimensions) * (gSubstrateTexScale)
                        + gSubstrateTexUVOffset;
    */
    float2 uv = i.uv * 1.0;
    
	// get hatching pixel
	float3 hatching = gHatchingTex.Sample(gSampler, uv).rgb;

    result.hatchingOutput = hatching;

	return result;
}



//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
technique11 styleLoad {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
		SetPixelShader(CompileShader(ps_5_0, adjustLoadFrag()));
	}
}
