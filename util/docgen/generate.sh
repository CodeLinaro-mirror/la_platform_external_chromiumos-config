#!/usr/bin/env bash
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# A convenience script to regenerate util/README.md with the util/docgen/main.go
# program.
script_dir="$(realpath "$(dirname "$0")")"
cd "${script_dir}" || exit 1

set -e

source "${script_dir}/../../setup_cipd.sh"

go get go.chromium.org/luci/lucicfg/docgen

go run main.go \
    -template "README.mdt" \
    -output "../README.md" \
    -starlarkRoot "../../.."