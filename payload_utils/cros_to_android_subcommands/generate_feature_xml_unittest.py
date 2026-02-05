#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for generate_feature_xml module."""

import pathlib
import tempfile
import unittest

from chromiumos.config.payload import config_bundle_pb2
from cros_to_android_subcommands import generate_feature_xml
from lxml import etree  # pylint: disable=import-error


class GenerateFeatureXmlTest(unittest.TestCase):
    """Tests for generate_feature_xml module."""

    def setUp(self):
        self.temp_dir_obj = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.temp_dir = pathlib.Path(self.temp_dir_obj.name)
        self.bundle = config_bundle_pb2.ConfigBundle()
        self.fingerprint_config = (
            self.bundle.android_hal_config.fingerprint_list.add()
        )
        self.fingerprint_config.id = "Fingerprint_Test_ID"

    def tearDown(self):
        self.temp_dir_obj.cleanup()

    def test_generate_fingerprint_feature(self):
        """Test fingerprint feature XML generation."""
        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        feature_file_path = self.temp_dir / "Fingerprint_Test_ID.xml"
        self.assertTrue(feature_file_path.is_file())
        with open(feature_file_path, "rb") as f:
            xml_content = f.read()

        root = etree.fromstring(xml_content)
        self.assertEqual(root.tag, "permissions")
        features = {f.get("name") for f in root.findall("feature")}
        self.assertIn("android.hardware.fingerprint", features)

    def test_generate_fingerprint_skip_no_id(self):
        """Test skipping if ID is missing."""
        self.fingerprint_config.ClearField("id")
        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        files = list(self.temp_dir.glob("*.xml"))
        self.assertEqual(len(files), 0)


if __name__ == "__main__":
    unittest.main()
