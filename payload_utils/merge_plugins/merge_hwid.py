# -*- coding: utf-8 -*-
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Plugin for merging HWID information into ConfigBundle format"""

import copy
import yaml

from chromiumos.config.api.component_pb2 import Component
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle

from common import config_bundle_utils as cbu
from .merge_plugin import MergePlugin


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
          # 'cpu':                 __merge_cpu,
          # 'display_panel':       __merge_display,
          # 'dram':                __merge_dram,
          # 'ec_flash_chip':       __merge_ec_flash,
          # 'embedded_controller': __merge_ec,
          # 'flash_chip':          __merge_flash,
          # 'storage':             __merge_storage,
          # 'touchpad':            __merge_touchpad,
          # 'tpm':                 __merge_tpm,
          # 'touchscreen':         __merge_touchscreen,
          # 'stylus':              __merge_stylus,
          # 'usb_hosts':           __merge_usb_hosts,
          # 'video':               __merge_video,
          # 'wireless':            __merge_wireless,
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
