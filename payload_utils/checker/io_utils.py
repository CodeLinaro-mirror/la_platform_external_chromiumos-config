# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import os

from bindings.api import config_bundle_pb2


def read_config(path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a binary proto from a file.

    Args:
        path: Path to the binary proto. See note above about deprecated repo
        root behavior.
    """
  project_config = config_bundle_pb2.ConfigBundle()
  with open(os.path.join(path), 'rb') as f:
    project_config.ParseFromString(f.read())
  return project_config
