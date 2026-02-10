# Copyright 2025 Google LLC. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Starlark API for creating and encoding component_id based device configurations.

This module provides API for constructing the protobuf messages defined in
android_component_configs.proto.
"""

load(
    "@proto//chromiumos/config/api/android_component_configs.proto",
    android_component_pb = "chromiumos.config.api",
)

# Needed to load from @proto.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/generate.star", "generate")

def _create_audio(
        id,
        soundcard = None):
    """Builds android_hal_config proto for an audio component."""

    return android_component_pb.AudioConfigurationType(
        id = id,
        soundcard = soundcard,
    )

def _create_fingerprint(
        id,
        board,
        fingerprint_sensor_type = None,
        sensor_location = None,
        ro_version = None):
    """Builds android_hal_config proto for a fingerprint reader."""

    return android_component_pb.FingerprintConfigurationType(
        id = id,
        board = board,
        fingerprint_sensor_type = fingerprint_sensor_type,
        sensor_location = sensor_location,
        ro_version = ro_version,
    )

def _create_cellular(
        id,
        modem_type = None,
        firmware_variant = None):
    """Builds android_hal_config proto for a cellular modem."""

    return android_component_pb.CellularConfigurationType(
        id = id,
        modem_type = modem_type,
        firmware_variant = firmware_variant,
    )

def _create_camera(
        id,
        media_profile_suffix = None,
        feature_front = None,
        feature_back = None,
        feature_autofocus = None):
    """Builds android_hal_config proto for a camera."""

    return android_component_pb.CameraConfigurationType(
        id = id,
        media_profile_suffix = media_profile_suffix,
        feature_front = feature_front,
        feature_back = feature_back,
        feature_autofocus = feature_autofocus,
    )

def _create_storage(
        id,
        storage_type = None):
    """Builds android_hal_config proto for a Storage."""

    return android_component_pb.StorageConfigurationType(
        id = id,
        storage_type = storage_type,
    )

def _create_keyboard(
        id,
        backlight_support = None,
        kb_default_brightness = None,
        kb_backlight_steps = None):
    """Builds android_hal_config proto for a keyboard."""

    return android_component_pb.KeyboardConfigurationType(
        id = id,
        backlight_support = backlight_support,
        kb_default_brightness = kb_default_brightness,
        kb_backlight_steps = kb_backlight_steps,
    )

def _create_stylus(
        id,
        stylus_type = None):
    """Builds android_hal_config proto for a stylus."""

    return android_component_pb.StylusConfigurationType(
        id = id,
        stylus_type = stylus_type,
    )

def _create_firmware(
        id,
        firmware_manifest_key = None,
        firmware_config = None,
        ufsc = None):
    """Builds android_hal_config proto for a firmware config."""

    return android_component_pb.FirmwareConfigurationType(
        id = id,
        firmware_manifest_key = firmware_manifest_key,
        firmware_config = firmware_config,
        ufsc = ufsc,
    )

def _create_touchscreen(
        id,
        screen_size = None):
    """Builds android_hal_config proto for a touch screen."""

    return android_component_pb.TouchscreenConfigurationType(
        id = id,
        screen_size = screen_size,
    )

def _create_touchpad(id):
    """Builds android_hal_config proto for a touchpad."""

    return android_component_pb.TouchpadConfigurationType(
        id = id,
    )

def _create_video(
        id,
        video_codec_suffix = None):
    """Builds android_hal_config proto for a video codec."""

    return android_component_pb.VideoConfigurationType(
        id = id,
        video_codec_suffix = video_codec_suffix,
    )

def _create_hwfeature(
        id,
        form_factor = None,
        touchscreen_support = None):
    """Builds android_hal_config proto for a hw_feature."""

    return android_component_pb.HardwareFeatureConfigurationType(
        id = id,
        form_factor = form_factor,
        touchscreen_support = touchscreen_support,
    )

def _create_sensor(
        id,
        feature_base_accelerometer = None,
        feature_lid_accelerometer = None,
        feature_base_gyroscope = None,
        feature_lid_gyroscope = None,
        feature_camera_lightsensor = None,
        feature_lid_lightsensor = None,
        feature_base_lightsensor = None):
    """Builds android_hal_config proto for sensor configuration."""

    return android_component_pb.SensorConfigurationType(
        id = id,
        feature_base_accelerometer = feature_base_accelerometer,
        feature_lid_accelerometer = feature_lid_accelerometer,
        feature_base_gyroscope = feature_base_gyroscope,
        feature_lid_gyroscope = feature_lid_gyroscope,
        feature_camera_lightsensor = feature_camera_lightsensor,
        feature_lid_lightsensor = feature_lid_lightsensor,
        feature_base_lightsensor = feature_base_lightsensor,
    )

def _create_hal_config(
        audio_configurations = None,
        fingerprint_configurations = None,
        cellular_configurations = None,
        camera_configurations = None,
        storage_configurations = None,
        keyboard_configurations = None,
        stylus_configurations = None,
        firmware_configurations = None,
        touchscreen_configurations = None,
        touchpad_configurations = None,
        video_configurations = None,
        hwfeature_configurations = None,
        sensor_configurations = None):
    """Builds a HalConfiguration proto."""

    return android_component_pb.HalConfiguration(
        audio_list = audio_configurations,
        fingerprint_list = fingerprint_configurations,
        cellular_list = cellular_configurations,
        camera_list = camera_configurations,
        storage_list = storage_configurations,
        keyboard_list = keyboard_configurations,
        stylus_list = stylus_configurations,
        firmware_list = firmware_configurations,
        touchscreen_list = touchscreen_configurations,
        touchpad_list = touchpad_configurations,
        video_list = video_configurations,
        hwfeature_list = hwfeature_configurations,
        sensor_list = sensor_configurations,
    )

android_hal_config = struct(
    create_audio = _create_audio,
    create_fingerprint = _create_fingerprint,
    create_cellular = _create_cellular,
    create_camera = _create_camera,
    create_storage = _create_storage,
    create_keyboard = _create_keyboard,
    create_stylus = _create_stylus,
    create_firmware = _create_firmware,
    create_touchscreen = _create_touchscreen,
    create_touchpad = _create_touchpad,
    create_video = _create_video,
    create_hwfeature = _create_hwfeature,
    create_sensor = _create_sensor,
    create_hal_config = _create_hal_config,
    gen_file = generate.gen_file,
    generate = generate.generate,
)
