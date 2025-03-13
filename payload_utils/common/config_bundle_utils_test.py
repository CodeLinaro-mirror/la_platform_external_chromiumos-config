# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for proto_utils."""

import unittest

from chromiumos.config.payload import config_bundle_pb2
from common import config_bundle_utils


class ConfigBundleUtilsTest(unittest.TestCase):
    """Tests for config_bundle_utils."""

    def test_find_program(self):
        """Test the find_program method."""
        empty = config_bundle_pb2.ConfigBundle()
        bundle = config_bundle_pb2.ConfigBundle()
        program = bundle.program_list.add()
        program.name = "TestProgram"
        program.id.value = "TestProgram"

        self.assertIsNone(
            config_bundle_utils.find_program(empty, "TestProgram")
        )
        self.assertEqual(
            config_bundle_utils.find_program(empty, "TestProgram", create=True),
            program,
        )
        self.assertEqual(
            config_bundle_utils.find_program(empty, "TestProgram"), program
        )

        self.assertEqual(
            config_bundle_utils.find_program(bundle, "TestProgram"), program
        )
        self.assertEqual(
            config_bundle_utils.find_program(bundle, "testprogram"), program
        )
        self.assertIsNone(
            config_bundle_utils.find_program(bundle, "does_not_exist")
        )

    def test_find_partner(self):
        """Test the find_partner method."""
        empty = config_bundle_pb2.ConfigBundle()
        bundle = config_bundle_pb2.ConfigBundle()
        partner = bundle.partner_list.add()
        partner.name = "TestPartner"
        partner.id.value = "TestPartner"

        self.assertIsNone(
            config_bundle_utils.find_partner(empty, "TestPartner")
        )
        self.assertEqual(
            config_bundle_utils.find_partner(empty, "TestPartner", create=True),
            partner,
        )

        # Now that we called with create=True, we should find it in the bundle
        self.assertEqual(
            config_bundle_utils.find_partner(empty, "TestPartner"), partner
        )

        self.assertEqual(
            config_bundle_utils.find_partner(bundle, "TestPartner"), partner
        )
        self.assertEqual(
            config_bundle_utils.find_partner(bundle, "testpartner"), partner
        )
        self.assertIsNone(
            config_bundle_utils.find_partner(bundle, "does_not_exist")
        )

    def test_find_component(self):
        """Test the find_component method."""
        empty = config_bundle_pb2.ConfigBundle()
        bundle = config_bundle_pb2.ConfigBundle()
        component = bundle.components.add()
        component.id.value = "TestComponent"

        self.assertIsNone(
            config_bundle_utils.find_component(empty, "TestComponent")
        )
        self.assertEqual(
            config_bundle_utils.find_component(
                empty, "TestComponent", create=True
            ),
            component,
        )

        # Now that we called with create=True, we should find it in the bundle
        self.assertEqual(
            config_bundle_utils.find_component(empty, "TestComponent"),
            component,
        )

        self.assertEqual(
            config_bundle_utils.find_component(bundle, "TestComponent"),
            component,
        )
        self.assertEqual(
            config_bundle_utils.find_component(bundle, "testcomponent"),
            component,
        )
        self.assertIsNone(
            config_bundle_utils.find_component(bundle, "does_not_exist")
        )

    def test_flatten_config(self):
        """Test flattening ConfigBundle"""

        # Build a dummy test bundle config
        bundle = config_bundle_pb2.ConfigBundle()

        program = bundle.program_list.add()
        program.name = "A Program"
        program.id.value = "a_program"

        partner_0 = bundle.partner_list.add()
        partner_0.name = "Partner 0"
        partner_0.id.value = "partner_0"

        partner_1 = bundle.partner_list.add()
        partner_1.name = "Partner 1"
        partner_1.id.value = "partner_1"

        hw_design = bundle.design_list.add()
        hw_design.name = "A Design"
        hw_design.id.value = "a_design"
        hw_design.program_id.MergeFrom(program.id)
        hw_design.odm_id.MergeFrom(partner_0.id)

        hw_design_config = hw_design.configs.add()
        hw_design_config.id.value = "a_design_config"

        sw_config = bundle.software_configs.add()
        sw_config.design_config_id.MergeFrom(hw_design_config.id)

        device_brand = bundle.device_brand_list.add()
        device_brand.brand_name = "A Brand"
        device_brand.id.value = "a_brand"
        device_brand.design_id.MergeFrom(hw_design.id)
        device_brand.oem_id.MergeFrom(partner_1.id)

        brand_config = bundle.brand_configs.add()
        brand_config.brand_id.MergeFrom(device_brand.id)

        # Flatten config bundle into a FlatConfigList
        flattened = config_bundle_utils.flatten_config(bundle)
        self.assertEqual(len(flattened.values), 1)

        # And verify that values were queried correctly
        flat_value = flattened.values[0]
        self.assertEqual(flat_value.program, program)
        self.assertEqual(flat_value.hw_design, hw_design)
        self.assertEqual(flat_value.odm, partner_0)
        self.assertEqual(flat_value.hw_design_config, hw_design_config)
        self.assertEqual(flat_value.device_brand, device_brand)
        self.assertEqual(flat_value.oem, partner_1)
        self.assertEqual(flat_value.brand_sw_config, brand_config)
