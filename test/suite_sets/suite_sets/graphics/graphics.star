# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//create.star", "create")

shared_owners = [
    "chromeos-gfx-display@google.com",
    "markyacoub@google.com",
]

shared_bug_component = "b:188154"

def _graphics_pre_fsi():
    return create.suite_set(
        suite_set_id = "graphics_pre_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Graphics tests for PVS pre FSI testing.",
        suite_sets = [],
        suites = ["graphics_hw", "graphics_webgl", "graphics_video"],
    )

def _graphics_fsi():
    return create.suite_set(
        suite_set_id = "graphics_fsi",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Graphics tests for PVS FSI testing.",
        suite_sets = [],
        suites = ["graphics_hw"],
    )

def _graphics_hw():
    return create.suite(
        suite_id = "graphics_hw",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Graphics tests for validating hardware pre FSI.",
        tests = [
            "tast.graphics.DisplayHwValidation.kms_addfb_basic",
            "tast.graphics.DisplayHwValidation.kms_atomic",
            "tast.graphics.DisplayHwValidation.kms_atomic_interruptible",
            "tast.graphics.DisplayHwValidation.kms_bw",
            "tast.graphics.DisplayHwValidation.kms_concurrent",
            "tast.graphics.DisplayHwValidation.kms_cursor_crc",
            "tast.graphics.DisplayHwValidation.kms_cursor_legacy",
            "tast.graphics.DisplayHwValidation.kms_dp_aux_dev",
            "tast.graphics.DisplayHwValidation.kms_flip",
            "tast.graphics.DisplayHwValidation.kms_invalid_mode",
            "tast.graphics.DisplayHwValidation.kms_panel_fitting",
            "tast.graphics.DisplayHwValidation.kms_pipe_crc_basic",
            "tast.graphics.DisplayHwValidation.kms_plane",
            "tast.graphics.DisplayHwValidation.kms_plane_alpha_blend",
            "tast.graphics.DisplayHwValidation.kms_plane_cursor",
            "tast.graphics.DisplayHwValidation.kms_plane_scaling",
            "tast.graphics.DisplayHwValidation.kms_rotation_crc",
            "tast.graphics.DisplayHwValidation.kms_scaling_modes",
            "tast.graphics.DisplayHwValidation.kms_setmode",
            "tast.graphics.DisplayHwValidation.kms_sysfs_edid_timing",
            "tast.graphics.DisplayHwValidation.testdisplay",
        ],
    )

def _graphics_video():
    return create.suite(
        suite_id = "graphics_video",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Graphics tests for validating video playback pre FSI.",
        tests = [
            "tast.video.Play.h264_hw_mse",
            "tast.video.Play.vp8_hw_mse",
            "tast.video.Play.vp9_hw_mse",
            "tast.video.Play.h264_hw",
            "tast.video.Play.vp8_hw",
            "tast.video.Play.vp9_hw",
            "tast.video.Seek.h264",
            "tast.video.Seek.vp8",
            "tast.video.Seek.vp9",
        ],
    )

def _graphics_webgl():
    return create.suite(
        suite_id = "graphics_webgl",
        owners = shared_owners,
        bug_component = shared_bug_component,
        criteria = "Graphics tests for WebGL FSI testing.",
        tests = [
            "tast.graphics.WebGLAquarium.50_fishes",
            "tast.graphics.WebGLAquarium.1000_fishes",
            "tast.graphics.WebGLAquarium.50_fishes_lacros",
            "tast.graphics.WebGLAquarium.1000_fishes_lacros",
            "tast.graphics.WebGLManyPlanetsDeep",
            "tast.graphics.WebGLManyPlanetsDeep.lacros",
        ],
    )

def _all_suite_sets():
    return [
        _graphics_pre_fsi(),
        _graphics_fsi(),
    ]

graphics_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)

def _all_suites():
    return [
        _graphics_hw(),
        _graphics_video(),
        _graphics_webgl(),
    ]

graphics_suites = struct(
    all_suites = _all_suites,
)
