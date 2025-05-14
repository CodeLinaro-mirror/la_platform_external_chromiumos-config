#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for the cros_to_android script."""

import argparse
import pathlib
import tempfile
import unittest

# pylint: disable=import-error
from chromiumos.config.api import design_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.api.software import software_config_pb2
from chromiumos.config.payload import config_bundle_pb2
import cros_to_android
from google.protobuf import json_format
from lxml import etree


# pylint: enable=import-error


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

    def tearDown(self):
        """Clean up the temporary directory."""
        self.temp_dir_obj.cleanup()

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
                "TestDesign_123/permissions.xml",
                "TestDesign_456/permissions.xml",
            ],
        )

        with open(output_files[0], "rb") as f:
            self.assertEqual(
                f.read(),
                b"<permissions>\n  "
                b'<feature name="android.hardware.fingerprint"/>\n'
                b"</permissions>\n",
            )


class HalEntryHelpersTest(unittest.TestCase):
    """Tests for the _add_*_entry helper functions."""

    # pylint: disable=protected-access

    def setUp(self):
        self.root_element = etree.Element("HalConfig")
        self.design_config = design_pb2.Design.Config()
        self.design_config.id.value = "TestModel:123"
        self.sw_config = software_config_pb2.SoftwareConfig()

    def test_add_cellular_entry_present_valid(self):
        """Test cellular entry with valid present modem."""
        self.design_config.hardware_features.cellular.present = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self.design_config.hardware_features.cellular.model = "TestFirmware"
        self.design_config.hardware_features.cellular.modem_type = (
            topology_pb2.HardwareFeatures.Cellular.MODEM_FM101
        )

        cros_to_android._add_cellular_entry(
            self.root_element, self.design_config
        )

        cc_elem = self.root_element.find("CellularConfiguration")
        self.assertIsNotNone(cc_elem)
        self.assertEqual(cc_elem.find("firmware-variant").text, "TestFirmware")
        self.assertEqual(cc_elem.find("modem-type").text, "FM101")

    def test_add_cellular_entry_not_present(self):
        """Test cellular entry when feature is not present."""
        self.design_config.hardware_features.cellular.present = (
            topology_pb2.HardwareFeatures.NOT_PRESENT
        )
        cros_to_android._add_cellular_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("CellularConfiguration"))

    def test_add_cellular_entry_modem_unknown(self):
        """Test cellular entry with MODEM_UNKNOWN."""
        self.design_config.hardware_features.cellular.present = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self.design_config.hardware_features.cellular.modem_type = (
            topology_pb2.HardwareFeatures.Cellular.MODEM_UNKNOWN
        )
        cros_to_android._add_cellular_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("CellularConfiguration"))

    def test_add_fingerprint_entry_present_power_button(self):
        """Test fingerprint entry, present, on power button."""
        fp_features = self.design_config.hardware_features.fingerprint
        fp_features.present = True
        fp_features.board = "TestBoard"
        fp_features.location = (
            topology_pb2.HardwareFeatures.Fingerprint.POWER_BUTTON_TOP_LEFT
        )
        fp_features.ro_version = "v1.0"

        cros_to_android._add_fingerprint_entry(
            self.root_element, self.design_config
        )

        fp_elem = self.root_element.find("FingerprintConfiguration")
        self.assertIsNotNone(fp_elem)
        self.assertEqual(fp_elem.find("board").text, "TestBoard")
        self.assertEqual(
            fp_elem.find("fingerprint-sensor-type").text, "POWER_BUTTON"
        )
        self.assertEqual(
            fp_elem.find("sensor-location").text, "POWER_BUTTON_TOP_LEFT"
        )
        self.assertEqual(fp_elem.find("ro-version").text, "v1.0")

    def test_add_fingerprint_entry_present_dedicated(self):
        """Test fingerprint entry, present, dedicated sensor."""
        fp_features = self.design_config.hardware_features.fingerprint
        fp_features.present = True
        fp_features.board = "AnotherBoard"
        fp_features.location = (
            topology_pb2.HardwareFeatures.Fingerprint.KEYBOARD_BOTTOM_RIGHT
        )

        cros_to_android._add_fingerprint_entry(
            self.root_element, self.design_config
        )

        fp_elem = self.root_element.find("FingerprintConfiguration")
        self.assertIsNotNone(fp_elem)
        self.assertEqual(fp_elem.find("board").text, "AnotherBoard")
        self.assertEqual(
            fp_elem.find("fingerprint-sensor-type").text, "STAND_ALONE"
        )
        self.assertEqual(
            fp_elem.find("sensor-location").text, "KEYBOARD_BOTTOM_RIGHT"
        )

    def test_add_fingerprint_entry_not_present(self):
        """Test fingerprint entry when not present."""
        self.design_config.hardware_features.fingerprint.present = False
        cros_to_android._add_fingerprint_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("FingerprintConfiguration"))

    def test_add_fingerprint_entry_missing_board(self):
        """Test fingerprint entry present but board missing."""
        fp_features = self.design_config.hardware_features.fingerprint
        fp_features.present = True
        fp_features.location = (
            topology_pb2.HardwareFeatures.Fingerprint.POWER_BUTTON_TOP_LEFT
        )
        cros_to_android._add_fingerprint_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("FingerprintConfiguration"))

    def test_add_fingerprint_entry_location_unknown(self):
        """Test fingerprint entry present but location unknown."""
        fp_features = self.design_config.hardware_features.fingerprint
        fp_features.present = True
        fp_features.board = "TestBoard"
        fp_features.location = (
            topology_pb2.HardwareFeatures.Fingerprint.LOCATION_UNKNOWN
        )
        cros_to_android._add_fingerprint_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("FingerprintConfiguration"))

    def test_add_firmware_entry_with_customizations(self):
        """Test firmware entry with coreboot customizations data."""
        self.sw_config.firmware.main_ro_payload.firmware_image_name = (
            "test_image"
        )
        self.design_config.hardware_features.fw_config.coreboot_customizations.extend(
            ["cust1", "cust2"]
        )

        cros_to_android._add_firmware_entry(
            self.root_element, self.design_config, self.sw_config
        )
        fw_elem = self.root_element.find("FirmwareConfiguration")
        self.assertIsNotNone(fw_elem)
        self.assertEqual(
            fw_elem.find("firmware-manifest-key").text, "test_image_cust1_cust2"
        )

    def test_add_firmware_entry_without_customizations(self):
        """Test firmware entry without coreboot customizations data."""
        self.sw_config.firmware.main_ro_payload.firmware_image_name = (
            "test_image"
        )

        cros_to_android._add_firmware_entry(
            self.root_element, self.design_config, self.sw_config
        )
        fw_elem = self.root_element.find("FirmwareConfiguration")
        self.assertIsNotNone(fw_elem)
        self.assertEqual(
            fw_elem.find("firmware-manifest-key").text, "test_image"
        )

    def test_add_firmware_entry_no_image_name(self):
        """Test firmware entry when image name is missing."""
        # sw_config.firmware.main_ro_payload.firmware_image_name is not set
        cros_to_android._add_firmware_entry(
            self.root_element, self.design_config, self.sw_config
        )
        self.assertIsNone(self.root_element.find("FirmwareConfiguration"))

    def test_add_audio_entry_valid(self):
        """Test audio entry with valid data."""
        audio_features = self.design_config.hardware_features.audio
        card_config = audio_features.card_configs.add()
        card_config.card_name = "TestSoundcard"

        cros_to_android._add_audio_entry(self.root_element, self.design_config)
        audio_elem = self.root_element.find("AudioConfiguration")
        self.assertIsNotNone(audio_elem)
        self.assertEqual(audio_elem.find("soundcard").text, "TestSoundcard")
        self.assertEqual(audio_elem.find("audio-config-dir").text, "TestModel")

    def test_add_audio_entry_no_card_configs(self):
        """Test audio entry with no card_configs."""
        cros_to_android._add_audio_entry(self.root_element, self.design_config)
        self.assertIsNone(self.root_element.find("AudioConfiguration"))


class FeatureXmlGenerationTest(unittest.TestCase):
    """Tests for feature XML generation functions."""

    def setUp(self):
        self.temp_dir_obj = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.temp_dir = pathlib.Path(self.temp_dir_obj.name)
        self.config = design_pb2.Design.Config()
        self.config.id.value = "TestModel:123"

    def _create_bundle_and_run_feature_generation(self):
        """Helper to run feature generation for self.config."""
        bundle = config_bundle_pb2.ConfigBundle()
        bundle.design_list.add().configs.add().CopyFrom(self.config)

        temp_json_path = self.temp_dir / "test_input_features.jsonproto"
        with open(temp_json_path, "w", encoding="utf-8") as f:
            f.write(json_format.MessageToJson(bundle))

        opts = argparse.Namespace(
            jsonproto_file=temp_json_path,
            output_dir=self.temp_dir,
        )
        cros_to_android.run_generate_feature_xml(opts)

    def _assert_feature_xml(self, expected_features: list[str]):
        """Asserts the presence and content of a feature XML."""
        feature_file_path = self.temp_dir / "TestModel_123/permissions.xml"

        self.assertTrue(feature_file_path.is_file())
        with open(feature_file_path, "rb") as f:
            xml_content = f.read()

        root = etree.fromstring(xml_content)

        found_features = {
            feature.get("name") for feature in root.findall("feature")
        }

        self.assertSetEqual(
            found_features,
            set(expected_features),
            (
                f"Expected features {set(expected_features)} but found "
                f"{found_features} in {feature_file_path}"
            ),
        )

    def test_generate_fingerprint_feature(self):
        """Test fingerprint feature XML."""
        self.config.hardware_features.fingerprint.present = True

        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.fingerprint"])

    def test_generate_accelerometer_feature(self):
        """Test accelerometer feature XML."""
        self.config.hardware_features.accelerometer.base_accelerometer = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.accelerometer"])

    def test_generate_gyroscope_feature(self):
        """Test gyroscope feature XML."""
        self.config.hardware_features.gyroscope.base_gyroscope = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.gyroscope"])

    def test_generate_compass_feature(self):
        """Test compass feature XML."""
        self.config.hardware_features.magnetometer.lid_magnetometer = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.compass"])

    def test_generate_light_sensor_feature(self):
        """Test light sensor feature XML."""
        self.config.hardware_features.light_sensor.camera_lightsensor = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.light"])

    def test_generate_hinge_angle_feature(self):
        """Test hinge angle feature XML."""
        self.config.hardware_features.form_factor.form_factor = (
            topology_pb2.HardwareFeatures.FormFactor.CONVERTIBLE
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.hinge_angle"])

    def test_generate_proximity_feature(self):
        """Test proximity sensor feature XML."""
        self.config.hardware_features.proximity.configs.add()
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.sensor.proximity"])

    def test_generate_sar_feature(self):
        """Test com.google.sensor.sar feature XML."""
        prox_config = self.config.hardware_features.proximity.configs.add()
        prox_config.semtech_config.sampling_frequency = 1
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            ["android.hardware.sensor.proximity", "com.google.sensor.sar"]
        )

    def test_generate_device_orientation_feature(self):
        """Test android.sensor.device_orientation feature XML."""
        self.config.hardware_features.accelerometer.lid_accelerometer = (
            topology_pb2.HardwareFeatures.PRESENT
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            [
                "android.hardware.sensor.accelerometer",
                "android.sensor.device_orientation",
            ]
        )


if __name__ == "__main__":
    unittest.main(module=__name__)
