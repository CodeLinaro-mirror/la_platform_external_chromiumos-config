#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for the cros_to_android script."""

import logging
import pathlib
import tempfile
import unittest

import cros_to_android  # pylint: disable=import-error


TEST_DATA_DIR = pathlib.Path(__file__).parent / "test_data"
VALID_JSON_INPUT = TEST_DATA_DIR / "config.jsonproto"
VALID_XSD_SCHEMA = TEST_DATA_DIR / "hal_config.xsd"


class CrosConfigConverterMainTest(unittest.TestCase):
    """Tests the main execution flow of the converter script."""

    def setUp(self):
        """Create a temporary directory for test outputs."""
        self.temp_dir_obj = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.temp_dir = pathlib.Path(self.temp_dir_obj.name)
        self.output_xml_path = self.temp_dir / "hal_config.xml"
        self.output_features_dir = self.temp_dir / "features"
        # Suppress logging below ERROR during tests
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        """Clean up the temporary directory."""
        self.temp_dir_obj.cleanup()
        # Re-enable logging
        logging.disable(logging.NOTSET)

    def test_main_generate_hal_xml_success(self):
        """Test main() generate-hal-xml success flow."""
        argv = [
            "generate-hal-xml",
            str(VALID_JSON_INPUT),
            "--output-xml",
            str(self.output_xml_path),
            "--xsd-schema",
            str(VALID_XSD_SCHEMA),
        ]

        return_code = cros_to_android.main(argv)

        self.assertEqual(return_code, 0)
        self.assertTrue(self.output_xml_path.is_file())

    def test_main_generate_feature_xml_success(self):
        """Test main() generate-feature-xml success flow."""
        argv = [
            "generate-feature-xml",
            str(VALID_JSON_INPUT),
            "--output-dir",
            str(self.output_features_dir),
        ]

        return_code = cros_to_android.main(argv)

        self.assertEqual(return_code, 0)
        self.assertTrue(self.output_features_dir.is_dir())
        output_files = [
            p for p in self.output_features_dir.rglob("*") if p.is_file()
        ]

        self.assertEqual(
            sorted(
                str(p.relative_to(self.output_features_dir))
                for p in output_files
            ),
            [
                "TestDesignWithFingerprint_123/android.hardware.fingerprint.xml",
                "TestDesignWithFingerprint_456/android.hardware.fingerprint.xml",
            ],
        )

        with open(output_files[0], "rb") as f:
            self.assertEqual(
                f.read(),
                b"<permissions>\n  "
                b'<feature name="android.hardware.fingerprint"/>\n'
                b"</permissions>\n",
            )


if __name__ == "__main__":
    unittest.main(module=__name__)
