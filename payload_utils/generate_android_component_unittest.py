#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for generate_android_component.py."""

from pathlib import Path
import unittest

import generate_android_component
from lxml import etree  # pylint: disable=import-error


TEST_DATA_DIR = Path(__file__).parent / "test_data"


class TestGenerateAndroidComponent(unittest.TestCase):
    """Tests for generate_android_component.py."""

    def test_process_halconfig_tree_audio(self):
        """Tests process_halconfig_tree for AudioConfiguration."""
        xml_file = TEST_DATA_DIR / "sample_hal_config.xml"
        tree = etree.parse(xml_file)
        root = tree.getroot()
        component = "AudioConfiguration"
        unique_configs = generate_android_component.process_halconfig_tree(
            root, component
        )

        self.assertIsNotNone(unique_configs)
        self.assertEqual(len(unique_configs), 2)
        for ucf in unique_configs:
            if ucf.find("audio-config-dir").text == "config1":
                self.assertEqual(ucf.find("param1").text, "value1")
            if ucf.find("audio-config-dir").text == "config2":
                self.assertEqual(ucf.find("param1").text, "value2")

    def test_process_halconfig_tree_fingerprint(self):
        """Tests process_halconfig_tree for FingerprintConfiguration."""
        xml_file = TEST_DATA_DIR / "sample_hal_config.xml"
        tree = etree.parse(xml_file)
        root = tree.getroot()
        component = "FingerprintConfiguration"
        unique_configs = generate_android_component.process_halconfig_tree(
            root, component
        )

        self.assertIsNotNone(unique_configs)
        self.assertEqual(len(unique_configs), 1)
        self.assertEqual(unique_configs[0].find("board").text, "board_a")

    def test_generate_configstar_per_component_audio(self):
        """Tests generate_configstar_per_component for audio."""
        comp_name_star = "audio"
        audio_element_config1 = etree.Element("AudioConfiguration")
        etree.SubElement(audio_element_config1, "audio-config-dir").text = (
            "config1"
        )
        etree.SubElement(audio_element_config1, "param1").text = "value1"
        audio_element_config2 = etree.Element("AudioConfiguration")
        etree.SubElement(audio_element_config2, "audio-config-dir").text = (
            "config2"
        )
        etree.SubElement(audio_element_config2, "param1").text = "value2"

        comp_configs = [audio_element_config1, audio_element_config2]
        star_content = []
        result = generate_android_component.generate_configstar_per_component(
            comp_name_star, comp_configs, star_content
        )

        self.assertEqual(
            result,
            {"audio": ["_ANDROID_HAL_AUDIO_Id1", "_ANDROID_HAL_AUDIO_Id2"]},
        )

    def test_generate_configstar_per_component_fingerprint(self):
        """Tests generate_configstar_per_component for fingerprint."""
        comp_name_star = "fingerprint"
        fp_element = etree.Element("FingerprintConfiguration")
        etree.SubElement(fp_element, "board").text = "board_a"
        etree.SubElement(fp_element, "sensor").text = "sensor_x"

        comp_configs = [fp_element]
        star_content = []
        result = generate_android_component.generate_configstar_per_component(
            comp_name_star, comp_configs, star_content
        )

        self.assertEqual(
            result, {"fingerprint": ["_ANDROID_HAL_FINGERPRINT_Id1"]}
        )


if __name__ == "__main__":
    unittest.main()
