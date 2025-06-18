# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "essential-inputs-team@google.com",
]

shared_bug_component = "b:95887"

def _input_pre_fsi():
    return create.suite_set(
        suite_set_id = "input_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Input tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["input_common"],
    )

def _input_fsi():
    return create.suite_set(
        suite_set_id = "input_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Input tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["input_common"],
    )

def _input_common():
    return create.suite(
        suite_id = "input_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Input tests common to FSI/Pre FSI testing.",
        tests = [
            "tast.inputs.VirtualKeyboardHandwriting.docked",
            "tast.inputs.VirtualKeyboardHandwriting.docked_informational",
            "tast.inputs.VirtualKeyboardHandwriting.floating",
            "tast.inputs.VirtualKeyboardHandwriting.floating_informational",
            "tast.inputs.VirtualKeyboardHandwriting.docked_lacros",
            "tast.inputs.VirtualKeyboardHandwriting.floating_lacros",
            "tast.inputs.VirtualKeyboardSpeech",
        ],
    )

def _all_suite_sets():
    return [
        _input_pre_fsi(),
        _input_fsi(),
    ]

input_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _input_common(),
    ]

input_suites = struct(
    all_suites = _all_suites,
)
