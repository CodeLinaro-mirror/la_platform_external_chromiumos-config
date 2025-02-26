"""Functions related to portage config.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/build/api/portage.proto",
    portage_pb = "chromiumos.build.api",
)

def _create_build_target(overlay = None, profile = None, use_flags = None):
    return portage_pb.Portage.BuildTarget(
        overlay_name = overlay,
        profile_name = profile,
        use_flags = use_flags,
    )

def _package(name, category, version):
    return portage_pb.Portage.Package(
        package_name = name,
        category = category,
        version = version,
    )

portage = struct(
    create_build_target = _create_build_target,
    package = _package,
)
