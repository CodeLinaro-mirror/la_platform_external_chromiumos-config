"""Functions related to software configs.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/build/api/firmware_config.proto",
    fw_pb = "chromiumos.build.api",
)
load(
    "@proto//chromiumos/config/api/resource_config.proto",
    resource_pb = "chromiumos.config.api",
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
    "@proto//chromiumos/config/api/software/camera_config.proto",
    cam_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/firmware_info.proto",
    fw_info_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/health_config.proto",
    health_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/nnpalm_config.proto",
    nnpalm_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/power_config.proto",
    pc_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/rma_config.proto",
    rma_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/ui_config.proto",
    ui_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/usb_config.proto",
    usb_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/wifi_config.proto",
    wf_pb = "chromiumos.config.api",
)

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/public_replication.star", "public_replication")

_FW_TYPE = struct(
    MAIN = fw_pb.FirmwareType.MAIN,
    EC = fw_pb.FirmwareType.EC,
    PD = fw_pb.FirmwareType.PD,
)

_HASH_ALGORITHM = struct(
    MD5SUM = fw_pb.FirmwarePayloadHash.MD5SUM,
)

_SUPPORT_BAND = struct(
    DISABLED = 0,
    BIOS_AND_OS = 1,
    OS_ONLY = 2,
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
        ish = None,
        libpayload = None,
        zephyr_ec = None,
        zephyr_detachable_base = None):
    """Builds a Firmware.BuildTargets proto."""
    return fw_pb.Firmware.BuildTargets(
        bmpblk = bmpblk,
        coreboot = coreboot,
        depthcharge = depthcharge,
        ec = ec,
        ec_extras = ec_extras,
        ish = ish,
        libpayload = libpayload,
        zephyr_ec = zephyr_ec,
        zephyr_detachable_base = zephyr_detachable_base,
    )

def _create_fw_build_config(build_targets):
    """Builds a FirmwareBuildConfig proto."""
    return fw_pb.FirmwareBuildConfig(build_targets = build_targets)

def _create_fw_build_config_by_names(
        coreboot_name,
        bmpblk_name = None,
        ec_name = None,
        depthcharge_name = None,
        ish_name = None,
        libpayload_name = None,
        ec_extras = None,
        zephyr_ec_name = None,
        zephyr_detachable_base_name = None):
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
            ec = ec_name,
            ec_extras = ec_extras,
            depthcharge = depthcharge_name if depthcharge_name else coreboot_name,
            ish = ish_name,
            libpayload = libpayload_name if libpayload_name else coreboot_name,
            zephyr_ec = zephyr_ec_name,
            zephyr_detachable_base = zephyr_detachable_base_name,
        ),
    )

def _create_fw_config(
        ro = None,
        rw = None,
        ec_ro = None,
        ec_rw = None,
        pd = None,
        ap_rw_a_hash = None,
        ap_rw_a_hash_algorithm = _HASH_ALGORITHM.MD5SUM):
    """Builds a FirmwareConfig proto."""
    return fw_pb.FirmwareConfig(
        main_ro_payload = ro,
        main_rw_payload = rw,
        ec_ro_payload = ec_ro,
        ec_rw_payload = ec_rw,
        pd_ro_payload = pd,
        main_rw_a_hash = fw_pb.FirmwarePayloadHash(
            algorithm = ap_rw_a_hash_algorithm,
            digest = ap_rw_a_hash,
        ) if ap_rw_a_hash else None,
    )

def _create_fw_payloads_by_names(
        ap_fw_name = None,
        ec_fw_name = None,
        pd_fw_name = None,
        ap_ro_version = None,
        ap_rw_version = None,
        ec_ro_version = None,
        ec_rw_version = None,
        ec_version = None,
        pd_version = None,
        ap_rw_a_hash = None,
        ap_rw_a_hash_algorithm = _HASH_ALGORITHM.MD5SUM):
    """Builds a FirmwareConfig proto using common naming patterns.

    NOTE: `ec_version` is deprecated. Please use `ec_ro_version` and
    `ec_rw_version`.
    """
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
        ec_fw_name = ec_fw_name or "%s_EC" % ap_fw_name
        sc_fw_config.ec_ro_payload = fw_pb.FirmwarePayload(
            firmware_image_name = ec_fw_name,
            type = _FW_TYPE.EC,
            version = ec_ro_version or ec_version,
        )
        if ec_rw_version:
            sc_fw_config.ec_rw_payload = fw_pb.FirmwarePayload(
                firmware_image_name = ec_fw_name,
                type = _FW_TYPE.EC,
                version = ec_rw_version,
            )
    if pd_fw_name:
        sc_fw_config.pd_ro_payload = fw_pb.FirmwarePayload(
            firmware_image_name = pd_fw_name,
            type = _FW_TYPE.PD,
            version = pd_version,
        )

    if ap_rw_a_hash:
        sc_fw_config.main_rw_a_hash = fw_pb.FirmwarePayloadHash(
            algorithm = ap_rw_a_hash_algorithm,
            digest = ap_rw_a_hash,
        )

    return sc_fw_config if ap_fw_name else None

def _create_audio(
        card_name,
        cras_custom_name = None,
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
        cras_custom_name = cras_custom_name,
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

def _create_health(
        vpd_has_sku_number = None,
        battery_has_smart_battery_info = None,
        routines_battery_health_percent_battery_wear_allowed = None,
        routines_nvme_wear_level_wear_level_threshold = None):
    """Builds a HealthConfig proto."""
    routines = None
    battery_health = None
    nvme_wear_level = None
    if routines_battery_health_percent_battery_wear_allowed != None:
        battery_health = health_pb.HealthConfig.BatteryHealth(
            percent_battery_wear_allowed =
                routines_battery_health_percent_battery_wear_allowed,
        )
    if routines_nvme_wear_level_wear_level_threshold != None:
        nvme_wear_level = health_pb.HealthConfig.NvmeWearLevel(
            wear_level_threshold =
                routines_nvme_wear_level_wear_level_threshold,
        )
    if battery_health or nvme_wear_level:
        routines = health_pb.HealthConfig.Routines(
            battery_health = battery_health,
            nvme_wear_level = nvme_wear_level,
        )
    return health_pb.HealthConfig(
        cached_vpd = health_pb.HealthConfig.CachedVpd(
            has_sku_number = vpd_has_sku_number,
        ),
        battery = health_pb.HealthConfig.Battery(
            has_smart_battery_info = battery_has_smart_battery_info,
        ),
        routines = routines,
    )

def _create_fw_info(
        has_alt_fw = None,
        has_splash_screen = None):
    """Builds an FirmwareInfo proto."""
    firmware_info = None

    if has_alt_fw or has_splash_screen:
        firmware_info = fw_info_pb.FirmwareInfo(
            has_alt_firmware = has_alt_fw,
            has_splash_screen = has_splash_screen,
        )

    return firmware_info

def _create_ssfc_probeable_component(
        identifier = None,
        value = None):
    """Builds an SsfcProbeableComponent proto."""
    return rma_pb.RmaConfig.SsfcConfig.SsfcComponentTypeConfig.SsfcProbeableComponent(
        identifier = identifier,
        value = value,
    )

def _create_ssfc_component_type_config(
        component_type = None,
        default_value = None,
        probeable_components = None):
    """Builds an SsfcComponentTypeConfig proto."""
    return rma_pb.RmaConfig.SsfcConfig.SsfcComponentTypeConfig(
        component_type = component_type,
        default_value = default_value,
        probeable_components = probeable_components,
    )

def _create_ssfc(
        mask = None,
        component_type_configs = None):
    """Builds an SsfcConfig proto."""
    return rma_pb.RmaConfig.SsfcConfig(
        mask = mask,
        component_type_configs = component_type_configs,
    )

def _create_rma(
        enabled = None,
        has_cbi = None,
        ssfc_config = None,
        use_legacy_custom_label = None):
    """Builds an RmaConfig proto."""
    return rma_pb.RmaConfig(
        enabled = enabled,
        has_cbi = has_cbi,
        ssfc_config = ssfc_config,
        use_legacy_custom_label = use_legacy_custom_label,
    )

def _create_nnpalm(
        model = None,
        radius_polynomial = None,
        touch_compatible = None):
    """Builds a NnpalmConfig proto."""
    return nnpalm_pb.NnpalmConfig(
        model = model,
        radius_polynomial = radius_polynomial,
        touch_compatible = touch_compatible,
    )

def _create_power(preferences):
    """Builds a PowerConfig proto."""
    return pc_pb.PowerConfig(preferences = preferences)

def _create_resource(ac = None, dc = None):
    """Builds a ResourceConfig proto.

    Args:
        ac: PowerSourcePreferences
        dc: PowerSourcePreferences
    """
    return resource_pb.ResourceConfig(
        ac = ac,
        dc = dc,
    )

def _create_power_source_preference(
        default = None,
        web_rtc = None,
        fullscreen_video = None,
        vm_boot = None,
        borealis_gaming = None,
        arcvm_gaming = None,
        battery_saver = None):
    """Builds a PowerSourcePreferences proto.

    Args:
        default: PowerPreferences
        web_rtc: PowerPreferences
        fullscreen_video: PowerPreferences
        vm_boot: PowerPreferences
        borealis_gaming: PowerPreferences
        arcvm_gaming: PowerPreferences
    """
    return resource_pb.ResourceConfig.PowerSourcePreferences(
        default_power_preferences = default,
        web_rtc_power_preferences = web_rtc,
        fullscreen_video_power_preferences = fullscreen_video,
        vm_boot_power_preferences = vm_boot,
        borealis_gaming_power_preferences = borealis_gaming,
        arcvm_gaming_power_preferences = arcvm_gaming,
        battery_saver_power_preferences = battery_saver,
    )

def _create_power_preference(governor = None, epp = None, cpu_offline = None):
    """Builds a PowerPreferences proto.

    Args:
        governor: Governor
        epp: EnergyPerformancePreference
    """
    return resource_pb.ResourceConfig.PowerPreferences(
        governor = governor,
        epp = epp,
        cpu_offline = cpu_offline,
    )

def _create_conservative_governor():
    """Builds a conservative governor Governor proto"""
    return resource_pb.ResourceConfig.Governor(
        conservative = resource_pb.ResourceConfig.ConservativeGovernor(),
    )

def _create_ondemand_governor(powersave_bias, sampling_rate_ms = 0):
    """Builds an ondemand governor Governor proto

    Args:
        powersave_bias: powersave bias for the ondemand governor
        sampling_rate_ms: sampling rate in ms for the ondemand governor
    """
    if sampling_rate_ms == 1:
        fail("sampling_rate_ms should be set to 0 or >= 2")

    return resource_pb.ResourceConfig.Governor(
        ondemand = resource_pb.ResourceConfig.OndemandGovernor(
            powersave_bias = powersave_bias,
            sampling_rate_ms = sampling_rate_ms,
        ),
    )

def _create_performance_governor():
    """Builds a performance governor Governor proto"""
    return resource_pb.ResourceConfig.Governor(
        performance = resource_pb.ResourceConfig.PerformanceGovernor(),
    )

def _create_powersave_governor():
    """Builds a powersave governor Governor proto"""
    return resource_pb.ResourceConfig.Governor(
        powersave = resource_pb.ResourceConfig.PowersaveGovernor(),
    )

def _create_schedutil_governor():
    """Builds a schedutil governor Governor proto"""
    return resource_pb.ResourceConfig.Governor(
        schedutil = resource_pb.ResourceConfig.SchedutilGovernor(),
    )

def _create_userspace_governor():
    """Builds an userspace governor Governor proto"""
    return resource_pb.ResourceConfig.Governor(
        userspace = resource_pb.ResourceConfig.UserspaceGovernor(),
    )

def _create_default_epp():
    """Builds a default epp EnergyPerformancePreference proto"""
    return resource_pb.ResourceConfig.EnergyPerformancePreference(
        default = resource_pb.ResourceConfig.DefaultEpp(),
    )

def _create_performance_epp():
    """Builds a performance epp EnergyPerformancePreference proto"""
    return resource_pb.ResourceConfig.EnergyPerformancePreference(
        performance = resource_pb.ResourceConfig.PerformanceEpp(),
    )

def _create_balance_performance_epp():
    """Builds a balance_performance epp EnergyPerformancePreference proto"""
    return resource_pb.ResourceConfig.EnergyPerformancePreference(
        balance_performance = resource_pb.ResourceConfig.BalancePerformanceEpp(),
    )

def _create_balance_power_epp():
    """Builds a balance_power epp EnergyPerformancePreference proto"""
    return resource_pb.ResourceConfig.EnergyPerformancePreference(
        balance_power = resource_pb.ResourceConfig.BalancePowerEpp(),
    )

def _create_power_epp():
    """Builds a power epp EnergyPerformancePreference proto"""
    return resource_pb.ResourceConfig.EnergyPerformancePreference(
        power = resource_pb.ResourceConfig.PowerEpp(),
    )

def _create_cpu_offline_small_core(min_active_threads = None):
    """Builds a cpu offline small core policy CpuOfflinePreference proto"""
    return resource_pb.ResourceConfig.CpuOfflinePreference(
        small_core = resource_pb.ResourceConfig.CpuOfflineSmallCore(
            min_active_threads = min_active_threads,
        ),
    )

def _create_cpu_offline_smt(min_active_threads = None):
    """Builds a cpu offline SMT policy CpuOfflinePreference proto"""
    return resource_pb.ResourceConfig.CpuOfflinePreference(
        smt = resource_pb.ResourceConfig.CpuOfflineSMT(
            min_active_threads = min_active_threads,
        ),
    )

def _create_cpu_offline_half(min_active_threads = None):
    """Builds a cpu offline half policy CpuOfflinePreference proto"""
    return resource_pb.ResourceConfig.CpuOfflinePreference(
        half = resource_pb.ResourceConfig.CpuOfflineHalf(
            min_active_threads = min_active_threads,
        ),
    )

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

def _create_rtw89_power_chain(
        limit_2g,
        limit_5g_1,
        limit_5g_3,
        limit_5g_4,
        limit_6g_1 = None,
        limit_6g_2 = None,
        limit_6g_3 = None,
        limit_6g_4 = None,
        limit_6g_5 = None,
        limit_6g_6 = None):
    """Builds a TransmitPowerChain for rtw89 drivers.

    Args:
        limit_2g: 2G band power limit: All 2G band channels. (0.25 dBm). Required.
        limit_5g_1: 5G band 1 power limit: 5.15G-5.35G channels. (0.25 dBm). Required.
        limit_5g_3: 5G band 3 power limit: 5.47G-5.725G channels. (0.25 dBm). Required.
        limit_5g_4: 5G band 4 power limit: 5.725G-5.95G channels. (0.25 dBm). Required.
        limit_6g_1: 6G band 1 power limit: 5.955G-6.155G channels. (0.25 dBm). Required.
        limit_6g_2: 6G band 2 power limit: 6.175G-6.415G channels. (0.25 dBm). Required.
        limit_6g_3: 6G band 3 power limit: 6.435G-6.515G channels. (0.25 dBm). Required.
        limit_6g_4: 6G band 4 power limit: 6.535G-6.695G channels. (0.25 dBm). Required.
        limit_6g_5: 6G band 5 power limit: 6.715G-6.855G channels. (0.25 dBm). Required
        limit_6g_6: 6G band 6 power limit: 6.895G-7.115G channels. (0.25 dBm). Required.
    """
    return wf_pb.WifiConfig.Rtw89Config.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g_1 = limit_5g_1,
        limit_5g_3 = limit_5g_3,
        limit_5g_4 = limit_5g_4,
        limit_6g_1 = limit_6g_1,
        limit_6g_2 = limit_6g_2,
        limit_6g_3 = limit_6g_3,
        limit_6g_4 = limit_6g_4,
        limit_6g_5 = limit_6g_5,
        limit_6g_6 = limit_6g_6,
    )

def _create_rtw89_geo_offsets(offset_2g, offset_5g, offset_6g = None):
    """Builds a GeoOffsets from rtw89 drivers.

    Args:
        offset_2g: Value to be added to the 2.4GHz WiFi band. (0.25 dBm) Required.
        offset_5g: Value to be added to all 5GHz WiFi bands. (0.25 dBm) Required.
        offset_6g: Value to be added to all 6GHz WiFi bands. (0.25 dBm) Required.
    """
    return wf_pb.WifiConfig.Rtw89Config.GeoOffsets(
        offset_2g = offset_2g,
        offset_5g = offset_5g,
        offset_6g = offset_6g,
    )

def _create_rtw89(
        non_tablet_mode_transmit_power_chain,
        tablet_mode_transmit_power_chain,
        fcc_offsets = None,
        eu_offsets = None,
        other_offsets = None):
    """Builds a WifiConfig proto for use with rtw89 drivers.

    Args:
        non_tablet_mode_transmit_power_chain: non-tablet mode power chain. Required.
        tablet_mode_transmit_power_chain: tablet mode power chain. Required.
        fcc_offsets: Offsets used for regulatory domains that follow FCC guidelines
        eu_offsets: Offsets used for regulatory domains that follow ESTI guidelines
        other_offsets: Offsets for regulatory domains that don't follow FCC or ETSI guidelines
    """
    return wf_pb.WifiConfig(
        rtw89_config = wf_pb.WifiConfig.Rtw89Config(
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

def _create_legacy_intel_wifi():
    return wf_pb.WifiConfig(
        legacy_intel_config = wf_pb.WifiConfig.LegacyIntelConfig(),
    )

def _create_mtk_geo_power_chain(
        limit_2g,
        limit_5g,
        offset_2g,
        offset_5g,
        limit_6g = None,
        offset_6g = None):
    """Builds a GeoTransmitPowerChain for mtk drivers.

    Args:
        limit_2g: 2G band geo power limit. (0.25 dBm). Required.
        limit_5g: 5G band geo power limit. (0.25 dBm). Required.
        offset_2g: Value to be added to the 2.4GHz WiFi band. (0.25 dBm). Required.
        offset_5g: Value to be added to all 5GHz WiFi bands. (0.25 dBm). Required.
        limit_6g: 6G band geo power limit. (0.25 dBm).
        offset_6g: Value to be added to all 6GHz WiFi bands. (0.25 dBm).
    """
    return wf_pb.WifiConfig.MtkConfig.GeoTransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g = limit_5g,
        offset_2g = offset_2g,
        offset_5g = offset_5g,
        limit_6g = limit_6g,
        offset_6g = offset_6g,
    )

def _create_mtk_power_chain(
        limit_2g,
        limit_5g_1,
        limit_5g_2,
        limit_5g_3,
        limit_5g_4,
        limit_6g_1 = None,
        limit_6g_2 = None,
        limit_6g_3 = None,
        limit_6g_4 = None,
        limit_6g_5 = None,
        limit_6g_6 = None):
    """Builds a TransmitPowerChain for mtk drivers.

    Args:
        limit_2g: 2G band power limit. (0.25 dBm). Required.
        limit_5g_1: 5G band 1 power limit: 5.15G-5.35G frequency. (0.25 dBm). Required.
        limit_5g_2: 5G band 2 power limit: 5.35G-5.47G frequency. (0.25 dBm). Required.
        limit_5g_3: 5G band 3 power limit: 5.47G-5.725G frequency. (0.25 dBm). Required.
        limit_5g_4: 5G band 4 power limit: 5.725G-5.95G frequency. (0.25 dBm). Required.
        limit_6g_1: 6G band 1 power limit: 5.945G-6.165G frequency. (0.25 dBm).
        limit_6g_2: 6G band 2 power limit: 6.165G-6.405G frequency. (0.25 dBm).
        limit_6g_3: 6G band 3 power limit: 6.405G-6.525G frequency. (0.25 dBm).
        limit_6g_4: 6G band 4 power limit: 6.525G-6.705G frequency. (0.25 dBm).
        limit_6g_5: 6G band 5 power limit: 6.705G-6.865G frequency. (0.25 dBm).
        limit_6g_6: 6G band 6 power limit: 6.865G-7.125G frequency. (0.25 dBm).
    """
    return wf_pb.WifiConfig.MtkConfig.TransmitPowerChain(
        limit_2g = limit_2g,
        limit_5g_1 = limit_5g_1,
        limit_5g_2 = limit_5g_2,
        limit_5g_3 = limit_5g_3,
        limit_5g_4 = limit_5g_4,
        limit_6g_1 = limit_6g_1,
        limit_6g_2 = limit_6g_2,
        limit_6g_3 = limit_6g_3,
        limit_6g_4 = limit_6g_4,
        limit_6g_5 = limit_6g_5,
        limit_6g_6 = limit_6g_6,
    )

def _create_mtcl_table(
        version,
        support_6ghz,
        bitmask_6ghz,
        support_5p9ghz,
        bitmask_5p9ghz):
    """Builds a MtclTable for mtk drivers.

    Args:
        version: The version of the MTCL payload. Only version 2 is supported. Required.
        support_6ghz: Support 6GHz operation. 0 disables, 1 enables if the driver and BIOS support this country, 2 enables if the kernel driver would enable operation. Required.
        bitmask_6ghz: The bitmask representing which countries should have 6GHz operation enabled. Valid values are 0x0 - 0xFFFFFFFF0000 where the final two bytes MUST be zero. Required.
        support_5p9ghz: Support 5.9GHz operation. 0 disables, 1 enables if the driver and BIOS support this country, 2 enables if the kernel driver would enable operation. Required.
        bitmask_5p9ghz: The bitmask representing which countries should have 5.9GHz operation enabled. Valid values are 0x0 - 0xFFFFFFFF0000 where the final two bytes MUST be zero. Required.
    """
    return wf_pb.WifiConfig.MtkConfig.MtclTable(
        version = version,
        support_6ghz = support_6ghz,
        bitmask_6ghz = bitmask_6ghz,
        support_5p9ghz = support_5p9ghz,
        bitmask_5p9ghz = bitmask_5p9ghz,
    )

def _create_mtk_wifi(
        non_tablet_mode_transmit_power_chain,
        tablet_mode_transmit_power_chain,
        fcc_transmit_power_chain = None,
        eu_transmit_power_chain = None,
        other_transmit_power_chain = None,
        country_list = None):
    """Builds a WifiConfig proto for use with mtk drivers.

    Args:
        non_tablet_mode_transmit_power_chain: non-tablet mode power chain. Required.
        tablet_mode_transmit_power_chain: tablet mode power chain. Required.
        fcc_transmit_power_chain: power chain for regulatory domains that follow FCC guidelines.
        eu_transmit_power_chain: power chain for regulatory domains that follow ESTI guidelines.
        other_transmit_power_chain: power chain for regulatory domains that don't follow FCC or ETSI guidelines.
        country_list: country list definition for MTCL ACPI method.
    """
    return wf_pb.WifiConfig(
        mtk_config = wf_pb.WifiConfig.MtkConfig(
            non_tablet_mode_power_table = non_tablet_mode_transmit_power_chain,
            tablet_mode_power_table = tablet_mode_transmit_power_chain,
            fcc_power_table = fcc_transmit_power_chain,
            eu_power_table = eu_transmit_power_chain,
            other_power_table = other_transmit_power_chain,
            country_list = country_list,
        ),
    )

def _create_camera(
        generate_media_profiles = False,
        camcorder_resolutions = None,
        has_external_camera = False):
    """Builds a CameraConfig proto."""
    return cam_pb.CameraConfig(
        generate_media_profiles = generate_media_profiles,
        camcorder_resolutions = camcorder_resolutions if camcorder_resolutions else [],
        has_external_camera = has_external_camera,
    )

_UI_REQUISITION = struct(
    CHROMEOS = ui_pb.UiConfig.REQUISITION_CHROMEOS,
    MEETHW = ui_pb.UiConfig.REQUISITION_MEETHW,
)

def _create_ui(
        extra_web_apps_dir = None,
        requisition = None,
        cloud_gaming_device = None):
    return ui_pb.UiConfig(
        extra_web_apps_dir = extra_web_apps_dir,
        requisition = requisition,
        cloud_gaming_device = cloud_gaming_device,
    )

def _create_usb(
        dp_only = None):
    return usb_pb.UsbConfig(
        typecd = usb_pb.UsbConfig.TypeCD(
            dp_only = dp_only or False,
        ),
    )

def _make_resolution(width, height):
    return cam_pb.Resolution(width = width, height = height)

sw_config = struct(
    create_ath10k = _create_ath10k,
    create_ath10k_power_chain = _create_ath10k_power_chain,
    create_audio = _create_audio,
    create_bluetooth = _create_bluetooth,
    create_camera = _create_camera,
    create_fw_info = _create_fw_info,
    create_fw_version = _create_fw_version,
    create_fw_payload = _create_fw_payload,
    create_fw_config = _create_fw_config,
    create_fw_payloads_by_names = _create_fw_payloads_by_names,
    create_fw_build_config = _create_fw_build_config,
    create_fw_build_config_by_names = _create_fw_build_config_by_names,
    create_fw_build_targets = _create_fw_build_targets,
    create_health = _create_health,
    create_ssfc_probeable_component = _create_ssfc_probeable_component,
    create_ssfc_component_type_config = _create_ssfc_component_type_config,
    create_ssfc = _create_ssfc,
    create_rma = _create_rma,
    create_nnpalm = _create_nnpalm,
    create_power = _create_power,
    create_resource = _create_resource,
    create_power_source_preference = _create_power_source_preference,
    create_power_preference = _create_power_preference,
    create_conservative_governor = _create_conservative_governor,
    create_ondemand_governor = _create_ondemand_governor,
    create_performance_governor = _create_performance_governor,
    create_powersave_governor = _create_powersave_governor,
    create_schedutil_governor = _create_schedutil_governor,
    create_userspace_governor = _create_userspace_governor,
    create_default_epp = _create_default_epp,
    create_performance_epp = _create_performance_epp,
    create_balance_performance_epp = _create_balance_performance_epp,
    create_balance_power_epp = _create_balance_power_epp,
    create_power_epp = _create_power_epp,
    create_cpu_offline_small_core = _create_cpu_offline_small_core,
    create_cpu_offline_smt = _create_cpu_offline_smt,
    create_cpu_offline_half = _create_cpu_offline_half,
    create_intel_antenna_gain = _create_intel_antenna_gain,
    create_intel_antgain_table = _create_intel_antgain_table,
    create_intel_dsm = _create_intel_dsm,
    create_intel_geo_offsets = _create_intel_geo_offsets,
    create_intel_offsets_table = _create_intel_offsets_table,
    create_intel_power_chain = _create_intel_power_chain,
    create_intel_sar_table = _create_intel_sar_table,
    create_intel_sar_avg_table = _create_intel_sar_avg_table,
    create_intel_wifi = _create_intel_wifi,
    create_legacy_intel_wifi = _create_legacy_intel_wifi,
    create_mtcl_table = _create_mtcl_table,
    create_mtk_geo_power_chain = _create_mtk_geo_power_chain,
    create_mtk_power_chain = _create_mtk_power_chain,
    create_mtk_wifi = _create_mtk_wifi,
    create_rtw88 = _create_rtw88,
    create_rtw88_geo_offsets = _create_rtw88_geo_offsets,
    create_rtw88_power_chain = _create_rtw88_power_chain,
    create_rtw89 = _create_rtw89,
    create_rtw89_geo_offsets = _create_rtw89_geo_offsets,
    create_rtw89_power_chain = _create_rtw89_power_chain,
    create_ui = _create_ui,
    create_usb = _create_usb,
    fw_type = _FW_TYPE,
    hash_algorithm = _HASH_ALGORITHM,
    support_band = _SUPPORT_BAND,
    ui_requisition = _UI_REQUISITION,
    make_resolution = _make_resolution,
)
