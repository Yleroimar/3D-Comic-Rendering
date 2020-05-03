#pragma once
///////////////////////////////////////////////////////////////////////////////////
//                  _            __  __                                                     _      
//   __      ____ _| |_ ___ _ __|  \/  | ___ _ __ ___   ___  _ __ _   _     _ __   ___   __| | ___ 
//   \ \ /\ / / _` | __/ _ \ '__| |\/| |/ _ \ '_ ` _ \ / _ \| '__| | | |   | '_ \ / _ \ / _` |/ _ \
//    \ V  V / (_| | ||  __/ |  | |  | |  __/ | | | | | (_) | |  | |_| |   | | | | (_) | (_| |  __/
//     \_/\_/ \__,_|\__\___|_|  |_|  |_|\___|_| |_| |_|\___/|_|   \__, |   |_| |_|\___/ \__,_|\___|
//                                                                |___/                            
//                                                                                
//	 \brief Water memory config node
//	 Contains the attributes and node computation for the water memory stylization
//
//   Developed by: Oliver Vainumäe
//
///////////////////////////////////////////////////////////////////////////////////
#include "mnpr_renderer.h"
#include "mnpr_nodes.h"
#include <maya/MRampAttribute.h>
#include <maya/MCurveAttribute.h>
//#include "node_watercolor.hpp"


// stylization attributes
static MObject aTestingValue;

// Hatching texture
static MObject aHatchingTex;

// Ramps
static MObject aSaturationRamp;

// Outline
static MObject aEdgeIntensityWM;
static MObject aEdgeWidthWM;
static MObject aEdgeThresholdWM;

// Overlap
static MObject aOverlapRangeWM;
static MObject aOverlapPickDistanceWM;
static MObject aOverlapFalloffWM;
static MObject aOverlapFalloffSpeedWM;
static MObject aOverlapDepthDifferenceWM;

// Discrete Surface Shading
static MObject aShadingTintR;
static MObject aShadingTintG;
static MObject aShadingTintB;
static MObject aShadingTint;
static MObject aShadingTintWeight;
static MObject aShadingDesaturationWeight;

static MObject aShadingThresholdHigh;
static MObject aShadingThresholdValueHigh;
static MObject aTransitionHighMid;

static MObject aShadingThresholdMid;
static MObject aShadingThresholdValueMid;
static MObject aTransitionMidLow;

static MObject aShadingIntensity;
static MObject aShadingIntensityHigh;
static MObject aShadingIntensityMid;
static MObject aShadingIntensityLow;



namespace wm {
    void initializeParameters(FXParameters *mFxParams,
                              EngineSettings *mEngSettings) {
        // adds parameters in the config node
        MStatus status;
        float renderScale = mEngSettings->renderScale[0];

        // MFn helpers
        MFnEnumAttribute eAttr;
        MFnTypedAttribute tAttr;
        MFnNumericAttribute nAttr;
        MFnStringData fnData;
        MRampAttribute rampAttr;

        // disable/enable engine settings
        mEngSettings->velocityPV[0] = 0.0;

        // Hatching Texture
        /*MObject oData = fnData.create(mFxParams->hatchingTexFilename);
        aHatchingTex = tAttr.create("hatchingTexture", "hatchingTexture", MFnData::kString, oData);
        tAttr.setStorable(true);
        ConfigNode::enableAttribute(aHatchingTex);*/

        // Testing Value
        {
            aTestingValue = nAttr.create(
                "testingValue", "testingValue",
                MFnNumericData::kFloat, mFxParams->testingValue[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(0.0);
            nAttr.setSoftMax(1.0);
            ConfigNode::enableAttribute(aTestingValue);
        }


        // Ramps
        {
            //aSaturationRamp = rampAttr.createCurveRamp("colorDesaturation", "colorDesaturation", &status);
            //aSaturationRamp = MCurveAttribute::createCurveAttr("colorDesaturation", "colorDesaturation", &status);
            //aSaturationRamp = rampAttr.createColorRamp("colorDesaturation", "colorDesaturation", &status);
            /*aSaturationRamp = MRampAttribute::createCurveRamp("colorDesaturation", "colorDesaturation", &status);*/
            //MAKE_INPUT(rampAttr);
            //ConfigNode::enableAttribute(aSaturationRamp);
        }


        // Outline
        {
            aEdgeThresholdWM = nAttr.create(
                "edgeThreshold", "edgeThreshold",
                MFnNumericData::kFloat, mFxParams->edgeThresholdWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMin(0.001);
            nAttr.setSoftMax(1.0);
            ConfigNode::enableAttribute(aEdgeThresholdWM);


            aEdgeWidthWM = nAttr.create(
                "edgeWidth", "edgeWidth",
                MFnNumericData::kFloat, mFxParams->edgeWidthWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.00);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aEdgeWidthWM);


            aEdgeIntensityWM = nAttr.create(
                "edgeIntensity", "edgeIntensity",
                MFnNumericData::kFloat, mFxParams->edgeIntensityWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.00);
            nAttr.setSoftMax(1.0);
            nAttr.setMax(10.0);
            ConfigNode::enableAttribute(aEdgeIntensityWM);
        }


        // Overlap
        {
            aOverlapRangeWM = nAttr.create(
                "overlapRange", "overlapRange",
                MFnNumericData::kFloat, mFxParams->overlapRangeWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aOverlapRangeWM);


            aOverlapPickDistanceWM = nAttr.create(
                "overlapPickDistance", "overlapPickDistance",
                MFnNumericData::kFloat, mFxParams->overlapPickDistanceWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(1.0);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aOverlapPickDistanceWM);


            aOverlapFalloffWM = nAttr.create(
                "overlapFalloff", "overlapFalloff",
                MFnNumericData::kFloat, mFxParams->overlapFalloffWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);
            ConfigNode::enableAttribute(aOverlapFalloffWM);


            aOverlapFalloffSpeedWM = nAttr.create(
                "overlapFalloffSpeed", "overlapFalloffSpeed",
                MFnNumericData::kFloat, mFxParams->overlapFalloffSpeedWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.001);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aOverlapFalloffSpeedWM);


            aOverlapDepthDifferenceWM = nAttr.create(
                "overlapDepthDifference", "overlapDepthDifference",
                MFnNumericData::kFloat, mFxParams->overlapDepthDifferenceWM[0],
                &status);
            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(0.0);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aOverlapDepthDifferenceWM);
        }


        // Discrete Surface Shading
        {
            aShadingTintR = nAttr.create(
                "shadingTintR", "shadingTintR",
                MFnNumericData::kFloat, mFxParams->shadingTintWM[0]);
            aShadingTintG = nAttr.create(
                "shadingTintG", "shadingTintG",
                MFnNumericData::kFloat, mFxParams->shadingTintWM[1]);
            aShadingTintB = nAttr.create(
                "shadingTintB", "shadingTintB",
                MFnNumericData::kFloat, mFxParams->shadingTintWM[2]);
            aShadingTint = nAttr.create(
                "shadingTint", "shadingTint",
                aShadingTintR, aShadingTintG, aShadingTintB);
            MAKE_INPUT(nAttr);
            nAttr.setUsedAsColor(true);
            ConfigNode::enableAttribute(aShadingTint);

            aShadingTintWeight = nAttr.create(
                "shadingTintWeight", "shadingTintWeight",
                MFnNumericData::kFloat,
                mFxParams->shadingTintWeightWM[0], &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(1.0);
            ConfigNode::enableAttribute(aShadingTintWeight);

            aShadingDesaturationWeight = nAttr.create(
                "desaturationWeight", "desaturationWeight",
                MFnNumericData::kFloat,
                mFxParams->shadingDesaturationWeightWM[0], &status);
            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(1.0);
            ConfigNode::enableAttribute(aShadingDesaturationWeight);


            // Shading thresholding
            aShadingThresholdValueHigh = nAttr.create(
                "shadingThresholdValueHigh", "shadingThresholdValueHigh",
                MFnNumericData::kFloat, mFxParams->shadingThresholdHigh[0]);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);

            aTransitionHighMid = nAttr.create(
                "transitionHighMid", "transitionHighMid",
                MFnNumericData::kFloat, mFxParams->transitionHighMid[0]);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);

            aShadingThresholdHigh = nAttr.create(
                "shadingThresholdHigh", "shadingThresholdHigh",
                aShadingThresholdValueHigh, aTransitionHighMid);
            MAKE_INPUT(nAttr);
            ConfigNode::enableAttribute(aShadingThresholdHigh);


            aShadingThresholdValueMid = nAttr.create(
                "surfaceThresholdValueMid", "surfaceThresholdValueMid",
                MFnNumericData::kFloat, mFxParams->shadingThresholdMid[0]);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);

            aTransitionMidLow = nAttr.create(
                "transitionMidLow", "transitionMidLow",
                MFnNumericData::kFloat, mFxParams->transitionMidLow[0]);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);

            aShadingThresholdMid = nAttr.create(
                "shadingThresholdMid", "shadingThresholdMid",
                aShadingThresholdValueMid, aTransitionMidLow);
            MAKE_INPUT(nAttr);
            ConfigNode::enableAttribute(aShadingThresholdMid);


            // Shading intensities
            aShadingIntensityHigh = nAttr.create(
                "shadingIntensityHigh", "shadingIntensityHigh",
                MFnNumericData::kFloat, mFxParams->shadingIntensityHigh[0]);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);

            aShadingIntensityMid = nAttr.create(
                "shadingIntensityMid", "shadingIntensityMid",
                MFnNumericData::kFloat, mFxParams->shadingIntensityMid[0]);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);

            aShadingIntensityLow = nAttr.create(
                "shadingIntensityLow", "shadingIntensityLow",
                MFnNumericData::kFloat, mFxParams->shadingIntensityLow[0]);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);

            aShadingIntensity = nAttr.create(
                "shadingIntensityLevels", "shadingIntensityLevels",
                aShadingIntensityLow, aShadingIntensityMid, aShadingIntensityHigh);
            MAKE_INPUT(nAttr);
            ConfigNode::enableAttribute(aShadingIntensity);
        }
    }


    void computeParameters(MNPROverride* mmnpr_renderer,
                           MDataBlock data,
                           FXParameters *mFxParams,
                           EngineSettings *mEngSettings) {
        MStatus status;

        /*
        MOperationShader* opShader;
        QuadRender* quadOp = (QuadRender*) MNPR->renderOperation("[quad] style-load");
        opShader = quadOp->getOperationShader();
        if (opShader) {
            // not exactly sure what is going on with the surfaceTex

            MString surfaceTex = data.inputValue(aHatchingTex, &status).asString();

            if (surfaceTex != mFxParams->hatchingTexFilename) {
                mFxParams->hatchingTexFilename = surfaceTex;
                opShader->textureParameters["gHatchingTex"]->
                    loadTexture(mFxParams->hatchingTexFilename);
            }

            opShader->textureParameters["gHatchingTex"]->setParams();
        }
        */

        auto asFloat = [&](MObject attribute) -> float {
            //return data.inputValue(attribute, &status).asFloat() * mEngSettings->renderScale[0];
            return data.inputValue(attribute, &status).asFloat();
        };

        auto asScaledFloat = [&](MObject attribute) -> float {
            return asFloat(attribute) * mEngSettings->renderScale[0];
        };

        mFxParams->testingValue[0] = asScaledFloat(aTestingValue);

        // Outline
        mFxParams->edgeThresholdWM[0] = asScaledFloat(aEdgeThresholdWM);
        mFxParams->edgeWidthWM[0] = asScaledFloat(aEdgeWidthWM);
        mFxParams->edgeIntensityWM[0] = asScaledFloat(aEdgeIntensityWM);

        // Overlap
        mFxParams->overlapRangeWM[0] = asScaledFloat(aOverlapRangeWM);
        mFxParams->overlapPickDistanceWM[0] = asScaledFloat(aOverlapPickDistanceWM);
        mFxParams->overlapFalloffWM[0] = asScaledFloat(aOverlapFalloffWM);
        mFxParams->overlapFalloffSpeedWM[0] = asScaledFloat(aOverlapFalloffSpeedWM);
        mFxParams->overlapDepthDifferenceWM[0] = asScaledFloat(aOverlapDepthDifferenceWM);

        // Discrete Surface Shading
        MFloatVector fvColor = data.inputValue(aShadingTint, &status).asFloatVector();
        mFxParams->shadingTintWM[0] = fvColor[0];
        mFxParams->shadingTintWM[1] = fvColor[1];
        mFxParams->shadingTintWM[2] = fvColor[2];
        mFxParams->shadingTintWeightWM[0] = asFloat(aShadingTintWeight);

        mFxParams->shadingDesaturationWeightWM[0] = asFloat(aShadingDesaturationWeight);

        mFxParams->shadingThresholdHigh[0] = asFloat(aShadingThresholdValueHigh);
        mFxParams->shadingThresholdMid[0] = asFloat(aShadingThresholdValueMid);

        mFxParams->transitionHighMid[0] = asFloat(aTransitionHighMid);
        mFxParams->transitionMidLow[0] = asFloat(aTransitionMidLow);

        mFxParams->shadingIntensityHigh[0] = asFloat(aShadingIntensityHigh);
        mFxParams->shadingIntensityMid[0] = asFloat(aShadingIntensityMid);
        mFxParams->shadingIntensityLow[0] = asFloat(aShadingIntensityLow);
    }
};