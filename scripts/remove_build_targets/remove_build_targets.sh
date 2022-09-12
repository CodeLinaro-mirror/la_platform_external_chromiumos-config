#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Removes build-target config

program=$1

sed -i '/build_target.star/d' ./config.star ./program.star
sed -i '/build_targets =/d' ./config.star ./program.star
sed -i '/BUILD_TARGETS/d' ./config.star ./program.star
./config/bin/gen_config config.star
git add -u
