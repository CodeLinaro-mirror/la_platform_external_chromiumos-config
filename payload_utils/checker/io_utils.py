# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IO-related helper functions."""

import os
import warnings

from bindings.api import config_bundle_pb2


def read_config(path: str) -> config_bundle_pb2.ConfigBundle:
  """Reads a binary proto from a file.

    Note that passing paths to repo roots is deprecated, and will raise a
    warning. If a repo root is passed, it is assumed the config can be found at
    'generated/config.binaryproto'.

    Args:
        path: Path to the binary proto. See note above about deprecated repo
        root behavior.
    """
  if os.path.isdir(path):
    warnings.warn(
        ('Passing a path to a repo root is deprecated, please pass a full path'
         ' to a binary proto. Path: {}'.format(path)), FutureWarning)
    path = os.path.join(path, 'generated', 'config.binaryproto')

  project_config = config_bundle_pb2.ConfigBundle()
  with open(os.path.join(path), 'rb') as f:
    project_config.ParseFromString(f.read())
  return project_config
