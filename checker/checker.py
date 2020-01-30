#!/usr/bin/env python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Stub implementation of the checker interface."""

import argparse


def argument_parser():
  parser = argparse.ArgumentParser()
  parser.add_argument('--program', metavar='PATH')
  parser.add_argument('--project', metavar='PATH')
  return parser


def main():
  parser = argument_parser()
  args = parser.parse_args()
  print('Called with project: {}'.format(args.project))
  print('Called with program: {}'.format(args.program))


if __name__ == '__main__':
  main()
