"""Functions related to flat config payloads

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/payload/flat_config.proto",
    flat_config_pb = "chromiumos.config.payload",
)

def _read(file_path):
    return proto.from_jsonpb(
        flat_config_pb.FlatConfigList,
        io.read_file(file_path),
    )

def _get_designs_by_overlay(design_configs):
    """Returns dict of {overlay1: [design1, design2], overlay2...}"""
    overlay_to_designs = {}
    for design_config in design_configs.values:
        design_name = design_config.hw_design.name
        build_target = design_config.sw_config.system_build_target
        program_name = design_config.program.name.lower()
        overlay = build_target.portage_build_target.overlay_name or program_name
        designs = overlay_to_designs.get(overlay, [])
        designs.append(design_name)
        overlay_to_designs[overlay] = designs

    overlay_to_unique_designs = {}
    for overlay in overlay_to_designs:
        overlay_to_unique_designs[overlay] = set(overlay_to_designs[overlay])
    return overlay_to_unique_designs

flat_config = struct(
    read = _read,
    get_designs_by_overlay = _get_designs_by_overlay,
)
