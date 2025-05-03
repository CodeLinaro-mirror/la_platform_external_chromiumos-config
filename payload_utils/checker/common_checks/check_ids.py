# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to program and project ids.

A note on how some of the checks relate:

- check_design_config_id_segments: Checks that a project's ids fall within the
segment specified in the program config.
- check_design_config_id_segments_overlap: Checks that no id segments overlap.
- check_design_config_ids_unique: Checks that ids within a project are unique.

Together, these constraints enforce uniqueness across a program. If two ids
within a project are the same, this is rejected by
check_design_config_ids_unique. If two ids in different projects are the same,
at least one of them must be out of the specified segment, because no two
segments can overlap.
"""

import itertools
import logging
import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.payload import config_bundle_pb2


class IdConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related to program and project ids."""

    def check_ids_consistent(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks all project ids are consistent with the program."""
        del factory_dir
        program_ids = [
            program.id.value for program in program_config.program_list
        ]
        for design in project_config.design_list:
            self.assertIn(design.program_id.value, program_ids)

    def check_design_config_id_segments(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Check that all DesignConfigIds fall within their segment."""
        del factory_dir
        segment_map = {}
        for program in program_config.program_list:
            for segment in program.design_config_id_segments:
                segment_map[segment.design_id.value] = segment

        for design in project_config.design_list:
            # It is valid for designs to not have a corresponding segment.
            segment = segment_map.get(design.id.value)
            if not segment:
                logging.warning(
                    "No DesignConfigIdSegment found for design %s, constraints "
                    "on ids will not be enforced",
                    design.id.value,
                )
                continue

            self.assertLess(segment.min_id, segment.max_id)

            for config in design.configs:
                # DesignConfigIds should have the form "<name>:<id>"
                _, id_num = config.id.value.split(":")
                id_num = int(id_num)

                # Unprovisioned config ids are exempt from the check.
                if id_num == 0x7FFFFFFF:
                    continue

                self.assertGreaterEqual(
                    id_num,
                    segment.min_id,
                    "DesignConfigId must be >= {}, got {}".format(
                        segment.min_id, id_num
                    ),
                )
                self.assertLessEqual(
                    id_num,
                    segment.max_id,
                    "DesignConfigId must be <= {}, got {}".format(
                        segment.max_id, id_num
                    ),
                )

    def check_design_config_id_segments_overlap(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Check that no DesignConfigIdSegments overlap."""
        del project_config, factory_dir
        programs = program_config.program_list
        # Flatten design config ID segments across programs
        design_config_id_segments = itertools.chain.from_iterable(
            program.design_config_id_segments for program in programs
        )
        # Get all pairs as permutations, so we can assume that one segment is
        # lower than the other.
        for seg_a, seg_b in itertools.permutations(
            design_config_id_segments, 2
        ):
            error_message = "Segments {} and {} overlap".format(seg_a, seg_b)

            # Segment min_ids can never be equal.
            self.assertNotEqual(seg_a.min_id, seg_b.min_id, error_message)

            # Only check the case where a's min_id is lower than b's min_id; the
            # other case will be checked by the opposite permutation.
            if seg_a.min_id < seg_b.min_id:
                # If a's min_id is lower than b's, a's max id must be lower than
                # b's min_id.
                self.assertLess(seg_a.max_id, seg_b.min_id, error_message)

    def check_design_config_ids_unique(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks all project DesignConfigIds are unique."""
        del program_config, factory_dir

        design_config_ids = set()
        for design in project_config.design_list:
            for config in design.configs:
                self.assertNotIn(
                    config.id.value,
                    design_config_ids,
                    "Found multiple configs with id '{}'".format(
                        config.id.value
                    ),
                )
                design_config_ids.add(config.id.value)
