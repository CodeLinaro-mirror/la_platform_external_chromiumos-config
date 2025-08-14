#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for the cros_to_android script."""

import argparse
import pathlib
import tempfile
import unittest

# pylint: disable=too-many-public-methods
# pylint: disable=import-error
from chromiumos.config.api import design_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.api.software import camera_config_pb2
from chromiumos.config.api.software import software_config_pb2
from chromiumos.config.payload import config_bundle_pb2
import cros_to_android
from google.protobuf import json_format
from lxml import etree


# pylint: enable=import-error


THIS_DIR = pathlib.Path(__file__).parent
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
        output_files = sorted(
            [p for p in self.output_features_dir.rglob("*") if p.is_file()]
        )

        self.assertEqual(
            [
                str(p.relative_to(self.output_features_dir))
                for p in output_files
            ],
            [
                "frid123_123/features.xml",
                "frid456_456/features.xml",
            ],
        )
        with open(output_files[0], "rb") as f:
            content = f.read()
            self.assertEqual(
                content,
                b"<permissions>\n  "
                b'<feature name="android.hardware.touchscreen"/>\n  '
                b'<feature name="android.hardware.touchscreen.multitouch"/>\n  '
                b'<feature name="android.hardware.touchscreen.multitouch.distinct"/>\n  '
                b'<feature name="android.hardware.touchscreen.multitouch.jazzhand"/>\n  '
                b'<feature name="android.hardware.camera.any"/>\n  '
                b'<feature name="android.hardware.camera.front"/>\n'
                b"</permissions>\n",
                f"Got unexpected content from file {f.name}: {content}",
            )

        with open(output_files[1], "rb") as f:
            self.assertEqual(
                f.read(),
                b"<permissions>\n  "
                b'<feature name="android.hardware.sensor.hinge_angle"/>\n'
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
        """Test audio entry with valid data (soundcard only)."""
        audio_features = self.design_config.hardware_features.audio
        card_config = audio_features.card_configs.add()
        card_config.card_name = "TestSoundcard"

        cros_to_android._add_audio_entry(self.root_element, self.design_config)
        audio_elem = self.root_element.find("AudioConfiguration")
        self.assertIsNotNone(audio_elem)
        self.assertEqual(audio_elem.find("soundcard").text, "TestSoundcard")
        self.assertEqual(
            audio_elem.find("audio-config-dir").text, "TestSoundcard"
        )

    def test_add_audio_entry_full_config(self):
        """Test audio entry with all valid data fields."""
        audio_features = self.design_config.hardware_features.audio
        card_config = audio_features.card_configs.add()
        card_config.card_name = "TestSoundcard"
        audio_features.headphone_codec = (
            topology_pb2.HardwareFeatures.Audio.ALC5682I
        )
        audio_features.speaker_amp = (
            topology_pb2.HardwareFeatures.Audio.MAX98390
        )
        audio_features.lid_microphone.value = 2
        audio_features.base_microphone.value = 1

        cros_to_android._add_audio_entry(self.root_element, self.design_config)
        audio_elem = self.root_element.find("AudioConfiguration")
        self.assertIsNotNone(audio_elem)
        self.assertEqual(audio_elem.find("soundcard").text, "TestSoundcard")
        self.assertEqual(
            audio_elem.find("audio-config-dir").text,
            "TestSoundcard_alc5682i_max98390_3",
        )

    def test_add_audio_entry_no_card_configs(self):
        """Test audio entry with no card_configs."""
        cros_to_android._add_audio_entry(self.root_element, self.design_config)
        self.assertIsNone(self.root_element.find("AudioConfiguration"))

    def test_add_video_entry_present_valid(self):
        """Test video entry with a valid arc_media_codecs_suffix."""
        self.design_config.hardware_features.soc.arc_media_codecs_suffix = (
            "test_suffix"
        )

        cros_to_android._add_video_entry(self.root_element, self.design_config)

        vc_elem = self.root_element.find("VideoConfiguration")
        self.assertIsNotNone(vc_elem)
        self.assertEqual(vc_elem.find("video-codec-suffix").text, "test_suffix")

    def test_add_video_entry_not_present(self):
        """Test video entry when arc_media_codecs_suffix is not present."""
        cros_to_android._add_video_entry(self.root_element, self.design_config)
        self.assertIsNone(self.root_element.find("VideoConfiguration"))

    def test_add_hardware_features_entry_valid_form_factor(self):
        """Test hardware features entry with a valid form factor."""
        self.design_config.hardware_features.form_factor.form_factor = (
            topology_pb2.HardwareFeatures.FormFactor.CLAMSHELL
        )
        cros_to_android._add_hardware_features_entry(
            self.root_element, self.design_config
        )
        hw_features_elem = self.root_element.find("HardwareFeatures")
        self.assertIsNotNone(hw_features_elem)
        self.assertEqual(hw_features_elem.find("form-factor").text, "CLAMSHELL")

    def test_add_hardware_features_entry_no_form_factor(self):
        """Test hardware features entry when no form factor is defined."""
        # Ensure form_factor is not set
        self.assertFalse(
            self.design_config.hardware_features.HasField("form_factor")
        )
        cros_to_android._add_hardware_features_entry(
            self.root_element, self.design_config
        )
        self.assertIsNone(self.root_element.find("HardwareFeatures"))

    def test_add_camera_entry_generated(self):
        """Camera entry generated if sw config enables it."""
        camera_device = (
            self.design_config.hardware_features.camera.devices.add()
        )
        camera_device.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        self.sw_config.camera_config.generate_media_profiles = True

        cros_to_android._add_camera_entry(
            self.root_element,
            self.design_config.hardware_features,
            self.sw_config,
            "TestModel",
            "123",
        )
        cam_config_elem = self.root_element.find("CameraConfiguration")
        self.assertIsNotNone(cam_config_elem)
        self.assertEqual(
            cam_config_elem.find("media-profile-suffix").text,
            "_testmodel_123",
        )

    def test_add_camera_entry_disabled(self):
        """Camera entry not generated if sw config disables it."""
        camera_device = (
            self.design_config.hardware_features.camera.devices.add()
        )
        camera_device.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        self.sw_config.camera_config.generate_media_profiles = False

        cros_to_android._add_camera_entry(
            self.root_element,
            self.design_config.hardware_features,
            self.sw_config,
            "TestModel",
            "123",
        )
        cam_config_elem = self.root_element.find("CameraConfiguration")
        self.assertIsNone(cam_config_elem)

    def test_add_wifi_entry_intel_config(self):
        """Test wifi entry when chip vendor is Intel."""
        wifi_config = self.design_config.hardware_features.wifi.wifi_config
        intel_wifi = wifi_config.intel_config
        intel_wifi.sar_table.sar_table_version = 1

        cros_to_android._add_wifi_entry(
            self.root_element, self.design_config, self.sw_config
        )

        wifi_elem = self.root_element.find("WiFiSarConfiguration")
        self.assertIsNotNone(wifi_elem)
        self.assertEqual(wifi_elem.find("Chip").text, "intel")

    def test_add_wifi_entry_mtk_no_regdomain(self):
        """Test wifi entry when chip vendor is MediaTek and no regdomain config."""
        wifi_config = self.design_config.hardware_features.wifi.wifi_config
        mtk_wifi = wifi_config.mtk_config
        tablet_power = mtk_wifi.tablet_mode_power_table
        tablet_power.limit_2g = 25
        tablet_power.limit_5g_1 = 55
        nontab_power = mtk_wifi.non_tablet_mode_power_table
        nontab_power.limit_2g = 25
        nontab_power.limit_5g_1 = 55

        cros_to_android._add_wifi_entry(
            self.root_element, self.design_config, self.sw_config
        )

        wifi_elem = self.root_element.find("WiFiSarConfiguration")
        self.assertIsNotNone(wifi_elem)
        self.assertEqual(wifi_elem.find("Chip").text, "mtk")
        power_elem = wifi_elem.find("MTKConfig").find("PowerTable.tablet")
        self.assertIsNotNone(power_elem)
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerLimit").text, "25"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g_1").find("PowerLimit").text, "55"
        )
        power_elem = wifi_elem.find("MTKConfig").find("PowerTable.clamshell")
        self.assertIsNotNone(power_elem)
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerLimit").text, "25"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g_1").find("PowerLimit").text, "55"
        )

    def test_add_wifi_entry_mtk_fcc_regdomain(self):
        """Test wifi entry when chip vendor is MediaTek and regdomain config is FCC."""
        wifi_config = self.design_config.hardware_features.wifi.wifi_config
        mtk_wifi = wifi_config.mtk_config
        tablet_power = mtk_wifi.tablet_mode_power_table
        tablet_power.limit_2g = 25
        tablet_power.limit_5g_1 = 55
        nontab_power = mtk_wifi.non_tablet_mode_power_table
        nontab_power.limit_2g = 25
        nontab_power.limit_5g_1 = 55
        fcc_power = mtk_wifi.fcc_power_table
        fcc_power.limit_2g = 20
        fcc_power.offset_2g = 2
        fcc_power.limit_5g = 50
        fcc_power.offset_5g = 5

        cros_to_android._add_wifi_entry(
            self.root_element, self.design_config, self.sw_config
        )

        wifi_elem = self.root_element.find("WiFiSarConfiguration")
        self.assertIsNotNone(wifi_elem)
        self.assertEqual(wifi_elem.find("Chip").text, "mtk")
        power_elem = wifi_elem.find("MTKConfig").find("PowerTable.tablet")
        self.assertIsNotNone(power_elem)
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerLimit").text, "25"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g_1").find("PowerLimit").text, "55"
        )
        power_elem = wifi_elem.find("MTKConfig").find("PowerTable.clamshell")
        self.assertIsNotNone(power_elem)
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerLimit").text, "25"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g_1").find("PowerLimit").text, "55"
        )
        power_elem = wifi_elem.find("MTKConfig").find("RegDomain.fcc")
        self.assertIsNotNone(power_elem)
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerLimit").text, "20"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.2g").find("PowerOffset").text, "2"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g").find("PowerLimit").text, "50"
        )
        self.assertEqual(
            power_elem.find("PowerConfig.5g").find("PowerOffset").text, "5"
        )


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

        # Add a sw_config to the bundle that matches the design config
        sw_config = bundle.software_configs.add()
        sw_config.design_config_id.value = self.config.id.value
        sw_config.id_scan_config.frid = "Google_testfrid"

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
        feature_file_path = self.temp_dir / "testfrid_123/features.xml"

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

    def test_generate_camera_any_feature(self):
        """Test camera.any feature presence."""
        self.config.hardware_features.camera.devices.add()
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(["android.hardware.camera.any"])

    def test_generate_camera_rear_feature(self):
        """Test rear camera feature presence."""
        cam_dev = self.config.hardware_features.camera.devices.add()
        cam_dev.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        cam_dev.detachable = False
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            ["android.hardware.camera.any", "android.hardware.camera"]
        )

    def test_generate_camera_front_feature(self):
        """Test front camera feature presence."""
        cam_dev = self.config.hardware_features.camera.devices.add()
        cam_dev.facing = topology_pb2.HardwareFeatures.Camera.FACING_FRONT
        cam_dev.detachable = False
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            ["android.hardware.camera.any", "android.hardware.camera.front"]
        )

    def test_generate_camera_autofocus_feature(self):
        """Test camera autofocus feature presence."""
        cam_dev = self.config.hardware_features.camera.devices.add()
        cam_dev.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        cam_dev.detachable = False
        cam_dev.flags = (
            topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_AUTOFOCUS
        )
        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            [
                "android.hardware.camera.any",
                "android.hardware.camera",
                "android.hardware.camera.autofocus",
            ]
        )

    def test_generate_camera_all_features(self):
        """Test all camera features present."""
        # Front camera
        front_cam = self.config.hardware_features.camera.devices.add()
        front_cam.facing = topology_pb2.HardwareFeatures.Camera.FACING_FRONT
        front_cam.detachable = False
        # Back camera with autofocus
        back_cam = self.config.hardware_features.camera.devices.add()
        back_cam.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        back_cam.detachable = False
        back_cam.flags = (
            topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_AUTOFOCUS
        )

        self._create_bundle_and_run_feature_generation()
        self._assert_feature_xml(
            [
                "android.hardware.camera.any",
                "android.hardware.camera",
                "android.hardware.camera.front",
                "android.hardware.camera.autofocus",
            ]
        )


class MediaProfileGenerationTest(unittest.TestCase):
    """Tests for media profile XML generation functions."""

    def setUp(self):
        self.temp_dir_obj = (
            tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        )
        self.temp_dir = pathlib.Path(self.temp_dir_obj.name)
        self.dtd_file = THIS_DIR / "media_profiles.dtd"

    def tearDown(self):
        self.temp_dir_obj.cleanup()

    def _create_bundle_and_run_media_profile_generation(
        self,
        design_config: design_pb2.Design.Config,
        generate_camera_media_profiles=True,
        no_dtd_file=False,
        custom_resolutions=None,
    ):
        """Helper to run media profile generation."""
        bundle = config_bundle_pb2.ConfigBundle()
        design = bundle.design_list.add()
        design.id.value = design_config.id.value.split(":")[0]
        design.configs.add().CopyFrom(design_config)

        sw_config = software_config_pb2.SoftwareConfig()
        sw_config.design_config_id.value = design_config.id.value
        sw_config.camera_config.generate_media_profiles = (
            generate_camera_media_profiles
        )
        if custom_resolutions:
            sw_config.camera_config.camcorder_resolutions.extend(
                custom_resolutions
            )
        bundle.software_configs.add().CopyFrom(sw_config)

        temp_json_path = self.temp_dir / "test_input_media_profiles.jsonproto"
        with open(temp_json_path, "w", encoding="utf-8") as f:
            f.write(json_format.MessageToJson(bundle))

        opts = argparse.Namespace(
            jsonproto_file=temp_json_path,
            output_dir=self.temp_dir,
            dtd_schema=None if no_dtd_file else self.dtd_file,
        )
        cros_to_android.run_generate_media_profiles(opts)

    def test_generate_media_profile_success_with_validation(self):
        """Test successful media profile generation with DTD validation."""
        config = design_pb2.Design.Config()
        config.id.value = "TestModel:123"
        camera_device = config.hardware_features.camera.devices.add()
        camera_device.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        camera_device.interface = (
            topology_pb2.HardwareFeatures.Camera.INTERFACE_MIPI
        )
        camera_device.orientation = (
            topology_pb2.HardwareFeatures.Camera.ORIENTATION_0
        )
        camera_device.flags = (
            topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_1080P
        )

        self._create_bundle_and_run_media_profile_generation(config)

        output_file = (
            self.temp_dir / "testmodel_123" / "media_profiles_testmodel_123.xml"
        )
        self.assertTrue(output_file.is_file())
        with open(output_file, "rb") as f:
            content = f.read()
            self.assertTrue(b"<MediaSettings>" in content)
            self.assertTrue(b'<CamcorderProfiles cameraId="0">' in content)

    def test_generate_media_profile_with_custom_bitrate(self):
        """Test media profile generation with custom bitrate configuration."""
        config = design_pb2.Design.Config()
        config.id.value = "TestModel:123"
        camera_device = config.hardware_features.camera.devices.add()
        camera_device.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        camera_device.flags = (
            topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_1080P
        )

        # Create custom resolution with bitrate
        resolution = camera_config_pb2.Resolution()
        resolution.width = 1280
        resolution.height = 720
        resolution.bitrate = 12000000  # 12 Mbps

        self._create_bundle_and_run_media_profile_generation(
            config, custom_resolutions=[resolution]
        )

        output_file = (
            self.temp_dir / "testmodel_123" / "media_profiles_testmodel_123.xml"
        )
        self.assertTrue(output_file.is_file())
        with open(output_file, "rb") as f:
            content = f.read()
            self.assertTrue(b"<MediaSettings>" in content)
            self.assertTrue(b'<CamcorderProfiles cameraId="0">' in content)
            # Verify custom bitrate is used
            self.assertTrue(b'bitRate="12000000"' in content)

    def test_generate_media_profile_success_without_validation(self):
        """Test successful media profile generation without DTD validation."""
        config = design_pb2.Design.Config()
        config.id.value = "TestModel:123"
        camera_device = config.hardware_features.camera.devices.add()
        camera_device.facing = topology_pb2.HardwareFeatures.Camera.FACING_BACK
        camera_device.flags = (
            topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_1080P
        )

        self._create_bundle_and_run_media_profile_generation(
            config, no_dtd_file=True
        )

        output_file = (
            self.temp_dir / "testmodel_123" / "media_profiles_testmodel_123.xml"
        )
        self.assertTrue(output_file.is_file())
        with open(output_file, "rb") as f:
            content = f.read()
            self.assertTrue(b"<MediaSettings>" in content)

    def test_generate_media_profile_disabled(self):
        """Test media profile generation when disabled in config."""
        config = design_pb2.Design.Config()
        config.id.value = "TestModel:123"
        config.hardware_features.camera.devices.add().facing = (
            topology_pb2.HardwareFeatures.Camera.FACING_BACK
        )

        self._create_bundle_and_run_media_profile_generation(
            config, generate_camera_media_profiles=False
        )

        output_file = (
            self.temp_dir / "testmodel_123" / "media_profiles_testmodel_123.xml"
        )
        self.assertFalse(output_file.exists())

    def test_generate_media_profile_no_camera_devices(self):
        """Test media profile generation with no camera devices."""
        config = design_pb2.Design.Config()
        config.id.value = "TestModel:789"
        # No camera devices added

        self._create_bundle_and_run_media_profile_generation(config)
        output_file = (
            self.temp_dir / "testmodel_789" / "media_profiles_testmodel_789.xml"
        )
        self.assertFalse(output_file.exists())

    def test_main_generate_media_profiles_success(self):
        """Test main() generate-media-profiles success flow with DTD."""
        argv = [
            "generate-media-profiles",
            str(VALID_JSON_INPUT),
            "--output-dir",
            str(self.temp_dir),
            "--dtd-schema",
            str(self.dtd_file),
        ]

        return_code = cros_to_android.main(argv)

        self.assertEqual(return_code, 0)
        output_file_123 = (
            self.temp_dir
            / "testdesign_123"
            / "media_profiles_testdesign_123.xml"
        )
        output_file_456 = (
            self.temp_dir
            / "testdesign_456"
            / "media_profiles_testdesign_456.xml"
        )

        self.assertTrue(output_file_123.exists())
        self.assertFalse(output_file_456.exists())


if __name__ == "__main__":
    unittest.main(module=__name__)
