"""Functions related to build targets.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/software/build_target_id.proto",
    bt_id_pb = "chromiumos.config.api.software",
)
load(
    "@proto//chromiumos/config/api/software/build_target.proto",
    bt_pb = "chromiumos.config.api.software",
)
load("//config/util/public_replication.star", "public_replication")

def _create(
        name,
        overlay_name = None,
        arc_device = None,
        first_api_level = "28",
        public_fields = None):
    """Builds a BuildTarget proto.

    Args:
        name: Name of the build target, e.g. "galaxy". Required.
        public_fields: Fields replicated to public configs. See
            PublicReplication proto for details.
        overlay_name: Name of the Portage overlay, e.g.
            "overlay-galaxy-private". If not specified, "name" is used.
        arc_device: Device name to report in ‘ro.product.device’. If not
            specified, "name"_cheets is used.
        first_api_level: The first Android API level that this build shipped
            with.

    Returns:
        A BuildTarget proto.
    """
    overlay_name = overlay_name or name
    return bt_pb.BuildTarget(
        public_replication = public_replication.create(public_fields = public_fields),
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
