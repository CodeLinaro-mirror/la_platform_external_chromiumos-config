#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Utilities for working with ConfigBundle instances more conveniently."""

from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle
from chromiumos.config.payload.flat_config_pb2 import FlatConfigList

from chromiumos.config.api import device_brand_pb2
from chromiumos.config.api.software import brand_config_pb2


def flatten_config(config: ConfigBundle) -> FlatConfigList:
  """Take a ConfigBundle and resolve all the values that are referred to by id.

  This denormalizes the ConfigBundle data to make it easier to query.

  Args:
    config: ConfigBundle instance to denormalize

  Returns
    FlatConfigList instance containing denormalized data for each device."""

  # pylint: disable=too-many-locals

  def _lookup(id_value, id_map):
    """Look up an id value in a given map, raise KeyError if not found"""
    key = id_value.value
    if not key:
      return None

    if key in id_map:
      return id_map[key]

    raise KeyError('Failed to lookup \'%s\' with value \'%s\'' %
                   (id_value.__class__.__name__.replace('Id', ''), key))

  # Break out global lists into maps from id => object
  partners = {p.id.value: p for p in config.partner_list}
  programs = {p.id.value: p for p in config.program_list}
  sw_configs = list(config.software_configs)
  brand_configs = {b.brand_id.value: b for b in config.brand_configs}

  results = FlatConfigList()
  for hw_design in config.design_list:
    device_brands = [device_brand_pb2.DeviceBrand()]
    if config.device_brand_list:
      device_brands = [
          x for x in config.device_brand_list
          if x.design_id.value == hw_design.id.value
      ]

    for device_brand in device_brands:
      # Brand config can be empty since platform JSON config allows it
      brand_config = brand_configs.get(device_brand.id.value,
                                       brand_config_pb2.BrandConfig())

      for hw_design_config in hw_design.configs:
        design_id = hw_design_config.id.value
        sw_config_matches = [
            x for x in sw_configs if x.design_config_id.value == design_id
        ]
        sw_config = sw_config_matches[0]

        # NOTE: We don't populate build_target because it doesn't share a
        # foreign key with anything. We'll store it as part of the build metadata
        # and use the BuildTargetId (overlay name) to look it up.
        flat_config = results.values.add()
        flat_config.program.MergeFrom(_lookup(hw_design.program_id, programs))
        flat_config.program_components.MergeFrom(config.components)
        flat_config.hw_design.MergeFrom(hw_design)
        flat_config.hw_design_config.MergeFrom(hw_design_config)
        flat_config.device_brand.MergeFrom(device_brand)
        flat_config.sw_config.MergeFrom(sw_config)
        flat_config.brand_sw_config.MergeFrom(brand_config)

        # We expect program_id to be defined above, but odm/oem is less consistently set
        if hw_design.odm_id.value:
          flat_config.odm.MergeFrom(_lookup(hw_design.odm_id, partners))

        if device_brand.oem_id.value:
          flat_config.oem.MergeFrom(_lookup(device_brand.oem_id, partners))

  return results


def find_partner(bundle: ConfigBundle, name: str, create=False):
  """Search for a partner with the given name (case insensitive).

  Args:
    bundle: config_bundle instance to search
    name: partner name to search for
    create: if partner isn't found, return a newly created one

  Returns:
    existing Partner if found, otherwise a newly created one or None
  """

  for partner in bundle.partner_list:
    if partner.name.lower() == name.lower():
      return partner

  if create:
    partner = bundle.partner_list.add()
    partner.id.value = name
    partner.name = name
    return partner
  return None


def find_program(bundle: ConfigBundle, name: str, create=False):
  """Search for a program with the given name (case insensitive).

  Args:
    bundle: config_bundle instance to search
    name: program name to search for
    create: if program isn't found, return a newly created one

  Returns:
    existing Program if found, otherwise a newly created one or None
  """

  for program in bundle.program_list:
    if program.name.lower() == name.lower():
      return program

  if create:
    program = bundle.program_list.add()
    program.id.value = name
    program.name = name
    return program
  return None
