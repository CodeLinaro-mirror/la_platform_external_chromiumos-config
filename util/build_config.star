load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/build_config.proto", bc_pb = "chromiumos.config.api")
load("@proto//chromeos_config/identity_scan_config.proto", id_scan_pb = "chromeos_config")
load("@proto//audio_config.proto", audio_pb = "chromiumos_config")
load("@proto//build_target_id.proto", bt_id_pb = "chromiumos_config")
load("@proto//brand_config.proto", brand_pb = "chromiumos_config")
load("@proto//firmware_config.proto", fw_pb = "firmware")
load("@proto//design_config_build_payload.proto", bp_pb = "chromiumos_config")

_FW_TYPE = struct(
    MAIN = fw_pb.FirmwareType.MAIN,
    EC = fw_pb.FirmwareType.EC,
)

def _create_fw_payload(name=None,
                       fw_type=_FW_TYPE.MAIN,
                       major_version=0,
                       minor_version=0,):
  return fw_pb.FirmwarePayload(
      build_target_name=name,
      firmware_image_name=name,
      type=fw_type,
      version=fw_pb.Version(major=major_version, minor=minor_version),
  )

def _create_fw_config(ro=None, rw=None, ec=None):
  return fw_pb.FirmwareConfig(main_ro_payload=ro,
                              main_rw_payload=rw,
                              ec_ro_payload=ec,)


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


def _create_audio(card_name, card_config_file = None, dsp_file = None, ucm_file = None):
  return audio_pb.AudioConfig(card_name=card_name,
                              card_config_file=card_config_file,
                              dsp_file=dsp_file,
                              ucm_file=ucm_file,)



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
    create_audio = _create_audio,
    create_brand_config = _create_brand_config,
    create_x86_identity = _create_x86_identity,
    create_arm_identity = _create_arm_identity,
    create_build_payload = _create_build_payload,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    fw_type = _FW_TYPE,
)
