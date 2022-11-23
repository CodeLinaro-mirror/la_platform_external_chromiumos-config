"""Functions related to designs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/design.proto",
    design_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/design_id.proto",
    design_id_pb = "chromiumos.config.api",
)
load("//config/util/generate.star", "generate")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/public_replication.star", "public_replication")
load(
    "@proto//chromiumos/config/api/software/software_config.proto",
    sc_pb = "chromiumos.config.api.software",
)

# Config identifier used for an unprovisioned configuration.
_UNPROVISIONED_CONFIG_ID = 0x7FFFFFFF

# Special value indicating that the FRID should be generated.
_FRID_AUTO = "__auto__"

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
        bluetooth = None,
        power = None,
        resource = None,
        audio = None,
        wifi = None,
        camera = None,
        health = None,
        nnpalm = None,
        ui = None,
        usb = None,
        rma = None,
        device_tree_compatible_match = None,
        smbios_name_match_override = None,
        frid = None):
    """Creates and appends new SW and HW configs.

    Create new Software and Hardware Design Configuration with the
    specified properties and then append them to the sw_configs and hw_configs
    arrays respectively. This ensures that all IDs are consistent.

    Note:
        Only one of device_tree_compatible_match,
        smbios_name_match_override, or frid can be specified.

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
        bluetooth: A BluetoothConfig to be used in the SoftwareConfig.
        power: A PowerConfig to be used in the SoftwareConfig.
        resource: A ResourceConfig to be used in the SoftwareConfig.
        audio: An AudioConfig to be used in the SoftwareConfig. Can be either a
            single AudioConfig or a list of AudioConfigs.
        wifi: A WifiConfig to be used in the SoftwareConfig.
        camera: A CameraConfig to be used in the SoftwareConfig.
        health: A HealthConfig to be used in the SoftwareConfig.
        nnpalm: A NnpalmConfig to be used in the SoftwareConfig.
        ui: A UiConfig to be used in the SoftwareConfig.
        usb: UsbConfig to be used in the SoftwareConfig.
        rma: An RmaConfig to be used in the SoftwareConfig.
        device_tree_compatible_match: Deprecated and traslated to FRID.
            ("google,name" -> "Google_Name").
        smbios_name_match_override: Deprecated and translated to FRID.
            ("Name" -> "Google_Name").
        frid: String which must match the AP firmware FRID (first part before the
            period) in order for the config to match.  Leaving this value unset
            will cause the config to match any FRID.
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
    hw_config.public_replication = public_replication.create(
        public_fields = _DEFAULT_PUBLIC_HW_CONFIG_FIELDS + extra_hw_config_public_fields,
    )
    hw_configs.append(hw_config)

    sw_config = sc_pb.SoftwareConfig()
    sw_config.design_config_id = hw_config.id

    # Verify that only one of the three match parameters are set
    match_list = [device_tree_compatible_match, smbios_name_match_override, frid]
    match_count = 0
    for match_var in match_list:
        if match_var:
            match_count += 1

    if match_count > 1:
        fail("Only one of device_tree_compatible_match, smbios_name_match_override, and frid can be specified")
    elif frid:
        if frid == _FRID_AUTO:
            frid_candidate = firmware_build_config.build_targets.coreboot
            if not frid_candidate:
                frid_candidate = design_id.value
            frid = "Google_%s" % frid_candidate.title()
    elif device_tree_compatible_match:
        _, _, firmware_name = device_tree_compatible_match.partition(",")
        frid = "Google_%s" % firmware_name.title()
        print("WARNING: device_tree_compatible_match is no longer supported.  " +
              "Changing %r to a FRID match of %r" % (device_tree_compatible_match, frid))
    else:
        smbios_name_match = smbios_name_match_override or design_id.value
        frid = "Google_%s" % smbios_name_match
        print("WARNING: smbios_name_match is no longer supported.  " +
              "Changing %r to a FRID match of %r" % (smbios_name_match, frid))

    sw_config.id_scan_config.frid = frid

    sw_config.id_scan_config.firmware_sku = config_id
    sw_config.firmware = firmware
    sw_config.firmware_build_config = firmware_build_config
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
    sw_config.health_config = health
    sw_config.nnpalm_config = nnpalm
    sw_config.ui_config = ui
    sw_config.usb_config = usb
    sw_config.rma_config = rma
    sw_config.public_replication = public_replication.create(
        public_fields = _DEFAULT_PUBLIC_SW_CONFIG_FIELDS + extra_sw_config_public_fields,
    )
    sw_configs.append(sw_config)

def _create_design_id(name, config_design_id_override = None):
    """Builds a DesignId proto."""
    return design_id_pb.DesignId(value = name, config_design_id_override = config_design_id_override)

def _create_design(
        id,
        program_id,
        odm_id,
        public_fields = ["id", "name", "program_id"],
        configs = None,
        board_id_phases = None,
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
    FRID_AUTO = _FRID_AUTO,
)
