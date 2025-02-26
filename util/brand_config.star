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
        whitelabel_tag = None,
        help_content_id = None,
        cloud_gaming_device = None,
        feature_device_type = None,
        custom_label_tag = None):
    """Builds a BrandConfig proto.

    Args:
        device_brand_id: A DeviceBrandId proto that is used to select a
            BrandConfig at runtime. Required.
        wallpaper: Base filename of the default wallpaper to show.
        regulatory_label: See chromeos-config readme
        whitelabel_tag: "whitelabel_tag" value set in the VPD, used to select a
            BrandConfig at runtime. Deprecated, please use custom_label_tag instead.
        help_content_id: help content identifier
        cloud_gaming_device: whether devices using this BrandConfig should
            enable cloud gaming features
        custom_label_tag: "whitelabel_tag" is deprecated and renamed to "custom_label_tag".
            See https://chromeos.google.com/partner/dlm/docs/factory/vpd.html#field-custom_label_tag.

    Returns:
        A BrandConfig proto.
    """
    if whitelabel_tag != None and custom_label_tag != None:
        fail("whitelabel_tag and custom_label_tag both exist, please use only custom_label_tag.")
    scan_config = None
    if whitelabel_tag or feature_device_type or custom_label_tag != None:
        scan_config = db_id_pb.DeviceBrandId.ScanConfig(
            whitelabel_tag = whitelabel_tag,
            feature_device_type = feature_device_type,
            custom_label_tag = custom_label_tag,
        )
    return bc_pb.BrandConfig(
        brand_id = device_brand_id,
        wallpaper = wallpaper,
        scan_config = scan_config,
        regulatory_label = regulatory_label,
        help_content_id = help_content_id,
        cloud_gaming_device = cloud_gaming_device,
    )

_FEATURE_DEVICE_TYPE = struct(
    OFF = db_id_pb.DeviceBrandId.ScanConfig.OFF,
    LEGACY = db_id_pb.DeviceBrandId.ScanConfig.LEGACY,
    ON = db_id_pb.DeviceBrandId.ScanConfig.ON,
)

brand_config = struct(
    create = _create,
    feature_device_type = _FEATURE_DEVICE_TYPE,
)
