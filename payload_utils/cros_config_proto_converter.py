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

from collections import namedtuple

from chromiumos.config.api import device_brand_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2
from chromiumos.config.api.software import brand_config_pb2

from google.protobuf import json_format

Config = namedtuple('Config',
                    ['program',
                     'hw_design',
                     'odm',
                     'hw_design_config',
                     'device_brand',
                     'device_signer_config',
                     'oem',
                     'sw_config',
                     'brand_config',
                     'build_target'])

ConfigFiles = namedtuple('ConfigFiles',
                         ['bluetooth',
                          'arc_hw_features',
                          'dptf_file'])

DPTF_PATH = 'sw_build_config/platform/chromeos-config/thermal/dptf.dv'

def ParseArgs(argv):
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
      '-o',
      '--output',
      type=str,
      help='Output file that will be generated')
  return parser.parse_args(argv)


def _Set(field, target, target_name):
  if field:
    target[target_name] = field


def _BuildArc(config, config_files):
  if config.build_target.arc:
    build_properties = {
        'device': config.build_target.arc.device,
        'first-api-level': config.build_target.arc.first_api_level,
        'marketing-name': config.device_brand.brand_name,
        'metrics-tag': config.hw_design.name.lower(),
        'product': config.build_target.id.value,
    }
    if config.oem:
      build_properties['oem'] = config.oem.name
    result = {
        'build-properties': build_properties
    }
    feature_id = _ArcHardwareFeatureId(config.hw_design_config)
    if feature_id in config_files.arc_hw_features:
      result['hardware-features'] = config_files.arc_hw_features[feature_id]
    return result

def _BuildBluetooth(config, bluetooth_files):
  bt_flags = config.sw_config.bluetooth_config.flags
  # Convert to native map (from proto wrapper)
  bt_flags_map = dict(bt_flags)
  result = {}
  if bt_flags_map:
    result['flags'] = bt_flags_map
  bt_comp = config.hw_design_config.hardware_features.bluetooth.component
  if bt_comp.vendor_id:
    bt_id = _BluetoothId(config.hw_design.name.lower(), bt_comp)
    if bt_id in bluetooth_files:
      result['config'] = bluetooth_files[bt_id]
  return result


def _BuildFingerprint(hw_topology):
  if hw_topology.HasField('fingerprint'):
    fp = hw_topology.fingerprint.hardware_feature.fingerprint
    result = {}
    if fp.location != topology_pb2.HardwareFeatures.Fingerprint.NOT_PRESENT:
      location = fp.Location.DESCRIPTOR.values_by_number[fp.location].name
      result['sensor-location'] = location.lower().replace('_', '-')
      if fp.board:
        result['board'] = fp.board
    return result


def _FwBcsPath(payload):
  if payload and payload.firmware_image_name:
    return 'bcs://%s.%d.%d.0.tbz2' % (
        payload.firmware_image_name,
        payload.version.major,
        payload.version.minor)


def _FwBuildTarget(payload):
  if payload:
    return payload.build_target_name


def _BuildFirmware(config):
  fw_payload_config = config.sw_config.firmware
  fw_build_config = config.sw_config.firmware_build_config
  main_ro = fw_payload_config.main_ro_payload
  main_rw = fw_payload_config.main_rw_payload
  ec_ro = fw_payload_config.ec_ro_payload
  pd_ro = fw_payload_config.pd_ro_payload

  build_targets = {}

  _Set(fw_build_config.build_targets.depthcharge, build_targets, 'depthcharge')
  _Set(fw_build_config.build_targets.coreboot, build_targets, 'coreboot')
  _Set(fw_build_config.build_targets.ec, build_targets, 'ec')
  _Set(
      list(fw_build_config.build_targets.ec_extras), build_targets, 'ec_extras')
  _Set(fw_build_config.build_targets.libpayload, build_targets, 'libpayload')

  result = {
      'bcs-overlay': config.build_target.overlay_name,
      'build-targets': build_targets,
  }

  _Set(main_ro.firmware_image_name.lower(), result, 'image-name')

  _Set(_FwBcsPath(main_ro), result, 'main-ro-image')
  _Set(_FwBcsPath(main_rw), result, 'main-rw-image')
  _Set(_FwBcsPath(ec_ro), result, 'ec-ro-image')
  _Set(_FwBcsPath(pd_ro), result, 'pd-ro-image')

  _Set(
      config.hw_design_config.hardware_features.fw_config.value,
      result,
      'firmware-config',
  )

  return result


def _BuildFwSigning(config):
  if config.sw_config.firmware and config.device_signer_config:
    return {
        'key-id': config.device_signer_config.key_id,
        'signature-id': config.hw_design.name.lower(),
    }
  return {}


def _File(source, destination):
  return {
      'destination': destination,
      'source': source
  }


def _BuildAudio(config):
  alsa_path = '/usr/share/alsa/ucm'
  cras_path = '/etc/cras'
  project_name = config.hw_design.name.lower()
  if not config.sw_config.HasField('audio_config'):
    return {}
  audio = config.sw_config.audio_config
  card = audio.card_name
  card_with_suffix = audio.card_name
  if audio.ucm_suffix:
    card_with_suffix += '.' + audio.ucm_suffix
  files = []
  if audio.ucm_file:
    files.append(_File(
        audio.ucm_file,
        '%s/%s/HiFi.conf' % (alsa_path, card_with_suffix)))
  if audio.ucm_master_file:
    files.append(_File(
        audio.ucm_master_file,
        '%s/%s/%s.conf' % (alsa_path, card_with_suffix, card_with_suffix)))
  if audio.card_config_file:
    files.append(_File(
        audio.card_config_file, '%s/%s/%s' % (cras_path, project_name, card)))
  if audio.dsp_file:
    files.append(
        _File(audio.dsp_file, '%s/%s/dsp.ini' % (cras_path, project_name)))

  result = {
      'main': {
          'cras-config-dir': project_name,
          'files': files,
      }
  }
  if audio.ucm_suffix:
    result['main']['ucm-suffix'] = audio.ucm_suffix

  return result


def _BuildCamera(hw_topology):
  if hw_topology.HasField('camera'):
    camera = hw_topology.camera.hardware_feature.camera
    result = {}
    if camera.count.value:
      result['count'] = camera.count.value
    return result


def _BuildIdentity(hw_scan_config, program, brand_scan_config=None):
  identity = {}
  _Set(hw_scan_config.firmware_sku, identity, 'sku-id')
  _Set(hw_scan_config.smbios_name_match, identity, 'smbios-name-match')
  # 'platform-name' is needed to support 'mosys platform name'. Clients should
  # longer require platform name, but set it here for backwards compatibility.
  _Set(program.name, identity, 'platform-name')
  # ARM architecture
  _Set(hw_scan_config.device_tree_compatible_match, identity,
       'device-tree-compatible-match')

  if brand_scan_config:
    _Set(brand_scan_config.whitelabel_tag, identity, 'whitelabel-tag')

  return identity


def _Lookup(id_value, id_map):
  if id_value.value:
    key = id_value.value
    if key in id_map:
      return id_map[id_value.value]
    error = 'Failed to lookup %s with value: %s' % (
        id_value.__class__.__name__.replace('Id', ''), key)
    print(error)
    print('Check the config contents provided:')
    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(id_map)
    raise Exception(error)


def _TransformBuildConfigs(config, config_files=ConfigFiles({}, {}, None)):
  partners = dict([(x.id.value, x) for x in config.partners.value])
  programs = dict([(x.id.value, x) for x in config.programs.value])
  sw_configs = list(config.software_configs)
  brand_configs = dict([(x.brand_id.value, x) for x in config.brand_configs])

  if len(config.build_targets) != 1:
    # Artifact of sharing the config_bundle for analysis and transforms.
    # Integrated analysis of multiple programs/projects it the only time
    # having multiple build targets would be valid.
    raise Exception('Single build_target required for transform')

  results = {}
  for hw_design in config.designs.value:
    if config.device_brands.value:
      device_brands = [x for x in config.device_brands.value
                       if x.design_id.value == hw_design.id.value]
    else:
      device_brands = [device_brand_pb2.DeviceBrand()]

    for device_brand in device_brands:
      # Brand config can be empty since platform JSON config allows it
      brand_config = brand_config_pb2.BrandConfig()
      if device_brand.id.value in brand_configs:
        brand_config = brand_configs[device_brand.id.value]

      for hw_design_config in hw_design.configs:
        design_id = hw_design_config.id.value
        sw_config_matches = [x for x in sw_configs
                             if x.design_config_id.value == design_id]
        if len(sw_config_matches) == 1:
          sw_config = sw_config_matches[0]
        elif len(sw_config_matches) > 1:
          raise Exception('Multiple software configs found for: %s' % design_id)
        else:
          raise Exception('Software config is required for: %s' % design_id)

        program = _Lookup(hw_design.program_id, programs)
        signer_configs = dict(
            [(x.brand_id.value, x) for x in program.device_signer_configs])
        device_signer_config = None
        if signer_configs:
          device_signer_config = _Lookup(device_brand.id, signer_configs)

        transformed_config = _TransformBuildConfig(
            Config(
                program=program,
                hw_design=hw_design,
                odm=_Lookup(hw_design.odm_id, partners),
                hw_design_config=hw_design_config,
                device_brand=device_brand,
                device_signer_config=device_signer_config,
                oem=_Lookup(device_brand.oem_id, partners),
                sw_config=sw_config,
                brand_config=brand_config,
                build_target=config.build_targets[0]),
            config_files)

        config_json = json.dumps(transformed_config,
                                 sort_keys=True,
                                 indent=2,
                                 separators=(',', ': '))

        if config_json not in results:
          results[config_json] = transformed_config

  return list(results.values())


def _TransformBuildConfig(config, config_files):
  """Transforms Config instance into target platform JSON schema.

  Args:
    config: Config namedtuple
    config_files: Map to look up the generated config files.

  Returns:
    Unique config payload based on the platform JSON schema.
  """
  result = {
      'identity': _BuildIdentity(
          config.sw_config.id_scan_config,
          config.program,
          config.brand_config.scan_config),
      'name': config.hw_design.name.lower(),
  }

  _Set(_BuildArc(config, config_files), result, 'arc')
  _Set(_BuildAudio(config), result, 'audio')
  _Set(_BuildBluetooth(config, config_files.bluetooth), result, 'bluetooth')
  _Set(config.device_brand.brand_code, result, 'brand-code')
  _Set(_BuildCamera(
      config.hw_design_config.hardware_topology), result, 'camera')
  _Set(_BuildFirmware(config), result, 'firmware')
  _Set(_BuildFwSigning(config), result, 'firmware-signing')
  _Set(_BuildFingerprint(
      config.hw_design_config.hardware_topology), result, 'fingerprint')
  power_prefs = config.sw_config.power_config.preferences
  power_prefs_map = dict(
      (x.replace('_', '-'),
       power_prefs[x]) for x in power_prefs)
  _Set(power_prefs_map, result, 'power')
  _Set(config_files.dptf_file, result, 'thermal')

  return result


def WriteOutput(configs, output=None):
  """Writes a list of configs to platform JSON format.

  Args:
    configs: List of config dicts defined in cros_config_schema.yaml
    output: Target file output (if None, prints to stdout)
  """
  json_output = json.dumps(
      {'chromeos': {
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


def _BluetoothId(project_name, bt_comp):
  return '_'.join([project_name,
                   bt_comp.vendor_id,
                   bt_comp.product_id,
                   bt_comp.bcd_device])


def _Feature(name, present):
  attrib = {'name': name}
  if present:
    return etree.Element('feature', attrib=attrib)
  else:
    return etree.Element('unavailable-feature', attrib=attrib)


def _AnyPresent(features):
  return topology_pb2.HardwareFeatures.PRESENT in features;


def _ArcHardwareFeatureId(design_config):
  return design_config.id.value.lower().replace(':', '_')


def WriteArcHardwareFeatureFiles(config, output_dir, build_root_dir):
  """Writes ARC hardware_feature.xml files for each config

  Args:
    config: Source ConfigBundle to process.
    output_dir: Path to the generated output.
    build_root_path: Path to the config file from portage's perspective.
  Returns:
    dict that maps the design_config_id onto the correct file.
  """
  result = {}
  for hw_design in config.designs.value:
    for design_config in hw_design.configs:
      hw_features = design_config.hardware_features
      multi_camera = hw_features.camera.count == 2
      touchscreen = _AnyPresent([hw_features.screen.touch_support])
      acc = hw_features.accelerometer
      gyro = hw_features.gyroscope
      compass = hw_features.magnetometer
      ls = hw_features.light_sensor
      root = etree.Element('permissions')
      root.extend([
          _Feature('android.hardware.camera', multi_camera),
          _Feature('android.hardware.camera.autofocus', multi_camera),
          _Feature('android.hardware.sensor.accelerometer',
                   _AnyPresent(
                       [acc.lid_accelerometer, acc.base_accelerometer])),
          _Feature('android.hardware.sensor.gyroscope',
                   _AnyPresent(
                       [gyro.lid_gyroscope, gyro.base_gyroscope])),
          _Feature('android.hardware.sensor.compass',
                   _AnyPresent(
                       [compass.lid_magnetometer, compass.base_magnetometer])),
          _Feature('android.hardware.sensor.light',
                   _AnyPresent(
                       [ls.lid_lightsensor, ls.base_lightsensor])),
          _Feature('android.hardware.touchscreen', touchscreen),
          _Feature('android.hardware.touchscreen.multitouch', touchscreen),
          _Feature(
              'android.hardware.touchscreen.multitouch.distinct', touchscreen),
          _Feature(
              'android.hardware.touchscreen.multitouch.jazzhand', touchscreen),
      ])

      feature_id = _ArcHardwareFeatureId( design_config)

      file_name = 'hardware_features_%s.xml' % feature_id
      output = '%s/arc/%s' % (output_dir, file_name)
      file_content = minidom.parseString(
          etree.tostring(root)).toprettyxml(indent='  ', encoding='utf-8')

      with open(output, 'wb') as f:
        f.write(file_content)

      result[feature_id] = {
          'build-path': '%s/arc/%s' % (build_root_dir, file_name),
          'system-path': '/etc/%s' % file_name,
      }
  return result


def WriteBluetoothConfigFiles(config, output_dir, build_root_path):
  """Writes bluetooth conf files for every unique bluetooth chip.

  Args:
    config: Source ConfigBundle to process.
    output_dir: Path to the generated output.
    build_root_path: Path to the config file from portage's perspective.
  Returns:
    dict that maps the bluetooth component id onto the file config.
  """
  result = {}
  for hw_design in config.designs.value:
    project_name = hw_design.name.lower()
    for design_config in hw_design.configs:
      bt_comp = design_config.hardware_features.bluetooth.component
      if bt_comp.vendor_id:
        bt_id = _BluetoothId(project_name, bt_comp)
        result[bt_id] = {
            'build-path': '%s/bluetooth/%s.conf' % (build_root_path, bt_id),
            'system-path': '/etc/bluetooth/%s/main.conf' % bt_id,
        }
        bt_content = '''[General]
DeviceID = bluetooth:%s:%s:%s''' % (bt_comp.vendor_id,
                                    bt_comp.product_id,
                                    bt_comp.bcd_device)

        output = '%s/bluetooth/%s.conf' % (output_dir, bt_id)
        with open(output, 'w') as output_stream:
          # Using print function adds proper trailing newline.
          print(bt_content, file=output_stream)
  return result


def _ReadConfig(path):
  """Reads a ConfigBundle proto from a file.

  Reads a ConfigBundle proto from a file first attempting to parse as json
  pb and falling back to parsing as binary pb.
  TODO(crbug.com/1073530): remove binary pb fallback when transition to json pb
  is complete.

  Args:
    path: Path to the file encoding the proto.
  """
  try:
    return _ReadJsonProtoConfig(path)
  except:
    return _ReadBinaryProtoConfig(path)


def _ReadJsonProtoConfig(path):
  """Reads a json proto ConfigBundle from a file.

  Args:
    path: Path to the json proto.
  """
  config = config_bundle_pb2.ConfigBundle()
  with open(path, 'r') as f:
    return json_format.Parse(f.read(), config)


def _ReadBinaryProtoConfig(path):
  """Reads a binary proto ConfigBundle from a file.

  Args:
    path: Path to the binary proto.
  """
  with open(path, 'rb') as f:
    return config_bundle_pb2.ConfigBundle.FromString(f.read())


def _MergeConfigs(configs):
  result = config_bundle_pb2.ConfigBundle()
  for config in configs:
    result.MergeFrom(config)

  return result


def Main(project_configs,
         program_config,
         output):
  """Transforms source proto config into platform JSON.

  Args:
    project_configs: List of source project configs to transform.
    program_config: Program config for the given set of projects.
    output: Output file that will be generated by the transform.
  """
  configs =_MergeConfigs(
      [_ReadConfig(program_config)] +
      [_ReadConfig(config) for config in project_configs])
  bluetooth_files = {}
  arc_hw_feature_files = {}
  dptf_file = None
  output_dir = os.path.dirname(output)
  build_root_dir = output_dir
  # TODO(shapiroc): Make standard after all projects migrated to new structure
  if 'sw_build_config' in output_dir:
    full_path = os.path.realpath(output)
    project_name = re.match(
        r'.*/(\w*)/sw_build_config/.*', full_path).groups(1)[0]
    # Projects don't know about each other until they are integrated into the
    # build system.  When this happens, the files need to be able to co-exist
    # without any collisions.  This prefixes the project name (which is how
    # portage maps in the project), so project files co-exist and can be
    # installed together.
    # This is necessary to allow projects to share files at the program level
    # without having portage file installation collisions.
    build_root_dir = os.path.join(project_name, output_dir)

    if os.path.exists(DPTF_PATH):
      project_dptf_path = os.path.join(project_name, 'dptf.dv')
      dptf_file = {
          'dptf-dv': project_dptf_path,
          'files': [_File(os.path.join(project_name, DPTF_PATH),
                          os.path.join('/etc/dptf', project_dptf_path))]
      }
  if os.path.exists(os.path.join(output_dir, 'bluetooth')):
    bluetooth_files = WriteBluetoothConfigFiles(
        configs, output_dir, build_root_dir)
  if os.path.exists(os.path.join(output_dir, 'arc')):
    arc_hw_feature_files = WriteArcHardwareFeatureFiles(
        configs, output_dir, build_root_dir)
  config_files = ConfigFiles(
      bluetooth=bluetooth_files,
      arc_hw_features=arc_hw_feature_files,
      dptf_file=dptf_file
  )
  WriteOutput(_TransformBuildConfigs(configs, config_files), output)


def main(argv=None):
  """Main program which parses args and runs

  Args:
    argv: List of command line arguments, if None uses sys.argv.
  """
  if argv is None:
    argv = sys.argv[1:]
  opts = ParseArgs(argv)
  Main(opts.project_configs, opts.program_config, opts.output)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
