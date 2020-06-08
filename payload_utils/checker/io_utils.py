# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import json
import pathlib

from typing import Any, Dict

from google.protobuf import json_format
from google.protobuf.message import Message

from chromiumos.config.payload import config_bundle_pb2



def write_message_json(message: Message, path: pathlib.Path, \
                       default_fields=False):
  """Take a Message and write it to a file as json.

  Args:
    message: protobuf message to write to file
    path: output file write json to
    default_fields: If true, include default values for fields
  """
  # ow this is a long parameter
  opts = {'including_default_value_fields': default_fields, 'sort_keys': True}

  with open(path, 'w') as outfile:
    outfile.write(json_format.MessageToJson(message, **opts))


def read_config(path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a ConfigBundle mesage from a jsonpb file.

  Args:
    path: Path to the json proto. See note above about deprecated repo
           root behavior.

  Returns:
    ConfigBundle parsed from file.
  """
  project_config = config_bundle_pb2.ConfigBundle()
  with open(path, 'r') as f:
    json_format.Parse(f.read(), project_config)
  return project_config


def read_model_sku_json(factory_dir: pathlib.Path) -> Dict[str, Any]:
  """Reads and parses the model_sku.json file.

  Args:
    factory_dir: Path to a project's factory dir.

  Returns:
    Parsed model_sku.json as a dict
  """
  with open(factory_dir.joinpath('generated', 'model_sku.json')) as f:
    return json.load(f)
