load("//config/proto/proto.star", "protos")
protos.register()

load("@proto//src/config/api/build_config.proto", bc_pb = "chromiumos.config.api")
load("@proto//src/platform2/chromeos-config/proto/identity_scan_config.proto", id_scan_pb = "chromeos_config")
load("@proto//src/third_party/chromiumos-overlay/proto/build_target_id.proto", bt_id_pb = "chromiumos_overlay")
load("@proto//src/third_party/chromiumos-overlay/proto/brand_config.proto", brand_pb = "chromiumos_overlay")
load("@proto//src/third_party/chromiumos-overlay/proto/design_config_build_payload.proto", bp_pb = "chromiumos_overlay")

def _create(build_target, design_config_payloads = None, brand_payloads = None):
  bt_id = bt_id_pb.BuildTargetId(value = build_target)
  return bc_pb.BuildConfig(build_target_id=bt_id,
                           build_payloads=design_config_payloads,
                           brand_configs=brand_payloads,)


def _create_list(build_configs):
  return bc_pb.BuildConfigList(value=build_configs)

def _create_brand_config(wallpaper, whitelabel_tag = None):
  scan_config = None
  if whitelabel_tag:
    scan_config = id_scan_pb.IdentityScanConfig.BrandId(
        whitelabel_tag=whitelabel_tag,)
  return brand_pb.BrandConfig(scan_config=scan_config,
                             wallpaper=wallpaper,)


def _create_x86_identity(smbios_name_match, fw_sku = 255):
  return id_scan_pb.IdentityScanConfig.DesignConfigId(
      smbios_name_match=smbios_name_match,
      firmware_sku=fw_sku,)

def _create_arm_identity(dt_compatible_match, fw_sku = 255):
  return id_scan_pb.IdentityScanConfig.DesignConfigId(
      device_tree_compatible_match=dt_compatible_match,
      firmware_sku=fw_sku,)


def _create_build_payload(scan_config,
                    firmware=None,
                    bt=None,
                    power=None,
                    audio=None,):
  return bp_pb.DesignConfigBuildPayload(
      scan_config=scan_config,
      firmware=firmware,
      bluetooth_config=bt,
      power_manager_config=power,
      audio_config=audio,
  )

build_config = struct(
    create = _create,
    create_list = _create_list,
    create_brand_config = _create_brand_config,
    create_x86_identity = _create_x86_identity,
    create_arm_identity = _create_arm_identity,
    create_build_payload = _create_build_payload,
)
