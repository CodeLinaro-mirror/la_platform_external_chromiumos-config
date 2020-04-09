# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for check_firmware_configuration."""

import unittest

from checker.common_checks.check_firmware_configuration import (
    FirmwareConfigurationConstraintSuite)

from config.payload.config_bundle_pb2 import ConfigBundle
from config.api.design_pb2 import Design, DesignList
from config.api.program_pb2 import (Program, ProgramList,
                                      FirmwareConfigurationSegment)
from config.api.hardware_topology_pb2 import HardwareTopology
from config.api.topology_pb2 import HardwareFeatures, Topology

# Alias a few nested classes to make creating test objects less verbose
# pylint: disable=invalid-name
FirmwareConfiguration = HardwareFeatures.FirmwareConfiguration
Config = Design.Config
# pylint: enable=invalid-name


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
                Config(
                    hardware_topology=HardwareTopology(
                        screen=Topology(
                            type=Topology.SCREEN,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(
                                    value=0b0000,
                                    mask=0b0001,
                                ))),
                        form_factor=Topology(
                            type=Topology.FORM_FACTOR,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(
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
                Config(
                    hardware_topology=HardwareTopology(
                        screen=Topology(
                            type=Topology.SCREEN,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(
                                    value=0b0000,
                                    mask=0b0011,
                                ))),
                        form_factor=Topology(
                            type=Topology.FORM_FACTOR,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(
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

  def test_check_firmware_value_collision(self):
    """Tests check_firmware_value_collision on a valid config."""
    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Config(
                    hardware_topology=HardwareTopology(
                        # ('screen1', SCREEN) topology uses fw value 0b0001.
                        screen=Topology(
                            id='screen1',
                            type=Topology.SCREEN,
                            description={'EN': 'First description'},
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(value=0b0001))),
                        # ('ff1', FORM_FACTOR) topology doesn't specify a fw
                        # value.
                        form_factor=Topology(
                            id='ff1',
                            type=Topology.FORM_FACTOR,
                        ),
                    )),
                Config(
                    hardware_topology=HardwareTopology(
                        # ('screen1', SCREEN) topology is used in a different
                        # design, again using fw value 0b0001. This is valid,
                        # because the topology has the same id and type. Note
                        # that the description is allowed to be different.
                        screen=Topology(
                            id='screen1',
                            type=Topology.SCREEN,
                            description={
                                'EN': 'Slightly different description'
                            },
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(
                                    value=0b0001))),),),
            ]),
        ]))

    FirmwareConfigurationConstraintSuite(
    ).check_firmware_configuration_value_collision(
        program_config=None, project_config=project_config)

  def test_check_firmware_value_collision_invalid_config(self):
    """Tests check_firmware_value_collision on an invalid config."""
    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Config(
                    hardware_topology=HardwareTopology(
                        # Both ('screen1', SCREEN) and ('thermal1', THERMAL) use
                        # fw value 0b0001.
                        screen=Topology(
                            id='screen1',
                            type=Topology.SCREEN,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(value=0b0001))),
                        thermal=Topology(
                            id='thermal1',
                            type=Topology.THERMAL,
                            hardware_feature=HardwareFeatures(
                                fw_config=FirmwareConfiguration(value=0b0001))),
                    )),
            ]),
        ]))

    with self.assertRaisesRegex(
        AssertionError,
        (r'Topologies \(thermal1, THERMAL\) and \(screen1, SCREEN\) both use '
         r'firmware value 1')):
      FirmwareConfigurationConstraintSuite(
      ).check_firmware_configuration_value_collision(
          program_config=None, project_config=project_config)
