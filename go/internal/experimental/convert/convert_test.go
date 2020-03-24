// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package convert

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"google.golang.org/protobuf/testing/protocmp"

	"go.chromium.org/chromiumos/config/go/api"
	"go.chromium.org/chromiumos/infra/proto/go/device"
)

func TestGenerateConfigBundle(t *testing.T) {
	cases := []struct {
		desc string
		in   *device.AllConfigs
		want *api.ConfigBundle
	}{
		{
			"Basic Conversion",
			&device.AllConfigs{
				Configs: []*device.Config{
					{
						Id: &device.ConfigId{
							PlatformId: &device.PlatformId{Value: "Platform1"},
							ModelId:    &device.ModelId{Value: "Model1"},
							VariantId:  &device.VariantId{Value: "1"},
						},
						FormFactor: device.Config_FORM_FACTOR_CONVERTIBLE,
					},
				},
			},
			&api.ConfigBundle{
				Designs: &api.DesignList{Value: []*api.Design{
					{
						Id:        &api.DesignId{Value: "Model1"},
						Name:      "Model1",
						ProgramId: &api.ProgramId{Value: "Platform1"},
						Configs: []*api.Design_Config{{
							Id: &api.DesignConfigId{Value: "Model1:1"},
							HardwareFeatures: &api.HardwareFeatures{
								FormFactor: &api.HardwareFeatures_FormFactor{
									FormFactor: api.HardwareFeatures_FormFactor_CONVERTIBLE,
								},
							},
						}},
					},
				}},
			},
		},
		{
			"Merge Designs",
			&device.AllConfigs{
				Configs: []*device.Config{
					{
						Id: &device.ConfigId{
							PlatformId: &device.PlatformId{Value: "Platform1"},
							ModelId:    &device.ModelId{Value: "Model1"},
							VariantId:  &device.VariantId{Value: "1"},
						},
					},
					{
						Id: &device.ConfigId{
							PlatformId: &device.PlatformId{Value: "Platform1"},
							ModelId:    &device.ModelId{Value: "Model1"},
							VariantId:  &device.VariantId{Value: "2"},
						},
					},
					{
						Id: &device.ConfigId{
							PlatformId: &device.PlatformId{Value: "Platform1"},
							ModelId:    &device.ModelId{Value: "Model2"},
							VariantId:  &device.VariantId{Value: "1"},
						},
					},
					{
						Id: &device.ConfigId{
							PlatformId: &device.PlatformId{Value: "Platform2"},
							ModelId:    &device.ModelId{Value: "Model3"},
							VariantId:  &device.VariantId{Value: "1"},
						},
					},
				},
			},
			&api.ConfigBundle{
				Designs: &api.DesignList{Value: []*api.Design{
					{
						Id:        &api.DesignId{Value: "Model1"},
						Name:      "Model1",
						ProgramId: &api.ProgramId{Value: "Platform1"},
						Configs: []*api.Design_Config{
							{
								Id: &api.DesignConfigId{Value: "Model1:1"},
							},
							{
								Id: &api.DesignConfigId{Value: "Model1:2"},
							},
						},
					},
					{
						Id:        &api.DesignId{Value: "Model2"},
						Name:      "Model2",
						ProgramId: &api.ProgramId{Value: "Platform1"},
						Configs: []*api.Design_Config{
							{
								Id: &api.DesignConfigId{Value: "Model2:1"},
							},
						},
					},
					{
						Id:        &api.DesignId{Value: "Model3"},
						Name:      "Model3",
						ProgramId: &api.ProgramId{Value: "Platform2"},
						Configs: []*api.Design_Config{
							{
								Id: &api.DesignConfigId{Value: "Model3:1"},
							},
						},
					},
				}},
			},
		},
	}

	for _, c := range cases {
		t.Run(c.desc, func(t *testing.T) {
			got, err := GenerateConfigBundle(c.in)
			if err != nil {
				t.Errorf("GenerateConfigBundle(%s) failed: %s", c.in, err)
			}
			if diff := cmp.Diff(c.want, got, protocmp.Transform(), protocmp.IgnoreEmptyMessages()); diff != "" {
				t.Errorf("GenerateConfigBundle(%s) returned diff (-want +got):\n%s", c.in, diff)
			}
		})
	}
}
