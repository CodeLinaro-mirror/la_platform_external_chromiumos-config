load("//config/util/bindings/proto.star", "protos")

protos.register()

load("@proto//api/program.proto", program_pb = "chromiumos.config.api")
load("@proto//api/program_id.proto", program_id_pb = "chromiumos.config.api")

load("//config/util/generate.star", generate = "generate")

def _create_firmware_configuration_segment(name, mask):
    return program_pb.FirmwareConfigurationSegment(
        name = name,
        mask = mask,
    )

def _create(name, component_quals = None, constraints = None, firmware_configuration_segments = None):
    program_id = program_id_pb.ProgramId(value = name)
    return program_pb.Program(
        id = program_id,
        name = name,
        component_quals = component_quals,
        design_config_constraints = constraints,
        firmware_configuration_segments = firmware_configuration_segments,
    )

def _create_list(programs):
    return program_pb.ProgramList(value = programs)

program = struct(
    create = _create,
    create_list = _create_list,
    create_firmware_configuration_segment = _create_firmware_configuration_segment,
    generate = generate.generate,
)
