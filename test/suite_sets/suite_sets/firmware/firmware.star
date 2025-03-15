# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "bbrotherton@google.com",
]
shared_bug_component = "b:chromiumos:platform:firmware"

def _firmware_other():
    return create.suite(
        suite_id = "firmware_other",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Tests used to qualify the device firmware, that are not part of faft_* suites, includes longer running stress tests.",
        tests = [
            "tast.storage.QuickStress.setup",
            "tast.storage.QuickStress.stress",
            "tast.storage.QuickStress.teardown",
            "tast.platform.BootPerf",
            # temporarily disable long running tests as they will
            # time out with 10 hour max runtime
            # "tauto.firmware_ConsecutiveBoot.dev.500",
            # "tauto.firmware_ConsecutiveBoot.2500",
            # "tauto.power_SuspendStress.bareFSI",
            "tauto.power_UiResume.freeze",
            "tauto.power_CPUFreq",
            "tauto.power_CPUIdle",
            "tauto.hardware_TPMCheck",
            # TODO need power battery life test figure out if old or new should be added
        ],
    )

def _faft_common():
    return create.suite_set(
        suite_set_id = "faft_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Common firmware suites/tests used to qualify the device firmware.",
        suite_sets = [],
        suites = [
            "faft_ec_fw_qual",
            "faft_pd",
        ],
    )

def _faft_ro():
    return create.suite_set(
        suite_set_id = "faft_ro",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "All the faft suites needed to qualify the device for a firmware for RO/RW release.",
        suite_sets = ["faft_common"],
        suites = ["faft_bios_ro_qual"],
    )

def _faft_rw():
    return create.suite_set(
        suite_set_id = "faft_rw",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "All the faft suites needed to qualify the device for a firmware for RW-only release.",
        suite_sets = ["faft_common"],
        suites = ["faft_bios_rw_qual"],
    )

def _firmware_rorw():
    return create.suite_set(
        suite_set_id = "firmware_rorw",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "All tests needed to qualify the device firmware for RO/RW release.",
        suite_sets = ["faft_ro"],
        suites = ["firmware_other"],
    )

def _firmware_rw():
    return create.suite_set(
        suite_set_id = "firmware_rw",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "All tests needed to qualify the device firmware for RW-only release.",
        suite_sets = ["faft_rw"],
        suites = ["firmware_other"],
    )

def _all_suite_sets():
    return [
        _faft_common(),
        _faft_ro(),
        _faft_rw(),
        _firmware_rorw(),
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
