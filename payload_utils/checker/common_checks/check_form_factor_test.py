# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for check_form_factor."""

import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.common_checks.check_form_factor import FormFactorConstraintSuite
from chromiumos.config.api.design_pb2 import Design
from chromiumos.config.api.program_pb2 import Program
from chromiumos.config.api.topology_pb2 import HardwareFeatures
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


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

# Some tests just check no exceptions were raised, and will not call self.assert
# methods
# pylint: disable=no-self-use


class CheckFormFactorTest(unittest.TestCase):
    """Tests for check_form_factor."""

    def test_check_form_factor(self):
        """Tests check_form_factor with valid configs."""
        # The program allows CLAMSHELL and CONVERTIBLE.
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_constraints=[
                        Constraint(
                            level=Constraint.REQUIRED,
                            features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            ),
                        ),
                        Constraint(
                            level=Constraint.REQUIRED,
                            features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CONVERTIBLE)
                            ),
                        ),
                        # Test adding other Constraints.
                        Constraint(
                            level=Constraint.REQUIRED,
                            features=HardwareFeatures(
                                screen=Screen(
                                    touch_support=HardwareFeatures.Present.PRESENT
                                )
                            ),
                        ),
                    ]
                )
            ]
        )

        # Project has two CLAMSHELL and one CONVERTIBLE
        project_config = ConfigBundle(
            design_list=[
                Design(
                    configs=[
                        Config(
                            hardware_features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            )
                        ),
                        Config(
                            hardware_features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            )
                        ),
                        Config(
                            hardware_features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CONVERTIBLE)
                            )
                        ),
                    ]
                )
            ]
        )

        FormFactorConstraintSuite().check_form_factor(
            program_config=program_config,
            project_config=project_config,
            factory_dir=None,
        )

    def test_check_form_factor_invalid(self):
        """Tests check_form_factor with invalid configs."""
        # The program allows CLAMSHELL and CONVERTIBLE.
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_constraints=[
                        Constraint(
                            level=Constraint.REQUIRED,
                            features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            ),
                        ),
                        Constraint(
                            level=Constraint.REQUIRED,
                            features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CONVERTIBLE)
                            ),
                        ),
                    ]
                )
            ]
        )

        # DETACHABLE is not allowed.
        project_config = ConfigBundle(
            design_list=[
                Design(
                    configs=[
                        Config(
                            hardware_features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            )
                        ),
                        Config(
                            hardware_features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=DETACHABLE)
                            )
                        ),
                    ]
                )
            ]
        )
        with self.assertRaisesRegex(
            AssertionError,
            r".*'DETACHABLE' not found in \['CLAMSHELL', 'CONVERTIBLE'\]",
        ):
            FormFactorConstraintSuite().check_form_factor(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )

    def test_check_form_factor_non_required_constraint(self):
        """Tests check_form_factor with a non-REQUIRED FormFactor Constraint."""
        program_config = ConfigBundle(
            program_list=[
                Program(
                    design_config_constraints=[
                        Constraint(
                            level=Constraint.OPTIONAL,
                            features=HardwareFeatures(
                                form_factor=FormFactor(form_factor=CLAMSHELL)
                            ),
                        ),
                    ]
                )
            ]
        )

        with self.assertRaisesRegex(
            AssertionError, "FormFactor constraints must be REQUIRED."
        ):
            FormFactorConstraintSuite().check_form_factor_required(
                program_config=program_config,
                project_config=None,
                factory_dir=None,
            )
