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
load(
    "@proto//chromiumos/config/api/software/software_config.proto",
    sc_pb = "chromiumos.config.api.software",
)

# Config identifier used for an unprovisioned configuration.
_UNPROVISIONED_CONFIG_ID = 0x7FFFFFFF

_CONSTRAINT = struct(
    REQUIRED = design_pb.Design.Config.Constraint.REQUIRED,
    PREFERRED = design_pb.Design.Config.Constraint.PREFERRED,
    OPTIONAL = design_pb.Design.Config.Constraint.OPTIONAL,
)

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
        base_hw_features = None,
        hardware_topology = None,
        firmware = None,
        firmware_build_config = None,
        bluetooth = None,
        power = None,
        audio = None,
        smbios_name_match_override = None):
    """Creates and appends new SW and HW configs.

    Create new Software and Hardware Design Configuration with the
    specified properties and then append them to the sw_configs and hw_configs
    arrays respectively. This ensures that all IDs are consistent.
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
        base_hw_features,
        hardware_topology,
    )
    hw_configs.append(hw_config)

    sw_config = sc_pb.SoftwareConfig()
    sw_config.design_config_id = hw_config.id
    sw_config.id_scan_config.smbios_name_match = smbios_name_match_override or design_id.value
    sw_config.id_scan_config.firmware_sku = config_id
    sw_config.firmware = firmware
    sw_config.firmware_build_config = firmware_build_config
    sw_config.bluetooth_config = bluetooth
    sw_config.power_config = power
    if audio:
        if type(audio) == "list":
            sw_config.audio_configs.extend(audio)
        else:
            sw_config.audio_configs.append(audio)
    sw_configs.append(sw_config)

def _create_design_id(name):
    """Builds a DesignId proto."""
    return design_id_pb.DesignId(value = name)

def _create_design(id, program_id, odm_id, configs = None):
    """Builds a Design proto."""
    return design_pb.Design(
        id = id,
        program_id = program_id,
        odm_id = odm_id,
        name = id.value,
        configs = configs,
    )

design = struct(
    append_configs = _append_configs,
    create_constraint = _create_constraint,
    create_constraints = _create_constraints,
    create_design_id = _create_design_id,
    create_design = _create_design,
    constraint = _CONSTRAINT,
    generate = generate.generate,
    UNPROVISIONED_CONFIG_ID = _UNPROVISIONED_CONFIG_ID,
)
