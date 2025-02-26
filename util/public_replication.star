"""Helper functions for building PublicReplication protos."""

load("@proto//google/protobuf/field_mask.proto", field_mask_pb = "google.protobuf")
load(
    "@proto//chromiumos/config/public_replication/public_replication.proto",
    public_replication_pb = "chromiumos.config.public_replication",
)

def _create(public_fields):
    """Creates a PublicReplication proto.

    Args:
        public_fields: A list of strings specifying fields that should be made
            public. See comment on the PublicReplication proto for semantics
            and example of how the proto works. Required.

    Returns:
        A PublicReplication proto, None if public_fields evaluates to False.
    """
    if public_fields:
        return public_replication_pb.PublicReplication(
            public_fields = field_mask_pb.FieldMask(paths = public_fields),
        )

    return None

public_replication = struct(
    create = _create,
)
