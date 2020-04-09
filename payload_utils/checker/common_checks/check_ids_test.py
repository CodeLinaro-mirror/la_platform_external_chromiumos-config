# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for check_ids."""

import unittest

from checker.common_checks.check_ids import IdConstraintSuite

from config.payload.config_bundle_pb2 import ConfigBundle
from config.api.design_pb2 import Design, DesignList
from config.api.program_pb2 import Program, ProgramList
from config.api.program_id_pb2 import ProgramId


class CheckIdsTest(unittest.TestCase):
  """Tests for check_ids."""

  def test_check_ids_consistent(self):
    """Tests check_ids_consistent with valid configs."""
    program_config = ConfigBundle(
        programs=ProgramList(
            value=[Program(id=ProgramId(value='testprogram1'))]))

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(program_id=ProgramId(value='testprogram1')),
            Design(program_id=ProgramId(value='testprogram1')),
        ]))

    IdConstraintSuite().check_ids_consistent(
        program_config=program_config, project_config=project_config)

  def test_check_ids_consistent_violated(self):
    """Tests check_ids_consistent with invalid configs."""
    program_config = ConfigBundle(
        programs=ProgramList(
            value=[Program(id=ProgramId(value='testprogram1'))]))

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(program_id=ProgramId(value='testprogram1')),
            Design(program_id=ProgramId(value='testprogram2')),
        ]))

    with self.assertRaises(AssertionError):
      IdConstraintSuite().check_ids_consistent(
          program_config=program_config, project_config=project_config)
