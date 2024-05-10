# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-platform-power@google.com",
]

shared_bug_component = "b:1361410"

def _power_pre_fsi():
    return create.suite_set(
        suite_set_id = "power_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Power tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["power_qual", "thermal_qual", "power_low_power_qual", "power_other"],
    )

def _power_fsi():
    return create.suite_set(
        suite_set_id = "power_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Power tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["power_qual", "thermal_qual", "power_low_power_qual"],
    )

def _power_qual():
    return create.suite(
        suite_id = "power_qual",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Power tests qualify a device for battery life while running.",
        tests = [
            "tast.meta.PowerQual.qual",
        ],
    )

def _power_low_power_qual():
    return create.suite(
        suite_id = "power_low_power_qual",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Power tests qualify a device for power consumption while in suspend/shutdown mode.",
        tests = [
            "tast.power.LowPowerConsumption.suspend",
            "tast.power.LowPowerConsumption.shutdown",
        ],
    )

def _thermal_qual():
    return create.suite(
        suite_id = "thermal_qual",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Tests to qualify thermal performance of the device.",
        tests = [
            "tauto.pvs_Sequence.ThermalQualChargingVideoCall",
            "tauto.pvs_Sequence.ThermalQualDischargingVideoCall",
            "tauto.pvs_Sequence.ThermalQualChargingThermalLoad",
            "tauto.pvs_Sequence.ThermalQualDischargingThermalLoad",
        ],
    )

def _power_other():
    return create.suite(
        suite_id = "power_other",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Other tests for validating power related performance and functionality.",
        tests = [
            "tauto.power_WakeSources",
        ],
    )

def _all_suite_sets():
    return [
        _power_pre_fsi(),
        _power_fsi(),
    ]

power_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _power_qual(),
        _power_low_power_qual(),
        _thermal_qual(),
        _power_other(),
    ]

power_suites = struct(
    all_suites = _all_suites,
)
