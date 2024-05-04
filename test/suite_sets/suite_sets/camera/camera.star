# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-camera-eng@google.com",
]

shared_bug_component = "b:1475606"

def _camera_pre_fsi():
    return create.suite_set(
        suite_set_id = "camera_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Camera tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["camera_common", "camera_pre_fsi_only"],
    )

def _camera_fsi():
    return create.suite_set(
        suite_set_id = "camera_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Camera tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["camera_common"],
    )

def _camera_common():
    return create.suite(
        suite_id = "camera_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Camera tests common to FSI/Pre FSI testing.",
        tests = [
            "tast.camera.CCAUITakePicture",
            "tast.camera.CCAUIRecordVideo",
        ],
    )

def _camera_pre_fsi_only():
    return create.suite(
        suite_id = "camera_pre_fsi_only",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Camera tests which should be run for Pre FSI testing only.",
        tests = [
            "tast.camera.CCAUISmoke.real",
            "tast.camera.CCAUISmoke.vivid",
        ],
    )

def _all_suite_sets():
    return [
        _camera_pre_fsi(),
        _camera_fsi(),
    ]

camera_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _camera_common(),
        _camera_pre_fsi_only(),
    ]

camera_suites = struct(
    all_suites = _all_suites,
)
