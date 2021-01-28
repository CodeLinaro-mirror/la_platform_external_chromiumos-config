#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs pytype on payload_utils.

# Create and activate venv.
# TODO(crbug.com/1171815): use vpython once pytype wheels are in place
echo "Creating and activating venv..."
/usr/bin/python3 -m venv .venv
source .venv/bin/activate

echo "Installing pytype..."
pip install -q pytype==2020.6.1

echo "Running pytype..."
pytype --config=payload_utils/pytype.cfg

deactivate