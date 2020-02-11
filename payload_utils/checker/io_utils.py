# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import os

from bindings.src.config.api import config_bundle_pb2


def read_repo_config(repo_path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a binary proto from a file in a program or project repo.

    Args:
        repo_path: Path to the root of the program or project repo.
    """
  project_config = config_bundle_pb2.ConfigBundle()
  with open(os.path.join(repo_path, 'generated', 'config.binaryproto'),
            'rb') as f:
    project_config.ParseFromString(f.read())
  return project_config
