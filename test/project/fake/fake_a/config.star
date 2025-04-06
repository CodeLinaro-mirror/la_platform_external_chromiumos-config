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

_ODMS = [_FAKE_ODM]
_OEMS = [_FAKE_OEM]
_COMPONENTS = []
_COMPONENT_VENDORS = []

_REF_DESIGN_NAME = "FAKE_A_REF_DESIGN"
_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)

# Hardware topology components

_FORM_FACTOR_CLAMSHELL = hw_topo.create_form_factor(hw_topo.ff.CLAMSHELL)

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

_STYLUS = hw_topo.create_stylus(
    "STYLUS",
    "Default stylus",
    stylus_type = hw_topo.stylus.INTERNAL,
)

_DGPU = hw_topo.create_dgpu(
    "NV3050",
    "Default dGPU",
    dgpu_type = hw_topo.dgpu.DGPU_NV3050,
)

_UWB = hw_topo.create_uwb(
    "UWB",
    "Default UWB",
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

_SENSOR = hw_topo.create_sensor(
    "SENSOR",
    "Default sensor",
    fw_configs = [hw_topo.make_fw_config(program.fw_masks.SENSOR, 3)],
    base_accel_present = True,
    base_gyro_present = True,
    base_magno_present = True,
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

_WIFI = hw_topo.create_wifi(
    "WIFI",
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
        fan = None):
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
        wifi = wifi if wifi else _WIFI,
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
        uwb = uwb,
        detachable_base = detachable_base,
        soc = soc,
        fan = fan if fan else _FAN_NOT_CONFIGURED,
    )

# Software configurations

_SC_FIRMWARE_INFO = sc.create_fw_info(
    has_alt_fw = True,
    has_splash_screen = True,
)

_SC_HEALTH = sc.create_health(
    vpd_has_sku_number = True,
    battery_has_smart_battery_info = True,
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
        tpm = _TPM,
        microphone_mute_switch = _MICROPHONE_MUTE_SWITCH,
        hdmi = _HDMI,
        hps = _HPS,
        battery = _BATTERY,
        dgpu = _DGPU,
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

_DESIGN = design.create_design(
    id = _DESIGN_ID,
    program_id = program.fake_a.id,
    odm_id = _FAKE_ODM.id,
    configs = _HW_CONFIGS,
)

_DEVICE_BRAND = device_brand.create(
    brand_name = "Fake ChromeOS Device Brandname",
    design_id = _DESIGN_ID,
    oem_id = _FAKE_OEM.id,
    brand_code = "AAAB",
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
]

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
comp.append_touchpad(
    _COMPONENTS,
    _COMPONENT_VENDORS,
    touch_vendor = partner.touch.ELAN,
    product_id = "99.0",
    fw_version = "9.0",
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
    designs = [_DESIGN],
    device_brands = [_DEVICE_BRAND],
    software_configs = _SW_CONFIGS,
    brand_configs = _BRAND_CONFIGS,
    components = _COMPONENTS,
)

design.generate(_CONFIG)
