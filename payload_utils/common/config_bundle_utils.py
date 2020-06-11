#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Utilities for working with ConfigBundle instances more conveniently."""

from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


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
