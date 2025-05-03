# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to form factors."""

import pathlib
from typing import Iterable

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.api import design_pb2
from chromiumos.config.api import program_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2


def get_form_factor_constraints(
    program: program_pb2.Program,
) -> Iterable[design_pb2.Design.Config.Constraint]:
    """Returns all Constraints on FormFactor."""
    return [
        c
        for c in program.design_config_constraints
        if c.features.form_factor.form_factor
    ]


class FormFactorConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related to form factors."""

    def check_form_factor(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks a project uses a form factor allowed by a program."""
        del factory_dir

        # Alias the FormFactor.Name fn. to increase readability. This fn. is
        # used to produce human-readable error messages.
        form_factor_name = (
            topology_pb2.HardwareFeatures.FormFactor.FormFactorType.Name
        )

        form_factor_constraints = {}
        for program in program_config.program_list:
            allowed_form_factors = []
            for constraint in get_form_factor_constraints(program):
                allowed_form_factors.append(
                    form_factor_name(
                        constraint.features.form_factor.form_factor
                    )
                )
            form_factor_constraints[program.id.value] = allowed_form_factors

        for design in project_config.design_list:
            allowed_form_factors = form_factor_constraints[
                design.program_id.value
            ]
            for config in design.configs:
                self.assertIn(
                    form_factor_name(
                        config.hardware_features.form_factor.form_factor
                    ),
                    allowed_form_factors,
                )

    def check_form_factor_required(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks all form factor constraints are REQUIRED."""
        del project_config, factory_dir

        for program in program_config.program_list:
            for constraint in program.design_config_constraints:
                self.assertEqual(
                    constraint.level,
                    design_pb2.Design.Config.Constraint.REQUIRED,
                    "FormFactor constraints must be REQUIRED.",
                )
