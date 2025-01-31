# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")
load("//suite_sets/pvs/common.star", "pvs_common")

def _pre_fsi():
    return create.suite_set(
        suite_set_id = "pre_fsi",
        owners = pvs_common.owners,
        bug_component = pvs_common.bug_component,
        criteria = "Automated tests that must be passed for device before FSI.",
        suite_sets = [
            "camera_pre_fsi",
            "cellular_pre_fsi",
            "graphics_pre_fsi",
            "input_pre_fsi",
            "performance_pre_fsi",
            "platform_pre_fsi",
            # power/thermal tests take a very long time temporarily remove
            # to allow validation of other tests
            # "power_pre_fsi",
        ],
        suites = [
            "audio_pre_fsi",
            "wifi_pre_fsi",
        ],
    )

def _fsi():
    return create.suite_set(
        suite_set_id = "fsi",
        owners = pvs_common.owners,
        bug_component = pvs_common.bug_component,
        criteria = "Automated tests that must pass before FSI.",
        suite_sets = [
            "camera_fsi",
            "cellular_fsi",
            "graphics_fsi",
            "input_fsi",
            "performance_fsi",
            "platform_fsi",
            "power_fsi",
        ],
        suites = [
            "virtualization_fsi",
        ],
    )

def _all_suite_sets():
    return [
        _pre_fsi(),
        _fsi(),
    ]

pvs_qualifications = struct(
    all_suite_sets = _all_suite_sets,
)
