"""Functions related to system image config.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/build/api/system_image.proto",
    system_pb = "chromiumos.build.api",
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

def _create_build_metadata(build_target, packages, package_summary = None):
    return system_pb.SystemImage.BuildMetadata(
        build_target = build_target,
        packages = packages,
        package_summary = package_summary,
    )

def _create_build_metadata_list(values):
    return system_pb.SystemImage.BuildMetadataList(
        values = values,
    )

def _create_package_summary(
        arc = None,
        chrome = None,
        chipset = None,
        kernel = None,
        toolchain = None):
    metadata_pb = system_pb.SystemImage.BuildMetadata

    return metadata_pb.PackageSummary(
        arc = metadata_pb.Arc(version = arc),
        chrome = metadata_pb.AshChrome(version = chrome),
        chipset = metadata_pb.Chipset(overlay = chipset),
        kernel = metadata_pb.Kernel(version = kernel),
        toolchain = metadata_pb.Toolchain(version = toolchain),
    )

system_image = struct(
    create_build_target = _create_build_target,
    create_build_metadata = _create_build_metadata,
    create_build_metadata_list = _create_build_metadata_list,
    create_package_summary = _create_package_summary,
)
