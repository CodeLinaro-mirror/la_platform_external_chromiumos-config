# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for check_ids."""

import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.common_checks.check_ids import IdConstraintSuite
from chromiumos.config.api.design_config_id_pb2 import DesignConfigId
from chromiumos.config.api.design_id_pb2 import DesignId
from chromiumos.config.api.design_pb2 import Design
from chromiumos.config.api.program_id_pb2 import ProgramId
from chromiumos.config.api.program_pb2 import DesignConfigIdSegment
from chromiumos.config.api.program_pb2 import Program
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


# Alias a few nested classes to make creating test objects less verbose
# pylint: disable=invalid-name
Config = Design.Config
# pylint: enable=invalid-name

# Some tests just check no exceptions were raised, and will not call self.assert
# methods
# pylint: disable=no-self-use


class CheckIdsTest(unittest.TestCase):
    """Tests for check_ids."""

    def test_check_ids_consistent(self):
        """Tests check_ids_consistent with valid configs."""
        program_config = ConfigBundle(
            program_list=[Program(id=ProgramId(value="testprogram1"))]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(program_id=ProgramId(value="testprogram1")),
                Design(program_id=ProgramId(value="testprogram1")),
            ]
        )

        IdConstraintSuite().check_ids_consistent(
            program_config=program_config,
            project_config=project_config,
            factory_dir=None,
        )

    def test_check_ids_consistent_violated(self):
        """Tests check_ids_consistent with invalid configs."""
        program_config = ConfigBundle(
            program_list=[Program(id=ProgramId(value="testprogram1"))]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(program_id=ProgramId(value="testprogram1")),
                Design(program_id=ProgramId(value="testprogram2")),
            ]
        )

        with self.assertRaises(AssertionError):
            IdConstraintSuite().check_ids_consistent(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )

    def test_check_design_config_id_segments(self):
        """Test check_design_config_id_segments with valid configs."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=11,
                            max_id=20,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="b"),
                            min_id=21,
                            max_id=30,
                        ),
                    ]
                )
            ]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(
                    id=DesignId(value="a"),
                    configs=[
                        Config(id=DesignConfigId(value="a:11")),
                        Config(id=DesignConfigId(value="a:15")),
                        Config(id=DesignConfigId(value="a:20")),
                    ],
                ),
                Design(
                    id=DesignId(value="b"),
                    configs=[
                        Config(id=DesignConfigId(value="b:25")),
                        # Unprovisioned ids are exempt from the check.
                        Config(id=DesignConfigId(value="b:2147483647")),
                    ],
                ),
                # Design 'c' doesn't have a segment.
                Design(
                    id=DesignId(value="c"),
                    configs=[
                        Config(id=DesignConfigId(value="c:40")),
                    ],
                ),
            ]
        )

        IdConstraintSuite().check_design_config_id_segments(
            program_config=program_config,
            project_config=project_config,
            factory_dir=None,
        )

    def test_check_design_config_id_segments_violated(self):
        """Test check_design_config_id_segments with ids out of range."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=11,
                            max_id=20,
                        ),
                    ]
                )
            ]
        )

        # Test ids on the lower boundary.
        for id_num in (9, 10):
            project_config = ConfigBundle(
                design_list=[
                    Design(
                        id=DesignId(value="a"),
                        configs=[
                            Config(
                                id=DesignConfigId(value="a:{}".format(id_num))
                            ),
                        ],
                    ),
                ]
            )

            with self.assertRaisesRegex(
                AssertionError,
                "DesignConfigId must be >= 11, got {}".format(id_num),
            ):
                IdConstraintSuite().check_design_config_id_segments(
                    program_config=program_config,
                    project_config=project_config,
                    factory_dir=None,
                )

        # Test ids on the upper boundary.
        for id_num in (21, 22):
            project_config = ConfigBundle(
                design_list=[
                    Design(
                        id=DesignId(value="a"),
                        configs=[
                            Config(
                                id=DesignConfigId(value="a:{}".format(id_num))
                            ),
                        ],
                    ),
                ]
            )

            with self.assertRaisesRegex(
                AssertionError,
                "DesignConfigId must be <= 20, got {}".format(id_num),
            ):
                IdConstraintSuite().check_design_config_id_segments(
                    program_config=program_config,
                    project_config=project_config,
                    factory_dir=None,
                )

    def test_check_design_config_id_segments_overlap(self):
        """Test check_design_config_id_segments_overlap with valid configs."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=11,
                            max_id=20,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="b"),
                            min_id=21,
                            max_id=30,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="c"),
                            min_id=41,
                            max_id=50,
                        ),
                    ]
                )
            ]
        )

        IdConstraintSuite().check_design_config_id_segments_overlap(
            program_config=program_config, project_config=None, factory_dir=None
        )

    def test_check_design_config_id_segments_overlap_violated(self):
        """Test check_design_config_id_segments_overlap with overlapping segments."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=11,
                            max_id=20,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="b"),
                            min_id=20,
                            max_id=30,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="c"),
                            min_id=31,
                            max_id=40,
                        ),
                    ]
                )
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "Segments {} and {} overlap".format(
                program_config.program_list[0].design_config_id_segments[0],
                program_config.program_list[0].design_config_id_segments[1],
            ),
        ):
            IdConstraintSuite().check_design_config_id_segments_overlap(
                program_config=program_config,
                project_config=None,
                factory_dir=None,
            )

        # Segments are declared in a different order.
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=31,
                            max_id=40,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="b"),
                            min_id=20,
                            max_id=30,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="c"),
                            min_id=11,
                            max_id=20,
                        ),
                    ]
                )
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "Segments {} and {} overlap".format(
                program_config.program_list[0].design_config_id_segments[2],
                program_config.program_list[0].design_config_id_segments[1],
            ),
        ):
            IdConstraintSuite().check_design_config_id_segments_overlap(
                program_config=program_config,
                project_config=None,
                factory_dir=None,
            )

        # Two segments have the same min_id.
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_id_segments=[
                        DesignConfigIdSegment(
                            design_id=DesignId(value="b"),
                            min_id=20,
                            max_id=30,
                        ),
                        DesignConfigIdSegment(
                            design_id=DesignId(value="a"),
                            min_id=20,
                            max_id=25,
                        ),
                    ]
                )
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "Segments {} and {} overlap".format(
                program_config.program_list[0].design_config_id_segments[0],
                program_config.program_list[0].design_config_id_segments[1],
            ),
        ):
            IdConstraintSuite().check_design_config_id_segments_overlap(
                program_config=program_config,
                project_config=None,
                factory_dir=None,
            )

    def test_check_design_config_ids_unique(self):
        """Tests check_design_config_ids_unique with valid configs."""
        project_config = ConfigBundle(
            design_list=[
                Design(
                    configs=[
                        Config(id=DesignConfigId(value="a")),
                        Config(id=DesignConfigId(value="b")),
                    ]
                ),
                Design(configs=[Config(id=DesignConfigId(value="c"))]),
            ]
        )

        IdConstraintSuite().check_design_config_ids_unique(
            program_config=None,
            project_config=project_config,
            factory_dir=None,
        )

    def test_check_design_config_ids_unique_violated(self):
        """Tests check_design_config_ids_unique with valid configs."""
        project_config = ConfigBundle(
            design_list=[
                Design(
                    configs=[
                        Config(id=DesignConfigId(value="a")),
                        Config(id=DesignConfigId(value="b")),
                    ]
                ),
                Design(configs=[Config(id=DesignConfigId(value="a"))]),
            ]
        )

        with self.assertRaisesRegex(
            AssertionError, "Found multiple configs with id 'a'"
        ):
            IdConstraintSuite().check_design_config_ids_unique(
                program_config=None,
                project_config=project_config,
                factory_dir=None,
            )
