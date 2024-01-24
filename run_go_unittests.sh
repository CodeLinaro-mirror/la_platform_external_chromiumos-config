#!/bin/bash -e
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Move to this script's directory.
script_dir="$(realpath "$(dirname "$0")")"
cd "${script_dir}"

# Get go from CIPD.
echo "Getting go from CIPD..."
cipd_root="${script_dir}/.cipd_bin"
cipd ensure \
  -log-level warning \
  -root "${cipd_root}" \
  -ensure-file - \
  <<ENSURE_FILE
infra/3pp/tools/go/\${platform} Tf3SZrWyvwG41VbGwWrdVUkS7Vqxa_Mh8vApnidVgUkC
ENSURE_FILE
# TODO(b/295057050): See if we can use the common Chromium Golang version
# as found in go/env.py.

PATH="${cipd_root}/bin:${PATH}"

echo "Running unittests..."
cd go/src/go.chromium.org/chromiumos/config/go
GOROOT="${cipd_root}" go test -mod=readonly ./...
