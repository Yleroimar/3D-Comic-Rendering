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
//   Developed by: Oliver Vainumäe
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

        /*
        targetList.append(MHWRender::MRenderTargetDescription(
            "bleedingTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
        */

        // maybe it'd be convenient to create another append method that would take
        // MRenderTargetDescription parameters as parameters and
        // would then delegate the object to the original append call? Shorter code...
        targetList.append(MHWRender::MRenderTargetDescription(
            "edgeTargetWM", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
    }


    void addOperations(MHWRender::MRenderOperationList &mOperations,
                       MRenderTargetList &mRenderTargets,
                       EngineSettings &mEngSettings,
                       FXParameters &mFxParams) {
        MString opName = "";
        MOperationShader* opShader;
        QuadRender* quadOp;

        opName = "[quad] cel shading surfaces";
        opShader = new MOperationShader("quadCelShader", "celSurfaces1");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("colorTarget"));
        //opShader->addTargetParameter("gColorTex", mRenderTargets.target(0));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        // opShader->addTargetParameter("gNormalTex", mRenderTargets.getTarget("normalsTarget"));
        opShader->addTargetParameter("gSpecularTex", mRenderTargets.getTarget("specularTarget"));
        opShader->addTargetParameter("gDiffuseTex", mRenderTargets.getTarget("diffuseTarget"));
        opShader->addParameter("surfaceThresholdHigh", mFxParams.surfaceThresholdHigh);
        opShader->addParameter("surfaceThresholdMid", mFxParams.surfaceThresholdMid);
        opShader->addParameter("surfaceHighIntensity", mFxParams.surfaceHighIntensity);
        opShader->addParameter("surfaceMidIntensity", mFxParams.surfaceMidIntensity);
        opShader->addParameter("surfaceLowIntensity", mFxParams.surfaceLowIntensity);
        opShader->addParameter("diffuseCoefficient", mFxParams.diffuseCoefficient);
        opShader->addParameter("specularCoefficient", mFxParams.specularCoefficient);
        opShader->addParameter("specularPower", mFxParams.specularPower);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] cel shading background";
        opShader = new MOperationShader("quadCelShader", "fixBackground");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


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


        opName = "[quad] display outlines";
        opShader = new MOperationShader("quadCelShader", "celOutlines1");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTargetWM"));
        opShader->addParameter("edgePower", mFxParams.edgePower);
        opShader->addParameter("edgeMultiplier", mFxParams.edgeMultiplier);
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
