#!/usr/bin/env python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Run a program's constraint checks on a project."""

import argparse
import os

from checker import constraint_suite_discovery
from checker import io_utils

COMMON_CHECKS_PATH = os.path.join(
    os.path.dirname(__file__), 'checker', 'common_checks')


def argument_parser():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      '--program',
      required=True,
      help=('Path to the root of the program repo'
            ' e.g. .../chromiumos/src/program/program1'),
      metavar='PATH')
  parser.add_argument(
      '--project',
      required=True,
      help=('Path to the root of the project repo'
            ' e.g. .../chromiumos/src/project/program1/project1'),
      metavar='PATH')
  return parser


def main():
  parser = argument_parser()
  args = parser.parse_args()

  project_config = io_utils.read_repo_config(args.project)
  program_config = io_utils.read_repo_config(args.program)

  constraint_suite_directories = [
      COMMON_CHECKS_PATH,
      os.path.join(args.program, 'checks'),
      os.path.join(args.project, 'checks')
  ]

  constraint_suites = []
  for directory in constraint_suite_directories:
    constraint_suites.extend(
        constraint_suite_discovery.discover_suites(directory))

  for suite in constraint_suites:
    suite.run_checks(
        program_config=program_config, project_config=project_config, verbose=1)


if __name__ == '__main__':
  main()
