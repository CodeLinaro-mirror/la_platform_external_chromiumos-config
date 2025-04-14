#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts ConfigBundle json pb into json pb with int enums."""

import argparse
import sys

from chromiumos.config.payload import config_bundle_pb2
from chromiumos.config.prototype import prototype_config_bundle_pb2
from google.protobuf import json_format


def Main(input_config, output_config):  # pylint: disable=invalid-name
    """Converts ConfigBundle json pb into json pb with enums as ints.

    Args:
        input_config: path to input file to convert.
        output_config: path to write converted output file to.
    """
    config = config_bundle_pb2.ConfigBundle()
    try:
        with open(input_config, "r", encoding="utf-8") as f:
            json_format.Parse(f.read(), config)
    except json_format.ParseError:
        config = prototype_config_bundle_pb2.PrototypeConfigBundle()
        with open(input_config, "r", encoding="utf-8") as f:
            json_format.Parse(f.read(), config)

    json_output = json_format.MessageToJson(
        config, sort_keys=True, use_integers_for_enums=True
    )
    with open(output_config, "w", encoding="utf-8") as f:
        print(json_output, file=f)


def main():
    """Main program which parses args and runs Main."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-i",
        "--input_config",
        type=str,
        required=True,
        help="Source ConfigBundle JSON PB file.",
    )
    parser.add_argument(
        "-o",
        "--output_config",
        type=str,
        required=True,
        help="Output JSON PB file.",
    )
    args = parser.parse_args()
    Main(args.input_config, args.output_config)


if __name__ == "__main__":
    sys.exit(main())
