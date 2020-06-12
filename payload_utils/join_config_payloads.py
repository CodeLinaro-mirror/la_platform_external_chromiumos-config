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

import argparse
import logging
import os
import sys
import tempfile
import yaml

from common import config_bundle_utils

from checker import io_utils
from chromiumos.config.payload import config_bundle_pb2

# HWID databases use some custom tags, which are mostly legacy as far as I can
# tell, so we'll ignore them explicitly to allow the parser to succeed.
yaml.add_constructor('!re', lambda a, b: None)
yaml.add_constructor('!region_field', lambda a, b: None)
yaml.add_constructor('!region_component', lambda a, b: None)

# git repo locations
CROS_PLATFORM_REPO = 'https://chromium.googlesource.com/chromiumos/platform2'


def load_models(public_path, private_path):
  """Load model.yaml from a public and/or private path."""

  # Have to import this here since we need repos cloned and sys.path set up
  # pylint: disable=import-outside-toplevel, import-error
  from cros_config_host import cros_config_schema
  from libcros_config_host import CrosConfig
  # pylint: enable=import-outside-toplevel, import-error

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


def add_hwid_components(config_bundle, hwid_db):  #pylint: disable=unused-argument
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
  # TODO(smcallis): implement
  return config_bundle


def merge_model(config_bundle, design_config, model):  #pylint: disable=unused-argument
  """Merge model from model.yaml into a specific Design.Config instance.

  The ConfigBundle, and Design.Config are updated in place with
  model.yaml information.

  Args:
    config_bundle (ConfigBundle): top level ConfigBundle to update
    design_config (Design.Config): design config in the config bundle to update
    model (dict):  parsed model.yaml information for design_config

  Returns:
    A reference to the input config_bundle updated with data from model
  """

  del design_config
  del model

  # TODO(smcallis): implement
  return config_bundle


def merge_configs(config_path, project_name, public_path, private_path,
                  hwid_path):
  # pylint: disable=too-many-locals
  # pylint: disable=too-many-branches
  # pylint: disable=too-many-statements
  """Read and merge configs together, generating new config_bundle output."""

  config_bundle = config_bundle_pb2.ConfigBundle()
  if config_path:
    config_bundle = io_utils.read_config(config_path)

  models = load_models(public_path, private_path)
  hwid_db = load_hwid(hwid_path)

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
      program_design.id.value = prog_name
      program_design.name = proj_name
      program_design.program_id.MergeFrom(program.id)

    # Create new Design.Config, the board id is encoded according to CBI:
    #  http://go/chromiumsrc/chromiumos/docs/+/master/design_docs/cros_board_info.md
    design_config = program_design.configs.add()
    design_config.id.value = '{}:{}'.format(proj_name.capitalize(), sku)
    return program_design, design_config

  # The primary source of SKU truth is the model.yaml files.  We'll take each
  # sku we find there and attempt to match with a DesignConfig in the
  # ConfigBundles, and update it if we find it, otherwise creating a new one.
  for model in models.GetDeviceConfigs():
    identity = model.GetProperties('/identity')
    program = identity['platform-name']
    project = model.GetName()
    whitelabel = identity.get('whitelabel-tag', '').lower()

    sku = str(identity.get('sku-id', 'any')).lower()
    if sku == 'any':
      logging.info('skipping wildcard sku in %s', project)
      continue

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

    # If we have a whitelabel tag, then just create a new DeviceBrand instead of
    # actually updating the config, since that will be handled by the non white
    # label variant
    if whitelabel:
      # Find brand for whitelabel if it exists
      brand = None
      for val in config_bundle.device_brand_list:
        if val.brand_name == whitelabel:
          brand = val
          break

      if not brand:
        brand = config_bundle.device_brand_list.add()

      brand.design_id.MergeFrom(design.id)
      brand.id.value = whitelabel
      brand.brand_name = whitelabel
      brand.brand_code = model.GetProperties('/brand-code')

      # And a new BrandConfig to hold the whitelabel tag and wallpaper
      brand_config = None
      for val in config_bundle.brand_configs:
        if val.scan_config.whitelabel_tag == whitelabel:
          brand_config = val
          break

      if not brand_config:
        brand_config = config_bundle.brand_configs.add()

      brand_config.brand_id.MergeFrom(brand.id)
      brand_config.scan_config.whitelabel_tag = whitelabel

      wallpaper = model.GetWallpaperFiles()
      if wallpaper:
        brand_config.wallpaper = wallpaper.pop()
    else:
      merge_model(config_bundle, design_config, model)

  # Merge information from HWID into config bundle
  return add_hwid_components(config_bundle, hwid_db)


def main(options):
  """Runs the script."""

  def clone_repo(repo, path):
    """Clone a given repo to the given path in the file system."""
    cmd = 'git clone -q --depth=1 --shallow-submodules {repo} {path}'.format(
        repo=repo, path=path)
    print('Creating shallow clone of {repo} ({cmd})'.format(repo=repo, cmd=cmd))
    os.system(cmd)

  if not (options.config_bundle or options.project_name):
    raise RuntimeError(
        'At least one of {config_opt} or {project_opt} must be specified.'
        .format(
            config_opt='--config-bundle/-c', project_opt='--project-name/-p'))

  with tempfile.TemporaryDirectory(prefix='join_proto_') as temppath:
    clone_repo(CROS_PLATFORM_REPO, os.path.join(temppath, 'platform2'))

    # setup sys.path so we can import from the cloned repos
    sys.path.append(os.path.join(temppath, 'platform2', 'chromeos-config'))

    io_utils.write_message_json(
        merge_configs(options.config_bundle, options.project_name,
                      options.public_model, options.private_model,
                      options.hwid),
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
      '--public-model', type=str, help='public model.yaml file to merge')
  parser.add_argument(
      '--private-model', type=str, help='private model.yaml file to merge')
  parser.add_argument('--hwid', type=str, help='HWID database to merge')

  main(parser.parse_args(sys.argv[1:]))
