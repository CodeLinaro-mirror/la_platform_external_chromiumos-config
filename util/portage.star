"""Functions related to portage config.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/config/api/software/portage.proto",
    portage_pb = "chromiumos.config.api.software",
)

def _create_build_target(overlay = None, profile = None, use_flags = None):
    return portage_pb.Portage.BuildTarget(
        overlay_name = overlay,
        profile_name = profile,
        use_flags = use_flags,
    )

portage = struct(
    create_build_target = _create_build_target,
)
