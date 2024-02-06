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
            "firmware_ECWakeFromULP",
            "firmware_PDResetHard",
            "firmware_PDResetHard.dts",
            "firmware_PDResetHard.dts_flip",
            "firmware_PDResetHard.flip",
            "firmware_PDResetHard.shutdown",
            "firmware_PDResetSoft",
            "firmware_PDResetSoft.dts",
            "firmware_PDResetSoft.dts_flip",
            "firmware_PDResetSoft.flip",
            "firmware_PDResetSoft.shutdown",
            "firmware_PDTrySrc",
            "firmware_PDTrySrc.flip",
            "firmware_PDVbusRequest",
            "firmware_PDVbusRequest.dts",
            "firmware_PDVbusRequest.dts_flip",
            "firmware_PDVbusRequest.flip",
            "firmware_PDVbusRequest.shutdown",
            "firmware_PDVbusRequest.suspend",
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
            "tast.firmware.PDProtocol",
        ],
    )

def _all_suites():
    return [
        _faft_pd(),
    ]

faft_pd = struct(
    all_suites = _all_suites,
)
