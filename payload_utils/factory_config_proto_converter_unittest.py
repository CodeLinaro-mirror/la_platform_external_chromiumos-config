#!/usr/bin/env python3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The unittest of factory_config_proto_converter.py"""

import os
import subprocess
import tempfile
import unittest

from chromiumos.config.test import fake_config
import factory_config_proto_converter


THIS_DIR = os.path.dirname(__file__)

PROGRAM_CONFIG_FILE = fake_config.FAKE_PROGRAM_CONFIG
PROJECT_CONFIG_FILE = fake_config.FAKE_PROJECT_CONFIG


def fakeConfig():
    return factory_config_proto_converter._MergeConfigs(
        [
            factory_config_proto_converter._ReadConfig(PROGRAM_CONFIG_FILE),
            factory_config_proto_converter._ReadConfig(PROJECT_CONFIG_FILE),
        ]
    )


class MainTest(unittest.TestCase):

    def testFullTransform(self):
        with tempfile.TemporaryDirectory() as tempdir:
            output_file = os.path.join(tempdir, "output")
            factory_config_proto_converter.Main(
                project_configs=[PROJECT_CONFIG_FILE],
                program_config=PROGRAM_CONFIG_FILE,
                output=output_file,
            )

            expected_file = os.path.join(THIS_DIR, "test_data/model_sku.json")
            changed = (
                subprocess.run(["diff", expected_file, output_file]).returncode
                != 0
            )

            regen_cmd = (
                "To regenerate the expected output, run:\n"
                "\tcd payload_utils && "
                "python3 -m factory_config_proto_converter "
                "-c %s "
                "-p %s "
                "-o %s "
                % (PROJECT_CONFIG_FILE, PROGRAM_CONFIG_FILE, expected_file)
            )

            if changed:
                print(regen_cmd)
                self.fail("Fake project transform does not match")


if __name__ == "__main__":
    unittest.main(module=__name__)
