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
vpython3 -m unittest discover -s payload_utils -p "*test.py"

echo "Running pylint..."
PYTHONPATH=payload_utils vpython3 -m pylint "$(pwd)/payload_utils" \
    --rcfile=payload_utils/pylintrc

echo "Checking Python files formatted with yapf..."
if ! vpython3 -m yapf --style .style.yapf --diff -r payload_utils ; then
    echo "Python files require reformatting. Please run 'yapf --style .style.yapf --in-place -r payload_utils'."
    exit 1
fi
