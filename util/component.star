"""Functions related to components.

See proto definitions for descriptions of arguments.
"""

load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/component.proto",
    comp_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/component_id.proto",
    comp_id_pb = "chromiumos.config.api",
)

def _vendor(name, vendor_id):
  return struct(
      name=name,
      vendor_id=vendor_id
  )

_VENDORS = struct(
    ELAN=_vendor('elan', '04f3')
)

def _create_touchscreen_fw_path(vendor, product_id, fw_version):
    """Applies vendor specific touch firmware naming conventions"""
    if vendor == _VENDORS.ELAN:
        return "%s/%s_%s.bin" % (vendor.name, product_id, fw_version)
    return None

def _create_touchscreen(vendor, product_id, fw_version, fw_path=None):
    """Builds a Component.Touchsreen proto."""
    id_value = comp_id_pb.ComponentId(
        value='_'.join([vendor.name, product_id, fw_version]))
    touchscreen = comp_pb.Component.Touchscreen(
        vendor_id=vendor.vendor_id,
        product_id=product_id,
        fw_version=fw_version,
        fw_path=fw_path or _create_touchscreen_fw_path(
            vendor, product_id, fw_version)
    )
    return comp_pb.Component(id = id_value, touchscreen = touchscreen)

def _create_soc_family(name, arch = comp_pb.Component.Soc.X86_64):
    """Builds a Component.Soc.Family proto."""
    return comp_pb.Component.Soc.Family(
        arch = arch,
        name = name,
    )

def _create_soc_model(family, model, cores, id):
    """Builds a Component proto for an Soc."""
    id_value = comp_id_pb.ComponentId(value = id)
    soc = comp_pb.Component.Soc(
        family = family,
        model = model,
        cores = cores,
    )
    return comp_pb.Component(id = id_value, soc = soc)

def _create_bt(vendor_id, product_id, bcd_device):
    """Builds a Component proto for Bluetooth."""
    component_id = comp_id_pb.ComponentId(
        value = "%s:%s:%s" % (vendor_id, product_id, bcd_device),
    )
    comp = comp_pb.Component(
        id = component_id,
        bluetooth = comp_pb.Component.Bluetooth(
            vendor_id = vendor_id,
            product_id = product_id,
            bcd_device = bcd_device,
        ),
    )
    return comp

_qual_status = struct(
    REQUESTED = comp_pb.Component.Qualification.REQUESTED,
    TECHNICALLY_QUALIFIED = comp_pb.Component.Qualification.TECHNICALLY_QUALIFIED,
    QUALIFIED = comp_pb.Component.Qualification.QUALIFIED,
)

def _create_qual(component_id, status = _qual_status.REQUESTED):
    """Builds a Component.Qualification proto."""
    return comp_pb.Component.Qualification(
        component_id = component_id,
        status = status,
    )

def _create_quals(component_ids, status = _qual_status.REQUESTED):
    """Builds a Component.Qualification proto for each of component_ids."""
    return [_create_qual(id, status) for id in component_ids]

comp = struct(
    create_soc_family = _create_soc_family,
    create_soc_model = _create_soc_model,
    create_bt = _create_bt,
    create_touchscreen = _create_touchscreen,
    create_qual = _create_qual,
    create_quals = _create_quals,
    qual_status = _qual_status,
    VENDORS = _VENDORS,
)
