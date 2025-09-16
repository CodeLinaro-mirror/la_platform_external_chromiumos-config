#!/bin/bash -e
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs python unittests in a venv.

# Move to this script's directory.
cd "$(dirname "$0")"

# Generate protos
echo "Generating proto bindings..."
./generate.sh

# Discover and run unittests in payload_utils.
echo "Running unittests..."
PYTHONPATH=payload_utils vpython3 -m pytest

echo "Running pylint..."
vpython3 -m pylint "$(pwd)/payload_utils" \
    --rcfile=payload_utils/pylintrc

echo "Checking Python files formatted..."
files=(
  $(git ls-tree -r HEAD | awk '$1 != "120000" && $NF ~ /\.py$/ {print $NF}')
)
if ! ./black --check --diff "${files[@]}"; then
  echo "Python files require reformatting."
  exit 1
fi
