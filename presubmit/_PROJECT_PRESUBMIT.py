# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys


# TODO(https://crbug.com/1046543): is there a better way to do this cross
# repo import?
sys.path.insert(1, "config/presubmit")
import presubmits


USE_PYTHON3 = True


def CheckChangeOnUpload(input_api, output_api):
    results = []
    results.extend(presubmits.CheckGenConfig(input_api, output_api))
    # Note that we only run this on upload. On the commit side in CQ there is a
    # separate builder that executes this check.
    results.extend(presubmits.CheckChecker(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    return presubmits.CheckGenConfig(input_api, output_api)
