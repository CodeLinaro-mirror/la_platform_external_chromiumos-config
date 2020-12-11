"""Functions related to build metadata processing

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

def _read(file_path):
    return proto.from_jsonpb(
        system_pb.SystemImage.BuildMetadataList,
        io.read_file(file_path),
    )

def _get_kernel_versions(build_metadata_list):
    """Returns dict of {kernel-version: overlay-name}"""
    kernel_versions = {}
    for build_metadata in build_metadata_list.values:
        overlay = build_metadata.build_target.portage_build_target.overlay_name
        for package in build_metadata.packages:
            if package.category == "sys-kernel":
                # version example = 4.4.111-r2222
                m = re.submatches("(\\d+\\.\\d+)\\..*", package.version)
                version = m[1]
                overlays = kernel_versions.get(version, [])
                overlays.append(overlay)
                kernel_versions[version] = overlays
    unique_kernel_overlays = {}
    for version in kernel_versions:
        unique_kernel_overlays[version] = set(kernel_versions[version])
    return unique_kernel_overlays

build_metadata = struct(
    read = _read,
    get_kernel_versions = _get_kernel_versions,
)
