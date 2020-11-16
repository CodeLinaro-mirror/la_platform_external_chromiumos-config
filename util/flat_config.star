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

flat_config = struct(
    read = _read,
)
