#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Marshal various scheduling configs. Store them into the UFS datastore
through the Google datastore API.

By default, this script converts a few config-related protos into datastore
entities:

1. ConfigBundleList from 'hw_design/generated/configs.jsonproto'
2. DutAttributeList from 'dut_attributes/generated/dut_attributes.jsonproto'
3. FlatConfigList from 'hw_design/generated/flattened.jsonproto'
4. DeviceStabilityList from
  '.../chromiumos/infra/config/testingconfig/generated/device_stability.cfg'

The lists are parsed and individual entities are extracted. Using the datastore
client specified, it encodes the protos as datastore entities and stores them
into the UFS datastore.
"""

import argparse
import datetime
import logging
import os

from google.cloud import datastore

from checker import io_utils
from common import proto_utils

# type constants
CB_INPUT_TYPE = 'chromiumos.config.payload.ConfigBundleList'
CB_OUTPUT_TYPE = 'chromiumos.config.payload.ConfigBundle'
DA_INPUT_TYPE = 'chromiumos.test.api.DutAttributeList'
DA_OUTPUT_TYPE = 'chromiumos.test.api.DutAttribute'
FC_INPUT_TYPE = 'chromiumos.config.payload.FlatConfigList'
FC_OUTPUT_TYPE = 'chromiumos.config.payload.FlatConfig'
DEV_STAB_INPUT_TYPE = 'chromiumos.test.dut.DeviceStabilityList'
DEV_STAB_OUTPUT_TYPE = 'chromiumos.test.dut.DeviceStability'

# UFS services
UFS_DEV_PROJECT = 'unified-fleet-system-dev'
UFS_PROD_PROJECT = 'unified-fleet-system'

# datastore constants
CONFIG_BUNDLE_KIND = 'ConfigBundle'
DUT_ATTRIBUTE_KIND = 'DutAttribute'
FLAT_CONFIG_KIND = 'FlatConfig'
DEVICE_STABILITY_KIND = 'DeviceStability'


def get_ufs_project(env):
  """Return project name based on env argument."""
  if env == 'dev':
    return UFS_DEV_PROJECT
  if env == 'prod':
    return UFS_PROD_PROJECT
  raise RuntimeError('get_ufs_project: environment %s not supported' % env)


def generate_config_bundle_id(bundle):
  """Generate ConfigBundleEntity id as ${program_id}-${design_id}."""
  return bundle.design_list[0].program_id.value + '-' + bundle.design_list[
      0].id.value


def handle_config_bundle_list(cb_list_path, client):
  """Take a path to a ConfigBundleList, iterate through the list and store into
  UFS datastore based on env.
  """
  cb_list = io_utils.read_json_proto(
      protodb.GetSymbol(CB_INPUT_TYPE)(), cb_list_path)

  for config_bundle in cb_list.values:
    update_config(config_bundle, client, flat=False)


def generate_flat_config_id(bundle):
  """Generate FlatConfigEntity id as ${program_id}-${design_id}-${design_config_id}
  if design_config_id is available. Else ${program_id}-${design_id}."""
  if bundle.hw_design_config.id.value:
    return bundle.hw_design.program_id.value + '-' + bundle.hw_design.id.value \
    + '-' + bundle.hw_design_config.id.value
  return bundle.hw_design.program_id.value + '-' + bundle.hw_design.id.value


def handle_flat_config_list(fc_list_path, client):
  """Take a path to a FlatConfigList, iterate through the list and store into
  UFS datastore based on env.
  """
  fc_list = io_utils.read_json_proto(
      protodb.GetSymbol(FC_INPUT_TYPE)(), fc_list_path)

  for flat_config in fc_list.values:
    update_config(flat_config, client, flat=True)


def update_config(config, client, flat=False):
  """Take a ConfigBundle or FlatConfig and store it an an entity in the UFS datastore."""
  if flat:
    kind = FLAT_CONFIG_KIND
    eid = generate_flat_config_id(config)
  else:
    kind = CONFIG_BUNDLE_KIND
    eid = generate_config_bundle_id(config)
  logging.info('update_config: handling %s', eid)

  key = client.key(kind, eid)
  entity = datastore.Entity(
      key=key,
      exclude_from_indexes=['ConfigData'],
  )
  entity['ConfigData'] = config.SerializeToString()
  entity['updated'] = datetime.datetime.now()

  logging.info('update_config: putting entity into datastore for %s', eid)
  client.put(entity)


def handle_dut_attribute_list(dut_attr_list_path, client):
  """Take a path to a DutAttributeList, iterate through the list and store into
  UFS datastore based on env.
  """
  dut_attr_list = io_utils.read_json_proto(
      protodb.GetSymbol(DA_INPUT_TYPE)(), dut_attr_list_path)

  for dut_attribute in dut_attr_list.dut_attributes:
    update_dut_attribute(dut_attribute, client)


def update_dut_attribute(attr, client):
  """Take a DutAttribute and store it in the UFS datastore as a DutAttributeEntity."""
  eid = attr.id.value
  logging.info('update_dut_attribute: handling %s', eid)

  key = client.key(DUT_ATTRIBUTE_KIND, eid)
  entity = datastore.Entity(
      key=key,
      exclude_from_indexes=['AttributeData'],
  )
  entity['AttributeData'] = attr.SerializeToString()
  entity['updated'] = datetime.datetime.now()

  logging.info('update_dut_attribute: putting entity into datastore for %s',
               eid)
  client.put(entity)


def handle_device_stability_list(dev_stab_list_path, client):
  """Take a path to a DeviceStabilityList, iterate through the list and store
  into UFS datastore based on env.
  """
  dev_stab_list = io_utils.read_json_proto(
      protodb.GetSymbol(DEV_STAB_INPUT_TYPE)(), dev_stab_list_path)

  for dev_stab in dev_stab_list.values:
    update_device_stability(dev_stab, client)


def update_device_stability(dev_stab, client):
  """Take a DeviceStability and store it in the UFS datastore as a
  DeviceStabilityEntity.
  """
  # TODO (justinsuen): May need to change this eventually. This assumes the use
  # of a single model (DutAttribute ID design_id) when defining a
  # DeviceStability entry.
  # http://cs/chromeos_internal/infra/config/testingconfig/target_test_requirements_config_helper.star?l=155
  for eid in dev_stab.dut_criteria[0].values:
    logging.info('update_device_stability: handling %s', eid)

    key = client.key(DEVICE_STABILITY_KIND, eid)
    entity = datastore.Entity(
        key=key,
        exclude_from_indexes=['StabilityData'],
    )
    entity['StabilityData'] = dev_stab.SerializeToString()
    entity['updated'] = datetime.datetime.now()

    logging.info(
        'update_device_stability: putting entity into datastore for %s', eid)
    client.put(entity)


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  parser = argparse.ArgumentParser(
      description=__doc__,
      formatter_class=argparse.RawDescriptionHelpFormatter,
  )

  parser.add_argument(
      '--env',
      type=str,
      default='dev',
      help='environment flag for UFS service',
  )

  # load database of protobuffer name -> Type
  protodb = proto_utils.create_symbol_db()
  options = parser.parse_args()
  ufs_ds_client = datastore.Client(project=get_ufs_project(options.env),)
  script_dir = os.path.dirname(os.path.realpath(__file__))

  handle_config_bundle_list("hw_design/generated/configs.jsonproto",
                            ufs_ds_client)
  handle_dut_attribute_list("dut_attributes/generated/dut_attributes.jsonproto",
                            ufs_ds_client)
  handle_flat_config_list("hw_design/generated/flattened.jsonproto",
                          ufs_ds_client)
  handle_device_stability_list(
      os.path.realpath(
          os.path.join(
              script_dir,
              "/../../../infra/config/testingconfig/generated/device_stability.cfg"
          )), ufs_ds_client)
