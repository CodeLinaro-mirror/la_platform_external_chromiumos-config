# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to Second Source Factory Cache (SSFC)."""

import itertools
import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.payload import config_bundle_pb2


class SecondSourceFactoryCacheConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related to Second Source Factory Cache (SSFC)."""

    def check_ssfc_masks(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks SSFC masks are valid.

        1. Check that the FirmwareConfigurationSegments defined in the program
            do not overlap.
        2. Check that each SSFC value is not 0.
        3. Check that each SSFC value within a project aligns with a segment.
        """
        del factory_dir

        for program in program_config.program_list:
            segments = program.ssfc_segments

            for segment_a, segment_b in itertools.combinations(segments, 2):
                overlap = segment_a.mask & segment_b.mask
                self.assertEqual(
                    overlap,
                    0,
                    msg="Overlap in masks {} and {}: {:b} & {:b} = {:b}".format(
                        segment_a.name,
                        segment_b.name,
                        segment_a.mask,
                        segment_b.mask,
                        overlap,
                    ),
                )

            # For every SSFC value within a project design, check the value
            # aligns with a segment.
            for design in project_config.design_list:

                if design.program_id.value != program.id.value:
                    continue

                for value, name in design.ssfc_value.items():

                    self.assertNotEqual(
                        value,
                        0,
                        "SSFC value {} cannot have a value of 0".format(name),
                    )

                    match_found = False
                    for seg in segments:
                        overlap = value & seg.mask
                        # Must be another SSFC segment
                        if overlap == 0:
                            continue

                        match_found = True

                        self.assertEqual(
                            overlap,
                            value,
                            "SSFC value {} = 0x{:08x} does not align with SSFC "
                            "Segment {} 0x{:08X}".format(
                                name, value, seg.name, seg.mask
                            ),
                        )

                    # After looping through all valid SSFC segments, ensure it
                    # was found.
                    self.assertTrue(
                        match_found,
                        "SSFC {} = 0x{:08x} does not belong to a SSFC segment. "
                        "Please define a new segment at the program "
                        "level.".format(name, value),
                    )
