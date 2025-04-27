# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Test for Hwid merging plugin"""

import unittest

from chromiumos.config.api.component_pb2 import Component
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle

from .merge_hwid import _set_support_status
from .merge_hwid import MergeHwid


def _mock_hwid_component(type_name, label, values):
    return {
        "components": {
            type_name: {
                "items": {
                    label: {"values": values},
                },
            },
        },
    }


class MergeHWidTests(unittest.TestCase):
    """Tests for MergeHwid plugin."""

    # pylint: disable=too-many-public-methods

    def test_support_status(self):
        """Test the _set_support_status functionality."""
        bundle = ConfigBundle()

        # With no status information, our support status should be unknown.
        component = bundle.components.add()
        component = _set_support_status(component, {})
        self.assertEqual(
            component.support_status,
            component.SupportStatus.STATUS_UNKNOWN,
        )

        # A known status should get reflected into component.
        component = bundle.components.add()
        component = _set_support_status(component, {"status": "supported"})
        self.assertEqual(
            component.support_status,
            component.SupportStatus.STATUS_SUPPORTED,
        )

        # An unknown status value should _not_ get reflected into component.
        component = bundle.components.add()
        component = _set_support_status(component, {"status": "fooble"})
        self.assertEqual(
            component.support_status,
            component.SupportStatus.STATUS_UNKNOWN,
        )

    def test_audio_codec(self):
        """Test basic audio codec functionality."""
        test_label = "ACLABEL123"
        test_name = "ACLABEL:123"

        hwid = _mock_hwid_component(
            "audio_codec",
            test_label,
            {"name": test_name},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "audio_codec")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.name, test_name)
        self.assertEqual(component.audio_codec.name, test_name)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_battery(self):
        """Test basic battery functionality."""
        test_label = "battery123"
        test_oem = "conglomo"
        test_model = "battery-123-abc"
        test_tech = "li-poly"

        hwid = _mock_hwid_component(
            "battery",
            test_label,
            {
                "manufacturer": test_oem,
                "model_name": test_model,
                "technology": test_tech,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "battery")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.manufacturer_id.value, test_oem)
        self.assertEqual(component.battery.model, test_model)
        self.assertEqual(
            component.battery.technology, Component.Battery.LI_POLY
        )

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_bluetooth(self):
        """Test basic bluetooth functionality."""
        test_label = "bluetooth123"
        test_vendor = "vendor"
        test_product = "product"
        test_bcd = "bcd"

        hwid = _mock_hwid_component(
            "bluetooth",
            test_label,
            {
                "idVendor": test_vendor,
                "idProduct": test_product,
                "bcdDevice": test_bcd,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "bluetooth")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.bluetooth.usb.vendor_id, test_vendor)
        self.assertEqual(component.bluetooth.usb.product_id, test_product)
        self.assertEqual(component.bluetooth.usb.bcd_device, test_bcd)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_cellular(self):
        """Test basic cellular functionality."""
        test_label = "cellular123"
        test_vendor = "vendor"
        test_product = "product"
        test_bcd = "bcd"

        hwid = _mock_hwid_component(
            "cellular",
            test_label,
            {
                "idVendor": test_vendor,
                "idProduct": test_product,
                "bcdDevice": test_bcd,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "cellular")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.cellular.usb.vendor_id, test_vendor)
        self.assertEqual(component.cellular.usb.product_id, test_product)
        self.assertEqual(component.cellular.usb.bcd_device, test_bcd)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_cpu(self):
        """Test basic cpu functionality."""
        test_label = "some_cpu_123"
        test_model = "intel i3-5005U"
        test_cores = 4

        hwid = _mock_hwid_component(
            "cpu",
            test_label,
            {
                "model": test_model,
                "cores": test_cores,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "cpu")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.soc.family.arch, component.soc.X86_64)
        self.assertEqual(component.soc.cores, 4)
        self.assertEqual(component.soc.family.name, "I3-5005U")

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_cpu_nocores(self):
        """Test cpu entry without cores field."""
        test_label = "some_cpu_123"
        test_model = "intel i3-5005U"

        hwid = _mock_hwid_component(
            "cpu",
            test_label,
            {
                "model": test_model,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "cpu")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.soc.cores, 0)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_display_panel(self):
        """Test basic display panel functionality."""
        test_label = "some_cpu_123"
        test_vendor = "ABCCo"
        test_product_id = "panel_1a_niner"
        test_width = 800
        test_height = 480

        hwid = _mock_hwid_component(
            "display_panel",
            test_label,
            {
                "vendor": test_vendor,
                "product_id": test_product_id,
                "width": test_width,
                "height": test_height,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "display_panel")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.id.value, test_label)
        self.assertEqual(component.manufacturer_id.value, test_vendor)
        self.assertEqual(component.display_panel.product_id, test_product_id)
        self.assertEqual(
            component.display_panel.properties.width_px, test_width
        )
        self.assertEqual(
            component.display_panel.properties.height_px, test_height
        )

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_dram(self):
        """Test basic display panel functionality."""
        test_label = "some_dram_123abc_0"
        test_part = "1234abcd"
        test_size = 2048

        test_timings = [
            ("LPDDR4", Component.Memory.LP_DDR4),
            ("LPDDR3", Component.Memory.LP_DDR3),
            ("DDR4", Component.Memory.DDR4),
            ("DDR3", Component.Memory.DDR3),
            ("DDR2", Component.Memory.DDR2),
            ("DDR", Component.Memory.DDR),
        ]

        for memory_timing, memory_type in test_timings:
            hwid = _mock_hwid_component(
                "dram",
                test_label,
                {
                    "part": test_part,
                    "size": str(test_size),
                    "timing": memory_timing,
                },
            )

            bundle = ConfigBundle()
            merger = MergeHwid(hwid_data=hwid)
            merger.merge(bundle)

            self.assertEqual(len(bundle.components), 1)
            component = bundle.components[0]
            self.assertEqual(component.hwid_type, "dram")
            self.assertEqual(component.hwid_label, test_label)
            self.assertEqual(component.id.value, test_label)
            self.assertEqual(component.memory.part_number, test_part)
            self.assertEqual(component.memory.profile.size_megabytes, test_size)
            self.assertEqual(component.memory.profile.type, memory_type)

            # Should be nothing unparsed
            self.assertEqual(merger.residual(), {})

    def test_ec_flash(self):
        """Test basic ec_flash functionality."""
        test_label = "some_flash_chip_123abc"
        test_part = "1234abcd"
        test_vendor = "TestVendorCo"

        hwid = _mock_hwid_component(
            "ec_flash_chip",
            test_label,
            {"name": test_part, "vendor": test_vendor},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "ec_flash_chip")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.ec_flash_chip.part_number, test_part)
        self.assertEqual(component.manufacturer_id.value, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_ec(self):
        """Test basic ec functionality."""
        test_label = "some_ec_123abc"
        test_part = "1234abcd"
        test_vendor = "TestVendorCo"

        hwid = _mock_hwid_component(
            "embedded_controller",
            test_label,
            {"name": test_part, "vendor": test_vendor},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "embedded_controller")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.ec.part_number, test_part)
        self.assertEqual(component.manufacturer_id.value, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_flash(self):
        """Test basic flash functionality."""
        test_label = "some_flash_123abc"
        test_part = "1234abcd"
        test_vendor = "TestVendorCo"

        hwid = _mock_hwid_component(
            "flash_chip",
            test_label,
            {"name": test_part, "vendor": test_vendor},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "flash_chip")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.system_flash_chip.part_number, test_part)
        self.assertEqual(component.manufacturer_id.value, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_storage(self):
        """Test basic storage functionality."""
        test_label = "some_storage_123abc"
        test_emmc5 = "1.2.3"
        test_manfid = "manfid"
        test_name = "Name"
        test_oemid = "oemid"
        test_prv = "prv"
        test_sectors = "sectors"
        test_type = "MMC"

        hwid = _mock_hwid_component(
            "storage",
            test_label,
            {
                "emmc5_fw_ver": test_emmc5,
                "manfid": test_manfid,
                "name": test_name,
                "oemid": test_oemid,
                "prv": test_prv,
                "sectors": test_sectors,
                "type": test_type,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "storage")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.storage.emmc5_fw_ver, test_emmc5)
        self.assertEqual(component.storage.manfid, test_manfid)
        self.assertEqual(component.storage.name, test_name)
        self.assertEqual(component.storage.oemid, test_oemid)
        self.assertEqual(component.storage.prv, test_prv)
        self.assertEqual(component.storage.sectors, test_sectors)
        self.assertEqual(component.storage.type, Component.Storage.EMMC)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_stylus_i2c(self):
        """Test stylus I2C functionality."""
        test_label = "some_touch_123abc"
        test_vendor = "0x1234"
        test_product = "0xbeef"

        hwid = _mock_hwid_component(
            "stylus",
            test_label,
            {
                "vendor": test_vendor,
                "product": test_product,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "stylus")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.stylus.i2c.product, test_product)
        self.assertEqual(component.stylus.i2c.vendor, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_stylus_usb(self):
        """Test stylus USB functionality."""
        test_label = "some_touch_123abc"
        test_vendorid = "0x1234"
        test_productid = "0xbeef"
        test_bcd_device = "bcd"

        hwid = _mock_hwid_component(
            "stylus",
            test_label,
            {
                "vendor_id": test_vendorid,
                "product_id": test_productid,
                "bcd_device": test_bcd_device,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "stylus")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.stylus.usb.product_id, test_productid)
        self.assertEqual(component.stylus.usb.vendor_id, test_vendorid)
        self.assertEqual(component.stylus.usb.bcd_device, test_bcd_device)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_touchpad_usb(self):
        """Test touchpad USB functionality."""
        test_label = "some_touchpad_123abc"
        test_product = "product"
        test_vendor = "vendor"

        hwid = _mock_hwid_component(
            "touchpad",
            test_label,
            {
                "product": test_product,
                "vendor": test_vendor,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "touchpad")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.touchpad.type, Component.Touch.USB)
        self.assertEqual(component.touchpad.usb.product_id, test_product)
        self.assertEqual(component.touchpad.usb.vendor_id, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_touchpad_i2c(self):
        """Test touchpad I2C functionality."""
        test_label = "some_touchpad_123abc"
        test_fw_version = "1.2.3"
        test_fw_csum = "csum"

        hwid = _mock_hwid_component(
            "touchpad",
            test_label,
            {"fw_version": test_fw_version, "fw_csum": test_fw_csum},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "touchpad")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.touchpad.type, Component.Touch.I2C)
        self.assertEqual(component.touchpad.fw_version, test_fw_version)
        self.assertEqual(component.touchpad.fw_checksum, test_fw_csum)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_tpm(self):
        """Test tpm functionality."""
        test_label = "some_tpm_123abc"
        test_mfg_info = "TPMCo"
        test_version = "1.2.3"

        hwid = _mock_hwid_component(
            "tpm",
            test_label,
            {"manufacturer_info": test_mfg_info, "version": test_version},
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "tpm")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.tpm.manufacturer_info, test_mfg_info)
        self.assertEqual(component.tpm.version, test_version)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_touchscreen(self):
        """Test touchscreen functionality."""
        test_label = "some_touch_123abc"
        test_vendor = "0x1234"
        test_product = "0xbeef"

        hwid = _mock_hwid_component(
            "touchscreen",
            test_label,
            {
                "vendor": test_vendor,
                "product": test_product,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "touchscreen")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.touchscreen.usb.product_id, test_product)
        self.assertEqual(component.touchscreen.usb.vendor_id, test_vendor)
        self.assertEqual(component.touchscreen.type, Component.Touch.USB)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_usb_hosts(self):
        """Test USB hosts functionality."""
        test_label = "some_touch_123abc"
        test_mfg = "ChipCo"
        test_device = "0x1234"
        test_vendor = "0xabcd"
        test_revision = "123"

        hwid = _mock_hwid_component(
            "usb_hosts",
            test_label,
            {
                "manufacturer": test_mfg,
                "device": test_device,
                "vendor": test_vendor,
                "revision_id": test_revision,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "usb_hosts")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.manufacturer_id.value, test_mfg)
        self.assertEqual(component.usb_host.product_id, test_device)
        self.assertEqual(component.usb_host.vendor_id, test_vendor)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_video_usb(self):
        """Test USB video functionality."""
        test_label = "some_touch_123abc"
        test_product = "0x1234"
        test_vendor = "0xabcd"
        test_bcd = "12"

        hwid = _mock_hwid_component(
            "video",
            test_label,
            {
                "bus_type": "usb",
                "idProduct": test_product,
                "idVendor": test_vendor,
                "bcdDevice": test_bcd,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "video")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.camera.usb.product_id, test_product)
        self.assertEqual(component.camera.usb.vendor_id, test_vendor)
        self.assertEqual(component.camera.usb.bcd_device, test_bcd)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_video_pci(self):
        """Test PCI video functionality."""
        test_label = "some_touch_123abc"
        test_vendor = "0xabcd"
        test_device = "0x1234"
        test_revision = "12"

        hwid = _mock_hwid_component(
            "video",
            test_label,
            {
                "bus_type": "pci",
                "vendor": test_vendor,
                "device": test_device,
                "revision_id": test_revision,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "video")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.camera.pci.vendor_id, test_vendor)
        self.assertEqual(component.camera.pci.device_id, test_device)
        self.assertEqual(component.camera.pci.revision_id, test_revision)

        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})

    def test_wireless(self):
        """Test wireless functionality."""
        test_label = "some_touch_123abc"
        test_vendor = "0xabcd"
        test_device = "0x1234"
        test_revision = "12"

        hwid = _mock_hwid_component(
            "wireless",
            test_label,
            {
                "vendor": test_vendor,
                "device": test_device,
                "revision_id": test_revision,
            },
        )

        bundle = ConfigBundle()
        merger = MergeHwid(hwid_data=hwid)
        merger.merge(bundle)

        self.assertEqual(len(bundle.components), 1)
        component = bundle.components[0]
        self.assertEqual(component.hwid_type, "wireless")
        self.assertEqual(component.hwid_label, test_label)
        self.assertEqual(component.wifi.pci.vendor_id, test_vendor)
        self.assertEqual(component.wifi.pci.device_id, test_device)
        self.assertEqual(component.wifi.pci.revision_id, test_revision)
        # Should be nothing unparsed
        self.assertEqual(merger.residual(), {})
