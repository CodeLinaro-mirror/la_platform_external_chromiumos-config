# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for check_firmware_configuration."""

import unittest

from checker.common_checks.check_firmware_configuration import (
    FirmwareConfigurationConstraintSuite)

from bindings.api.config_bundle_pb2 import ConfigBundle
from bindings.api.design_pb2 import Design, DesignList
from bindings.api.program_pb2 import (Program, ProgramList,
                                      FirmwareConfigurationSegment)
from bindings.api.hardware_topology_pb2 import HardwareTopology
from bindings.api.topology_pb2 import HardwareFeatures, Topology


class CheckFirmwareConfigurationTest(unittest.TestCase):
  """Tests for check_firmware_configuration."""

  def test_check_firmware_configuration_masks(self):
    """Tests check_firmware_configuration_masks with valid configs."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(firmware_configuration_segments=[
                FirmwareConfigurationSegment(name='screen', mask=0b0001),
                FirmwareConfigurationSegment(name='form_factor', mask=0b0110),
            ])
        ]))

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=Topology(
                            type=Topology.SCREEN,
                            hardware_feature=HardwareFeatures(
                                fw_config=HardwareFeatures
                                .FirmwareConfiguration(
                                    value=0b0000,
                                    mask=0b0001,
                                ))),
                        form_factor=Topology(
                            type=Topology.FORM_FACTOR,
                            hardware_feature=HardwareFeatures(
                                fw_config=HardwareFeatures
                                .FirmwareConfiguration(
                                    value=0b0010,
                                    mask=0b0110,
                                ))),
                    ))
            ]),
        ]))

    FirmwareConfigurationConstraintSuite().check_firmware_configuration_masks(
        program_config=program_config, project_config=project_config)

  def test_check_firmware_configuration_masks_overlap(self):
    """Tests check_firmware_configuration_masks with overlapping segments."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(firmware_configuration_segments=[
                FirmwareConfigurationSegment(name='screen', mask=0b0011),
                FirmwareConfigurationSegment(name='form_factor', mask=0b0110),
            ])
        ]))

    with self.assertRaisesRegex(
        AssertionError,
        'Overlap in masks screen and form_factor: 11 & 110 = 10'):
      FirmwareConfigurationConstraintSuite().check_firmware_configuration_masks(
          program_config=program_config, project_config=None)

  def test_check_firmware_configuration_masks_invalid(self):
    """Tests check_firmware_configuration_masks with an invalid mask."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(firmware_configuration_segments=[
                FirmwareConfigurationSegment(name='screen', mask=0b0001),
                FirmwareConfigurationSegment(name='form_factor', mask=0b0110),
            ])
        ]))

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=Topology(
                            type=Topology.SCREEN,
                            hardware_feature=HardwareFeatures(
                                fw_config=HardwareFeatures
                                .FirmwareConfiguration(
                                    value=0b0000,
                                    mask=0b0011,
                                ))),
                        form_factor=Topology(
                            type=Topology.FORM_FACTOR,
                            hardware_feature=HardwareFeatures(
                                fw_config=HardwareFeatures
                                .FirmwareConfiguration(
                                    value=0b0010,
                                    mask=0b0110,
                                ))),
                    ))
            ]),
        ]))

    with self.assertRaisesRegex(AssertionError,
                                'Unexpected mask for topology SCREEN'):
      FirmwareConfigurationConstraintSuite().check_firmware_configuration_masks(
          program_config=program_config, project_config=project_config)
