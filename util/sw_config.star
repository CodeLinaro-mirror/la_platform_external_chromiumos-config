"""Functions related to software configs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/software/chromeos_config/identity_scan_config.proto",
    id_scan_pb = "chromiumos.config.api.software.chromeos_config",
)
load(
    "@proto//chromiumos/config/api/software/audio_config.proto",
    audio_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/bluetooth_config.proto",
    bt_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/firmware_config.proto",
    fw_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/power_config.proto",
    pc_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/software_config.proto",
    sc_pb = "chromiumos.config.api.software",
)

_FW_TYPE = struct(
    MAIN = fw_pb.FirmwareType.MAIN,
    EC = fw_pb.FirmwareType.EC,
    PD = fw_pb.FirmwareType.PD,
)

def _create_fw_version(major_version = None, minor_version = None):
    """
    Builds a firmware Version proto.

    If major_version is not specified, None is returned.
    """
    return fw_pb.Version(
        major = major_version,
        minor = minor_version,
    ) if major_version else None

def _create_fw_payload(
        name = None,
        fw_type = _FW_TYPE.MAIN,
        major_version = 0,
        minor_version = 0):
    """Builds a FirmwarePayload proto."""
    return fw_pb.FirmwarePayload(
        firmware_image_name = name,
        type = fw_type,
        version = fw_pb.Version(major = major_version, minor = minor_version),
    )

def _create_fw_build_targets(
        coreboot = None,
        depthcharge = None,
        ec = None,
        ec_extras = None,
        libpayload = None):
    """Builds a FirmwareBuildConfig.BuildTargets proto."""
    return fw_pb.FirmwareBuildConfig.BuildTargets(
        coreboot = coreboot,
        depthcharge = depthcharge,
        ec = ec,
        ec_extras = ec_extras,
        libpayload = libpayload,
    )

def _create_fw_build_config(build_targets):
    """Builds a FirmwareBuildConfig proto."""
    return fw_pb.FirmwareBuildConfig(build_targets = build_targets)

def _create_fw_build_config_by_names(
        coreboot_name,
        ec_name = None,
        depthcharge_name = None,
        libpayload_name = None,
        ec_extras = None):
    """Builds a FirmwareBuildConfig proto using common naming patterns.

    Build targets are set to be coreboot_name unless they are otherwise
    specified, e.g. depthcharge is set to coreboot_name unless
    depthcharge_name is specified. This function is provided as a convenience,
    as different firmware build targets often share the same name.
    """
    return fw_pb.FirmwareBuildConfig(
        build_targets = fw_pb.FirmwareBuildConfig.BuildTargets(
            coreboot = coreboot_name,
            ec = ec_name if ec_name else coreboot_name,
            ec_extras = ec_extras,
            depthcharge = depthcharge_name if depthcharge_name else coreboot_name,
            libpayload = libpayload_name if libpayload_name else coreboot_name,
        ),
    )

def _create_fw_config(ro = None, rw = None, ec = None, pd = None):
    """Builds a FirmwareConfig proto."""
    return fw_pb.FirmwareConfig(
        main_ro_payload = ro,
        main_rw_payload = rw,
        ec_ro_payload = ec,
        pd_ro_payload = pd,
    )

def _create_fw_payloads_by_names(
        ap_fw_name = None,
        ec_fw_name = None,
        pd_fw_name = None,
        ap_ro_version = None,
        ap_rw_version = None,
        ec_version = None,
        pd_version = None):
    """Builds a FirmwareConfig proto using common naming patterns."""
    sc_fw_config = fw_pb.FirmwareConfig()
    if ap_fw_name:
        sc_fw_config.main_ro_payload = fw_pb.FirmwarePayload(
            firmware_image_name = ap_fw_name,
            type = _FW_TYPE.MAIN,
            version = ap_ro_version,
        )
        if ap_rw_version:
            sc_fw_config.main_rw_payload = fw_pb.FirmwarePayload(
                firmware_image_name = ap_fw_name,
                type = _FW_TYPE.MAIN,
                version = ap_rw_version,
            )
    if ec_fw_name or ap_fw_name:
        sc_fw_config.ec_ro_payload = fw_pb.FirmwarePayload(
            firmware_image_name = ec_fw_name if ec_fw_name else ("%s_EC" % ap_fw_name),
            type = _FW_TYPE.EC,
            version = ec_version,
        )
    if pd_fw_name:
        sc_fw_config.pd_ro_payload = fw_pb.FirmwarePayload(
            firmware_image_name = pd_fw_name,
            type = _FW_TYPE.PD,
            version = pd_version,
        )
    return sc_fw_config if ap_fw_name else None

def _create_x86_id_scan(smbios_name_match = None, fw_sku = 255, design_config_id = None):
    """Deprecated. Use design.append_configs"""
    if smbios_name_match and design_config_id:
        fail(
            "smbios_name_match cannot be used if design_config_id ",
            "is used. smbios_name_match is deprecated, please use ",
            "design_config_id.",
        )

    if design_config_id:
        smbios_name_match, fw_sku = design_config_id.value.split(":")
        fw_sku = int(fw_sku)

    return id_scan_pb.IdentityScanConfig.DesignConfigId(
        smbios_name_match = smbios_name_match,
        firmware_sku = fw_sku,
    )

def _create_arm_id_scan(dt_compatible_match = None, fw_sku = 255, design_config_id = None):
    """Deprecated. Use design.append_configs"""
    if dt_compatible_match and design_config_id:
        fail(
            "dt_compatible_match cannot be used if design_config_id ",
            "is used. dt_compatible_match is deprecated, please use ",
            "design_config_id.",
        )

    if design_config_id:
        dt_compatible_match, fw_sku = design_config_id.value.split(":")
        fw_sku = int(fw_sku)
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
        ucm_suffix = None,
        module_file = None,
        board_file = None,
        hdmi_name = None,
        hdmi_ucm_file = None,
        hdmi_ucm_master_file = None):
    """Builds an AudioConfig proto."""
    if hdmi_name:
        if not hdmi_ucm_file:
            hdmi_ucm_file = "ucm-config/%s/HiFi.conf" % hdmi_name
        if not hdmi_ucm_master_file:
            hdmi_ucm_master_file = "ucm-config/%s/%s.conf" % (hdmi_name, hdmi_name)
    return audio_pb.AudioConfig(
        card_name = card_name,
        card_config_file = card_config_file,
        dsp_file = dsp_file,
        ucm_file = ucm_file if ucm_file else ("ucm-config/%s/HiFi.conf" % card_name),
        ucm_master_file = ucm_master_file if ucm_master_file else ("ucm-config/%s/%s.conf" % (card_name, card_name)),
        ucm_suffix = ucm_suffix,
        module_file = module_file,
        board_file = board_file,
        hdmi_name = hdmi_name,
        hdmi_ucm_file = hdmi_ucm_file,
        hdmi_ucm_master_file = hdmi_ucm_master_file,
    )

def _create_bluetooth(flags):
    """Builds a BluetoothConfig proto."""
    return bt_pb.BluetoothConfig(flags = flags)

def _create_power(preferences):
    """Builds a PowerConfig proto."""
    return pc_pb.PowerConfig(preferences = preferences)

def _create(
        design_config_id = None,
        id_scan_config = None,
        firmware = None,
        firmware_build_config = None,
        bluetooth = None,
        power = None,
        audio = None):
    """Deprecated. Use append_configs instead."""
    return sc_pb.SoftwareConfig(
        design_config_id = design_config_id,
        id_scan_config = id_scan_config,
        firmware = firmware,
        firmware_build_config = firmware_build_config,
        bluetooth_config = bluetooth,
        power_config = power,
        audio_config = audio,
    )

sw_config = struct(
    # Deprecated. Use append_configs instead
    create = _create,
    create_audio = _create_audio,
    create_bluetooth = _create_bluetooth,
    # Deprecated. Use append_configs instead
    create_x86_id_scan = _create_x86_id_scan,
    # Deprecated. Use append_configs instead
    create_arm_id_scan = _create_arm_id_scan,
    create_fw_version = _create_fw_version,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    create_fw_payloads_by_names = _create_fw_payloads_by_names,
    create_fw_build_config = _create_fw_build_config,
    create_fw_build_config_by_names = _create_fw_build_config_by_names,
    create_fw_build_targets = _create_fw_build_targets,
    create_power = _create_power,
    fw_type = _FW_TYPE,
)
