# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges all SuiteSets into a single list"""

load("//create.star", "create")
load("//suite_sets/camera/camera.star", "camera_suite_sets")
load("//suite_sets/cellular/cellular.star", "cellular_suite_sets")
load("//suite_sets/example/example_suite_sets.star", "example_suite_sets")
load("//suite_sets/firmware/firmware.star", "firmware_suite_sets")
load("//suite_sets/graphics/graphics.star", "graphics_suite_sets")
load("//suite_sets/input/input.star", "input_suite_sets")
load("//suite_sets/performance/performance.star", "performance_suite_sets")
load("//suite_sets/platform/platform.star", "platform_suite_sets")
load("//suite_sets/power/power.star", "power_suite_sets")
load("//suite_sets/pvs/qualifications.star", "pvs_qualifications")

_suite_sets = []

_suite_sets.extend(camera_suite_sets.all_suite_sets())
_suite_sets.extend(cellular_suite_sets.all_suite_sets())
_suite_sets.extend(graphics_suite_sets.all_suite_sets())
_suite_sets.extend(input_suite_sets.all_suite_sets())
_suite_sets.extend(performance_suite_sets.all_suite_sets())
_suite_sets.extend(platform_suite_sets.all_suite_sets())
_suite_sets.extend(power_suite_sets.all_suite_sets())
_suite_sets.extend(example_suite_sets.all_suite_sets())
_suite_sets.extend(firmware_suite_sets.all_suite_sets())
_suite_sets.extend(pvs_qualifications.all_suite_sets())

compiled_suite_sets = create.suite_set_list(suite_sets = _suite_sets)
