# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for constraint_suite_discovery."""

import os
import sys
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.constraint_suite import ConstraintSuite
from checker.constraint_suite_discovery import discover_suites


TESTDATA_PATH = os.path.join(os.path.dirname(__file__), "testdata")


class DiscoverSuitesTest(unittest.TestCase):
    """Tests for discover_suites."""

    def test_discover_suites(self):
        """Tests that ConstraintSuites are found and loaded."""
        suites = discover_suites(directory=TESTDATA_PATH)

        self.assertEqual(len(suites), 2)

        self.assertEqual(type(suites[0]).__name__, "Example1ConstraintSuite")
        self.assertEqual(type(suites[1]).__name__, "Example2ConstraintSuite")

        for suite in suites:
            self.assertIsInstance(suite, ConstraintSuite)
            self.assertTrue(hasattr(suite, "check_first_thing"))
            self.assertTrue(hasattr(suite, "check_second_thing"))

    def test_discover_suites_path_unmodified(self):
        """Tests that discover_suites doesn't modify sys.path."""
        path_before = sys.path
        discover_suites(directory=TESTDATA_PATH)
        self.assertEqual(sys.path, path_before)

    def test_discover_suites_invalid_pattern(self):
        """Tests non-Python patterns raise an error."""
        with self.assertRaisesRegex(ValueError, 'pattern must end with ".py"'):
            discover_suites(directory=TESTDATA_PATH, pattern="*.txt")
