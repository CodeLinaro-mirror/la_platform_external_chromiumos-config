// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package convert

import (
	"fmt"
	"strings"

	"go.chromium.org/chromiumos/config/go/api"
	"go.chromium.org/chromiumos/infra/proto/go/device"
)

// GenerateConfigBundle converts allConfigs into a ConfigBundle
func GenerateConfigBundle(allConfigs *device.AllConfigs) (*api.ConfigBundle, error) {
	// AllConfigs is a flat list of configs, whereas ConfigBundle has
	// Designs, which have a list of Design_Configs. Each config in AllConfigs
	// produces a Design_Config, and a map from DesignId -> Design is used to
	// group the Design_Configs.
	designMap := make(map[string]*api.Design)
	for _, config := range allConfigs.Configs {
		// Generate a DesignId for config. If this DesignId is already in
		// designMap, use the corresponding Design; otherwise, insert a new
		// Design into designMap.
		designKey := generateBasicDesign(config.GetId()).GetId().GetValue()
		design, prs := designMap[designKey]
		if !prs {
			design = generateBasicDesign(config.GetId())
			designMap[designKey] = design
		}

		designConfig, err := generateDesignConfig(config)
		if err != nil {
			return nil, err
		}
		design.Configs = append(design.Configs, designConfig)
	}

	// Collect all the values in designMap and use them to create a
	// ConfigBundle.
	designs := make([]*api.Design, 0, len(designMap))

	for _, v := range designMap {
		designs = append(designs, v)
	}

	return &api.ConfigBundle{Designs: &api.DesignList{Value: designs}}, nil
}

// generateBasicDesign returns a Design with no Design_Configs.
//
// ModelId maps to DesignId and PlatformId maps to ProgramId.
func generateBasicDesign(id *device.ConfigId) *api.Design {
	return &api.Design{
		Id:        &api.DesignId{Value: id.GetModelId().GetValue()},
		Name:      id.GetModelId().GetValue(),
		ProgramId: &api.ProgramId{Value: id.GetPlatformId().GetValue()},
	}
}

func generateDesignConfig(config *device.Config) (*api.Design_Config, error) {
	id := config.GetId()

	hardwareFeatures, err := generateHardwareFeatures(config)
	if err != nil {
		return nil, err
	}

	return &api.Design_Config{
		// ModelId + VariantId maps to DesignConfigId
		Id: &api.DesignConfigId{Value: fmt.Sprintf(
			"%s:%s", id.GetModelId().GetValue(), id.GetVariantId().GetValue(),
		)},
		HardwareFeatures: hardwareFeatures,
	}, nil
}

func generateFormFactor(formFactor device.Config_FormFactor) (*api.HardwareFeatures_FormFactor, error) {
	// Config_FormFactor should always map 1:1 with HardwareFeatures_FormFactor,
	// with only the prefixes differing. For example:
	// Config_FORM_FACTOR_CLAMSHELL -> HardwareFeatures_FormFactor_CLAMSHELL.
	//
	// Do this translation as:
	// Config_FormFactor -> string name -> string replacement
	// -> HardwareFeatures_FormFactor.
	if formFactor == device.Config_FORM_FACTOR_UNSPECIFIED {
		return nil, nil
	}

	formFactorName := strings.TrimPrefix(formFactor.String(), "FORM_FACTOR_")
	hardwareFeaturesValue, prs := api.HardwareFeatures_FormFactor_FormFactorType_value[formFactorName]
	if !prs {
		return nil, fmt.Errorf("No HardwareFeatures_FormFactor found for Config_FormFactor %v", formFactor)
	}

	return &api.HardwareFeatures_FormFactor{
		FormFactor: api.HardwareFeatures_FormFactor_FormFactorType(hardwareFeaturesValue),
	}, nil
}

func generateHardwareFeatures(config *device.Config) (*api.HardwareFeatures, error) {
	hwFeaturesOut := &api.HardwareFeatures{}

	formFactor, err := generateFormFactor(config.GetFormFactor())
	if err != nil {
		return nil, err
	}
	hwFeaturesOut.FormFactor = formFactor

	return hwFeaturesOut, nil
}
