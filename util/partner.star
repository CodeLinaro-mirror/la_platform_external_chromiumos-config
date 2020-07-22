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
    destination_file_format=None):
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

def _create(name):
    """Builds a Partner proto."""
    partner_id = partner_id_pb.PartnerId(value = name)
    return partner_pb.Partner(
        id = partner_id,
        name = name,
    )

def _create_list(partners):
    """Builds a PartnerList proto."""
    return partner_pb.PartnerList(value = partners)

_WACOM_FW_FORMAT = "_firmware_{vendor_id}_{product_id}.hex"
_EMRIGHT_FW_FORMAT = "emright_firmware_{vendor_id}_{product_id}.bin"

partner = struct(
    create = _create,
    create_list = _create_list,
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
    ),
    touch = struct(
        ELAN = _create_touch_partner(
            name = "elan",
            vendor_id = "04F3",
            symlink_file_format = "elan_i2c_{product_id}.bin",
        ),
        ELAN_TS = _create_touch_partner(
            name = "elants",
            vendor_id = "04F3",
            symlink_file_format = "elants_i2c_{product_id}.bin",
        ),
        ELAN_HID_TS = _create_touch_partner(
            name = "elants",
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
            destination_file_format = "{product_id}.{fw_version}.bin",
        ),
        G2TOUCH = _create_touch_partner(
            name = "g2touch",
            vendor_id = "2A94",
            symlink_file_format = "g2touch_{product_id}.bin",
        ),
        PIXART = _create_touch_partner(
            name = "pixart",
            vendor_id = "093A",
            symlink_file_format = "pix_tp{product_series}_{product_id}.bin",
        ),
        RAYDIUM = _create_touch_partner(
            name = "raydium",
            vendor_id = "2386",
            symlink_file_format = "raydium_0x{product_series}{product_id}_{fw_version}.fw",
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
    ),
    battery = struct(
        PANASONIC = _create_battery_partner(
            name = "PANASON",
        ),
    ),
)
