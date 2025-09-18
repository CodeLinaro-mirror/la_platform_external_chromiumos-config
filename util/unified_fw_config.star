# Copyright 2025 Google LLC. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Starlark API for creating and encoding unified firmware configurations.

This module provides APIs to:
1. Instantiate the FirmwareConfig proto.
2. Encode the proto into the 3-DWORD (12-byte) binary format specified
   by the firmware configuration schema.
"""

load(
    "@proto//chromiumos/config/api/software/unified_fw_config.proto",
    fw_config_pb = "chromiumos.config.api.software",
)

# Define the unified firmware configuration schema layout.
# This struct acts as the "Single Source of Truth" for bit packing.
_UNIFIED_FW_CONFIG_SCHEMA = struct(
    # DWORD 0
    AUDIO_CODEC = struct(DWORD = 0, START = 0, END = 2),
    AUDIO_AMPLIFIER = struct(DWORD = 0, START = 3, END = 5),
    AUDIO_BUS_TYPE = struct(DWORD = 0, START = 6, END = 7),
    CAMERA_UFC_TYPE = struct(DWORD = 0, START = 8, END = 9),
    CAMERA_UFC_NAME = struct(DWORD = 0, START = 10, END = 12),
    CAMERA_WFC_TYPE = struct(DWORD = 0, START = 13, END = 14),
    CAMERA_WFC_NAME = struct(DWORD = 0, START = 15, END = 17),
    STORAGE_TYPE = struct(DWORD = 0, START = 18, END = 19),
    SD_CARD_CONTROLLER = struct(DWORD = 0, START = 20, END = 21),
    TOUCHSCREEN = struct(DWORD = 0, START = 22, END = 23),
    TOUCHSCREEN_PROBE_TYPE = struct(DWORD = 0, START = 24, END = 25),
    TOUCHSCREEN_SOC_INTERFACE = struct(DWORD = 0, START = 26, END = 27),
    SENSOR_HUB_PRESENT = struct(DWORD = 0, START = 28, END = 28),
    FINGERPRINT_PRESENT = struct(DWORD = 0, START = 29, END = 29),
    WIFI_INTERFACE = struct(DWORD = 0, START = 30, END = 31),

    # DWORD 1
    TRACKPAD = struct(DWORD = 1, START = 0, END = 2),
    TRACKPAD_PROBE_TYPE = struct(DWORD = 1, START = 3, END = 4),
    TRACKPAD_SOC_INTERFACE = struct(DWORD = 1, START = 5, END = 6),
    CELLULAR_INTERFACE = struct(DWORD = 1, START = 7, END = 8),
    FORM_FACTOR = struct(DWORD = 1, START = 9, END = 10),
    KEYBOARD_COMPONENT_NAME = struct(DWORD = 1, START = 11, END = 13),
    PANEL_ID = struct(DWORD = 1, START = 14, END = 17),
    STYLUS_PRESENT = struct(DWORD = 1, START = 18, END = 18),

    # DWORD 2
    KB_BACKLIGHT_PRESENT = struct(DWORD = 2, START = 0, END = 0),
    KB_NUM_PAD_PRESENT = struct(DWORD = 2, START = 1, END = 1),
    THERMAL_FAN_PRESENT = struct(DWORD = 2, START = 2, END = 2),
    LID_SENSOR = struct(DWORD = 2, START = 3, END = 5),
    BASE_SENSOR = struct(DWORD = 2, START = 6, END = 8),
    TABLET_MODE_BASE_ORIENTATION = struct(DWORD = 2, START = 9, END = 9),
    CHARGER_CHIP = struct(DWORD = 2, START = 10, END = 12),
    PDC_CHIP_PORT_0 = struct(DWORD = 2, START = 13, END = 14),
    PDC_CHIP_PORT_1 = struct(DWORD = 2, START = 15, END = 16),
    PDC_CHIP_PORT_2 = struct(DWORD = 2, START = 17, END = 18),
    PDC_CHIP_PORT_3 = struct(DWORD = 2, START = 19, END = 20),
)

def _set_bits(dword, value, start_bit, end_bit):
    """Sets a value into a bit range within a DWORD."""
    if value == None:
        value = 0  # Treat None as 0

    size = end_bit - start_bit + 1
    if size <= 0:
        fail("Bit size must be positive, but got size %d for [%d:%d]" % (size, end_bit, start_bit))

    max_val = (1 << size) - 1
    if value < 0 or value > max_val:
        fail("Value %d is out of range for %d bits ([%d:%d]), max is %d" % (value, size, end_bit, start_bit, max_val))

    mask = max_val << start_bit
    return (dword & ~mask) | (value << start_bit)

def _add_field(dwords, schema_entry, proto_value):
    """Helper to add a single field's value to the correct dword list slot."""
    dwords[schema_entry.DWORD] = _set_bits(
        dwords[schema_entry.DWORD],
        proto_value,
        schema_entry.START,
        schema_entry.END,
    )

def _encode_to_dwords(fw_config_proto):
    """
    Encodes a FirmwareConfig proto into a list of 3 DWORDs.

    Args:
        fw_config_proto: An instance of the software.FirmwareConfig proto.

    Returns:
        list[int]: A list of three 32-bit integers representing the encoded config.
    """
    dwords = [0, 0, 0]

    # --- DWORD 0 ---
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.AUDIO_CODEC, fw_config_proto.audio_codec)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.AUDIO_AMPLIFIER, fw_config_proto.audio_amplifier)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.AUDIO_BUS_TYPE, fw_config_proto.audio_bus_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CAMERA_UFC_TYPE, fw_config_proto.camera_ufc_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CAMERA_UFC_NAME, fw_config_proto.camera_ufc_name)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CAMERA_WFC_TYPE, fw_config_proto.camera_wfc_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CAMERA_WFC_NAME, fw_config_proto.camera_wfc_name)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.STORAGE_TYPE, fw_config_proto.storage_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.SD_CARD_CONTROLLER, fw_config_proto.sd_card_controller)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TOUCHSCREEN, fw_config_proto.touchscreen)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TOUCHSCREEN_PROBE_TYPE, fw_config_proto.touchscreen_probe_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TOUCHSCREEN_SOC_INTERFACE, fw_config_proto.touchscreen_soc_interface)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.SENSOR_HUB_PRESENT, 1 if fw_config_proto.sensor_hub_present else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.FINGERPRINT_PRESENT, 1 if fw_config_proto.fingerprint_present else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.WIFI_INTERFACE, fw_config_proto.wifi_interface)

    # --- DWORD 1 ---
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TRACKPAD, fw_config_proto.trackpad)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TRACKPAD_PROBE_TYPE, fw_config_proto.trackpad_probe_type)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TRACKPAD_SOC_INTERFACE, fw_config_proto.trackpad_soc_interface)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CELLULAR_INTERFACE, fw_config_proto.cellular_interface)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.FORM_FACTOR, fw_config_proto.form_factor)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.KEYBOARD_COMPONENT_NAME, fw_config_proto.keyboard_component_name)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.PANEL_ID, fw_config_proto.panel_id)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.STYLUS_PRESENT, 1 if fw_config_proto.stylus_present else 0)

    # --- DWORD 2 ---
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.KB_BACKLIGHT_PRESENT, 1 if fw_config_proto.kb_backlight_present else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.KB_NUM_PAD_PRESENT, 1 if fw_config_proto.kb_num_pad_present else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.THERMAL_FAN_PRESENT, 1 if fw_config_proto.fan_present else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.LID_SENSOR, fw_config_proto.lid_sensor)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.BASE_SENSOR, fw_config_proto.base_sensor)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.TABLET_MODE_BASE_ORIENTATION, 1 if fw_config_proto.tablet_mode_base_orientation else 0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.CHARGER_CHIP, fw_config_proto.charger_chip)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.PDC_CHIP_PORT_0, fw_config_proto.pdc_chip_vendor_port_0)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.PDC_CHIP_PORT_1, fw_config_proto.pdc_chip_vendor_port_1)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.PDC_CHIP_PORT_2, fw_config_proto.pdc_chip_vendor_port_2)
    _add_field(dwords, _UNIFIED_FW_CONFIG_SCHEMA.PDC_CHIP_PORT_3, fw_config_proto.pdc_chip_vendor_port_3)

    return dwords

def _create_firmware_config(
        # AP Fields
        audio_codec = None,
        audio_amplifier = None,
        audio_bus_type = None,
        camera_ufc_type = None,
        camera_ufc_name = None,
        camera_wfc_type = None,
        camera_wfc_name = None,
        storage_type = None,
        sd_card_controller = None,
        touchscreen = None,
        touchscreen_probe_type = None,
        touchscreen_soc_interface = None,
        sensor_hub_present = None,
        fingerprint_present = None,
        wifi_interface = None,
        trackpad = None,
        trackpad_probe_type = None,
        trackpad_soc_interface = None,
        cellular_interface = None,
        form_factor = None,
        keyboard_component_name = None,
        panel_id = None,
        stylus_present = None,
        # EC Fields
        kb_backlight_present = None,
        kb_num_pad_present = None,
        thermal_fan_present = None,
        lid_sensor = None,
        base_sensor = None,
        tablet_mode_base_orientation = None,
        charger_chip = None,
        pdc_chip_port_0 = None,
        pdc_chip_port_1 = None,
        pdc_chip_port_2 = None,
        pdc_chip_port_3 = None):
    """Builds a FirmwareConfig proto."""

    return fw_config_pb.FirmwareConfig(
        # AP Fields
        audio_codec = audio_codec,
        audio_amplifier = audio_amplifier,
        audio_bus_type = audio_bus_type,
        camera_ufc_type = camera_ufc_type,
        camera_ufc_name = camera_ufc_name,
        camera_wfc_type = camera_wfc_type,
        camera_wfc_name = camera_wfc_name,
        storage_type = storage_type,
        sd_card_controller = sd_card_controller,
        touchscreen = touchscreen,
        touchscreen_probe_type = touchscreen_probe_type,
        touchscreen_soc_interface = touchscreen_soc_interface,
        sensor_hub_present = sensor_hub_present,
        fingerprint_present = fingerprint_present,
        wifi_interface = wifi_interface,
        trackpad = trackpad,
        trackpad_probe_type = trackpad_probe_type,
        trackpad_soc_interface = trackpad_soc_interface,
        cellular_interface = cellular_interface,
        form_factor = form_factor,
        keyboard_component_name = keyboard_component_name,
        panel_id = panel_id,
        stylus_present = stylus_present,
        # EC Fields
        kb_backlight_present = kb_backlight_present,
        kb_num_pad_present = kb_num_pad_present,
        fan_present = thermal_fan_present,
        lid_sensor = lid_sensor,
        base_sensor = base_sensor,
        tablet_mode_base_orientation = tablet_mode_base_orientation,
        charger_chip = charger_chip,
        pdc_chip_vendor_port_0 = pdc_chip_port_0,
        pdc_chip_vendor_port_1 = pdc_chip_port_1,
        pdc_chip_vendor_port_2 = pdc_chip_port_2,
        pdc_chip_vendor_port_3 = pdc_chip_port_3,
    )

unified_fw_config = struct(
    create = _create_firmware_config,
    encode_to_dwords = _encode_to_dwords,
)
