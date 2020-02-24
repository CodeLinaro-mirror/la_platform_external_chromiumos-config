# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for io_utils."""

import os
import tempfile
import unittest

from checker import io_utils

from bindings.api.config_bundle_pb2 import ConfigBundle
from bindings.api.program_pb2 import ProgramList, Program


class IoUtilsTest(unittest.TestCase):
  """Tests for io_utils."""

  def setUp(self):
    self.config = ConfigBundle(
        programs=ProgramList(value=[Program(name='TestProgram1')]))
    self.repo_path = tempfile.mkdtemp()

    os.mkdir(os.path.join(self.repo_path, 'generated'))

    with open(
        os.path.join(self.repo_path, 'generated', 'config.binaryproto'),
        'wb') as f:
      f.write(self.config.SerializeToString())

  def test_read_repo_config(self):
    """Tests the binary proto can be read."""
    self.assertEqual(io_utils.read_repo_config(self.repo_path), self.config)
