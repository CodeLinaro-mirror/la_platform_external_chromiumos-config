"""Loads proto descriptors, including imports, of this repo into lucicfg proto
registry, so protos can be imported as load("@proto//...").
"""

lucicfg.check_version("1.8.6", "Please update depot_tools")

# Descriptor set providing commonly used protocol buffers such
# as duration, field_mask, etc.. See LUCI docs.
# buildifier: disable=load-on-top
load("@stdlib//internal/descpb.star", "wellknown_descpb")

longrunning_operations = proto.new_descriptor_set(
    name = "google/longrunning/operations",
    blob = io.read_file("google_longrunning_operations_descpb.bin"),
    deps = [wellknown_descpb],
)

protos = proto.new_descriptor_set(
    name = "chromiumos",
    blob = io.read_file("descpb.bin"),
    deps = [wellknown_descpb, longrunning_operations],
)

# We register here so that users don't have to.
protos.register()
