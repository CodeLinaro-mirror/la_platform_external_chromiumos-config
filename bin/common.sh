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
  echo "Usage: $0 [options] <config_file>" >&2
  echo "  where <config_file> is a main starlark" >&2
  echo "  configuration file, typically config.star" >&2
  echo
  echo "Options:"
  echo "  --no-proto - Don't regenerate proto definitions"
  exit 1
}

# Creates a python venv using vpython
#
# This piggybacks on the venv created by vpython itself. Once the venv is active
# the python/python3 commands will be symlinked to the vpython ones and we'll
# have access to the vpython site-packages (installed according to .vpython)
function create_venv() {
  # Bash gets variable scoping very wrong, even though we're declaring
  # a local variable here, it can still conflict with a read-only global
  # and throw an error, so use __ prefix as a workaround
  local -r __script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
  local -r __config_dir="$(realpath -e "${__script_dir}/../")"

  # Create and activate venv.  We use vpython3 here specifically because
  # depot_tools bundles its own python3 interpreter, which gives us a more
  # hermetic experience for vpython dependencies.
  local -r __vpython="vpython3 -vpython-spec ${__config_dir}/.vpython"
  local -r __venv_root="$(${__vpython} -c 'print(__import__("sys").prefix)')"

  # Ignore shellcheck non-constant source warning.
  # shellcheck source=/dev/null
  source "${__venv_root}/bin/activate"
}
