# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import json
import pathlib

from chromiumos.config.payload import config_bundle_pb2

from google.protobuf import json_format


def read_config(path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a json proto from a file.

    Args:
        path: Path to the json proto. See note above about deprecated repo
        root behavior.
    """
  project_config = config_bundle_pb2.ConfigBundle()
  with open(path, 'r') as f:
    json_format.Parse(f.read(), project_config)
  return project_config


def read_model_sku_json(factory_dir: pathlib.Path) -> dict:
  """Reads and parses the model_sku.json file.

  Args:
      factory_dir: Path to a project's factory dir.
  """
  with open(factory_dir.joinpath('generated', 'model_sku.json')) as f:
    return json.load(f)
