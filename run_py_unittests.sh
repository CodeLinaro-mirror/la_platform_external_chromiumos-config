#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs python unittests in a venv.

readonly bin_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"/bin

# Move to this script's directory.
cd "$(dirname "$0")"

# Generate protos
echo "Generating proto bindings..."
./generate.sh

# Create and activate venv.
echo "Creating and activating venv..."
source "${bin_dir}/common.sh"
create_venv

# Discover and run unittests in payload_utils.
echo "Running unittests..."
python3 -m unittest discover -s payload_utils -p "*test.py"

echo "Running pylint..."
PYTHONPATH=payload_utils pylint "$(pwd)/payload_utils" \
    --rcfile=payload_utils/pylintrc

echo "Checking Python files formatted with yapf..."
if ! yapf --style .style.yapf --diff -r payload_utils ; then
    echo "Python files require reformatting. Please run 'yapf --style .style.yapf --in-place -r payload_utils'."
    exit 1
fi

# Deactivate venv.
deactivate
