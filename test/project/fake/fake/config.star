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

_FAKE_ODM = partner.create("FAKE-ODM")
_FAKE_OEM = partner.create("FAKE-OEM")
_FAKE_OEMA = partner.create("FAKE-OEMA")
_FAKE_OEMB = partner.create("FAKE-OEMB")
_FAKE_OEMC = partner.create("FAKE-OEMC")
_FAKE_LOEMA = partner.create("FAKE-LOEMA")
_FAKE_LOEMB = partner.create("FAKE-LOEMB")
_FAKE_LOEMC = partner.create("FAKE-LOEMC")

_ODMS = [_FAKE_ODM]
_OEMS = [_FAKE_OEM, _FAKE_OEMA, _FAKE_OEMB, _FAKE_OEMC, _FAKE_LOEMA, _FAKE_LOEMB, _FAKE_LOEMC]
_COMPONENTS = []
_COMPONENT_VENDORS = []

_REF_DESIGN_NAME = "FAKE-REF-DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)
_DESIGN_ID_A = design.create_design_id("PROJECT-A")
_DESIGN_ID_B = design.create_design_id("PROJECT-B")
_DESIGN_ID_C = design.create_design_id("PROJECT-C")
_DESIGN_ID_WL = design.create_design_id("PROJECT-WL")
_DESIGN_ID_BOX = design.create_design_id("PROJECT-BOX")

_FORM_FACTOR_CLAMSHELL = hw_topo.create_form_factor(hw_topo.ff.CLAMSHELL)
_FORM_FACTOR_CONVERTIBLE = hw_topo.create_form_factor(hw_topo.ff.CONVERTIBLE)
_FORM_FACTOR_CHROMEBOX = hw_topo.create_form_factor(hw_topo.ff.CHROMEBOX)
_SCREEN = hw_topo.create_screen(
    id = "SCREEN",
    description = "Default screen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 280,
    touch = False,
)
_TOUCHSCREEN = hw_topo.create_screen(
    id = "TOUCHSCREEN",
    description = "Touchscreen",
    inches = 15,
    width_px = 1920,
    height_px = 1080,
    pixels_per_in = 120,
    touch = True,
)
_AUDIO = hw_topo.create_audio("AUDIO", "Default audio", speaker_amp = hw_topo.audio_codec.MAX98373, headphone_codec = hw_topo.audio_codec.ALC5682I)
_STYLUS = hw_topo.create_stylus("STYLUS", "Default stylus", stylus_type = hw_topo.stylus.INTERNAL)
_KEYBOARD = hw_topo.create_keyboard(backlight = True, pwr_btn_present = False, kb_type = hw_topo.kb_type.DETACHABLE)
_THERMAL = hw_topo.create_thermal("THERMAL", "Default thermal")
_CAMERA = hw_topo.create_camera("DEFAULT CAMERA", "Default camera", fw_configs = [hw_topo.make_fw_config(program.fw_masks.CAMERA, 2)], camera_devices = [hw_topo.make_camera_device(id = "0123:abcd", interface = "usb", facing = "front", orientation = 0)])
_SENSOR = hw_topo.create_sensor("SENSOR", "Default sensor", fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)], base_accel_present = True, base_gyro_present = True, base_magno_present = True)
_FINGERPRINT = hw_topo.create_fingerprint("FINGERPRINT", "Default fingerprint", location = hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT, board = "fake-fingerprint-board")
_NO_FINGERPRINT = hw_topo.create_fingerprint("NONE", "No finger print sensor", location = hw_topo.fp_loc.NOT_PRESENT)
_PROXIMITY_SENSOR = hw_topo.create_proximity_sensor("PROXIMITY_SENSOR", "Default proximity_sensor")
_DAUGHTER_BOARD = hw_topo.create_daughter_board("Default DB", "Default daughter_board", fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 1)])
_NON_VOLATILE_STORAGE = hw_topo.create_non_volatile_storage("NON_VOLATILE_STORAGE", "Default non_volatile_storage", storage_type = hw_topo.storage.EMMC)
_RAM = hw_topo.create_ram("RAM", "Default ram", gigabytes = 16, type = hw_topo.memory.DDR3, speed_mhz = 3600)
_WIFI = hw_topo.create_wifi("WIFI", "Default wifi")
_LTE_BOARD = hw_topo.create_lte_board("LTE_BOARD", "Default lte_board", lte_present = True)
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

_AUDIO_CARD = "fakeaudiocard"

_SC_BLUETOOTH = sc.create_bluetooth(flags = {"enable-suspend-management": True})
_SC_POWER = sc.create_power(
    preferences = {
        "battery-poll-interval-initial-ms": "1000",
        "disable-dark-resume": "0",
        "set-wifi-transmit-power-for-tablet-mode": "1",
    },
)

def create_hardware_topology(
        screen = None,
        form_factor = None,
        keyboard = None,
        fingerprint = None,
        stylus = None,
        bluetooth = None,
        barreljack = None,
        lte_board = None,
        camera = None,
        daughter_board = None):
    return hw_topo.create_hardware_topology(
        bluetooth = bluetooth if bluetooth else None,
        barreljack = barreljack if barreljack else None,
        fingerprint = fingerprint if fingerprint else _NO_FINGERPRINT,
        form_factor = form_factor if form_factor else _FORM_FACTOR_CLAMSHELL,
        keyboard = keyboard if keyboard else _KEYBOARD,
        lte_board = lte_board if lte_board else None,
        screen = screen if screen else _SCREEN,
        stylus = stylus if stylus else None,
        accelerometer_gyroscope_magnetometer = _SENSOR,
        audio = _AUDIO,
        camera = camera if camera else _CAMERA,
        daughter_board = daughter_board if daughter_board else _DAUGHTER_BOARD,
        motherboard_usb = _MOTHERBOARD_USB,
        non_volatile_storage = _NON_VOLATILE_STORAGE,
        proximity_sensor = _PROXIMITY_SENSOR,
        ram = _RAM,
        sd_reader = _SD_READER,
        thermal = _THERMAL,
        wifi = _WIFI,
        power_button = _POWER_BUTTON,
        volume_button = _VOLUME_BUTTON,
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
        fingerprint = _FINGERPRINT,
        lte_board = _LTE_BOARD,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
    ),
    audio = sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        public_fields = ["card_name"],
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
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
)

design.append_configs(
    hw_configs = _HW_CONFIGS,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID,
    config_id = 0,
    hardware_topology = create_hardware_topology(
        lte_board = _LTE_BOARD,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
        camera = hw_topo.create_camera("Non-default CAMERA", "Non-default camera", fw_configs = [hw_topo.make_fw_config(program.fw_masks.CAMERA, 0)], camera_devices = [hw_topo.make_camera_device(id = "0123:abcd", interface = "usb", facing = "front", orientation = 0)]),
        daughter_board = hw_topo.create_daughter_board("Non-default DB", "Non-default daughter_board", fw_configs = [hw_topo.make_fw_config(program.fw_masks.DB, 0)]),
    ),
    audio = sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        ucm_suffix = "2mic",
    ),
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
    power = _SC_POWER,
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
)

_HW_CONFIGS_A = []

design.append_configs(
    hw_configs = _HW_CONFIGS_A,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_A,
    config_id = 32,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        fingerprint = _FINGERPRINT,
        form_factor = _FORM_FACTOR_CONVERTIBLE,
        lte_board = _LTE_BOARD,
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
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
    power = _SC_POWER,
)

_HW_CONFIGS_B = []

design.append_configs(
    hw_configs = _HW_CONFIGS_B,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_B,
    config_id = 33,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        form_factor = _FORM_FACTOR_CONVERTIBLE,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
    ),
    audio = sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        ucm_suffix = "2mic",
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
    power = _SC_POWER,
)

_HW_CONFIGS_C = []

design.append_configs(
    hw_configs = _HW_CONFIGS_C,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_C,
    config_id = 34,
    hardware_topology = create_hardware_topology(
        bluetooth = _BLUETOOTH,
        screen = _TOUCHSCREEN,
        stylus = _STYLUS,
    ),
    audio = sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
    ),
    bluetooth = _SC_BLUETOOTH,
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
    power = _SC_POWER,
)

_HW_CONFIGS_WL = []
_HDMI_AUDIO_CARD = "HDA ATI HDMI"

design.append_configs(
    hw_configs = _HW_CONFIGS_WL,
    sw_configs = _SW_CONFIGS,
    design_id = _DESIGN_ID_WL,
    config_id = 64,
    hardware_topology = create_hardware_topology(),
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
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
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
    ),
    audio = [sc.create_audio(
        _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
    )],
    firmware = sc.create_fw_payloads_by_names(
        "Fake",
        "Fake_EC",
        "Fake_PD",
        ap_ro_version = sc.create_fw_version(11111),
        ap_rw_version = sc.create_fw_version(11111),
        ec_version = sc.create_fw_version(11111, 2),
        pd_version = sc.create_fw_version(11111),
    ),
    firmware_build_config = sc.create_fw_build_config_by_names("fake", ec_extras = ["fake-ec-extra1", "fake-ec-extra2"]),
    power = _SC_POWER,
)

# Currently public_fields is only set on the fake project. Once it is ready
# to be set on all projects, it can be made a default on create_design.
#
# TODO(crbug.com/1092530): Remove repetition once public_fields can be made a
# default.
_DESIGN = design.create_design(
    public_fields = ["id", "program_id"],
    id = _DESIGN_ID,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS,
)

_DESIGN_A = design.create_design(
    public_fields = ["id", "program_id"],
    id = _DESIGN_ID_A,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_A,
)

_DESIGN_B = design.create_design(
    public_fields = ["id", "program_id"],
    id = _DESIGN_ID_B,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_B,
)

_DESIGN_C = design.create_design(
    public_fields = ["id", "program_id"],
    id = _DESIGN_ID_C,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_C,
)

_DESIGN_WL = design.create_design(
    public_fields = ["id", "program_id"],
    id = _DESIGN_ID_WL,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS_WL,
)

_DESIGN_BOX = design.create_design(
    public_fields = ["id", "program_id"],
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

_DEVICE_BRAND_BOX = device_brand.create(
    brand_name = "ChromeOS Device Brandname Box",
    design_id = _DESIGN_ID_BOX,
    oem_id = _FAKE_OEM.id,
    brand_code = "FDBX",
)

_BRAND_CONFIGS = [
    brand_config.create(
        device_brand_id = _DEVICE_BRAND.id,
        wallpaper = "fake-wallpaper",
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

_COMPONENTS.append(
    comp.create_wifi(
        vendor_id = "0f22",
        device_id = "0a11",
        revision_id = "11",
    ),
)

_CONFIG = config_bundle.create(
    partners = _ODMS + _OEMS + _COMPONENT_VENDORS,
    designs = [_DESIGN, _DESIGN_A, _DESIGN_B, _DESIGN_C, _DESIGN_WL, _DESIGN_BOX],
    device_brands = [_DEVICE_BRAND, _DEVICE_BRAND_A, _DEVICE_BRAND_B, _DEVICE_BRAND_C, _WL_DEVICE_BRAND_A, _WL_DEVICE_BRAND_B, _WL_DEVICE_BRAND_C, _DEVICE_BRAND_BOX],
    software_configs = _SW_CONFIGS,
    brand_configs = _BRAND_CONFIGS,
    components = _COMPONENTS,
)

design.generate(_CONFIG)
