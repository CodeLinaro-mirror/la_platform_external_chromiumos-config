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
        suites = ["labqual_stable", "platform_common"],
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

def _labqual_stable():
    return create.suite(
        suite_id = "labqual_stable",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Platform tests to check device readiness for lab entry.",
        tests = [
            "tast.labqual.BootupTimesUSB.usb_recovery",
            "tast.labqual.TPMReset.rec_mode",
            "tast.labqual.SerialNumber",
            "tast.labqual.DeviceHwid",
            "tast.labqual.ServoGBBFlagsFutility",
            "tast.labqual.DevToSecureMode.dev_mode",
            "tast.labqual.InternalStorage",
            "tast.labqual.BootupTimesUSB.usb_dev",
            "tast.labqual.TPMStatus",
            "tast.labqual.ECControlRead",
            "tast.labqual.SSHStability",
            "tast.labqual.ServoGSCFlags",
            "tast.labqual.ServoDeviceBatteryCheck",
            "tast.labqual.UpdateDutFirmware",
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
        _labqual_stable(),
        _platform_common(),
        _platform_fsi_only(),
    ]

platform_suites = struct(
    all_suites = _all_suites,
)
