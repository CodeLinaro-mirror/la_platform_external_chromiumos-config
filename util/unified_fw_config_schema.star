"""
Defines the UNIFIED_FW_CONFIG_SCHEMA struct.

This file is the "Single Source of Truth" for the firmware
config bit field layout and is loaded by unified_fw_config.star.
"""

# -----------------------------------------------------------------------------
# !! IMPORTANT !!
# When adding or renaming a field in this file, you must also make
# corresponding changes in these two files:
#
# 1.  `unified_fw_config.proto`:
#     Add/rename the matching proto field. The proto field name MUST
#     be the lowercase version of the schema key.
#     Example: `PDC_CHIP_VENDOR_PORT_0` -> `pdc_chip_vendor_port_0`
#
# 2.  `unified_fw_config.star` (`_create_firmware_config` function):
#     Add/rename the matching function argument, which must also
#     be the lowercase version of the schema key.
#     Example: `pdc_chip_vendor_port_0 = None`
# -----------------------------------------------------------------------------

# Define the unified firmware configuration schema layout.
# This struct acts as the "Single Source of Truth" for bit packing.
# USED_BY field must be "AP", "EC", or "BOTH".
UNIFIED_FW_CONFIG_SCHEMA = struct(
    # DWORD 0
    AUDIO_CODEC = struct(DWORD = 0, START = 0, END = 2, USED_BY = "AP"),
    AUDIO_AMPLIFIER = struct(DWORD = 0, START = 3, END = 5, USED_BY = "AP"),
    CAMERA_UFC_NAME = struct(DWORD = 0, START = 6, END = 8, USED_BY = "AP"),
    CAMERA_WFC_NAME = struct(DWORD = 0, START = 9, END = 11, USED_BY = "AP"),
    STORAGE_TYPE = struct(DWORD = 0, START = 12, END = 14, USED_BY = "AP"),
    SD_CARD_CONTROLLER = struct(DWORD = 0, START = 15, END = 16, USED_BY = "AP"),
    TOUCHSCREEN = struct(DWORD = 0, START = 17, END = 18, USED_BY = "AP"),
    TOUCHSCREEN_PROBE_TYPE = struct(DWORD = 0, START = 19, END = 20, USED_BY = "AP"),
    TOUCHSCREEN_SOC_INTERFACE = struct(DWORD = 0, START = 21, END = 22, USED_BY = "AP"),
    SENSOR_HUB_PRESENT = struct(DWORD = 0, START = 23, END = 23, USED_BY = "BOTH"),
    FINGERPRINT_PRESENT = struct(DWORD = 0, START = 24, END = 24, USED_BY = "AP"),
    WIFI_INTERFACE = struct(DWORD = 0, START = 25, END = 26, USED_BY = "AP"),
    CELLULAR_INTERFACE = struct(DWORD = 0, START = 27, END = 28, USED_BY = "AP"),
    FORM_FACTOR = struct(DWORD = 0, START = 29, END = 30, USED_BY = "BOTH"),
    STYLUS_PRESENT = struct(DWORD = 0, START = 31, END = 31, USED_BY = "AP"),

    # DWORD 1
    TRACKPAD = struct(DWORD = 1, START = 0, END = 2, USED_BY = "AP"),
    TRACKPAD_PROBE_TYPE = struct(DWORD = 1, START = 3, END = 4, USED_BY = "AP"),
    TRACKPAD_SOC_INTERFACE = struct(DWORD = 1, START = 5, END = 6, USED_BY = "AP"),
    PANEL_ID = struct(DWORD = 1, START = 7, END = 10, USED_BY = "AP"),
    KB_BACKLIGHT_PRESENT = struct(DWORD = 1, START = 11, END = 11, USED_BY = "BOTH"),
    KB_NUM_PAD_PRESENT = struct(DWORD = 1, START = 12, END = 12, USED_BY = "BOTH"),
    KEYBOARD_COMPONENT_NAME = struct(DWORD = 1, START = 13, END = 15, USED_BY = "BOTH"),

    # DWORD 2
    FAN_PRESENT = struct(DWORD = 2, START = 0, END = 0, USED_BY = "EC"),
    LID_SENSOR = struct(DWORD = 2, START = 1, END = 3, USED_BY = "EC"),
    BASE_SENSOR = struct(DWORD = 2, START = 4, END = 6, USED_BY = "EC"),
    TABLET_MODE_BASE_ORIENTATION = struct(DWORD = 2, START = 7, END = 7, USED_BY = "EC"),
    CHARGER_CHIP = struct(DWORD = 2, START = 8, END = 10, USED_BY = "EC"),
    PDC_CHIP_VENDOR_PORT_0 = struct(DWORD = 2, START = 11, END = 12, USED_BY = "EC"),
    PDC_CHIP_VENDOR_PORT_1 = struct(DWORD = 2, START = 13, END = 14, USED_BY = "EC"),
    PDC_CHIP_VENDOR_PORT_2 = struct(DWORD = 2, START = 15, END = 16, USED_BY = "EC"),
    PDC_CHIP_VENDOR_PORT_3 = struct(DWORD = 2, START = 17, END = 18, USED_BY = "EC"),
)
