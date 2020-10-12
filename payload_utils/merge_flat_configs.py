#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Merge two FlatConfigList messages into a single FlatConfigList.

The second FlatConfigList is optional, in which case the first input is
copied to the output."""

import argparse

from checker import io_utils

from chromiumos.config.payload import flat_config_pb2


def merge(files, outfile):
  """Merge multiple FlatConfigList .jsonproto files.

  Merge the given files into a single FlatConfigList and write to the output.

  Args:
    files  ([str]): .jsonproto files containing FlatConfigList
    outfile (str): filename to which to write merged config
  """

  config = flat_config_pb2.FlatConfigList()
  for file in files:
    config.values.MergeFrom(io_utils.read_flat_config(file).values)
  io_utils.write_message_json(config, outfile)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      "input",
      type=str,
      nargs='+',
      help="FlatConfigList to merge in jsonpb format.")
  parser.add_argument(
      '-o',
      '--output',
      type=str,
      required=True,
      help='output file to write FlatConfigList jsonproto to')

  options = parser.parse_args()
  merge(options.input, options.output)
