#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# pylint: disable=module-missing-docstring,class-missing-docstring

import os
import subprocess
import unittest

import cros_config_proto_converter

from chromiumos.config.test import fake_config

from chromiumos.config.api.software.build_target_pb2 import BuildTarget
from chromiumos.config.api.design_pb2 import Design
from chromiumos.config.api.software.firmware_config_pb2 import (FirmwareConfig,
                                                                FirmwarePayload)
from chromiumos.config.api.software.software_config_pb2 import SoftwareConfig

THIS_DIR = os.path.dirname(__file__)

PROGRAM_CONFIG_FILE = fake_config.FAKE_PROGRAM_CONFIG
PROJECT_CONFIG_FILE = fake_config.FAKE_PROJECT_CONFIG


def fakeConfig():
  return cros_config_proto_converter._MergeConfigs([
      cros_config_proto_converter._ReadConfig(PROGRAM_CONFIG_FILE),
      cros_config_proto_converter._ReadConfig(PROJECT_CONFIG_FILE)
  ])


class ParseArgsTests(unittest.TestCase):

  def testParseArgs(self):
    argv = [
        '-c',
        'config1',
        'config2',
        '-p',
        'program_config',
        '-o',
        'output',
    ]
    args = cros_config_proto_converter.ParseArgs(argv)
    self.assertEqual(args.project_configs, [
        'config1',
        'config2',
    ])
    self.assertEqual(args.program_config, 'program_config')
    self.assertEqual(args.output, 'output')


class MainTest(unittest.TestCase):

  def testFullTransform(self):
    output_file = 'payload_utils/test_data/fake_project.json'
    cros_config_proto_converter.Main(
        project_configs=[PROJECT_CONFIG_FILE],
        program_config=PROGRAM_CONFIG_FILE,
        output=output_file,
    )

    changed = subprocess.run([
        'git', 'diff', '--exit-code', 'payload_utils/test_data'
    ]).returncode != 0

    if changed:
      msg = ('Fake project transform does not match.\n'
             'If the differences are correct per the changes in\n'
             'your changelist then check them in and try again.')
      self.fail(msg)


class TransformBuildConfigsTest(unittest.TestCase):

  def testMissingLookups(self):
    config = fakeConfig()
    config.ClearField('programs')

    with self.assertRaisesRegex(Exception, 'Failed to lookup Program'):
      cros_config_proto_converter._TransformBuildConfigs(config)

  def testMissingBuildTarget(self):
    config = fakeConfig()
    config.ClearField('build_targets')

    with self.assertRaisesRegex(Exception, 'Single build_target required'):
      cros_config_proto_converter._TransformBuildConfigs(config)

  def testMultipleBuildTarget(self):
    config = fakeConfig()
    duplicate_config = cros_config_proto_converter._MergeConfigs(
        [config, fakeConfig()])

    with self.assertRaisesRegex(Exception, 'Single build_target required'):
      cros_config_proto_converter._TransformBuildConfigs(duplicate_config)

  def testEmptyDeviceBrand(self):
    config = fakeConfig()
    config.ClearField('device_brands')
    # Signer configs tied to device brands, so need to clear that also
    config.programs.value[0].ClearField('device_signer_configs')

    self.assertIsNotNone(
        cros_config_proto_converter._TransformBuildConfigs(config))

  def testMissingSwConfig(self):
    config = fakeConfig()
    config.ClearField('software_configs')

    with self.assertRaisesRegex(Exception, 'Software config is required'):
      cros_config_proto_converter._TransformBuildConfigs(config)

  def testUniqueConfigsOnly(self):
    config = fakeConfig()
    # Get past multiple build_targets check first
    config.ClearField('build_targets')
    duplicate_config = cros_config_proto_converter._MergeConfigs(
        [config, fakeConfig()])

    with self.assertRaisesRegex(Exception, 'Multiple software configs'):
      cros_config_proto_converter._TransformBuildConfigs(duplicate_config)


if __name__ == '__main__':
  unittest.main(module=__name__)
