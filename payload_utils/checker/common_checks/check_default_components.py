# Copyright 2026 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to default components."""

import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.payload import config_bundle_pb2


class DefaultComponentConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks for default components."""

    def check_single_default_per_type(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks that at most one component of each type has default=True."""
        del program_config, factory_dir

        hal_config = project_config.android_hal_config

        for field in hal_config.DESCRIPTOR.fields:
            component_list = getattr(hal_config, field.name)
            if not component_list:
                continue

            default_count = 0
            for component in component_list:
                if getattr(component, "default", False):
                    default_count += 1

            self.assertLessEqual(
                default_count,
                1,
                f"Multiple components of type '{field.name}' have default=True. "
                f"Count: {default_count}. Only at most one is allowed.",
            )
