# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

def _wifi_pre_fsi():
    return create.suite(
        suite_id = "wifi_pre_fsi",
        owners = [
            "chromeos-wifi-champs@google.com",
        ],
        bug_component = "b:893827",
        criteria = "Wi-Fi tests that run pre FSI and are not part of AVL/require no special testbed.",
        tests = [
            "tast.wifi.SetTXPower",
            "tast.wifi.SetTXPower.vpd",
            "tast.wifi.CheckIntelSARTable",
        ],
    )

def _all_suites():
    return [
        _wifi_pre_fsi(),
    ]

wifi_suites = struct(
    all_suites = _all_suites,
)
