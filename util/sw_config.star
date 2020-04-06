"""Functions related to software configs.

See proto definitions for descriptions of arguments.
"""

load("//config/util/bindings/proto.star", "protos")

protos.register()

load("@proto//api/software/chromeos_config/identity_scan_config.proto", id_scan_pb = "chromiumos.config.api.software.chromeos_config")
load("@proto//api/software/audio_config.proto", audio_pb = "chromiumos.config.api.software")
load("@proto//api/software/firmware_config.proto", fw_pb = "chromiumos.config.api.software")
load("@proto//api/software/power_config.proto", pc_pb = "chromiumos.config.api.software")
load("@proto//api/software/software_config.proto", sc_pb = "chromiumos.config.api.software")

_FW_TYPE = struct(
    MAIN = fw_pb.FirmwareType.MAIN,
    EC = fw_pb.FirmwareType.EC,
    PD = fw_pb.FirmwareType.PD,
)

def _create_fw_payload(
        name = None,
        fw_type = _FW_TYPE.MAIN,
        build_target_name = None,
        major_version = 0,
        minor_version = 0):
    """Builds a FirmwarePayload proto."""
    build_target_name = build_target_name or name
    return fw_pb.FirmwarePayload(
        firmware_image_name = name,
        build_target_name = build_target_name,
        type = fw_type,
        version = fw_pb.Version(major = major_version, minor = minor_version),
    )

def _create_fw_config(ro = None, rw = None, ec = None, ec_extras = None, pd = None):
    """Builds a FirmwareConfig proto."""
    return fw_pb.FirmwareConfig(
        main_ro_payload = ro,
        main_rw_payload = rw,
        ec_ro_payload = ec,
        ec_extras = ec_extras,
        pd_ro_payload = pd,
    )

def _create_x86_id_scan(smbios_name_match, fw_sku = 255):
    """Builds a IdentityScanConfig.DesignConfigId proto for x86."""
    return id_scan_pb.IdentityScanConfig.DesignConfigId(
        smbios_name_match = smbios_name_match,
        firmware_sku = fw_sku,
    )

def _create_arm_id_scan(dt_compatible_match, fw_sku = 255):
    """Builds a IdentityScanConfig.DesignConfigId proto for arm."""
    return id_scan_pb.IdentityScanConfig.DesignConfigId(
        device_tree_compatible_match = dt_compatible_match,
        firmware_sku = fw_sku,
    )

def _create_audio(
        card_name,
        card_config_file = None,
        dsp_file = None,
        ucm_file = None,
        ucm_master_file = None,
        ucm_suffix = None):
    """Builds an AudioConfig proto."""
    return audio_pb.AudioConfig(
        card_name = card_name,
        card_config_file = card_config_file,
        dsp_file = dsp_file,
        ucm_file = ucm_file,
        ucm_master_file = ucm_master_file,
        ucm_suffix = ucm_suffix,
    )

def _create_power(preferences):
    """Builds a PowerConfig proto."""
    return pc_pb.PowerConfig(preferences = preferences)

def _create(
        design_config_id = None,
        id_scan_config = None,
        firmware = None,
        bt = None,
        power = None,
        audio = None):
    """Builds a SoftwareConfig proto."""
    return sc_pb.SoftwareConfig(
        design_config_id = design_config_id,
        id_scan_config = id_scan_config,
        firmware = firmware,
        bluetooth_config = bt,
        power_config = power,
        audio_config = audio,
    )

sw_config = struct(
    create = _create,
    create_audio = _create_audio,
    create_x86_id_scan = _create_x86_id_scan,
    create_arm_id_scan = _create_arm_id_scan,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    create_power = _create_power,
    fw_type = _FW_TYPE,
)
