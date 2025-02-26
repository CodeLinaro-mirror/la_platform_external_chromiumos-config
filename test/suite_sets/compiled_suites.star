# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges all Suites into a single list"""

load("//create.star", "create")
load("//suite_sets/audio/audio.star", "audio_suites")
load("//suite_sets/camera/camera.star", "camera_suites")
load("//suite_sets/cellular/cellular.star", "cellular_suites")
load("//suite_sets/cq/bvt-cq.star", "bvt_cq")
load("//suite_sets/cq/bvt-inline.star", "bvt_inline")
load("//suite_sets/cq/bvt-tast-cq.star", "bvt_tast_cq")
load("//suite_sets/example/example_suites.star", "example_suites")
load("//suite_sets/firmware/faft_bios_ro_qual.star", "faft_bios_ro_qual")
load("//suite_sets/firmware/faft_bios_rw_qual.star", "faft_bios_rw_qual")
load("//suite_sets/firmware/faft_ec_fw_qual.star", "faft_ec_fw_qual")
load("//suite_sets/firmware/faft_pd.star", "faft_pd")
load("//suite_sets/firmware/firmware.star", "firmware_suites")
load("//suite_sets/graphics/graphics.star", "graphics_suites")
load("//suite_sets/input/input.star", "input_suites")
load("//suite_sets/performance/performance.star", "performance_suites")
load("//suite_sets/platform/platform.star", "platform_suites")
load("//suite_sets/power/power.star", "power_suites")
load("//suite_sets/virtualization/virtualization.star", "virtualization_suites")
load("//suite_sets/wifi/wifi.star", "wifi_suites")

_suites = []

_suites.extend(audio_suites.all_suites())
_suites.extend(camera_suites.all_suites())
_suites.extend(cellular_suites.all_suites())
_suites.extend(graphics_suites.all_suites())
_suites.extend(input_suites.all_suites())
_suites.extend(performance_suites.all_suites())
_suites.extend(platform_suites.all_suites())
_suites.extend(power_suites.all_suites())
_suites.extend(bvt_cq.all_suites())
_suites.extend(bvt_inline.all_suites())
_suites.extend(bvt_tast_cq.all_suites())
_suites.extend(example_suites.all_suites())
_suites.extend(faft_bios_ro_qual.all_suites())
_suites.extend(faft_bios_rw_qual.all_suites())
_suites.extend(faft_ec_fw_qual.all_suites())
_suites.extend(faft_pd.all_suites())
_suites.extend(firmware_suites.all_suites())
_suites.extend(virtualization_suites.all_suites())
_suites.extend(wifi_suites.all_suites())

compiled_suites = create.suite_list(suites = _suites)
