#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Convert a ConfigBundle instance to a FlatConfig instance.

ConfigBundle is a fully normalized format, where eg: Partners are referred to by
id. By denormalizing into a flattened format, we can more easily query projects."""

import argparse

from common import config_bundle_utils
from checker import io_utils


def flatten(infile, outfile):
  """Flatten a ConfigBundle .jsonproto file.

    Take a ConfigBundle in .jsonproto format, read it, flatten, and write the
    output FlatConfig to the given output file.

    Args:
      infile  (str): input file containing ConfigBundle in .jsonproto format
      outfile (str): filename to write flattened config to
  pars"""

  config = io_utils.read_config(infile)
  flatlist = config_bundle_utils.flatten_config(config)
  io_utils.write_message_json(flatlist, outfile)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      '-i',
      '--input',
      type=str,
      required=True,
      help="""ConfigBundle to flatten in jsonpb format.""")
  parser.add_argument(
      '-o',
      '--output',
      type=str,
      required=True,
      help='output file to write FlatConfigList jsonproto to')

  options = parser.parse_args()
  flatten(options.input, options.output)
