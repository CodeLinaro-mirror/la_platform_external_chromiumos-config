# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import os

from chromiumos.config.payload import config_bundle_pb2

from google.protobuf import json_format


def read_config(path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a json proto from a file.

    Args:
        path: Path to the json proto. See note above about deprecated repo
        root behavior.
    """
  try:
    return _read_json_config(path)
  except:
    # TODO(crbug.com/1073530): remove binary pb fallback when transition to
    # json pb is complete.
    return _read_binary_config(path)


def _read_json_config(path: str) -> config_bundle_pb2.ConfigBundle:
  project_config = config_bundle_pb2.ConfigBundle()
  with open(path, 'r') as f:
    json_format.Parse(f.read(), project_config)
  return project_config


def _read_binary_config(path: str) -> config_bundle_pb2.ConfigBundle:
  project_config = config_bundle_pb2.ConfigBundle()
  with open(os.path.join(path), 'rb') as f:
    project_config.ParseFromString(f.read())
  return project_config
