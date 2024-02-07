# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "jackgelinas@google.com",
    "bbrotherton@google.com",
]
shared_bug_component = "b:chromiumos:platform:firmware"

def _firmware_other():
    return create.suite(
        suite_id = "firmware_other",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Tests used to qualify the device firmware, that are not part of faft_* suites.",
        tests = [
            "tast.storage.QuickStress",
            "tast.platform.BootPerf",
            "firmware_ConsecutiveBoot.dev.500",
            "firmware_ConsecutiveBoot.2500",
            "power_SuspendStress.bareFSI",
            "power_UiResume.freeze",
            "power_CPUFreq",
            "power_CPUIlde",
            "hardware_TPMCheck",
            # TODO need power battery life test figure out if old or new should be added
        ],
    )

def _firmware_common():
    return create.suite_set(
        suite_set_id = "firmware_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Common firmware suites/tests used to qualify the device firmware.",
        suite_sets = [],
        suites = [
            "faft_ec_fw_qual",
            "faf_pd",
            "firmware_other",
        ],
    )

def _firmware_ro():
    return create.suite_set(
        suite_set_id = "firmware_ro",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Qualify the device firmware for RO/RW release.",
        suite_sets = ["firmware_common"],
        suites = ["faft_bios_ro_qual"],
    )

def _firmware_rw():
    return create.suite_set(
        suite_set_id = "firmware_rw",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Qualify the device firmware for RW-only release.",
        suite_sets = ["firmware_common"],
        suites = ["faft_bios_rw_qual"],
    )

def _all_suite_sets():
    return [
        _firmware_common(),
        _firmware_ro(),
        _firmware_rw(),
    ]

firmware_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _firmware_other(),
    ]

firmware_suites = struct(
    all_suites = _all_suites,
)
