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
        self.temp_dir = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.output_xml_path = pathlib.Path(self.temp_dir.name) / "output.xml"
        # Suppress logging below ERROR during tests
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        """Clean up the temporary directory."""
        self.temp_dir.cleanup()
        # Re-enable logging
        logging.disable(logging.NOTSET)

    def test_main_success_flow(self):
        """Test main() with valid inputs."""
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


if __name__ == "__main__":
    unittest.main(module=__name__)
