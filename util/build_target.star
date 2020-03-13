load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/build_target_id.proto", bt_id_pb = "chromiumos.config.api")
load("@proto//api/software/build_target.proto", bt_pb = "chromiumos.config.api.software")

def _create(name, arc_device = None, first_api_level = '28'):
  return bt_pb.BuildTarget(
    id = bt_id_pb.BuildTargetId(value = name),
    overlay_name = name,
    arc = bt_pb.BuildTarget.ArcBuildProperties(
      device = arc_device or "%s_cheets" % name,
      first_api_level = first_api_level,
    ),
  )

build_target = struct(
    create = _create,
)
