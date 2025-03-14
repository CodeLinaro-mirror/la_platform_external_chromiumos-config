#!/usr/bin/env bash

# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Common bash functions used for configuration generation and transforms.
function summarize() {
  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    echo "Config generation step succeeded"
  else
    echo "Config generation step failed!!!" >&2
  fi
}

function config_usage() {
  echo "Usage: $0 [options] <config_file>" >&2
  echo "  where <config_file> is a main starlark" >&2
  echo "  configuration file, typically config.star" >&2
  echo
  echo "Options:"
  echo "  --output-dir/-o <dir> - Directory to write output to (default cwd)"
  exit 1
}
