#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See generated commit message for details on script.

project=$1
name=regen-display-screens

changes=$(git status | grep "generated")
if [[ -n "${changes}" ]]; then
  echo "For ${project}, uploading: ${changes}"
  git add -u
  git commit -m"
${project}: Regenerating display screen config

BUG=None
TEST=cq

Cq-Depend: chromium:2208050
"

  repo upload --no-verify --ht="${name}"
fi
