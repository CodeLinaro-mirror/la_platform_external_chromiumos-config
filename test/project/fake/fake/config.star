#!/usr/bin/env gen_config

load("//config/util/component.star", "comp")
load("//config/util/config_bundle.star", "config_bundle")
load("//config/util/sw_config.star", sc = "sw_config")
load("//config/util/brand_config.star", "brand_config")
load("//config/util/design.star", "design")
load("//config/util/device_brand.star", "device_brand")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/partner.star", "partner")
load("//program/program.star", "program")

_FAKE_ODM = partner.create("FAKE_ODM")
_FAKE_OEM = partner.create("FAKE_OEM")
_FAKE_OEMA = partner.create("FAKE_OEMA")
_FAKE_OEMB = partner.create("FAKE_OEMB")
_FAKE_OEMC = partner.create("FAKE_OEMC")
_FAKE_OEMD = partner.create("FAKE_OEMD")
_FAKE_LOEMA = partner.create("FAKE_LOEMA")
_FAKE_LOEMB = partner.create("FAKE_LOEMB")
_FAKE_LOEMC = partner.create("FAKE_LOEMC")

_ODMS = [_FAKE_ODM]
_OEMS = [_FAKE_OEM, _FAKE_OEMA, _FAKE_OEMB, _FAKE_OEMC, _FAKE_OEMD, _FAKE_LOEMA, _FAKE_LOEMB, _FAKE_LOEMC]
_COMPONENTS = []
_COMPONENT_VENDORS = []

_REF_DESIGN_NAME = "FAKE_REF_DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)
_DESIGN_ID_A = design.create_design_id("PROJECT_A")
_DESIGN_ID_B = design.create_design_id("PROJECT_B")
_DESIGN_ID_C = design.create_design_id("PROJECT_C")
_DESIGN_ID_WL = design.create_design_id("PROJECT_WL")
_DESIGN_ID_REBRAND = design.create_design_id("PROJECT_REBRAND")
_DESIGN_ID_BOX = design.create_design_id("PROJECT_BOX")

_FORM_FACTOR_CLAMSHELL = hw_topo.create_form_factor(hw_topo.ff.CLAMSHELL)
_FORM_FACTOR_CONVERTIBLE = hw_topo.create_form_factor(hw_topo.ff.CONVERTIBLE)
_FORM_FACTOR_CHROMEBOX = hw_topo.create_form_factor(hw_topo.ff.CHROMEBOX)
_FORM_FACTOR_CHROMEBASE = hw_topo.create_form_factor(hw_topo.ff.CHROMEBASE)
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
        hw_topo.create_als_step(None, 400, 80.1, 80.1),
        hw_topo.create_als_step(100, None, 100),
    ],
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
    no_als_battery_brightness = 63.0,
    no_als_ac_brightness = 80,
    als_steps = [
        hw_topo.create_als_step(None, 400, 80, 63),
        hw_topo.create_als_step(100, None, 100, 80),
    ],
)
_HDMI = hw_topo.create_hdmi(
    id = "HDMI",
    description = "HDMI port",
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

_AUDIO_WITHOUT_MIC_SUFFIX = hw_topo.override_audio(
    _AUDIO_WITH_INIT,
    ucm_suffix = "{design}",
    ucm_config = hw_topo.audio_config_structure.COMMON,
    cras_config = hw_topo.audio_config_structure.COMMON,
)

_AUDIO_WITH_FIXED_SUFFIX = hw_topo.override_audio(
    _AUDIO_WITH_INIT,
    ucm_suffix = "fixed_suffix",
    ucm_config = hw_topo.audio_config_structure.DESIGN,
)

_STYLUS = hw_topo.create_stylus("STYLUS", "Default stylus", stylus_type = hw_topo.stylus.INTERNAL)
_BL_KEYBOARD = hw_topo.create_keyboard(backlight = True, pwr_btn_present = True, kb_type = hw_topo.kb_type.INTERNAL, numpad_present = True, backlight_user_steps = [0, 10, 20, 40, 60, 100])
_KEYBOARD = hw_topo.create_keyboard(backlight = False, pwr_btn_present = False, kb_type = hw_topo.kb_type.DETACHABLE, numpad_present = False)
_THERMAL = hw_topo.create_thermal("THERMAL", "Default thermal")
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
        ),
    ],
)
_CAMERA2 = hw_topo.create_camera(
    "CAMERA2",
    "1 USB camera and 1 MIPI camera",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.CAMERA, 0)],
    camera_devices = [
        hw_topo.make_camera_device(
            interface = "usb",
            facing = "front",
            orientation = 0,
            flags = hw_topo.camera_flags.SUPPORT_AUTOFOCUS,
            ids = ["0123:abcd"],
            privacy_switch_present = True,
        ),
        hw_topo.make_camera_device(
            interface = "mipi",
            facing = "back",
            orientation = 180,
            flags = hw_topo.camera_flags.SUPPORT_1080P | hw_topo.camera_flags.SUPPORT_AUTOFOCUS,
            ids = ["mipi-cam"],
        ),
    ],
)
_SENSOR = hw_topo.create_sensor("SENSOR", "Default sensor", fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)], base_accel_present = True, base_gyro_present = True, base_magno_present = True)
_SENSOR_WITH_LIGHT = hw_topo.create_sensor("SENSOR", "Default sensor plus light sensor", fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)], base_accel_present = True, base_gyro_present = True, base_magno_present = True, lid_light_present = True)
_FINGERPRINT = hw_topo.create_fingerprint("FINGERPRINT", "Default fingerprint", location = hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT, board = "fake_fingerprint_board")
_NO_FINGERPRINT = hw_topo.create_fingerprint("NONE", "No finger print sensor", location = hw_topo.fp_loc.NOT_PRESENT)
_HPS = hw_topo.create_hps("HPS", "Default Hps", present = True)
_PROXIMITY_SENSOR = hw_topo.create_proximity_sensor("PROXIMITY_SENSOR", "Default proximity_sensor")
_DAUGHTER_BOARD = hw_topo.create_daughter_board("Default DB", "Default daughter_board", fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 1)])
_NON_VOLATILE_STORAGE = hw_topo.create_non_volatile_storage("NON_VOLATILE_STORAGE", "Default non_volatile_storage", storage_type = hw_topo.storage.EMMC)
_WIFI = hw_topo.create_wifi("WIFI", "Default wifi", fw_configs = [hw_topo.make_fw_config(program.fw_masks.WIFI_SAR_ID, 6)])
_LTE_BOARD = hw_topo.create_cellular_board("LTE_BOARD", "Default cellular_board", present = True, type = hw_topo.cellular.CELLULAR_LTE)
_LTE_BOARD_WITH_MODEL = hw_topo.create_cellular_board("LTE_BOARD_MODEL", "Default cellular_board w/ model", present = True, type = hw_topo.cellular.CELLULAR_LTE, model = "FakeModem")
_SD_READER = hw_topo.create_sd_reader("SD_READER", "Default sd_reader")
_MOTHERBOARD_USB = hw_topo.create_motherboard_usb("MOTHERBOARD_USB", "Default motherboard_usb")
_BLUETOOTH = hw_topo.create_bluetooth("BLUETOOTH", "Default bluetooth", bt_component = program.bluetooth_component.bluetooth)
_BARRELJACK = hw_topo.create_barreljack("BARRELJACK", "Default barreljack", bj_present = True)
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

_SC_HEALTH = sc.create_health(
    vpd_has_sku_number = True,
    battery_has_smart_battery_info = True,
)
_SC_BLUETOOTH = sc.create_bluetooth(flags = {"enable-suspend-management": True})
_SC_POWER = sc.create_power(
    preferences = {
        "battery-poll-interval-initial-ms": "1000",
        "set-wifi-transmit-power-for-tablet-mode": "1",
    },
)

_TOUCH = hw_topo.create_touch("TOUCH", "Numpad touch", fw_configs = [hw_topo.make_fw_config(program.fw_masks.TOUCH, 1)])

_TPM = hw_topo.TPM_GSC_H1B

_MICROPHONE_MUTE_SWITCH = hw_topo.create_microphone_mute_switch(present = True)

_POWER_SUPPLY = hw_topo.create_power_supply("POWER_SUPPLY", "Default power supply", usb_min_ac_watts = 20)

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
        power_supply = None):
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
        proximity_sensor = _PROXIMITY_SENSOR,
        sd_reader = _SD_READER,
        thermal = _THERMAL,
        wifi = _WIFI,
        power_button = _POWER_BUTTON,
        volume_button = _VOLUME_BUTTON,
        ec = hw_topo.EC_CHROME,
        touch = _TOUCH,
        tpm = hw_topo.TPM_GSC_H1B,
        microphone_mute_switch = microphone_mute_switch,
        hdmi = hdmi,
        hps = hps,
        power_supply = power_supply if power_supply else _POWER_SUPPLY,
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
    ),
    bluetooth = _SC_BLUETOOTH,
    health = _SC_HEALTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
    wifi = sc.create_ath10k(
        non_tablet_mode_transmit_power_chain = sc.create_ath10k_power_chain(
            limit_2g = 1,
            limit_5g = 2,
        ),
        tablet_mode_transmit_power_chain = sc.create_ath10k_power_chain(
            limit_2g = 3,
            limit_5g = 4,
        ),
    ),
    ui = sc.create_ui(extra_web_apps_dir = "apps1"),
)

design.append_configs(
    hw_configs = _HW_CONFIGS,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID,
    config_id = 0,
    hardware_topology = create_hardware_topology(
        cellular_board = _LTE_BOARD_WITH_MODEL,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        camera = _CAMERA2,
        daughter_board = hw_topo.create_daughter_board("Non-default DB", "Non-default daughter_board", fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)]),
        microphone_mute_switch = _MICROPHONE_MUTE_SWITCH,
        keyboard = _BL_KEYBOARD,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = sc.create_power({
        "suspend-to-idle": "0",
    }),
    wifi = sc.create_rtw88(
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
    ),
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
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
    wifi = sc.create_intel_wifi(
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
    ),
    camera = sc.create_camera(generate_media_profiles = True),
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
            "DB with LTE",
            "Non-default daughter_board with LTE",
            fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)],
            cellular_support = True,
            cellular_model = "FakeModemB",
            cellular_type = hw_topo.cellular.CELLULAR_LTE,
        ),
        bluetooth = _BLUETOOTH,
        camera = _CAMERA1,
        form_factor = _FORM_FACTOR_DETACHABLE,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
    camera = sc.create_camera(
        generate_media_profiles = True,
        camcorder_resolutions = [sc.make_resolution(640, 480)],
    ),
    wifi = sc.create_mtk_wifi(
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
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        form_factor = _FORM_FACTOR_CHROMESLATE,
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
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
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
)

design.append_configs(
    hw_configs = _HW_CONFIGS_REBRAND,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_REBRAND,
    config_id = 65,
    hardware_topology = create_hardware_topology(
        camera = _CAMERA1,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
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
        audio = _AUDIO_WITHOUT_MIC_SUFFIX,
        power_supply = hw_topo.create_power_supply(
            "BJ_POWER_SUPPLY",
            "Default power supply with barreljack",
            usb_min_ac_watts = 90,
            bj_present = True,
        ),
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
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
        audio = _AUDIO_WITH_FIXED_SUFFIX,
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111, 2, 3),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
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
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake_ec_extra1", "fake_ec_extra2"], zephyr_ec_name = "projects/fake/fake"),
    power = _SC_POWER,
    camera = sc.create_camera(generate_media_profiles = True),
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
)

_DEVICE_BRAND_A = device_brand.create(
    brand_name = "ChromeOS Device Brandname A",
    design_id = _DESIGN_ID_A,
    oem_id = _FAKE_OEMA.id,
    brand_code = "FDAA",
)

_DEVICE_BRAND_B = device_brand.create(
    brand_name = "ChromeOS Device Brandname B",
    design_id = _DESIGN_ID_B,
    oem_id = _FAKE_OEMB.id,
    brand_code = "FDBB",
)

_DEVICE_BRAND_C = device_brand.create(
    brand_name = "ChromeOS Device Brandname C",
    design_id = _DESIGN_ID_C,
    oem_id = _FAKE_OEMC.id,
    brand_code = "FDCC",
)

_WL_DEVICE_BRAND = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL",
    design_id = _DESIGN_ID_WL,
    oem_id = None,
    brand_code = "WLZZ",
)

_WL_DEVICE_BRAND_A = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-A",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMA.id,
    brand_code = "WLAA",
)

_WL_DEVICE_BRAND_B = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-B",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMB.id,
    brand_code = "WLBB",
)

_WL_DEVICE_BRAND_C = device_brand.create(
    brand_name = "ChromeOS Device Brandname WL-C",
    design_id = _DESIGN_ID_WL,
    oem_id = _FAKE_LOEMC.id,
    brand_code = "WLCC",
)

_REBRAND_DEVICE_BRAND_D = device_brand.create(
    brand_name = "ChromeOS Device Brandname REBRAND-D",
    design_id = _DESIGN_ID_REBRAND,
    oem_id = _FAKE_OEMD.id,
    brand_code = "RBDD",
)

_DEVICE_BRAND_BOX = device_brand.create(
    brand_name = "ChromeOS Device Brandname Box",
    design_id = _DESIGN_ID_BOX,
    oem_id = _FAKE_OEM.id,
    brand_code = "FDBX",
)

_BRAND_CONFIGS = [
    brand_config.create(
        device_brand_id = _DEVICE_BRAND.id,
        wallpaper = "fake_wallpaper",
        regulatory_label = "fake_regulatory_label",
        help_content_id = "fake_help",
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND.id,
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_A.id,
        whitelabel_tag = "loema",
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_B.id,
        whitelabel_tag = "loemb",
    ),
    brand_config.create(
        device_brand_id = _WL_DEVICE_BRAND_C.id,
        whitelabel_tag = "loemc",
    ),
    brand_config.create(
        device_brand_id = _REBRAND_DEVICE_BRAND_D.id,
        whitelabel_tag = "branda",
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
    designs = [_DESIGN, _DESIGN_A, _DESIGN_B, _DESIGN_C, _DESIGN_WL, _DESIGN_REBRAND, _DESIGN_BOX],
    device_brands = [_DEVICE_BRAND, _DEVICE_BRAND_A, _DEVICE_BRAND_B, _DEVICE_BRAND_C, _WL_DEVICE_BRAND, _WL_DEVICE_BRAND_A, _WL_DEVICE_BRAND_B, _WL_DEVICE_BRAND_C, _REBRAND_DEVICE_BRAND_D, _DEVICE_BRAND_BOX],
    software_configs = _SW_CONFIGS,
    brand_configs = _BRAND_CONFIGS,
    components = _COMPONENTS,
)

design.generate(_CONFIG)
