# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for check_default_components."""

import pathlib
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.common_checks.check_default_components import (
    DefaultComponentConstraintSuite,
)
from chromiumos.config.payload import config_bundle_pb2


class TestDefaultComponentConstraintSuite(unittest.TestCase):
    """Tests for DefaultComponentConstraintSuite."""

    def setUp(self):
        self.temp_dir = pathlib.Path("/tmp")  # Not used by the check itself

    def test_check_no_defaults(self):
        """Tests check passes when no defaults are set."""
        project_config = config_bundle_pb2.ConfigBundle()
        hal_config = project_config.android_hal_config

        # Add some components, none default
        fp1 = hal_config.fingerprint_list.add()
        fp1.id = "fp1"
        fp2 = hal_config.fingerprint_list.add()
        fp2.id = "fp2"

        suite = DefaultComponentConstraintSuite()
        suite.check_single_default_per_type(
            program_config=config_bundle_pb2.ConfigBundle(),
            project_config=project_config,
            factory_dir=self.temp_dir,
        )

    def test_check_one_default(self):
        """Tests check passes when exactly one default is set."""
        project_config = config_bundle_pb2.ConfigBundle()
        hal_config = project_config.android_hal_config

        fp1 = hal_config.fingerprint_list.add()
        fp1.id = "fp1"
        fp1.default = True
        fp2 = hal_config.fingerprint_list.add()
        fp2.id = "fp2"

        suite = DefaultComponentConstraintSuite()
        suite.check_single_default_per_type(
            program_config=config_bundle_pb2.ConfigBundle(),
            project_config=project_config,
            factory_dir=self.temp_dir,
        )

    def test_check_multiple_defaults_fail(self):
        """Tests check fails when multiple defaults are set for the same type."""
        project_config = config_bundle_pb2.ConfigBundle()
        hal_config = project_config.android_hal_config

        fp1 = hal_config.fingerprint_list.add()
        fp1.id = "fp1"
        fp1.default = True
        fp2 = hal_config.fingerprint_list.add()
        fp2.id = "fp2"
        fp2.default = True

        suite = DefaultComponentConstraintSuite()
        with self.assertRaises(AssertionError) as context:
            suite.check_single_default_per_type(
                program_config=config_bundle_pb2.ConfigBundle(),
                project_config=project_config,
                factory_dir=self.temp_dir,
            )

        self.assertIn("have default=True", str(context.exception))


if __name__ == "__main__":
    unittest.main()
