# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

def _audio_pre_fsi():
    return create.suite(
        suite_id = "audio_pre_fsi",
        owners = [
            "chromeos-audio-bugs@google.com",
            "aaronyu@google.com",
        ],
        bug_component = "b:776546",
        criteria = "Audio tests for PVS pre FSI testing.",
        tests = [
            "tast.audio.UCMSequences.section_verb",
            "tast.audio.UCMSequences.section_device",
            "tast.audio.UCMSequences.section_modifier",
            "tast.audio.SoundCardInit.run_success",
            "tast.audio.SoundCardInit.validate_rdc_range",
            "tast.audio.EchoRefDevice.frequency_200",
            "tast.audio.EchoRefDevice.frequency_400",
            "tast.audio.EchoRefDevice.frequency_1000",
            "tast.audio.EchoRefDevice.frequency_2000",
        ],
    )

def _all_suites():
    return [
        _audio_pre_fsi(),
    ]

audio_suites = struct(
    all_suites = _all_suites,
)
