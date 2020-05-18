#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Restructures to allow shared arc features config across projects.

project=$1


changes=$(grep create_screen config.star)
if [[ -n "${changes}" ]]; then
  ./config/bin/gen_config config.star
  git add -u
fi

