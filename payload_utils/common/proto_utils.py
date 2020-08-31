# python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Proto-related helper functions."""

import copy

from typing import Any, Dict, List, Text

from google.protobuf import message as pb_message

from chromiumos.config.public_replication import public_replication_pb2


def get_all_fields(message: pb_message.Message) -> List[Any]:
  """Returns the value of each field in message.

  Note that the value, not the name, is returned. For example, given a Timestamp
  message:

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


def get_dep_graph(message: pb_message.Message) -> Dict[Text, List[Text]]:
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


def get_dep_order(message: pb_message.Message) -> List[Text]:
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
  if src.DESCRIPTOR.full_name != dst.DESCRIPTOR.full_name:
    raise ValueError(
        'src and dst must be the same message type. Got '
        f'{src.DESCRIPTOR.full_name} and {dst.DESCRIPTOR.full_name}')

  # First, see if any of the fields on src are a PublicReplication message. If
  # one is found, apply the field mask within it.
  for field_descriptor in src.DESCRIPTOR.fields:
    message_descriptor = field_descriptor.message_type
    if (message_descriptor and message_descriptor.full_name
        == public_replication_pb2.PublicReplication.DESCRIPTOR.full_name):
      public_fields = getattr(src, field_descriptor.name).public_fields
      public_fields.MergeMessage(src, dst)

  # Iterate the fields of src and call apply_public_replication
  # recursively.
  for field_descriptor in src.DESCRIPTOR.fields:
    if field_descriptor.type != field_descriptor.TYPE_MESSAGE:
      continue

    if field_descriptor.label == field_descriptor.LABEL_REPEATED:
      # For repeated fields, for each message in src, create a new message in
      # dst and call apply_public_replication.
      for next_src in getattr(src, field_descriptor.name):
        # map fields are considered repeated messages, but do not have an 'add'
        # method. Skip this case. It wasn't clear if there was a better way to
        # detect a map field via the descriptor.
        dst_field = getattr(dst, field_descriptor.name)
        if hasattr(dst_field, 'add'):
          next_dst = dst_field.add()

          # If the newly added field doesn't have any fields set, remove it to
          # avoid creating many empty messages on dst. Create a copy of next_dst
          # to check if next_dst changed after the recursive call to
          # apply_public_replication and remove next_dst from the
          # list if it didn't change.
          next_dst_copy = copy.deepcopy(next_dst)

          apply_public_replication(next_src, next_dst)

          if dst_field[-1] == next_dst_copy:
            dst_field.pop()
    else:
      # For non-repeated fields, get the field in src and dst and call
      # apply_public_replication.
      next_src = getattr(src, field_descriptor.name)
      next_dst = getattr(dst, field_descriptor.name)
      apply_public_replication(next_src, next_dst)
