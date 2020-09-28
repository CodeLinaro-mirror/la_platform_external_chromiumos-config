"""Functions related to program configs.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/program.proto",
    program_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/program_id.proto",
    program_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/design_id.proto",
    design_id_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/device_brand_id.proto",
    db_id_pb = "chromiumos.config.api",
)
load("//config/util/generate.star", "generate")
load("//config/util/public_replication.star", "public_replication")

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

def _create(
        name,
        public_fields = ["name", "id"],
        component_quals = None,
        constraints = None,
        firmware_configuration_segments = None,
        design_config_id_segments = None,
        device_signer_configs = None):
    """Builds a Program proto."""
    program_id = program_id_pb.ProgramId(value = name)
    return program_pb.Program(
        public_replication = public_replication.create(public_fields = public_fields),
        id = program_id,
        name = name,
        component_quals = component_quals,
        design_config_constraints = constraints,
        firmware_configuration_segments = firmware_configuration_segments,
        design_config_id_segments = design_config_id_segments,
        device_signer_configs = device_signer_configs,
    )

program = struct(
    create = _create,
    create_firmware_configuration_segment = _create_firmware_configuration_segment,
    create_design_config_id_segment = _create_design_config_id_segment,
    create_signer_config = _create_signer_config,
    create_signer_config_by_brand = _create_signer_config_by_brand,
    create_signer_configs_by_brand = _create_signer_configs_by_brand,
    create_signer_config_by_design = _create_signer_config_by_design,
    create_signer_configs_by_design = _create_signer_configs_by_design,
    generate = generate.generate,
)
