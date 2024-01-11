# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Contains all the pre-upload and pre-commit validation checks for SuiteSets"""

# [VPYTHON:BEGIN]
# python_version: "3.8"
# wheel: <
#   name: "infra/python/wheels/protobuf-py2_py3"
#   version: "version:3.18.1"
# >
# [VPYTHON:END]

import argparse
import pathlib
import sys


sys.path.insert(
    1,
    str(
        pathlib.Path(__file__).parent.resolve()
        / "../../../../platform/dev/src/chromiumos/test/python"
    ),
)

from src.tools import (  # noqa: E402 pylint: disable=wrong-import-position,no-name-in-module
    suite_set_utils,
)


def main(args):
    """Entry point."""
    if args.suite_set_file:
        suite_set_utils.load_suite_sets([args.suite_set_file])
    if args.suite_file:
        suite_set_utils.load_suites([args.suite_file])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Validate SuiteSets",
        description=(
            "Validates the given Suite/SuiteSet files are well formed. Only the"
            "given files are validated so if no files are given, none are"
            "validated."
        ),
    )
    parser.add_argument(
        "-ss", "--suite_set_file", help="Path to SuiteSet file to validate"
    )
    parser.add_argument(
        "-s", "--suite_file", help="Path to Suite file to validate"
    )
    main(parser.parse_args())
