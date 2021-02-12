"""Functions related to software configs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/software/audio_config.proto",
    audio_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/camera_config.proto",
    cam_pb = "chromiumos.config.api.software",
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
    "@proto//chromiumos/config/api/software/wifi_config.proto",
    wf_pb = "chromiumos.config.api.software",
)
load("//config/util/public_replication.star", "public_replication")

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
    """Builds a Firmware.BuildTargets proto."""
    return fw_pb.Firmware.BuildTargets(
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
        build_targets = fw_pb.Firmware.BuildTargets(
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

def _create_audio(
        card_name,
        card_config_file = None,
        dsp_file = None,
        ucm_file = None,
        ucm_master_file = None,
        ucm_suffix = None,
        module_file = None,
        board_file = None,
        sound_card_init_file = None,
        card_id = None,
        public_fields = ["card_name"]):
    """Builds an AudioConfig proto."""
    return audio_pb.AudioConfig(
        public_replication = public_replication.create(public_fields = public_fields),
        card_name = card_name,
        card_config_file = card_config_file,
        dsp_file = dsp_file,
        ucm_file = ucm_file if ucm_file else ("ucm-config/%s/HiFi.conf" % card_name),
        ucm_master_file = ucm_master_file if ucm_master_file else ("ucm-config/%s/%s.conf" % (card_name, card_name)),
        ucm_suffix = ucm_suffix,
        module_file = module_file,
        board_file = board_file,
        sound_card_init_file = sound_card_init_file,
        card_id = card_id,
    )

def _create_bluetooth(flags):
    """Builds a BluetoothConfig proto."""
    return bt_pb.BluetoothConfig(flags = flags)

def _create_power(preferences):
    """Builds a PowerConfig proto."""
    return pc_pb.PowerConfig(preferences = preferences)

def _create_ath10k_power_chain(limit_2g, limit_5g):
    """Builds a TransmitPowerChain for ath10k drivers.

    Args:
        limit_2g: 2G band power limit (dBm). Required.
        limit_5g: 5G band power limit (dBm). Required.
    """
    return wf_pb.WifiConfig.Ath10kConfig.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g = limit_5g,
    )

def _create_ath10k(non_tablet_mode_transmit_power_chain, tablet_mode_transmit_power_chain):
    """Builds a WifiConfig proto for use with ath10k drivers.

    Args:
        non_tablet_mode_transmit_power_chain: non-tablet mode power chain. Required.
        tablet_mode_transmit_power_chain: tablet mode power chain. Required.
    """
    return wf_pb.WifiConfig(
        ath10k_config = wf_pb.WifiConfig.Ath10kConfig(
            non_tablet_mode_power_table = non_tablet_mode_transmit_power_chain,
            tablet_mode_power_table = tablet_mode_transmit_power_chain,
        ),
    )

def _create_rtw88_power_chain(
        limit_2g,
        limit_5g_1,
        limit_5g_3,
        limit_5g_4):
    """Builds a TransmitPowerChain for rtw88 drivers.

    Args:
        limit_2g: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
        limit_5g_1: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
        limit_5g_3: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
        limit_5g_4: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.
    """
    return wf_pb.WifiConfig.Rtw88Config.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g_1 = limit_5g_1,
        limit_5g_3 = limit_5g_3,
        limit_5g_4 = limit_5g_4,
    )

def _create_rtw88_geo_offsets(offset_2g, offset_5g):
    """Builds a GeoOffsets from rtw88 drivers.

    Args:
        offset_2g: Value to be added to the 2.4GHz WiFi band. (0.125 dBm) Required.
        offset_5g: Value to be added to all 5GHz WiFi bands. (0.125 dBm) Required.
    """
    return wf_pb.WifiConfig.Rtw88Config.GeoOffsets(
        offset_2g = offset_2g,
        offset_5g = offset_5g,
    )

def _create_rtw88(
        non_tablet_mode_transmit_power_chain,
        tablet_mode_transmit_power_chain,
        fcc_offsets = None,
        eu_offsets = None,
        other_offsets = None):
    """Builds a WifiConfig proto for use with rtw88 drivers.

    Args:
        non_tablet_mode_transmit_power_chain: non-tablet mode power chain. Required.
        tablet_mode_transmit_power_chain: tablet mode power chain. Required.
        fcc_offsets: Offsets used for regulatory domains that follow FCC guidelines
        eu_offsets: Offsets used for regulatory domains that follow ESTI guidelines
        other_offsets: Offsets for regulatory domains that don't follow FCC or ETSI guidelines
    """
    return wf_pb.WifiConfig(
        rtw88_config = wf_pb.WifiConfig.Rtw88Config(
            non_tablet_mode_power_table = non_tablet_mode_transmit_power_chain,
            tablet_mode_power_table = tablet_mode_transmit_power_chain,
            offset_fcc = fcc_offsets,
            offset_eu = eu_offsets,
            offset_other = other_offsets,
        ),
    )

def _create_intel_power_chain(
        limit_2g,
        limit_5g_1,
        limit_5g_2,
        limit_5g_3,
        limit_5g_4):
    """Builds a TransmitPowerChain for intel drivers.

    Args:
        limit_2g: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
        limit_5g_1: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
        limit_5g_2: 5G band 2 power limit: 5.35G-5.47G channels. (0.125 dBm). Required.
        limit_5g_3: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
        limit_5g_4: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.
    """
    return wf_pb.WifiConfig.IntelConfig.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g_1 = limit_5g_1,
        limit_5g_2 = limit_5g_2,
        limit_5g_3 = limit_5g_3,
        limit_5g_4 = limit_5g_4,
    )

def _create_intel_geo_offsets(
        max_2g,
        offset_2g_a,
        offset_2g_b,
        max_5g,
        offset_5g_a,
        offset_5g_b):
    """Builds a GeoOffsets for intel drivers.

    Args:
        max_2g: Defines the 2.4 GHz upper value for the allowed power to not be
            crossed by applying the Geo offset. Required.
        offset_2g_a: Value to be added to the 2.4GHz WiFi band for chain a. (0.125 dBm) Required.
        offset_2g_b: Value to be added to the 2.4GHz WiFi band for chain b. (0.125 dBm) Required.
        max_5g: Defines the 5 GHz upper value for the allowed power to not be
            crossed by applying the Geo offset. Required.
        offset_5g_a: Value to be added to 5GHz WiFi bands for chain a. (0.125 dBm) Required.
        offset_5g_b: Value to be added to 5GHz WiFi bands for chain b. (0.125 dBm) Required.
    """
    return wf_pb.WifiConfig.IntelConfig.GeoOffsets(
        max_2g = max_2g,
        offset_2g_a = offset_2g_a,
        offset_2g_b = offset_2g_b,
        max_5g = max_5g,
        offset_5g_a = offset_5g_a,
        offset_5g_b = offset_5g_b,
    )

def _create_intel_wifi(
        tablet_mode_transmit_power_chain_a,
        tablet_mode_transmit_power_chain_b,
        non_tablet_mode_transmit_power_chain_a,
        non_tablet_mode_transmit_power_chain_b,
        fcc_offsets = None,
        eu_offsets = None,
        other_offsets = None):
    """Builds a WifiConfig proto for use with intel drivers.

    Args:
        non_tablet_mode_transmit_power_chain_a: non-tablet mode power chain for chain a. Required.
        non_tablet_mode_transmit_power_chain_b: non-tablet mode power chain for chain b. Required.
        tablet_mode_transmit_power_chain_a: tablet mode power chain for chain a. Required.
        tablet_mode_transmit_power_chain_b: tablet mode power chain for chain b. Required.
        fcc_offsets: Offsets used for regulatory domains that follow FCC guidelines. Required.
        eu_offsets: Offsets used for regulatory domains that follow ESTI guidelines. Required.
        other_offsets: Offsets for regulatory domains that don't follow FCC or ETSI guidelines. Required.
    """
    return wf_pb.WifiConfig(
        intel_config = wf_pb.WifiConfig.IntelConfig(
            tablet_mode_power_table_a = tablet_mode_transmit_power_chain_a,
            tablet_mode_power_table_b = tablet_mode_transmit_power_chain_b,
            non_tablet_mode_power_table_a = non_tablet_mode_transmit_power_chain_a,
            non_tablet_mode_power_table_b = non_tablet_mode_transmit_power_chain_b,
            wgds_version = 0,
            offset_fcc = fcc_offsets,
            offset_eu = eu_offsets,
            offset_other = other_offsets,
        ),
    )

def _create_camera(
        generate_media_profiles = False,
        camcorder_resolutions = None):
    """Builds a CameraConfig proto."""
    return cam_pb.CameraConfig(
        generate_media_profiles = generate_media_profiles,
        camcorder_resolutions = camcorder_resolutions if camcorder_resolutions else [],
    )

def _make_resolution(width, height):
    return cam_pb.Resolution(width = width, height = height)

sw_config = struct(
    create_ath10k = _create_ath10k,
    create_ath10k_power_chain = _create_ath10k_power_chain,
    create_audio = _create_audio,
    create_bluetooth = _create_bluetooth,
    create_camera = _create_camera,
    create_fw_version = _create_fw_version,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    create_fw_payloads_by_names = _create_fw_payloads_by_names,
    create_fw_build_config = _create_fw_build_config,
    create_fw_build_config_by_names = _create_fw_build_config_by_names,
    create_fw_build_targets = _create_fw_build_targets,
    create_power = _create_power,
    create_intel_geo_offsets = _create_intel_geo_offsets,
    create_intel_power_chain = _create_intel_power_chain,
    create_intel_wifi = _create_intel_wifi,
    create_rtw88 = _create_rtw88,
    create_rtw88_geo_offsets = _create_rtw88_geo_offsets,
    create_rtw88_power_chain = _create_rtw88_power_chain,
    fw_type = _FW_TYPE,
    make_resolution = _make_resolution,
)
