# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for proto_utils."""

import unittest

from chromiumos.config.payload import config_bundle_pb2
from common import config_bundle_utils


class ConfigBundleUtilsTest(unittest.TestCase):
  """Tests for config_bundle_utils."""

  def test_find_program(self):
    """Test the find_program method."""
    empty = config_bundle_pb2.ConfigBundle()
    bundle = config_bundle_pb2.ConfigBundle()
    program = bundle.program_list.add()
    program.name = 'TestProgram'
    program.id.value = 'TestProgram'

    self.assertIsNone(config_bundle_utils.find_program(empty, 'TestProgram'))
    self.assertEqual(
        config_bundle_utils.find_program(empty, 'TestProgram', create=True),
        program)
    self.assertEqual(
        config_bundle_utils.find_program(empty, 'TestProgram'), program)

    self.assertEqual(
        config_bundle_utils.find_program(bundle, 'TestProgram'), program)
    self.assertEqual(
        config_bundle_utils.find_program(bundle, 'testprogram'), program)
    self.assertIsNone(
        config_bundle_utils.find_program(bundle, 'does_not_exist'))
