// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package constraints

import (
	"testing"

	"go.chromium.org/chromiumos/config/go/src/config/api"
)

func TestCheckProgramIds(t *testing.T) {
	programConfig := &api.ConfigBundle{
		Programs: &api.ProgramList{
			Value: []*api.Program{
				&api.Program{Id: &api.ProgramId{Value: "TestProgram"}},
			},
		},
	}

	projectConfig := &api.ConfigBundle{
		Designs: &api.DesignList{
			Value: []*api.Design{
				&api.Design{
					Id:        &api.DesignId{Value: "TestDesign1"},
					ProgramId: &api.ProgramId{Value: "TestProgram"},
				},
				&api.Design{
					Id:        &api.DesignId{Value: "TestDesign2"},
					ProgramId: &api.ProgramId{Value: "TestProgram"},
				},
			},
		},
	}

	if err := CheckProgramIds(programConfig, projectConfig); err != nil {
		t.Errorf("CheckProgramIds returned error %v, want nil", err)
	}
}

func TestCheckProgramIdsErrors(t *testing.T) {
	programConfig := &api.ConfigBundle{
		Programs: &api.ProgramList{
			Value: []*api.Program{
				&api.Program{Id: &api.ProgramId{Value: "TestProgram"}},
			},
		},
	}

	projectConfig := &api.ConfigBundle{
		Designs: &api.DesignList{
			Value: []*api.Design{
				&api.Design{
					Id:        &api.DesignId{Value: "TestDesign1"},
					ProgramId: &api.ProgramId{Value: "OtherTestProgram"},
				},
				&api.Design{
					Id:        &api.DesignId{Value: "TestDesign2"},
					ProgramId: &api.ProgramId{Value: "TestProgram"},
				},
			},
		},
	}

	if err := CheckProgramIds(programConfig, projectConfig); err == nil {
		t.Error("CheckProgramIds returned nil, want error")
	}
}
