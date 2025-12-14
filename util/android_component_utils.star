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
        soundcard):
    """Builds android_hal_config proto for an audio component."""

    return android_component_pb.AudioConfigurationType(
        id = id,
        soundcard = soundcard,
    )

def _create_fingerprint(
        id,
        board,
        fingerprint_sensor_type,
        sensor_location,
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
        modem_type,
        firmware_variant):
    """Builds android_hal_config proto for a cellular modem."""

    return android_component_pb.CellularConfigurationType(
        id = id,
        modem_type = modem_type,
        firmware_variant = firmware_variant,
    )

def _create_hal_config(
        audio_configurations = None,
        fingerprint_configurations = None,
        cellular_configurations = None):
    """Builds a HalConfiguration proto."""

    return android_component_pb.HalConfiguration(
        audio_list = audio_configurations,
        fingerprint_list = fingerprint_configurations,
        cellular_list = cellular_configurations,
    )

android_hal_config = struct(
    create_audio = _create_audio,
    create_fingerprint = _create_fingerprint,
    create_cellular = _create_cellular,
    create_hal_config = _create_hal_config,
    gen_file = generate.gen_file,
    generate = generate.generate,
)
