# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for check_form_factor."""

import unittest

from checker.common_checks.check_form_factor import FormFactorConstraintSuite

from config.payload.config_bundle_pb2 import ConfigBundle
from config.api.design_pb2 import Design, DesignList
from config.api.program_pb2 import Program, ProgramList
from config.api.topology_pb2 import HardwareFeatures

# Alias a few nested classes to make creating test objects less verbose
# pylint: disable=invalid-name
Constraint = Design.Config.Constraint
FormFactor = HardwareFeatures.FormFactor
Screen = HardwareFeatures.Screen
Config = Design.Config
# pylint: enable=invalid-name
CLAMSHELL = HardwareFeatures.FormFactor.FormFactorType.CLAMSHELL
CONVERTIBLE = HardwareFeatures.FormFactor.FormFactorType.CONVERTIBLE
DETACHABLE = HardwareFeatures.FormFactor.FormFactorType.DETACHABLE


class CheckFormFactorTest(unittest.TestCase):
  """Tests for check_form_factor."""

  def test_check_form_factor(self):
    """Tests check_form_factor with valid configs."""
    # The program allows CLAMSHELL and CONVERTIBLE.
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(design_config_constraints=[
                Constraint(
                    level=Constraint.REQUIRED,
                    features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
                Constraint(
                    level=Constraint.REQUIRED,
                    features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CONVERTIBLE))),
                # Test adding other Constraints.
                Constraint(
                    level=Constraint.REQUIRED,
                    features=HardwareFeatures(
                        screen=Screen(
                            touch_support=HardwareFeatures.Present.PRESENT))),
            ])
        ]))

    # Project has two CLAMSHELL and one CONVERTIBLE
    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Config(
                    hardware_features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
                Config(
                    hardware_features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
                Config(
                    hardware_features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CONVERTIBLE)))
            ])
        ]))

    FormFactorConstraintSuite().check_form_factor(
        program_config=program_config, project_config=project_config)

  def test_check_form_factor_invalid(self):
    """Tests check_form_factor with invalid configs."""
    # The program allows CLAMSHELL and CONVERTIBLE.
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(design_config_constraints=[
                Constraint(
                    level=Constraint.REQUIRED,
                    features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
                Constraint(
                    level=Constraint.REQUIRED,
                    features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CONVERTIBLE))),
            ])
        ]))

    # DETACHABLE is not allowed.
    project_config = ConfigBundle(
        designs=DesignList(value=[
            Design(configs=[
                Config(
                    hardware_features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
                Config(
                    hardware_features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=DETACHABLE))),
            ])
        ]))
    with self.assertRaisesRegex(
        AssertionError,
        r".*'DETACHABLE' not found in \['CLAMSHELL', 'CONVERTIBLE'\]"):
      FormFactorConstraintSuite().check_form_factor(
          program_config=program_config, project_config=project_config)

  def test_check_form_factor_non_required_constraint(self):
    """Tests check_form_factor with a non-REQUIRED FormFactor Constraint."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[
            Program(design_config_constraints=[
                Constraint(
                    level=Constraint.OPTIONAL,
                    features=HardwareFeatures(
                        form_factor=FormFactor(form_factor=CLAMSHELL))),
            ])
        ]))

    with self.assertRaisesRegex(AssertionError,
                                'FormFactor constraints must be REQUIRED.'):
      FormFactorConstraintSuite().check_form_factor_required(
          program_config=program_config, project_config=None)
