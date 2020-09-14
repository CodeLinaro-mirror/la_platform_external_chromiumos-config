"""Functions related to system image config.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/config/api/software/system_image.proto",
    system_pb = "chromiumos.config.api.software",
)
load("//config/util/portage.star", "portage")

def _create_build_target(overlay = None, profile = None, use_flags = None):
    return system_pb.SystemImage.BuildTarget(
        portage_build_target = portage.create_build_target(
            overlay,
            profile,
            use_flags,
        ),
    )

system_image = struct(
    create_build_target = _create_build_target,
)
