#!/usr/bin/env gen_config

load("//config/util/brand_config.star", "brand_config")
load("//config/util/component.star", "comp")
load("//config/util/config_bundle.star", "config_bundle")
load("//config/util/design.star", "design")
load("//config/util/device_brand.star", "device_brand")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/partner.star", "partner")
load("//config/util/sw_config.star", sc = "sw_config")
load("//program/program.star", "program")

_FAKE_ODM = partner.create("FAKE_ODM")
_FAKE_OEM = partner.create("FAKE_OEM")
_FAKE_OEMA = partner.create("FAKE_OEMA")
_FAKE_OEMB = partner.create("FAKE_OEMB")
_FAKE_OEMC = partner.create("FAKE_OEMC")
_FAKE_OEMD = partner.create("FAKE_OEMD")
_FAKE_OEME = partner.create("FAKE_OEME")
_FAKE_LOEMA = partner.create("FAKE_LOEMA")
_FAKE_LOEMB = partner.create("FAKE_LOEMB")
_FAKE_LOEMC = partner.create("FAKE_LOEMC")

_ODMS = [_FAKE_ODM]
_OEMS = [_FAKE_OEM, _FAKE_OEMA, _FAKE_OEMB, _FAKE_OEMC, _FAKE_OEMD, _FAKE_OEME, _FAKE_LOEMA, _FAKE_LOEMB, _FAKE_LOEMC]
_COMPONENTS = []
_COMPONENT_VENDORS = []

_REF_DESIGN_NAME = "FAKE_REF_DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)
_DESIGN_ID_A = design.create_design_id("PROJECT_A")
_DESIGN_ID_B = design.create_design_id("PROJECT_B")
_DESIGN_ID_C = design.create_design_id(
    "PROJECT_C",
    config_design_id_override = _DESIGN_ID_B,
)
_DESIGN_ID_D = design.create_design_id(
    "PROJECT_D",
    model_name_design_id_override = _DESIGN_ID_C,
)
_DESIGN_ID_E = design.create_design_id("PROJECT_E")
_DESIGN_ID_WL = design.create_design_id("PROJECT_WL")
_DESIGN_ID_REBRAND = design.create_design_id("PROJECT_REBRAND")
_DESIGN_ID_BOX = design.create_design_id("PROJECT_BOX")

_FORM_FACTOR_CLAMSHELL = hw_topo.create_form_factor(hw_topo.ff.CLAMSHELL)
_FORM_FACTOR_CLAMSHELL_POWER_RECOV = hw_topo.create_form_factor(
    hw_topo.ff.CLAMSHELL,
    hw_topo.recovery_input.POWER_BUTTON,
)
_FORM_FACTOR_CONVERTIBLE = hw_topo.create_form_factor(hw_topo.ff.CONVERTIBLE)
_FORM_FACTOR_CHROMEBOX = hw_topo.create_form_factor(hw_topo.ff.CHROMEBOX)
_FORM_FACTOR_CHROMEBASE = hw_topo.create_form_factor(hw_topo.ff.CHROMEBASE, detachable_ui = True)
_FORM_FACTOR_DETACHABLE = hw_topo.create_form_factor(hw_topo.ff.DETACHABLE)
_FORM_FACTOR_CHROMESLATE = hw_topo.create_form_factor(hw_topo.ff.CHROMESLATE)
_SCREEN = hw_topo.create_screen(
    id = "SCREEN",
    description = "Default screen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 280,
    touch = False,
    min_visible_backlight_level = 1000,
    turn_off_screen_timeout_ms = 0,
    no_als_battery_brightness = 63.2,
    no_als_ac_brightness = 80.1,
    als_steps = [
        hw_topo.create_als_step(None, 400, 80.1, 60.1),
        hw_topo.create_als_step(100, None, 100),
    ],
    seamless_refresh_rate_switching = True,
    privacy_screen = False,
    rounded_corners = comp.create_rounded_corners(15),
    variable_refresh_rate_available = True,
)
_TOUCHSCREEN = hw_topo.create_screen(
    id = "TOUCHSCREEN",
    description = "Touchscreen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 120,
    touch = True,
    turn_off_screen_timeout_ms = 3000,
    no_als_ac_brightness_nits = 135,
    max_brightness_nits = 215,
    als_steps = [
        hw_topo.create_als_step(
            None,
            400,
            ac_backlight_nits = 133,
            battery_backlight_nits = 80,
        ),
        hw_topo.create_als_step(100, None, ac_backlight_nits = 215),
    ],
    privacy_screen = False,
)
_PRIVACY_SCREEN = hw_topo.create_screen(
    id = "PRIVACY_SCREEN",
    description = "Privacy screen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 280,
    touch = False,
    min_visible_backlight_level = 1000,
    turn_off_screen_timeout_ms = 0,
    no_als_battery_brightness = 63.2,
    no_als_ac_brightness = 80.1,
    als_steps = [
        hw_topo.create_als_step(None, 400, 80.1, 60.1),
        hw_topo.create_als_step(100, None, 100),
    ],
    seamless_refresh_rate_switching = True,
    privacy_screen = True,
    variable_refresh_rate_available = False,
)

_OLED_TOUCHSCREEN = hw_topo.create_screen(
    id = "OLED_TOUCHSCREEN",
    description = "OLED Touchscreen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 120,
    touch = True,
    turn_off_screen_timeout_ms = 3000,
    no_als_ac_brightness_nits = 135,
    max_brightness_nits = 215,
    panel_type = hw_topo.panel_type.OLED,
    als_steps = [
        hw_topo.create_als_step(
            None,
            400,
            ac_backlight_nits = 133,
            battery_backlight_nits = 80,
        ),
        hw_topo.create_als_step(100, None, ac_backlight_nits = 215),
    ],
)

_HDMI = hw_topo.create_hdmi(
    id = "HDMI",
    description = "HDMI port",
)
_HDMI_CEC_POWER_ON = hw_topo.create_hdmi(
    id = "HDMI",
    description = "HDMI port with CEC power on",
    cec = hw_topo.create_hdmi_cec(
        power_on_displays_on_boot = True,
    ),
)

_AUDIO_CARD = "fakeaudiocard"
_AUDIO = hw_topo.create_audio(
    "AUDIO",
    "Default audio",
    headphone_codec = hw_topo.audio_codec.ALC5682I,
    card_configs = [hw_topo.create_audio_card_config(
        card_name = _AUDIO_CARD,
    )],
)
_AUDIO_WITH_INIT = hw_topo.create_audio(
    "AUDIO",
    "Default audio",
    speaker_amp = hw_topo.amplifier.MAX98373,
    headphone_codec = hw_topo.audio_codec.ALC5682I,
    card_configs = [
        hw_topo.create_audio_card_config(
            card_name = _AUDIO_CARD + ".card_suffix",
            sound_card_init_config = hw_topo.audio_config_structure.DESIGN,
        ),
    ],
)
_AUDIO_WITH_UNDERSCORE = hw_topo.create_audio(
    "AUDIO",
    "Default audio",
    speaker_amp = hw_topo.amplifier.ALC5650,
    headphone_codec = hw_topo.audio_codec.ALC5650,
    card_configs = [hw_topo.create_audio_card_config(
        card_name = _AUDIO_CARD,
    )],
)

_AUDIO_WITH_CUSTOM_MIC_SUFFIX = hw_topo.override_audio(
    _AUDIO_WITH_INIT,
    ucm_suffix = "{speaker_amp}.{headset_codec}.{camera_count}pos.{user_facing_mic_count}uf{world_facing_mic_count}wf{total_mic_count}total.{design}",
    ucm_config = hw_topo.audio_config_structure.COMMON,
    cras_config = hw_topo.audio_config_structure.COMMON,
)

_AUDIO_WITH_FIXED_SUFFIX = hw_topo.override_audio(
    _AUDIO_WITH_INIT,
    ucm_suffix = "fixed_suffix",
    ucm_config = hw_topo.audio_config_structure.DESIGN,
)

_AUDIO_WITH_CUSTOM_MIC_SUFFIX_AND_CRAS_SUFFIX = hw_topo.override_audio(
    _AUDIO_WITH_INIT,
    ucm_suffix = "{speaker_amp}.{headset_codec}.{camera_count}pos.{user_facing_mic_count}uf{world_facing_mic_count}wf{total_mic_count}total.{design}",
    cras_suffix = "{speaker_amp}.{headset_codec}.{camera_count}pos.{user_facing_mic_count}uf{world_facing_mic_count}wf{total_mic_count}total.{design}",
    ucm_config = hw_topo.audio_config_structure.COMMON,
    cras_config = hw_topo.audio_config_structure.COMMON,
)

_STYLUS = hw_topo.create_stylus(
    "STYLUS",
    "Default stylus",
    stylus_type = hw_topo.stylus.INTERNAL,
)

_NO_STYLUS = hw_topo.create_stylus(
    "NO_STYLUS",
    "No Stylus",
    stylus_type = hw_topo.stylus.NONE,
)

_DGPU = hw_topo.create_dgpu(
    "NV3050",
    "Default dGPU",
    dgpu_type = hw_topo.dgpu.DGPU_NV3050,
)

_DSP_ISH = hw_topo.create_dsp(
    "ISH",
    "Intel ISH",
    dsp_vendor = hw_topo.dsp.DSP_VENDOR_INTEL,
)

_UWB = hw_topo.create_uwb(
    "UWB",
    "Default UWB",
)

_SOC = hw_topo.create_soc(
    "SOC",
    "Default SoC",
    arc_media_codecs_suffix = "mainstream",
    hevc_support = False,
    resource = sc.create_resource(
        ac = sc.create_power_source_preference(
            default = sc.create_power_preference(
                epp = sc.create_power_epp(),
            ),
        ),
    ),
)

_BL_KEYBOARD = hw_topo.create_keyboard(
    backlight = True,
    pwr_btn_present = False,
    kb_type = hw_topo.kb_type.INTERNAL,
    numpad_present = True,
    backlight_user_steps = [0, 10, 20, 40, 60, 100],
    no_als_brightness = 40,
    als_steps = [
        hw_topo.create_kb_als_step(None, 20, 40),
        hw_topo.create_kb_als_step(15, None, 0),
    ],
    mcu_type = hw_topo.kb_mcu_type.MCU_PRISM,
)

_KEYBOARD_WITH_LAYOUT = hw_topo.create_keyboard(
    backlight = True,
    pwr_btn_present = False,
    kb_type = hw_topo.kb_type.INTERNAL,
    numpad_present = True,
    bottom_left_layout = hw_topo.kb_bottom_left_layout.BOTTOM_LEFT_3_KEYS,
    bottom_right_layout = hw_topo.kb_bottom_right_layout.BOTTOM_RIGHT_2_KEYS,
    numeric_pad_layout = hw_topo.kb_numeric_pad_layout.NUMERIC_PAD_4_COLUMN,
)

_KEYBOARD = hw_topo.create_keyboard(
    backlight = False,
    pwr_btn_present = False,
    kb_type = hw_topo.kb_type.DETACHABLE,
    numpad_present = False,
)

_THERMAL = hw_topo.create_thermal(
    "THERMAL",
    "Default thermal",
    config_path_suffix = "default",
)
_CAMERA0 = hw_topo.create_camera(
    "CAMERA0",
    "No cameras",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.CAMERA, 1)],
    camera_devices = [],
)
_CAMERA1 = hw_topo.create_camera(
    "CAMERA1",
    "1 USB camera",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.CAMERA, 2)],
    camera_devices = [
        hw_topo.make_camera_device(
            interface = "usb",
            facing = "front",
            orientation = 0,
            flags = 0,
            ids = ["0123:abcd"],
            privacy_switch_present = False,
            microphone_count = 2,
        ),
    ],
)
_CAMERA2 = hw_topo.create_camera(
    "CAMERA2",
    "1 USB camera and 1 MIPI camera",
    fw_configs = [hw_topo.make_fw_config(
        program.fw_masks.CAMERA,
        0,
        coreboot_customizations = ["2cameras", "1custom"],
    )],
    camera_devices = [
        hw_topo.make_camera_device(
            interface = "usb",
            facing = "front",
            orientation = 0,
            flags = hw_topo.camera_flags.SUPPORT_AUTOFOCUS,
            ids = ["0123:abcd"],
            privacy_switch_present = True,
            microphone_count = 1,
        ),
        hw_topo.make_camera_device(
            interface = "mipi",
            facing = "back",
            orientation = 180,
            flags = hw_topo.camera_flags.SUPPORT_1080P | hw_topo.camera_flags.SUPPORT_AUTOFOCUS,
            ids = ["mipi-cam"],
            microphone_count = 2,
        ),
    ],
)
_SENSOR = hw_topo.create_sensor(
    "SENSOR",
    "Default sensor",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)],
    base_accel_present = True,
    base_gyro_present = True,
    base_magno_present = True,
)
_SENSOR_WITH_LIGHT = hw_topo.create_sensor(
    "SENSOR with ALS",
    "Default sensor plus light sensor",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)],
    base_accel_present = True,
    base_gyro_present = True,
    base_magno_present = True,
    lid_light_present = True,
    base_light_present = True,
    camera_light_present = True,
)
_FINGERPRINT = hw_topo.create_fingerprint(
    "FINGERPRINT",
    "Default fingerprint",
    present = True,
    location = hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT,
    board = "fake_fingerprint_board",
    fingerprint_diag = hw_topo.create_fingerprint_diag(
        routine_enable = True,
        max_pixel_dev = 5,
        max_dead_pixels = 5,
        pixel_median = hw_topo.create_fingerprint_diag_pixel_median(
            cb_type1_lower = 1,
            cb_type1_upper = 2,
            cb_type2_lower = 3,
            cb_type2_upper = 4,
            icb_type1_lower = 5,
            icb_type1_upper = 6,
            icb_type2_lower = 7,
            icb_type2_upper = 8,
        ),
        num_detect_zone = 2,
        detect_zones = [hw_topo.create_fingerprint_diag_detect_zone(
            x1 = 10,
            y1 = 20,
            x2 = 30,
            y2 = 40,
        ), hw_topo.create_fingerprint_diag_detect_zone(
            x1 = 50,
            y1 = 60,
            x2 = 70,
            y2 = 80,
        )],
        max_dead_pixels_in_detect_zone = 0,
        max_reset_pixel_dev = 5,
        max_error_reset_pixels = 5,
    ),
)
_NO_FINGERPRINT = hw_topo.create_fingerprint(
    "NONE",
    "No finger print sensor",
    present = False,
)
_HPS = hw_topo.create_hps("HPS", "Default Hps", present = True)
_PROXIMITY_SENSOR = hw_topo.create_proximity_sensor(
    "PROXIMITY_SENSOR",
    "Default proximity_sensor",
)
_NO_PROXIMITY_SENSOR = None
_DAUGHTER_BOARD = hw_topo.create_daughter_board(
    "Default DB",
    "Default daughter_board",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 1)],
    side = hw_topo.port_position.RIGHT,
    usbc_ports = [hw_topo.create_usbc_port(index_override = 1)],
    usb4 = True,
)
_NON_VOLATILE_STORAGE = hw_topo.create_non_volatile_storage(
    "NON_VOLATILE_STORAGE",
    "Default non_volatile_storage",
    storage_type = hw_topo.storage.EMMC,
)
_WIFI6 = hw_topo.create_wifi(
    "WIFI6",
    "Default wifi",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.WIFI_SAR_ID, 6)],
)
_REGULATORY_DOMAIN_MAPPING = {
    "CE": 4,
    "ISED": 2,
    "MIC": 4,
}
_POWER_LEVEL_MAPPING = {
    "HIGH": 1,
    "LOW": 2,
}
_LTE_BOARD = hw_topo.create_cellular_board(
    "LTE_BOARD",
    "Default cellular_board",
    present = True,
    type = hw_topo.cellular.CELLULAR_LTE,
    dynamic_power_reduction_config = hw_topo.make_cellular_dynamic_power_reduction_config(
        modem_manager = True,
        multi_power_level_sar = True,
        default_proximity_state_far = True,
        tablet_mode = True,
        regulatory_domain_mapping = _REGULATORY_DOMAIN_MAPPING,
        power_level_mapping = _POWER_LEVEL_MAPPING,
    ),
    wedge_timeout_in_ms = 120000,
)
_LTE_BOARD_WITH_MODEL = hw_topo.create_cellular_board(
    "LTE_BOARD_MODEL",
    "Default cellular_board w/ model",
    present = True,
    type = hw_topo.cellular.CELLULAR_LTE,
    modem_type = hw_topo.modem.MODEM_FM101,
    model = "FakeModem",
    dynamic_power_reduction_config = hw_topo.make_cellular_dynamic_power_reduction_config(gpio = 0, tablet_mode = True),
)
_LTE_BOARD_WITH_NO_DPR = hw_topo.create_cellular_board(
    "LTE_BOARD_NO_DPR",
    "Default cellular_board without dynamic power reduction config",
    present = True,
    type = hw_topo.cellular.CELLULAR_LTE,
    modem_type = hw_topo.modem.MODEM_L850,
    dynamic_power_reduction_config = None,
    wedge_timeout_in_ms = 180000,
)
_SD_READER = hw_topo.create_sd_reader(
    "SD_READER",
    "Default sd_reader",
    present = True,
)
_NO_SD_READER = hw_topo.create_sd_reader(
    "SD_READER",
    "No sd_reader",
    present = False,
)
_MOTHERBOARD_USB = hw_topo.create_motherboard_usb(
    "MOTHERBOARD_USB",
    "Default motherboard_usb",
    side = hw_topo.port_position.LEFT,
    usbc_ports = [
        hw_topo.create_usbc_port(hw_topo.port_position.BACK),
        hw_topo.create_usbc_port(hw_topo.port_position.FRONT),
    ],
    usb4 = True,
)
_BLUETOOTH = hw_topo.create_bluetooth(
    "BLUETOOTH",
    "Default bluetooth",
    bt_component = program.bluetooth_component.bluetooth,
)
_BARRELJACK = hw_topo.create_barreljack(
    "BARRELJACK",
    "Default barreljack",
    bj_present = True,
)
_POWER_BUTTON = hw_topo.create_power_button(
    region = hw_topo.region.SCREEN,
    edge = hw_topo.edge.LEFT,
    position = 0.9,
)

_VOLUME_BUTTON = hw_topo.create_volume_button(
    region = hw_topo.region.SCREEN,
    edge = hw_topo.edge.RIGHT,
    position = 0.75,
)

_SC_DISK_LAYOUT = sc.create_disk_layout(default_key_stateful = True)

_SC_FIRMWARE_INFO = sc.create_fw_info(
    has_alt_fw = True,
    has_splash_screen = True,
)

_SC_HEALTH = sc.create_health(
    vpd_has_sku_number = True,
    battery_has_smart_battery_info = True,
    routines_battery_capacity_high_mah = 10000,
    routines_battery_capacity_low_mah = 1000,
    routines_battery_health_maximum_cycle_count = 1000,
    routines_battery_health_percent_battery_wear_allowed = 50,
    routines_nvme_wear_level_wear_level_threshold = 50,
)
_SC_RMA = sc.create_rma(
    enabled = True,
    has_cbi = True,
    ssfc_config = sc.create_ssfc(
        mask = 0xF0000000,
        component_type_configs = [
            sc.create_ssfc_component_type_config(
                component_type = "component_1",
                default_value = 0x0,
                probeable_components = [
                    sc.create_ssfc_probeable_component(
                        identifier = "identifier_1",
                        value = 0x1,
                    ),
                    sc.create_ssfc_probeable_component(
                        identifier = "identifier_2",
                        value = 0x2,
                    ),
                ],
            ),
        ],
    ),
    use_legacy_custom_label = True,
)
_SC_NNPALM = sc.create_nnpalm(
    model = "alpha",
    radius_polynomial = "1,0",
    touch_compatible = True,
)
_SC_BLUETOOTH = sc.create_bluetooth(
    flags = {"enable-suspend-management": True},
)
_SC_POWER = sc.create_power(
    preferences = {
        "battery-poll-interval-initial-ms": "1000",
    },
)
_SC_WIFI_ATH10K = sc.create_ath10k(
    non_tablet_mode_transmit_power_chain = sc.create_ath10k_power_chain(
        limit_2g = 1,
        limit_5g = 2,
    ),
    tablet_mode_transmit_power_chain = sc.create_ath10k_power_chain(
        limit_2g = 3,
        limit_5g = 4,
    ),
)
_SC_WIFI_RTW88 = sc.create_rtw88(
    non_tablet_mode_transmit_power_chain = sc.create_rtw88_power_chain(
        limit_2g = 1,
        limit_5g_1 = 2,
        limit_5g_3 = 3,
        limit_5g_4 = 4,
    ),
    tablet_mode_transmit_power_chain = sc.create_rtw88_power_chain(
        limit_2g = 5,
        limit_5g_1 = 6,
        limit_5g_3 = 7,
        limit_5g_4 = 8,
    ),
    fcc_offsets = sc.create_rtw88_geo_offsets(
        offset_2g = 9,
        offset_5g = 10,
    ),
    eu_offsets = sc.create_rtw88_geo_offsets(
        offset_2g = 11,
        offset_5g = 12,
    ),
    other_offsets = sc.create_rtw88_geo_offsets(
        offset_2g = 13,
        offset_5g = 14,
    ),
)
_SC_WIFI6_INTEL = sc.create_intel_wifi(
    sar_table = sc.create_intel_sar_table(
        sar_table_revision = 2,
        tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 1,
            limit_5g_1 = 2,
            limit_5g_2 = 3,
            limit_5g_3 = 4,
            limit_5g_4 = 5,
            limit_5g_5 = 6,
            limit_6g_1 = 7,
            limit_6g_2 = 8,
            limit_6g_3 = 9,
            limit_6g_4 = 10,
            limit_6g_5 = 11,
        ),
        tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 12,
            limit_5g_1 = 13,
            limit_5g_2 = 14,
            limit_5g_3 = 15,
            limit_5g_4 = 16,
            limit_5g_5 = 17,
            limit_6g_1 = 18,
            limit_6g_2 = 19,
            limit_6g_3 = 20,
            limit_6g_4 = 21,
            limit_6g_5 = 22,
        ),
        non_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 23,
            limit_5g_1 = 24,
            limit_5g_2 = 25,
            limit_5g_3 = 26,
            limit_5g_4 = 27,
            limit_5g_5 = 28,
            limit_6g_1 = 29,
            limit_6g_2 = 30,
            limit_6g_3 = 31,
            limit_6g_4 = 32,
            limit_6g_5 = 33,
        ),
        non_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 34,
            limit_5g_1 = 35,
            limit_5g_2 = 36,
            limit_5g_3 = 37,
            limit_5g_4 = 38,
            limit_5g_5 = 39,
            limit_6g_1 = 40,
            limit_6g_2 = 41,
            limit_6g_3 = 42,
            limit_6g_4 = 43,
            limit_6g_5 = 44,
        ),
        cdb_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 45,
            limit_5g_1 = 46,
            limit_5g_2 = 47,
            limit_5g_3 = 48,
            limit_5g_4 = 49,
            limit_5g_5 = 50,
            limit_6g_1 = 51,
            limit_6g_2 = 52,
            limit_6g_3 = 53,
            limit_6g_4 = 54,
            limit_6g_5 = 55,
        ),
        cdb_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 56,
            limit_5g_1 = 57,
            limit_5g_2 = 58,
            limit_5g_3 = 59,
            limit_5g_4 = 60,
            limit_5g_5 = 61,
            limit_6g_1 = 62,
            limit_6g_2 = 63,
            limit_6g_3 = 64,
            limit_6g_4 = 65,
            limit_6g_5 = 66,
        ),
        cdb_non_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 67,
            limit_5g_1 = 68,
            limit_5g_2 = 69,
            limit_5g_3 = 70,
            limit_5g_4 = 71,
            limit_5g_5 = 72,
            limit_6g_1 = 73,
            limit_6g_2 = 74,
            limit_6g_3 = 75,
            limit_6g_4 = 76,
            limit_6g_5 = 77,
        ),
        cdb_non_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 78,
            limit_5g_1 = 79,
            limit_5g_2 = 80,
            limit_5g_3 = 81,
            limit_5g_4 = 82,
            limit_5g_5 = 83,
            limit_6g_1 = 84,
            limit_6g_2 = 85,
            limit_6g_3 = 86,
            limit_6g_4 = 87,
            limit_6g_5 = 88,
        ),
    ),
    wgds_table = sc.create_intel_offsets_table(
        wgds_revision = 2,
        fcc_offsets = sc.create_intel_geo_offsets(
            max_2g = 1,
            offset_2g_a = 2,
            offset_2g_b = 3,
            max_5g = 4,
            offset_5g_a = 5,
            offset_5g_b = 6,
            max_6g = 7,
            offset_6g_a = 8,
            offset_6g_b = 9,
        ),
        eu_offsets = sc.create_intel_geo_offsets(
            max_2g = 10,
            offset_2g_a = 11,
            offset_2g_b = 12,
            max_5g = 13,
            offset_5g_a = 14,
            offset_5g_b = 15,
            max_6g = 16,
            offset_6g_a = 17,
            offset_6g_b = 18,
        ),
        other_offsets = sc.create_intel_geo_offsets(
            max_2g = 19,
            offset_2g_a = 20,
            offset_2g_b = 21,
            max_5g = 22,
            offset_5g_a = 23,
            offset_5g_b = 24,
            max_6g = 25,
            offset_6g_a = 26,
            offset_6g_b = 27,
        ),
    ),
    ant_table = sc.create_intel_antgain_table(
        ant_table_revision = 2,
        ant_ppag_mode = 3,
        ant_gain_chain_a = sc.create_intel_antenna_gain(
            ant_gain_2g = 1,
            ant_gain_5g_1 = 2,
            ant_gain_5g_2 = 3,
            ant_gain_5g_3 = 4,
            ant_gain_5g_4 = 5,
            ant_gain_5g_5 = 6,
            ant_gain_6g_1 = 7,
            ant_gain_6g_2 = 8,
            ant_gain_6g_3 = 9,
            ant_gain_6g_4 = 10,
            ant_gain_6g_5 = 11,
        ),
        ant_gain_chain_b = sc.create_intel_antenna_gain(
            ant_gain_2g = 12,
            ant_gain_5g_1 = 13,
            ant_gain_5g_2 = 14,
            ant_gain_5g_3 = 15,
            ant_gain_5g_4 = 16,
            ant_gain_5g_5 = 17,
            ant_gain_6g_1 = 18,
            ant_gain_6g_2 = 19,
            ant_gain_6g_3 = 20,
            ant_gain_6g_4 = 21,
            ant_gain_6g_5 = 22,
        ),
    ),
    wtas_table = sc.create_intel_sar_avg_table(
        wtas_revision = 0x0,
        tas_selection = 1,
        tas_list_size = 16,
        deny_list_entry_1 = 1,
        deny_list_entry_2 = 2,
        deny_list_entry_3 = 3,
        deny_list_entry_4 = 4,
        deny_list_entry_5 = 5,
        deny_list_entry_6 = 6,
        deny_list_entry_7 = 7,
        deny_list_entry_8 = 8,
        deny_list_entry_9 = 9,
        deny_list_entry_10 = 10,
        deny_list_entry_11 = 11,
        deny_list_entry_12 = 12,
        deny_list_entry_13 = 13,
        deny_list_entry_14 = 14,
        deny_list_entry_15 = 15,
        deny_list_entry_16 = 16,
    ),
    dsm = sc.create_intel_dsm(
        disable_active_sdr_channels = 1,
        support_indonesia_5g_band = 2,
        support_ultra_high_band = 3,
        regulatory_configurations = 4,
        uart_configurations = 5,
        enablement_11ax = 6,
        unii_4 = 7,
    ),
)
_SC_WIFI7_INTEL = sc.create_intel_wifi(
    sar_table = sc.create_intel_sar_table(
        sar_table_revision = 2,
        tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 1,
            limit_5g_1 = 2,
            limit_5g_2 = 3,
            limit_5g_3 = 4,
            limit_5g_4 = 5,
            limit_5g_5 = 6,
            limit_6g_1 = 7,
            limit_6g_2 = 8,
            limit_6g_3 = 9,
            limit_6g_4 = 10,
            limit_6g_5 = 11,
        ),
        tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 12,
            limit_5g_1 = 13,
            limit_5g_2 = 14,
            limit_5g_3 = 15,
            limit_5g_4 = 16,
            limit_5g_5 = 17,
            limit_6g_1 = 18,
            limit_6g_2 = 19,
            limit_6g_3 = 20,
            limit_6g_4 = 21,
            limit_6g_5 = 22,
        ),
        non_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 23,
            limit_5g_1 = 24,
            limit_5g_2 = 25,
            limit_5g_3 = 26,
            limit_5g_4 = 27,
            limit_5g_5 = 28,
            limit_6g_1 = 29,
            limit_6g_2 = 30,
            limit_6g_3 = 31,
            limit_6g_4 = 32,
            limit_6g_5 = 33,
        ),
        non_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 34,
            limit_5g_1 = 35,
            limit_5g_2 = 36,
            limit_5g_3 = 37,
            limit_5g_4 = 38,
            limit_5g_5 = 39,
            limit_6g_1 = 40,
            limit_6g_2 = 41,
            limit_6g_3 = 42,
            limit_6g_4 = 43,
            limit_6g_5 = 44,
        ),
        cdb_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 45,
            limit_5g_1 = 46,
            limit_5g_2 = 47,
            limit_5g_3 = 48,
            limit_5g_4 = 49,
            limit_5g_5 = 50,
            limit_6g_1 = 51,
            limit_6g_2 = 52,
            limit_6g_3 = 53,
            limit_6g_4 = 54,
            limit_6g_5 = 55,
        ),
        cdb_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 56,
            limit_5g_1 = 57,
            limit_5g_2 = 58,
            limit_5g_3 = 59,
            limit_5g_4 = 60,
            limit_5g_5 = 61,
            limit_6g_1 = 62,
            limit_6g_2 = 63,
            limit_6g_3 = 64,
            limit_6g_4 = 65,
            limit_6g_5 = 66,
        ),
        cdb_non_tablet_mode_transmit_power_chain_a = sc.create_intel_power_chain(
            limit_2g = 67,
            limit_5g_1 = 68,
            limit_5g_2 = 69,
            limit_5g_3 = 70,
            limit_5g_4 = 71,
            limit_5g_5 = 72,
            limit_6g_1 = 73,
            limit_6g_2 = 74,
            limit_6g_3 = 75,
            limit_6g_4 = 76,
            limit_6g_5 = 77,
        ),
        cdb_non_tablet_mode_transmit_power_chain_b = sc.create_intel_power_chain(
            limit_2g = 78,
            limit_5g_1 = 79,
            limit_5g_2 = 80,
            limit_5g_3 = 81,
            limit_5g_4 = 82,
            limit_5g_5 = 83,
            limit_6g_1 = 84,
            limit_6g_2 = 85,
            limit_6g_3 = 86,
            limit_6g_4 = 87,
            limit_6g_5 = 88,
        ),
    ),
    wgds_table = sc.create_intel_offsets_table(
        wgds_revision = 2,
        fcc_offsets = sc.create_intel_geo_offsets(
            max_2g = 1,
            offset_2g_a = 2,
            offset_2g_b = 3,
            max_5g = 4,
            offset_5g_a = 5,
            offset_5g_b = 6,
            max_6g = 7,
            offset_6g_a = 8,
            offset_6g_b = 9,
        ),
        eu_offsets = sc.create_intel_geo_offsets(
            max_2g = 10,
            offset_2g_a = 11,
            offset_2g_b = 12,
            max_5g = 13,
            offset_5g_a = 14,
            offset_5g_b = 15,
            max_6g = 16,
            offset_6g_a = 17,
            offset_6g_b = 18,
        ),
        other_offsets = sc.create_intel_geo_offsets(
            max_2g = 19,
            offset_2g_a = 20,
            offset_2g_b = 21,
            max_5g = 22,
            offset_5g_a = 23,
            offset_5g_b = 24,
            max_6g = 25,
            offset_6g_a = 26,
            offset_6g_b = 27,
        ),
    ),
    ant_table = sc.create_intel_antgain_table(
        ant_table_revision = 2,
        ant_ppag_mode = 3,
        ant_gain_chain_a = sc.create_intel_antenna_gain(
            ant_gain_2g = 1,
            ant_gain_5g_1 = 2,
            ant_gain_5g_2 = 3,
            ant_gain_5g_3 = 4,
            ant_gain_5g_4 = 5,
            ant_gain_5g_5 = 6,
            ant_gain_6g_1 = 7,
            ant_gain_6g_2 = 8,
            ant_gain_6g_3 = 9,
            ant_gain_6g_4 = 10,
            ant_gain_6g_5 = 11,
        ),
        ant_gain_chain_b = sc.create_intel_antenna_gain(
            ant_gain_2g = 12,
            ant_gain_5g_1 = 13,
            ant_gain_5g_2 = 14,
            ant_gain_5g_3 = 15,
            ant_gain_5g_4 = 16,
            ant_gain_5g_5 = 17,
            ant_gain_6g_1 = 18,
            ant_gain_6g_2 = 19,
            ant_gain_6g_3 = 20,
            ant_gain_6g_4 = 21,
            ant_gain_6g_5 = 22,
        ),
    ),
    wtas_table = sc.create_intel_sar_avg_table(
        wtas_revision = 0x0,
        tas_selection = 1,
        tas_list_size = 16,
        deny_list_entry_1 = 1,
        deny_list_entry_2 = 2,
        deny_list_entry_3 = 3,
        deny_list_entry_4 = 4,
        deny_list_entry_5 = 5,
        deny_list_entry_6 = 6,
        deny_list_entry_7 = 7,
        deny_list_entry_8 = 8,
        deny_list_entry_9 = 9,
        deny_list_entry_10 = 10,
        deny_list_entry_11 = 11,
        deny_list_entry_12 = 12,
        deny_list_entry_13 = 13,
        deny_list_entry_14 = 14,
        deny_list_entry_15 = 15,
        deny_list_entry_16 = 16,
    ),
    dsm = sc.create_intel_dsm(
        disable_active_sdr_channels = 1,
        support_indonesia_5g_band = 2,
        support_ultra_high_band = 3,
        regulatory_configurations = 4,
        uart_configurations = 5,
        enablement_11ax = 6,
        unii_4 = 7,
        enablement_11be_countries = sc.create_intel_dsm_enablement_11be_countries(),
        energy_detection_threshold = sc.create_intel_dsm_energy_detection_threshold(),
    ),
    bt_sar = sc.create_intel_bt_sar(revision = 2),
    wbem = sc.create_intel_wbem(revision = 0),
    bpag = sc.create_intel_bpag(revision = 2),
    bbfb = sc.create_intel_bbfb(revision = 1),
    bdcm = sc.create_intel_bdcm(revision = 1),
    bbsm = sc.create_intel_bbsm(revision = 1),
    bucs = sc.create_intel_bucs(revision = 1),
    bdmm = sc.create_intel_bdmm(revision = 1),
    ebrd = sc.create_intel_ebrd(revision = 1),
    wpfc = sc.create_intel_wpfc(revision = 0),
    dsbr = sc.create_intel_dsbr(revision = 0),
)
_TOUCH = hw_topo.create_touch(
    "TOUCH",
    "Numpad touch",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.TOUCH, 1)],
)

_TPM = hw_topo.TPM_GSC_H1B

_MICROPHONE_MUTE_SWITCH = hw_topo.create_microphone_mute_switch(present = True)

_POWER_SUPPLY = hw_topo.create_power_supply(
    "POWER_SUPPLY",
    "Default power supply",
    usb_min_ac_watts = 20,
)

_BATTERY = hw_topo.create_battery(no_battery_boot_supported = True)

_PROXIMITY_CONFIG = [
    hw_topo.create_semtech_proximity(
        [
            hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.WIFI, "left"),
            hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.CELLULAR),
        ],
        [
            hw_topo.create_semtech_proximity_channel("0", hardwaregain = 4),
            hw_topo.create_semtech_proximity_channel("1"),
        ],
    ),
    hw_topo.create_semtech_proximity(
        hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.WIFI, "right"),
        [
            hw_topo.create_semtech_proximity_channel("0", hardwaregain = 2),
            hw_topo.create_semtech_proximity_channel("1"),
        ],
    ),
    hw_topo.create_activity_proximity(
        [
            hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.WIFI),
            hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.CELLULAR),
        ],
    ),
]

_USB_DETACHABLE_BASE = hw_topo.create_detachable_base(
    ec_image_name = "Fake_Detachable",
    product_id = 1000,
    usb_path = "1-1.1",
    vendor_id = 0x18d1,
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.DETACHABLE_BASE, 0)],
)

_USB_DETACHABLE_BASE_WITH_TP = hw_topo.create_detachable_base(
    ec_image_name = "Fake_Detachable",
    touch_image_name = "Fake_Tp_Version",
    product_id = 1000,
    usb_path = "1-1.1",
    vendor_id = 0x18d1,
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.DETACHABLE_BASE, 1)],
)

_I2C_DETACHABLE_BASE = hw_topo.create_detachable_base(
    ec_image_name = "Fake_Detachable",
    product_id = 1000,
    i2c_path = "1-0023",
    vendor_id = 0x18d1,
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.DETACHABLE_BASE, 2)],
)

_FAN_NOT_CONFIGURED = hw_topo.create_fan(
    id = "FAN",
    description = "Fan info for when nothing is configured",
    fan_count = None,
)

_NO_FAN = hw_topo.create_fan(
    id = "FAN",
    description = "Fan info for no fan",
    fan_count = 0,
)

_TWO_FAN = hw_topo.create_fan(
    id = "FAN",
    description = "Fan info for two fans",
    fan_count = 2,
)

_EC_LIMITED = hw_topo.create_ec(
    max_sensor_odr_mhz = 50000,
    max_accelerometer_calibration = 100,
)

def create_hardware_topology(
        screen = None,
        form_factor = None,
        keyboard = None,
        fingerprint = None,
        stylus = None,
        bluetooth = None,
        barreljack = None,
        cellular_board = None,
        camera = None,
        daughter_board = None,
        sensor = None,
        ec = None,
        tpm = None,
        microphone_mute_switch = None,
        hdmi = None,
        hps = None,
        audio = None,
        power_supply = None,
        proximity_sensor = None,
        wifi = None,
        battery = None,
        dgpu = None,
        uwb = None,
        detachable_base = None,
        soc = None,
        sd_reader = None,
        fan = None,
        dsp = None):
    return hw_topo.create_hardware_topology(
        bluetooth = bluetooth if bluetooth else None,
        barreljack = barreljack if barreljack else None,
        fingerprint = fingerprint if fingerprint else _NO_FINGERPRINT,
        form_factor = form_factor if form_factor else _FORM_FACTOR_CLAMSHELL,
        keyboard = keyboard if keyboard else _KEYBOARD,
        cellular_board = cellular_board,
        screen = screen if screen else _SCREEN,
        stylus = stylus if stylus else None,
        accelerometer_gyroscope_magnetometer = sensor if sensor else _SENSOR,
        audio = audio if audio else _AUDIO,
        camera = camera if camera else None,
        daughter_board = daughter_board if daughter_board else _DAUGHTER_BOARD,
        motherboard_usb = _MOTHERBOARD_USB,
        non_volatile_storage = _NON_VOLATILE_STORAGE,
        proximity_sensor = proximity_sensor,
        sd_reader = sd_reader if sd_reader else _SD_READER,
        thermal = _THERMAL,
        wifi = wifi or _WIFI6,
        power_button = _POWER_BUTTON,
        volume_button = _VOLUME_BUTTON,
        ec = ec or hw_topo.EC_CHROME,
        touch = _TOUCH,
        tpm = tpm or hw_topo.TPM_GSC_H1B,
        microphone_mute_switch = microphone_mute_switch,
        hdmi = hdmi,
        hps = hps,
        power_supply = power_supply if power_supply else _POWER_SUPPLY,
        battery = battery,
        dgpu = dgpu,
        dsp = dsp,
        uwb = uwb,
        detachable_base = detachable_base,
        soc = soc,
        fan = fan if fan else _FAN_NOT_CONFIGURED,
    )

# Create empty arrays that we will continually append new configurations to
# as we call append_configs
_HW_CONFIGS = []
_SW_CONFIGS = []

design.append_configs(
    hw_configs = _HW_CONFIGS,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID,
    config_id = 0x7fffffff,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        barreljack = _BARRELJACK,
        camera = _CAMERA1,
        fingerprint = _FINGERPRINT,
        cellular_board = _LTE_BOARD,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        sensor = _SENSOR_WITH_LIGHT,
        tpm = _TPM,
        microphone_mute_switch = _MICROPHONE_MUTE_SWITCH,
        hdmi = _HDMI,
        hps = _HPS,
        battery = _BATTERY,
        dgpu = _DGPU,
        dsp = _DSP_ISH,
        uwb = _UWB,
        sd_reader = _NO_SD_READER,
        fan = _NO_FAN,
    ),
    bluetooth = _SC_BLUETOOTH,
    health = _SC_HEALTH,
    rma = _SC_RMA,
    nnpalm = _SC_NNPALM,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ap_rw_a_hash = "b9392520207df3c79d1c5dd98171387f",
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
        ish_name = "fake",
    ),
    firmware_info = _SC_FIRMWARE_INFO,
    power = _SC_POWER,
    wifi = _SC_WIFI_ATH10K,
    ui = sc.create_ui(extra_web_apps_dir = "apps1"),
    usb = sc.create_usb(dp_only = True),
    frid = "Google_Ref",
)

design.append_configs(
    hw_configs = _HW_CONFIGS,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID,
    config_id = 0,
    hardware_topology = create_hardware_topology(
        form_factor = _FORM_FACTOR_CLAMSHELL_POWER_RECOV,
        cellular_board = _LTE_BOARD_WITH_MODEL,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        camera = _CAMERA2,
        daughter_board = hw_topo.create_daughter_board(
            "Non-default DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(
                program.fw_masks.DB,
                0,
                coreboot_customizations = ["0db"],
            )],
        ),
        hdmi = _HDMI_CEC_POWER_ON,
        microphone_mute_switch = _MICROPHONE_MUTE_SWITCH,
        keyboard = _BL_KEYBOARD,
        battery = _BATTERY,
        fan = _TWO_FAN,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        # Leave out ec_rw_version intentionally for testing
        pd_version = sc.create_fw_version(11111),
        # Leave out has_ec_component_manifest for testing
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = sc.create_power({
        "suspend-to-idle": "0",
    }),
    wifi = _SC_WIFI_RTW88,
    camera = sc.create_camera(generate_media_profiles = True),
    ui = sc.create_ui(extra_web_apps_dir = "apps2"),
)

design.append_configs(
    hw_configs = _HW_CONFIGS,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID,
    config_id = 1,
    hardware_topology = create_hardware_topology(
        form_factor = _FORM_FACTOR_CLAMSHELL_POWER_RECOV,
        cellular_board = _LTE_BOARD_WITH_MODEL,
        screen = _OLED_TOUCHSCREEN,
        stylus = _STYLUS,
        camera = _CAMERA2,
        daughter_board = hw_topo.create_daughter_board(
            "Non-default DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(
                program.fw_masks.DB,
                0,
                coreboot_customizations = ["0db"],
            )],
        ),
        microphone_mute_switch = _MICROPHONE_MUTE_SWITCH,
        sensor = _SENSOR_WITH_LIGHT,
        keyboard = _KEYBOARD_WITH_LAYOUT,
        battery = _BATTERY,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        # Leave out ec_rw_version intentionally for testing
        pd_version = sc.create_fw_version(11111),
        # Set has_ec_component_manifest to False for testing
        has_ec_component_manifest = False,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = sc.create_power({
        "suspend-to-idle": "0",
    }),
    wifi = _SC_WIFI_RTW88,
    camera = sc.create_camera(generate_media_profiles = True),
    ui = sc.create_ui(extra_web_apps_dir = "apps2"),
)

_HW_CONFIGS_A = []

design.append_configs(
    hw_configs = _HW_CONFIGS_A,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_A,
    config_id = 32,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        fingerprint = _FINGERPRINT,
        form_factor = _FORM_FACTOR_CONVERTIBLE,
        cellular_board = _LTE_BOARD,
        ec = _EC_LIMITED,
        proximity_sensor = hw_topo.create_proximity_sensor(
            "PROXIMITY_SENSOR",
            "Default proximity_sensor",
            proximity_config = _PROXIMITY_CONFIG,
        ),
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
    ),
    audio = sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        ucm_suffix = "2mic",
        module_file = "audio/alsa-module-config/alsa-%s.conf" % _DESIGN_ID_A.value.lower(),
        board_file = "audio/cras-config/board.ini",
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        depthcharge_name = "fake2",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    resource = sc.create_resource(
        ac = sc.create_power_source_preference(
            arcvm_gaming = sc.create_power_preference(
                governor = sc.create_ondemand_governor(0, 2),
                epp = sc.create_balance_performance_epp(),
            ),
            borealis_gaming = sc.create_power_preference(
                governor = sc.create_ondemand_governor(0, 32),
                epp = sc.create_balance_performance_epp(),
            ),
            default = sc.create_power_preference(
                governor = sc.create_ondemand_governor(0, 2),
                epp = sc.create_balance_performance_epp(),
            ),
            vm_boot = sc.create_power_preference(
                governor = sc.create_performance_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            fullscreen_video = sc.create_power_preference(
                governor = sc.create_ondemand_governor(600, 2),
                epp = sc.create_balance_performance_epp(),
            ),
            web_rtc = sc.create_power_preference(
                governor = sc.create_ondemand_governor(400, 16),
                epp = sc.create_balance_performance_epp(),
            ),
            battery_saver = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_power_epp(),
                cpu_offline = sc.create_cpu_offline_smt(),
            ),
        ),
        dc = sc.create_power_source_preference(
            arcvm_gaming = sc.create_power_preference(
                governor = sc.create_conservative_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            borealis_gaming = sc.create_power_preference(
                governor = sc.create_performance_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            default = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            vm_boot = sc.create_power_preference(
                governor = sc.create_performance_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            fullscreen_video = sc.create_power_preference(
                governor = sc.create_schedutil_governor(),
                epp = sc.create_balance_power_epp(),
            ),
            web_rtc = sc.create_power_preference(
                governor = sc.create_userspace_governor(),
                epp = sc.create_balance_power_epp(),
            ),
            battery_saver = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_power_epp(),
                cpu_offline = sc.create_cpu_offline_half(),
            ),
        ),
    ),
    wifi = _SC_WIFI6_INTEL,
    camera = sc.create_camera(generate_media_profiles = True, has_external_camera = True),
    frid = "Google_Ref_A",
)

_HW_CONFIGS_B = []

design.append_configs(
    hw_configs = _HW_CONFIGS_B,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_B,
    config_id = 33,
    hardware_topology = create_hardware_topology(
        audio = _AUDIO_WITH_INIT,
        daughter_board = hw_topo.create_daughter_board(
            "DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)],
            cellular_support = False,
        ),
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        form_factor = _FORM_FACTOR_DETACHABLE,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        cellular_board = _LTE_BOARD_WITH_MODEL,
        wifi = hw_topo.create_wifi(
            "WIFI_ATH10K",
            "ath10k wifi",
            wifi_config = _SC_WIFI_ATH10K,
        ),
        proximity_sensor = hw_topo.create_proximity_sensor(
            "PROXIMITY_SENSOR",
            "Default proximity_sensor",
            proximity_config = hw_topo.create_activity_proximity(hw_topo.create_proximity_location(hw_topo.proximity_sensor_radio_type.CELLULAR)),
        ),
        soc = hw_topo.create_soc(
            "SPECIAL_SOC",
            "Non-default SoC",
            resource = sc.create_resource(
                ac = sc.create_power_source_preference(
                    default = sc.create_power_preference(
                        epp = sc.create_performance_epp(),
                    ),
                    battery_saver = sc.create_power_preference(
                        cpu_offline = sc.create_cpu_offline_smt(),
                    ),
                ),
                dc = sc.create_power_source_preference(
                    battery_saver = sc.create_power_preference(
                        cpu_offline = sc.create_cpu_offline_half(),
                    ),
                ),
            ),
        ),
        detachable_base = _I2C_DETACHABLE_BASE,
    ),
    bluetooth = _SC_BLUETOOTH,
    disk_layout = _SC_DISK_LAYOUT,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(
        generate_media_profiles = True,
        camcorder_resolutions = [sc.make_resolution(640, 480)],
    ),
    frid = None,
)

design.append_configs(
    hw_configs = _HW_CONFIGS_B,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_B,
    config_id = 34,
    hardware_topology = create_hardware_topology(
        audio = _AUDIO_WITH_UNDERSCORE,
        daughter_board = hw_topo.create_daughter_board(
            "DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)],
            cellular_support = False,
            hdmi_support = True,
            hdmi_cec = hw_topo.create_hdmi_cec(
                power_on_displays_on_boot = True,
                power_off_displays_on_shutdown = True,
            ),
        ),
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        form_factor = _FORM_FACTOR_DETACHABLE,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        cellular_board = _LTE_BOARD_WITH_MODEL,
        wifi = hw_topo.create_wifi(
            "WIFI_MTK",
            "mtk wifi",
            wifi_config = sc.create_mtk_wifi(
                non_tablet_mode_transmit_power_chain = sc.create_mtk_power_chain(
                    limit_2g = 1,
                    limit_5g_1 = 2,
                    limit_5g_2 = 3,
                    limit_5g_3 = 4,
                    limit_5g_4 = 5,
                ),
                tablet_mode_transmit_power_chain = sc.create_mtk_power_chain(
                    limit_2g = 6,
                    limit_5g_1 = 7,
                    limit_5g_2 = 8,
                    limit_5g_3 = 9,
                    limit_5g_4 = 10,
                ),
                fcc_transmit_power_chain = sc.create_mtk_geo_power_chain(
                    limit_2g = 11,
                    limit_5g = 12,
                    offset_2g = 13,
                    offset_5g = 14,
                ),
                eu_transmit_power_chain = sc.create_mtk_geo_power_chain(
                    limit_2g = 15,
                    limit_5g = 16,
                    offset_2g = 17,
                    offset_5g = 18,
                ),
                other_transmit_power_chain = sc.create_mtk_geo_power_chain(
                    limit_2g = 19,
                    limit_5g = 20,
                    offset_2g = 21,
                    offset_5g = 22,
                ),
                country_list = sc.create_mtcl_table(
                    version = 2,
                    support_6ghz = sc.support_band.BIOS_AND_OS,
                    bitmask_6ghz = 0x123456780000,
                    support_5p9ghz = sc.support_band.BIOS_AND_OS,
                    bitmask_5p9ghz = 0x876543210000,
                ),
            ),
        ),
        detachable_base = _USB_DETACHABLE_BASE,
        soc = _SOC,
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
        zephyr_detachable_base_name = "fake_zephyr_detachable_base",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(
        generate_media_profiles = True,
        camcorder_resolutions = [sc.make_resolution(640, 480)],
    ),
)

design.append_configs(
    hw_configs = _HW_CONFIGS_B,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_B,
    config_id = 35,
    hardware_topology = create_hardware_topology(
        audio = _AUDIO_WITH_INIT,
        daughter_board = hw_topo.create_daughter_board(
            "DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)],
            cellular_support = False,
        ),
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        form_factor = _FORM_FACTOR_DETACHABLE,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        cellular_board = _LTE_BOARD_WITH_MODEL,
        wifi = hw_topo.create_wifi(
            "WIFI_RTK89",
            "rt89 wifi",
            wifi_config = sc.create_rtw89(
                non_tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
                    limit_2g = 1,
                    limit_5g_1 = 2,
                    limit_5g_3 = 3,
                    limit_5g_4 = 4,
                ),
                tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
                    limit_2g = 5,
                    limit_5g_1 = 6,
                    limit_5g_3 = 7,
                    limit_5g_4 = 8,
                ),
                fcc_offsets = sc.create_rtw89_geo_offsets(
                    offset_2g = 9,
                    offset_5g = 10,
                ),
                eu_offsets = sc.create_rtw89_geo_offsets(
                    offset_2g = 11,
                    offset_5g = 12,
                ),
                other_offsets = sc.create_rtw89_geo_offsets(
                    offset_2g = 13,
                    offset_5g = 14,
                ),
            ),
        ),
        detachable_base = _USB_DETACHABLE_BASE_WITH_TP,
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
        zephyr_detachable_base_name = "fake_zephyr_detachable_base",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(
        generate_media_profiles = True,
        camcorder_resolutions = [sc.make_resolution(640, 480)],
    ),
)

_HW_CONFIGS_C = []

design.append_configs(
    hw_configs = _HW_CONFIGS_C,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_C,
    config_id = 34,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        screen = _PRIVACY_SCREEN,
        stylus = _STYLUS,
        form_factor = _FORM_FACTOR_CHROMESLATE,
        wifi = hw_topo.create_wifi(
            "WIFI_RTW88",
            "rtw88 wifi",
            wifi_config = _SC_WIFI_RTW88,
        ),
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    wifi = sc.create_rtw89(
        non_tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
            limit_2g = 1,
            limit_5g_1 = 2,
            limit_5g_3 = 3,
            limit_5g_4 = 4,
        ),
        tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
            limit_2g = 5,
            limit_5g_1 = 6,
            limit_5g_3 = 7,
            limit_5g_4 = 8,
        ),
        fcc_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 9,
            offset_5g = 10,
        ),
        eu_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 11,
            offset_5g = 12,
        ),
        other_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 13,
            offset_5g = 14,
        ),
    ),
    camera = sc.create_camera(has_external_camera = True),
)

_HW_CONFIGS_D = []

design.append_configs(
    hw_configs = _HW_CONFIGS_D,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_D,
    config_id = 40,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        screen = _PRIVACY_SCREEN,
        stylus = _STYLUS,
        form_factor = _FORM_FACTOR_CHROMESLATE,
        wifi = hw_topo.create_wifi(
            "WIFI_RTW88",
            "rtw88 wifi",
            wifi_config = _SC_WIFI_RTW88,
        ),
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    wifi = sc.create_rtw89(
        non_tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
            limit_2g = 1,
            limit_5g_1 = 2,
            limit_5g_3 = 3,
            limit_5g_4 = 4,
        ),
        tablet_mode_transmit_power_chain = sc.create_rtw89_power_chain(
            limit_2g = 5,
            limit_5g_1 = 6,
            limit_5g_3 = 7,
            limit_5g_4 = 8,
        ),
        fcc_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 9,
            offset_5g = 10,
        ),
        eu_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 11,
            offset_5g = 12,
        ),
        other_offsets = sc.create_rtw89_geo_offsets(
            offset_2g = 13,
            offset_5g = 14,
        ),
    ),
    camera = sc.create_camera(has_external_camera = True),
)

_HW_CONFIGS_WL = []
_HW_CONFIGS_REBRAND = []
_HDMI_AUDIO_CARD = "HDA ATI HDMI"

design.append_configs(
    hw_configs = _HW_CONFIGS_WL,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_WL,
    config_id = 64,
    hardware_topology = create_hardware_topology(
        camera = _CAMERA1,
        daughter_board = hw_topo.create_daughter_board(
            "LTE DB",
            "LTE daughter_board",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 2)],
            cellular_support = True,
            cellular_type = hw_topo.cellular.CELLULAR_LTE,
            cellular_dynamic_power_reduction_config = hw_topo.make_cellular_dynamic_power_reduction_config(gpio = 20, tablet_mode = True),
            cellular_wedge_timeout_in_ms = 210000,
            cellular_modem_type = hw_topo.modem.MODEM_NL668,
        ),
        proximity_sensor = hw_topo.create_proximity_sensor(
            "PROXIMITY_SENSOR",
            "Default proximity_sensor",
            proximity_config = _PROXIMITY_CONFIG,
        ),
        wifi = hw_topo.create_wifi(
            "WIFI_INTEL7",
            "intel wifi7",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.WIFI_SAR_ID, 7)],
            wifi_config = _SC_WIFI7_INTEL,
        ),
    ),
    audio = [sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
    ), sc.create_audio(
        _HDMI_AUDIO_CARD,
        ucm_file = "ucm-config/%s/HiFi.conf" % _HDMI_AUDIO_CARD,
        ucm_master_file = "ucm-config/%s/%s.conf" % (_HDMI_AUDIO_CARD, _HDMI_AUDIO_CARD),
    )],
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    launched = True,
)

design.append_configs(
    hw_configs = _HW_CONFIGS_REBRAND,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_REBRAND,
    config_id = 65,
    hardware_topology = create_hardware_topology(
        camera = _CAMERA1,
        cellular_board = _LTE_BOARD_WITH_NO_DPR,
        wifi = hw_topo.create_wifi(
            "WIFI_INTEL_LEGACY",
            "intel wifi (legacy config)",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.WIFI_SAR_ID, 6)],
            wifi_config = sc.create_legacy_intel_wifi(),
        ),
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
)

_HW_CONFIGS_BOX = []

design.append_configs(
    hw_configs = _HW_CONFIGS_BOX,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_BOX,
    config_id = 128,
    hardware_topology = create_hardware_topology(
        form_factor = _FORM_FACTOR_CHROMEBOX,
        audio = _AUDIO_WITH_CUSTOM_MIC_SUFFIX,
        power_supply = hw_topo.create_power_supply(
            "BJ_POWER_SUPPLY",
            "Default power supply with barreljack",
            usb_min_ac_watts = 90,
            bj_present = True,
        ),
        camera = _CAMERA0,
        cellular_board = _LTE_BOARD_WITH_MODEL,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(generate_media_profiles = True),
)

design.append_configs(
    hw_configs = _HW_CONFIGS_BOX,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_BOX,
    config_id = 129,
    hardware_topology = create_hardware_topology(
        form_factor = _FORM_FACTOR_CHROMEBASE,
        camera = _CAMERA0,
        audio = _AUDIO_WITH_CUSTOM_MIC_SUFFIX_AND_CRAS_SUFFIX,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(generate_media_profiles = True),
)

design.append_configs(
    hw_configs = _HW_CONFIGS_BOX,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_BOX,
    config_id = 130,
    hardware_topology = create_hardware_topology(
        form_factor = _FORM_FACTOR_CHROMEBASE,
        audio = _AUDIO_WITH_FIXED_SUFFIX,
        sensor = hw_topo.create_sensor("SENSOR", "Lid accelerometer", lid_accel_present = True, lid_light_present = True),
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    power = _SC_POWER,
    camera = sc.create_camera(generate_media_profiles = True),
    ui = sc.create_ui(cloud_gaming_device = True),
)

_BOARD_ID_PHASE = {
    0: "PROTO",
    1: "EVT",
    2: "DVT",
    3: "PVT",
}

_DESIGN = design.create_design(
    id = _DESIGN_ID,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS,
    board_id_phases = _BOARD_ID_PHASE,
)

_DESIGN_A = design.create_design(
    id = _DESIGN_ID_A,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_A,
)

_DESIGN_B = design.create_design(
    id = _DESIGN_ID_B,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_B,
)

_DESIGN_C = design.create_design(
    id = _DESIGN_ID_C,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_C,
)

_DESIGN_D = design.create_design(
    id = _DESIGN_ID_D,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_D,
)

def _filter_design_e(
        screen,
        stylus,
        **kwargs):
    if (screen == _TOUCHSCREEN) != (stylus == _STYLUS):
        return True

_DESIGN_E = design.create_design_with_configs(
    design_id = _DESIGN_ID_E,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    sw_configs = _SW_CONFIGS,
    firmware_build_config = sc.create_fw_build_config_by_names(
        "fake",
        ec_name = "fake",
        ec_extras = ["fake_ec_extra1", "fake_ec_extra2"],
        zephyr_ec_name = "projects/fake/fake",
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_ro_version = sc.create_fw_version(11111, 2),
        ec_rw_version = sc.create_fw_version(11111, 2, 4),
        pd_version = sc.create_fw_version(11111),
        has_ec_component_manifest = True,
    ),
    include_unprovisioned = False,
    initial_config_id = 0x10000,
    hardware_topology_bundle = hw_topo.create_hardware_topology_bundle(
        audio = _AUDIO_WITH_INIT,
        form_factor = _FORM_FACTOR_CONVERTIBLE,
        motherboard_usb = _MOTHERBOARD_USB,
        non_volatile_storage = _NON_VOLATILE_STORAGE,
        screen = [_SCREEN, _TOUCHSCREEN],
        sd_reader = _SD_READER,
        volume_button = _VOLUME_BUTTON,
        power_button = _POWER_BUTTON,
        wifi = _WIFI6,
        camera = [_CAMERA1, hw_topo.create_versioned_topology(_CAMERA2, 2)],
        daughter_board = hw_topo.create_daughter_board(
            "DB",
            "Non-default daughter_board",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)],
            cellular_support = False,
        ),
        keyboard = [_KEYBOARD, hw_topo.create_versioned_topology(_BL_KEYBOARD, 1)],
        stylus = [_NO_STYLUS, _STYLUS],
        proximity_sensor = [_NO_PROXIMITY_SENSOR, _PROXIMITY_SENSOR],
        thermal = _THERMAL,
        soc = _SOC,
    ),
    bluetooth = _SC_BLUETOOTH,
    power = _SC_POWER,
    health = _SC_HEALTH,
    hardware_topology_filter = _filter_design_e,
    # active_configs can accept either list or range type
    active_configs = list(range(0x10000, 0x10004)) + [0x10005, 0x10007],
    config_notes = {
        0x10000: "SKU1",
        0x10001: "SKU2",
        0x10002: "SKU3",
        0x10003: "SKU4",
        0x10005: "SKU5",
        0x10007: "SKU6",
    },
    spi_flash_transform = {
        "W25Q32BV/W25Q32CV/W25Q32DV": "W25Q32DV",
    },
    launched = True,
)

_DESIGN_WL = design.create_design(
    id = _DESIGN_ID_WL,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_WL,
    custom_type = design.custom_type.WHITELABEL,
)

_DESIGN_REBRAND = design.create_design(
    id = _DESIGN_ID_REBRAND,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_REBRAND,
    custom_type = design.custom_type.REBRAND,
)

_DESIGN_BOX = design.create_design(
    id = _DESIGN_ID_BOX,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_BOX,
)

_DEVICE_BRAND = device_brand.create(
    brand_name = "Fake ChromeOS Device Brandname",
    design_id = _DESIGN_ID,
    oem_id = _FAKE_OEM.id,
    brand_code = "AAAA",
    export_oem_info = True,
)

_DEVICE_BRAND_A = device_brand.create(
    brand_name = "ChromeOS Device Brandname A",
    design_id = _DESIGN_ID_A,
    oem_id = _FAKE_OEMA.id,
    brand_code = "FDAA",
    export_oem_info = True,
)

_DEVICE_BRAND_B = device_brand.create(
    brand_name = "ChromeOS Device Brandname B",
    design_id = _DESIGN_ID_B,
    oem_id = _FAKE_OEMB.id,
    brand_code = "FDBB",
    export_oem_info = True,
)

_DEVICE_BRAND_C = device_brand.create(
    brand_name = "ChromeOS Device Brandname C",
    design_id = _DESIGN_ID_C,
    oem_id = _FAKE_OEMC.id,
    brand_code = "FDCC",
    export_oem_info = True,
)

_DEVICE_BRAND_D = device_brand.create(
    brand_name = "ChromeOS Device Brandname D",
    design_id = _DESIGN_ID_D,
    oem_id = _FAKE_OEMC.id,
    brand_code = "FDCD",
    export_oem_info = True,
)

_DEVICE_BRAND_E = device_brand.create(
    brand_name = "ChromeOS Device Brandname E",
    design_id = _DESIGN_ID_E,
    oem_id = _FAKE_OEME.id,
    brand_code = "FDCE",
    export_oem_info = True,
)

_DEVICE_BRAND_E_WITH_FEATURE_ON = device_brand.create(
    brand_name = "ChromeOS Device Brandname E with feature device type on",
    design_id = _DESIGN_ID_E,
    oem_id = _FAKE_OEME.id,
    brand_code = "FDDE",
    export_oem_info = True,
)

_WL_DEVICE_BRAND = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_OEM.id,
    brand_code = "WLZZ",
    export_oem_info = True,
)

_WL_DEVICE_BRAND_A = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-A",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMA.id,
    brand_code = "WLAA",
    export_oem_info = True,
)

_WL_DEVICE_BRAND_B = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-B",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMB.id,
    brand_code = "WLBB",
    export_oem_info = True,
)

_WL_DEVICE_BRAND_C = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-C",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMC.id,
    brand_code = "WLCC",
    export_oem_info = True,
)

_REBRAND_DEVICE_BRAND_D = device_brand.create(
    brand_name = "ChromeOS Device Brandname REBRAND-D",
    design_id = _DESIGN_ID_REBRAND,
    oem_id = _FAKE_OEMD.id,
    brand_code = "RBDD",
    export_oem_info = True,
)

_DEVICE_BRAND_BOX = device_brand.create(
    brand_name = "ChromeOS Device Brandname Box",
    design_id = _DESIGN_ID_BOX,
    oem_id = _FAKE_OEM.id,
    brand_code = "FDBX",
    export_oem_info = True,
)

_BRAND_CONFIGS = [
    brand_config.create(
        device_brand_id = _DEVICE_BRAND.id,
        wallpaper = "fake_wallpaper",
        regulatory_label = "fake_regulatory_label",
        help_content_id = "fake_help",
        cloud_gaming_device = True,
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND.id,
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_A.id,
        custom_label_tag = "loema",
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_B.id,
        custom_label_tag = "loemb",
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_C.id,
        custom_label_tag = "loemc",
        cloud_gaming_device = False,
    ),
    brand_config.create(
        device_brand_id = _REBRAND_DEVICE_BRAND_D.id,
        # whitelabel_tag is deprecated, please use custom_label_tag.
        whitelabel_tag = "branda",
        cloud_gaming_device = True,
    ),
    brand_config.create(
        device_brand_id = _DEVICE_BRAND_E_WITH_FEATURE_ON.id,
        feature_device_type = brand_config.feature_device_type.ON,
    ),
]

comp.append_display_panel(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    display_vendor = partner.display_panel.AUO,
    product_id = "1A1A",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 280,
)
comp.append_display_panel(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    display_vendor = partner.display_panel.BOE,
    product_id = "2B2B",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 120,
)
comp.append_touchscreen(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.ELAN_TS,
    product_id = "01FF",
    fw_version = "1234",
)
comp.append_touchscreen(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.SIS,
    product_id = "111A",
    fw_version = "1.0",
)
comp.append_touchscreen(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.ILITEK,
    product_id = "2323",
    fw_version = "0700.0000.0000.0000",
)
comp.append_touchscreen(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.ILITDDI,
    product_id = "0001",
    fw_version = "0C.00.02.00",
)
comp.append_touchpad(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.ELAN,
    product_id = "99.0",
    fw_version = "9.0",
)
comp.append_touchpad(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.SYNAPTICS,
    product_id = "ABC1",
    fw_version = "1.1",
)
comp.append_battery(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    battery_vendor = partner.battery.PANASONIC,
    model = "AP15O5L",
)

_COMPONENTS.append(
    comp.create_wifi(
        vendor_id = "0f22",
        device_id = "0a11",
        revision_id = "11",
    ),
)

_COMPONENTS.append(
    comp.create_cellular(
        vendor_id = "abcd",
        product_id = "1234",
        bcd_device = "42",
    ),
)

_CONFIG = config_bundle.create(
    partners = _ODMS + _OEMS + _COMPONENT_VENDORS,
    designs = [_DESIGN, _DESIGN_A, _DESIGN_B, _DESIGN_C, _DESIGN_D, _DESIGN_E, _DESIGN_WL, _DESIGN_REBRAND, _DESIGN_BOX],
    device_brands = [_DEVICE_BRAND, _DEVICE_BRAND_A, _DEVICE_BRAND_B, _DEVICE_BRAND_C, _DEVICE_BRAND_D, _DEVICE_BRAND_E, _DEVICE_BRAND_E_WITH_FEATURE_ON, _WL_DEVICE_BRAND, _WL_DEVICE_BRAND_A, _WL_DEVICE_BRAND_B, _WL_DEVICE_BRAND_C, _REBRAND_DEVICE_BRAND_D, _DEVICE_BRAND_BOX],
    software_configs = _SW_CONFIGS,
    brand_configs = _BRAND_CONFIGS,
    components = _COMPONENTS,
)

design.generate(_CONFIG)
