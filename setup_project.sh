#!/bin/bash
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Setup a project.

mkdir /tmp/setup_project 2>/dev/null
cipd install -force -root /tmp/setup_project \
  chromiumos/infra/setup_project/\$\{platform\} prod
# If --checkout is not supplied, assume that this script is being run from
# a checkout and infer the root.
if [[ "$*" != *"-checkout"* ]]; then
  set -- "$@" "-checkout=$(pwd)/../../"
fi
/tmp/setup_project/setup_project setup-project "$@"