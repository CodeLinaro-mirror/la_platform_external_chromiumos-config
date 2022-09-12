#!/bin/bash
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Appends the include chromiumos/config:/OWNERS.all_projects
# statement to all program/project level owners files.

project=$1

if [ ! -f "OWNERS" ]; then
  echo "No OWNERS, so skipping ${project}"
  exit 0
fi
sed -i 's/include chromiumos\/config:\/OWNERS.all_projects/include chromeos\/config-internal:\/OWNERS.all_projects/g' OWNERS
git add OWNERS
