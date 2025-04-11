#!/bin/bash -e
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs pytype on payload_utils.

echo "Running pytype..."
set -- vpython3 -m pytype --keep-going --config=payload_utils/pytype.cfg
echo "$@"
"$@"
