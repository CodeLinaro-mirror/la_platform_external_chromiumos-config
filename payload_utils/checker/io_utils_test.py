# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for io_utils."""

import os
import tempfile
import unittest

from checker import io_utils

from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle
from chromiumos.config.api.program_pb2 import ProgramList, Program

from google.protobuf import json_format


class IoUtilsTest(unittest.TestCase):
  """Tests for io_utils."""

  def setUp(self):
    self.config = ConfigBundle(
        programs=ProgramList(value=[Program(name='TestProgram1')]))
    repo_path = tempfile.mkdtemp()

    os.mkdir(os.path.join(repo_path, 'generated'))

    self.config_path = os.path.join(repo_path, 'generated', 'config.jsonproto')
    json_output = json_format.MessageToJson(
        self.config, sort_keys=True, use_integers_for_enums=True)
    with open(self.config_path, 'w') as f:
      print(json_output, file=f)

  def test_read_config(self):
    """Tests the json proto can be read."""
    self.assertEqual(io_utils.read_config(self.config_path), self.config)
