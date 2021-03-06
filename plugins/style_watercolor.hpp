#pragma once
///////////////////////////////////////////////////////////////////////////////////
//                  _                     _            
//   __      ____ _| |_ ___ _ __ ___ ___ | | ___  _ __ 
//   \ \ /\ / / _` | __/ _ \ '__/ __/ _ \| |/ _ \| '__|
//    \ V  V / (_| | ||  __/ | | (_| (_) | | (_) | |   
//     \_/\_/ \__,_|\__\___|_|  \___\___/|_|\___/|_|   
//                                                     
//	 \brief Watercolor stylization pipeline
//	 Contains the watercolor stylization pipeline with all necessary targets and operations
//
//   Developed by: Santiago Montesdeoca
//
///////////////////////////////////////////////////////////////////////////////////
#include "mnpr_renderer.h"


namespace wc {
    void addTargets(MRenderTargetList &targetList) {
        // add style specific targets

        unsigned int tWidth = targetList[0]->width();
        unsigned int tHeight = targetList[0]->height();
        int MSAA = targetList[0]->multiSampleCount();
        unsigned arraySliceCount = 0;
        bool isCubeMap = false;
        MHWRender::MRasterFormat rgba8 = MHWRender::kR8G8B8A8_SNORM;
        MHWRender::MRasterFormat rgb8 = MHWRender::kR8G8B8X8;

        targetList.append(MHWRender::MRenderTargetDescription(
            "bleedingTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
    }


    void addOperations(MHWRender::MRenderOperationList &mOperations,
                       MRenderTargetList &mRenderTargets,
                       EngineSettings &mEngSettings,
                       FXParameters &mFxParams) {
        MString opName = "";


        opName = "[quad] pigment density";
        auto opShader = new MOperationShader("quadPigmentManipulation", "pigmentDensityWC");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("pigmentCtrlTarget"));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        auto quadOp = new QuadRender(opName,
                                     MHWRender::MClearOperation::kClearNone,
                                     mRenderTargets,
                                     *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] separable H";
        opShader = new MOperationShader("wc", "quadSeparable", "blurH");
        opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexClamp, MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        opShader->addTargetParameter("gEdgeControlTex", mRenderTargets.getTarget("edgeCtrlTarget"));
        opShader->addTargetParameter("gAbstractionControlTex", mRenderTargets.getTarget("abstractCtrlTarget"));
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
        opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexClamp, MHWRender::MSamplerState::kMinMagMipPoint);
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("bleedingTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTarget"));
        opShader->addTargetParameter("gDepthTex", mRenderTargets.getTarget("linearDepth"));
        opShader->addTargetParameter("gEdgeControlTex", mRenderTargets.getTarget("edgeCtrlTarget"));
        opShader->addTargetParameter("gAbstractionControlTex", mRenderTargets.getTarget("abstractCtrlTarget"));
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
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gBlendTex", mRenderTargets.getTarget("bleedingTarget"));
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] edge darkening";
        opShader = new MOperationShader("quadEdgeManipulation", "gradientEdgesWC");
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTarget"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("edgeCtrlTarget"));
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
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gEdgeTex", mRenderTargets.getTarget("edgeTarget"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("edgeCtrlTarget"));
        opShader->addTargetParameter("gBlendingTex", mRenderTargets.getTarget("bleedingTarget"));
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
        opShader->addTargetParameter("gColorTex", mRenderTargets.getTarget("stylizationTarget"));
        opShader->addTargetParameter("gSubstrateTex", mRenderTargets.getTarget("substrateTarget"));
        opShader->addTargetParameter("gControlTex", mRenderTargets.getTarget("pigmentCtrlTarget"));
        opShader->addParameter("gSubstrateColor", mEngSettings.substrateColor);
        opShader->addParameter("gPigmentDensity", mFxParams.pigmentDensity);
        opShader->addParameter("gDryBrushThreshold", mFxParams.dryBrushThreshold);
        quadOp = new QuadRender(opName,
                                MHWRender::MClearOperation::kClearNone,
                                mRenderTargets,
                                *opShader);
        mOperations.append(quadOp);
        mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });


        opName = "[quad] substrate distortion";
        opShader = new MOperationShader("quadSubstrate", "substrateDistortion");
        opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexMirror, MHWRender::MSamplerState::kMinMagMipPoint);
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
    }
};
