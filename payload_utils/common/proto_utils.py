# python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Proto-related helper functions."""

from typing import Any, Dict, List, Text

from google.protobuf import message as pb_message


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
