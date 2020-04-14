"""Functions related to program configs.

See proto definitions for descriptions of arguments.
"""

load("//config/util/bindings/proto.star", "protos")
load("@proto//api/program.proto", program_pb = "chromiumos.config.api")
load("@proto//api/program_id.proto", program_id_pb = "chromiumos.config.api")
load("@proto//api/device_brand_id.proto", db_id_pb = "chromiumos.config.api")
load("//config/util/generate.star", "generate")

def _create_firmware_configuration_segment(name, mask):
    """Builds a FirmwareConfigurationSegment proto."""
    return program_pb.FirmwareConfigurationSegment(
        name = name,
        mask = mask,
    )

def _create_signer_config(device_brand_id, key_id):
    """Builds a DeviceSignerConfig proto."""
    return program_pb.DeviceSignerConfig(
        brand_id = db_id_pb.DeviceBrandId(value=device_brand_id),
        key_id = key_id,
    )

def _create(name,
            component_quals=None,
            constraints=None,
            firmware_configuration_segments=None,
            device_signer_configs=None):
    """Builds a Program proto."""
    program_id = program_id_pb.ProgramId(value = name)
    return program_pb.Program(
        id=program_id,
        name=name,
        component_quals=component_quals,
        design_config_constraints=constraints,
        firmware_configuration_segments=firmware_configuration_segments,
        device_signer_configs=device_signer_configs,
    )

def _create_list(programs):
    """Builds a ProgramList proto."""
    return program_pb.ProgramList(value = programs)

program = struct(
    create = _create,
    create_list = _create_list,
    create_firmware_configuration_segment = _create_firmware_configuration_segment,
    create_signer_config = _create_signer_config,
    generate = generate.generate,
)
