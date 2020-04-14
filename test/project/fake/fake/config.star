#!/usr/bin/env lucicfg

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

_PARTNERS = [_FAKE_ODM, _FAKE_OEM]

_REF_DESIGN_NAME = "FAKE-REF-DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)

_DB_FW_MASK = 0x0000000f
_CAMERA_FW_MASK = 0x000000f0

_SCREEN = hw_topo.create_screen("SCREEN", "Default screen", inches = 15, touch = False)
_FORM_FACTOR = hw_topo.create_form_factor("FORM_FACTOR", "Default form_factor", hw_topo.ff.CLAMSHELL)
_AUDIO = hw_topo.create_audio("AUDIO", "Default audio", codec = hw_topo.audio_codec.RT5682)
_STYLUS = hw_topo.create_stylus("STYLUS", "Default stylus", stylus_type = hw_topo.stylus.INTERNAL)
_KEYBOARD = hw_topo.create_keyboard("KEYBOARD", "Default keyboard", backlight = True, pwr_btn_present = False, kb_type = hw_topo.kb_type.DETACHABLE)
_THERMAL = hw_topo.create_thermal("THERMAL", "Default thermal")
_CAMERA = hw_topo.create_camera("CAMERA", "Default camera", fw_configs = [hw_topo.make_fw_config(_CAMERA_FW_MASK, 2)], count = 1)
_SENSOR = hw_topo.create_sensor("SENSOR", "Default sensor")
_FINGERPRINT = hw_topo.create_fingerprint("FINGERPRINT", "Default fingerprint", location = hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT, board = "fake-fingerprint-board")
_PROXIMITY_SENSOR = hw_topo.create_proximity_sensor("PROXIMITY_SENSOR", "Default proximity_sensor")
_DAUGHTER_BOARD = hw_topo.create_daughter_board("DAUGHTER_BOARD", "Default daughter_board", fw_configs = [hw_topo.make_fw_config(_DB_FW_MASK, 1)])
_NON_VOLATILE_STORAGE = hw_topo.create_non_volatile_storage("NON_VOLATILE_STORAGE", "Default non_volatile_storage", storage_type = hw_topo.storage.EMMC)
_RAM = hw_topo.create_ram("RAM", "Default ram", gigabytes = 16, type = hw_topo.memory.DDR3, speed_mhz = 3600)
_WIFI = hw_topo.create_wifi("WIFI", "Default wifi")
_LTE_BOARD = hw_topo.create_lte_board("LTE_BOARD", "Default lte_board", lte_present = True)
_SD_READER = hw_topo.create_sd_reader("SD_READER", "Default sd_reader")
_MOTHERBOARD_USB = hw_topo.create_motherboard_usb("MOTHERBOARD_USB", "Default motherboard_usb")

_FP = hw_topo.create_fingerprint(
    id = "AA_BB",
    description = "Fingerprint sensor",
    location = hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT,
    board = "fake-fingerprint-board",
)

_HW_DESIGN_CONFIG = design.create_config(
    design_id = _DESIGN_ID,
    config_id = "1",
    hardware_topology = hw_topo.create_hardware_topology(
        screen = _SCREEN,
        form_factor = _FORM_FACTOR,
        audio = _AUDIO,
        stylus = _STYLUS,
        keyboard = _KEYBOARD,
        thermal = _THERMAL,
        camera = _CAMERA,
        accelerometer_gyroscope_magnetometer = _SENSOR,
        fingerprint = _FINGERPRINT,
        proximity_sensor = _PROXIMITY_SENSOR,
        daughter_board = _DAUGHTER_BOARD,
        non_volatile_storage = _NON_VOLATILE_STORAGE,
        ram = _RAM,
        wifi = _WIFI,
        lte_board = _LTE_BOARD,
        sd_reader = _SD_READER,
        motherboard_usb = _MOTHERBOARD_USB,
    ),
)

_HW_DESIGN_CONFIG_2 = design.create_config(
    design_id = _DESIGN_ID,
    config_id = "2",
    hardware_topology = hw_topo.create_hardware_topology(
        screen = _SCREEN,
        form_factor = _FORM_FACTOR,
        audio = _AUDIO,
        stylus = _STYLUS,
        keyboard = _KEYBOARD,
        thermal = _THERMAL,
        camera = _CAMERA,
        accelerometer_gyroscope_magnetometer = _SENSOR,
        fingerprint = _FINGERPRINT,
        proximity_sensor = _PROXIMITY_SENSOR,
        daughter_board = _DAUGHTER_BOARD,
        non_volatile_storage = _NON_VOLATILE_STORAGE,
        ram = _RAM,
        wifi = _WIFI,
        lte_board = _LTE_BOARD,
        sd_reader = _SD_READER,
        motherboard_usb = _MOTHERBOARD_USB,
    ),
)

_DESIGN = design.create_design(
    id = _DESIGN_ID,
    program_id = program.fake.id,
    odm_id = _FAKE_ODM.id,
    configs = [
        _HW_DESIGN_CONFIG,
        _HW_DESIGN_CONFIG_2,
    ],
)

_DEVICE_BRAND = device_brand.create(
    brand_name = "Fake ChromeOS Device Brandname",
    design_id = _DESIGN_ID,
    oem_id = _FAKE_OEM.id,
    brand_code = "AAAA",
)

_AUDIO_CARD = "fakeaudiocard"

_SW_CONFIG = sc.create(
    design_config_id = _HW_DESIGN_CONFIG.id,
    id_scan_config = sc.create_x86_id_scan(
        smbios_name_match = "Fake",
        fw_sku = 0x7fffffff,
    ),
    audio = sc.create_audio(
        card_name = _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        ucm_file = "audio/%s/HiFi.conf" % _AUDIO_CARD,
        ucm_master_file = "audio/%s/%s.conf" % (_AUDIO_CARD, _AUDIO_CARD),
    ),
    firmware = sc.create_fw_config(
        ro = sc.create_fw_payload(
            name = "Fake",
            build_target_name = "fake",
            major_version = 11111,
        ),
        rw = sc.create_fw_payload(
            name = "Fake",
            build_target_name = "fake",
            major_version = 11111,
        ),
        ec = sc.create_fw_payload(
            name = "Fake_EC",
            build_target_name = "fake",
            fw_type = sc.fw_type.EC,
            major_version = 11111,
            minor_version = 2,
        ),
        ec_extras = ["fake-ec-extra1", "fake-ec-extra2"],
        pd = sc.create_fw_payload(
            name = "Fake_PD",
            build_target_name = "fake",
            fw_type = sc.fw_type.PD,
            major_version = 11111,
        ),
    ),
    power = sc.create_power(
        preferences = {
            "battery_poll_interval_initial_ms": "1000",
            "disable_dark_resume": "0",
        },
    ),
)

_SW_CONFIG_2 = sc.create(
    design_config_id = _HW_DESIGN_CONFIG_2.id,
    id_scan_config = sc.create_x86_id_scan(
        smbios_name_match = "Fake",
        fw_sku = 2,
    ),
    audio = sc.create_audio(
        card_name = _AUDIO_CARD,
        card_config_file = "audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
        dsp_file = "audio/%s/dsp.ini" % _AUDIO_CARD,
        ucm_file = "audio/%s/HiFi.conf" % _AUDIO_CARD,
        ucm_master_file = "audio/%s/%s.conf" % (_AUDIO_CARD, _AUDIO_CARD),
        ucm_suffix = "2mic",
    ),
    firmware = sc.create_fw_config(
        ro = sc.create_fw_payload(
            name = "Fake",
            build_target_name = "fake",
            major_version = 11111,
        ),
        rw = sc.create_fw_payload(
            name = "Fake",
            build_target_name = "fake",
            major_version = 11111,
        ),
        ec = sc.create_fw_payload(
            name = "Fake_EC",
            build_target_name = "fake",
            fw_type = sc.fw_type.EC,
            major_version = 11111,
            minor_version = 2,
        ),
        ec_extras = ["fake-ec-extra1", "fake-ec-extra2"],
        pd = sc.create_fw_payload(
            name = "Fake_PD",
            build_target_name = "fake",
            fw_type = sc.fw_type.PD,
            major_version = 11111,
        ),
    ),
    power = sc.create_power(
        preferences = {
            "battery_poll_interval_initial_ms": "1000",
            "disable_dark_resume": "0",
        },
    ),
)

_CONFIG = config_bundle.create(
    partners = _PARTNERS,
    designs = [_DESIGN],
    device_brands = [_DEVICE_BRAND],
    software_configs = [_SW_CONFIG, _SW_CONFIG_2],
    brand_configs = [
        brand_config.create(
            device_brand_id = _DEVICE_BRAND.id,
            wallpaper = "fake-wallpaper",
        ),
    ],
)

design.generate(_CONFIG)
