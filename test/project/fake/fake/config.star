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

_CLAMSHELL = hw_topo.create_form_factor("CLAMSHELL", "Device can only rotate 200 degrees", hw_topo.ff.CLAMSHELL)
_MLB_USB = hw_topo.create_motherboard_usb("1C1A", "1 Type-A and C", usbc_count = 1, usba_count = 1)
_DB = hw_topo.create_daughter_board("1C1A", "Daugher board with 1 Type-A and C", usbc_count = 1, usba_count = 1, fw_mask = _DB_FW_MASK, db_id = 2)

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
        motherboard_usb = _MLB_USB,
        form_factor = _CLAMSHELL,
        fingerprint = _FP,
    ),
)

_HW_DESIGN_CONFIG_2 = design.create_config(
    design_id = _DESIGN_ID,
    config_id = "2",
    hardware_topology = hw_topo.create_hardware_topology(
        motherboard_usb = _MLB_USB,
        form_factor = _CLAMSHELL,
        fingerprint = _FP,
        daughter_board = _DB,
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
