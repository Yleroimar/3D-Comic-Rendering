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
//#include "node_watercolor.hpp"


// stylization attributes
static MObject aTestingValue;

// Cel Outline
static MObject aEdgePower;
static MObject aEdgeMultiplier;

// Cel Surface
static MObject aSurfaceThresholdHigh;
static MObject aSurfaceThresholdMid;
static MObject aTransitionHighMid;
static MObject aTransitionMidLow;
static MObject aSurfaceHighIntensity;
static MObject aSurfaceMidIntensity;
static MObject aSurfaceLowIntensity;
static MObject aDiffuseCoefficient;
static MObject aSpecularCoefficient;
static MObject aSpecularPower;


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

        // disable/enable engine settings
        mEngSettings->velocityPV[0] = 0.0;
        
        aTestingValue = nAttr.create("testingValue", "testingValue",
                                  MFnNumericData::kFloat,
                                  mFxParams->testingValue[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setSoftMin(0.0);
        nAttr.setSoftMax(1.0);
        ConfigNode::enableAttribute(aTestingValue);

        // Cel Outline
        aEdgePower = nAttr.create("edgePower", "edgePower",
                                  MFnNumericData::kFloat,
                                  mFxParams->edgePower[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.01);
        nAttr.setSoftMax(10.0);
        ConfigNode::enableAttribute(aEdgePower);

        aEdgeMultiplier = nAttr.create("edgeMultiplier", "edgeMultiplier",
                                       MFnNumericData::kFloat,
                                       mFxParams->edgeMultiplier[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setSoftMin(0.0);
        nAttr.setSoftMax(10.0);
        ConfigNode::enableAttribute(aEdgeMultiplier);


        // Cel Surface
        aSurfaceThresholdHigh = nAttr.create("surfaceThresholdHigh", "surfaceThresholdHigh",
                                             MFnNumericData::kFloat,
                                             mFxParams->surfaceThresholdHigh[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setMax(1.0);
        ConfigNode::enableAttribute(aSurfaceThresholdHigh);

        aSurfaceThresholdMid = nAttr.create("surfaceThresholdMid", "surfaceThresholdMid",
                                            MFnNumericData::kFloat,
                                            mFxParams->surfaceThresholdMid[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setMax(1.0);
        ConfigNode::enableAttribute(aSurfaceThresholdMid);


        aTransitionHighMid = nAttr.create("transitionHighMid", "transitionHighMid",
                                          MFnNumericData::kFloat,
                                          mFxParams->transitionHighMid[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setMax(1.0);
        ConfigNode::enableAttribute(aTransitionHighMid);

        aTransitionMidLow = nAttr.create("transitionMidLow", "transitionMidLow",
                                         MFnNumericData::kFloat,
                                         mFxParams->transitionMidLow[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setMax(1.0);
        ConfigNode::enableAttribute(aTransitionMidLow);

        aSurfaceHighIntensity = nAttr.create("surfaceHighIntensity", "surfaceHighIntensity",
                                             MFnNumericData::kFloat,
                                             mFxParams->surfaceHighIntensity[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setSoftMax(2.0);
        ConfigNode::enableAttribute(aSurfaceHighIntensity);

        aSurfaceMidIntensity = nAttr.create("surfaceMidIntensity", "surfaceMidIntensity",
                                            MFnNumericData::kFloat,
                                            mFxParams->surfaceMidIntensity[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setSoftMax(2.0);
        ConfigNode::enableAttribute(aSurfaceMidIntensity);

        aSurfaceLowIntensity = nAttr.create("surfaceLowIntensity", "surfaceLowIntensity",
                                            MFnNumericData::kFloat,
                                            mFxParams->surfaceLowIntensity[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.0);
        nAttr.setSoftMax(2.0);
        ConfigNode::enableAttribute(aSurfaceLowIntensity);

        aDiffuseCoefficient = nAttr.create("diffuseCoefficient", "diffuseCoefficient",
                                           MFnNumericData::kFloat,
                                           mFxParams->diffuseCoefficient[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setSoftMin(0.0);
        nAttr.setSoftMax(1.0);
        ConfigNode::enableAttribute(aDiffuseCoefficient);

        aSpecularCoefficient = nAttr.create("specularCoefficient", "specularCoefficient",
                                            MFnNumericData::kFloat,
                                            mFxParams->specularCoefficient[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setSoftMin(0.0);
        nAttr.setSoftMax(2.0);
        ConfigNode::enableAttribute(aSpecularCoefficient);

        aSpecularPower = nAttr.create("specularPower", "specularPower",
                                      MFnNumericData::kFloat,
                                      mFxParams->specularPower[0], &status);
        MAKE_INPUT(nAttr);
        nAttr.setMin(0.01);
        nAttr.setSoftMax(10.0);
        ConfigNode::enableAttribute(aSpecularPower);
    }


    void computeParameters(MNPROverride* mmnpr_renderer,
                           MDataBlock data,
                           FXParameters *mFxParams,
                           EngineSettings *mEngSettings) {
        MStatus status;

        auto asFloat = [&](MObject attribute) -> float {
            return data.inputValue(attribute, &status).asFloat() * mEngSettings->renderScale[0];
        };

        mFxParams->testingValue[0] = asFloat(aTestingValue);

        // Cel Outline
        mFxParams->edgePower[0] = asFloat(aEdgePower);
        mFxParams->edgeMultiplier[0] = asFloat(aEdgeMultiplier);

        // Cel Surface
        mFxParams->surfaceThresholdHigh[0] = asFloat(aSurfaceThresholdHigh);
        mFxParams->surfaceThresholdMid[0] = asFloat(aSurfaceThresholdMid);

        mFxParams->transitionHighMid[0] = asFloat(aTransitionHighMid);
        mFxParams->transitionMidLow[0] = asFloat(aTransitionMidLow);

        mFxParams->surfaceHighIntensity[0] = asFloat(aSurfaceHighIntensity);
        mFxParams->surfaceMidIntensity[0] = asFloat(aSurfaceMidIntensity);
        mFxParams->surfaceLowIntensity[0] = asFloat(aSurfaceLowIntensity);

        mFxParams->diffuseCoefficient[0] = asFloat(aDiffuseCoefficient);
        mFxParams->specularCoefficient[0] = asFloat(aSpecularCoefficient);
        mFxParams->specularPower[0] = asFloat(aSpecularPower);
        /*
        */

        /*
        // Cel Outline
        mFxParams->edgePower[0] =
            data.inputValue(aEdgePower, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->edgeMultiplier[0] =
            data.inputValue(aEdgeMultiplier, &status).asFloat() * mEngSettings->renderScale[0];

        // Cel Surface
        mFxParams->surfaceThresholdHigh[0] =
            data.inputValue(aSurfaceThresholdHigh, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->surfaceThresholdMid[0] =
            data.inputValue(aSurfaceThresholdMid, &status).asFloat() * mEngSettings->renderScale[0];

        mFxParams->transitionHighMid[0] =
            data.inputValue(aTransitionHighMid, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->transitionMidLow[0] =
            data.inputValue(aTransitionMidLow, &status).asFloat() * mEngSettings->renderScale[0];

        mFxParams->surfaceHighIntensity[0] =
            data.inputValue(aSurfaceHighIntensity, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->surfaceMidIntensity[0] =
            data.inputValue(aSurfaceMidIntensity, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->surfaceLowIntensity[0] =
            data.inputValue(aSurfaceLowIntensity, &status).asFloat() * mEngSettings->renderScale[0];

        mFxParams->diffuseCoefficient[0] =
            data.inputValue(aDiffuseCoefficient, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->specularCoefficient[0] =
            data.inputValue(aSpecularCoefficient, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->specularPower[0] =
            data.inputValue(aSpecularPower, &status).asFloat() * mEngSettings->renderScale[0];
        */
    }
};