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

def _create_build_metadata(build_target, portage_packages):
    return system_pb.SystemImage.BuildMetadata(
        build_target = build_target,
        packages = portage_packages,
    )

system_image = struct(
    create_build_target = _create_build_target,
    create_build_metadata = _create_build_metadata,
)
