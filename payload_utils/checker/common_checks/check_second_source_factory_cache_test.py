# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for check_second_source_factory_cache."""

import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.common_checks.check_second_source_factory_cache import (
    SecondSourceFactoryCacheConstraintSuite,
)
from chromiumos.config.api.design_pb2 import Design
from chromiumos.config.api.program_pb2 import FirmwareConfigurationSegment
from chromiumos.config.api.program_pb2 import Program
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


# Some tests just check no exceptions were raised, and will not call self.assert
# methods
# pylint: disable=no-self-use


class CheckSecondSourceFactoryCacheTest(unittest.TestCase):
    """Tests for check_second_source_factory_cache."""

    def test_check_second_source_factory_cache_masks(self):
        """Tests check_second_source_factory_cache_masks with valid configs."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    ssfc_segments=[
                        FirmwareConfigurationSegment(
                            name="camera", mask=0b0011
                        ),
                        FirmwareConfigurationSegment(
                            name="sensor", mask=0b1100
                        ),
                    ]
                )
            ]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(
                    ssfc_value={
                        0b0001: "CameraA",
                        0b0011: "CameraC",
                        0b0100: "SensorA",
                        0b1000: "SensorB",
                    }
                ),
            ]
        )

        SecondSourceFactoryCacheConstraintSuite().check_ssfc_masks(
            program_config=program_config,
            project_config=project_config,
            factory_dir=None,
        )

    def test_check_second_source_factory_cache_masks_non_zero(self):
        """Tests check_second_source_factory_cache_masks with 0-valued SSFC vals."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    ssfc_segments=[
                        FirmwareConfigurationSegment(
                            name="camera", mask=0b0011
                        ),
                        FirmwareConfigurationSegment(
                            name="sensor", mask=0b1100
                        ),
                    ]
                )
            ]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(
                    ssfc_value={
                        0b0001: "CameraA",
                        0b0000: "CameraZ",
                        0b0100: "SensorA",
                        0b1000: "SensorB",
                    }
                ),
            ]
        )

        with self.assertRaisesRegex(
            AssertionError, "SSFC value CameraZ cannot have a value of 0"
        ):
            SecondSourceFactoryCacheConstraintSuite().check_ssfc_masks(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )

    def test_check_second_source_factory_cache_overlapping(self):
        """Tests check_second_source_factory_cache_masks overlapping segments."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    ssfc_segments=[
                        FirmwareConfigurationSegment(
                            name="camera", mask=0b0011
                        ),
                        FirmwareConfigurationSegment(
                            name="sensor", mask=0b1110
                        ),
                    ]
                )
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "2 != 0 : Overlap in masks camera and sensor: 11 & 1110 = 10",
        ):
            SecondSourceFactoryCacheConstraintSuite().check_ssfc_masks(
                program_config=program_config,
                project_config=None,
                factory_dir=None,
            )

    def test_check_second_source_factory_cache_misalign(self):
        """Tests check_second_source_factory_cache_masks with misaligned values."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    ssfc_segments=[
                        FirmwareConfigurationSegment(
                            name="camera", mask=0b0011
                        ),
                        FirmwareConfigurationSegment(
                            name="sensor", mask=0b1100
                        ),
                    ]
                )
            ]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(
                    ssfc_value={
                        0b0001: "CameraA",
                        0b0011: "CameraC",
                        0b1110: "SensorA",
                    }
                ),
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "2 != 14 : SSFC value SensorA = 0x0000000e does not align with "
            "SSFC Segment camera 0x00000003",
        ):
            SecondSourceFactoryCacheConstraintSuite().check_ssfc_masks(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )

    def test_check_second_source_factory_cache_undef_segment(self):
        """Tests check_second_source_factory_cache_masks undefined segments."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    ssfc_segments=[
                        FirmwareConfigurationSegment(
                            name="camera", mask=0b0011
                        ),
                    ]
                )
            ]
        )

        project_config = ConfigBundle(
            design_list=[
                Design(
                    ssfc_value={
                        0b0001: "CameraA",
                        0b0011: "CameraC",
                        0b1100: "SensorA",
                    }
                ),
            ]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "False is not true : SSFC SensorA = 0x0000000c does not belong to "
            "a SSFC segment. Please define a new segment at the program level.",
        ):
            SecondSourceFactoryCacheConstraintSuite().check_ssfc_masks(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )
