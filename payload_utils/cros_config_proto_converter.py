#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Transforms config from /config/proto/api proto format to platform JSON."""

import argparse
import json
import pprint
import os
import sys
import re
import xml.etree.ElementTree as etree
import xml.dom.minidom as minidom

from typing import List

from collections import namedtuple

from google.protobuf import json_format

from chromiumos.config.api import device_brand_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2
from chromiumos.config.api.software import brand_config_pb2

Config = namedtuple('Config', [
    'program', 'hw_design', 'odm', 'hw_design_config', 'device_brand',
    'device_signer_config', 'oem', 'sw_config', 'brand_config', 'build_target'
])

ConfigFiles = namedtuple(
    'ConfigFiles',
    ['bluetooth', 'arc_hw_features', 'touch_fw', 'dptf_map', 'camera_map'])

CAMERA_CONFIG_DEST_PATH_TEMPLATE = '/etc/camera/camera_config_{}.json'
CAMERA_CONFIG_SOURCE_PATH_TEMPLATE = (
    'sw_build_config/platform/chromeos-config/camera/camera_config_{}.json')

DPTF_PATH = 'sw_build_config/platform/chromeos-config/thermal'
DPTF_FILE = 'dptf.dv'
TOUCH_PATH = 'sw_build_config/platform/chromeos-config/touch'
WALLPAPER_BASE_PATH = '/usr/share/chromeos-assets/wallpaper'


def parse_args(argv):
  """Parse the available arguments.

  Invalid arguments or -h cause this function to print a message and exit.

  Args:
    argv: List of string arguments (excluding program name / argv[0])

  Returns:
    argparse.Namespace object containing the attributes.
  """
  parser = argparse.ArgumentParser(
      description='Converts source proto config into platform JSON config.')
  parser.add_argument(
      '-c',
      '--project_configs',
      nargs='+',
      type=str,
      help='Space delimited list of source protobinary project config files.')
  parser.add_argument(
      '-p',
      '--program_config',
      type=str,
      help='Path to the source program-level protobinary file')
  parser.add_argument(
      '-o', '--output', type=str, help='Output file that will be generated')
  return parser.parse_args(argv)


def _upsert(field, target, target_name):
  """Updates or inserts `field` within `target`.

  If `target_name` already exists within `target` an update is performed,
  otherwise, an insert is performed.
  """
  if field or field == 0:
    if target_name in target:
      target[target_name].update(field)
    else:
      target[target_name] = field


def _build_arc(config, config_files):
  if not config.build_target.arc:
    return None

  build_properties = {
      'device': config.build_target.arc.device,
      'first-api-level': config.build_target.arc.first_api_level,
      'marketing-name': config.device_brand.brand_name,
      'metrics-tag': config.hw_design.name.lower(),
      'product': config.build_target.id.value,
  }
  if config.oem:
    build_properties['oem'] = config.oem.name
  result = {'build-properties': build_properties}
  feature_id = _arc_hardware_feature_id(config.hw_design_config)
  if feature_id in config_files.arc_hw_features:
    result['hardware-features'] = config_files.arc_hw_features[feature_id]
  topology = config.hw_design_config.hardware_topology
  ppi = topology.screen.hardware_feature.screen.panel_properties.pixels_per_in
  # Only set for high resolution displays
  if ppi and ppi > 250:
    result['scale'] = ppi
  return result


def _build_ash_flags(config: Config) -> List[str]:
  """Returns a list of Ash flags for config.

  Ash is the window manager and system UI for ChromeOS, see
  https://chromium.googlesource.com/chromium/src/+/refs/heads/master/ash/.
  """
  # A map from flag name -> value. Value may be None for boolean flags.
  flags = {}

  hw_features = config.hw_design_config.hardware_features
  if hw_features.stylus.stylus == topology_pb2.HardwareFeatures.Stylus.INTERNAL:
    flags['has-internal-stylus'] = None

  fp_loc = hw_features.fingerprint.location
  if fp_loc and fp_loc != topology_pb2.HardwareFeatures.Fingerprint.NOT_PRESENT:
    loc_name = topology_pb2.HardwareFeatures.Fingerprint.Location.Name(fp_loc)
    flags['fingerprint-sensor-location'] = loc_name.lower().replace('_', '-')

  wallpaper = config.brand_config.wallpaper
  # If a wallpaper is set, the 'default-wallpaper-is-oem' flag needs to be set.
  # If a wallpaper is not set, the 'default_[large|small].jpg' wallpapers
  # should still be set.
  if wallpaper:
    flags['default-wallpaper-is-oem'] = None
  else:
    wallpaper = 'default'

  for size in ('small', 'large'):
    flags[f'default-wallpaper-{size}'] = (
        f'{WALLPAPER_BASE_PATH}/{wallpaper}_{size}.jpg')

    # For each size, also install 'guest' and 'child' wallpapers.
    for wallpaper_type in ('guest', 'child'):
      flags[f'{wallpaper_type}-wallpaper-{size}'] = (
          f'{WALLPAPER_BASE_PATH}/{wallpaper_type}_{size}.jpg')

  flags['arc-build-properties'] = json_format.MessageToDict(
      config.build_target.arc)

  power_button = hw_features.power_button
  if power_button.edge:
    flags['ash-power-button-position'] = json.dumps({
        'edge':
            topology_pb2.HardwareFeatures.Button.Edge.Name(power_button.edge
                                                          ).lower(),
        # Starlark sometimes represents float literals strangely, e.g. changing
        # 0.9 to 0.899999. Round to two digits here.
        'position':
            round(power_button.position, 2)
    })

  volume_button = hw_features.volume_button
  if volume_button.edge:
    flags['ash-side-volume-button-position'] = json.dumps({
        'region':
            topology_pb2.HardwareFeatures.Button.Region.Name(
                volume_button.region).lower(),
        'edge':
            topology_pb2.HardwareFeatures.Button.Edge.Name(volume_button.edge
                                                          ).lower(),
    })

  return sorted([f'--{k}={v}' if v else f'--{k}' for k, v in flags.items()])


def _build_ui(config: Config) -> dict:
  """Builds the 'ui' property from cros_config_schema."""
  return {'extra-ash-flags': _build_ash_flags(config)}


def _build_bluetooth(config, bluetooth_files):
  bt_flags = config.sw_config.bluetooth_config.flags
  # Convert to native map (from proto wrapper)
  bt_flags_map = dict(bt_flags)
  result = {}
  if bt_flags_map:
    result['flags'] = bt_flags_map
  bt_comp = config.hw_design_config.hardware_features.bluetooth.component.usb
  if bt_comp.vendor_id:
    bt_id = _bluetooth_id(config.hw_design.name.lower(), bt_comp)
    if bt_id in bluetooth_files:
      result['config'] = bluetooth_files[bt_id]
  return result


def _build_fingerprint(hw_topology):
  if not hw_topology.HasField('fingerprint'):
    return None

  fp = hw_topology.fingerprint.hardware_feature.fingerprint
  result = {}
  if fp.location != topology_pb2.HardwareFeatures.Fingerprint.NOT_PRESENT:
    location = fp.Location.DESCRIPTOR.values_by_number[fp.location].name
    result['sensor-location'] = location.lower().replace('_', '-')
    if fp.board:
      result['board'] = fp.board
  return result


def _fw_bcs_path(payload):
  if payload and payload.firmware_image_name:
    return 'bcs://%s.%d.%d.0.tbz2' % (payload.firmware_image_name,
                                      payload.version.major,
                                      payload.version.minor)

  return None


def _fw_build_target(payload):
  if payload:
    return payload.build_target_name

  return None


def _build_firmware(config):
  """Returns firmware config, or None if no build targets."""
  fw_payload_config = config.sw_config.firmware
  fw_build_config = config.sw_config.firmware_build_config
  main_ro = fw_payload_config.main_ro_payload
  main_rw = fw_payload_config.main_rw_payload
  ec_ro = fw_payload_config.ec_ro_payload
  pd_ro = fw_payload_config.pd_ro_payload

  build_targets = {}

  _upsert(fw_build_config.build_targets.depthcharge, build_targets,
          'depthcharge')
  _upsert(fw_build_config.build_targets.coreboot, build_targets, 'coreboot')
  _upsert(fw_build_config.build_targets.ec, build_targets, 'ec')
  _upsert(
      list(fw_build_config.build_targets.ec_extras), build_targets, 'ec_extras')
  _upsert(fw_build_config.build_targets.libpayload, build_targets, 'libpayload')

  if not build_targets:
    return None

  result = {
      'bcs-overlay': config.build_target.overlay_name,
      'build-targets': build_targets,
  }

  _upsert(main_ro.firmware_image_name.lower(), result, 'image-name')

  _upsert(_fw_bcs_path(main_ro), result, 'main-ro-image')
  _upsert(_fw_bcs_path(main_rw), result, 'main-rw-image')
  _upsert(_fw_bcs_path(ec_ro), result, 'ec-ro-image')
  _upsert(_fw_bcs_path(pd_ro), result, 'pd-ro-image')

  _upsert(
      config.hw_design_config.hardware_features.fw_config.value,
      result,
      'firmware-config',
  )

  return result


def _build_fw_signing(config):
  if config.sw_config.firmware and config.device_signer_config:
    hw_design = config.hw_design.name.lower()
    return {
        'key-id': config.device_signer_config.key_id,
        # TODO(shapiroc): Need to fix for whitelabel.
        # Whitelabel will collide on unique signature-id values.
        'signature-id': hw_design,
    }
  return {}


def _file(source, destination):
  return {'destination': destination, 'source': source}


def _file_v2(build_path, system_path):
  return {'build-path': build_path, 'system-path': system_path}


def _build_audio(config):
  if not config.sw_config.audio_configs:
    return {}
  alsa_path = '/usr/share/alsa/ucm'
  cras_path = '/etc/cras'
  project_name = config.hw_design.name.lower()
  program_name = config.program.name.lower()
  files = []
  ucm_suffix = None
  for audio in config.sw_config.audio_configs:
    card = audio.card_name
    card_with_suffix = audio.card_name
    if audio.ucm_suffix:
      # TODO: last ucm_suffix wins.
      ucm_suffix = audio.ucm_suffix
      card_with_suffix += '.' + audio.ucm_suffix
    if audio.ucm_file:
      files.append(
          _file(audio.ucm_file,
                '%s/%s/HiFi.conf' % (alsa_path, card_with_suffix)))
    if audio.ucm_master_file:
      files.append(
          _file(
              audio.ucm_master_file, '%s/%s/%s.conf' %
              (alsa_path, card_with_suffix, card_with_suffix)))
    if audio.card_config_file:
      files.append(
          _file(audio.card_config_file,
                '%s/%s/%s' % (cras_path, project_name, card)))
    if audio.dsp_file:
      files.append(
          _file(audio.dsp_file, '%s/%s/dsp.ini' % (cras_path, project_name)))
    if audio.module_file:
      files.append(
          _file(audio.module_file,
                '/etc/modprobe.d/alsa-%s.conf' % program_name))
    if audio.board_file:
      files.append(
          _file(audio.board_file,
                '%s/%s/board.ini' % (cras_path, project_name)))

  result = {
      'main': {
          'cras-config-dir': project_name,
          'files': files,
      }
  }

  if ucm_suffix:
    result['main']['ucm-suffix'] = ucm_suffix

  return result


def _build_camera(hw_topology):
  if hw_topology.HasField('camera'):
    camera = hw_topology.camera.hardware_feature.camera
    result = {}
    if camera.count.value:
      result['count'] = camera.count.value
    return result

  return None


def _build_identity(hw_scan_config, program, brand_scan_config=None):
  identity = {}
  _upsert(hw_scan_config.firmware_sku, identity, 'sku-id')
  _upsert(hw_scan_config.smbios_name_match, identity, 'smbios-name-match')
  # 'platform-name' is needed to support 'mosys platform name'. Clients should
  # longer require platform name, but set it here for backwards compatibility.
  _upsert(program.name, identity, 'platform-name')
  # ARM architecture
  _upsert(hw_scan_config.device_tree_compatible_match, identity,
          'device-tree-compatible-match')

  if brand_scan_config:
    _upsert(brand_scan_config.whitelabel_tag, identity, 'whitelabel-tag')

  return identity


def _lookup(id_value, id_map):
  if not id_value.value:
    return None

  key = id_value.value
  if key in id_map:
    return id_map[id_value.value]
  error = 'Failed to lookup %s with value: %s' % (
      id_value.__class__.__name__.replace('Id', ''), key)
  print(error)
  print('Check the config contents provided:')
  printer = pprint.PrettyPrinter(indent=4)
  printer.pprint(id_map)
  raise Exception(error)


def _build_touch_file_config(config, project_name):
  partners = {x.id.value: x for x in config.partners.value}
  files = []
  for comp in config.components:
    touch = comp.touchscreen
    # Everything is the same for Touch screen/pad, except different fields
    if comp.HasField('touchpad'):
      touch = comp.touchpad
    if touch.product_id:
      vendor = _lookup(comp.manufacturer_id, partners)
      if not vendor:
        raise Exception("Manufacturer must be set for touch device %s" %
                        comp.id.value)

      product_id = touch.product_id
      fw_version = touch.fw_version

      touch_vendor = vendor.touch_vendor
      sym_link = touch_vendor.fw_file_format.format(
          vendor_name=vendor.name,
          vendor_id=touch_vendor.vendor_id,
          product_id=product_id,
          fw_version=fw_version,
          product_series=touch.product_series)

      file_name = "%s_%s.bin" % (product_id, fw_version)
      fw_file_path = os.path.join(TOUCH_PATH, vendor.name, file_name)

      if not os.path.exists(fw_file_path):
        raise Exception("Touchscreen fw bin file doesn't exist at: %s" %
                        fw_file_path)

      files.append({
          "destination":
              "/opt/google/touch/firmware/%s_%s" % (vendor.name, file_name),
          "source":
              os.path.join(project_name, fw_file_path),
          "symlink":
              os.path.join("/lib/firmware", sym_link),
      })

  result = {}
  _upsert(files, result, 'files')
  return result


def _transform_build_configs(config,
                             config_files=ConfigFiles({}, {}, {}, {}, {})):
  # pylint: disable=too-many-locals,too-many-branches
  partners = {x.id.value: x for x in config.partners.value}
  programs = {x.id.value: x for x in config.programs.value}
  sw_configs = list(config.software_configs)
  brand_configs = {x.brand_id.value: x for x in config.brand_configs}

  if len(config.build_targets) != 1:
    # Artifact of sharing the config_bundle for analysis and transforms.
    # Integrated analysis of multiple programs/projects it the only time
    # having multiple build targets would be valid.
    raise Exception('Single build_target required for transform')

  results = {}
  for hw_design in config.designs.value:
    if config.device_brands.value:
      device_brands = [
          x for x in config.device_brands.value
          if x.design_id.value == hw_design.id.value
      ]
    else:
      device_brands = [device_brand_pb2.DeviceBrand()]

    for device_brand in device_brands:
      # Brand config can be empty since platform JSON config allows it
      brand_config = brand_config_pb2.BrandConfig()
      if device_brand.id.value in brand_configs:
        brand_config = brand_configs[device_brand.id.value]

      for hw_design_config in hw_design.configs:
        design_id = hw_design_config.id.value
        sw_config_matches = [
            x for x in sw_configs if x.design_config_id.value == design_id
        ]
        if len(sw_config_matches) == 1:
          sw_config = sw_config_matches[0]
        elif len(sw_config_matches) > 1:
          raise Exception('Multiple software configs found for: %s' % design_id)
        else:
          raise Exception('Software config is required for: %s' % design_id)

        program = _lookup(hw_design.program_id, programs)
        signer_configs_by_design = {}
        signer_configs_by_brand = {}
        for signer_config in program.device_signer_configs:
          design_id = signer_config.design_id.value
          brand_id = signer_config.brand_id.value
          if design_id:
            signer_configs_by_design[design_id] = signer_config
          elif brand_id:
            signer_configs_by_brand[brand_id] = signer_config
          else:
            raise Exception('No ID found for signer config: %s' % signer_config)

        device_signer_config = None
        if signer_configs_by_design or signer_configs_by_brand:
          design_id = hw_design.id.value
          brand_id = device_brand.id.value
          if design_id in signer_configs_by_design:
            device_signer_config = signer_configs_by_design[design_id]
          elif brand_id in signer_configs_by_brand:
            device_signer_config = signer_configs_by_brand[brand_id]
          else:
            # Assume that if signer configs are set, every config is setup
            raise Exception('Signer config missing for design: %s, brand: %s' %
                            (design_id, brand_id))

        transformed_config = _transform_build_config(
            Config(
                program=program,
                hw_design=hw_design,
                odm=_lookup(hw_design.odm_id, partners),
                hw_design_config=hw_design_config,
                device_brand=device_brand,
                device_signer_config=device_signer_config,
                oem=_lookup(device_brand.oem_id, partners),
                sw_config=sw_config,
                brand_config=brand_config,
                build_target=config.build_targets[0]), config_files)

        config_json = json.dumps(
            transformed_config,
            sort_keys=True,
            indent=2,
            separators=(',', ': '))

        if config_json not in results:
          results[config_json] = transformed_config

  return list(results.values())


def _transform_build_config(config, config_files):
  """Transforms Config instance into target platform JSON schema.

  Args:
    config: Config namedtuple
    config_files: Map to look up the generated config files.

  Returns:
    Unique config payload based on the platform JSON schema.
  """
  result = {
      'identity':
          _build_identity(config.sw_config.id_scan_config, config.program,
                          config.brand_config.scan_config),
      'name':
          config.hw_design.name.lower(),
  }

  _upsert(_build_arc(config, config_files), result, 'arc')
  _upsert(_build_audio(config), result, 'audio')
  _upsert(_build_bluetooth(config, config_files.bluetooth), result, 'bluetooth')
  _upsert(config.device_brand.brand_code, result, 'brand-code')
  _upsert(
      _build_camera(config.hw_design_config.hardware_topology), result,
      'camera')
  _upsert(_build_firmware(config), result, 'firmware')
  _upsert(_build_fw_signing(config), result, 'firmware-signing')
  _upsert(
      _build_fingerprint(config.hw_design_config.hardware_topology), result,
      'fingerprint')
  _upsert(_build_ui(config), result, 'ui')
  power_prefs = config.sw_config.power_config.preferences
  power_prefs_map = dict(
      (x.replace('_', '-'), power_prefs[x]) for x in power_prefs)
  _upsert(power_prefs_map, result, 'power')
  if config_files.camera_map:
    camera_file = config_files.camera_map.get(config.hw_design.name, {})
    _upsert(camera_file, result, 'camera')
  if config_files.dptf_map:
    # Prefer design specific if found, if not fall back to project wide config
    # mapped under the empty string.
    if config_files.dptf_map.get(config.hw_design.name):
      dptf_file = config_files.dptf_map[config.hw_design.name]
    else:
      dptf_file = config_files.dptf_map.get('')
    _upsert(dptf_file, result, 'thermal')
  _upsert(config_files.touch_fw, result, 'touch')

  return result


def write_output(configs, output=None):
  """Writes a list of configs to platform JSON format.

  Args:
    configs: List of config dicts defined in cros_config_schema.yaml
    output: Target file output (if None, prints to stdout)
  """
  json_output = json.dumps({'chromeos': {
      'configs': configs,
  }},
                           sort_keys=True,
                           indent=2,
                           separators=(',', ': '))
  if output:
    with open(output, 'w') as output_stream:
      # Using print function adds proper trailing newline.
      print(json_output, file=output_stream)
  else:
    print(json_output)


def _bluetooth_id(project_name, bt_comp):
  return '_'.join(
      [project_name, bt_comp.vendor_id, bt_comp.product_id, bt_comp.bcd_device])


def _feature(name, present):
  attrib = {'name': name}
  if present:
    return etree.Element('feature', attrib=attrib)

  return etree.Element('unavailable-feature', attrib=attrib)


def _any_present(features):
  return topology_pb2.HardwareFeatures.PRESENT in features


def _arc_hardware_feature_id(design_config):
  return design_config.id.value.lower().replace(':', '_')


def _write_arc_hardware_feature_file(output_dir, file_name, config_content):
  output_dir += '/arc'
  os.makedirs(output_dir, exist_ok=True)
  output = '%s/%s' % (output_dir, file_name)
  file_content = minidom.parseString(config_content).toprettyxml(
      indent='  ', encoding='utf-8')

  with open(output, 'wb') as f:
    f.write(file_content)


def _write_arc_hardware_feature_files(config, output_dir, build_root_dir):
  """Writes ARC hardware_feature.xml files for each config

  Args:
    config: Source ConfigBundle to process.
    output_dir: Path to the generated output.
    build_root_path: Path to the config file from portage's perspective.
  Returns:
    dict that maps the design_config_id onto the correct file.
  """
  # pylint: disable=too-many-locals
  result = {}
  configs_by_design = {}
  for hw_design in config.designs.value:
    for design_config in hw_design.configs:
      hw_features = design_config.hardware_features
      any_camera = hw_features.camera.count.value > 0
      multi_camera = hw_features.camera.count == 2
      touchscreen = _any_present([hw_features.screen.touch_support])
      acc = hw_features.accelerometer
      gyro = hw_features.gyroscope
      compass = hw_features.magnetometer
      light_sensor = hw_features.light_sensor
      root = etree.Element('permissions')
      root.extend([
          _feature('android.hardware.camera', multi_camera),
          _feature('android.hardware.camera.autofocus', multi_camera),
          _feature('android.hardware.camera.any', any_camera),
          _feature('android.hardware.camera.front', any_camera),
          _feature(
              'android.hardware.sensor.accelerometer',
              _any_present([acc.lid_accelerometer, acc.base_accelerometer])),
          _feature('android.hardware.sensor.gyroscope',
                   _any_present([gyro.lid_gyroscope, gyro.base_gyroscope])),
          _feature(
              'android.hardware.sensor.compass',
              _any_present(
                  [compass.lid_magnetometer, compass.base_magnetometer])),
          _feature(
              'android.hardware.sensor.light',
              _any_present(
                  [light_sensor.lid_lightsensor,
                   light_sensor.base_lightsensor])),
          _feature('android.hardware.touchscreen', touchscreen),
          _feature('android.hardware.touchscreen.multitouch', touchscreen),
          _feature('android.hardware.touchscreen.multitouch.distinct',
                   touchscreen),
          _feature('android.hardware.touchscreen.multitouch.jazzhand',
                   touchscreen),
      ])

      design_name = hw_design.name.lower()

      # Constructs the following map:
      # design_name -> config -> design_configs
      # This allows any of the following file naming schemes:
      # - All configs within a design share config (design_name prefix only)
      # - Nobody shares (full design_name and config id prefix needed)
      #
      # Having shared configs when possible makes code reviews easier around
      # the configs and makes debugging easier on the platform side.
      config_content = etree.tostring(root)
      arc_configs = configs_by_design.get(design_name, {})
      design_configs = arc_configs.get(config_content, [])
      design_configs.append(design_config)
      arc_configs[config_content] = design_configs
      configs_by_design[design_name] = arc_configs

  for design_name, unique_configs in configs_by_design.items():
    for file_content, design_configs in unique_configs.items():
      file_name = 'hardware_features_%s.xml' % design_name
      if len(unique_configs) == 1:
        _write_arc_hardware_feature_file(output_dir, file_name, file_content)

      for design_config in design_configs:
        feature_id = _arc_hardware_feature_id(design_config)
        if len(unique_configs) > 1:
          file_name = 'hardware_features_%s.xml' % feature_id
          _write_arc_hardware_feature_file(output_dir, file_name, file_content)
        result[feature_id] = _file_v2('%s/arc/%s' % (build_root_dir, file_name),
                                      '/etc/%s' % file_name)
  return result


def _write_bluetooth_config_files(config, output_dir, build_root_path):
  """Writes bluetooth conf files for every unique bluetooth chip.

  Args:
    config: Source ConfigBundle to process.
    output_dir: Path to the generated output.
    build_root_path: Path to the config file from portage's perspective.
  Returns:
    dict that maps the bluetooth component id onto the file config.
  """
  output_dir += '/bluetooth'
  result = {}
  for hw_design in config.designs.value:
    project_name = hw_design.name.lower()
    for design_config in hw_design.configs:
      bt_comp = design_config.hardware_features.bluetooth.component.usb
      if bt_comp.vendor_id:
        bt_id = _bluetooth_id(project_name, bt_comp)
        result[bt_id] = _file_v2(
            '%s/bluetooth/%s.conf' % (build_root_path, bt_id),
            '/etc/bluetooth/%s/main.conf' % bt_id)
        bt_content = '''[General]
DeviceID = bluetooth:%s:%s:%s''' % (bt_comp.vendor_id, bt_comp.product_id,
                                    bt_comp.bcd_device)

        os.makedirs(output_dir, exist_ok=True)
        output = '%s/%s.conf' % (output_dir, bt_id)
        with open(output, 'w') as output_stream:
          # Using print function adds proper trailing newline.
          print(bt_content, file=output_stream)
  return result


def _read_config(path):
  """Reads a ConfigBundle proto from a json pb file.

  Args:
    path: Path to the file encoding the json pb proto.
  """
  config = config_bundle_pb2.ConfigBundle()
  with open(path, 'r') as f:
    return json_format.Parse(f.read(), config)


def _merge_configs(configs):
  result = config_bundle_pb2.ConfigBundle()
  for config in configs:
    result.MergeFrom(config)

  return result


def _camera_map(configs, project_name):
  """Produces a camera config map for the given configs.

  Produces a map that maps from the design name to the camera config for that
  design.

  Args:
    configs: Source ConfigBundle to process.
    project_name: Name of project processing for.

  Returns:
    map from design name to camera config.
  """
  result = {}
  for design in configs.designs.value:
    design_name = design.name
    config_path = CAMERA_CONFIG_SOURCE_PATH_TEMPLATE.format(design_name.lower())
    if os.path.exists(config_path):
      destination = CAMERA_CONFIG_DEST_PATH_TEMPLATE.format(design_name.lower())
      result[design_name] = {
          'config-path':
              destination,
          'config-file':
              _file_v2(os.path.join(project_name, config_path), destination),
      }
  return result


def _dptf_map(configs, project_name):
  """Produces a dptf map for the given configs.

  Produces a map that maps from design name to the dptf file config for that
  design. It looks for the dptf files at:
      DPTF_PATH + DPTF_FILE
  for a project wide config, that it maps under the empty string, and at:
      DPTF_PATH + design_name + DPTF_FILE
  for design specific configs that it maps under the design name.

  Args:
    configs: Source ConfigBundle to process.
    project_name: Name of project processing for.

  Returns:
    map from design name or empty string (project wide), to dptf config.
  """
  result = {}
  project_dptf_path = os.path.join(project_name, 'dptf.dv')
  # Looking at top level for project wide, and then for each design name
  # for design specific.
  dirs = [""] + [d.name for d in configs.designs.value]
  for directory in dirs:
    if os.path.exists(os.path.join(DPTF_PATH, directory.lower(), DPTF_FILE)):
      dptf_file = {
          'dptf-dv':
              project_dptf_path,
          'files': [
              _file(
                  os.path.join(project_name, DPTF_PATH, directory.lower(),
                               DPTF_FILE),
                  os.path.join('/etc/dptf', project_dptf_path))
          ]
      }
      result[directory] = dptf_file
  return result


def Main(project_configs, program_config, output):  # pylint: disable=invalid-name
  """Transforms source proto config into platform JSON.

  Args:
    project_configs: List of source project configs to transform.
    program_config: Program config for the given set of projects.
    output: Output file that will be generated by the transform.
  """
  configs = _merge_configs([_read_config(program_config)] +
                           [_read_config(config) for config in project_configs])
  bluetooth_files = {}
  arc_hw_feature_files = {}
  touch_fw = {}
  dptf_map = {}
  camera_map = {}
  output_dir = os.path.dirname(output)
  build_root_dir = output_dir
  if 'sw_build_config' in output_dir:
    full_path = os.path.realpath(output)
    project_name = re.match(r'.*/(\w*)/sw_build_config/.*',
                            full_path).groups(1)[0]
    # Projects don't know about each other until they are integrated into the
    # build system.  When this happens, the files need to be able to co-exist
    # without any collisions.  This prefixes the project name (which is how
    # portage maps in the project), so project files co-exist and can be
    # installed together.
    # This is necessary to allow projects to share files at the program level
    # without having portage file installation collisions.
    build_root_dir = os.path.join(project_name, output_dir)

    camera_map = _camera_map(configs, project_name)
    dptf_map = _dptf_map(configs, project_name)

  if os.path.exists(TOUCH_PATH):
    touch_fw = _build_touch_file_config(configs, project_name)
  bluetooth_files = _write_bluetooth_config_files(configs, output_dir,
                                                  build_root_dir)
  arc_hw_feature_files = _write_arc_hardware_feature_files(
      configs, output_dir, build_root_dir)
  config_files = ConfigFiles(
      bluetooth=bluetooth_files,
      arc_hw_features=arc_hw_feature_files,
      touch_fw=touch_fw,
      dptf_map=dptf_map,
      camera_map=camera_map)
  write_output(_transform_build_configs(configs, config_files), output)


def main(argv=None):
  """Main program which parses args and runs

  Args:
    argv: List of command line arguments, if None uses sys.argv.
  """
  if argv is None:
    argv = sys.argv[1:]
  opts = parse_args(argv)
  Main(opts.project_configs, opts.program_config, opts.output)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
