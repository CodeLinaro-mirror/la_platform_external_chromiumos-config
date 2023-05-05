#!/usr/bin/env bash
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Move to this script's directory.
script_dir="$(realpath "$(dirname "$0")")"
cd "${script_dir}" || exit 1

set -e

source "${script_dir}/setup_cipd.sh"

echo "Checking Starlark files formatted..."
if ! find util -name '*.star' -exec lucicfg fmt -dry-run {} +; then
    echo "Found unformatted Starlark files. Please format with lucicfg fmt (https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#formatting_linting)."
    exit 1
fi

echo "Linting Starlark files..."
if ! find util -name '*.star' -exec lucicfg lint {} +; then
    echo "Found linting errors in Starlark files. Please fix and re-lint with lucicfg lint (https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#formatting_linting)."
    exit 1
fi
