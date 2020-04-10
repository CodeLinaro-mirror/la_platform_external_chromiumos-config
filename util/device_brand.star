"""Functions related to device brand.

See proto definitions for descriptions of arguments.
"""

load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/device_brand.proto",
    db_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/device_brand_id.proto",
    db_id_pb = "chromiumos.config.api",
)

DEFAULT_BRAND_CODE = "ZZCR"

def _create(brand_name, design_id, oem_id, brand_code = DEFAULT_BRAND_CODE):
    """Builds a DeviceBrand proto."""
    return db_pb.DeviceBrand(
        id = db_id_pb.DeviceBrandId(value = brand_code),
        design_id = design_id,
        oem_id = oem_id,
        brand_code = brand_code,
        brand_name = brand_name,
    )

def _create_list(device_brands):
    """Builds a DeviceBrandList proto."""
    return db_pb.DeviceBrandList(value = device_brands)

device_brand = struct(
    create = _create,
    create_list = _create_list,
)
