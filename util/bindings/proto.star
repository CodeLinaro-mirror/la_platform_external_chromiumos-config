"""Loads proto descriptors, including imports, of this repo into lucicfg proto
registry, so protos can be imported as load("@proto//...").
"""

lucicfg.check_version("1.8.6", "Please update depot_tools")

# Descriptor set providing commonly used protocol buffers such
# as duration, field_mask, etc.. See LUCI docs.
# buildifier: disable=load-on-top
load("@stdlib//internal/descpb.star", "wellknown_descpb")
load("@proto//google/protobuf/descriptor.proto", descriptorpb = "google.protobuf")

protos = proto.new_descriptor_set(
    name = "chromiumos",
    blob = proto.to_wirepb(
        io.read_proto(
            descriptorpb.FileDescriptorSet,
            "../../generated/descriptors.json",
        ),
    ),
    deps = [wellknown_descpb],
)

# We register here so that users don't have to.
protos.register()
