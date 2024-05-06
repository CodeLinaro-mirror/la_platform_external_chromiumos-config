# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-cellular-eng@google.com",
]

shared_bug_component = "b:167157"

def _cellular_pre_fsi():
    return create.suite_set(
        suite_set_id = "cellular_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Cellular tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["cellular_common", "cellular_pre_fsi_only"],
    )

def _cellular_fsi():
    return create.suite_set(
        suite_set_id = "cellular_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Cellular tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["cellular_common"],
    )

def _cellular_common():
    return create.suite(
        suite_id = "cellular_common",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Cellular tests common to FSI/Pre FSI testing.",
        tests = [
            "tast.cellular.ConnectivityPerf",
            "tast.cellular.ModemfwdSmoke",
            "tast.cellular.ShillSafetyDance",
            "tast.cellular.Smoke",
            "tast.cellular.Smoke.amarisoft",
            "tast.cellular.Smoke.att",
            "tast.cellular.Smoke.bell",
            "tast.cellular.Smoke.docomo",
            "tast.cellular.Smoke.ee",
            "tast.cellular.Smoke.fi",
            "tast.cellular.SmokeIPConnectivity",
            "tast.cellular.SmokeIPConnectivity.amarisoft",
            "tast.cellular.SmokeIPConnectivity.att",
            "tast.cellular.SmokeIPConnectivity.bell",
            "tast.cellular.SmokeIPConnectivity.docomo",
            "tast.cellular.SmokeIPConnectivity.ee",
            "tast.cellular.SmokeIPConnectivity.fi",
            "tast.cellular.SmokeIPConnectivity.kddi",
            "tast.cellular.SmokeIPConnectivity.rak",
            "tast.cellular.SmokeIPConnectivity.rakuten",
            "tast.cellular.SmokeIPConnectivity.roger",
            "tast.cellular.SmokeIPConnectivity.softbank",
            "tast.cellular.SmokeIPConnectivity.telus",
            "tast.cellular.SmokeIPConnectivity.tmobile",
            "tast.cellular.SmokeIPConnectivity.verizon",
            "tast.cellular.SmokeIPConnectivity.vodafone",
            "tast.cellular.Smoke.kddi",
            "tast.cellular.Smoke.rak",
            "tast.cellular.Smoke.rakuten",
            "tast.cellular.Smoke.roger",
            "tast.cellular.Smoke.softbank",
            "tast.cellular.Smoke.telus",
            "tast.cellular.Smoke.tmobile",
            "tast.cellular.Smoke.verizon",
            "tast.cellular.Smoke.vodafone",
        ],
    )

def _cellular_pre_fsi_only():
    return create.suite(
        suite_id = "cellular_pre_fsi_only",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Cellular tests which should be run for Pre FSI testing only.",
        tests = [
            "tast.cellular.ShillEnableAndConnect",
        ],
    )

def _all_suite_sets():
    return [
        _cellular_pre_fsi(),
        _cellular_fsi(),
    ]

cellular_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _cellular_common(),
        _cellular_pre_fsi_only(),
    ]

cellular_suites = struct(
    all_suites = _all_suites,
)
