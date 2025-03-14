#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Restructures to allow shared arc features config across projects.

project=$1

./config/bin/gen_config config.star

changes=$(git status | grep "sw_build_config")
if [[ -n "${changes}" ]]; then
  git rm sw_build_config/platform/chromeos-config/generated/arc/hardware_features_*_*.xml
  ./config/bin/gen_config config.star
  git add sw_build_config/platform/chromeos-config/generated/arc/hardware_features*
  git add -u
fi
