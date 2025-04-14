# python3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for the utilities module"""

import unittest

from common import utilities


class UtilitiesTest(unittest.TestCase):
    """Tests for utilities.py"""

    def test_levenshtein_distance(self):
        """Test levenshtein distance"""
        self.assertEqual(utilities.levenshtein_distance("", ""), 0)
        self.assertEqual(utilities.levenshtein_distance("1", ""), 1)
        self.assertEqual(utilities.levenshtein_distance("", "1"), 1)
        self.assertEqual(utilities.levenshtein_distance("1", "1"), 0)
        self.assertEqual(utilities.levenshtein_distance("1", "2"), 1)
        self.assertEqual(utilities.levenshtein_distance("foo", "bar"), 3)
        self.assertEqual(utilities.levenshtein_distance("kitten", "mittens"), 2)
