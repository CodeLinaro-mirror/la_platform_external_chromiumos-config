load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/design.proto", design_pb = "chromiumos.config.api")
load("@proto//api/design_config_id.proto", config_id_pb = "chromiumos.config.api")
load("@proto//api/design_id.proto", design_id_pb = "chromiumos.config.api")

load("//config/util/hw_topology.star", hw_topo = "hw_topo")

_CONSTRAINT = struct(
    REQUIRED = design_pb.Design.Config.Constraint.REQUIRED,
    PREFERRED = design_pb.Design.Config.Constraint.PREFERRED,
    OPTIONAL = design_pb.Design.Config.Constraint.OPTIONAL,
)

def _create_constraint(hw_features, level = _CONSTRAINT.REQUIRED):
  return design_pb.Design.Config.Constraint(level=level, features=hw_features,)

def _create_constraints(hw_features, level = _CONSTRAINT.REQUIRED):
  return [design_pb.Design.Config.Constraint(
      level=level, features=hw_feature) for hw_feature in hw_features]

def _create_config(design_id, config_id, base_hw_features = None, hardware_topology=None):
  result = design_pb.Design.Config()
  result.id.value = "%s:%s" % (design_id.value, config_id)
  result.hardware_topology = hardware_topology
  result.hardware_features = hw_topo.convert_to_hw_features(
    base_hw_features, hardware_topology)
  return result

def _create_design_id(name):
  return design_id_pb.DesignId(value=name)

def _create_design(id, program_id, odm_id, configs = None):
  return design_pb.Design(
      id=id,
      program_id=program_id,
      odm_id=odm_id,
      name=id.value,
      configs=configs,
  )

def _create_design_list(designs):
  return design_pb.DesignList(value=designs)

def _generate(config):
  def _generate_impl(ctx):
    ctx.output["config.cfg"] = proto.to_jsonpb(config)
    ctx.output["config.binaryproto"] = proto.to_wirepb(config)
  lucicfg.generator(impl = _generate_impl)

design = struct(
    create_constraint = _create_constraint,
    create_constraints = _create_constraints,
    create_config = _create_config,
    create_design_id = _create_design_id,
    create_design = _create_design,
    create_design_list = _create_design_list,
    constraint = _CONSTRAINT,
    generate = _generate,
)
