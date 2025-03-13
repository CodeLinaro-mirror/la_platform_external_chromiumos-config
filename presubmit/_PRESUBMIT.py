# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys


USE_PYTHON3 = True

# TODO(https://crbug.com/1046543): is there a better way to do this cross
# repo import?
sys.path.insert(1, "config/presubmit")
import presubmits


def CheckChangeOnUpload(input_api, output_api):
    return presubmits.CheckGenConfig(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    return presubmits.CheckGenConfig(input_api, output_api)
