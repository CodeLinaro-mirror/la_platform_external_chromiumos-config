#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Aggregate one or more protobuffer messages into an output message.

Takes a list of input messages and produces a single output message of some
aggregate type.  If the message and aggregate types are the same, then
the following operation is performed, merging messages.  Note that any repeated
fields are _concatenated_ not overwritten:

    output = OutputType()
    for input in inputs:
      output.MergeFrom(input)

If the types are different, then the inputs are aggregated into the
values field of the output:

    output = OutputType()
    for input in inputs:
        output.values.append(input)
"""

import argparse

from checker import io_utils
from common import proto_utils


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "inputs",
        type=str,
        nargs="+",
        help="message(s) to aggregate in jsonproto format",
    )

    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="output file to write aggregated messages to",
    )

    # TODO: remove defaults once config_postsubmit change rolls out
    parser.add_argument(
        "-m",
        "--message-type",
        type=str,
        default="chromiumos.config.payload.FlatConfigList",
        help="input message type to aggregate",
    )

    parser.add_argument(
        "-a",
        "--aggregate-type",
        type=str,
        default="chromiumos.config.payload.FlatConfigList",
        help="aggregage message type to output",
    )

    # load database of protobuffer name -> Type
    protodb = proto_utils.create_symbol_db()

    options = parser.parse_args()
    output = protodb.GetSymbol(options.aggregate_type)()
    for path in options.inputs:
        if options.message_type == options.aggregate_type:
            output.MergeFrom(
                io_utils.read_json_proto(
                    protodb.GetSymbol(options.message_type)(), path
                )
            )
        else:
            output.values.append(
                io_utils.read_json_proto(
                    protodb.GetSymbol(options.message_type)(), path
                )
            )

    io_utils.write_message_json(
        output, options.output, use_integers_for_enums=True
    )
