# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Constraint checks related to firmware configuration."""

import itertools

from checker import constraint_suite
from checker import proto_utils

from bindings.api import config_bundle_pb2
from bindings.api import topology_pb2


class FirmwareConfigurationConstraintSuite(constraint_suite.ConstraintSuite):
  """Constraint checks related to firmware configuration."""

  def check_firmware_configuration_masks(
      self, program_config: config_bundle_pb2.ConfigBundle,
      project_config: config_bundle_pb2.ConfigBundle):
    """Checks firmware configuration masks are valid.

    1. Check that the FirmwareConfigurationSegments defined in the program do
    not overlap.
    2. Check that each mask defined in a FirmwareConfiguration aligns with a
    segment.
    """
    if len(program_config.programs.value) != 1:
      raise NotImplementedError('Expect exactly 1 program')

    segments = program_config.programs.value[0].firmware_configuration_segments
    # Collect all masks defined by segments.
    masks = set()

    for segment_a, segment_b in itertools.combinations(segments, 2):
      overlap = segment_a.mask & segment_b.mask
      self.assertFalse(
          overlap,
          msg='Overlap in masks {} and {}: {:b} & {:b} = {:b}'.format(
              segment_a.name, segment_b.name, segment_a.mask, segment_b.mask,
              overlap))

      masks.add(segment_a.mask)
      masks.add(segment_b.mask)

    # For every topology that defines a FirmwareConfiguration, check the mask
    # aligns with a segment.
    for design in project_config.designs.value:
      for config in design.configs:
        for topology in proto_utils.get_all_fields(config.hardware_topology):
          mask = topology.hardware_feature.fw_config.mask
          if mask:
            self.assertIn(
                mask, masks, 'Unexpected mask for topology {}'.format(
                    topology_pb2.Topology.Type.Name(topology.type)))
