#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Marshal ConfigBundles and store them into the UFS datastore through the Google datastore API.

By default, this function reads a ConfigBundleList from
'hw_design/generated/configs.jsonproto' and parses ConfigBundles from it. Using
the API specified, it encodes the ConfigBundle as a ConfigBundleEntity and
stores it into the UFS datastore.
"""

import argparse
import datetime
import logging

from google.cloud import datastore

from checker import io_utils
from common import proto_utils

# type constants
INPUT_TYPE = 'chromiumos.config.payload.ConfigBundleList'
OUTPUT_TYPE = 'chromiumos.config.payload.ConfigBundle'

# UFS services
UFS_DEV_PROJECT = 'unified-fleet-system-dev'
UFS_PROD_PROJECT = 'unified-fleet-system'

# datastore constants
CONFIG_BUNDLE_KIND = 'ConfigBundle'


def get_ufs_project(env):
  """Return project name based on env argument."""
  if env == 'dev':
    return UFS_DEV_PROJECT
  if env == 'prod':
    return UFS_PROD_PROJECT
  raise RuntimeError('get_ufs_project: environment %s not supported' % env)


def generate_entity_id(bundle):
  """Generate ConfigBundleEntity id as ${program_id}-${design_id}."""
  return bundle.design_list[0].program_id.value + '-' + bundle.design_list[
      0].id.value


def update_config_bundle(bundle, project):
  """Take a ConfigBundle and store it in the UFS datastore as a ConfigBundleEntity."""
  eid = generate_entity_id(bundle)
  logging.info('update_config_bundle: handling %s', eid)

  client = datastore.Client(project=project,)
  key = client.key(CONFIG_BUNDLE_KIND, eid)
  entity = datastore.Entity(
      key=key,
      exclude_from_indexes=['ConfigData'],
  )
  entity['ConfigData'] = bundle.SerializeToString()
  entity['updated'] = datetime.datetime.now()

  try:
    logging.info('update_config_bundle: putting entity into datastore for %s',
                 eid)
    client.put(entity)
  except Exception as err:  # pylint: disable=broad-except
    logging.exception('update_config_bundle: %s', err)


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  parser = argparse.ArgumentParser(
      description=__doc__,
      formatter_class=argparse.RawDescriptionHelpFormatter,
  )

  parser.add_argument(
      'input',
      type=str,
      help='message to read in jsonproto format',
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
  output = protodb.GetSymbol(OUTPUT_TYPE)()

  # read ConfigBundleList from options.input
  cb_list = io_utils.read_json_proto(
      protodb.GetSymbol(INPUT_TYPE)(), options.input)

  for config_bundle in cb_list.values:
    update_config_bundle(config_bundle, get_ufs_project(options.env))
