#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Convert a ConfigBundle instance to a FlatConfig instance.

ConfigBundle is a fully normalized format, where eg: Partners are referred to by
id. By denormalizing into a flattened format, we can more easily query projects.
"""

import argparse

from checker import io_utils
from common import config_bundle_utils
from common import logging_utils


def flatten(infile, outfile):
    """Flatten a ConfigBundle .jsonproto file.

    Take a ConfigBundle in .jsonproto format, read it, flatten, and write the
    output FlatConfig to the given output file.

    Args:
        infile (str): input file containing ConfigBundle in .jsonproto format
        outfile (str): filename to write flattened config to parse
    """

    config = io_utils.read_config(infile)
    flatlist = config_bundle_utils.flatten_config(config)
    io_utils.write_message_json(flatlist, outfile)
    print(str(len(flatlist.values)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    logging_utils.parser_add_argument(parser)
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        required=True,
        help="""ConfigBundle to flatten in jsonpb format.""",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="output file to write FlatConfigList jsonproto to",
    )

    args = parser.parse_args()
    logging_utils.config_logging(args)

    flatten(args.input, args.output)
