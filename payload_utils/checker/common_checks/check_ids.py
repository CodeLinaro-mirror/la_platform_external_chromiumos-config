# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Constraint checks related to program and project ids."""

import itertools

from checker import constraint_suite
from checker import config_bundle_utils

from chromiumos.config.payload import config_bundle_pb2


class IdConstraintSuite(constraint_suite.ConstraintSuite):
  """Constraint checks related to program and project ids."""

  def check_ids_consistent(self, program_config: config_bundle_pb2.ConfigBundle,
                           project_config: config_bundle_pb2.ConfigBundle):
    """Checks all project ids are consistent with the program."""
    program_id = program_config.programs.value[0].id
    for design in project_config.designs.value:
      self.assertEqual(program_id, design.program_id)

  def check_design_config_id_segments(
      self, program_config: config_bundle_pb2.ConfigBundle,
      project_config: config_bundle_pb2.ConfigBundle):
    """Check that all DesignConfigIds fall within their segment."""
    program = config_bundle_utils.get_program(program_config)
    segment_map = {
        s.design_id.value: s for s in program.design_config_id_segments
    }

    for design in project_config.designs.value:
      # It is valid for designs to not have a corresponding segment.
      segment = segment_map.get(design.id.value)
      if not segment:
        continue

      self.assertLess(segment.min_id, segment.max_id)

      for config in design.configs:
        # DesignConfigIds should have the form "<name>:<id>"
        _, id_num = config.id.value.split(':')
        id_num = int(id_num)

        # Unprovisioned config ids are exempt from the check.
        if id_num == 0x7FFFFFFF:
          continue

        self.assertGreaterEqual(
            id_num, segment.min_id,
            'DesignConfigId must be >= {}, got {}'.format(
                segment.min_id, id_num))
        self.assertLessEqual(
            id_num, segment.max_id,
            'DesignConfigId must be <= {}, got {}'.format(
                segment.max_id, id_num))

  def check_design_config_id_segments_overlap(
      self, program_config: config_bundle_pb2.ConfigBundle,
      project_config: config_bundle_pb2.ConfigBundle):
    """Check that no DesignConfigIdSegments overlap."""
    del project_config

    program = config_bundle_utils.get_program(program_config)

    # Get all pairs as permutations, so we can assume that one segment is lower
    # than the other.
    for seg_a, seg_b in itertools.permutations(
        program.design_config_id_segments, 2):
      error_message = 'Segments {} and {} overlap'.format(seg_a, seg_b)

      # Segment min_ids can never be equal.
      self.assertNotEqual(seg_a.min_id, seg_b.min_id, error_message)

      # Only check the case where a's min_id is lower than b's min_id; the other
      # case will be checked by the opposite permutation.
      if seg_a.min_id < seg_b.min_id:
        # If a's min_id is lower than b's, a's max id must be lower than b's
        # min_id.
        self.assertLess(seg_a.max_id, seg_b.min_id, error_message)
