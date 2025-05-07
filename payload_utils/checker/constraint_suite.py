# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines ConstraintSuite, which is subclassed to define constraints."""

import inspect
import pathlib
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from chromiumos.config.payload import config_bundle_pb2


class InvalidConstraintSuiteError(Exception):
    """Exception raised when an invalid ConstraintSuite is defined."""


class ConstraintSuite:
    """A class whose instances are suites of constraints.

    Constraint authors should subclass ConstraintSuite and add methods starting
    with "check" for each constraint they want to enforce. Each check method
    should accept two ConfigBundles, with parameter names "project_config" and
    "program_config", and a path to the project's "factory" dir, with
    parameter name "factory_dir". A check method is considered failed iff
    it raises an Exception.

    Assertion methods similar to those on unittest.TestCase are available, e.g.
    "assertEqual". See DELEGATED_ASSERTIONS attribute for full list of assertion
    methods.

    A ConstraintSuite subclass should group related constraints. For example a
    suite to check form factor constraints could look like:

    class FormFactorConstraintSuite(ConstraintSuite):

      def checkFormFactorDefined(
        self, program_config, project_config, factory_dir
      ):
        ...

      def checkFormFactorAllowedByProgram(
        self, program_config, project_config, factory_dir
      ):
        ...
    """

    DELEGATED_ASSERTIONS = [
        "assertEqual",
        "assertNotEqual",
        "assertTrue",
        "assertFalse",
        "assertIn",
        "assertNotIn",
        "assertGreaterEqual",
        "assertLessEqual",
        "assertLess",
    ]

    def __add_delegated_assertions(self):
        """Adds assertion methods to self.

        Assertion methods just call corresponding method on unittest.TestCase.
        """
        for assertion_name in self.DELEGATED_ASSERTIONS:
            assertion = getattr(unittest.TestCase(), assertion_name)
            setattr(self, assertion_name, assertion)

    def __init__(self):
        super().__init__()

        def is_check(name, value):
            return name.startswith("check") and inspect.ismethod(value)

        self._checks = [
            value
            for name, value in inspect.getmembers(self)
            if is_check(name, value)
        ]

        self.__add_delegated_assertions()

    def run_checks(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
        verbose: int = 0,
    ):
        """Runs all of the checks on an instance.

        Args:
            program_config: The program's config, to pass to each check.
            project_config: The project's config, to pass to each check.
            factory_dir: Path to the project's factory dir, to pass to
                each check.
            verbose: Verbosity mode, 0: silent, >= 1: print name of check.
        """
        for method in self._checks:
            if verbose:
                # TODO(b/187699547): Improve logging and failure reporting.
                print(
                    "Running {}.{}".format(
                        self.__class__.__name__, method.__name__
                    )
                )
            method(
                program_config=program_config,
                project_config=project_config,
                factory_dir=factory_dir,
            )
