load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/software_config_id.proto", sc_id_pb = "chromiumos.config.api")
load("@proto//api/software/chromeos_config/identity_scan_config.proto", id_scan_pb = "chromiumos.config.api.software.chromeos_config")
load("@proto//api/software/audio_config.proto", audio_pb = "chromiumos.config.api.software")
load("@proto//api/software/firmware_config.proto", fw_pb = "chromiumos.config.api.software")
load("@proto//api/software/software_config.proto", sc_pb = "chromiumos.config.api.software")

_FW_TYPE = struct(
    MAIN = fw_pb.FirmwareType.MAIN,
    EC = fw_pb.FirmwareType.EC,
    PD = fw_pb.FirmwareType.PD,
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

def _create_fw_config(ro=None, rw=None, ec=None, ec_extras=None, pd=None):
  return fw_pb.FirmwareConfig(main_ro_payload=ro,
                              main_rw_payload=rw,
                              ec_ro_payload=ec,
                              ec_extras = ec_extras,
                              pd_ro_payload=pd,)

def _create_x86_identity(smbios_name_match, fw_sku = 255):
  return id_scan_pb.IdentityScanConfig.SoftwareConfigId(
      smbios_name_match=smbios_name_match,
      firmware_sku=fw_sku,)

def _create_arm_identity(dt_compatible_match, fw_sku = 255):
  return id_scan_pb.IdentityScanConfig.SoftwareConfigId(
      device_tree_compatible_match=dt_compatible_match,
      firmware_sku=fw_sku,)


def _create_audio(card_name, card_config_file = None, dsp_file = None, ucm_file = None):
  return audio_pb.AudioConfig(card_name=card_name,
                              card_config_file=card_config_file,
                              dsp_file=dsp_file,
                              ucm_file=ucm_file,)


def _create(scan_config,
            firmware=None,
            bt=None,
            power=None,
            audio=None,):
  platform_name = (scan_config.smbios_name_match or
                   scan_config.device_tree_compatible_match)
  sc_id = sc_id_pb.SoftwareConfigId(
      value="%s:%d" % (platform_name, scan_config.firmware_sku))
  return sc_pb.SoftwareConfig(
      id=sc_id,
      scan_config=scan_config,
      firmware=firmware,
      bluetooth_config=bt,
      power_manager_config=power,
      audio_config=audio,
  )

sw_config = struct(
    create = _create,
    create_audio = _create_audio,
    create_x86_identity = _create_x86_identity,
    create_arm_identity = _create_arm_identity,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    fw_type = _FW_TYPE,
)
