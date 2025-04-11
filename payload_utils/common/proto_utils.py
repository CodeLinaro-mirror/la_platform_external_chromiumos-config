# python3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Proto-related helper functions."""

import importlib
import os
from typing import Any, Dict, List, NamedTuple, Optional, Set

from chromiumos.config.public_replication import public_replication_pb2
from google.protobuf import message as pb_message
from google.protobuf import symbol_database
from google.protobuf.descriptor import FieldDescriptor


def _build_type_map():
    """Build a map from the TYPE_* constants in protobuf to string names."""
    mapping = {}
    for field in dir(FieldDescriptor):
        if field.startswith("TYPE_"):
            mapping[getattr(FieldDescriptor, field)] = field[5:].lower()
    return mapping


type_strings = _build_type_map()


class FieldInfo(NamedTuple):
    """Named tuple to represent information about a proto field.

    Fields:
      name:     Name of the field in the message
      typeid:   FieldDescriptor type for the field
      typename: For compound fields, the name of the message type.
                For value fields, a string-ified type name
      repeated: True if the field is repeated
    """

    name: str
    typeid: int
    typename: str
    repeated: bool


def create_symbol_db() -> symbol_database.SymbolDatabase:
    """Load any generated messages from python/ and return symbol database.

    Messages auto-register when imported, so we just recursively import and
    generate protobuffer files and return the default instance of
    SymbolDatabase.

    Returns:
        symbol_database.Default()
    """

    def __import_modules(dirname: str, paths: List[str]) -> None:
        """Recurse through a list of paths and automatically load protobufs.

        This starts with dirname and recursively descends looking for python
        files ending with _pb2.py and loads them into the current name space.

        Args:
            dirname: Directory name to process
            paths: list of parent paths names for current call
        """
        for path in os.listdir(dirname):
            full_path = os.path.join(dirname, path)

            if os.path.isdir(full_path) and not os.path.islink(full_path):
                __import_modules(full_path, paths + [path])
            elif os.path.isfile(full_path):
                if path.endswith("_pb2.py"):
                    importlib.import_module(
                        "%s.%s" % (".".join(paths), path[:-3])
                    )

    __import_modules(
        os.path.join(os.path.dirname(__file__), "../../python/chromiumos"),
        ["chromiumos"],
    )
    return symbol_database.Default()


def resolve_field_path(
    message: pb_message.Message,
    path: str,
) -> List[Optional[FieldInfo]]:
    """Resolve a dotted field path into specific information about the fields.

    A field path is of the format foo.bar.baz where the dotted notation .field
    indicates a particular field of the preceding message type.

    We resolve this by iteratively looking up each field starting with a root
    message type, and populating information about it.

    The result is a list of FieldInfo instances, one per field.  If a field
    is not found, then None is returned for it and subsequent fields.

    Args:
        message: a protobuffer Message type to root the path in
        path: a dotted field path
    """

    fields = path.split(".")
    infos = [None] * len(fields)

    current = message.DESCRIPTOR
    for idx, field in enumerate(fields):
        descriptor = current.fields_by_name.get(field)
        if not descriptor:
            break

        typename = type_strings[descriptor.type]
        if descriptor.message_type:
            typename = descriptor.message_type.name

        infos[idx] = FieldInfo(
            name=field,
            typeid=descriptor.type,
            typename=typename,
            repeated=(descriptor.label == descriptor.LABEL_REPEATED),
        )

        # If field isn't a message type then we're done
        if descriptor.type != descriptor.TYPE_MESSAGE:
            break

        current = descriptor.message_type

    return infos


def get_all_fields(message: pb_message.Message) -> List[Any]:
    """Returns the value of each field in message.

    Note that the value, not the name, is returned. For example, given a
    Timestamp message:

    {
      "seconds": 1,
      "nanos": 2
    }

    the result is [1, 2].
    """
    fields = []
    for field_descriptor in message.DESCRIPTOR.fields:
        fields.append(getattr(message, field_descriptor.name))
    return fields


def get_dep_graph(message: pb_message.Message) -> Dict[str, List[str]]:
    """Compute the dep graph of a message.

    This is a sparse representation of a DAG as a dict where the key is the
    name of a message, and the value is the list of that message's
    dependencies.
    """

    def helper(dep_graph, descriptor):
        deps = set()
        for field in descriptor.fields:
            if field.type == field.TYPE_MESSAGE:
                deps.add(field.message_type.full_name)
                helper(dep_graph, field.message_type)
        dep_graph[descriptor.full_name] = sorted(deps)

    graph = {}
    helper(graph, message.DESCRIPTOR)
    return graph


def get_dep_order(message: pb_message.Message) -> List[str]:
    """Compute dependency order of protobuf type and its dependencies.

    This is a list from a preorder traversal of the dependency graph above.
    """

    def dfs(graph, callback, node, seen=None):
        if seen is None:
            seen = set()

        if node in graph:
            for child in graph[node]:
                dfs(graph, callback, child, seen)

        if not node in seen:
            callback(node)
        seen.add(node)

    deps = []
    dfs(get_dep_graph(message), deps.append, message.DESCRIPTOR.full_name)
    return deps


def apply_public_replication(src: pb_message.Message, dst: pb_message.Message):
    """Traverses src and merges fields to dst when a PublicReplication message is
    found.

    See the comment on the PublicReplication proto for a complete description of
    the semantics of PublicReplication.

    Args:
        src: Source message.
        dst: Destination message to be merged into.
    """
    __apply_public_replication_internal(src, dst, visited_messages=set())


def __apply_public_replication_internal(
    src: pb_message.Message, dst: pb_message.Message, visited_messages=Set[str]
):
    """Private function to do most of the work of apply_public_replication.

    Allows bookkeeping information to be passed between recursive calls, along
    with the src and dst messages.

    Args:
        src: Source message.
        dst: Destination message to be merged into.
        visited_messages: Set of the full message names that have been visited
            higher in the call stack. Used to prevent infinite recursion if a
            message references itself.
    """
    if src.DESCRIPTOR.full_name != dst.DESCRIPTOR.full_name:
        raise ValueError(
            "src and dst must be the same message type. Got "
            f"{src.DESCRIPTOR.full_name} and {dst.DESCRIPTOR.full_name}"
        )

    # If a message with the same type as src has been visited higher in the call
    # stack, stop here. Then, create a new set with src's name in it. Note that
    # it doesn't work to add src's name to visited_messages, because a message
    # with the same type as src might be visited after this function exists,
    # e.g. in a list of messages with the same type.
    if src.DESCRIPTOR.full_name in visited_messages:
        return

    visited_messages = visited_messages.union([src.DESCRIPTOR.full_name])

    # First, see if any of the fields on src are a PublicReplication message. If
    # one is found, apply the field mask within it.
    for field_descriptor in src.DESCRIPTOR.fields:
        message_descriptor = field_descriptor.message_type
        if (
            message_descriptor
            and message_descriptor.full_name
            == public_replication_pb2.PublicReplication.DESCRIPTOR.full_name
        ):
            public_fields = getattr(src, field_descriptor.name).public_fields
            public_fields.MergeMessage(src, dst)

    # Iterate the fields of src and call __apply_public_replication_internal
    # recursively.
    for field_descriptor in src.DESCRIPTOR.fields:
        if field_descriptor.type != field_descriptor.TYPE_MESSAGE:
            continue

        if field_descriptor.label == field_descriptor.LABEL_REPEATED:
            # For repeated fields, for each message in src, create a new message
            # in dst and call __apply_public_replication_internal.
            for next_src in getattr(src, field_descriptor.name):
                # map fields are considered repeated messages, but do not have
                # an 'add' method. Skip this case. It wasn't clear if there was
                # a better way to detect a map field via the descriptor.
                dst_field = getattr(dst, field_descriptor.name)
                if hasattr(dst_field, "add"):
                    next_dst = dst_field.add()
                    __apply_public_replication_internal(
                        next_src, next_dst, visited_messages
                    )
                    # If the newly added field doesn't have any fields set,
                    # remove it to avoid creating many empty messages on dst.
                    if not dst_field[-1].ByteSize():
                        dst_field.pop()
        else:
            # For non-repeated fields, get the field in src and dst and call
            # __apply_public_replication_internal.
            next_src = getattr(src, field_descriptor.name)
            next_dst = getattr(dst, field_descriptor.name)
            __apply_public_replication_internal(
                next_src, next_dst, visited_messages
            )
            # If the newly added field doesn't have any fields set, remove it to
            # avoid creating many empty messages on dst, unless it was also
            # empty on src, since the presence of message fields may be
            # meaningful in some cases. Additionally, this avoids clobbering
            # fields nested within a message in a oneof where the currently-set
            # oneof is a different field.
            if not next_dst.ByteSize() and next_src.ByteSize():
                dst.ClearField(field_descriptor.name)
