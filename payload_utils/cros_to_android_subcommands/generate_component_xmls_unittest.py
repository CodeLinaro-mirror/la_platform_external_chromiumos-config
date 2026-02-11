# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for the cros_to_android script."""

import pathlib
import tempfile
import unittest

from chromiumos.config.payload import config_bundle_pb2
from cros_to_android import generate_component_xmls
from lxml import etree  # pylint: disable=import-error


class ComponentXmlGenerationTest(unittest.TestCase):
    """Tests for component XML generation."""

    def setUp(self):
        self.temp_dir_obj = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.temp_dir = pathlib.Path(self.temp_dir_obj.name)

    def tearDown(self):
        self.temp_dir_obj.cleanup()

    def test_generate_component_xmls_success(self):
        """Test successful generation of component XML files."""
        bundle = config_bundle_pb2.ConfigBundle()
        hal_config = bundle.android_hal_config

        audio = hal_config.audio_list.add()
        audio.id = "audio_config_1"
        audio.soundcard = "TestSoundcard"

        cellular = hal_config.cellular_list.add()
        cellular.id = "cellular_config_1"
        cellular.modem_type = 3
        cellular.firmware_variant = "TestFirmware"

        fp1 = hal_config.fingerprint_list.add()
        fp1.id = "fingerprint_config_1"
        fp1.board = "TestBoard1"
        fp1.fingerprint_sensor_type = "POWER_BUTTON"
        fp1.sensor_location = 1
        fp1.ro_version = "v1.2.3"

        fp2 = hal_config.fingerprint_list.add()
        fp2.id = "fingerprint_config_2"
        fp2.board = "TestBoard2"
        fp2.fingerprint_sensor_type = "STAND_ALONE"
        fp2.sensor_location = 3

        generate_component_xmls.generate(bundle, self.temp_dir)

        audio_file = self.temp_dir / "audio_config_1.xml"
        self.assertTrue(audio_file.is_file())
        audio_root = etree.parse(audio_file).getroot()
        self.assertEqual(audio_root.tag, "AudioConfiguration")
        self.assertEqual(audio_root.find("soundcard").text, "TestSoundcard")

        cellular_file = self.temp_dir / "cellular_config_1.xml"
        self.assertTrue(cellular_file.is_file())
        cellular_root = etree.parse(cellular_file).getroot()
        self.assertEqual(cellular_root.tag, "CellularConfiguration")
        self.assertEqual(cellular_root.find("modem-type").text, "MODEM_FM101")
        self.assertEqual(
            cellular_root.find("firmware-variant").text, "TestFirmware"
        )

        fp1_file = self.temp_dir / "fingerprint_config_1.xml"
        self.assertTrue(fp1_file.is_file())
        fp1_root = etree.parse(fp1_file).getroot()
        self.assertEqual(fp1_root.tag, "FingerprintConfiguration")
        self.assertEqual(fp1_root.find("board").text, "TestBoard1")
        self.assertEqual(
            fp1_root.find("fingerprint-sensor-type").text, "POWER_BUTTON"
        )
        self.assertEqual(
            fp1_root.find("sensor-location").text, "POWER_BUTTON_TOP_LEFT"
        )
        self.assertEqual(fp1_root.find("ro-version").text, "v1.2.3")

        fp2_file = self.temp_dir / "fingerprint_config_2.xml"
        self.assertTrue(fp2_file.is_file())
        fp2_root = etree.parse(fp2_file).getroot()
        self.assertEqual(fp2_root.tag, "FingerprintConfiguration")
        self.assertEqual(fp2_root.find("board").text, "TestBoard2")
        self.assertEqual(
            fp2_root.find("fingerprint-sensor-type").text, "STAND_ALONE"
        )
        self.assertEqual(
            fp2_root.find("sensor-location").text, "KEYBOARD_BOTTOM_RIGHT"
        )
        self.assertIsNone(fp2_root.find("ro-version"))

    def test_generate_component_xml_no_id(self):
        """Test that no file is generated when a component has no id."""
        bundle = config_bundle_pb2.ConfigBundle()
        hal_config = bundle.android_hal_config

        # Audio config without an id
        audio = hal_config.audio_list.add()
        audio.soundcard = "TestSoundcardNoId"

        # Check that no files were created
        output_files = list(self.temp_dir.glob("*.xml"))
        self.assertEqual(len(output_files), 0)

    def test_generate_component_xml_repeated_field(self):
        """Test skipping empty repeated fields and keeping populated ones."""
        bundle = config_bundle_pb2.ConfigBundle()
        hal_config = bundle.android_hal_config
        camera = hal_config.camera_list.add()
        camera.id = "camera_config_1"
        camera.media_profile_suffix = "TestPrefix"

        generate_component_xmls.generate(bundle, self.temp_dir)
        xml_file = self.temp_dir / "camera_config_1.xml"
        self.assertTrue(xml_file.is_file())

        root = etree.parse(xml_file).getroot()
        self.assertEqual(root.tag, "CameraConfiguration")
        self.assertEqual(root.find("media-profile-suffix").text, "TestPrefix")
        self.assertIsNone(root.find("cameras"))


if __name__ == "__main__":
    unittest.main(module=__name__)
