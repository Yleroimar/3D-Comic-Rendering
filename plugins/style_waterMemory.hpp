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

        MHWRender::MRasterFormat rgba8 = MHWRender::kR8G8B8A8_SNORM;
        MHWRender::MRasterFormat rgb8 = MHWRender::kR8G8B8X8;
        MHWRender::MRasterFormat rgba16f = MHWRender::kR16G16B16A16_FLOAT;
        MHWRender::MRasterFormat rgba32f = MHWRender::kR32G32B32A32_FLOAT;
        MHWRender::MRasterFormat defaultUserDepth = MHWRender::kR16G16B16A16_SNORM;

        MHWRender::MRasterFormat diffuseDepth = targetList.getDescription("diffuseTarget")->rasterFormat();
        MHWRender::MRasterFormat colorDepth = targetList.getDescription("colorTarget")->rasterFormat();

        /*
        targetList.append(MHWRender::MRenderTargetDescription(
            "bleedingTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
        */

        // maybe it'd be convenient to create another append method that would take
        // MRenderTargetDescription parameters as parameters and
        // would then delegate the object to the original append call? Shorter code...
        targetList.append(MHWRender::MRenderTargetDescription(
            "edgeTargetWM", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));

        targetList.append(MHWRender::MRenderTargetDescription(
            "hatchingTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));

        targetList.append(MHWRender::MRenderTargetDescription(
            "widerDiffuseTarget", tWidth, tHeight, 1, diffuseDepth, arraySliceCount, isCubeMap));

        targetList.append(MHWRender::MRenderTargetDescription(
            "uvTarget", tWidth, tHeight, 1, diffuseDepth, arraySliceCount, isCubeMap));

        targetList.append(MHWRender::MRenderTargetDescription(
            "colorSpreadTarget", tWidth, tHeight, 1, colorDepth, arraySliceCount, isCubeMap));
    }


    void addOperations(MHWRender::MRenderOperationList &mOperations,
                       MRenderTargetList &mRenderTargets,
                       EngineSettings &mEngSettings,
                       FXParameters &mFxParams) {
        MString opName = "";
        MOperationShader* opShader;
        QuadRender* quadOp;
        
        /*
        // enable once the shader is set up
        opName = "[quad] style-load";
        opShader = new MOperationShader("", "");
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "hatchingTarget" });
        */


        opName = "[quad] widen diffuse target";
        opShader = new MOperationShader("quadLighting", "includeNegatives");
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("diffuseTarget"));
        opShader->addParameter("positiveScale", mFxParams.testingValue);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "widerDiffuseTarget" });


        opName = "[quad] pigment application";
        opShader = new MOperationShader("quadPigmentApplication", "pigmentApplicationWM");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gSubstrateTex", mRenderTargets.getTarget("substrateTarget"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("pigmentCtrlTarget"));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        /*opShader->addParameter("gPigmentDensity", mFxParams.pigmentDensity);
        opShader->addParameter("gDryBrushThreshold", mFxParams.dryBrushThreshold);*/
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] color spread";
        opShader = new MOperationShader("wm", "quadColorSpread", "testTech");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("diffuseTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("depthTarget"));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "colorSpreadTarget" });


        opName = "[quad] cel shading surfaces";
        opShader = new MOperationShader("quadCelShader", "celSurfaces1");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.target(0));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        // opShader->addTargetParameter("gNormalTex", mRenderTargets.getTarget("normalsTarget"));
        opShader->addTargetParameter("gSpecularTex", mRenderTargets.getTarget("specularTarget"));
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("widerDiffuseTarget"));
        opShader->addParameter("gSurfaceThresholdHigh", mFxParams.surfaceThresholdHigh);
        opShader->addParameter("gSurfaceThresholdMid", mFxParams.surfaceThresholdMid);
        opShader->addParameter("gTransitionHighMid", mFxParams.transitionHighMid);
        opShader->addParameter("gTransitionMidLow", mFxParams.transitionMidLow);
        opShader->addParameter("gSurfaceHighIntensity", mFxParams.surfaceHighIntensity);
        opShader->addParameter("gSurfaceMidIntensity", mFxParams.surfaceMidIntensity);
        opShader->addParameter("gSurfaceLowIntensity", mFxParams.surfaceLowIntensity);
        opShader->addParameter("gDiffuseCoefficient", mFxParams.diffuseCoefficient);
        opShader->addParameter("gSpecularCoefficient", mFxParams.specularCoefficient);
        opShader->addParameter("gSpecularPower", mFxParams.specularPower);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        /*
        */
        opName = "[quad] substrate-based hatching";
        opShader = new MOperationShader("quadHatching", "hatchTest");
        opShader->addTargetParameter("gStylizationTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gHatchCtrl", mRenderTargets.getTarget("pigmentCtrlTarget"));
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        opShader->addTargetParameter("gSubstrateTex", mRenderTargets.getTarget("substrateTarget"));
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("widerDiffuseTarget"));
        opShader->addTargetParameter("gSpecularTex", mRenderTargets.getTarget("specularTarget"));
        //opShader->addParameter("gTestingValue", mFxParams.testingValue);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        /*mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });*/


        // edge detection
        opName = "[quad] edge detection (WM)";
        //opShader = new MOperationShader("quadEdgeDetection", "sobelRGBDEdgeDetection");
        opShader = new MOperationShader("quadEdgeDetection", "dogRGBDEdgeDetection");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "edgeTargetWM" });


        /*
        */
        opName = "[quad] uv hatching";
        opShader = new MOperationShader("quadHatching", "hatchUVsTest");
        opShader->addTargetParameter("gStylizationTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        opShader->addTargetParameter("gUVsTex", mRenderTargets.getTarget("normalsTarget"));
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("widerDiffuseTarget"));
        opShader->addTargetParameter("gSpecularTex", mRenderTargets.getTarget("specularTarget"));
        //opShader->addParameter("gTestingValue", mFxParams.testingValue);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "hatchingTarget" });
        /*mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });*/


        opName = "[quad] display outlines";
        opShader = new MOperationShader("quadCelShader", "celOutlines1");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTargetWM"));
        /*opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTargetWM"));*/
        opShader->addParameter("gEdgePower", mFxParams.edgePower);
        opShader->addParameter("gEdgeMultiplier", mFxParams.edgeMultiplier);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });

        


        /*
        opName = "[quad] move";
        opShader = new MOperationShader("quadCelShader", "display");
        //opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.target(0));
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("edgeTargetWM"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("depthTarget"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("substrateTarget"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("outputTarget"));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        */


        /*
        opName = "[quad] edge detection";
        opShader = new MOperationShader("quadEdgeDetection", "dogRGBDEdgeDetection");
        opShader->addSamplerState("gSampler",
                                  MHWRender::MSamplerState::kTexClamp,
                                  MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gDepthTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
        quadOp = new QuadRender(opName,
                                     MHWRender::MClearOperation::kClearNone,
                                     mRenderTargets,
                                     *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "edgeTarget" });
        */

        /*
        opName = "[quad] separable H";
        opShader = new MOperationShader("wc", "quadSeparable", "blurH");
        opShader->addSamplerState("gSampler",
                                  MHWRender::MSamplerState::kTexClamp,
                                  MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter("gEdgeTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter("gDepthTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
        opShader->addTargetParameter("gEdgeControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addTargetParameter("gAbstractionControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("abstractCtrlTarget")));
        opShader->addParameter("gRenderScale", mEngSettings.renderScale);
        opShader->addParameter("gBleedingThreshold", mFxParams.bleedingThreshold);
        opShader->addParameter("gEdgeDarkeningKernel", mFxParams.edgeDarkeningWidth);
        opShader->addParameter("gGapsOverlapsKernel", mFxParams.gapsOverlapsWidth);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "bleedingTarget", "edgeTarget" });


        opName = "[quad] separable V";
        opShader = new MOperationShader("wc", "quadSeparable", "blurV");
        opShader->addSamplerState("gSampler",
                                  MHWRender::MSamplerState::kTexClamp,
                                  MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("bleedingTarget")));
        opShader->addTargetParameter("gEdgeTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter("gDepthTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
        opShader->addTargetParameter("gEdgeControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addTargetParameter("gAbstractionControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("abstractCtrlTarget")));
        opShader->addParameter("gRenderScale", mEngSettings.renderScale);
        opShader->addParameter("gBleedingThreshold", mFxParams.bleedingThreshold);
        opShader->addParameter("gEdgeDarkeningKernel", mFxParams.edgeDarkeningWidth);
        opShader->addParameter("gGapsOverlapsKernel", mFxParams.gapsOverlapsWidth);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "bleedingTarget", "edgeTarget" });


        opName = "[quad] bleeding";
        opShader = new MOperationShader("quadBlend", "blendFromAlpha");
        opShader->addTargetParameter("gColorTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter("gBlendTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("bleedingTarget")));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] edge darkening";
        opShader = new MOperationShader("quadEdgeManipulation", "strongEdgesWM");
        opShader->addTargetParameter("gColorTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter("gEdgeTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter("gControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        opShader->addParameter("gEdgeIntensity", mFxParams.edgeDarkeningIntensity);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        */

        /*
        opName = "[quad] edge darkening";
        opShader = new MOperationShader("quadEdgeManipulation", "testOutputWM");
        opShader->addTargetParameter("gColorTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        */

        /*
        opName = "[quad] pigment density";
        opShader = new MOperationShader("quadPigmentManipulation", "pigmentDensityWC");

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gControlTex", mRenderTargets.target(mRenderTargets.indexOf("pigmentCtrlTarget")));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);

        quadOp = new QuadRender(opName,
                                     MHWRender::MClearOperation::kClearNone,
                                     mRenderTargets,
                                     *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] separable H";
        opShader = new MOperationShader("wc", "quadSeparable", "blurH");

        opShader->addSamplerState("gSampler",
                                  MHWRender::MSamplerState::kTexClamp,
                                  MHWRender::MSamplerState::kMinMagMipPoint);

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gEdgeTex", mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter(
            "gDepthTex", mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
        opShader->addTargetParameter(
            "gEdgeControlTex", mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addTargetParameter(
            "gAbstractionControlTex", mRenderTargets.target(mRenderTargets.indexOf("abstractCtrlTarget")));
        opShader->addParameter("gRenderScale", mEngSettings.renderScale);
        opShader->addParameter("gBleedingThreshold", mFxParams.bleedingThreshold);
        opShader->addParameter("gEdgeDarkeningKernel", mFxParams.edgeDarkeningWidth);
        opShader->addParameter("gGapsOverlapsKernel", mFxParams.gapsOverlapsWidth);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "bleedingTarget", "edgeTarget" });


        opName = "[quad] separable V";
        opShader = new MOperationShader("wc", "quadSeparable", "blurV");

        opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexClamp,
                                  MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex", mRenderTargets.target(mRenderTargets.indexOf("bleedingTarget")));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
        opShader->addTargetParameter("gEdgeControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addTargetParameter("gAbstractionControlTex",
                                     mRenderTargets.target(mRenderTargets.indexOf("abstractCtrlTarget")));
        opShader->addParameter("gRenderScale", mEngSettings.renderScale);
        opShader->addParameter("gBleedingThreshold", mFxParams.bleedingThreshold);
        opShader->addParameter("gEdgeDarkeningKernel", mFxParams.edgeDarkeningWidth);
        opShader->addParameter("gGapsOverlapsKernel", mFxParams.gapsOverlapsWidth);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "bleedingTarget", "edgeTarget" });


        opName = "[quad] bleeding";
        opShader = new MOperationShader("quadBlend", "blendFromAlpha");

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gBlendTex", mRenderTargets.target(mRenderTargets.indexOf("bleedingTarget")));

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] edge darkening";
        opShader = new MOperationShader("quadEdgeManipulation", "gradientEdgesWC");

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gEdgeTex", mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter(
            "gControlTex", mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        opShader->addParameter("gEdgeIntensity", mFxParams.edgeDarkeningIntensity);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] gaps and overlaps";
        opShader = new MOperationShader("quadGapsOverlaps", "gapsOverlaps");

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gEdgeTex", mRenderTargets.target(mRenderTargets.indexOf("edgeTarget")));
        opShader->addTargetParameter(
            "gControlTex", mRenderTargets.target(mRenderTargets.indexOf("edgeCtrlTarget")));
        opShader->addTargetParameter(
            "gBlendingTex", mRenderTargets.target(mRenderTargets.indexOf("bleedingTarget")));
        opShader->addParameter("gGORadius", mFxParams.gapsOverlapsWidth);
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] pigment application";
        opShader = new MOperationShader("quadPigmentApplication", "pigmentApplicationWC");

        opShader->addTargetParameter(
            "gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
        opShader->addTargetParameter(
            "gSubstrateTex", mRenderTargets.target(mRenderTargets.indexOf("substrateTarget")));
        opShader->addTargetParameter(
            "gControlTex", mRenderTargets.target(mRenderTargets.indexOf("pigmentCtrlTarget")));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        opShader->addParameter("gPigmentDensity", mFxParams.pigmentDensity);
        opShader->addParameter("gDryBrushThreshold", mFxParams.dryBrushThreshold);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        */

        /*
        opName = "[quad] substrate distortion";
        opShader = new MOperationShader("quadSubstrate", "substrateDistortion");

        opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexMirror,
                                  MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("substrateCtrlTarget"));
        opShader->addTargetParameter("gSubstrateTex", mRenderTargets.getTarget("substrateTarget"));
        opShader->addParameter("gSubstrateDistortion", mEngSettings.substrateDistortion);

        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
        */
    }
};
