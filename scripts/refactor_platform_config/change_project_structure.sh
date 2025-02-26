#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Restructures the generated platform config based on the portage needs.

project=$1

if [ -f "sw_build_config/platform/chromeos-config/generated/project-config.json" ]; then
  echo "sw_build_config already exists for ${project}"
  exit 0
fi
if [ ! -f "generated/project/project-config.json" ]; then
  echo "project-config.json doesn't exist for ${project}"
  exit 0
fi
mkdir -p sw_build_config/platform/chromeos-config/generated/arc
mkdir -p sw_build_config/platform/chromeos-config/generated/bluetooth
git mv generated/project/project-config.json sw_build_config/platform/chromeos-config/generated
./config/bin/gen_config config.star
git add sw_build_config/platform/chromeos-config/generated/arc/*
git add sw_build_config/platform/chromeos-config/generated/bluetooth/*
git add -u
