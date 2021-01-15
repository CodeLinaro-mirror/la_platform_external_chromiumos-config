"""Functions related to build summary processing

See proto definitions for descriptions of arguments.
"""

# Add @unused to silence lint.
load("@stdlib//internal/re.star", "re")

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/software/system_image.proto",
    system_pb = "chromiumos.config.api.software",
)

def _overlay(build_summary):
    return build_summary.build_target.portage_build_target.overlay_name

def _remove_invalid_entries(bs_list):
    invalid = [
        "galaxy",  # Test overlay
        # TODO: Filter non-cros devices.
        # Warning ... they may not be public and this is a public repo.
    ]
    return [bs for bs in bs_list if _overlay(bs) not in invalid]

def _read(file_path):
    build_summary_list = proto.from_jsonpb(
        system_pb.SystemImage.BuildSummaryList,
        io.read_file(file_path),
    )
    return _remove_invalid_entries(build_summary_list.values)

def _get_kernel_versions(build_summaries):
    """Returns dict of {kernel-version: [overlay-name, ...]}"""
    kernel_versions = {}
    for build_summary in build_summaries:
        overlay = _overlay(build_summary)
        version = build_summary.kernel.version
        overlays = kernel_versions.get(version, [])
        overlays.append(overlay)
        kernel_versions[version] = overlays
    unique_kernel_overlays = {}
    for version in kernel_versions:
        unique_kernel_overlays[version] = set(kernel_versions[version])
    return unique_kernel_overlays

def _get_soc_families(build_summaries):
    """Returns dict of {overlay-name: soc-family} if the SOC value is set"""
    soc_families = {}
    for build_summary in build_summaries:
        overlay = build_summary.build_target.portage_build_target.overlay_name
        soc_family = build_summary.chipset.overlay
        if soc_family:
            soc_families[overlay] = soc_family
    return soc_families

build_summary = struct(
    read = _read,
    get_kernel_versions = _get_kernel_versions,
    get_soc_families = _get_soc_families,
)
