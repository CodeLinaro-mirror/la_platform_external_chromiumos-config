#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Run a program's constraint checks on a project."""

import argparse
import os
import pathlib

from checker import constraint_suite_discovery
from checker import io_utils


COMMON_CHECKS_PATH = os.path.join(
    os.path.dirname(__file__), "checker", "common_checks"
)


def argument_parser():
    """Returns an ArgumentParser for the script."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--program",
        required=True,
        help=(
            "Path to the program config json proto e.g. "
            ".../chromiumos/src/program/program1/generated/config.jsonproto."
        ),
        metavar="PATH",
    )
    parser.add_argument(
        "--project",
        required=True,
        help=(
            "Path to the project config binary proto e.g. "
            ".../chromiumos/src/project/project1/generated/config.jsonproto."
        ),
        metavar="PATH",
    )
    parser.add_argument(
        "--factory_dir",
        # TODO(crbug.com/1085429): Require this once passed by Recipes.
        required=False,
        type=pathlib.Path,
        help=(
            "Path to the project factory confir dir e.g."
            ".../chromiumos/src/project/project1/factory"
        ),
        metavar="PATH",
    )
    return parser


def main():
    """Runs the script."""
    parser = argument_parser()
    args = parser.parse_args()

    project_config = io_utils.read_config(args.project)
    program_config = io_utils.read_config(args.program)

    # Expect program checks in a 'checks' dir under the root of the program
    # repo.  Note that args.program points to the generated file, so use
    # dirname + '..' to find the root of the program repo.
    program_checks_dir = os.path.join(
        os.path.dirname(args.program), "../checks"
    )

    constraint_suite_directories = [
        program_checks_dir,
        COMMON_CHECKS_PATH,
    ]

    # If two suites have the same name, only run the one in the program
    # directory.  This allows programs to override common suites.
    constraint_suites = {}
    for directory in constraint_suite_directories:
        for suite in constraint_suite_discovery.discover_suites(directory):
            suite_name = suite.__class__.__name__
            if suite_name not in constraint_suites:
                constraint_suites[suite_name] = suite

    for suite in constraint_suites.values():
        suite.run_checks(
            program_config=program_config,
            project_config=project_config,
            factory_dir=args.factory_dir,
            verbose=1,
        )


if __name__ == "__main__":
    main()
