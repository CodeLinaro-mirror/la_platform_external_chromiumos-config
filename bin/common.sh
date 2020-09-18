#!/usr/bin/env bash

# Copyright 2020 The Chromium OS Authors. All rights reserved.
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
  echo "Usage: $0 <config_file>" >&2
  echo "  where <config_file> is a main starlark" >&2
  echo "  configuration file, typically config.star" >&2
  exit 1
}

# Creates a Python venv and installs requirements.txt.
#
# This function must be called with a link to the src/config directory in cwd.
# The venv will be created as src/config/.venv and src/config/requirements.txt
# will be installed.
function create_venv(){
  # Create and activate venv.
  readonly venv_path=config/.venv
  /usr/bin/python3 -m venv "${venv_path}"
  # Ignore shellcheck non-constant source warning.
  # shellcheck source=/dev/null
  source "${venv_path}/bin/activate"

  # Install requirements.
  pip install wheel -q
  pip install -r config/requirements.txt -q
}