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
    "@proto//chromiumos/config/api/software/chromeos_config/identity_scan_config.proto",
    id_scan_pb = "chromiumos.config.api.software.chromeos_config",
)

def _create(device_brand_id, wallpaper = None, whitelabel_tag = None):
    """Builds a BrandConfig proto.

    Args:
        device_brand_id: A DeviceBrandId proto that is used to select a
            BrandConfig at runtime. Required.
        wallpaper: Base filename of the default wallpaper to show.
        whitelabel_tag: "whitelabel_tag" value set in the VPD, used to select a
            BrandConfig at runtime. See https://chromeos.google.com/partner/dlm/docs/factory/vpd.html#field-whitelabel_tag.

    Returns:
        A BrandConfig proto.
    """
    scan_config = None
    if whitelabel_tag:
        scan_config = id_scan_pb.IdentityScanConfig.BrandId(
            whitelabel_tag = whitelabel_tag,
        )
    return bc_pb.BrandConfig(
        brand_id = device_brand_id,
        wallpaper = wallpaper,
        scan_config = scan_config,
    )

brand_config = struct(
    create = _create,
)
