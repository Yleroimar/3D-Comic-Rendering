////////////////////////////////////////////////////////////////////////////////////////////////////
// quadCommon.fxh (HLSL)
// Brief: Common utility shader elements for MNPR
// Contributors: Santiago Montesdeoca, Oliver Vainumäe
////////////////////////////////////////////////////////////////////////////////////////////////////
//                          _
//     __ _ _   _  __ _  __| |       ___ ___  _ __ ___  _ __ ___   ___  _ __
//    / _` | | | |/ _` |/ _` |_____ / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \| '_ \
//   | (_| | |_| | (_| | (_| |_____| (_| (_) | | | | | | | | | | | (_) | | | |
//    \__, |\__,_|\__,_|\__,_|      \___\___/|_| |_| |_|_| |_| |_|\___/|_| |_|
//       |_|
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader file provides utility variables, structs, vertex shader and functions to aid
// the development of quad operations in MNPR
////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef _QUADCOMMON_FXH
#define _QUADCOMMON_FXH


// COMMON MAYA VARIABLES
float4x4 gWVP : WorldViewProjection;     // world-view-projection transformation
float2 gScreenSize : ViewportPixelSize;  // screen size, in pixels


// COMMON VARIABLES
static float3 luminanceCoeff = float3(0.241, 0.691, 0.068);
static float2 gTexel = 1.0f / gScreenSize;
static const float PI = 3.14159265f;


// COMMON TEXTURES
Texture2D gColorTex;      // color target


// COMMON SAMPLERS
uniform SamplerState gSampler;



//        _                   _
//    ___| |_ _ __ _   _  ___| |_ ___
//   / __| __| '__| | | |/ __| __/ __|
//   \__ \ |_| |  | |_| | (__| |_\__ \
//   |___/\__|_|   \__,_|\___|\__|___/
//
// base input structs
struct appData {
	float3 vertex : POSITION;
};

struct appDataSampler {
	float3 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
};

struct vertexOutput {
	float4 pos : SV_POSITION;
};

struct vertexOutputSampler {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};



//                   _                    _               _
//   __   _____ _ __| |_ _____  __    ___| |__   __ _  __| | ___ _ __ ___
//   \ \ / / _ \ '__| __/ _ \ \/ /   / __| '_ \ / _` |/ _` |/ _ \ '__/ __|
//    \ V /  __/ |  | ||  __/>  <    \__ \ | | | (_| | (_| |  __/ |  \__ \
//     \_/ \___|_|   \__\___/_/\_\   |___/_| |_|\__,_|\__,_|\___|_|  |___/
//
// VERTEX SHADER
vertexOutput quadVert(appData v) {
	vertexOutput o;
	o.pos = mul(float4(v.vertex, 1.0f), gWVP);
	return o;
}

// VERTEX SHADER (with uvs)
vertexOutputSampler quadVertSampler(appDataSampler v) {
	vertexOutputSampler o;
	o.pos = mul(float4(v.vertex, 1.0f), gWVP);
	o.uv = v.texcoord;
	return o;
}



//     __                  _   _
//    / _|_   _ _ __   ___| |_(_) ___  _ __  ___
//   | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
//   |  _| |_| | | | | (__| |_| | (_) | | | \__ \
//   |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//
float luminance(float3 color) { return dot(color.rgb, luminanceCoeff); }

float4 unpremultiply(float4 color) {
	if (color.a) color.rgb /= color.a;
	
	return color;
}

/*
 * All of these functions have been made to make
 * all the shader code consistent and to reduce
 * the times the same functionality gets implemented.
 *
 * For example:
 *  I might make a mistake in one of the cases
 *  I write a conversion between screen and uv spaces.
 *  If I implement it only here and use it everywhere,
 *  I can fix this mistake by only editing the code here.
 * 
 * Overall this should make the code shorter and easier
 * to read once the reader is familair with these functions.
 * 
 * Looks like this low-level language is being
 * given high-level funtions.
 */

float4 loadColorTex(int3 loc) { return gColorTex.Load(loc); }

/**
 * Returns:
 *	 0 if maxDistance < distance,
 *   1 if distance < falloffStart,
 *   x from [0; 1] based on the falloff.
 */
float falloffValue(float distance, float maxDistance, float falloffStart) {
    if (maxDistance < distance) return 0.0;

    if (distance < falloffStart) return 1.0;

    float falloffLength = maxDistance - falloffStart;

    float distanceToMax = maxDistance - distance;

    return distanceToMax / falloffLength;
}

// had to redefine max and min,
// because otherwise VSC analyzer would make the use of regular min/max red.
float max(float a, float b) { return a > b ? a : b; }
float max(float2 xy) { return max(xy.x, xy.y); }
float max(float3 rgb) { return max(max(rgb.rg), rgb.b); }
float max(float4 rgba) { return max(max(rgba.rgb), rgba.a); }

float min(float a, float b) { return a < b ? a : b; }
float min(float2 xy) { return min(xy.x, xy.y); }
float min(float3 rgb) { return min(min(rgb.rg), rgb.b); }
float min(float4 rgba) { return min(min(rgba.rgb), rgba.a); }

float avg(float2 xy) { return (xy.x + xy.y) / 2.0; }
float avg(float3 rgb) { return (rgb.r + rgb.g + rgb.b) / 3.0; }
float avg(float4 rgba) { return (rgba.r + rgba.g + rgba.b + rgba.a) / 4.0; }

float mod(float x, float y) {
	// Now I am wondering if this is the same as the % operator?
    return x - y * floor(x / y);
}

// offset a float2 screen-location to int2
int2 offsetScreen(float2 xy) { return round(xy); }
int2 offsetScreen(int2 xy, float2 dxy) { return offsetScreen(xy + dxy); }
int2 offsetScreen(int3 loc, float2 dxy) { return offsetScreen(loc.xy + dxy); }
// offset a float2 screen-location to int3
int3 offsetLoc(float2 xy) { return int3(offsetScreen(xy), 0); }
int3 offsetLoc(int2 xy, float2 dxy) { return int3(offsetScreen(xy, dxy), 0); }
int3 offsetLoc(int3 loc, float2 dxy) { return int3(offsetScreen(loc, dxy), 0); }

float2 screen2uv(int2 xy) { return xy * gTexel; }
float2 screen2uv(float2 xy) { return offsetScreen(xy) * gTexel; }
float2 screen2uv(int3 loc) { return screen2uv(loc.xy); }
int2 uv2screen(float2 uv) { return offsetScreen(uv / gTexel); }
int3 uv2loc(float2 uv) { return int3(uv2screen(uv), 0); }

int2 kernelOffsetScreen(int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return int2(i % kernelWidth - kernelWidthHalf,
				i / kernelWidth - kernelWidthHalf);
}
int2 kernelOffsetScreen(int i, int kernelWidth) {
	return kernelOffsetScreen(i, kernelWidth,
							  kernelWidth / 2,
							  kernelWidth * kernelWidth);
}
int2 kernelOffsetScreen(int2 xy,
						int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return xy + kernelOffsetScreen(i, kernelWidth, kernelWidthHalf, kernelSize);
}
int2 kernelOffsetScreen(int3 loc,
						int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return kernelOffsetScreen(loc.xy, i, kernelWidth, kernelWidthHalf, kernelSize);
}

int3 kernelOffsetLoc(int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return int3(kernelOffsetScreen(i, kernelWidth, kernelWidthHalf, kernelSize), 0);
}
int3 kernelOffsetLoc(int i, int kernelWidth) {
	return int3(kernelOffsetScreen(i, kernelWidth), 0);
}
int3 kernelOffsetLoc(int2 xy,
					 int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return int3(kernelOffsetScreen(xy, i, kernelWidth, kernelWidthHalf, kernelSize), 0);
}
int3 kernelOffsetLoc(int3 loc,
					 int i, int kernelWidth, int kernelWidthHalf, int kernelSize) {
	return int3(kernelOffsetScreen(loc, i, kernelWidth, kernelWidthHalf, kernelSize), 0);
}


#endif /* _QUADCOMMON_FXH */
