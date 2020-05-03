/////////////////////////////////////////////////////////////////////////////
// quadEdgeDetection10.fx (HLSL)
// Brief: Edge detection operations
// Contributors: Santiago Montesdeoca
/////////////////////////////////////////////////////////////////////////////
//             _                    _      _            _   _
//     ___  __| | __ _  ___      __| | ___| |_ ___  ___| |_(_) ___  _ __
//    / _ \/ _` |/ _` |/ _ \    / _` |/ _ \ __/ _ \/ __| __| |/ _ \| '_ \
//   |  __/ (_| | (_| |  __/   | (_| |  __/ ||  __/ (__| |_| | (_) | | | |
//    \___|\__,_|\__, |\___|    \__,_|\___|\__\___|\___|\__|_|\___/|_| |_|
//               |___/
/////////////////////////////////////////////////////////////////////////////
// This shader file provides different algorithms for edge detection in MNPR
// 1.- Sobel edge detection
// 2.- DoG edge detection
/////////////////////////////////////////////////////////////////////////////
#include "include\\quadCommon.fxh"

// TEXTURES
Texture2D gCurrentTex;
Texture2D gDepthTex;
Texture2D gNormalsTex;


struct RGBDN {
	float4 rgbd;
	float3 normal;
	float weightSum;
};


//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float4 loadCurrentTex(int3 loc) { return gCurrentTex.Load(loc); }

float3 loadColor(int3 loc) { return gColorTex.Load(loc).rgb; }

float loadDepth(int3 loc) { return gDepthTex.Load(loc).r; }

float4 loadNormalsTex(int3 loc) { return gNormalsTex.Load(loc); }
float3 loadNormals(float4 normalsTex) { return normalsTex.rgb; }
float3 loadNormals(int3 loc) { return loadNormals(loadNormalsTex(loc)); }
int loadObjectID(float4 normalsTex) { return round(normalsTex.a * 100); }
int loadObjectID(int3 loc) { return loadObjectID(loadNormalsTex(loc)); }
int loadObjectID(int3 loc, int dx, int dy) { return loadObjectID(loc + int3(dx, dy, 0)); }

float4 rgbd(int3 loc) { return float4(loadColor(loc), loadDepth(loc)); }
float4 rgbd(int3 loc, int dx, int dy) { return rgbd(loc + int3(dx, dy, 0)); }


RGBDN rgbdn(int3 loc) {
	RGBDN result;

	result.rgbd = rgbd(loc);
	result.normal = loadNormals(loc);
	result.weightSum = 0.0; // warning evasion

	return result;
}
RGBDN rgbdn(int3 loc, int dx, int dy) { return rgbdn(loc + int3(dx, dy, 0)); }






//              _          _     ____   ____ ____  ____
//    ___  ___ | |__   ___| |   |  _ \ / ___| __ )|  _ \
//   / __|/ _ \| '_ \ / _ \ |   | |_) | |  _|  _ \| | | |
//   \__ \ (_) | |_) |  __/ |   |  _ <| |_| | |_) | |_| |
//   |___/\___/|_.__/ \___|_|   |_| \_\\____|____/|____/
//

// Contributor: Santiago Montesdeoca
// Performs a sobel edge detection on RGBD channels
// -> Based on the sobel image processing operator by Sobel and Feldman 1968 
//    [1968] A 3x3 Isotropic Gradient Operator for Image Processing
float3 sobelRGBDFrag(vertexOutput i) : SV_Target {
	int3 loc = int3(i.pos.xy, 0);  // for load sampling

	// get rgb values at kernel area
	float4 topLeft = rgbd(loc, -1, -1);
	float4 topMiddle = rgbd(loc, 0, -1);
	float4 topRight = rgbd(loc, 1, -1);
	float4 midLeft = rgbd(loc, -1, 0);
	float4 middle = rgbd(loc);
	float4 midRight = rgbd(loc, 1, 0);
	float4 bottomLeft = rgbd(loc, -1, 1);
	float4 bottomMiddle = rgbd(loc, 0, 1);
	float4 bottomRight = rgbd(loc, 1, 1);

	// convolve with kernel
	// HORIZONTAL        VERTICAL
	// -1  -2  -1       -1   0   1
	//  0   0   0       -2   0   2
	//  1   2   1       -1   0   1

	float4 hKernelMul = (1 * topLeft) + (2 * topMiddle) + (1 * topRight) +
        				(-1 * bottomLeft) + (-2 * bottomMiddle) + (-1 * bottomRight);

	float4 vKernelMul = (1 * topLeft) + (-1 * topRight) +
        				(2 * midLeft) + (-2 * midRight) +
        				(1 * bottomLeft) + (-1 * bottomRight);

	hKernelMul.a *= 5;  // modulate depth
	float rgbdHorizontal = length(hKernelMul);
	// float rgbdHorizontal = max3(hKernelMul.rgb);

	vKernelMul.a *= 5;  // modulate depth
	float rgbdVertical = length(vKernelMul);
	// float rgbdVertical = max3(vKernelMul.rgb);

	float edgeMagnitude = length(float2(rgbdHorizontal, rgbdVertical));

	return edgeMagnitude.xxx;
}


float4 sobelRGBDNFrag(vertexOutput i) : SV_Target {
	int3 loc = int3(i.pos.xy, 0);

	// get rgb values at kernel area
	RGBDN topLeft = rgbdn(loc, -1, -1);
	RGBDN topMiddle = rgbdn(loc, 0, -1);
	RGBDN topRight = rgbdn(loc, 1, -1);
	RGBDN midLeft = rgbdn(loc, -1, 0);
	RGBDN middle = rgbdn(loc);
	RGBDN midRight = rgbdn(loc, 1, 0);
	RGBDN bottomLeft = rgbdn(loc, -1, 1);
	RGBDN bottomMiddle = rgbdn(loc, 0, 1);
	RGBDN bottomRight = rgbdn(loc, 1, 1);

	// convolve with kernel
	// HORIZONTAL        VERTICAL
	// -1  -2  -1       -1   0   1
	//  0   0   0       -2   0   2
	//  1   2   1       -1   0   1

	float4 hKernelMulRGBD =
		(1 * topLeft.rgbd) + (2 * topMiddle.rgbd) + (1 * topRight.rgbd) +
        (-1 * bottomLeft.rgbd) + (-2 * bottomMiddle.rgbd) + (-1 * bottomRight.rgbd);

	float3 hKernelMulN =
		(1 * topLeft.normal) + (2 * topMiddle.normal) + (1 * topRight.normal) +
        (-1 * bottomLeft.normal) + (-2 * bottomMiddle.normal) + (-1 * bottomRight.normal);

	float4 vKernelMulRGBD =
		(1 * topLeft.rgbd) + (-1 * topRight.rgbd) +
		(2 * midLeft.rgbd) + (-2 * midRight.rgbd) +
		(1 * bottomLeft.rgbd) + (-1 * bottomRight.rgbd);

	float3 vKernelMulN =
		(1 * topLeft.normal) + (-1 * topRight.normal) +
		(2 * midLeft.normal) + (-2 * midRight.normal) +
		(1 * bottomLeft.normal) + (-1 * bottomRight.normal);

	float rgbHorizontal = length(hKernelMulRGBD.rgb);
	float dHorizontal = hKernelMulRGBD.a * 5.0;
	float nHorizontal = length(hKernelMulN.rgb);

	float rgbVertical = length(vKernelMulRGBD.rgb);
	float dVertical = vKernelMulRGBD.a * 5.0;
	float nVertical = length(vKernelMulN.rgb);

	float edgeMagnitudeRGB = length(float2(rgbHorizontal, rgbVertical));
	float edgeMagnitudeD = length(float2(dHorizontal, dVertical));
	float edgeMagnitudeN = length(float2(nHorizontal, nVertical));

	return float4(edgeMagnitudeRGB, edgeMagnitudeD, edgeMagnitudeN,
				  length(float3(edgeMagnitudeRGB,
				  				edgeMagnitudeD,
								edgeMagnitudeN)));
}



//    ____         ____     ____   ____ ____  ____
//   |  _ \  ___  / ___|   |  _ \ / ___| __ )|  _ \
//   | | | |/ _ \| |  _    | |_) | |  _|  _ \| | | |
//   | |_| | (_) | |_| |   |  _ <| |_| | |_) | |_| |
//   |____/ \___/ \____|   |_| \_\\____|____/|____/
//

// Contributor: Santiago Montesdeoca
// Performs a Difference of Gaussians edge detection on RGBD channels
float3 dogRGBDFrag(vertexOutput i) : SV_Target{
	int3 loc = int3(i.pos.xy, 0);  // for load sampling

	// get rgb values at kernel area
	float4 topLeft = rgbd(loc, -1, -1);
	float4 topMiddle = rgbd(loc, 0, -1);
	float4 topRight = rgbd(loc, 1, -1);
	float4 midLeft = rgbd(loc, -1, 0);
	float4 middle = rgbd(loc);
	float4 midRight = rgbd(loc, 1, 0);
	float4 bottomLeft = rgbd(loc, -1, 1);
	float4 bottomMiddle = rgbd(loc, 0, 1);
	float4 bottomRight = rgbd(loc, 1, 1);

	// convolve with kernel
	//           SIGMA 1.0
	// 0.077847   0.123317   0.077847
	// 0.123317   0.195346   0.123317
	// 0.077847   0.123317   0.077847

	float4 gaussianKernelMul =
        (0.077847 * topLeft) + (0.123317 * topMiddle) + (0.077847 * topRight) +
		(0.123317 * midLeft) + (0.195346 * middle) + (0.123317 * midRight) +
		(0.077847 * bottomLeft) + (0.123317 * bottomMiddle) + (0.077847 * bottomRight);

	// calculate difference of gaussians
	float4 dog = saturate(middle - gaussianKernelMul);
	dog.a *= 3.0;  // modulate depth
	float edgeMagnitude = length(dog);
	// float edgeMagnitude = max(max3(dog.rgb), dog.a);

	if (edgeMagnitude > 0.05)
		edgeMagnitude = 1.0;

	return edgeMagnitude.xxx;
}


float4 dogRGBDNFrag(vertexOutput i) : SV_Target{
	int3 loc = int3(i.pos.xy, 0);

	RGBDN topLeft = rgbdn(loc, -1, -1);
	RGBDN topMiddle = rgbdn(loc, 0, -1);
	RGBDN topRight = rgbdn(loc, 1, -1);
	RGBDN midLeft = rgbdn(loc, -1, 0);
	RGBDN middle = rgbdn(loc);
	RGBDN midRight = rgbdn(loc, 1, 0);
	RGBDN bottomLeft = rgbdn(loc, -1, 1);
	RGBDN bottomMiddle = rgbdn(loc, 0, 1);
	RGBDN bottomRight = rgbdn(loc, 1, 1);

	// convolve with kernel
	//           SIGMA 1.0
	// 0.077847   0.123317   0.077847
	// 0.123317   0.195346   0.123317
	// 0.077847   0.123317   0.077847

	float w1 = 0.195346;
	float w2 = 0.123317;
	float w3 = 0.077847;

	float4 gaussianKernelMulRGBD =
        (w3 * topLeft.rgbd) + (w2 * topMiddle.rgbd) + (w3 * topRight.rgbd) +
		(w2 * midLeft.rgbd) + (w1 * middle.rgbd) + (w2 * midRight.rgbd) +
		(w3 * bottomLeft.rgbd) + (w2 * bottomMiddle.rgbd) + (w3 * bottomRight.rgbd);

	float3 gaussianKernelMulNormals =
        (w3 * topLeft.normal) + (w2 * topMiddle.normal) + (w3 * topRight.normal) +
		(w2 * midLeft.normal) + (w1 * middle.normal) + (w2 * midRight.normal) +
		(w3 * bottomLeft.normal) +  (w2 * bottomMiddle.normal) + (w3 * bottomRight.normal);

	// calculate difference of gaussians
	float4 dogRGBD = saturate(middle.rgbd - gaussianKernelMulRGBD);
	float3 dogNormal = saturate(middle.normal - gaussianKernelMulNormals);
	float edgeMagnitudeRGB = length(dogRGBD.rgb);
	float edgeMagnitudeD = dogRGBD.a * 3.0; // modulate depth
	float edgeMagnitudeN = length(dogNormal);
	// float edgeMagnitude = max(max3(dog.rgb), dog.a);

	return float4(edgeMagnitudeRGB, edgeMagnitudeD, edgeMagnitudeN, 1.0);
}


float gaussianWeight(float x, float y, float sigma) {
    // return 0.15915 * exp(-0.5 * (x * x + y * y) / (sigma * sigma)) / (sigma);
    return 0.15915 * exp(-0.5 * (x * x + y * y) / (sigma * sigma)) / (sigma);
}
float gaussianWeight(int3 dloc, float sigma) { return gaussianWeight(dloc.x, dloc.y, sigma); }

RGBDN getKernelResult(int3 loc, int kernelWidth, float sigma) {
	RGBDN result;

	float4 value4 = float4(0.0, 0.0, 0.0, 0.0);

	result.rgbd = float4(0.0, 0.0, 0.0, 0.0);
	result.normal = float3(0.0, 0.0, 0.0);
	result.weightSum = 0.0;

	int kernelWidthHalf = kernelWidth / 2;
	int kernelSize = kernelWidth * kernelWidth;

	[unroll(25)]
	for (int i = 0; i < kernelSize; i++) {
		int3 dloc = kernelOffsetLoc(i, kernelWidth,
								   kernelWidthHalf, kernelSize);

		int3 loc2 = loc + dloc;

		RGBDN values = rgbdn(loc2);
		float weight = gaussianWeight(dloc, sigma);

		value4 += weight * values.rgbd;

		result.rgbd += weight * values.rgbd;
		result.normal += weight * values.normal;
		result.weightSum += weight;
	}

	result.rgbd = value4 / result.weightSum;
	result.normal /= result.weightSum;

	return result;
}
// RGBDN getKernelResult(int3 loc, int kernelWidth) {
// 	return getKernelResult(loc, kernelWidth, 0.5 * kernelWidth);
// }

float4 badDogRGBDNFrag(vertexOutput vertex) : SV_Target{
	int3 loc = int3(vertex.pos.xy, 0);

	// RGBDN kernelResult1 = getKernelResult(loc, 5, 0.1);
	RGBDN kernelResult1 = getKernelResult(loc, 5, 1.0);
	// RGBDN kernelResult1 = rgbdn(loc);
	// RGBDN kernelResult2 = getKernelResult(loc, 5, 2.1);
	RGBDN kernelResult2 = getKernelResult(loc, 5, 1.6);

	// calculate difference of gaussians
	float4 dogRGBD = kernelResult1.rgbd - kernelResult2.rgbd;
	float3 dogNormal = kernelResult1.normal - kernelResult2.normal;

	float edgeMagnitudeRGB = length(dogRGBD.rgb);
	float edgeMagnitudeD = 100.0 * dogRGBD.a;
	float edgeMagnitudeN = 3.0 * length(dogNormal);
	edgeMagnitudeN = 4.0 * pow(edgeMagnitudeN, 1.1);
	
	return float4(edgeMagnitudeRGB, edgeMagnitudeD, edgeMagnitudeN, 1.0);
}



float4 objectIDEdgeDetectionFrag(vertexOutput vertex) : SV_Target {
	int3 loc = int3(vertex.pos.xy, 0);

	float4 currentTex = loadCurrentTex(loc);
	currentTex.a = 0.0;

	int id = loadObjectID(loc);

	[unroll(9)]
	for (int i = 0; i < 9; i++) {
		int3 loc2 = kernelOffsetLoc(loc, i, 3, 1, 9);

		int id2 = loadObjectID(loc2);

		if (id == id2) continue;

		currentTex.a = 1.0;
		return currentTex;
	}

	return currentTex;
}



//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// Sobel RGBD edge detection
technique11 sobelRGBDEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, sobelRGBDFrag()));
	}
}

// Sobel RGBDN edge detection
technique11 sobelRGBDNEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, sobelRGBDNFrag()));
	}
}

// Difference of Gaussians RGBD edge detection
technique11 dogRGBDEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, dogRGBDFrag()));
	}
}

// Difference of Gaussians RGBDN edge detection
technique11 dogRGBDNEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, dogRGBDNFrag()));
		// SetPixelShader(CompileShader(ps_5_0, sobelRGBDFrag()));
	}
}

technique11 badDogRGBDNEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, badDogRGBDNFrag()));
	}
}

// ObjectID-based edge detection
technique11 objectIDEdgeDetection {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVert()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, objectIDEdgeDetectionFrag()));
	}
}
