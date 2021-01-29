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

def _create_build_metadata_list(builds):
    return system_pb.SystemImage.BuildMetadataList(
        values = builds,
    )

def _create_build_summary(
        build_target,
        kernel = None,
        chipset = None,
        arc = None):
    return system_pb.SystemImage.BuildSummary(
        build_target = build_target,
        kernel = system_pb.SystemImage.BuildSummary.Kernel(version = kernel),
        chipset = system_pb.SystemImage.BuildSummary.Chipset(overlay = chipset),
        arc = system_pb.SystemImage.BuildSummary.Arc(version = arc),
    )

def _create_build_summary_list(build_summaries):
    return system_pb.SystemImage.BuildSummaryList(
        values = build_summaries,
    )

system_image = struct(
    create_build_target = _create_build_target,
    create_build_metadata = _create_build_metadata,
    create_build_metadata_list = _create_build_metadata_list,
    create_build_summary = _create_build_summary,
    create_build_summary_list = _create_build_summary_list,
)
