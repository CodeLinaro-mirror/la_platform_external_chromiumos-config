"""Functions related to partner configs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/partner.proto",
    partner_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/partner_id.proto",
    partner_id_pb = "chromiumos.config.api",
)

def _create_touch_partner(
        name,
        vendor_id,
        symlink_file_format,
        destination_file_format = "{product_id}_{fw_version}.bin"):
    partner = _create(name)
    partner.touch_vendor = partner_pb.Partner.TouchVendor(
        vendor_id = vendor_id,
        symlink_file_format = symlink_file_format,
        destination_file_format = destination_file_format,
    )
    return partner

def _create_display_partner(vendor_code):
    partner = _create(vendor_code)
    partner.display_panel_vendor = partner_pb.Partner.DisplayPanelVendor(
        vendor_code = vendor_code,
    )
    return partner

def _create_battery_partner(name):
    partner = _create(name)
    partner.battery_vendor = partner_pb.Partner.BatteryVendor(
        vendor_name = name,
    )
    return partner

def _create(name):
    """Builds a Partner proto."""
    partner_id = partner_id_pb.PartnerId(value = name)
    return partner_pb.Partner(
        id = partner_id,
        name = name,
    )

_WACOM_FW_FORMAT = "_firmware_{vendor_id}_{product_id}.hex"
_EMRIGHT_FW_FORMAT = "emright_firmware_{vendor_id}_{product_id}.bin"

partner = struct(
    create = _create,
    display_panel = struct(
        AUO = _create_display_partner(
            vendor_code = "AUO",
        ),
        BOE = _create_display_partner(
            vendor_code = "BOE",
        ),
        CMN = _create_display_partner(
            vendor_code = "CMN",
        ),
        IVO = _create_display_partner(
            vendor_code = "IVO",
        ),
        INX = _create_display_partner(
            vendor_code = "INX",
        ),
    ),
    touch = struct(
        ELAN = _create_touch_partner(
            name = "elan",
            vendor_id = "04F3",
            symlink_file_format = "elan_i2c_{product_id}.bin",
        ),
        ELAN_EEPROM = _create_touch_partner(
            name = "elan_eeprom",
            vendor_id = "04F3",
            symlink_file_format = "elan_eeprom_{product_id}.bin",
        ),
        ELAN_TS = _create_touch_partner(
            name = "elants",
            vendor_id = "04F3",
            symlink_file_format = "elants_i2c_{product_id}.bin",
        ),
        ELAN_HID_TS = _create_touch_partner(
            name = "elants_hid",
            vendor_id = "04F3",
            symlink_file_format = "elants_i2chid_{product_id}.bin",
        ),
        EMRIGHT = _create_touch_partner(
            name = "emright",
            vendor_id = "2C68",
            symlink_file_format = _EMRIGHT_FW_FORMAT,
        ),
        EMRIGHT_AUO = _create_touch_partner(
            name = "emright_auo",
            vendor_id = "AF06",
            symlink_file_format = _EMRIGHT_FW_FORMAT,
        ),
        EMRIGHT_BOE = _create_touch_partner(
            name = "emright_boe",
            vendor_id = "E509",
            symlink_file_format = _EMRIGHT_FW_FORMAT,
        ),
        GOODIX = _create_touch_partner(
            name = "goodix",
            vendor_id = "27C6",
            symlink_file_format = "goodix_firmware_{product_id}.bin",
        ),
        G2TOUCH = _create_touch_partner(
            name = "g2touch",
            vendor_id = "2A94",
            symlink_file_format = "g2touch_{product_id}.bin",
            destination_file_format = "PID_{product_id}_{fw_version}.bin",
        ),
        HIMAX = _create_touch_partner(
            name = "himax",
            vendor_id = "4858",
            symlink_file_format = "himax_i2chid_{product_id}.bin",
            destination_file_format = "{product_id}_{fw_version}.bin",
        ),
        HIMAX2 = _create_touch_partner(
            name = "himax",
            vendor_id = "3558",
            symlink_file_format = "himax_i2chid_{product_id}.bin",
            destination_file_format = "{product_id}_{fw_version}.bin",
        ),
        MELFAS = _create_touch_partner(
            name = "melfas",
            vendor_id = "1FD2",
            symlink_file_format = "melfas_mip4_{product_id}.fw",
            destination_file_format = "{product_id}_{fw_version}.fw",
        ),
        PIXART = _create_touch_partner(
            name = "pixart",
            vendor_id = "093A",
            symlink_file_format = "pix_tp{product_series}_{product_id}.bin",
        ),
        RAYDIUM = _create_touch_partner(
            name = "raydium",
            vendor_id = "2386",
            symlink_file_format = "raydium_0x{product_series}{product_id}.fw",
            destination_file_format = "raydium_0x{product_series}{product_id}_{fw_version}.fw",
        ),
        SIS = _create_touch_partner(
            name = "sis",
            vendor_id = "0457",
            symlink_file_format = "sis_{product_id}.bin",
        ),
        SYNAPTICS = _create_touch_partner(
            name = "synaptics",
            vendor_id = "06CB",
            symlink_file_format = "hid-{vendor_id}_{product_id}",
        ),
        WACOM = _create_touch_partner(
            name = "wacom",
            vendor_id = "056A",
            symlink_file_format = "wacom" + _WACOM_FW_FORMAT,
        ),
        WACOM2 = _create_touch_partner(
            name = "wacom2",
            vendor_id = "2D1F",
            symlink_file_format = "wacom2" + _WACOM_FW_FORMAT,
        ),
        WACOM_AUO = _create_touch_partner(
            name = "wacom_auo",
            vendor_id = "AF06",
            symlink_file_format = "wacom" + _WACOM_FW_FORMAT,
        ),
        WACOM_BOE = _create_touch_partner(
            name = "wacom_boe",
            vendor_id = "E509",
            symlink_file_format = "wacom2" + _WACOM_FW_FORMAT,
        ),
        WEIDA = _create_touch_partner(
            name = "weida",
            vendor_id = "2575",
            symlink_file_format = "wdt{product_series}_{product_id}.bin",
        ),
        ZINITIX = _create_touch_partner(
            name = "zinitix",
            vendor_id = "14E5",
            symlink_file_format = "zinitix_firmware_{product_id}.bin",
            destination_file_format = "zinitix_{product_id}_{fw_version}.bin",
        ),
        WACOM_BUGZZY = _create_touch_partner(
            name = "wacom",
            vendor_id = "2D1F",
            symlink_file_format = "wacom_firmware.hex",
            destination_file_format = "wacom_{product_id}_{fw_version}.hex",
        ),
        ILITEK = _create_touch_partner(
            name = "ilitek",
            vendor_id = "222A",
            symlink_file_format = "ilitek_{product_id}.bin",
            destination_file_format = "{product_id}_{fw_version}.bin",
        ),
        ILITDDI = _create_touch_partner(
            name = "ilitddi",
            vendor_id = "222A",
            symlink_file_format = "ilitddi_{product_id}.hex",
            destination_file_format = "{product_id}_{fw_version}.hex",
        ),
        FOCALTECH = _create_touch_partner(
            name = "focaltech",
            vendor_id = "2808",
            symlink_file_format = "focal_hid_{product_id}.bin",
            destination_file_format = "{product_id}_{fw_version}.bin",
        ),
        PARADETECH = _create_touch_partner(
            name = "paradetech",
            vendor_id = "1DA0",
            symlink_file_format = "paradetech_{product_id}.bin",
        ),
        CIRQUE = _create_touch_partner(
            name = "cirque",
            vendor_id = "0488",
            symlink_file_format = "cirque_firmware_{product_id}.hex",
            destination_file_format = "{vendor_id}_{product_id}_{fw_version}.hex",
        ),
    ),
    battery = struct(
        PANASONIC = _create_battery_partner(
            name = "panasonic",
        ),
    ),
)
