# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for check_model_sku_json."""

import json
import os
import pathlib
import tempfile
import unittest

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker.common_checks.check_model_sku_json import (
    CheckModelSkuJsonConstraintSuite,
)


class CheckModelSkuTest(unittest.TestCase):
    """Tests for check_model_sku_json."""

    def setUp(self):
        self.factory_dir = pathlib.Path(tempfile.mkdtemp())

        generated_dir = self.factory_dir / "generated"
        os.mkdir(generated_dir)

        model_sku = {
            "model": [
                {
                    "milkyway": {
                        "component.audio_card_name": "audiocard1",
                        "component.has_front_camera": True,
                        "component.has_lte": None,
                    }
                }
            ]
        }

        with open(generated_dir / "model_sku.json", "w", encoding="utf-8") as f:
            json.dump(model_sku, f)

    def test_check_model_present(self):
        """Tests check_model_present with valid configs."""
        CheckModelSkuJsonConstraintSuite().check_model_present(
            program_config=None,
            project_config=None,
            factory_dir=self.factory_dir,
        )

    def test_check_model_present_violated(self):
        """Tests check_model_present with invalid configs."""

        with open(
            self.factory_dir / "generated" / "model_sku.json",
            "w",
            encoding="utf-8",
        ) as f:
            json.dump({"a": 1}, f)

        with self.assertRaisesRegex(
            AssertionError,
            "'model' must be present and have at least one item.",
        ):
            CheckModelSkuJsonConstraintSuite().check_model_present(
                program_config=None,
                project_config=None,
                factory_dir=self.factory_dir,
            )
