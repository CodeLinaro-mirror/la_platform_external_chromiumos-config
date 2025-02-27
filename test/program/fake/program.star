# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/component.star", "comp")
load("//config/util/design.star", "design")
load("//config/util/hw_features.star", "hw_feat")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/program.star", program_util = "program")
load("//config/util/sw_config.star", sc = "sw_config")

_FAKE_SOC = comp.create_soc_model(
    family = comp.create_soc_family(name = "FAKE_FAMILY"),
    model = "FAKE_MODEL",
    cores = 2,
    id = "FAKE_MODEL_2",
)

_SOC_MODELS = [_FAKE_SOC]

_FAKE_BT_COMP = comp.create_bt("0001", "0002", "0003")

_BT_COMPS = [_FAKE_BT_COMP]

_QUALIFIED_COMPS = _SOC_MODELS + _BT_COMPS

_QUAL_CONSTRAINTS = comp.create_quals(
    [comp.id for comp in _QUALIFIED_COMPS],
    comp.qual_status.QUALIFIED,
)

_FW_MASKS = struct(
    DB = 0x0000000F,
    CAMERA = 0x000000F0,
    SENSOR = 0x00000F00,
    WIFI_SAR_ID = 0x0000F000,
    TOUCH = 0x00010000,
    DETACHABLE_BASE = 0x00F00000,
)

_FIRMWARE_CONFIGURATION_SEGMENTS = [
    program_util.create_firmware_configuration_segment("Daughter board", _FW_MASKS.DB),
    program_util.create_firmware_configuration_segment("Camera", _FW_MASKS.CAMERA),
    program_util.create_firmware_configuration_segment("Sensor", _FW_MASKS.SENSOR),
    program_util.create_firmware_configuration_segment("Intel wifi sar id", _FW_MASKS.WIFI_SAR_ID),
    program_util.create_firmware_configuration_segment("Touch controller", _FW_MASKS.TOUCH),
    program_util.create_firmware_configuration_segment("Detachable Base", _FW_MASKS.DETACHABLE_BASE),
]

_FEATURE_CONSTRAINTS = design.create_constraints([
    hw_feat.create_features(
        bluetooth = hw_feat.create_bluetooth(present = True),
        camera = hw_feat.create_cameras(
            hw_feat.create_camera(),
        ),
        display = hw_feat.create_display(internal = True, external = False),
        fingerprint = hw_feat.create_fingerprint(
            location = hw_feat.location.SIDE_LEFT,
            board = "test_board",
            ro_version = "ro-test",
            present = True,
        ),
        form_factor = hw_feat.create_form_factor(hw_feat.form_factor.CLAMSHELL),
        keyboard = hw_feat.create_keyboard(hw_feat.keyboard_type.INTERNAL),
        screen = hw_feat.create_screen(touch = True),
        storage = hw_feat.create_storage(hw_feat.storage.EMMC),
        stylus = hw_feat.create_stylus(hw_feat.stylus_type.INTERNAL),
        touchpad = hw_feat.create_touchpad(present = True),
    ),
    hw_feat.create_form_factor(hw_feat.form_factor.CLAMSHELL),
    hw_feat.create_form_factor(hw_feat.form_factor.CONVERTIBLE),
])

# Signer config for program FAKE

_SIGNER_BRAND_CONFIGS = program_util.create_signer_configs_by_brand(
    {
        "WLAA": "KEYD",  # White label A
        "WLBB": "KEYE",  # White label B
        "WLCC": "KEYF",  # White label C
        "WLZZ": "DEFAULT",  # White label default
    },
)

_SIGNER_DESIGN_CONFIGS = program_util.create_signer_configs_by_design(
    {
        "FAKE_REF_DESIGN": "DEFAULT",
        "PROJECT_A": "KEYA",  # Follow up design A
        "PROJECT_B": "KEYB",  # Follow up design B
        "PROJECT_BOX": "KEYBX",  # Follow up design BOX
        "PROJECT_C": "KEYC",  # Follow up design C
        "PROJECT_D": "KEYD",  # Follow up design D
        "PROJECT_E": "KEYE",  # Follow up design E
        "PROJECT_REBRAND": "KEYRB",  # Follow up design REBRAND
    },
)

_SIGNER_CONFIG = _SIGNER_BRAND_CONFIGS + _SIGNER_DESIGN_CONFIGS

# signer config for program FAKE_A

_SIGNER_DESIGN_CONFIGS_FAKE_A = program_util.create_signer_configs_by_design(
    {
        "FAKE_A_REF_DESIGN": "DEFAULT",
    },
)

_SIGNER_CONFIG_FAKE_A = _SIGNER_DESIGN_CONFIGS_FAKE_A

platform = program_util.platform
_PLATFORM = program_util.create_platform(
    soc_family = "FAKE_INTEL_PLATFORM",
    soc_arch = platform.X86_64,
    gpu_family = "FAKE_INTEL_GPU",
    graphics_apis = [platform.GRAPHICS_API_OPENGL],
    video_codecs = [
        platform.H264_DECODE,
        platform.H264_DECODE,
        platform.H265_DECODE,
    ],
    suspend_to_idle = True,
    dark_resume = True,
    wake_on_dp = True,
    boost_arcvm = 0.5,
    boost_urgent = 20,
    cpuset_nonurgent = "0-5",
    input_boost = 15,
    boost_top_app = 60,
    arc_media_codecs_suffix = "",
    hevc_support = True,
    resource = sc.create_resource(
        ac = sc.create_power_source_preference(
            default = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            arcvm_gaming = sc.create_power_preference(
                governor = sc.create_performance_governor(),
                epp = sc.create_performance_epp(),
                cpu_offline = sc.create_cpu_offline_smt(),
            ),
            battery_saver = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_power_epp(),
                cpu_offline = sc.create_cpu_offline_small_core(
                    min_active_threads = 4,
                ),
                cpufreq_disable_boost = True,
            ),
        ),
        dc = sc.create_power_source_preference(
            default = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_balance_performance_epp(),
            ),
            web_rtc = sc.create_power_preference(
                governor = sc.create_ondemand_governor(1),
                epp = sc.create_default_epp(),
                cpu_offline = sc.create_cpu_offline_half(),
            ),
            battery_saver = sc.create_power_preference(
                governor = sc.create_powersave_governor(),
                epp = sc.create_power_epp(),
                cpu_offline = sc.create_cpu_offline_small_core(
                    min_active_threads = 4,
                ),
                cpufreq_disable_boost = True,
            ),
        ),
    ),
    schedqos = program_util.create_schedqos(
        default = program_util.create_schedqos_config_set(
            normal_cpu_share = 1024,
            background_cpu_share = 10,
            thread_urgent_bursty = program_util.create_schedqos_thread_config(
                rt_priority = 8,
                nice = -8,
                uclamp_min = 0,
                cpuset_cgroup = program_util.schedqos_cpuset_cgroup.ALL,
                latency_sensitive = True,
            ),
            thread_urgent = program_util.create_schedqos_thread_config(
                rt_priority = -1,
                nice = 0,
                uclamp_min = 1,
                cpuset_cgroup = program_util.schedqos_cpuset_cgroup.EFFICIENT,
                latency_sensitive = False,
            ),
            thread_balanced = program_util.create_schedqos_thread_config(
                rt_priority = 0,
                nice = 8,
                uclamp_min = 2,
            ),
            thread_eco = None,
            thread_utility = program_util.create_schedqos_thread_config(),
            thread_background = program_util.create_schedqos_thread_config(),
            thread_urgent_bursty_server = program_util.create_schedqos_thread_config(),
            thread_urgent_bursty_client = program_util.create_schedqos_thread_config(),
        ),
    ),
    swap_config = program_util.create_swap_config(
        size_multiplier = 1.5,
    ),
)

_PLATFORM_A = program_util.create_platform(
    soc_family = "FAKE_INTEL_PLATFORM_A",
    soc_arch = platform.X86_64,
    gpu_family = "FAKE_INTEL_GPU_A",
    suspend_to_idle = True,
    dark_resume = True,
)

_HDMI_AUDIO_CARD = hw_topo.create_audio_card_config(
    card_name = "HDA ATI HDMI",
    ucm_config = hw_topo.audio_config_structure.COMMON,
    cras_config = hw_topo.audio_config_structure.NONE,
    ucm_suffix = "",
)

_FAKE = program_util.create(
    name = "FAKE_PROGRAM",
    component_quals = _QUAL_CONSTRAINTS,
    constraints = _FEATURE_CONSTRAINTS,
    firmware_configuration_segments = _FIRMWARE_CONFIGURATION_SEGMENTS,
    device_signer_configs = _SIGNER_CONFIG,
    mosys_platform_name = "fake",
    platform = _PLATFORM,
    audio_config = program_util.create_audio_config(
        has_module_file = True,
        default_ucm_suffix = "{speaker_amp}.{headset_codec}.{mic_description}.{design}",
        card_configs = [_HDMI_AUDIO_CARD],
    ),
    generate_camera_media_profiles = True,
    launched = True,
)

# Define Program _FAKE_A, mapped to same overlay as Program _FAKE.
_FAKE_A = program_util.create(
    name = "FAKE_A_PROGRAM",
    base_program = "FAKE_PROGRAM",
    component_quals = _QUAL_CONSTRAINTS,
    constraints = _FEATURE_CONSTRAINTS,
    firmware_configuration_segments = _FIRMWARE_CONFIGURATION_SEGMENTS,
    device_signer_configs = _SIGNER_CONFIG_FAKE_A,
    mosys_platform_name = "fake_a",
    platform = _PLATFORM_A,
    audio_config = program_util.create_audio_config(
        has_module_file = True,
        default_ucm_suffix = "{speaker_amp}.{headset_codec}.{mic_description}.{design}",
        card_configs = [_HDMI_AUDIO_CARD],
    ),
    generate_camera_media_profiles = True,
    launched = True,
)

program = struct(
    fake = _FAKE,
    fake_a = _FAKE_A,
    fw_masks = _FW_MASKS,
    components = _QUALIFIED_COMPS,
    bluetooth_component = _FAKE_BT_COMP,
)
