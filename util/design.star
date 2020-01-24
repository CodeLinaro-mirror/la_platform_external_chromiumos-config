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

design = struct(
    create_constraint = _create_constraint,
    create_constraints = _create_constraints,
    constraint = _CONSTRAINT,
)