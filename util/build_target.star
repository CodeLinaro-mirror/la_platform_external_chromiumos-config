"""Functions related to build targets.

See proto definitions for descriptions of arguments.
"""

load("@proto//api/software/build_target_id.proto", bt_id_pb = "chromiumos.config.api.software")
load("@proto//api/software/build_target.proto", bt_pb = "chromiumos.config.api.software")
load("//config/util/bindings/proto.star", "protos")

protos.register()

def _create(
        name,
        overlay_name = None,
        arc_device = None,
        first_api_level = "28"):
    """Builds a BuildTarget proto."""
    overlay_name = overlay_name or name
    return bt_pb.BuildTarget(
        id = bt_id_pb.BuildTargetId(value = name),
        overlay_name = overlay_name,
        arc = bt_pb.BuildTarget.ArcBuildProperties(
            device = arc_device or "%s_cheets" % name,
            first_api_level = first_api_level,
        ),
    )

build_target = struct(
    create = _create,
)
