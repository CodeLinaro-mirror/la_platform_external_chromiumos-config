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

from collections import namedtuple

from chromiumos.config.payload import config_bundle_pb2
from chromiumos.config.api import device_brand_pb2
from chromiumos.config.api.software import brand_config_pb2

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


def _BuildArc(config):
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
  return {
      'build-properties': build_properties
  }

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
    location = fp.Location.DESCRIPTOR.values_by_number[fp.location].name
    result = {
        'sensor-location': location.lower().replace('_', '-'),
    }
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

  if fw_build_config.HasField('build_targets') and any((
      _FwBuildTarget(main_ro),
      _FwBuildTarget(main_rw),
      _FwBuildTarget(ec_ro),
      _FwBuildTarget(pd_ro),
      fw_payload_config.ec_extras,
  )):
    raise ValueError(
        'FirmwareBuildConfig.build_targets cannot be set if build_target_name '
        'is set on any FirmwarePayload or ec_extras is set. '
        'FirmwarePayload.build_target_name is deprecated, please use '
        'FirmwareBuildConfig.build_targets instead.'
    )

  if fw_build_config.HasField('build_targets'):
    _Set(fw_build_config.build_targets.depthcharge, build_targets,
         'depthcharge')
    _Set(fw_build_config.build_targets.coreboot, build_targets, 'coreboot')
    _Set(fw_build_config.build_targets.ec, build_targets, 'ec')
    _Set(
        list(fw_build_config.build_targets.ec_extras), build_targets,
        'ec_extras')
    _Set(fw_build_config.build_targets.libpayload, build_targets, 'libpayload')
  else:
    _Set(_FwBuildTarget(main_ro), build_targets, 'depthcharge')
    # Default to RO build target if no RW set
    _Set(_FwBuildTarget(main_rw) or _FwBuildTarget(main_ro),
        build_targets,
        'coreboot')
    _Set(_FwBuildTarget(ec_ro), build_targets, 'ec')
    _Set(list(fw_payload_config.ec_extras), build_targets, 'ec_extras')
    # Default to EC build target if no PD set
    _Set(_FwBuildTarget(pd_ro) or _FwBuildTarget(ec_ro),
        build_targets,
        'libpayload')

  result = {
      'bcs-overlay': config.build_target.overlay_name,
      'build-targets': build_targets,
  }

  _Set(main_ro.firmware_image_name.lower(), result, 'image-name')

  if not any((
      main_ro.firmware_image_name,
      main_rw.firmware_image_name,
      ec_ro.firmware_image_name,
      pd_ro.firmware_image_name,
  )):
    result['no-firmware'] = True

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


def _TransformBuildConfigs(config, bluetooth_files={}):
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
            bluetooth_files)

        config_json = json.dumps(transformed_config,
                                 sort_keys=True,
                                 indent=2,
                                 separators=(',', ': '))

        if config_json not in results:
          results[config_json] = transformed_config

  return list(results.values())


def _TransformBuildConfig(config, bluetooth_files):
  """Transforms Config instance into target platform JSON schema.

  Args:
    config: Config namedtuple
    bluetooth_files: Map to look up the generated bluetooth config files.

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

  _Set(_BuildArc(config), result, 'arc')
  _Set(_BuildAudio(config), result, 'audio')
  _Set(_BuildBluetooth(config, bluetooth_files), result, 'bluetooth')
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


def WriteBluetoothConfigFiles(config, output_dir):
  """Writes bluetooth conf files for every unique bluetooth chip.

  Args:
    config: Source ConfigBundle to process.
    output_dir: Path to the generated output.
  Returns:
    dict that maps the bluetooth component id onto the file config.
  """
  project_gen_path = re.match(r'.*(generated.*)', output_dir).groups(1)[0]
  result = {}
  for hw_design in config.designs.value:
    project_name = hw_design.name.lower()
    for design_config in hw_design.configs:
      bt_comp = design_config.hardware_features.bluetooth.component
      if bt_comp.vendor_id:
        bt_id = _BluetoothId(project_name, bt_comp)
        result[bt_id] = {
            'build-path': '%s/%s/bluetooth/%s.conf' % (
                project_name, project_gen_path, bt_id),
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
  """Reads a binary proto from a file.

  Args:
    path: Path to the binary proto.
  """
  config = config_bundle_pb2.ConfigBundle()
  with open(path, 'rb') as f:
    config.ParseFromString(f.read())
  return config


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
  bt_files = {}
  # Extracts output directory through regex versus separate args
  if output and 'generated' in output:
    bt_files = WriteBluetoothConfigFiles(configs, os.path.dirname(output))
  WriteOutput(_TransformBuildConfigs(configs, bt_files), output)


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
