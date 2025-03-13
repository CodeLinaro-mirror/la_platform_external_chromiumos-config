#!/bin/bash
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See generated commit message for details on script.

project=$1
name=add-all-project-owners

changes=$(git status | grep "OWNERS")
if [[ -n "${changes}" ]]; then
  echo "For ${project}, uploading: ${changes}"
  git commit -m"
${project}: Adding all_projects OWNERS

Adding owners to support easy refactors across all programs/projects.

BUG=b:195297624
TEST=cq
"

  repo upload --no-verify -y --ht="${name}"
fi
