"""Functions related to program configs.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/config/api/design_id.proto",
    design_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/device_brand_id.proto",
    db_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/program.proto",
    program_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/program_id.proto",
    program_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/schedqos_config.proto",
    schedqos_pb = "chromiumos.config.api",
)

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/generate.star", "generate")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/public_replication.star", "public_replication")

_DEFAULT_PUBLIC_FIELDS = ["name", "id", "base_program"]

_LAUNCHED_PUBLIC_FIELDS = [
    "audio_config",
    "platform.arc_settings",
    "platform.capabilities",
    "platform.hevc_support",
    "platform.resource_config",
    "platform.scheduler_tune",
    "platform.schedqos_config",
    "platform.swap_config",
    "mosys_platform_name",
    "generate_camera_media_profiles",
]

def _create_schedqos(default = None):
    """Builds a SchedqosConfig proto"""
    return schedqos_pb.SchedqosConfig(
        default = default,
    )

def _create_schedqos_config_set(
        normal_cpu_share = None,
        background_cpu_share = None,
        thread_urgent_bursty = None,
        thread_urgent = None,
        thread_balanced = None,
        thread_eco = None,
        thread_utility = None,
        thread_background = None,
        thread_urgent_bursty_server = None,
        thread_urgent_bursty_client = None):
    """Builds a ConfigSet proto for schedqos"""
    return schedqos_pb.SchedqosConfig.ConfigSet(
        normal_cpu_share = normal_cpu_share,
        background_cpu_share = background_cpu_share,
        thread_urgent_bursty = thread_urgent_bursty,
        thread_urgent = thread_urgent,
        thread_balanced = thread_balanced,
        thread_eco = thread_eco,
        thread_utility = thread_utility,
        thread_background = thread_background,
        thread_urgent_bursty_server = thread_urgent_bursty_server,
        thread_urgent_bursty_client = thread_urgent_bursty_client,
    )

def _create_schedqos_thread_config(
        rt_priority = None,
        nice = None,
        uclamp_min = None,
        cpuset_cgroup = None,
        latency_sensitive = None):
    """Builds a ThreadConfig proto for schedqos"""
    thread_config = schedqos_pb.SchedqosConfig.ThreadConfig(
        cpuset_cgroup = cpuset_cgroup,
    )
    if rt_priority != None:
        thread_config.rt_priority.value = rt_priority
    if nice != None:
        thread_config.nice.value = nice
    if uclamp_min != None:
        thread_config.uclamp_min.value = uclamp_min
    if latency_sensitive != None:
        thread_config.latency_sensitive.value = latency_sensitive
    return thread_config

_SCHEDQOS_CPUSET_CGROUP = struct(
    ALL = schedqos_pb.SchedqosConfig.CPUSET_CGROUP_ALL,
    EFFICIENT = schedqos_pb.SchedqosConfig.CPUSET_CGROUP_EFFICIENT,
)

def _create_firmware_configuration_segment(name, mask):
    """Builds a FirmwareConfigurationSegment proto."""
    return program_pb.FirmwareConfigurationSegment(
        name = name,
        mask = mask,
    )

def _create_design_config_id_segment(design_id, min_id, max_id):
    """Builds a DesignConfigIdSegment proto."""
    return program_pb.DesignConfigIdSegment(
        design_id = design_id,
        min_id = min_id,
        max_id = max_id,
    )

# TODO(shapiroc): Migrate clients, make this private, and fix param order
def _create_signer_config(device_brand_id, key_id, design_id = None):
    """Builds a DeviceSignerConfig proto."""
    if design_id:
        return program_pb.DeviceSignerConfig(
            design_id = design_id_pb.DesignId(value = design_id),
            key_id = key_id,
        )
    else:
        return program_pb.DeviceSignerConfig(
            brand_id = db_id_pb.DeviceBrandId(value = device_brand_id),
            key_id = key_id,
        )

def _create_signer_config_by_brand(device_brand_id, key_id):
    return _create_signer_config(device_brand_id = device_brand_id, key_id = key_id)

def _create_signer_configs_by_brand(configs):
    return [_create_signer_config_by_brand(id, key) for id, key in configs.items()]

def _create_signer_config_by_design(design_id, key_id):
    return _create_signer_config(design_id = design_id, key_id = key_id, device_brand_id = None)

def _create_signer_configs_by_design(configs):
    return [_create_signer_config_by_design(id, key) for id, key in configs.items()]

def _create_swap_config(
        size_multiplier = None):
    swap_config = None
    if any([
        size_multiplier != None,
    ]):
        swap_config = program_pb.Program.Platform.SwapConfig(
            size_multiplier = size_multiplier,
        )
    return swap_config

def _create_platform(
        soc_family,
        soc_arch,
        gpu_family = None,
        graphics_apis = [],
        video_codecs = [],
        suspend_to_idle = None,
        dark_resume = None,
        wake_on_dp = None,
        boost_urgent = None,
        cpuset_nonurgent = None,
        input_boost = None,
        boost_top_app = None,
        boost_arcvm = None,
        hevc_support = None,
        arc_media_codecs_suffix = None,
        resource = None,
        schedqos = None,
        swap_config = None):
    capabilities = None
    if any([
        suspend_to_idle != None,
        dark_resume != None,
        wake_on_dp != None,
    ]):
        capabilities = program_pb.Program.Platform.Capabilities(
            suspend_to_idle = suspend_to_idle,
            dark_resume = dark_resume,
            wake_on_dp = wake_on_dp,
        )

    scheduler_tune = None
    if any([
        boost_urgent != None,
        cpuset_nonurgent != None,
        input_boost != None,
        boost_top_app != None,
        boost_arcvm != None,
    ]):
        scheduler_tune = program_pb.Program.Platform.SchedulerTune(
            boost_urgent = boost_urgent,
            cpuset_nonurgent = cpuset_nonurgent,
            input_boost = input_boost,
            boost_top_app = boost_top_app,
            boost_arcvm = boost_arcvm,
        )

    arc_settings = None
    if any([
        arc_media_codecs_suffix != None,
    ]):
        arc_settings = program_pb.Program.Platform.ArcSettings(
            media_codecs_suffix = arc_media_codecs_suffix,
        )

    return program_pb.Program.Platform(
        soc_family = soc_family,
        soc_arch = soc_arch,
        gpu_family = gpu_family,
        graphics_apis = graphics_apis,
        video_codecs = video_codecs,
        capabilities = capabilities,
        scheduler_tune = scheduler_tune,
        arc_settings = arc_settings,
        hevc_support = hw_topo.bool_to_present(hevc_support),
        resource_config = resource,
        schedqos_config = schedqos,
        swap_config = swap_config,
    )

def _create_audio_config(
        card_configs = [],
        has_module_file = False,
        default_ucm_suffix = "{model}",
        default_cras_suffix = ""):
    """Builds an AudioConfig proto.

    Args:
        card_configs: A list of CardConfig protos specifying card configs to be
            installed and used for all designs within this program. Individual
            projects will not be able to modify card configs set here, so this
            should only be used for configs needing to be present on all
            designs such as HDMI/DP audio out consistently provided by the SoC
            platform.
        has_module_file: A boolean specifying whether an alsa module file
        should be installed.
        default_ucm_suffix: A default format string used to generate the
            parts of the UCM suffix not referring to audio components. This
            value is used for any card config not providing a value for
            ucm_config. The following placeholders may be used:
                {design}: The design name.
                {camera_count}: The number of cameras (usually 0, 1 or 2).
                {headset_codec}: The headset codec name (in lowercase)
                    specified in the topology containing the card config.
                {speaker_amp}: The speaker amp name (in lowercase) specified in
                    the topology containing the card config.
                {mic_description}: A description of the microphone topology, of
                    the form {user_facing_mic_count}uf{world_facing_mic_count}wf, with
                    components elided if their count is 0.
                {total_mic_count}: The total number of internal microphones.
                {user_facing_mic_count}: The number of internal user-facing microphones.
                {world_facing_mic_count}: The number of internal world-facing microphones.
        default_cras_suffix: Similar to default_ucm_suffix.
        launched: A bool indicating whether this program is launched, and as
            such whether additional preset fields should be made public.
    """
    return program_pb.Program.AudioConfig(
        card_configs = card_configs,
        has_module_file = has_module_file,
        default_ucm_suffix = default_ucm_suffix,
        default_cras_suffix = default_cras_suffix,
    )

def _create(
        name,
        base_program = None,
        public_fields = [],
        component_quals = None,
        constraints = None,
        firmware_configuration_segments = None,
        ssfc_segments = None,
        design_config_id_segments = None,
        device_signer_configs = None,
        mosys_platform_name = None,
        platform = None,
        audio_config = None,
        generate_camera_media_profiles = None,
        launched = False):
    """Builds a Program proto."""
    program_id = program_id_pb.ProgramId(value = name)

    public_fields = list(public_fields)
    public_fields += _DEFAULT_PUBLIC_FIELDS
    if launched:
        public_fields += _LAUNCHED_PUBLIC_FIELDS

    return program_pb.Program(
        public_replication = public_replication.create(public_fields = public_fields),
        id = program_id,
        name = name,
        base_program = base_program,
        component_quals = component_quals,
        design_config_constraints = constraints,
        firmware_configuration_segments = firmware_configuration_segments,
        ssfc_segments = ssfc_segments,
        design_config_id_segments = design_config_id_segments,
        device_signer_configs = device_signer_configs,
        mosys_platform_name = mosys_platform_name,
        platform = platform,
        audio_config = audio_config,
        generate_camera_media_profiles = generate_camera_media_profiles,
    )

program = struct(
    create = _create,
    create_audio_config = _create_audio_config,
    create_platform = _create_platform,
    create_firmware_configuration_segment = _create_firmware_configuration_segment,
    create_design_config_id_segment = _create_design_config_id_segment,
    create_signer_config = _create_signer_config,
    create_signer_config_by_brand = _create_signer_config_by_brand,
    create_signer_configs_by_brand = _create_signer_configs_by_brand,
    create_signer_config_by_design = _create_signer_config_by_design,
    create_signer_configs_by_design = _create_signer_configs_by_design,
    create_schedqos = _create_schedqos,
    create_schedqos_config_set = _create_schedqos_config_set,
    create_schedqos_thread_config = _create_schedqos_thread_config,
    create_swap_config = _create_swap_config,
    generate = generate.generate,
    platform = program_pb.Program.Platform,
    schedqos_cpuset_cgroup = _SCHEDQOS_CPUSET_CGROUP,
)
