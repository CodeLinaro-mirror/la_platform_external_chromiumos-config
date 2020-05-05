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

def elan_fw_format(product_id, fw_version):
    return "%s_%s.bin" % (product_id, fw_version)

def _create_touchscreen_partner(name, vendor_id, fw_format_fn):
    return struct(
        partner=_create(name),
        vendor_id=vendor_id,
        fw_format_fn=fw_format_fn
    )

def _create(name):
    """Builds a Partner proto."""
    partner_id = partner_id_pb.PartnerId(value=name)
    return partner_pb.Partner(
        id=partner_id,
        name=name)

def _create_list(partners):
    """Builds a PartnerList proto."""
    return partner_pb.PartnerList(value = partners)

partner = struct(
    create=_create,
    create_list=_create_list,
    touchscreen=struct(
        ELAN=_create_touchscreen_partner(
            name='elan',
            vendor_id='04f3',
            fw_format_fn=elan_fw_format),
    )
)
