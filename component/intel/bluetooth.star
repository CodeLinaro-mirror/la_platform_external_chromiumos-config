# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Functions related to Intel Bluetooth components.

See proto definitions for descriptions of arguments.
"""

load("//config/util/component.star", "comp")

VENDOR_ID = "00E0"
VERSION = "0400"

def _model(model):
    """Builds a Component proto for Intel Bluetooth."""
    return comp.create_bt(VENDOR_ID, model, VERSION)

intel_bt = struct(
    model = _model,
)
