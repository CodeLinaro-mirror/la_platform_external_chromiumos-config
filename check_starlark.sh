#!/usr/bin/env bash
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
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
    if ! buildifier -mode check "$f"; then
        found_unformatted=1
    fi
done

if [[ $found_unformatted -ne 0 ]]; then
    echo "Found unformatted Starlark files. Please format with buildifier (https://github.com/bazelbuild/buildtools/tree/master/buildifier)."
    exit 1
fi

echo "Linting Starlark files..."
found_lint_fail=0
for f in util/**/*.star; do
    if ! buildifier -lint warn "$f"; then
        found_lint_fail=1
    fi
done

if [[ $found_lint_fail -ne 0 ]]; then
    echo "Found linting errors in Starlark files. Please fix and re-lint with buildifier (https://github.com/bazelbuild/buildtools/tree/master/buildifier)."
    exit 1
fi