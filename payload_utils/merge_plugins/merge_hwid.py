# -*- coding: utf-8 -*-
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Plugin for merging HWID information into ConfigBundle format"""

import copy
import logging as _logging
import re
import yaml

from chromiumos.config.api.component_pb2 import Component
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle

from common import config_bundle_utils as cbu
from .merge_plugin import MergePlugin

# Create named logger
logging = _logging.getLogger(__name__)


def _include_item(item):
  """Predicate to determine whether to include a HWID item.

  Modify this to add additional exclusion conditions.
  """

  # Status values that indicate we should exclude the item
  bad_status_values = set([
      'unsupported',
  ])

  if not item['values']:
    return False

  if item.get('status', '').lower() in bad_status_values:
    return False

  return True


def _maybe_delete(val, key):
  """Delete key from dict, but degrade to noop if it's not present."""
  if key in val:
    del val[key]


def _del_if_empty(val, key):
  """Delete a key from a dict if it's empty"""
  if key in val and not val[key]:
    del val[key]


def _non_null_items(items):
  """Unwrap a HWID item block into a dictionary for non-null values.

  a HWID item block looks like:
    items:
      storage_device:
        status: unsupported
        values:
          class: '0x010101'
          device: '0xff00'
          sectors: '5000000'
          vendor: '0xbeef'
      some_hardware:
         values:
      FAKE_RAM_CHIP:
        values:
          class: '0x010101'
          device: '0xff00'
          sectors: '250000000'
          vendor: '0xabcd'

  We'll iterate over the items and check whether it should be excluded
  based on _include_item.

  The resulting output is a dict with unwrapped item values:
    {
      'storage_device': {'class' : '0x010101', ...},
      ...
    }
  """
  return {
      key: item['values'] for key, item in items.items() if _include_item(item)
  }


class MergeHwid(MergePlugin):
  """Merge plugin for HWID files.

  After calling merge(), residual() can be called to get an object containing
  any remaining values in the HWID data.
  """

  def __init__(self, hwid_path=None, hwid_data=None):
    """Create a new HWID merger.

    Args:
      hwid_path (str): Path to the HWID file on disk to read
      hwid_data (dict): HWID data specified directly
    """

    if hwid_path and hwid_data:
      raise RuntimeError('Only one of hwid_path or hwid_data can be specified')

    if hwid_path:
      with open(hwid_path) as hwid_file:
        self.data = yaml.load(hwid_file, Loader=yaml.FullLoader)
    else:
      self.data = copy.deepcopy(hwid_data)

  def residual(self):
    """Get any remaining data that hasn't been parsed."""
    return self.data

  def merge(self, bundle: ConfigBundle):
    """Merge our data into the given ConfigBundle instance."""
    components = self.data['components']
    for component_type in list(components.keys()):
      value = components[component_type]
      if not value:
        continue

      # yapf: disable
      callback = {
        'audio_codec':         MergeHwid._merge_audio,
        'battery':             MergeHwid._merge_battery,
        'bluetooth':           MergeHwid._merge_bluetooth,
        'cpu':                 MergeHwid._merge_cpu,
        'display_panel':       MergeHwid._merge_display_panel,
        'dram':                MergeHwid._merge_dram,
        'ec_flash_chip':       MergeHwid._merge_ec_flash,
        'embedded_controller': MergeHwid._merge_ec,
        'flash_chip':          MergeHwid._merge_flash,
        'storage':             MergeHwid._merge_storage,
        'stylus':              MergeHwid._merge_stylus,
        'touchpad':            MergeHwid._merge_touchpad,
        'tpm':                 MergeHwid._merge_tpm,
        'touchscreen':         MergeHwid._merge_touchscreen,
        'usb_hosts':           MergeHwid._merge_usb_hosts,
        'video':               MergeHwid._merge_video,
        'wireless':            MergeHwid._merge_wireless,
      }.get(component_type)
      # yapf: enable

      if callback:
        value['items'] = _non_null_items(value['items'])
        MergeHwid._iterate_items(bundle, value['items'], callback)

        _del_if_empty(value, 'items')
        _del_if_empty(components, component_type)

    _del_if_empty(self.data, 'components')

  @staticmethod
  def _iterate_items(bundle, items, callback):
    """Iterate items in an item dict and call callback on them.

    Handle boilerplate for callbacks to delete empty/touched
    fields as we go to leave an informative residual.

    Callbacks must take a ConfigBundle and an item and return
    an iterable of fields in the item that were touched/used.

    Args:
      bundle: ConfigBundle instance to modify
      items:  dict of label => [item]
      callback: callback to process a single item.
    """

    for label in list(items.keys()):
      values = items[label]
      touched = callback(bundle, label, values)

      for name in touched:
        _maybe_delete(values, name)
      _del_if_empty(items, label)

  @staticmethod
  def _merge_audio(bundle, label, values):
    """Merge audio_codec items."""
    component = cbu.find_component(bundle, id_value=label, create=True)

    # save HWID values
    component.hwid_type = 'audio_codec'
    component.hwid_label = label

    # configure component
    component.name = values.get('name', label)
    component.audio_codec.name = component.name

    return ['name']

  @staticmethod
  def _merge_battery(bundle, label, values):
    """Merge battery items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'battery'
    component.hwid_label = label

    # lookup or create manufacturer
    if 'manufacturer' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['manufacturer'], create=True).id)
      touched.add('manufacturer')

    # set model
    if 'model_name' in values:
      component.battery.model = values['model_name']
      touched.add('model_name')

    # set battery technology
    if 'technology' in values:
      tech = values['technology'].lower().replace('-', '')

      tech_map = {
          'liion': Component.Battery.LI_ION,
          'lipoly': Component.Battery.LI_POLY,
      }

      if tech in tech_map:
        component.battery.technology = tech_map[tech]
        touched.add('technology')

    return touched

  @staticmethod
  def _merge_bluetooth(bundle, label, values):
    """Merge bluetooth items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'bluetooth'
    component.hwid_label = label

    # lookup or create manufacturer
    if 'manufacturer' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['manufacturer'], create=True).id)
      touched.add('manufacturer')

    fields = [
        ('vendor_id', 'idVendor'),
        ('product_id', 'idProduct'),
        ('bcd_device', 'bcdDevice'),
    ]

    for attr, key in fields:
      if key in values:
        setattr(component.bluetooth.usb, attr, values[key])
        touched.add(key)

    return touched

  @staticmethod
  def _merge_cpu(bundle, label, values):
    """Merge cpu items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'cpu'
    component.hwid_label = label

    model_re = re.compile(  # reversed from HWID cpu model values
        '(a[0-9]?-[0-9]+[a-z]?|(m3-|i3-|i5-|i7-)*[0-9y]{4,5}[uy]?|n[0-9]{4})')

    component.soc.cores = int(values.get('cores', 0))
    touched.add('cores')

    if 'model' in values:
      component.soc.model = values['model']
      touched.add('model')

      model_string = values['model'].lower()
      if 'intel' in model_string or 'amd' in model_string:
        component.soc.family.arch = component.soc.X86_64
      elif 'aarch64' in model_string or 'armv8' in model_string:
        component.soc.family.arch = component.soc.ARM64
      elif 'armv7' in model_string:
        component.soc.family.arch = component.soc.ARM
      else:
        logging.warning('unknown family for cpu model \'%s\'', model_string)

      match = model_re.search(model_string)
      if match:
        component.soc.family.name = match.group(0).upper()

    return touched

  @staticmethod
  def _merge_display_panel(bundle, label, values):
    """Merge display panel items."""
    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'display_panel'
    component.hwid_label = label

    if 'vendor' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['vendor'], create=True).id)

    component.display_panel.product_id = values.get('product_id', '')
    component.display_panel.properties.width_px = int(values.get('width', 0))
    component.display_panel.properties.height_px = int(values.get('height', 0))

    return set(['vendor', 'product_id', 'width', 'height'])

  @staticmethod
  def _merge_dram(bundle, label, values):
    """Merge dram items."""
    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'dram'
    component.hwid_label = label

    component.memory.part_number = values.get('part', '')
    component.memory.profile.size_megabytes = int(values.get('size', 0))

    if 'timing' in values:
      memory_type = values['timing'].split('-')[0]
      if memory_type == 'LPDDR4':
        component.memory.profile.type = component.memory.LP_DDR4
      elif memory_type == 'LPDDR3':
        component.memory.profile.type = component.memory.LP_DDR3
      elif memory_type == 'DDR4':
        component.memory.profile.type = component.memory.DDR4
      elif memory_type == 'DDR3':
        component.memory.profile.type = component.memory.DDR3
      elif memory_type == 'DDR2':
        component.memory.profile.type = component.memory.DDR2
      elif memory_type == 'DDR':
        component.memory.profile.type = component.memory.DDR

    return set(['part', 'size', 'timing'])

  @staticmethod
  def _merge_ec_flash(bundle, label, values):
    """Merge EC flash items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'ec_flash_chip'
    component.hwid_label = label

    component.ec_flash_chip.part_number = values.get('name', '')
    touched.add('name')

    if 'vendor' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['vendor'], create=True).id)
      touched.add('vendor')

    return touched

  @staticmethod
  def _merge_ec(bundle, label, values):
    """Merge EC items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'embedded_controller'
    component.hwid_label = label

    component.ec.part_number = values.get('name', '')
    touched.add('name')

    if 'vendor' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['vendor'], create=True).id)
      touched.add('vendor')

    return touched

  @staticmethod
  def _merge_flash(bundle, label, values):
    """Merge flash items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = component.id.value

    # save HWID values
    component.hwid_type = 'flash_chip'
    component.hwid_label = label

    component.system_flash_chip.part_number = values.get('name', '')
    touched.add('name')

    if 'vendor' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['vendor'], create=True).id)
      touched.add('vendor')

    return touched

  @staticmethod
  def _merge_storage(bundle, label, values):
    """Merge storage items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('model', label)
    touched.add('model')

    # save HWID values
    component.hwid_type = 'storage'
    component.hwid_label = label

    component.storage.emmc5_fw_ver = values.get('emmc5_fw_ver', '')
    component.storage.manfid = values.get('manfid', '')
    component.storage.name = values.get('name', '')
    component.storage.oemid = values.get('oemid', '')
    component.storage.prv = values.get('prv', '')
    component.storage.sectors = values.get('sectors', '')

    touched.update(
        ['emmc5_fw_ver', 'manfid', 'name', 'oemid', 'prv', 'sectors'])

    if values.get('type', '').lower() == 'mmc':
      component.storage.type = component.storage.EMMC
    touched.add('type')

    if values.get('vendor', '').lower() == 'ata':
      component.storage.type = component.storage.SATA
    touched.add('vendor')

    return touched

  @staticmethod
  def _merge_stylus(bundle, label, values):
    """Merge stylus items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('name', label)
    touched.add('name')

    # save HWID values
    component.hwid_type = 'stylus'
    component.hwid_label = label

    i2c_keys = ['product', 'vendor']
    if all(key in values for key in i2c_keys):
      component.stylus.i2c.product = values['product']
      component.stylus.i2c.vendor = values['vendor']
      touched.update(i2c_keys)

    usb_keys = ['product_id', 'vendor_id']
    if all(key in values for key in usb_keys):
      component.stylus.usb.product_id = values['product_id']
      component.stylus.usb.vendor_id = values['vendor_id']
      touched.update(usb_keys)

      if 'bcd_device' in values:
        component.stylus.usb.bcd_device = values['bcd_device']
      touched.add('bcd_device')

      if 'version' in values:
        component.stylus.usb.bcd_device = values['version']
      touched.add('version')

    return touched

  @staticmethod
  def _merge_touchpad(bundle, label, values):
    """Merge touchpad items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('model', label)
    touched.add('model')

    # save HWID values
    component.hwid_type = 'touchpad'
    component.hwid_label = label

    # Check for USB based touchpad
    # We don't receive an explicit type for the touchpad bus type, so
    # we assume that if we have a product and vendor id, that it's USB,
    # otherwise it's I2C (rare)
    if 'product' in values and 'vendor' in values:
      component.touchpad.type = component.touchpad.USB
      component.touchpad.product_id = component.name
      component.touchpad.usb.vendor_id = values['vendor']
      component.touchpad.usb.product_id = values['product']
      touched.update(['vendor', 'product'])

    elif 'fw_version' in values and 'fw_csum' in values:
      # i2c based touchpad
      component.touchpad.type = component.touchpad.I2C
      component.touchpad.product_id = values.get('product_id', '')
      component.touchpad.fw_version = values['fw_version']
      component.touchpad.fw_checksum = values['fw_csum']
      touched.update(['fw_version', 'fw_csum', 'product_id'])

    return touched

  @staticmethod
  def _merge_tpm(bundle, label, values):
    """Merge tpm items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = label

    # save HWID values
    component.hwid_type = 'tpm'
    component.hwid_label = label

    component.tpm.manufacturer_info = values.get('manufacturer_info', '')
    component.tpm.version = values.get('version', '')

    touched.update(['manufacturer_info', 'version'])
    return touched

  @staticmethod
  def _merge_touchscreen(bundle, label, values):
    """Merge touchscreen items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('name', label)
    touched.add('name')

    # save HWID values
    component.hwid_type = 'touchscreen'
    component.hwid_label = label

    def oneof(values, keys, default=""):
      for key in keys:
        if key in values:
          return values[key]
      return default

    component.touchscreen.product_id = label
    component.touchscreen.usb.product_id = oneof(
        values,
        ['product', 'product_id'],
    )
    component.touchscreen.usb.vendor_id = oneof(values, ['vendor', 'vendor_id'])
    component.touchscreen.usb.bcd_device = values.get('bcd_device', '')

    if all([
        component.touchscreen.usb.product_id,
        component.touchscreen.usb.vendor_id
    ]):
      component.touchscreen.type = component.touchscreen.USB

    touched.update(
        ['product', 'product_id', 'vendor', 'vendor_id', 'bcd_device'])
    return touched

  @staticmethod
  def _merge_usb_hosts(bundle, label, values):
    """Merge USB host items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('product', label)
    touched.add('product')

    # save HWID values
    component.hwid_type = 'usb_hosts'
    component.hwid_label = label

    def get_oneof(obj, keys, default=None):
      """Get one of a set of keys from values, or return a default value."""
      for key in keys:
        if key in obj:
          touched.add(key)
          return obj[key]
      return default

    if 'manufacturer' in values:
      component.manufacturer_id.MergeFrom(
          cbu.find_partner(bundle, values['manufacturer'], create=True).id)
      touched.add('manufacturer')

    host = component.usb_host
    host.product_id = get_oneof(values, ['idProduct', 'device'], '')
    host.vendor_id = get_oneof(values, ['idVendor', 'vendor'], '')
    host.bcd_device = get_oneof(values, ['bcdDevice', 'revision_id'], '')

    return touched

  @staticmethod
  def _merge_video(bundle, label, values):
    """Merge video items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = values.get('product', label)
    touched.add('product')

    # save HWID values
    component.hwid_type = 'video'
    component.hwid_label = label

    usb_fields = ['bcdDevice', 'idProduct', 'idVendor']
    pci_fields = ['vendor', 'device', 'revision_id']

    if values.get('bus_type') == 'usb' or \
       all(key in values for key in usb_fields):

      if 'manufacturer' in values:
        component.manufacturer_id.MergeFrom(
            cbu.find_partner(bundle, values['manufacturer'], create=True).id)

      component.camera.usb.vendor_id = values.get('idVendor', '')
      component.camera.usb.product_id = values.get('idProduct', '')
      component.camera.usb.bcd_device = values.get('bcdDevice', '')
      touched.update(usb_fields)

    if values.get('bus_type') == 'pci' or \
       all(key in values for key in pci_fields):

      component.camera.pci.vendor_id = values.get('vendor', '')
      component.camera.pci.device_id = values.get('device', '')
      component.camera.pci.revision_id = values.get('revision_id', '')
      touched.update(pci_fields)

    touched.add('bus_type')
    return touched

  @staticmethod
  def _merge_wireless(bundle, label, values):
    """Merge wireless items."""
    touched = set()

    component = cbu.find_component(bundle, id_value=label, create=True)
    component.name = label

    # save HWID values
    component.hwid_type = 'wireless'
    component.hwid_label = label

    component.wifi.pci.vendor_id = values.get('vendor', '')
    component.wifi.pci.device_id = values.get('device', '')
    component.wifi.pci.revision_id = values.get('revision_id', '')
    touched.update(['vendor', 'device', 'revision_id'])
    return touched
