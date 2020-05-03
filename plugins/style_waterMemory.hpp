#pragma once
///////////////////////////////////////////////////////////////////////////////////
//                  _            __  __                                 
//   __      ____ _| |_ ___ _ __|  \/  | ___ _ __ ___   ___  _ __ _   _ 
//   \ \ /\ / / _` | __/ _ \ '__| |\/| |/ _ \ '_ ` _ \ / _ \| '__| | | |
//    \ V  V / (_| | ||  __/ |  | |  | |  __/ | | | | | (_) | |  | |_| |
//     \_/\_/ \__,_|\__\___|_|  |_|  |_|\___|_| |_| |_|\___/|_|   \__, |
//                                                                |___/ 
//                                                     
//	 \brief Water memory stylization pipeline
//	 Contains the water memory stylization pipeline with all necessary targets and operations
//
//   Developed by: Oliver Vainum�e
//
///////////////////////////////////////////////////////////////////////////////////
#include "mnpr_renderer.h"


namespace wm {
    void addTargets(MRenderTargetList &targetList) {
        // add style specific targets

        unsigned int tWidth = targetList[0]->width();
        unsigned int tHeight = targetList[0]->height();
        int MSAA = targetList[0]->multiSampleCount();

        unsigned arraySliceCount = 0;
        bool isCubeMap = false;

        MHWRender::MRasterFormat r1 = MHWRender::kR1_UNORM;
        MHWRender::MRasterFormat r8 = MHWRender::kR8_UNORM;
        MHWRender::MRasterFormat r16sn = MHWRender::kR16_SNORM;
        MHWRender::MRasterFormat r16un = MHWRender::kR16_UNORM;
        MHWRender::MRasterFormat rg16sn = MHWRender::kR16G16_SNORM;
        MHWRender::MRasterFormat rgba8 = MHWRender::kR8G8B8A8_SNORM;
        MHWRender::MRasterFormat rgba8un = MHWRender::kR8G8B8A8_UNORM;
        MHWRender::MRasterFormat defaultUserDepth = MHWRender::kR16G16B16A16_SNORM;

        MHWRender::MRasterFormat diffuseDepth = targetList
            .getDescription("diffuseTarget")->rasterFormat();
        MHWRender::MRasterFormat colorDepth = targetList
            .getDescription("colorTarget")->rasterFormat();

        auto appendTarget = [&](const MString &name,
                                ::MHWRender::MRasterFormat rasterFormat) -> void {
            targetList.append(MHWRender::MRenderTargetDescription(
                name, tWidth, tHeight, 1, rasterFormat, arraySliceCount, isCubeMap));
        };

        /*
        targetList.append(MHWRender::MRenderTargetDescription(
            "bleedingTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
        */

        {
            appendTarget("edgeTargetWM", r8);
            appendTarget("edgeThresholdedTarget", r1);
            /*appendTarget("edgeDilatedTarget", r1);*/
            appendTarget("blurredEdgeTarget", r16un);
            appendTarget("edgeGradientTarget", rg16sn);
            appendTarget("edgeUvTarget", rg16sn);
            appendTarget("edgeUvDilatedTarget", rg16sn);
            appendTarget("edgeWidthTarget", rg16sn);
            //appendTarget("edgeUvDebugTarget", colorDepth);
            /*appendTarget("edgeResultTarget", r16sn);*/
            /*appendTarget("edgeResultAverageTarget", colorDepth);*/
        }

        appendTarget("widerDiffuseTarget", diffuseDepth);
        appendTarget("discreteLightTarget", diffuseDepth);
        /*appendTarget("discreteShadingTarget", diffuseDepth);*/

        /*appendTarget("colorSpreadTarget", colorDepth);*/

        /*appendTarget("hatchingTarget", rgba8);*/

        appendTarget("uvTarget", diffuseDepth);
        appendTarget("debugTarget", colorDepth);
    }


    void addOperations(MHWRender::MRenderOperationList &mOperations,
                       MRenderTargetList &mRenderTargets,
                       EngineSettings &mEngSettings,
                       FXParameters &mFxParams) {
        MString opName = "";
        MOperationShader* opShader;
        QuadRender* quadOp;


        // a bunch of lambdas to shorten the rest of the code.
        auto appendOp = [&](std::vector<MString> t_targetDescNames) -> void {
            mOperations.append(new QuadRender(opName,
                                              MHWRender::MClearOperation::kClearNone,
                                              mRenderTargets,
                                              *opShader));

            mRenderTargets.setOperationOutputs(opName, t_targetDescNames);
        };

        auto addTargetParameter = [&](const MString& paramName,
                                      MString t_descName) -> void {
            opShader->addTargetParameter(paramName,
                                         mRenderTargets.getTarget(t_descName));
        };

        auto addParameter = [&](const MString& paramName,
                                std::vector<float>& value) -> void {
            opShader->addParameter(paramName,
                                   value);
        };

        auto addSamplerState = [&](const MString& paramName = "gSampler",
                                   MHWRender::MSamplerState::TextureAddress addressingMode
                                   = MHWRender::MSamplerState::kTexClamp,
                                   MHWRender::MSamplerState::TextureFilter filteringMode
                                   = MHWRender::MSamplerState::kMinMagMipPoint) -> void {
            opShader->addSamplerState(paramName,
                                      addressingMode,
                                      filteringMode);
        };



        {
            opName = "[quad] objectID-based edge-detection";
            opShader = new MOperationShader("quadEdgeDetection", "objectIDEdgeDetection");
            addTargetParameter("gCurrentTex", "edgeTarget");
            addTargetParameter("gNormalsTex", "normalsTarget");
            appendOp({ "edgeTarget" });


            opName = "[quad] edge channel picker";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "edgePicker");
            addTargetParameter("gEdgeTex", "edgeTarget");
            addTargetParameter("gAbstractControlTex", "abstractCtrlTarget");
            appendOp({ "edgeTargetWM" });


            opName = "[quad] edge thresholding";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "thresholdEdges");
            addTargetParameter("gEdgeTex", "edgeTargetWM");
            addParameter("gEdgeThreshold", mFxParams.edgeThresholdWM);
            appendOp({ "edgeThresholdedTarget" });


            /*opName = "[quad] edge target dilate";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdge");
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            appendOp({ "edgeDilatedTarget" });*/


            opName = "[quad] edge control fixing";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "fixEdgeCtrl");
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            addTargetParameter("gDepthTex", "linearDepth");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            appendOp({ "edgeCtrlTarget" });


            opName = "[quad] edge control fixing (2)";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "fixEdgeCtrl");
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            addTargetParameter("gDepthTex", "linearDepth");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            appendOp({ "edgeCtrlTarget" });
        }

        // TODO: REMOVE, THIS IS ONLY FOR THE DURATION TESTING
        bool bruteForce = false;

        if (!bruteForce) {
            opName = "[quad] separable H";
            opShader = new MOperationShader("wm", "quadSeparable", "blurH");
            /*addSamplerState();*/
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            appendOp({ "blurredEdgeTarget" });

            opName = "[quad] separable V";
            opShader = new MOperationShader("wm", "quadSeparable", "blurV");
            /*addSamplerState();*/
            addTargetParameter("gEdgeTex", "blurredEdgeTarget");
            appendOp({ "blurredEdgeTarget" });

            // MERGE BREAK

            opName = "[quad] edge gradient";
            opShader = new MOperationShader("quadGradientFinding", "gradientTowardsEdge");
            /*addSamplerState();*/
            addTargetParameter("gValueTex", "blurredEdgeTarget");
            appendOp({ "edgeGradientTarget" });

            opName = "[quad] closest edge locations";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "edgeUvLocations");
            addSamplerState();
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            addTargetParameter("gGradientTex", "edgeGradientTarget");
            appendOp({ "edgeUvTarget" });

            // MERGE BREAK

            opName = "[quad] dilate edge locations";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvTarget");
            appendOp({ "edgeUvDilatedTarget" });

            // MERGE BREAK

            opName = "[quad] dilate edge locations";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            appendOp({ "edgeUvDilatedTarget" });
        }


        if (bruteForce) {
            opName = "[quad] set edge Locations";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "placeUVs");
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            appendOp({ "edgeUvTarget" });

            opName = "[quad] dilate edge locations 1";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvTarget");
            appendOp({ "edgeUvDilatedTarget" });

            opName = "[quad] dilate edge locations 2";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            appendOp({ "edgeUvDilatedTarget" });

            opName = "[quad] dilate edge locations 3";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            appendOp({ "edgeUvDilatedTarget" });

            opName = "[quad] dilate edge locations 4";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "dilateEdgeLocations");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            appendOp({ "edgeUvDilatedTarget" });
        }


        {
            opName = "[quad] edge width";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "removeFarPixels");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            addParameter("gEdgeWidth", mFxParams.edgeWidthWM);
            appendOp({ "edgeWidthTarget" });


            /*opName = "[quad] edge uv location debug";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "edgeLocationDebug");
            addTargetParameter("gEdgeLocationTex", "edgeWidthTarget");
            appendOp({ "edgeUvDebugTarget" });*/


            /*opName = "[quad] edge intensity";
            opShader = new MOperationShader("wm", "quadEdgeManipulation", "edgeIntensity");
            addTargetParameter("gEdgeLocationTex", "edgeWidthTarget");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            addParameter("gEdgeIntensity", mFxParams.edgeIntensityWM);
            appendOp({ "edgeResultTarget" });*/
        }


        // DISCRETE LIGHT SHADING
        {
            opName = "[quad] widen diffuse target";
            opShader = new MOperationShader("quadLighting", "includeNegatives");
            addTargetParameter("gDiffuseTex", "diffuseTarget");
            addParameter("positiveScale", mFxParams.testingValue);
            appendOp({ "widerDiffuseTarget" });


            opName = "[quad] discrete light";
            opShader = new MOperationShader("wm", "quadSurfaceShading", "discreteLight");
            addTargetParameter("gDiffuseTex", "widerDiffuseTarget");
            addParameter("gShadingTint", mFxParams.shadingTintWM);
            addParameter("gShadingTintWeight", mFxParams.shadingTintWeightWM);
            addParameter("gSurfaceThresholdHigh", mFxParams.shadingThresholdHigh);
            addParameter("gSurfaceThresholdMid", mFxParams.shadingThresholdMid);
            addParameter("gTransitionHighMid", mFxParams.transitionHighMid);
            addParameter("gTransitionMidLow", mFxParams.transitionMidLow);
            addParameter("gSurfaceHighIntensity", mFxParams.shadingIntensityHigh);
            addParameter("gSurfaceMidIntensity", mFxParams.shadingIntensityMid);
            addParameter("gSurfaceLowIntensity", mFxParams.shadingIntensityLow);
            appendOp({ "discreteLightTarget" });


            opName = "[quad] discrete light tint";
            opShader = new MOperationShader("wm", "quadSurfaceShading", "tintShade");
            addTargetParameter("gLightTex", "discreteLightTarget");
            addTargetParameter("gDepthTex", "linearDepth");
            addParameter("gShadingTint", mFxParams.shadingTintWM);
            addParameter("gShadingTintWeight", mFxParams.shadingTintWeightWM);
            appendOp({ "discreteLightTarget" });


            opName = "[quad] surface shading and desaturation";
            opShader = new MOperationShader("wm", "quadSurfaceShading", "shadeSurfaces");
            addTargetParameter("gRenderTex", "stylizationTarget");
            addTargetParameter("gLightTex", "discreteLightTarget");
            addParameter("gShadingDesaturationWeight", mFxParams.shadingDesaturationWeightWM);
            appendOp({ "stylizationTarget" });


            /*opName = "[quad] discrete surfaces";
            opShader = new MOperationShader("quadCelShader", "shadeSurfaces");
            addTargetParameter("gColorTex", "stylizationTarget");
            addTargetParameter("gLightTex", "discreteLightTarget");
            addParameter("gSurfaceThresholdHigh", mFxParams.surfaceThresholdHigh);
            addParameter("gSurfaceThresholdMid", mFxParams.surfaceThresholdMid);
            addParameter("gTransitionHighMid", mFxParams.transitionHighMid);
            addParameter("gTransitionMidLow", mFxParams.transitionMidLow);
            addParameter("gSurfaceHighIntensity", mFxParams.surfaceHighIntensity);
            addParameter("gSurfaceMidIntensity", mFxParams.surfaceMidIntensity);
            addParameter("gSurfaceLowIntensity", mFxParams.surfaceLowIntensity);
            addParameter("gDiffuseCoefficient", mFxParams.diffuseCoefficient);
            addParameter("gSpecularCoefficient", mFxParams.specularCoefficient);
            addParameter("gSpecularPower", mFxParams.specularPower);
            appendOp({ "discreteShadingTarget" });*/


            /* opName = "[quad] cel shading surfaces";
             opShader = new MOperationShader("quadCelShader", "celSurfaces1");
             addTargetParameter("gColorTex", "stylizationTarget");
             addTargetParameter("gDepthTex", "linearDepth");
             addTargetParameter("gSpecularTex", "specularTarget");
             addTargetParameter("gDiffuseTex", "widerDiffuseTarget");
             addParameter("gSurfaceThresholdHigh", mFxParams.surfaceThresholdHigh);
             addParameter("gSurfaceThresholdMid", mFxParams.surfaceThresholdMid);
             addParameter("gTransitionHighMid", mFxParams.transitionHighMid);
             addParameter("gTransitionMidLow", mFxParams.transitionMidLow);
             addParameter("gSurfaceHighIntensity", mFxParams.surfaceHighIntensity);
             addParameter("gSurfaceMidIntensity", mFxParams.surfaceMidIntensity);
             addParameter("gSurfaceLowIntensity", mFxParams.surfaceLowIntensity);
             addParameter("gDiffuseCoefficient", mFxParams.diffuseCoefficient);
             addParameter("gSpecularCoefficient", mFxParams.specularCoefficient);
             addParameter("gSpecularPower", mFxParams.specularPower);
             appendOp({ "stylizationTarget" });*/
        }


        // OVERLAPS
        {
            opName = "[quad] color overlaps";
            opShader = new MOperationShader("wm", "quadOverlaps", "overlaps");
            addTargetParameter("gRenderTex", "stylizationTarget");
            addTargetParameter("gEdgeTex", "edgeThresholdedTarget");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            addTargetParameter("gAbstractControlTex", "abstractCtrlTarget");
            addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
            addTargetParameter("gNormalsTex", "normalsTarget");
            addTargetParameter("gDepthTex", "linearDepth");
            addParameter("gOverlapRange", mFxParams.overlapRangeWM);
            addParameter("gOverlapPickDistance", mFxParams.overlapPickDistanceWM);
            addParameter("gOverlapFalloff", mFxParams.overlapFalloffWM);
            addParameter("gOverlapFalloffSpeed", mFxParams.overlapFalloffSpeedWM);
            addParameter("gOverlapDepthDifference", mFxParams.overlapDepthDifferenceWM);
            appendOp({ "stylizationTarget" });

            /*opName = "[quad] color overlaps";
            opShader = new MOperationShader("wm", "quadOverlaps", "overlapsOld");
            addTargetParameter("gColorTex", "stylizationTarget");*/
            /*addTargetParameter("gColorTex", "colorTarget");*/
            /*addTargetParameter("gEdgeTex", "blurredEdgeTarget");
            addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
            addTargetParameter("gNormalsTex", "normalsTarget");
            addTargetParameter("gDepthTex", "linearDepth");
            appendOp({ "stylizationTarget" });*/
            /*appendOp({ "colorSpreadTarget" });*/
        }


        // HATCHING
        {
            opName = "[quad] substrate-based hatching";
            opShader = new MOperationShader("quadHatching", "hatchTest");
            addTargetParameter("gRenderTex", "stylizationTarget");
            addTargetParameter("gHatchCtrl", "pigmentCtrlTarget");
            addTargetParameter("gColorTex", "colorTarget");
            addTargetParameter("gSubstrateTex", "substrateTarget");
            addTargetParameter("gDiffuseTex", "widerDiffuseTarget");
            addTargetParameter("gSpecularTex", "specularTarget");
            //addParameter("gTestingValue", mFxParams.testingValue);
            appendOp({ "stylizationTarget" });


            /*opName = "[quad] uv hatching";
            opShader = new MOperationShader("quadHatching", "hatchUVsTest");
            addTargetParameter("gStylizationTex", "stylizationTarget");
            addTargetParameter("gColorTex", "colorTarget");
            addTargetParameter("gNormalsTex", "normalsTarget");
            addTargetParameter("gDiffuseTex", "widerDiffuseTarget");
            addTargetParameter("gSpecularTex", "specularTarget");
            appendOp({ "hatchingTarget" });*/
        }



        opName = "[quad] edge darkening";
        opShader = new MOperationShader("wm", "quadEdgeManipulation", "applyEdges");
        addTargetParameter("gRenderTex", "stylizationTarget");
        addTargetParameter("gEdgeLocationTex", "edgeUvDilatedTarget");
        addTargetParameter("gEdgeControlTex", "edgeCtrlTarget");
        addTargetParameter("gSubstrateTex", "substrateTarget");
        addParameter("gEdgeIntensity", mFxParams.edgeIntensityWM);
        addParameter("gEdgeWidth", mFxParams.edgeWidthWM);
        appendOp({ "stylizationTarget" });
    }
};
