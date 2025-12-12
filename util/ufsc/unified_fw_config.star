# Copyright 2025 Google LLC. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Starlark API for creating and encoding unified firmware configurations.

This module provides APIs to:
1. Instantiate the FirmwareConfig proto.
2. Encode the proto into the 4-DWORD (16-byte) binary format specified
   by the firmware configuration schema.
"""

load(
    "@proto//chromiumos/config/api/software/unified_fw_config.proto",
    fw_config_pb = "chromiumos.config.api.software",
)

_schema_dict = json.decode(io.read_file("unified_fw_config_schema.json"))
UNIFIED_FW_CONFIG_SCHEMA = struct(**{
    field_name: struct(**field_props)
    for field_name, field_props in _schema_dict.items()
    if not field_name.startswith("_")  # skip metadata
})

def _validate_ufsc_schema():
    """
    Check for UFSC schema validity

    Checks the loaded schema for:
    1. Invalid ranges (start_bit > end_bit)
    2. Bit overlaps between fields within the same DWORD.

    """
    dword_map = {}

    for field_name in dir(UNIFIED_FW_CONFIG_SCHEMA):
        entry = getattr(UNIFIED_FW_CONFIG_SCHEMA, field_name)

        if entry.start_bit > entry.end_bit:
            fail("Schema field Error: Field '%s' has start_bit (%d) > end_bit (%d)." % (
                field_name,
                entry.start_bit,
                entry.end_bit,
            ))

        if entry.dword not in dword_map:
            dword_map[entry.dword] = []

        dword_map[entry.dword].append((entry.start_bit, entry.end_bit, field_name))

    for dword_idx, intervals in dword_map.items():
        sorted_intervals = sorted(intervals)

        for i in range(len(sorted_intervals) - 1):
            current_field = sorted_intervals[i]
            next_field = sorted_intervals[i + 1]

            c_start, c_end, c_name = current_field
            n_start, n_end, n_name = next_field

            # Check overlap
            if n_start <= c_end:
                fail((
                    "Schema Field Overlap Error: Bit Overlap detected in DWORD {dword}.\n" +
                    "  Field '{name1}' range [{s1}:{e1}]\n" +
                    "  Field '{name2}' range [{s2}:{e2}]\n"
                ).format(
                    dword = dword_idx,
                    name1 = c_name,
                    s1 = c_start,
                    e1 = c_end,
                    name2 = n_name,
                    s2 = n_start,
                    e2 = n_end,
                ))

_validate_ufsc_schema()

def _set_bits(dword, value, start_bit, end_bit):
    """Sets a value into a bit range within a DWORD."""
    if value == None:
        value = 0

    size = end_bit - start_bit + 1
    if size <= 0:
        fail("Bit size must be positive, but got size %d for [%d:%d]" % (size, end_bit, start_bit))

    max_val = (1 << size) - 1
    if value < 0 or value > max_val:
        fail("Value %s is out of range for %d bits ([%d:%d]), max is %d" % (value, size, end_bit, start_bit, max_val))

    mask = max_val << start_bit
    return (dword & ~mask) | (value << start_bit)

def _add_field(dwords, schema_entry, proto_value):
    """Helper to add a single field's value to the correct dword list slot."""
    if schema_entry.dword >= len(dwords):
        fail("Schema entry %s specifies DWORD %d, which is out of range." % (
            schema_entry,
            schema_entry.dword,
        ))

    dwords[schema_entry.dword] = _set_bits(
        dwords[schema_entry.dword],
        proto_value,
        schema_entry.start_bit,
        schema_entry.end_bit,
    )

def _encode_to_dwords(fw_config_proto):
    """
    Encodes a FirmwareConfig proto into a list of 4 DWORDs.

    This function is generic and iterates over UNIFIED_FW_CONFIG_SCHEMA.

    Args:
        fw_config_proto: An instance of the software.FirmwareConfig proto.

    Returns:
        list[int]: A list of four 32-bit integers representing the encoded config.
    """
    dwords = [0, 0, 0, 0]

    for schema_key in dir(UNIFIED_FW_CONFIG_SCHEMA):
        schema_entry = getattr(UNIFIED_FW_CONFIG_SCHEMA, schema_key)
        proto_field_name = schema_key.lower()
        proto_field = getattr(fw_config_proto, proto_field_name, None)
        if proto_field == None:
            fail("Error: Field '%s' (derived from schema key '%s') was not found in the fw_config_proto." % (
                proto_field_name,
                schema_key,
            ))
        _add_field(dwords, schema_entry, proto_field)

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
        sensor_hub = None,
        fingerprint_interface = None,
        wifi_interface = None,
        trackpad = None,
        trackpad_probe_type = None,
        trackpad_soc_interface = None,
        cellular_interface = None,
        form_factor = None,
        keyboard_layout = None,
        panel_id = None,
        stylus = None,
        # EC Fields
        kb_backlight = None,
        kb_num_pad = None,
        thermal_fan = None,
        lid_sensor = None,
        base_sensor = None,
        tablet_mode_base_orientation = None,
        charger_chip = None,
        pdc_chip_vendor_port_0 = None,
        pdc_chip_vendor_port_1 = None,
        pdc_chip_vendor_port_2 = None,
        pdc_chip_vendor_port_3 = None,
        ap_oem_3bit_field0 = None,
        ap_oem_2bit_field0 = None,
        ap_oem_2bit_field1 = None,
        ap_oem_1bit_field0 = None,
        ec_oem_3bit_field0 = None,
        ec_oem_2bit_field0 = None,
        ec_oem_2bit_field1 = None,
        ec_oem_1bit_field0 = None):
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
        sensor_hub = sensor_hub,
        fingerprint_interface = fingerprint_interface,
        wifi_interface = wifi_interface,
        trackpad = trackpad,
        trackpad_probe_type = trackpad_probe_type,
        trackpad_soc_interface = trackpad_soc_interface,
        cellular_interface = cellular_interface,
        form_factor = form_factor,
        keyboard_layout = keyboard_layout,
        panel_id = panel_id,
        stylus = stylus,
        # EC Fields
        kb_backlight = kb_backlight,
        kb_num_pad = kb_num_pad,
        thermal_fan = thermal_fan,
        lid_sensor = lid_sensor,
        base_sensor = base_sensor,
        tablet_mode_base_orientation = tablet_mode_base_orientation,
        charger_chip = charger_chip,
        pdc_chip_vendor_port_0 = pdc_chip_vendor_port_0,
        pdc_chip_vendor_port_1 = pdc_chip_vendor_port_1,
        pdc_chip_vendor_port_2 = pdc_chip_vendor_port_2,
        pdc_chip_vendor_port_3 = pdc_chip_vendor_port_3,
        ap_oem_3bit_field0 = ap_oem_3bit_field0,
        ap_oem_2bit_field0 = ap_oem_2bit_field0,
        ap_oem_2bit_field1 = ap_oem_2bit_field1,
        ap_oem_1bit_field0 = ap_oem_1bit_field0,
        ec_oem_3bit_field0 = ec_oem_3bit_field0,
        ec_oem_2bit_field0 = ec_oem_2bit_field0,
        ec_oem_2bit_field1 = ec_oem_2bit_field1,
        ec_oem_1bit_field0 = ec_oem_1bit_field0,
    )

unified_fw_config = struct(
    create = _create_firmware_config,
    encode_to_dwords = _encode_to_dwords,
)
