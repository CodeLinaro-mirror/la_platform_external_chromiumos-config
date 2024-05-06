# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-faft@google.com",
    "jbettis@chromium.org",
]

shared_bug_component = "b:792402"

def _platform_pre_fsi():
    return create.suite_set(
        suite_set_id = "platform_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["labqual", "platform_common"],
    )

def _platform_fsi():
    return create.suite_set(
        suite_set_id = "platform_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["platform_common", "platform_fsi_only"],
    )

def labqual():
    return create.suite(
        suite_id = "labqual",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests to check device readiness for lab entry.",
        tests = [
            "tauto.platform_ServoPowerStateController.usb",
            "tauto.firmware_DevMode",
            "tauto.firmware_UserRequestRecovery",
            "tauto.firmware_FAFTSetup",
            "tauto.firmware_UserRequestRecovery.dev",
        ],
    )

def _platform_common():
    return create.suite(
        suite_id = "platform_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests common to FSI/Pre FSI testing.",
        tests = [
            "tast.lockscreen.PINUnlock",
        ],
    )

def _platform_fsi_only():
    return create.suite(
        suite_id = "platform_fsi_only",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests which should be run for Pre FSI testing only.",
        tests = [
            "tast.quicksettings.BasicLayout.tablet",
        ],
    )

def _all_suite_sets():
    return [
        _platform_pre_fsi(),
        _platform_fsi(),
    ]

platform_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        labqual(),
        _platform_common(),
        _platform_fsi_only(),
    ]

platform_suites = struct(
    all_suites = _all_suites,
)
