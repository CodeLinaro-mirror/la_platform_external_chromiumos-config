"""Functions related to device brand.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
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

def _create(
        brand_name,
        design_id,
        oem_id,
        brand_code = DEFAULT_BRAND_CODE,
        export_oem_info = False):
    """Builds a DeviceBrand proto."""
    return db_pb.DeviceBrand(
        id = db_id_pb.DeviceBrandId(value = brand_code),
        design_id = design_id,
        oem_id = oem_id,
        export_oem_info = export_oem_info,
        brand_code = brand_code,
        brand_name = brand_name,
    )

device_brand = struct(
    create = _create,
)
