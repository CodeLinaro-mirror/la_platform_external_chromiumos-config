#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs python unittests and pytype in a venv.

# Move to this script's directory.
cd "$(dirname "$0")"

# Generate protos
echo "Generating proto bindings..."
./generate.sh

# Create and activate venv.
echo "Creating and activating venv..."
/usr/bin/python3 -m venv .venv
source .venv/bin/activate

# Install requirements.
echo "Installing required packages..."
# An upgrade to setuptools is needed for pytype.
pip install setuptools==45.2.0 -q
pip install -r requirements.txt -q

# Discover and run unittests in payload_utils.
echo "Running unittests..."
python3 -m unittest discover -s payload_utils -p *test.py

# Run pytype.
echo "Running pytype..."
pytype --config=pytype.cfg

# Deactivate venv.
deactivate