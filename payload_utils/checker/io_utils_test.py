# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for io_utils."""

import json
import os
import pathlib
import tempfile
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import io_utils
from chromiumos.config.api.program_pb2 import Program
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle
from common import config_bundle_utils
from google.protobuf import json_format


class IoUtilsTest(unittest.TestCase):
    """Tests for io_utils."""

    def setUp(self):
        self.config = ConfigBundle(program_list=[Program(name="TestProgram1")])
        self.flat_config = config_bundle_utils.flatten_config(self.config)
        repo_path = tempfile.mkdtemp()

        os.mkdir(os.path.join(repo_path, "generated"))

        self.config_path = os.path.join(
            repo_path, "generated", "config.jsonproto"
        )
        json_output = json_format.MessageToJson(
            self.config, sort_keys=True, use_integers_for_enums=True
        )
        with open(self.config_path, "w", encoding="utf-8") as f:
            print(json_output, file=f)

        self.flat_config_path = os.path.join(
            repo_path, "generated", "flattened.jsonproto"
        )
        json_output = json_format.MessageToJson(
            self.flat_config, sort_keys=True, use_integers_for_enums=True
        )
        with open(self.flat_config_path, "w", encoding="utf-8") as f:
            print(json_output, file=f)

        self.factory_path = os.path.join(repo_path, "factory")
        os.makedirs(os.path.join(self.factory_path, "generated"))
        self.model_sku = {"model": {"a": 1}}
        with open(
            os.path.join(self.factory_path, "generated", "model_sku.json"),
            "w",
            encoding="utf-8",
        ) as f:
            json.dump(self.model_sku, f)

    def test_read_config(self):
        """Tests the json proto can be read."""
        self.assertEqual(io_utils.read_config(self.config_path), self.config)

    def test_read_flat_config(self):
        """Tests the json proto can be read."""
        self.assertEqual(
            io_utils.read_flat_config(self.flat_config_path), self.flat_config
        )

    def test_read_model_sku_json(self):
        """Tests model_sku.json can be read."""
        self.assertDictEqual(
            io_utils.read_model_sku_json(pathlib.Path(self.factory_path)),
            self.model_sku,
        )
