# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

def _faft_pd():
    return create.suite(
        suite_id = "faft_pd",
        owners = [
            "chromeos-faft@google.com",
            "jbettis@chromium.org",
        ],
        bug_component = "b:792402",
        criteria = "Verify the behaviors of the USB PD stack.",
        tests = [
            "tast.firmware.ECPDConnect.dtsoff",
            "tast.firmware.ECPDConnect.flipcc",
            "tast.firmware.ECPDConnect.flipcc_dtsoff",
            "tast.firmware.ECPDConnect.normal",
            "tast.firmware.ECPDPowerSwap.dtsoff",
            "tast.firmware.ECPDPowerSwap.flipcc",
            "tast.firmware.ECPDPowerSwap.flipcc_dtsoff",
            "tast.firmware.ECPDPowerSwap.normal",
            "tast.firmware.ECPDPowerSwap.shutdown",
            "tast.firmware.ECPDPowerSwap.suspend",
            "tast.firmware.ECPDTrysrc.flipcc",
            "tast.firmware.ECPDTrysrc.normal",
            "tast.firmware.ECWakeFromULP.lid_switch",
            "tast.firmware.PDDataSwap.dtsoff",
            "tast.firmware.PDDataSwap.dtsoff_snk",
            "tast.firmware.PDDataSwap.flipcc",
            "tast.firmware.PDDataSwap.flipcc_dtsoff",
            "tast.firmware.PDDataSwap.flipcc_dtsoff_snk",
            "tast.firmware.PDDataSwap.flipcc_snk",
            "tast.firmware.PDDataSwap.normal",
            "tast.firmware.PDDataSwap.normal_snk",
            "tast.firmware.PDDataSwap.shutdown",
            "tast.firmware.PDProtocol",
            "tast.firmware.PDVbusRequest.dtsoff",
            "tast.firmware.PDVbusRequest.flipcc",
            "tast.firmware.PDVbusRequest.flipcc_dtsoff",
            "tast.firmware.PDVbusRequest.normal",
            "tast.firmware.PDVbusRequest.shutdown",
            "tauto.firmware_PDResetHard",
            "tauto.firmware_PDResetHard.dts",
            "tauto.firmware_PDResetHard.dts_flip",
            "tauto.firmware_PDResetHard.flip",
            "tauto.firmware_PDResetHard.shutdown",
            "tauto.firmware_PDResetSoft",
            "tauto.firmware_PDResetSoft.dts",
            "tauto.firmware_PDResetSoft.dts_flip",
            "tauto.firmware_PDResetSoft.flip",
            "tauto.firmware_PDResetSoft.shutdown",
            "tauto.firmware_PDVbusRequest",
            "tauto.firmware_PDVbusRequest.dts",
            "tauto.firmware_PDVbusRequest.dts_flip",
            "tauto.firmware_PDVbusRequest.flip",
            "tauto.firmware_PDVbusRequest.shutdown",
            "tauto.firmware_PDVbusRequest.suspend",
        ],
    )

def _all_suites():
    return [
        _faft_pd(),
    ]

faft_pd = struct(
    all_suites = _all_suites,
)
