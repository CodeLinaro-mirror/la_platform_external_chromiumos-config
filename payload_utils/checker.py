#!/usr/bin/env python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Run a program's constraint checks on a project."""

import argparse
import os

from checker import io_utils


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

  print('Read project config: {}'.format(project_config))
  print('Read program config: {}'.format(program_config))


if __name__ == '__main__':
  main()
