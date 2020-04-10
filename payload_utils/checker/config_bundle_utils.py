# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""ConfigBundle-related helper functions."""

from chromiumos.config.payload import config_bundle_pb2
from chromiumos.config.api import program_pb2


def get_program(
    config_bundle: config_bundle_pb2.ConfigBundle) -> program_pb2.Program:
  """Returns the one program in config_bundle.

  Raises if config_bundle doesn't have exactly one program.
  """
  programs = config_bundle.programs.value
  if len(programs) != 1:
    raise ValueError('Expected exactly one program')

  return programs[0]
