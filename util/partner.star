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

def _create_touchscreen_partner(name, vendor_id, fw_file_format):
    partner = _create(name)
    partner.touchscreen_vendor = partner_pb.Partner.TouchscreenVendor(
        vendor_id = vendor_id,
        fw_file_format = fw_file_format,
    )
    return partner

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
    touchscreen = struct(
        ELAN = _create_touchscreen_partner(
            name = "elan",
            vendor_id = "04F3",
            fw_file_format = "elants_i2c_{product_id}.bin",
        ),
        EMRIGHT = _create_touchscreen_partner(
            name = "emright",
            vendor_id = "2C68",
            fw_file_format = _EMRIGHT_FW_FORMAT,
        ),
        EMRIGHT_AUO = _create_touchscreen_partner(
            name = "emright_auo",
            vendor_id = "AF06",
            fw_file_format = _EMRIGHT_FW_FORMAT,
        ),
        EMRIGHT_BOE = _create_touchscreen_partner(
            name = "emright_boe",
            vendor_id = "E509",
            fw_file_format = _EMRIGHT_FW_FORMAT,
        ),
        GOODIX = _create_touchscreen_partner(
            name = "goodix",
            vendor_id = "27C6",
            fw_file_format = "goodix_firmware_{product_id}.bin",
        ),
        G2TOUCH = _create_touchscreen_partner(
            name = "g2touch",
            vendor_id = "2A94",
            fw_file_format = "g2touch_{product_id}.bin",
        ),
        PIXART = _create_touchscreen_partner(
            name = "pixart",
            vendor_id = "093A",
            fw_file_format = "pix_tp{product_series}_{product_id}.bin",
        ),
        RAYDIUM = _create_touchscreen_partner(
            name = "raydium",
            vendor_id = "2386",
            fw_file_format = "raydium_0x{product_series}{product_id}_{fw_version}.fw",
        ),
        SIS = _create_touchscreen_partner(
            name = "sis",
            vendor_id = "0457",
            fw_file_format = "sis_{product_id}.bin",
        ),
        SYNAPTICS = _create_touchscreen_partner(
            name = "synaptics",
            vendor_id = "06CB",
            fw_file_format = "hid-{vendor_id}_{product_id}",
        ),
        WACOM = _create_touchscreen_partner(
            name = "wacom",
            vendor_id = "056A",
            fw_file_format = "wacom" + _WACOM_FW_FORMAT,
        ),
        WACOM2 = _create_touchscreen_partner(
            name = "wacom2",
            vendor_id = "2D1F",
            fw_file_format = "wacom2" + _WACOM_FW_FORMAT,
        ),
        WACOM_AUO = _create_touchscreen_partner(
            name = "wacom_auo",
            vendor_id = "AF06",
            fw_file_format = "wacom" + _WACOM_FW_FORMAT,
        ),
        WACOM_BOE = _create_touchscreen_partner(
            name = "wacom_boe",
            vendor_id = "E509",
            fw_file_format = "wacom2" + _WACOM_FW_FORMAT,
        ),
        WEIDA = _create_touchscreen_partner(
            name = "weida",
            vendor_id = "2575",
            fw_file_format = "wdt{product_series}_{product_id}.bin",
        ),
    ),
)
