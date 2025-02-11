# Copyright 2024 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Contains all the pre-upload and pre-commit validation checks for SuiteSets"""

# [VPYTHON:BEGIN]
# python_version: "3.11"
# wheel: <
#   name: "infra/python/wheels/protobuf-py3"
#   version: "version:4.21.9"
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
    suite_sets = suite_set_utils.load_suite_sets([args.suite_set_file])
    suites = suite_set_utils.load_suites([args.suite_file])
    suite_set_utils.validate_centralized_suites(suite_sets + suites)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Validate SuiteSets",
        description=(
            "Validates the given Suite/SuiteSet files are well formed."
        ),
    )
    parser.add_argument(
        "--suite_set_file",
        help="Path to SuiteSet file to validate",
        required=True,
    )
    parser.add_argument(
        "--suite_file", help="Path to Suite file to validate", required=True
    )
    main(parser.parse_args())
