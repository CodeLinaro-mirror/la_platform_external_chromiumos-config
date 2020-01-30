// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package constraints

import (
	"fmt"

	"go.chromium.org/chromiumos/config/go/src/config/api"
)

// CheckProgramIds checks that all designs in projectConfig have the same
// ProgramId as programConfig.
func CheckProgramIds(programConfig *api.ConfigBundle, projectConfig *api.ConfigBundle) error {
	programID := programConfig.Programs.Value[0].Id
	for _, design := range projectConfig.Designs.Value {
		if programID.Value != design.ProgramId.Value {
			return fmt.Errorf(
				"Design %v must have programId %v. Actual: %v",
				design.Id.Value, programID.Value, design.ProgramId.Value,
			)
		}
	}

	return nil
}
