# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related the model_sku.json factory file."""

import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from checker import io_utils
from chromiumos.config.payload import config_bundle_pb2


class CheckModelSkuJsonConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related the model_sku.json factory file."""

    def check_model_present(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks that there is at least one model"""
        del program_config, project_config

        model_sku = io_utils.read_model_sku_json(factory_dir=factory_dir)
        self.assertTrue(
            model_sku.get("model"),
            "'model' must be present and have at least one item.",
        )
