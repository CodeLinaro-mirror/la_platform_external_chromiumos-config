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

shopt -s globstar nullglob

echo "Checking Starlark files formatted..."
found_unformatted=0
for f in util/**/*.star; do
    if ! lucicfg fmt "${f}" -dry-run; then
        found_unformatted=1
    fi
done

if [[ ${found_unformatted} -ne 0 ]]; then
    echo "Found unformatted Starlark files. Please format with lucicfg fmt (https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#formatting_linting)."
    exit 1
fi

echo "Linting Starlark files..."
found_lint_fail=0
for f in util/**/*.star; do
    if ! lucicfg lint "${f}"; then
        found_lint_fail=1
    fi
done

if [[ ${found_lint_fail} -ne 0 ]]; then
    echo "Found linting errors in Starlark files. Please fix and re-lint with lucicfg lint (https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#formatting_linting)."
    exit 1
fi
