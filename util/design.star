load("//config/proto/proto.star", "protos")
protos.register()

load("@proto//src/config/api/design.proto", design_pb = "chromiumos.config.api")
load("@proto//src/config/api/design_config_id.proto", config_id_pb = "chromiumos.config.api")
load("@proto//src/config/api/design_id.proto", design_id_pb = "chromiumos.config.api")

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

def _create_config(design_id, config_id, hw_features=None, hw_topology=None):
  design_config_id = config_id_pb.DesignConfigId(
      value="%s:%s" % (design_id.value, config_id))
  return design_pb.Design.Config(id=design_config_id,
                                 hardware_features=hw_features,
                                 hardware_topology=hw_topology,)

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

design = struct(
    create_constraint = _create_constraint,
    create_constraints = _create_constraints,
    create_config = _create_config,
    create_design_id = _create_design_id,
    create_design = _create_design,
    create_design_list = _create_design_list,
    constraint = _CONSTRAINT,
)
