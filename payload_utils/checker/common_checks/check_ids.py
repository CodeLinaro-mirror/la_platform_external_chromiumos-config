# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Constraint checks related to program and project ids."""

from checker import constraint_suite

from chromiumos.config.payload import config_bundle_pb2


class IdConstraintSuite(constraint_suite.ConstraintSuite):
  """Constraint checks related to program and project ids."""

  def check_ids_consistent(self, program_config: config_bundle_pb2.ConfigBundle,
                           project_config: config_bundle_pb2.ConfigBundle):
    """Checks all project ids are consistent with the program."""
    program_id = program_config.programs.value[0].id
    for design in project_config.designs.value:
      self.assertEqual(program_id, design.program_id)
