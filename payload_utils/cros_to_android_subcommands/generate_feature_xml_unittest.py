#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for generate_feature_xml module."""

import pathlib
import tempfile
import unittest

from chromiumos.config.api import android_component_configs_pb2
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

    def test_generate_camera_feature(self):
        """Test camera feature XML generation."""
        camera_config = self.bundle.android_hal_config.camera_list.add()
        camera_config.id = "Camera_Test_ID"
        camera = camera_config.cameras.add()
        camera.position = (
            android_component_configs_pb2.CameraConfigurationType.FACING_FRONT
        )
        camera.autofocus_support = (
            android_component_configs_pb2.HalConfiguration.PRESENT
        )

        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        feature_file_path = self.temp_dir / "Camera_Test_ID.xml"
        self.assertTrue(feature_file_path.is_file())
        with open(feature_file_path, "rb") as f:
            xml_content = f.read()

        root = etree.fromstring(xml_content)
        self.assertEqual(root.tag, "permissions")
        features = {f.get("name") for f in root.findall("feature")}
        self.assertIn("android.hardware.camera.any", features)
        self.assertIn("android.hardware.camera.front", features)
        self.assertIn("android.hardware.camera.autofocus", features)
        self.assertNotIn("android.hardware.camera", features)

    def test_generate_hardware_feature(self):
        """Test hardware feature XML generation."""
        hw_config = self.bundle.android_hal_config.hwfeature_list.add()
        hw_config.id = "HW_Test_ID"
        hw_config.form_factor = "CONVERTIBLE"
        hw_config.touchscreen_support = "true"

        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        feature_file_path = self.temp_dir / "HW_Test_ID.xml"
        self.assertTrue(feature_file_path.is_file())
        with open(feature_file_path, "rb") as f:
            xml_content = f.read()

        root = etree.fromstring(xml_content)
        self.assertEqual(root.tag, "permissions")
        features = {f.get("name") for f in root.findall("feature")}
        self.assertIn("android.hardware.sensor.hinge_angle", features)
        self.assertIn("android.hardware.touchscreen", features)
        self.assertIn("android.hardware.touchscreen.multitouch", features)

    def test_generate_sensor_feature(self):
        """Test sensor feature XML generation."""
        accel_config = self.bundle.android_hal_config.accelerometer_list.add()
        accel_config.id = "Accelerometer_Test_ID"
        accel_config.feature_accelerometer = (
            android_component_configs_pb2.HalConfiguration.PRESENT
        )

        light_config = self.bundle.android_hal_config.lightsensor_list.add()
        light_config.id = "LightSensor_Test_ID"
        light_config.feature_lightsensor = (
            android_component_configs_pb2.HalConfiguration.PRESENT
        )

        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        accel_file = self.temp_dir / "Accelerometer_Test_ID.xml"
        self.assertTrue(accel_file.is_file())
        with open(accel_file, "rb") as f:
            xml_content = f.read()
        root = etree.fromstring(xml_content)
        features = {f.get("name") for f in root.findall("feature")}
        self.assertIn("android.hardware.sensor.accelerometer", features)

        light_file = self.temp_dir / "LightSensor_Test_ID.xml"
        self.assertTrue(light_file.is_file())
        with open(light_file, "rb") as f:
            xml_content = f.read()
        root = etree.fromstring(xml_content)
        features = {f.get("name") for f in root.findall("feature")}
        self.assertIn("android.hardware.sensor.light", features)

        gyro_file = self.temp_dir / "Gyroscope_Test_ID.xml"
        self.assertFalse(gyro_file.exists())

    def test_generate_proximity_feature(self):
        """Test proximity feature XML generation."""
        prox_config = self.bundle.android_hal_config.proximity_list.add()
        prox_config.id = "Proximity_Test_ID"

        # Initially, no semtech_config is present.
        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        prox_file = self.temp_dir / "Proximity_Test_ID.xml"
        self.assertTrue(prox_file.is_file())
        with open(prox_file, "rb") as f:
            xml_content = f.read()
        root = etree.fromstring(xml_content)
        features = {f.get("name") for f in root.findall("feature")}

        self.assertIn("android.hardware.sensor.proximity", features)
        self.assertNotIn("com.google.sensor.sar", features)

        # Now, add semtech_config and check again.
        prox_config.semtech_proximity.semtech_config.sampling_frequency = 10.0
        generate_feature_xml.generate_from_hal_config(
            self.bundle.android_hal_config, self.temp_dir
        )

        with open(prox_file, "rb") as f:
            xml_content = f.read()
        root = etree.fromstring(xml_content)
        features = {f.get("name") for f in root.findall("feature")}

        self.assertIn("android.hardware.sensor.proximity", features)
        self.assertIn("com.google.sensor.sar", features)

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
