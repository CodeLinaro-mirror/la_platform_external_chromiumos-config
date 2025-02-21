# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "baseos-perf@google.com",
]

shared_bug_component = "b:167279"

def _performance_pre_fsi():
    return create.suite_set(
        suite_set_id = "performance_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Performance tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["performance_common"],
    )

def _performance_fsi():
    return create.suite_set(
        suite_set_id = "performance_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Performance tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["performance_common"],
    )

def _performance_common():
    return create.suite(
        suite_id = "performance_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Performance tests common to FSI/Pre FSI testing.",
        tests = [
            "tast.platform.BootPerf.default_bounds",
            "tast.platform.BootPerf.ec_reboot_bounds",
            "tast.platform.BootPerf.from_g3_bounds",
            "tast.platform.BootPerf.from_s5_bounds",
            "tauto.power_UiResume.freeze",
        ],
    )

def _all_suite_sets():
    return [
        _performance_pre_fsi(),
        _performance_fsi(),
    ]

performance_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _performance_common(),
    ]

performance_suites = struct(
    all_suites = _all_suites,
)
