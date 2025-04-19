#!/usr/bin/env vpython3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Join program stubs from project payloads to make full payloads.  Projects
set a Program instance with only the ID set.  We need to lookup that program
in the full set of flattened configs and populate it before materializing the
flattened protos.
"""

import argparse
import logging

from checker import io_utils
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundleList
from chromiumos.config.payload.flat_config_pb2 import FlatConfigList
from common import logging_utils


def main(opts):
    """Perform Program join operation on project configs."""
    logging.debug("Reading program configs")
    program_configs = io_utils.read_json_proto(
        ConfigBundleList(),
        opts.program_configs,
    )

    logging.debug("Reading project configs")
    project_configs = io_utils.read_json_proto(
        FlatConfigList(),
        opts.project_configs,
    )

    # Map program id => program proto
    logging.debug("Generating program map")
    program_map = {}
    for config in program_configs.values:
        for program in config.program_list:
            program_id = program.id.value.lower()
            logging.info("Saw config for program %s", program_id)
            program_map[program_id] = program

    # Fill in project configs
    logging.debug("Populating program payloads")
    for config in project_configs.values:
        program_id = config.hw_design.program_id.value.lower()
        program_config = program_map.get(program_id)
        if program_config:
            logging.debug(
                "  Linking design %s to program %s",
                config.hw_design_config.id.value,
                config.program.id.value,
            )
            config.program.CopyFrom(program_config)

    logging.debug("Writing output")
    io_utils.write_message_json(project_configs, opts.output)

    if opts.binary_output:
        io_utils.write_message_binary(project_configs, opts.binary_output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    logging_utils.parser_add_argument(parser)
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="file to write joined payload to",
    )

    parser.add_argument(
        "-b",
        "--binary-output",
        type=str,
        help=(
            "file to write the joined payload to in binary wire format, in "
            "addition to the jsonpb written to --output."
        ),
    )

    parser.add_argument(
        "-i",
        "--project-configs",
        type=str,
        required=True,
        help="file containing FlatConfigList with project ConfigBundles to join",
    )

    parser.add_argument(
        "-p",
        "--program-configs",
        type=str,
        required=True,
        help="file containing ConfigBundleList with program ConfigBundles",
    )

    args = parser.parse_args()
    logging_utils.config_logging(args)

    main(args)
