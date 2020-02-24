load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/program.proto", program_pb = "chromiumos.config.api")
load("@proto//api/program_id.proto", program_id_pb = "chromiumos.config.api")


def _create(name, component_quals = None, constraints = None):
  program_id = program_id_pb.ProgramId(value=name)
  return program_pb.Program(id = program_id,
                            name = name,
                            component_quals = component_quals,
                            design_config_constraints = constraints,)

def _create_list(programs):
  return program_pb.ProgramList(value = programs)

program = struct(
    create = _create,
    create_list = _create_list,
)
