# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for constraint_suite."""

import os
import pathlib
import tempfile
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.constraint_suite import ConstraintSuite
from chromiumos.config.api.design_pb2 import Design
from chromiumos.config.api.program_pb2 import Program
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


# Some tests just check no exceptions were raised, and will not call self.assert
# methods
# pylint: disable=no-self-use


class ValidConstraintSuite(ConstraintSuite):
    """A valid constraint suite for testing, that defines two checks."""

    # pylint: disable=missing-docstring

    def _helper_method(self):
        assert False, "helper_method should never be called"

    def check_program_valid(
        self,
        program_config,
        project_config,
        factory_dir,
    ):
        del project_config, factory_dir
        self.assertEqual(program_config.program_list[0].name, "TestProgram1")

    def check_project_valid(
        self,
        program_config,
        project_config,
        factory_dir,
    ):
        del program_config, factory_dir
        self.assertEqual(project_config.design_list[0].name, "TestDesign1")


class FactoryDirSuite(ConstraintSuite):
    """A valid constraint suite for testing that expects a file in factory_dir."""

    # pylint: disable=missing-docstring

    def check_generated_config_present(
        self,
        program_config,
        project_config,
        factory_dir,
    ):
        del program_config, project_config
        self.assertTrue(os.path.exists(os.path.join(factory_dir, "test.txt")))


class InvalidConstraintSuite(ConstraintSuite):
    """An invalid constraint suite for testing, that defines no checks."""

    # pylint: disable=missing-docstring

    def helper_method1(self):
        pass

    def helper_method2(self):
        pass


class ConstraintSuiteTest(unittest.TestCase):
    """Tests for constraint_suite."""

    def test_runs_checks(self):
        """Tests running checks on a project that fulfills constraints."""
        program_config = ConfigBundle(
            program_list=[Program(name="TestProgram1")]
        )
        project_config = ConfigBundle(design_list=[Design(name="TestDesign1")])

        ValidConstraintSuite().run_checks(
            program_config=program_config,
            project_config=project_config,
            factory_dir=None,
        )

    def test_runs_checks_fails_constraint(self):
        """Tests running checks on a project that violates constraints."""
        program_config = ConfigBundle(
            program_list=[Program(name="TestProgram2")]
        )
        project_config = ConfigBundle(design_list=[Design(name="TestDesign1")])

        with self.assertRaisesRegex(
            AssertionError, "'TestProgram2' != 'TestProgram1'"
        ):
            ValidConstraintSuite().run_checks(
                program_config=program_config,
                project_config=project_config,
                factory_dir=None,
            )

    def test_checks_factory_dir(self):
        """Tests running checks that a file in factory_dir is present."""

        with tempfile.TemporaryDirectory() as tmpdir:
            with open(
                os.path.join(tmpdir, "test.txt"), "w", encoding="utf-8"
            ) as fp:
                fp.write("test file\n")

            FactoryDirSuite().run_checks(
                program_config=None,
                project_config=None,
                factory_dir=pathlib.Path(tmpdir),
            )

    def test_checks_factory_dir_violated(self):
        """Tests running checks that fail because a file in factory_dir is
        not present.
        """

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(AssertionError):
                FactoryDirSuite().run_checks(
                    program_config=None,
                    project_config=None,
                    factory_dir=pathlib.Path(tmpdir),
                )

    def test_has_delegated_assertions(self):
        """Tests that ConstraintSuites have assertion methods."""
        constraint_suite = ValidConstraintSuite()
        self.assertTrue(hasattr(constraint_suite, "assertTrue"))
        with self.assertRaisesRegex(AssertionError, "1 != 2"):
            constraint_suite.assertEqual(1, 2)
