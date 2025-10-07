"""Functions related to designs.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/config/api/design.proto",
    design_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/design_id.proto",
    design_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/software/software_config.proto",
    sc_pb = "chromiumos.config.api.software",
)

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/generate.star", "generate")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/public_replication.star", "public_replication")

# Config identifier used for an unprovisioned configuration.
_UNPROVISIONED_CONFIG_ID = 0x7FFFFFFF

_CONSTRAINT = struct(
    REQUIRED = design_pb.Design.Config.Constraint.REQUIRED,
    PREFERRED = design_pb.Design.Config.Constraint.PREFERRED,
    OPTIONAL = design_pb.Design.Config.Constraint.OPTIONAL,
)

_CUSTOMTYPE = struct(
    NO_CUSTOM = design_pb.Design.NO_CUSTOM,
    WHITELABEL = design_pb.Design.WHITELABEL,
    REBRAND = design_pb.Design.REBRAND,
)

# Default hw_config_fields to be exposed
_DEFAULT_PUBLIC_HW_CONFIG_FIELDS = [
    "id",
]

# Default sw_config_fields to be exposed
_DEFAULT_PUBLIC_SW_CONFIG_FIELDS = [
    "design_config_id",
    "id_scan_config",
]

_LAUNCHED_HW_PUBLIC_FIELDS = [
    "hardware_features",
    "hardware_topology.wifi.hardware_feature.fw_config",
]

_LAUNCHED_SW_PUBLIC_FIELDS = [
    "bluetooth_config",
    "camera_config",
    "firmware_build_config",
    "health_config",
    "nnpalm_config",
    "ui_config",
]

def _create_constraint(hw_features, level = _CONSTRAINT.REQUIRED):
    """Builds a Design.Config.Constraint proto."""
    return design_pb.Design.Config.Constraint(level = level, features = hw_features)

def _create_constraints(hw_features, level = _CONSTRAINT.REQUIRED):
    """Builds a Design.Config.Constrain proto for each of hw_features."""
    return [design_pb.Design.Config.Constraint(
        level = level,
        features = hw_feature,
    ) for hw_feature in hw_features]

def _append_configs(
        sw_configs,
        hw_configs,
        design_id,
        config_id,
        extra_hw_config_public_fields = [],
        extra_sw_config_public_fields = [],
        hardware_topology = None,
        firmware = None,
        firmware_build_config = None,
        firmware_info = None,
        bluetooth = None,
        power = None,
        resource = None,
        audio = None,
        wifi = None,
        camera = None,
        disk_layout = None,
        health = None,
        nnpalm = None,
        ui = None,
        usb = None,
        rma = None,
        device_tree_compatible_match = None,
        smbios_name_match_override = None,
        unified_fw_config_val = None,
        frid = None,
        launched = False):
    """Creates and appends new SW and HW configs.

    Create new Software and Hardware Design Configuration with the
    specified properties and then append them to the sw_configs and hw_configs
    arrays respectively. This ensures that all IDs are consistent.

    Args:
        sw_configs: An array to append the new SoftwareConfig to. Required.
        hw_configs: An array to append the new Design.Config to. Required.
        design_id: A DesignId to use for the Design.Config and SoftwareConfig.
            Required.
        config_id: A str or int used to construct the DesignConfigId for the
            Design.Config and SoftwareConfig. Required.
        extra_hw_config_public_fields: A list of str specifying fields on
            Design.Config that will be made public in addition to the default
            _DEFAULT_PUBLIC_HW_CONFIG_FIELDS. See PublicReplication proto
            for details.
        extra_sw_config_public_fields: A list of str specifying fields on
            SoftwareConfig that will be made public in addition to the default
            _DEFAULT_PUBLIC_SW_CONFIG_FIELDS. See PublicReplication proto for
            details.
        hardware_topology: A HardwareTopology to be used in the Design.Config.
        firmware: A FirmwareConfig to be used in the SoftwareConfig.
        firmware_build_config: A FirmwareBuildConfig to be used in the
            SoftwareConfig.
        firmware_info: Information related to runtime firmware,
        bluetooth: A BluetoothConfig to be used in the SoftwareConfig.
        power: A PowerConfig to be used in the SoftwareConfig.
        resource: A ResourceConfig to be used in the SoftwareConfig.
        audio: An AudioConfig to be used in the SoftwareConfig. Can be either a
            single AudioConfig or a list of AudioConfigs.
        wifi: A WifiConfig to be used in the SoftwareConfig.
        camera: A CameraConfig to be used in the SoftwareConfig.
        disk_layout: Define disk layout override, to be used in the SoftwareConfig.
        health: A HealthConfig to be used in the SoftwareConfig.
        nnpalm: A NnpalmConfig to be used in the SoftwareConfig.
        ui: A UiConfig to be used in the SoftwareConfig.
        usb: UsbConfig to be used in the SoftwareConfig.
        rma: An RmaConfig to be used in the SoftwareConfig.
        device_tree_compatible_match: Deprecated, use FRID instead.
        smbios_name_match_override: Deprecated, use FRID instead.
        frid: String which must match the AP firmware FRID (first part before the
            period) in order for the config to match.  Leaving this value unset
            will result in FRID being generated from coreboot target name or design ID.
        launched: A bool indicating whether this config is launched, and as
            such whether additional preset fields should be made public.
    """

    # Ensure that config_id is convertable to int and is serialized as a
    # decimal instead of a string. This makes it easier for a consumer
    # to construct the DesignConfigId.value string correctly.
    #
    # This means that specifying
    #   config_id = "0x7fffffff"
    #   config_id = "0x7FFFFFFF"
    #   config_id = 0x7fffffff
    #
    # will all get serialized the same way, i.e. 2147483647.
    config_id = int(config_id)

    hw_config = design_pb.Design.Config()
    hw_config.id.value = "%s:%s" % (design_id.value, config_id)
    hw_config.hardware_topology = hardware_topology
    hw_config.hardware_features = hw_topo.convert_to_hw_features(
        hardware_topology,
    )
    hw_config_public_fields = list(_DEFAULT_PUBLIC_HW_CONFIG_FIELDS)
    sw_config_public_fields = list(_DEFAULT_PUBLIC_SW_CONFIG_FIELDS)
    if launched:
        hw_config_public_fields += _LAUNCHED_HW_PUBLIC_FIELDS
        sw_config_public_fields += _LAUNCHED_SW_PUBLIC_FIELDS
    hw_config.public_replication = public_replication.create(
        public_fields = hw_config_public_fields + extra_hw_config_public_fields,
    )
    hw_configs.append(hw_config)

    sw_config = sc_pb.SoftwareConfig()
    sw_config.design_config_id = hw_config.id

    # Generate a default FRID from coreboot target name or design ID.
    if not frid:
        if firmware_build_config:
            candidate_name = firmware_build_config.build_targets.coreboot
        else:
            candidate_name = design_id.value
        frid = "Google_%s" % candidate_name.title()

    sw_config.id_scan_config.frid = frid

    # Ignoring all other options to generate FRID.
    if device_tree_compatible_match:
        print("WARNING: device_tree_compatible_match is deprecated. FRID `%s` is used for this config." % frid)

    if smbios_name_match_override:
        print("WARNING: smbios_name_match is deprecated. FRID `%s` is used for this config." % frid)

    sw_config.id_scan_config.firmware_sku = config_id
    sw_config.firmware = firmware
    sw_config.firmware_build_config = firmware_build_config
    sw_config.firmware_info = firmware_info
    sw_config.bluetooth_config = bluetooth
    sw_config.power_config = power
    sw_config.resource_config = resource
    if audio:
        if type(audio) == "list":
            sw_config.audio_configs.extend(audio)
        else:
            sw_config.audio_configs.append(audio)
    sw_config.wifi_config = wifi
    sw_config.camera_config = camera
    sw_config.disk_layout = disk_layout
    sw_config.health_config = health
    sw_config.nnpalm_config = nnpalm
    sw_config.ui_config = ui
    sw_config.usb_config = usb
    sw_config.rma_config = rma
    sw_config.public_replication = public_replication.create(
        public_fields = sw_config_public_fields + extra_sw_config_public_fields,
    )
    sw_config.unified_fw_config.value = unified_fw_config_val
    sw_configs.append(sw_config)

def _create_design_id(name, config_design_id_override = None, model_name_design_id_override = None):
    """Builds a DesignId proto."""
    return design_id_pb.DesignId(
        value = name,
        config_design_id_override = config_design_id_override,
        model_name_design_id_override = model_name_design_id_override,
    )

def _create_design(
        id,
        program_id,
        odm_id,
        public_fields = ["id", "name", "program_id"],
        configs = None,
        board_id_phases = None,
        spi_flash_transform = None,
        custom_type = _CUSTOMTYPE.NO_CUSTOM):
    """Builds a Design proto."""
    return design_pb.Design(
        id = id,
        program_id = program_id,
        odm_id = odm_id,
        public_replication = public_replication.create(public_fields = public_fields),
        name = id.value,
        configs = configs,
        board_id_phase = board_id_phases,
        custom_type = custom_type,
        spi_flash_transform = spi_flash_transform,
    )

def _hoist_version(versioned_topologies, names):
    return struct(
        topology = dict(zip(names, [t.topology for t in versioned_topologies])),
        version = max([t.version for t in versioned_topologies] + [0]),
    )

def _cartesian_product(hardware_topology_bundle):
    result = [[]]
    for values in hardware_topology_bundle:
        intermediate_result = []
        for previous_value in result:
            intermediate_result.extend([previous_value + [next_value] for next_value in values.topologies])
        result = intermediate_result

    names = [field.name for field in hardware_topology_bundle]
    return [_hoist_version(value, names) for value in result]

def _find_unprovisioned_config(configs, unprovisioned_topologies):
    for config in configs:
        matches = True
        for topology_type, topology in unprovisioned_topologies.items():
            if config[topology_type] != topology:
                matches = False
                break
        if matches:
            return config

    fail("Failed to find config matching unprovisioned_topologies: ", unprovisioned_topologies)

def _foreach_topology(
        initial_config_id,
        hardware_topology_bundle,
        config_factory,
        unprovisioned_topologies):
    configs = [config.topology for config in sorted(
        _cartesian_product(hardware_topology_bundle),
        key = lambda config: config.version,
    )]

    unprovisioned_config = _find_unprovisioned_config(configs, unprovisioned_topologies)
    config_factory(_UNPROVISIONED_CONFIG_ID, unprovisioned_config)

    config_id = initial_config_id
    for config in configs:
        if config_factory(config_id, config):
            config_id += 1

def _topology_name(topo):
    if topo:
        return topo.id
    return "None"

def _create_design_with_configs(
        design_id,
        program_id,
        odm_id,
        sw_configs,
        hardware_topology_bundle,
        initial_config_id,
        include_unprovisioned = False,
        unprovisioned_topologies = {},
        extra_hw_configs = None,
        public_fields = ["id", "name", "program_id"],
        board_id_phases = None,
        custom_type = _CUSTOMTYPE.NO_CUSTOM,
        extra_hw_config_public_fields = [],
        extra_sw_config_public_fields = [],
        firmware = None,
        firmware_build_config = None,
        firmware_info = None,
        bluetooth = None,
        power = None,
        camera = None,
        disk_layout = None,
        health = None,
        ui = None,
        frid = None,
        rma = None,
        hardware_topology_filter = None,
        active_configs = None,
        spi_flash_transform = None,
        config_notes = {},
        launched = False):
    """Create a design with configs for each topology combination in the bundle.

    Parameters mirror those of design.append_configs() and design.create_design
    (with id renamed to design_id, matching design.append_configs()). A config
    is generated for each combination of topologies in
    hardware_topology_bundle.

    Args:
        design_id: A DesignId to use for the Design.Config and SoftwareConfig.
        program_id: ID that uniquely identifies the program.
        odm_id: ODM for the given hardware design.
        sw_configs: An array to append the new SoftwareConfig to.
        hardware_topology_bundle: A bundle of hardware topology values created
            by create_hardware_topology_bundle().
        initial_config_id: The first design config ID to use. Consecutive IDs
            will be used for the remaining configs, except those skipped due to
            a hardware_topology_filter.
        include_unprovisioned: Whether to generated a config for the
            unprovisioned ID in addition to other configs. The same
            configuration as used for initial_config_id will be used for the
            unprovisioned config, unless unprovisioned_topologies is specified.
        unprovisioned_topologies: A set of hardware topologies which the
            unprovisioned config should incude. The unprovisioned config will be
            set to the first generated config containing all of these topologies.
            Implies include_unprovisioned.
        extra_hw_configs: An array to append the extra Design.Config to.
        public_fields:  A list of strings specifying fields that should be made
            public. See comment on the PublicReplication proto for semantics
            and example of how the proto works.
        board_id_phases: Board version assignment for each build phase.
        custom_type: Define custom type as custom label or rebrand.
        extra_hw_config_public_fields: A list of str specifying fields on
            Design.Config that will be made public in addition to the default
            _DEFAULT_PUBLIC_HW_CONFIG_FIELDS. See PublicReplication proto
            for details.
        extra_sw_config_public_fields: A list of str specifying fields on
            SoftwareConfig that will be made public in addition to the default
            _DEFAULT_PUBLIC_SW_CONFIG_FIELDS. See PublicReplication proto for
            details.
        firmware: A FirmwareConfig to be used in the SoftwareConfig.
        firmware_build_config: A FirmwareBuildConfig to be used in the
            SoftwareConfig.
        firmware_info: Information related to runtime firmware,
        bluetooth: A BluetoothConfig to be used in the SoftwareConfig.
        power: A PowerConfig to be used in the SoftwareConfig.
        disk_layout: Define disk layout override, to be used in the SoftwareConfig.
        camera: A CameraConfig to be used in the SoftwareConfig.
        health: A HealthConfig to be used in the SoftwareConfig.
        ui: A UiConfig to be used in the SoftwareConfig.
        frid: String which must match the AP firmware FRID (first part before the
            period) in order for the config to match.  Leaving this value unset
            will result in FRID being generated from coreboot target name or design ID.
        rma: An RmaConfig to be used in the SoftwareConfig.
        hardware_topology_filter: An optional function filtering out the config ID and
            the topologies to be used for that config. Return True to skip generating
            this config.
        active_configs: An array that contains the config IDs we need.
        spi_flash_transform: An optional mapping of AP SPI flash chip names that
            that provide a transform for the output of futility flash --get-info
            to the input required by ap_wpsr tool. This supports the AP RO
            verification features.
        config_notes: Notes to document any particular DesignConfigId in the
            generated markdown table.
        launched: A bool indicating whether this design is launched, and as
            such whether additional preset fields should be made public.
    """
    hw_configs = []

    if unprovisioned_topologies:
        include_unprovisioned = True

    if not active_configs:
        active_configs = []
    active_configs = list(active_configs)
    active_configs += config_notes.keys()
    if include_unprovisioned:
        active_configs = [_UNPROVISIONED_CONFIG_ID] + active_configs

    markdown = []
    varying_topology_names = set(
        [t.name for t in hardware_topology_bundle if len(t.topologies) > 1],
    )
    varying_topologies = []

    def _is_active_config(config_id):
        if config_id in active_configs:
            return "v"
        return ""

    def config_factory(config_id, topologies):
        if hardware_topology_filter:
            filter_result = hardware_topology_filter(config_id = config_id, **topologies)
            if filter_result:
                return False

        fw_config = 0
        for topology in topologies.values():
            if topology and proto.has(topology.hardware_feature, "fw_config"):
                fw_config |= topology.hardware_feature.fw_config.value

        varying_topologies.append([
            "0x%x" % config_id,
            "0x%x" % fw_config,
            _is_active_config(config_id),
            config_notes.get(config_id, ""),
        ] + [
            _topology_name(t)
            for name, t in sorted(topologies.items())
            if name in varying_topology_names
        ] + ["`cbi set 2 0x%x 4`" % config_id, "`cbi set 6 0x%x 4`" % fw_config])

        if config_id in active_configs:
            print(design_id.value, "configs added: 0x%x" % config_id)

            _append_configs(
                hw_configs = hw_configs,
                sw_configs = sw_configs,
                design_id = design_id,
                extra_hw_config_public_fields = extra_hw_config_public_fields,
                extra_sw_config_public_fields = extra_sw_config_public_fields,
                config_id = config_id,
                hardware_topology = hw_topo.create_hardware_topology(**topologies),
                firmware_build_config = firmware_build_config,
                firmware = firmware,
                firmware_info = firmware_info,
                bluetooth = bluetooth,
                power = power,
                camera = camera,
                disk_layout = disk_layout,
                health = health,
                ui = ui,
                frid = frid,
                rma = rma,
                launched = launched,
            )
        return True

    _foreach_topology(
        initial_config_id = initial_config_id,
        hardware_topology_bundle = hardware_topology_bundle,
        config_factory = config_factory,
        unprovisioned_topologies = unprovisioned_topologies,
    )
    markdown = [
        ["## Common topologies"],
        ["type", "name"],
        ["-"] * 2,
    ] + [
        [t.name, _topology_name(t.topologies[0].topology)]
        for t in hardware_topology_bundle
        if len(t.topologies) == 1
    ] + [
        [],
        ["## Varying topologies"],
        ["DesignConfigId", "fw_config", "active", "Notes"] + sorted(varying_topology_names) + ["CBI SKU_ID", "CBI FW_CONFIG"],
        ["-"] * (len(varying_topology_names) + 6),
    ] + varying_topologies + [[]]
    designconfigid_table = "\n".join(["|".join(line) for line in markdown])
    generate.gen_file(designconfigid_table, "_DesignConfigTable".join([design_id.value, ".md"]))
    return _create_design(
        id = design_id,
        program_id = program_id,
        odm_id = odm_id,
        configs = hw_configs + (extra_hw_configs or []),
        public_fields = public_fields,
        board_id_phases = board_id_phases,
        custom_type = custom_type,
        spi_flash_transform = spi_flash_transform,
    )

design = struct(
    append_configs = _append_configs,
    create_constraint = _create_constraint,
    create_constraints = _create_constraints,
    create_design_id = _create_design_id,
    create_design = _create_design,
    constraint = _CONSTRAINT,
    custom_type = _CUSTOMTYPE,
    generate = generate.generate,
    UNPROVISIONED_CONFIG_ID = _UNPROVISIONED_CONFIG_ID,
    create_design_with_configs = _create_design_with_configs,
)
