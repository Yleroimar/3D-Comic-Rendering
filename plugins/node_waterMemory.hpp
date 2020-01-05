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
// Cel Outline
static MObject aEdgePower;
static MObject aEdgeMultiplier;

// Cel Surface
static MObject aSurfaceThresholdHigh;
static MObject aSurfaceThresholdMid;
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

        // Cel Outline
        {
            aEdgePower = nAttr.create("edgePower", "edgePower",
                                      MFnNumericData::kFloat,
                                      mFxParams->edgePower[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.01);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aEdgePower);
        }

        {
            aEdgeMultiplier = nAttr.create("edgeMultiplier", "edgeMultiplier",
                                           MFnNumericData::kFloat,
                                           mFxParams->edgeMultiplier[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(0.0);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aEdgeMultiplier);
        }

        // Cel Surface
        {
            aSurfaceThresholdHigh = nAttr.create("surfaceThresholdHigh", "surfaceThresholdHigh",
                                      MFnNumericData::kFloat,
                                      mFxParams->surfaceThresholdHigh[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);
            ConfigNode::enableAttribute(aSurfaceThresholdHigh);
        }
        
        {
            aSurfaceThresholdMid = nAttr.create("surfaceThresholdMid", "surfaceThresholdMid",
                                      MFnNumericData::kFloat,
                                      mFxParams->surfaceThresholdMid[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setMax(1.0);
            ConfigNode::enableAttribute(aSurfaceThresholdMid);
        }
        
        {
            aSurfaceHighIntensity = nAttr.create("surfaceHighIntensity", "surfaceHighIntensity",
                                      MFnNumericData::kFloat,
                                      mFxParams->surfaceHighIntensity[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);
            ConfigNode::enableAttribute(aSurfaceHighIntensity);
        }
        
        {
            aSurfaceMidIntensity = nAttr.create("surfaceMidIntensity", "surfaceMidIntensity",
                                      MFnNumericData::kFloat,
                                      mFxParams->surfaceMidIntensity[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);
            ConfigNode::enableAttribute(aSurfaceMidIntensity);
        }
        
        {
            aSurfaceLowIntensity = nAttr.create("surfaceLowIntensity", "surfaceLowIntensity",
                                      MFnNumericData::kFloat,
                                      mFxParams->surfaceLowIntensity[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.0);
            nAttr.setSoftMax(2.0);
            ConfigNode::enableAttribute(aSurfaceLowIntensity);
        }
        
        {
            aDiffuseCoefficient = nAttr.create("diffuseCoefficient", "diffuseCoefficient",
                                      MFnNumericData::kFloat,
                                      mFxParams->diffuseCoefficient[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(0.0);
            nAttr.setSoftMax(1.0);
            ConfigNode::enableAttribute(aDiffuseCoefficient);
        }
        
        {
            aSpecularCoefficient = nAttr.create("specularCoefficient", "specularCoefficient",
                                      MFnNumericData::kFloat,
                                      mFxParams->specularCoefficient[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setSoftMin(0.0);
            nAttr.setSoftMax(2.0);
            ConfigNode::enableAttribute(aSpecularCoefficient);
        }
        
        {
            aSpecularPower = nAttr.create("specularPower", "specularPower",
                                      MFnNumericData::kFloat,
                                      mFxParams->specularPower[0], &status);

            MAKE_INPUT(nAttr);
            nAttr.setMin(0.01);
            nAttr.setSoftMax(10.0);
            ConfigNode::enableAttribute(aSpecularPower);
        }
    }


    void computeParameters(MNPROverride* mmnpr_renderer,
                           MDataBlock data,
                           FXParameters *mFxParams,
                           EngineSettings *mEngSettings) {
        MStatus status;

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

        /*
        // BLEEDING
        mFxParams->bleedingThreshold[0] = data.inputValue(aBleedingThreshold, &status).asFloat();
        int bleedingRadius =
            (int) (data.inputValue(aBleedingRadius, &status).asShort() * mEngSettings->renderScale[0]);

        if ((mFxParams->bleedingRadius[0] != bleedingRadius) || (!mEngSettings->initialized)) {
            mFxParams->bleedingRadius[0] = (float) bleedingRadius;

            float sigma = (float) bleedingRadius * 2.0f;

            // calculate new bleeding kernel
            float normDivisor = 0;

            for (int x = -bleedingRadius; x <= bleedingRadius; x++) {
                float weight = (float) (0.15915*exp(-0.5*x*x / (sigma*sigma)) / sigma);

                //float weight = (float)(pow((6.283185*sigma*sigma), -0.5) * exp((-0.5*x*x) / (sigma*sigma)));
                normDivisor += weight;
                mFxParams->bleedingWeigths[x + bleedingRadius] = weight;
            }

            // normalize weights
            for (int x = -bleedingRadius; x <= bleedingRadius; x++) {
                mFxParams->bleedingWeigths[x + bleedingRadius] /= normDivisor;
            }

            // send weights to shaders
            MOperationShader* opShader;
            QuadRender* quadOp = (QuadRender*) mmnpr_renderer->renderOperation("[quad] separable H");
            opShader = quadOp->getOperationShader();
            MHWRender::MShaderInstance* shaderInstance = opShader->shaderInstance();

            if (shaderInstance) {
                shaderInstance->setParameter("gBleedingRadius", &mFxParams->bleedingRadius[0]);
                shaderInstance->setArrayParameter(
                    "gGaussianWeights", &mFxParams->bleedingWeigths[0], (bleedingRadius * 2) + 1);
            }

            quadOp = (QuadRender*) mmnpr_renderer->renderOperation("[quad] separable V");
            opShader = quadOp->getOperationShader();
            shaderInstance = opShader->shaderInstance();

            if (shaderInstance) {
                shaderInstance->setParameter("gBleedingRadius", &mFxParams->bleedingRadius[0]);
                shaderInstance->setArrayParameter(
                    "gGaussianWeights", &mFxParams->bleedingWeigths[0], (bleedingRadius * 2) + 1);
            }
        }
        */
        /*
        // EDGE DARKENING
        mFxParams->edgeDarkeningIntensity[0] =
            data.inputValue(aEdgeDarkeningIntensity, &status).asFloat() * mEngSettings->renderScale[0];
        mFxParams->edgeDarkeningWidth[0] =
            roundf(data.inputValue(aEdgeDarkeningWidth, &status).asShort() * mEngSettings->renderScale[0]);
        // GAPS & OVERLAPS
        mFxParams->gapsOverlapsWidth[0] =
            roundf(data.inputValue(aGapsOverlapsWidth, &status).asShort() * mEngSettings->renderScale[0]);

        // PIGMENT EFFECTS
        mFxParams->pigmentDensity[0] = data.inputValue(aPigmentDensity, &status).asFloat();
        float drybrushThresholdInput = data.inputValue(aDryBrushThreshold, &status).asFloat();
        mFxParams->dryBrushThreshold[0] = (float)20.0 - drybrushThresholdInput;
        */
    }
};