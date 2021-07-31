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
    "@proto//chromiumos/config/api/software/ui_config.proto",
    ui_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/build/api/firmware_config.proto",
    fw_pb = "chromiumos.build.api",
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

def _create_fw_version(major_version = None, minor_version = None, patch_version = None):
    """
    Builds a firmware Version proto.

    If major_version is not specified, None is returned.
    """
    return fw_pb.Version(
        major = major_version,
        minor = minor_version,
        patch = patch_version,
    ) if major_version else None

def _create_fw_payload(
        name = None,
        fw_type = _FW_TYPE.MAIN,
        major_version = 0,
        minor_version = 0,
        patch_version = 0):
    """Builds a FirmwarePayload proto."""
    return fw_pb.FirmwarePayload(
        firmware_image_name = name,
        type = fw_type,
        version = fw_pb.Version(major = major_version, minor = minor_version, patch = patch_version),
    )

def _create_fw_build_targets(
        bmpblk = None,
        coreboot = None,
        depthcharge = None,
        ec = None,
        ec_extras = None,
        libpayload = None,
        zephyr_ec = None):
    """Builds a Firmware.BuildTargets proto."""
    return fw_pb.Firmware.BuildTargets(
        bmpblk = bmpblk,
        coreboot = coreboot,
        depthcharge = depthcharge,
        ec = ec,
        ec_extras = ec_extras,
        libpayload = libpayload,
        zephyr_ec = zephyr_ec,
    )

def _create_fw_build_config(build_targets):
    """Builds a FirmwareBuildConfig proto."""
    return fw_pb.FirmwareBuildConfig(build_targets = build_targets)

def _create_fw_build_config_by_names(
        coreboot_name,
        bmpblk_name = None,
        ec_name = None,
        depthcharge_name = None,
        libpayload_name = None,
        ec_extras = None,
        zephyr_ec_name = None):
    """Builds a FirmwareBuildConfig proto using common naming patterns.

    Build targets are set to be coreboot_name unless they are otherwise
    specified, e.g. depthcharge is set to coreboot_name unless
    depthcharge_name is specified. This function is provided as a convenience,
    as different firmware build targets often share the same name.
    """
    return fw_pb.FirmwareBuildConfig(
        build_targets = fw_pb.Firmware.BuildTargets(
            bmpblk = bmpblk_name,
            coreboot = coreboot_name,
            ec = ec_name if ec_name else coreboot_name,
            ec_extras = ec_extras,
            depthcharge = depthcharge_name if depthcharge_name else coreboot_name,
            libpayload = libpayload_name if libpayload_name else coreboot_name,
            zephyr_ec = zephyr_ec_name,
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

def _create_intel_antenna_gain(
        ant_gain_2g,
        ant_gain_5g_1,
        ant_gain_5g_2,
        ant_gain_5g_3,
        ant_gain_5g_4,
        ant_gain_5g_5 = None,
        ant_gain_6g_1 = None,
        ant_gain_6g_2 = None,
        ant_gain_6g_3 = None,
        ant_gain_6g_4 = None,
        ant_gain_6g_5 = None):
    """Builds AntennaGain for intel drivers.

    Args:
        ant_gain_2g: Antenna gain used for 2400MHz frequency.
        ant_gain_5g_1: Antenna gain used for 5150–5350MHz frequency. Required.
        ant_gain_5g_2: Antenna gain used for 5350–5470MHz frequency. Required.
        ant_gain_5g_3: Antenna gain used for 5470–5725MHz frequency. Required.
        ant_gain_5g_4: Antenna gain used for 5725–5950MHz frequency. Required.
        ant_gain_5g_5: Antenna gain used for 5945–6165MHz frequency. Rev 1 & 2.
        ant_gain_6g_1: Antenna gain used for 6165–6405MHz frequency. Rev 1 & 2.
        ant_gain_6g_2: Antenna gain used for 6405–6525MHz frequency. Rev 1 & 2.
        ant_gain_6g_3: Antenna gain used for 6525–6705MHz frequency. Rev 1 & 2.
        ant_gain_6g_4: Antenna gain used for 6705–6865MHz frequency. Rev 1 & 2.
        ant_gain_6g_5: Antenna gain used for 6865–7105MHz frequency. Rev 1 & 2.
    """
    return wf_pb.WifiConfig.IntelConfig.Gains.AntennaGain(
        ant_gain_2g = ant_gain_2g,
        ant_gain_5g_1 = ant_gain_5g_1,
        ant_gain_5g_2 = ant_gain_5g_2,
        ant_gain_5g_3 = ant_gain_5g_3,
        ant_gain_5g_4 = ant_gain_5g_4,
        ant_gain_5g_5 = ant_gain_5g_5,
        ant_gain_6g_1 = ant_gain_6g_1,
        ant_gain_6g_2 = ant_gain_6g_2,
        ant_gain_6g_3 = ant_gain_6g_3,
        ant_gain_6g_4 = ant_gain_6g_4,
        ant_gain_6g_5 = ant_gain_6g_5,
    )

def _create_intel_power_chain(
        limit_2g,
        limit_5g_1,
        limit_5g_2,
        limit_5g_3,
        limit_5g_4,
        limit_5g_5 = None,
        limit_6g_1 = None,
        limit_6g_2 = None,
        limit_6g_3 = None,
        limit_6g_4 = None,
        limit_6g_5 = None):
    """Builds a TransmitPowerChain for intel drivers.

    Args:
        limit_2g: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
        limit_5g_1: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
        limit_5g_2: 5G band 2 power limit: 5.35G-5.47G channels. (0.125 dBm). Required.
        limit_5g_3: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
        limit_5g_4: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.
        limit_5g_5: 5G band 5 power limit: 5.95G-6.165G channels. (0.125 dBm). Rev 1 & 2.
        limit_6g_1: 6G band 1 power limit: 6.165G-6.405G channels. (0.125 dBm). Rev 1 & 2.
        limit_6g_2: 6G band 2 power limit: 6.405G-6.525G channels. (0.125 dBm). Rev 1 & 2.
        limit_6g_3: 6G band 3 power limit: 6.525G-6.705G channels. (0.125 dBm). Rev 1 & 2.
        limit_6g_4: 6G band 4 power limit: 6.705G-6.865G channels. (0.125 dBm). Rev 1 & 2.
        limit_6g_5: 6G band 5 power limit: 6.865G-7.105G channels. (0.125 dBm). Rev 1 & 2.
    """
    return wf_pb.WifiConfig.IntelConfig.SarTable.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g_1 = limit_5g_1,
        limit_5g_2 = limit_5g_2,
        limit_5g_3 = limit_5g_3,
        limit_5g_4 = limit_5g_4,
        limit_5g_5 = limit_5g_5,
        limit_6g_1 = limit_6g_1,
        limit_6g_2 = limit_6g_2,
        limit_6g_3 = limit_6g_3,
        limit_6g_4 = limit_6g_4,
        limit_6g_5 = limit_6g_5,
    )

def _create_intel_geo_offsets(
        max_2g,
        offset_2g_a,
        offset_2g_b,
        max_5g,
        offset_5g_a,
        offset_5g_b,
        max_6g = None,
        offset_6g_a = None,
        offset_6g_b = None):
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
        max_6g: Defines the 6 GHz upper value for the allowed power to not be
                crossed by applying the Geo offset. Rev 1 & 2.
        offset_6g_a: Value to be added to 6GHz WiFi bands for chain a. (0.125 dBm) Rev 1 & 2.
        offset_6g_b: Value to be added to 6GHz WiFi bands for chain b. (0.125 dBm) Rev 1 & 2.
    """
    return wf_pb.WifiConfig.IntelConfig.Offsets.GeoOffsets(
        max_2g = max_2g,
        offset_2g_a = offset_2g_a,
        offset_2g_b = offset_2g_b,
        max_5g = max_5g,
        offset_5g_a = offset_5g_a,
        offset_5g_b = offset_5g_b,
        max_6g = max_6g,
        offset_6g_a = offset_6g_a,
        offset_6g_b = offset_6g_b,
    )

def _create_intel_antgain_table(
        ant_table_revision = 0xff,
        ant_ppag_mode = None,
        ant_gain_chain_a = None,
        ant_gain_chain_b = None):
    """Builds a antenna Gains for intel drivers.

    Args:
        ant_table_revision: Antenna gains table revision
        ant_ppag_mode: Defines the mode of the ANT_gain control to be used.
        ant_gain_chain_a: Defines the ANT_gain in dBi for chain A to be used.
        ant_gain_chain_b: Defines the ANT_gain in dBi for chain B to be used.
    """
    return wf_pb.WifiConfig.IntelConfig.Gains(
        ant_table_version = ant_table_revision,
        ant_mode_ppag = ant_ppag_mode,
        ant_gain_table_a = ant_gain_chain_a,
        ant_gain_table_b = ant_gain_chain_b,
    )

def _create_intel_dsm(
        disable_active_sdr_channels = -1,
        support_indonesia_5g_band = -1,
        support_ultra_high_band = -1,
        regulatory_configurations = -1,
        uart_configurations = -1,
        enablement_11ax = -1,
        unii_4 = -1):
    """Builds a DSM for intel drivers.

    Args:
        disable_active_sdr_channels: Allow OEMs to set ETSI 5.8GHz SRD Channels to Passive/Disabled.
        support_indonesia_5g_band: Enable/Disable 5.15-5.35GHz band support in Indonesia.
        support_ultra_high_band: Control the enablement of 6 GHz band.
        regulatory_configurations: Regulatory special configurations enablements value.
        uart_configurations: M.2 UART interface configuration.
        enablement_11ax: Control enablement of 11ax on certificated modules.
        unii_4: Control enablement of UNII-4 over certificate modules.
    """
    return wf_pb.WifiConfig.IntelConfig.DSM(
        disable_active_sdr_channels = disable_active_sdr_channels,
        support_indonesia_5g_band = support_indonesia_5g_band,
        support_ultra_high_band = support_ultra_high_band,
        regulatory_configurations = regulatory_configurations,
        uart_configurations = uart_configurations,
        enablement_11ax = enablement_11ax,
        unii_4 = unii_4,
    )

def _create_intel_sar_table(
        sar_table_revision = 0xff,
        tablet_mode_transmit_power_chain_a = None,
        tablet_mode_transmit_power_chain_b = None,
        non_tablet_mode_transmit_power_chain_a = None,
        non_tablet_mode_transmit_power_chain_b = None,
        cdb_tablet_mode_transmit_power_chain_a = None,
        cdb_tablet_mode_transmit_power_chain_b = None,
        cdb_non_tablet_mode_transmit_power_chain_a = None,
        cdb_non_tablet_mode_transmit_power_chain_b = None):
    """Builds a SarTable proto for use with intel drivers.

    Args:
        sar_table_revision: SAR table revision.
        tablet_mode_transmit_power_chain_a: Tablet mode power chain for chain a.
        tablet_mode_transmit_power_chain_b: Tablet mode power chain for chain b.
        non_tablet_mode_transmit_power_chain_a: Non-tablet mode power chain for chain a.
        non_tablet_mode_transmit_power_chain_b: Non-tablet mode power chain for chain b.
        cdb_tablet_mode_transmit_power_chain_a: Tablet mode concurrency dual band power chain for chain a.
        cdb_tablet_mode_transmit_power_chain_b: Tablet mode concurrency dual band power chain for chain b.
        cdb_non_tablet_mode_transmit_power_chain_a: Non-tablet mode concurrency dual band power chain for chain a.
        cdb_non_tablet_mode_transmit_power_chain_b: Non-tablet mode concurrency dual band power chain for chain b.
    """
    return wf_pb.WifiConfig.IntelConfig.SarTable(
        sar_table_version = sar_table_revision,
        tablet_mode_power_table_a = tablet_mode_transmit_power_chain_a,
        tablet_mode_power_table_b = tablet_mode_transmit_power_chain_b,
        non_tablet_mode_power_table_a = non_tablet_mode_transmit_power_chain_a,
        non_tablet_mode_power_table_b = non_tablet_mode_transmit_power_chain_b,
        cdb_tablet_mode_power_table_a = cdb_tablet_mode_transmit_power_chain_a,
        cdb_tablet_mode_power_table_b = cdb_tablet_mode_transmit_power_chain_b,
        cdb_non_tablet_mode_power_table_a = cdb_non_tablet_mode_transmit_power_chain_a,
        cdb_non_tablet_mode_power_table_b = cdb_non_tablet_mode_transmit_power_chain_b,
    )

def _create_intel_offsets_table(
        wgds_revision = 0xff,
        fcc_offsets = None,
        eu_offsets = None,
        other_offsets = None):
    """Builds a Geo Offsets proto for use with intel drivers.

    Args:
        wgds_revision: Geo delta table revision,
        fcc_offsets: Offsets used for regulatory domains that follow FCC guidelines.
        eu_offsets: Offsets used for regulatory domains that follow ESTI guidelines.
        other_offsets: Offsets for regulatory domains that don't follow FCC or ETSI guidelines.
    """
    return wf_pb.WifiConfig.IntelConfig.Offsets(
        wgds_version = wgds_revision,
        offset_fcc = fcc_offsets,
        offset_eu = eu_offsets,
        offset_other = other_offsets,
    )

def _create_intel_sar_avg_table(
        wtas_revision = 0xffff,
        tas_selection = 0,
        tas_list_size = 0,
        deny_list_entry_1 = 0,
        deny_list_entry_2 = 0,
        deny_list_entry_3 = 0,
        deny_list_entry_4 = 0,
        deny_list_entry_5 = 0,
        deny_list_entry_6 = 0,
        deny_list_entry_7 = 0,
        deny_list_entry_8 = 0,
        deny_list_entry_9 = 0,
        deny_list_entry_10 = 0,
        deny_list_entry_11 = 0,
        deny_list_entry_12 = 0,
        deny_list_entry_13 = 0,
        deny_list_entry_14 = 0,
        deny_list_entry_15 = 0,
        deny_list_entry_16 = 0):
    """Builds a wifi time average SAR proto for use with intel drivers.

    Args:
        wtas_revision: Wifi time average SAR version.
        tas_selection: Enable/disable the TAS feature.
        tas_list_size: Represents the number of blocked countries that are not approved by the
                       OEM to support this feature, even if that feature is enabled.
        deny_list_entry_1: ISO country code 1 to block.
        deny_list_entry_2: ISO country code 2 to block.
        deny_list_entry_3: ISO country code 3 to block.
        deny_list_entry_4: ISO country code 4 to block.
        deny_list_entry_5: ISO country code 5 to block.
        deny_list_entry_6: ISO country code 6 to block.
        deny_list_entry_7: ISO country code 7 to block.
        deny_list_entry_8: ISO country code 8 to block.
        deny_list_entry_9: ISO country code 9 to block.
        deny_list_entry_10: ISO country code 10 to block.
        deny_list_entry_11: ISO country code 11 to block.
        deny_list_entry_12: ISO country code 12 to block.
        deny_list_entry_13: ISO country code 13 to block.
        deny_list_entry_14: ISO country code 14 to block.
        deny_list_entry_15: ISO country code 15 to block.
        deny_list_entry_16: ISO country code 16 to block.
    """
    return wf_pb.WifiConfig.IntelConfig.Average(
        sar_avg_version = wtas_revision,
        tas_selection = tas_selection,
        tas_list_size = tas_list_size,
        deny_list_entry_1 = deny_list_entry_1,
        deny_list_entry_2 = deny_list_entry_2,
        deny_list_entry_3 = deny_list_entry_3,
        deny_list_entry_4 = deny_list_entry_4,
        deny_list_entry_5 = deny_list_entry_5,
        deny_list_entry_6 = deny_list_entry_6,
        deny_list_entry_7 = deny_list_entry_7,
        deny_list_entry_8 = deny_list_entry_8,
        deny_list_entry_9 = deny_list_entry_9,
        deny_list_entry_10 = deny_list_entry_10,
        deny_list_entry_11 = deny_list_entry_11,
        deny_list_entry_12 = deny_list_entry_12,
        deny_list_entry_13 = deny_list_entry_13,
        deny_list_entry_14 = deny_list_entry_14,
        deny_list_entry_15 = deny_list_entry_15,
        deny_list_entry_16 = deny_list_entry_16,
    )

def _create_intel_wifi(
        sar_table = _create_intel_sar_table(),
        wgds_table = _create_intel_offsets_table(),
        ant_table = _create_intel_antgain_table(),
        wtas_table = _create_intel_sar_avg_table(),
        dsm = _create_intel_dsm()):
    """Builds a IntelConfig proto for use with intel drivers.

    Args:
        sar_table: SarTable proto for use with intel driver.
        wgds_table: Geo Offsets proto for use with intel driver.
        ant_table: Antenna Gains for use with intel driver.
        wtas_table: Time average SAR for use with intel driver.
        dsm: Device specific methods return values for intel driver.
    """
    return wf_pb.WifiConfig(
        intel_config = wf_pb.WifiConfig.IntelConfig(
            sar_table = sar_table,
            wgds_table = wgds_table,
            ant_table = ant_table,
            wtas_table = wtas_table,
            dsm = dsm,
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

_UI_REQUISITION = struct(
    CHROMEOS = ui_pb.UiConfig.REQUISITION_CHROMEOS,
    MEETHW = ui_pb.UiConfig.REQUISITION_MEETHW,
)

def _create_ui(
        extra_web_apps_dir = None,
        requisition = None):
    return ui_pb.UiConfig(
        extra_web_apps_dir = extra_web_apps_dir,
        requisition = requisition,
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
    create_intel_antenna_gain = _create_intel_antenna_gain,
    create_intel_antgain_table = _create_intel_antgain_table,
    create_intel_dsm = _create_intel_dsm,
    create_intel_geo_offsets = _create_intel_geo_offsets,
    create_intel_offsets_table = _create_intel_offsets_table,
    create_intel_power_chain = _create_intel_power_chain,
    create_intel_sar_table = _create_intel_sar_table,
    create_intel_sar_avg_table = _create_intel_sar_avg_table,
    create_intel_wifi = _create_intel_wifi,
    create_rtw88 = _create_rtw88,
    create_rtw88_geo_offsets = _create_rtw88_geo_offsets,
    create_rtw88_power_chain = _create_rtw88_power_chain,
    create_ui = _create_ui,
    fw_type = _FW_TYPE,
    ui_requisition = _UI_REQUISITION,
    make_resolution = _make_resolution,
)
