# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

def _virtualization_fsi():
    return create.suite(
        suite_id = "virtualization_fsi",
        owners = [
            "cros-arc-te@google.com",
        ],
        bug_component = "b:1052117",
        criteria = "Validate Virtualization related functionality for FSI.",
        tests = [
            "tast.arc.OobeArcAppOpen",
            "tast.arc.VerifyDefaultApps",
        ],
    )

def _all_suites():
    return [
        _virtualization_fsi(),
    ]

virtualization_suites = struct(
    all_suites = _all_suites,
)
