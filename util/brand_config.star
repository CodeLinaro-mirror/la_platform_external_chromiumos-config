"""Functions related to brand configs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/software/brand_config.proto",
    bc_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/device_brand_id.proto",
    db_id_pb = "chromiumos.config.api",
)

def _create(
        device_brand_id,
        wallpaper = None,
        regulatory_label = None,
        whitelabel_tag = None):
    """Builds a BrandConfig proto.

    Args:
        device_brand_id: A DeviceBrandId proto that is used to select a
            BrandConfig at runtime. Required.
        wallpaper: Base filename of the default wallpaper to show.
        regulatory_label: See chromeos-config readme
        whitelabel_tag: "whitelabel_tag" value set in the VPD, used to select a
            BrandConfig at runtime. See https://chromeos.google.com/partner/dlm/docs/factory/vpd.html#field-whitelabel_tag.

    Returns:
        A BrandConfig proto.
    """
    scan_config = None
    if whitelabel_tag:
        scan_config = db_id_pb.DeviceBrandId.ScanConfig(
            whitelabel_tag = whitelabel_tag,
        )
    return bc_pb.BrandConfig(
        brand_id = device_brand_id,
        wallpaper = wallpaper,
        scan_config = scan_config,
        regulatory_label = regulatory_label,
    )

brand_config = struct(
    create = _create,
)
