#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Join information from config_bundle, model.yaml and HWID.

Takes a generated config_bundle payload, optional public and private model.yaml
 files, and an optional HWID database and merges the data together into a new
set of generated joined data.

Can optionally generate a new ConfigBundle from just the model.yaml and HWID
files.  Simple specify a project name with --project-name/-p and omit
--config-bundle/-c.  At least one of these two options must be specified.
"""

# pylint: disable=too-many-lines

import argparse
import logging
import os
import re
import sys
import tempfile
import yaml

from google.cloud import bigquery

from common import config_bundle_utils
from common import utilities

from checker import io_utils
from chromiumos.build.api import firmware_config_pb2
from chromiumos.config.api import design_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2

# HWID databases use some custom tags, which are mostly legacy as far as I can
# tell, so we'll ignore them explicitly to allow the parser to succeed.
yaml.add_constructor('!re', lambda loader, node: loader.construct_scalar(node))
yaml.add_constructor('!region_field', lambda loader, node: None)
yaml.add_constructor('!region_component', lambda loader, node: None)

# git repo locations
CROS_PLATFORM_REPO = 'https://chromium.googlesource.com/chromiumos/platform2'
CROS_CONFIG_INTERNAL_REPO = 'https://chrome-internal.googlesource.com/chromeos/config-internal'

# DLM/AVL table configurations
DLM_PRODUCTS_TABLE = 'cros-device-lifecycle-manager.prod.products'
DLM_DEVICES_TABLE = 'cros-device-lifecycle-manager.prod.devices'

# gs bucket names
BCS_BUCKET = 'gs://chromeos-binaries'


def remove_prefix(value, prefix):
  """Remove a prefix from a string, if present"""
  if value.startswith(prefix):
    return value[len(prefix):]
  return value


def load_models(public_path, private_path):
  """Load model.yaml from a public and/or private path."""

  # Have to import this here since we need repos cloned and sys.path set up
  # pylint: disable=import-outside-toplevel, import-error
  from cros_config_host import cros_config_schema
  from libcros_config_host import CrosConfig
  # pylint: enable=import-outside-toplevel, import-error

  if not (public_path or private_path):
    return None

  configs = [config for config in [public_path, private_path] if config]
  with tempfile.TemporaryDirectory() as temp_dir:
    # Convert the model.yaml files into a payload JSON
    config_file = os.path.join(temp_dir, 'config.json')
    cros_config_schema.Main(
        schema=None, config=None, output=config_file, configs=configs)

    # And load the payload json into a CrosConfigJson object
    return CrosConfig(config_file)


def load_hwid(hwid_path):
  """Load a HWID database from the given path."""
  with open(hwid_path) as infile:
    return yaml.load(infile, Loader=yaml.FullLoader)


def non_null_values(items):
  """Unwrap a HWID item block into a dictionary of key => values for non-null values.

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

  We'll iterate over this and break out the 'values' block, make sure it's not None,
  and check whether we should exclude it based on the 'status' field if present."""

  def _include(val):
    if not val['values']:
      return False

    if 'status' in val and val['status'].lower() == 'unsupported':
      return False
    return True

  return [(key, val['values']) for key, val in items.items() if _include(val)]


def merge_avl_dlm(config_bundle):
  """Merge in additional information from AVL/DLM.

  Args:
    config_bundle: ConfigBundle instance to update

  Returns:
    reference to updated ConfigBundle
  """

  # Have to import this here since we need repos cloned and sys.path set up
  # pylint: disable=import-outside-toplevel, import-error
  from backfill import video_codec
  # pylint: enable=import-outside-toplevel, import-error

  # full list of platform names we have hardware codec information on
  platforms = list(video_codec.synonyms) + list(video_codec.video_codec_by_soc)

  def canonical_name(name):
    """Canonicalize code name for a project."""

    # These rules are from empirical runs with the real project data
    name = name.lower()
    if "_" in name:
      name = name[0:name.find("_")]
    return name

  client = bigquery.Client(project="chromeos-bot")

  def merge_form_factor(design, name, device_form_factor):
    """Map from form factor information in DLM to our proto definitions."""
    try:
      form_factor_enum = topology_pb2.HardwareFeatures.FormFactor
      form_factor = getattr(form_factor_enum, device_form_factor)

      for design_config in design.configs:
        design_config.hardware_features.form_factor.form_factor = form_factor
    except AttributeError:
      logging.warning(
          "invalid form factor '%s' for '%s'",
          device_form_factor,
          name,
      )

  def merge_platform_and_video(design, platform):
    """Canonicalize the platform name and match it to video codecs.

    Args:
      design (Design): design instance to modify with platform information"
      platform (str): platform name as pulled from DLM
    """

    # canonicalize to uppercase and take first of any alternates seperated by /
    platform = platform.upper().split("/")[0]

    # some platform names are of the form "platform_soc (model)" so
    # let's strip out the contents inside the parens if present.
    platform_re = re.compile(r"[a-zA-Z0-9]*\(([a-zA-Z0-9-]*)\)")
    match = platform_re.search(platform)
    if match:
      platform = match.group(1)

    # measure levenshtein distance to each platform name to find the best match.
    platform_dist = []
    for name in platforms:
      platform_dist.append(
          (utilities.levenshtein_distance(platform, name), name),)

    # take the closest match to be the best one
    best_dist, best_name = min(platform_dist)

    # ignore matches that aren't at least 50% similar
    match_ratio = float(len(platform) - best_dist) / len(platform)
    logging.info("Best platform match for %s is %s.", platform, best_name)

    if match_ratio < 0.5:
      logging.info("Too dissimilar, skipping.")
      return

    # resolve synonyms to canonical names
    while best_name in video_codec.synonyms:
      best_name = video_codec.synonyms[best_name]

    # and update the protobuf with platform information and codecs
    design.platform.name = best_name
    del design.platform.video_acceleration[:]  # clear list

    for codec in video_codec.video_codec_by_soc[best_name]:
      logging.info("Adding codec %s",
                   design_pb2.Design.Platform.VideoAcceleration.Name(codec))
      design.platform.video_acceleration.append(codec)

  ##############################################################################
  ## start of function body

  # canonicalize design names to be compatible with the DLM database
  project_names = [
      canonical_name(design.name) for design in config_bundle.design_list
  ]

  if not project_names:
    logging.info("no designs to populate from DLM, aborting")
    return config_bundle

  # query all projects at once, we'll filter them on our side.
  query = """
    SELECT googleCodeName, deviceFormFactor, platform
      FROM {device_table} devices
      WHERE googleCodeName IN ({projects})
  """.format(
      device_table=DLM_DEVICES_TABLE,
      projects=",".join(["'%s'" % name for name in project_names]),
  )
  logging.info(query)

  # sort through DLM information and update config bundle
  rows = list(client.query(query))
  for design, name in zip(config_bundle.design_list, project_names):
    rows = [row for row in rows if row.get('googleCodeName') == name]

    if len(rows) == 0:
      logging.warning("no results returned for '%s', bad project name?", name)
      continue

    if len(rows) > 1:
      logging.warning(
          "multiple results returned for '%s', cowardly refusing to merge DLM data",
          name,
      )
      continue

    merge_form_factor(design, name, rows[0].get('deviceFormFactor'))
    merge_platform_and_video(design, rows[0].get('platform'))

  return config_bundle


def backfill_configs(config_bundle):
  """Add any additional backfill information on top of the joined payload.

  This is really miscellaneous information that we don't have an existing
  source for (eg: it wasn't specified in model.yaml or HWID, such as the
  EC type), so we have to store it externally and merge it in to make it
  available to downstream consumers of the merged data.
  """

  # Have to import this here since we need repos cloned and sys.path set up
  # pylint: disable=import-outside-toplevel, import-error
  from backfill import ec_config
  # pylint: enable=import-outside-toplevel, import-error

  # iterate over program and projects
  for design in config_bundle.design_list:
    for design_config in design.configs:
      program = design.program_id.value.lower()
      project = design.name.lower()

      # populate embedded controller information
      ec_type = ec_config.get_board_ec(program, project)

      if (ec_type is not None and
          not design_config.hardware_features.HasField("embedded_controller")):
        # get reference to embedded controller proto
        controller = design_config.hardware_features.embedded_controller
        controller.present = topology_pb2.HardwareFeatures.PRESENT

        if ec_type == ec_config.EC_NONE:
          controller.present = topology_pb2.HardwareFeatures.NOT_PRESENT
        else:
          controller.ec_type = \
            {
                ec_config.EC_CHROME :
                    topology_pb2.HardwareFeatures.EmbeddedController.EC_CHROME,
                ec_config.EC_WILCO :
                    topology_pb2.HardwareFeatures.EmbeddedController.EC_WILCO
            }[ec_type]

  return config_bundle


def add_hwid_components(config_bundle, hwid_db):
  """Add components from the HWID database to the config_bundle.

  HWID doesn't map hardware to SKU, it's more a listing of all possible
  hardware components, which is resolved at runtime to generate an actual
  accounting of what hardware is on a specific device.  So we'll add the
  components under the ConfigBundle, but not actually tie them together
  into design configs (yet).

  Args:
    config_bundle (ConfigBundle): config to add HWID components to
    hwid_db (dict): parsed HWID database

  Returns:
    A reference to the input config_bundle updated with components from HWID
  """

  # pylint: disable=too-many-statements
  # pylint: disable=too-many-locals

  def create_audio_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = values.get('name', '')
      comp.audio_codec.name = comp.name

  def create_battery_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = comp.id.value
      if 'manufacturer' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['manufacturer'], create=True).id)

      comp.battery.model = values.get('model_name', '')
      if 'technology' in values and values['technology'].lower() == 'li-ion':
        comp.battery.technology = comp.battery.LI_ION

  def create_bluetooth_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = comp.id.value

      comp.bluetooth.usb.vendor_id = values.get('idVendor', '')
      comp.bluetooth.usb.product_id = values.get('idProduct', '')
      comp.bluetooth.usb.bcd_device = values.get('bcdDevice', '')

  def create_cpu_components(items):
    model_re = re.compile(  # reversed from HWID cpu model values
        '(a[0-9]?-[0-9]+[a-z]?|(m3-|i3-|i5-|i7-)*[0-9y]{4,5}[uy]?|n[0-9]{4})')

    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.soc.model = values.get('model', '')
      comp.soc.cores = int(values.get('cores', 0))

      if 'model' in values:
        model_string = values['model'].lower()
        if 'intel' in model_string or 'amd' in model_string:
          comp.soc.family.arch = comp.soc.X86_64
        elif 'aarch64' in model_string or 'armv8' in model_string:
          comp.soc.family.arch = comp.soc.ARM64
        elif 'armv7' in model_string:
          comp.soc.family.arch = comp.soc.ARM
        else:
          logging.warning('unknown family for cpu model \'%s\'', model_string)

        match = model_re.search(model_string)
        if match:
          comp.soc.family.name = match.group(0).upper()

  def create_display_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key

      if 'vendor' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['vendor'], create=True).id)

      comp.display_panel.product_id = values.get('product_id', '')
      comp.display_panel.properties.width_px = int(values.get('width', 0))
      comp.display_panel.properties.height_px = int(values.get('height', 0))

  def create_dram_components(items):
    # There's a lot of duplicated part numbers in the HWID db, mostly
    # due to specifying slot number.  That information is largely incorrect
    # anyways, so we'll deduplicate parts here
    part_values = {}
    for _, values in non_null_values(items):
      # skip incompletely specified parts
      if not all(key in values for key in ['part', 'size', 'timing']):
        continue

      part_values[values['part']] = (int(values['size']), values['timing'])

    for part_number, (size, timing) in part_values.items():
      comp = config_bundle.components.add()
      comp.id.value = part_number
      comp.memory.part_number = part_number
      comp.memory.profile.size_megabytes = int(size)

      memory_type = timing.split('-')[0]
      if memory_type == 'LPDDR4':
        comp.memory.profile.type = comp.memory.LP_DDR4
      elif memory_type == 'LPDDR3':
        comp.memory.profile.type = comp.memory.LP_DDR3
      elif memory_type == 'DDR4':
        comp.memory.profile.type = comp.memory.DDR4
      elif memory_type == 'DDR3':
        comp.memory.profile.type = comp.memory.DDR3
      elif memory_type == 'DDR2':
        comp.memory.profile.type = comp.memory.DDR2
      elif memory_type == 'DDR':
        comp.memory.profile.type = comp.memory.DDR

  def create_ec_flash_components(items):
    for _, values in non_null_values(items):
      part_number = values.get('name', '')

      comp = config_bundle.components.add()
      comp.id.value = part_number
      if 'vendor' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['vendor'], create=True).id)
      comp.ec_flash_chip.part_number = part_number

  def create_flash_components(items):
    for _, values in non_null_values(items):
      part_number = values.get('name', '')

      comp = config_bundle.components.add()
      comp.id.value = part_number
      if 'vendor' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['vendor'], create=True).id)
      comp.system_flash_chip.part_number = part_number

  def create_ec_components(items):
    for _, values in non_null_values(items):
      part_number = values.get('name', '')

      comp = config_bundle.components.add()
      comp.id.value = part_number
      comp.name = part_number

      if 'vendor' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['vendor'], create=True).id)
      comp.ec.part_number = part_number

  def create_storage_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = key

      comp.storage.emmc5_fw_ver = values.get('emmc5_fw_ver', '')
      comp.storage.manfid = values.get('manfid', '')
      comp.storage.name = values.get('name', '')
      comp.storage.oemid = values.get('oemid', '')
      comp.storage.prv = values.get('prv', '')
      comp.storage.sectors = values.get('sectors', '')

      if 'type' in values:
        storage_type = values['type'].lower()
        if storage_type == 'mmc':
          comp.storage.type = comp.storage.EMMC

  def create_touchpad_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = values.get('id', values.get('name', key))
      comp.name = values.get('name', key)

      # Check for USB based touchpad
      # We don't receive an explicit type for the touchpad bus type, so
      # we assume that if we have a product and vendor id, that it's USB,
      # otherwise it's I2C (rare)
      if 'product' in values and 'vendor' in values:
        comp.touchpad.type = comp.touchpad.USB
        comp.touchpad.product_id = comp.name
        comp.touchpad.usb.vendor_id = values['vendor']
        comp.touchpad.usb.product_id = values['product']
      elif 'fw_version' in values and 'fw_csum' in values:
        # i2c based touchpad
        comp.touchpad.type = comp.touchpad.I2C
        comp.touchpad.product_id = values.get('product_id', '')
        comp.touchpad.fw_version = values['fw_version']
        comp.touchpad.fw_checksum = values['fw_csum']

  def create_tpm_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = key
      comp.tpm.manufacturer_info = values.get('manufacturer_info', '')
      comp.tpm.version = values.get('version', '')

  def create_usb_host_components(items):

    def get_oneof(obj, keys, default=None):
      """Get one of a set of keys from a dict, or return a default value."""
      for key in keys:
        if key in obj:
          return obj[key]
      return default

    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = values.get('product', key)
      comp.name = values.get('product', key)
      if 'manufacturer' in values:
        comp.manufacturer_id.MergeFrom(
            config_bundle_utils.find_partner(
                config_bundle, values['manufacturer'], create=True).id)

      host = comp.usb_host
      host.product_id = get_oneof(values, ['idProduct', 'device'], '')
      host.vendor_id = get_oneof(values, ['idVendor', 'vendor'], '')
      host.bcd_device = get_oneof(values, ['bcdDevice', 'revision_id'], '')

  def create_video_components(items):
    usb_fields = ['bcdDevice', 'idProduct', 'idVendor']
    pci_fields = ['vendor', 'device', 'revision_id']

    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      if values.get('bus_type') == 'usb' or \
         all(key in values for key in usb_fields):
        comp.id.value = key
        comp.name = values['product']

        if 'manufacturer' in values:
          comp.manufacturer_id.MergeFrom(
              config_bundle_utils.find_partner(
                  config_bundle, values['manufacturer'], create=True).id)

        comp.camera.usb.vendor_id = values.get('idVendor', '')
        comp.camera.usb.product_id = values.get('idProduct', '')
        comp.camera.usb.bcd_device = values.get('bcdDevice', '')

      if values.get('bus_type') == 'pci' or \
         all(key in values for key in pci_fields):
        comp.id.value = key
        comp.name = key

        comp.camera.pci.vendor_id = values.get('vendor', '')
        comp.camera.pci.device_id = values.get('device', '')
        comp.camera.pci.revision_id = values.get('revision_id', '')

  def create_wireless_components(items):
    for key, values in non_null_values(items):
      comp = config_bundle.components.add()
      comp.id.value = key
      comp.name = key

      comp.wifi.pci.vendor_id = values.get('vendor', '')
      comp.wifi.pci.device_id = values.get('device', '')
      comp.wifi.pci.revision_id = values.get('revision_id', '')

  components = hwid_db['components']
  for component_type, value in components.items():
    if value:
      {
          'audio_codec': create_audio_components,
          'battery': create_battery_components,
          'bluetooth': create_bluetooth_components,
          'cpu': create_cpu_components,
          'display_panel': create_display_components,
          'dram': create_dram_components,
          'ec_flash_chip': create_ec_flash_components,
          'embedded_controller': create_ec_components,
          # 'firmware_keys': create_fw_key_components,
          'flash_chip': create_flash_components,
          # 'mainboard': create_mainboard_components,
          # 'region': create_region_components,
          # 'ro_ec_firmware': create_ro_ec_fw_components,
          # 'ro_main_firmware': create_ro_main_components,
          'storage': create_storage_components,
          'touchpad': create_touchpad_components,
          'tpm': create_tpm_components,
          'usb_hosts': create_usb_host_components,
          'video': create_video_components,
          'wireless': create_wireless_components
      }.get(component_type, (lambda x: None))(
          value['items'])

  return config_bundle


def merge_audio_config(sw_config, model):
  """Merge audio configuration from model.yaml into the given sw_config.

  Args:
    sw_config (SoftwareConfig): software config to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  audio_props = model.GetProperties('/audio/main')
  audio_config = sw_config.audio_configs.add()
  audio_config.ucm_suffix = audio_props.get('ucm-suffix', '')


def merge_power_config(sw_config, model):
  """Merge power configuration from model.yaml into the given sw_config.

  Args:
    sw_config (SoftwareConfig): software config to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  power_props = model.GetProperties('/power')
  power_config = sw_config.power_config

  for key, val in power_props.items():
    # We don't support autobrightness yet
    if key == 'autobrightness':
      continue
    power_config.preferences[key] = val


def merge_bluetooth_config(sw_config, model):
  """Merge bluetooth configuration from model.yaml into the given sw_config.

  Args:
    sw_config (SoftwareConfig): software config to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  bt_props = model.GetProperties('/bluetooth')
  bt_config = sw_config.bluetooth_config

  for key, val in bt_props.get('flags', {}).items():
    bt_config.flags[key] = val


def merge_firmware_config(sw_config, model):
  """Merge firmware configuration from model.yaml into the given sw_config.

  Args:
    sw_config (SoftwareConfig): software config to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """

  # extra model.yaml firmware config and the raw bcs overlay needed to resolve
  # bcs:// paths to absolute gs:// paths
  fw_props = model.GetFirmwareConfig()
  bcs_overlay = remove_prefix(fw_props.get('bcs-overlay', ''), 'overlay-')
  bcs_ebuild = bcs_overlay.split('-')[0]

  def decode_bcs_url(url):
    """Convert a bcs:// url to an absolute gs:// one."""
    gs_template = BCS_BUCKET + '/HOME' + \
      '/bcs-{bcs}/overlay-{bcs}/chromeos-base/chromeos-firmware-{ebuild}/{path}'

    if url.startswith("bcs://") and bcs_overlay:
      url = remove_prefix(url, "bcs://")
      return gs_template.format(
          bcs=bcs_overlay, model=model.GetName(), path=url, ebuild=bcs_ebuild)
    return url

  # Populate firmware config
  fw_config = sw_config.firmware
  fw_config.main_ro_payload.type = firmware_config_pb2.FirmwareType.MAIN
  fw_config.main_ro_payload.firmware_image_name = \
    decode_bcs_url(fw_props.get('main-ro-image', ''))

  fw_config.main_rw_payload.type = firmware_config_pb2.FirmwareType.MAIN
  fw_config.main_rw_payload.firmware_image_name = \
    decode_bcs_url(fw_props.get('main-rw-image', ''))

  fw_config.ec_ro_payload.type = firmware_config_pb2.FirmwareType.EC
  fw_config.ec_ro_payload.firmware_image_name = \
    decode_bcs_url(fw_props.get('ec-ro-image', ''))

  fw_config.pd_ro_payload.type = firmware_config_pb2.FirmwareType.PD
  fw_config.pd_ro_payload.firmware_image_name = \
    decode_bcs_url(fw_props.get('pd-ro-image', ''))

  # Populate build config
  build_props = model.GetProperties('/firmware/build-targets')

  build_config = sw_config.firmware_build_config
  build_config.build_targets.coreboot = build_props.get('coreboot', '')
  build_config.build_targets.depthcharge = build_props.get('depthcharge', '')
  build_config.build_targets.ec = build_props.get('ec', '')
  build_config.build_targets.libpayload = build_props.get('libpayload', '')

  for extra in build_props.get('ec-extras', []):
    build_config.build_targets.ec_extras.add(extra)


def merge_camera_config(hw_feat, model):
  """Merge camera config from model.yaml into the given hardware features.

  Args:
    hw_feat (HardwareFeatures): hardware features to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  camera_props = model.GetProperties('/camera')
  del hw_feat, camera_props
  # TODO: Merge camera configuration when it's available


def merge_buttons(hw_feat, model):
  """Merge power/volume button information from model.yaml into hardware features.

  Args:
    hw_feat (HardwareFeatures): hardware features to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  ui_props = model.GetProperties('/ui')
  button = topology_pb2.HardwareFeatures.Button

  if 'power-button' in ui_props:
    edge = ui_props['power-button']['edge']
    hw_feat.power_button.edge = button.Edge.Value(edge.upper())
    hw_feat.power_button.position = float(ui_props['power-button']['position'])

  if 'side-volume-button' in ui_props:
    region = ui_props['side-volume-button']['region']
    hw_feat.volume_button.region = button.Region.Value(region.upper())
    side = ui_props['side-volume-button']['side']
    hw_feat.volume_button.edge = button.Edge.Value(side.upper())


def merge_hardware_props(hw_feat, model):
  """Merge hardware properties from model.yaml into the given hardware features.

  Args:
    hw_feat (HardwareFeatures): hardware features to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  form_factor = topology_pb2.HardwareFeatures.FormFactor
  stylus = topology_pb2.HardwareFeatures.Stylus

  def kw_to_present(config, key):
    if not key in config:
      return topology_pb2.HardwareFeatures.PRESENT_UNKNOWN
    if config[key]:
      return topology_pb2.HardwareFeatures.PRESENT
    return topology_pb2.HardwareFeatures.NOT_PRESENT

  hw_props = model.GetProperties('/hardware-properties')

  hw_feat.accelerometer.base_accelerometer = \
      kw_to_present(hw_props, 'has-base-accelerometer')
  hw_feat.accelerometer.lid_accelerometer = \
      kw_to_present(hw_props, 'has-lid-accelerometer')
  hw_feat.gyroscope.base_gyroscope = \
      kw_to_present(hw_props, 'has-base-gyroscope')
  hw_feat.gyroscope.lid_gyroscope = \
      kw_to_present(hw_props, 'has-lid-gyroscope')
  hw_feat.light_sensor.base_lightsensor = \
      kw_to_present(hw_props, 'has-base-light-sensor')
  hw_feat.light_sensor.lid_lightsensor = \
      kw_to_present(hw_props, 'has-lid-light-sensor')
  hw_feat.magnetometer.base_magnetometer = \
      kw_to_present(hw_props, 'has-base-magnetometer')
  hw_feat.magnetometer.lid_magnetometer = \
      kw_to_present(hw_props, 'has-lid-magnetometer')
  hw_feat.screen.touch_support = \
      kw_to_present(hw_props, 'has-touchscreen')

  hw_feat.form_factor.form_factor = form_factor.FORM_FACTOR_UNKNOWN
  if hw_props.get('is-lid-convertible', False):
    hw_feat.form_factor.form_factor = form_factor.CONVERTIBLE

  stylus_val = hw_props.get('stylus-category', '')
  if not stylus_val:
    hw_feat.stylus.stylus = stylus.STYLUS_UNKNOWN
  if stylus_val == 'none':
    hw_feat.stylus.stylus = stylus.NONE
  if stylus_val == 'internal':
    hw_feat.stylus.stylus = stylus.INTERNAL
  if stylus_val == 'external':
    hw_feat.stylus.stylus = stylus.EXTERNAL


def merge_fingerprint_config(hw_feat, model):
  """Merge fingerprint config from model.yaml into the given hardware features.

  Args:
    hw_feat (HardwareFeatures): hardware features to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    None
  """
  location = topology_pb2.HardwareFeatures.Fingerprint.Location

  fing_prop = model.GetProperties('/fingerprint')
  hw_feat.fingerprint.board = fing_prop.get('board', '')

  sensor_location = fing_prop.get('sensor-location', 'none')
  if sensor_location == 'none':
    sensor_location = 'not-present'
  hw_feat.fingerprint.location = location.Value(sensor_location.upper().replace(
      '-', '_'))


def merge_device_brand(config_bundle, design, model, project_name):
  """Merge brand information from model.yaml into specific Design instance.

  The ConfigBundle and Design protos are updated in place with the information
  from model.yaml.

  In general we'll have a 1:1 mapping with Design to Brand information so we
  create a new DeviceBrand and link it to a new Brand_Config value.

  Args:
    config_bundle (ConfigBundle): top level ConfigBundle to update
    design (Design): design in the config bundle to update
    model (CrosConfig): parsed model.yaml information
    project_name (str): name of the device (eg: phaser)

  Returns:
    A reference to the input ConfigBundle updated with data from model
  """

  whitelabel = model.GetProperties('/identity/whitelabel-tag')
  whitelabel = whitelabel or ""

  # find/create new brand entry for the design
  brand_name = ""
  brand_code = model.GetProperties("/brand-code")
  brand_id = "{}_{}".format(project_name, brand_code)

  # find/create device brand
  device_brand = None
  for brand in config_bundle.device_brand_list:
    if (brand.design_id == design.id and brand.brand_name == brand_name and
        brand.brand_code == brand_code):
      device_brand = brand
      break

  if not device_brand:
    device_brand = config_bundle.device_brand_list.add()
    device_brand.id.value = brand_id
    device_brand.design_id.MergeFrom(design.id)
    device_brand.brand_name = ""
    device_brand.brand_code = brand_code

  # find/create brand config
  brand_config = None
  for config in config_bundle.brand_configs:
    if (config.brand_id == device_brand.id and
        config.scan_config.whitelabel_tag == whitelabel):
      brand_config = config
      break

  if not brand_config:
    brand_config = config_bundle.brand_configs.add()
    brand_config.brand_id.MergeFrom(device_brand.id)
    brand_config.scan_config.whitelabel_tag = whitelabel

  wallpaper = model.GetWallpaperFiles()
  if wallpaper:
    brand_config.wallpaper = wallpaper.pop()

  regulatory_label = model.GetProperties('/regulatory-label')
  if regulatory_label:
    brand_config.regulatory_label = regulatory_label

  return config_bundle


def merge_model(config_bundle, design_config, model):
  """Merge model from model.yaml into a specific Design.Config instance.

  The ConfigBundle, and Design.Config are updated in place with
  model.yaml information.

  Args:
    config_bundle (ConfigBundle): top level ConfigBundle to update
    design_config (Design.Config): design config in the config bundle to update
    model (CrosConfig): parsed model.yaml information

  Returns:
    A reference to the input config_bundle updated with data from model
  """

  identity = model.GetProperties('/identity')

  # Merge hardware configuration
  hw_feat = design_config.hardware_features
  merge_fingerprint_config(hw_feat, model)
  merge_hardware_props(hw_feat, model)
  merge_camera_config(hw_feat, model)
  merge_buttons(hw_feat, model)

  # Merge software configuration
  sw_config = None
  for config in config_bundle.software_configs:
    if config.design_config_id == design_config.id:
      sw_config = config
      break

  # Already have software config for this design_config, so don't re-populate
  if sw_config:
    return config_bundle

  sw_config = config_bundle.software_configs.add()
  sw_config.design_config_id.MergeFrom(design_config.id)

  sw_config.id_scan_config.firmware_sku = identity.get('sku-id', 0xFFFFFFFF)

  if 'smbios-name-match' in identity:
    sw_config.id_scan_config.smbios_name_match = identity['smbios-name-match']

  if 'device-tree-compatible-match' in identity:
    sw_config.id_scan_config.device_tree_compatible_match = \
       identity['device-tree-compatible-match']

  merge_firmware_config(sw_config, model)
  merge_bluetooth_config(sw_config, model)
  merge_power_config(sw_config, model)
  merge_audio_config(sw_config, model)

  return config_bundle


def merge_configs(config_path, program_name, project_name, public_path,
                  private_path, hwid_path):
  # pylint: disable=too-many-arguments
  # pylint: disable=too-many-locals
  # pylint: disable=too-many-branches
  # pylint: disable=too-many-statements
  """Read and merge configs together, generating new config_bundle output."""

  config_bundle = config_bundle_pb2.ConfigBundle()
  if config_path:
    config_bundle = io_utils.read_config(config_path)

  models = load_models(public_path, private_path)

  # ensure that a program entry is added for the manually specified program name
  if program_name:
    config_bundle_utils.find_program(
        config_bundle, program_name.capitalize(), create=True)

  def find_design_config(prog_name, proj_name, sku):
    """Searches config_bundle a matching design_config.

    Args:
      prog_name (str): program name
      proj_name (str): project name
      sku (str): specific sku

    Returns:
      Either found Design and Design.Config for input parameters or new ones
      create and placed in the config_bundle.
    """

    # Ensure program exists
    program = config_bundle_utils.find_program(
        config_bundle, prog_name, create=True)

    # Find design matching program and project names
    program_design = None
    for design in config_bundle.design_list:
      if program.id != design.program_id:
        continue

      program_design = design
      if proj_name.lower() != design.name.lower():
        continue

      # Found matching design, iterate design configs looking for SKU
      for design_config in design.configs:
        design_sku = design_config.id.value.lower().split(':')[-1]
        if design_sku == sku:
          return design, design_config

    # No Design found, create one
    if not program_design:
      program_design = config_bundle.design_list.add()
      program_design.id.value = proj_name
      program_design.name = proj_name
      program_design.program_id.MergeFrom(program.id)

    # Create new Design.Config, the board id is encoded according to CBI:
    #  http://go/chromiumsrc/chromiumos/docs/+/master/design_docs/cros_board_info.md
    design_config = program_design.configs.add()
    design_config.id.value = '{}:{}'.format(proj_name.capitalize(), sku)
    return program_design, design_config

  # GetDeviceConfigs() will return an entry for all combinations of:
  #     (program, project, sku, whitelabel)
  # so we need to be careful not to create duplicate entries.
  for model in models.GetDeviceConfigs() if models else []:
    identity = model.GetProperties('/identity')
    program = identity['platform-name']
    project = model.GetName()

    sku = identity.get('sku-id')
    if not sku:
      sku = 0xFFFFFFFF
      logging.info('found wildcard sku in %s, setting sku-id to "%s"', project,
                   sku)
    sku = str(sku)

    if sku == '255':
      logging.info('skipping unprovisioned sku %s', sku)
      continue

    assert program, 'program name is undefined'
    assert project, 'project name is undefined'

    # Ignore projects other than the one specified
    if project_name and (project != project_name.lower()):
      continue

    # Lookup design config for this specific device
    design, design_config = find_design_config(program, project, sku)

    merge_device_brand(config_bundle, design, model, project_name)
    merge_model(config_bundle, design_config, model)

  # Merge information from HWID into config bundle
  if hwid_path:
    return add_hwid_components(config_bundle, load_hwid(hwid_path))
  return config_bundle


def main(options):
  """Runs the script."""

  def clone_repo(repo, path):
    """Clone a given repo to the given path in the file system."""
    cmd = 'git clone -q --depth=1 --shallow-submodules {repo} {path}'.format(
        repo=repo, path=path)
    print('Creating shallow clone of {repo} ({cmd})'.format(repo=repo, cmd=cmd))
    os.system(cmd)

  def clone_or_use_dep(repo, clone_path, dep_path, sub_path=''):
    """Either use a dependency in-place or clone it and use that.

    If the dependency doesn't exist at dep_path, then clone it into clone_path.
    Either way, add the path/{sub_path} to sys.path.

    Args:
      repo (str): url of the git repo for the dependency
      clone_path (str): where to clone repo if neeeded
      dep_path (str): location on disk the path might be located
      sub_path (str): path inside of repo to add to sys.path

    Returns:
      nothing
    """
    root_path = dep_path
    if not os.path.exists(root_path):
      clone_repo(repo, clone_path)
      root_path = clone_path
    sys.path.append(os.path.join(root_path, sub_path))

  if not (options.config_bundle or options.project_name):
    raise RuntimeError(
        'At least one of {config_opt} or {project_opt} must be specified.'
        .format(
            config_opt='--config-bundle/-c', project_opt='--project-name/-p'))

  with tempfile.TemporaryDirectory(prefix='join_proto_') as temppath:
    this_dir = os.path.realpath(os.path.dirname(__file__))

    clone_or_use_dep(
        CROS_PLATFORM_REPO,
        os.path.join(temppath, 'platform2'),
        os.path.realpath(os.path.join(this_dir, "../../platform2")),
        'chromeos-config',
    )

    clone_or_use_dep(
        CROS_CONFIG_INTERNAL_REPO,
        os.path.join(temppath, 'config-internal'),
        os.path.realpath(os.path.join(this_dir, "../../config-internal")),
    )

    io_utils.write_message_json(
        merge_avl_dlm(
            backfill_configs(
                merge_configs(options.config_bundle, options.program_name,
                              options.project_name, options.public_model,
                              options.private_model, options.hwid))),
        options.output,
        default_fields=True)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      '-o',
      '--output',
      type=str,
      required=True,
      help='output file to write joined ConfigBundle jsonproto to')
  parser.add_argument(
      '-c',
      '--config-bundle',
      type=str,
      help="""generated config_bundle payload in jsonpb format
(eg: generated/config.jsonproto).  If not specified, an empty ConfigBundle
instance is used instad.""")
  parser.add_argument(
      '-p',
      '--project-name',
      type=str,
      help="""When specified without --config-bundle/-c, this species the project name to
generate ConfigBundle information for from the model.yaml/HWID files.  When
specified with --config-bundle/-c, then only projects with this name will be
updated.""")
  parser.add_argument(
      '--program-name',
      type=str,
      help="""Program name to add to the output ConfigBundle.  This program will be
added to the program_list even if there are no designs present.""")
  parser.add_argument(
      '--public-model', type=str, help='public model.yaml file to merge')
  parser.add_argument(
      '--private-model', type=str, help='private model.yaml file to merge')
  parser.add_argument('--hwid', type=str, help='HWID database to merge')
  parser.add_argument(
      "-v", "--verbose", help="increase output verbosity", action="store_true")
  parser.add_argument("-l", "--log", type=str, help='set logging level')

  args = parser.parse_args()
  # pylint: disable=invalid-name
  loglevel = logging.INFO if args.verbose else logging.WARNING
  if args.log:
    loglevel = {
        "critical": logging.CRITICAL,
        "error": logging.ERROR,
        "warning": logging.WARNING,
        "info": logging.INFO,
        "debug": logging.DEBUG,
    }.get(args.log.lower())

    if not loglevel:
      logging.error("invalid value for -l/--log '%s'", args.log)

  logging.basicConfig(level=loglevel)
  main(args)
