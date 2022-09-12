#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See generated commit message for details on script.

project=$1
name=shared-hw-arc-features

changes=$(git status | grep "sw_build_config")
if [[ -n "${changes}" ]]; then
  echo "For ${project}, uploading: ${changes}"
  git add -u
  git commit -m"
${project}: Regenerating ARC hardware_features*

ARC hardware features can now be shared across the same design project.

This regenerates the config to leverage this sharing option.

BUG=None
TEST=cq

Cq-Depend: chromium:2194303
"

  repo upload --no-verify --ht="${name}"
fi
