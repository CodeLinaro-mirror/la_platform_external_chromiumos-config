#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Filters a ConfigBundle based on PublicReplication messages."""

import argparse

from checker import io_utils
from chromiumos.config.payload import config_bundle_pb2
from common import proto_utils


def argument_parser():
    """Returns an ArgumentParser for the script."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        required=True,
        help=(
            "Path to the private config json proto e.g. "
            ".../chromiumos/src/project/project1/generated/config.jsonproto."
        ),
        metavar="PATH",
    )
    parser.add_argument(
        "--output",
        required=True,
        help=(
            "Path to the output the filtered public json proto. Note that if "
            "filtering for public fields produces an empty ConfigBundle, no "
            "output is written."
        ),
        metavar="PATH",
    )
    return parser


def main():
    """Runs the script."""
    parser = argument_parser()
    args = parser.parse_args()

    private_config = io_utils.read_config(args.input)
    public_config = config_bundle_pb2.ConfigBundle()

    proto_utils.apply_public_replication(private_config, public_config)

    # Skip writing an empty ConfigBundle.
    if public_config != config_bundle_pb2.ConfigBundle():
        io_utils.write_message_json(public_config, args.output)
    else:
        print(
            "Filtering for public fields produced an empty ConfigBundle, "
            "skipping writing output."
        )


if __name__ == "__main__":
    main()
