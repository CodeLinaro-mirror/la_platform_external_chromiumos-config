#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See generated commit message for details on script.

program=$1
name=remove-build-targets

changes=$(git status | grep "generated")
if [[ -n "${changes}" ]]; then
  echo "For ${program}, uploading: ${changes}"
  git add -u
  git commit -m"
${program}: Removing build-targets config

BUG=None
TEST=cq

Cq-Depend: chromium:2568394
"

  repo upload --no-verify --ht="${name}"
fi
