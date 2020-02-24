# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for check_topology."""

import unittest

from checker.common_checks.check_topology import TopologyConstraintSuite

from bindings.api.config_bundle_pb2 import ConfigBundle
from bindings.api.design_pb2 import Design, DesignList
from bindings.api.hardware_topology_pb2 import HardwareTopology
from bindings.api.topology_pb2 import (HardwareFeatures,
                                                        Topology)


class CheckIdsTest(unittest.TestCase):
  """Tests for check_topology."""

  def setUp(self):
    """Creates objects to be shared between tests."""
    self.screen_1_topology = Topology(
        id="part1",
        type=Topology.SCREEN,
        description={'EN': 'The first type of screen.'},
        hardware_feature=HardwareFeatures(
            screen=HardwareFeatures.Screen(
                milliinch=HardwareFeatures.Count(value=10))),
    )

    self.screen_2_topology = Topology(
        id="part2",
        type=Topology.SCREEN,
        description={'EN': 'The second type of screen.'},
        hardware_feature=HardwareFeatures(
            screen=HardwareFeatures.Screen(
                milliinch=HardwareFeatures.Count(value=20))),
    )

    self.keyboard_1_topology = Topology(
        id="part1",
        type=Topology.KEYBOARD,
        description={'EN': 'The first type of keyboard.'},
        hardware_feature=HardwareFeatures(
            keyboard=HardwareFeatures.Keyboard(
                backlight=HardwareFeatures.PRESENT)),
    )

  def test_check_topologies_consistent(self):
    """Tests no assertions thrown when topologies are consistent."""
    # Screen topologies differ in id and type between configs. The same keyboard
    # topology is used by both configs (the entire message, including id and
    # type match).
    #
    # Note that screen_1_topology and keyboard_1_topology share the same id
    # ("part1"), but are a different type, so do not violate the constraint.
    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=self.screen_1_topology,
                        keyboard=self.keyboard_1_topology)),
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=self.screen_2_topology,
                        keyboard=self.keyboard_1_topology))
            ])
        ]))

    TopologyConstraintSuite().run_checks(
        program_config=None, project_config=project_config)

  def test_check_topologies_consistent_violated(self):
    """Tests assertion thrown when topologies are inconsistent."""
    # Create a copy of the first screen topology, but change the milliinch
    # value. Now, a given id and type maps to two different messages.
    invalid_screen_topology = Topology()
    invalid_screen_topology.CopyFrom(self.screen_1_topology)
    invalid_screen_topology.hardware_feature.screen.milliinch.value = 20

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=self.screen_1_topology,
                        keyboard=self.keyboard_1_topology)),
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=invalid_screen_topology,
                        keyboard=self.keyboard_1_topology))
            ])
        ]))

    with self.assertRaisesRegex(
        AssertionError,
        r'Two different messages found for id and type \(part1, SCREEN\)*'):
      TopologyConstraintSuite().run_checks(
          program_config=None, project_config=project_config)

  def test_check_topologies_consistent_violated_across_designs(self):
    """Tests assertion thrown when topologies are inconsistent across designs.
    """
    # Create a copy of the first screen topology, but change the milliinch
    # value. Now, a given id and type maps to two different messages.
    invalid_screen_topology = Topology()
    invalid_screen_topology.CopyFrom(self.screen_1_topology)
    invalid_screen_topology.hardware_feature.screen.milliinch.value = 20

    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=self.screen_1_topology,
                        keyboard=self.keyboard_1_topology)),
            ]),
            Design(configs=[
                Design.Config(
                    hardware_topology=HardwareTopology(
                        screen=invalid_screen_topology,
                        keyboard=self.keyboard_1_topology))
            ])
        ]))

    with self.assertRaisesRegex(
        AssertionError,
        r'Two different messages found for id and type \(part1, SCREEN\)*'):
      TopologyConstraintSuite().run_checks(
          program_config=None, project_config=project_config)
