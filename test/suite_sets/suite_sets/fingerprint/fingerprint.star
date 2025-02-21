# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-fingerprint@google.com",
]

shared_bug_component = "b:782045"

def _fingerprint_pre_fsi():
    return create.suite_set(
        suite_set_id = "fingerprint_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Fingerprint tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["fingerprint_common"],
    )

def _fingerprint_fsi():
    return create.suite_set(
        suite_set_id = "fingerprint_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Fingerprint tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["fingerprint_common"],
    )

def _fingerprint_common():
    return create.suite(
        suite_id = "fingerprint_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Fingerprint tests common to FSI/Pre FSI testing.",
        tests = [
            "tauto.firmware_Fingerprint.RDP1",
            "tauto.firmware_Fingerprint.RebootToRO",
            "tauto.firmware_Fingerprint.ObeysRollback",
            "tauto.firmware_Fingerprint.CrosConfig",
            "tauto.firmware_Fingerprint.ROOnlyBootsValidRW",
            "tauto.firmware_FingerprintSigner",
            "tauto.firmware_Fingerprint.RDP0",
            "tauto.firmware_Fingerprint.SoftwareWriteProtect",
            "tauto.firmware_Fingerprint.SystemIsLocked",
            "tauto.firmware_Fingerprint.RWNoUpdateRO",
            "tauto.firmware_Fingerprint.ROCanUpdateRW",
            "tauto.firmware_Fingerprint.AddEntropy",
            "tauto.firmware_Fingerprint.ReadFlash",
        ],
    )

def _all_suite_sets():
    return [
        _fingerprint_pre_fsi(),
        _fingerprint_fsi(),
    ]

fingerprint_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _fingerprint_common(),
    ]

fingerprint_suites = struct(
    all_suites = _all_suites,
)
