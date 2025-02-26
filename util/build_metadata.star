"""Functions related to processing BuildMetadata from SystemImage

See proto definitions for descriptions of arguments.
"""

# Add @unused to silence lint.
load("@stdlib//internal/re.star", "re")

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/build/api/system_image.proto",
    system_pb = "chromiumos.build.api",
)

def _overlay(build_metadata):
    """Break out the overlay name from BuildMetadata."""
    return build_metadata.build_target.portage_build_target.overlay_name

def _kernel_version(build_metadata):
    """Gets the major kernel version for the overlay"""
    return build_metadata.package_summary.kernel.version

def _soc_family(build_metadata):
    """Gets the SoC Family name for a given overlay"""
    return build_metadata.package_summary.chipset.overlay

def _remove_invalid_entries(bs_list):
    """Filter out any invalid metadata based on overlay name."""
    invalid = [
        "galaxy",  # Test overlay
        # TODO: Filter non-cros devices.
        # Warning ... they may not be public and this is a public repo.
    ]
    return [bs for bs in bs_list if _overlay(bs).lower() not in invalid]

def _read(file_path):
    """Read a BuildMetadataList from a json proto."""
    build_metadata_list = proto.from_jsonpb(
        system_pb.SystemImage.BuildMetadataList,
        io.read_file(file_path),
    )
    return _remove_invalid_entries(build_metadata_list.values)

def _get_kernel_versions(build_metadata_list):
    """Returns dict of {kernel-version: [overlay-name, ...]}"""
    kernel_versions = {}
    for build_metadata in build_metadata_list:
        overlay = _overlay(build_metadata)
        version = _kernel_version(build_metadata)
        if not version:
            continue

        overlays = kernel_versions.get(version, [])
        overlays.append(overlay)
        kernel_versions[version] = overlays
    unique_kernel_overlays = {}
    for version in kernel_versions:
        unique_kernel_overlays[version] = set(kernel_versions[version])
    return unique_kernel_overlays

def _get_soc_families(build_metadata_list):
    """Returns dict of {overlay-name: soc-family} if the SOC value is set"""
    soc_families = {}
    for build_metadata in build_metadata_list:
        overlay = _overlay(build_metadata)
        soc_family = _soc_family(build_metadata)
        if soc_family:
            soc_families[overlay] = soc_family
    return soc_families

def _get_overlays(build_metadata_list):
    """Returns set of all overlays"""
    return set([_overlay(bm) for bm in build_metadata_list])

def _get_socs_kernels_overlays(build_metadata_list):
    """Returns a map of all unique SoC familes, kernel-versions, and overlays

    Args:
        build_metadata_list: Software Build config bundle
    Returns:
        map: {soc-family: {kernel-version: overlays[]}}
    """
    socs_kernels_overlays = {}
    for build_metadata in build_metadata_list:
        overlay = _overlay(build_metadata)
        soc_family = _soc_family(build_metadata)
        kernel = _kernel_version(build_metadata)
        if soc_family and kernel:
            kernels = socs_kernels_overlays.setdefault(soc_family, {})
            overlays = kernels.setdefault(kernel, [])
            overlays.append(overlay)
    return socs_kernels_overlays

build_metadata = struct(
    read = _read,
    get_kernel_versions = _get_kernel_versions,
    get_soc_families = _get_soc_families,
    get_socs_kernels_overlays = _get_socs_kernels_overlays,
    get_overlays = _get_overlays,
)
