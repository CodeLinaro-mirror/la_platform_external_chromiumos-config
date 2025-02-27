#!/bin/bash -e
# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates the Suite and SuiteSet proto files.
#
# This depends on lucicfg binary which would normally be on a ChromeOS
# engineer's PATH as part of depot_tools.

set -e

script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
readonly script_dir
repo_root="$(realpath -e "${script_dir}/../..")"
readonly repo_root

package_root="${script_dir}"

usage="Regenerate Suite and SuiteSet protos.

Usage: ${0} [OPTION]...

Options:
  -r, --package-root      Package root starlark generation script
                          (default ${package_root})
  -h, --help              Display help output."

# Parse args
while [[ $# -ne 0 ]]; do
  case $1 in
  -r|--package-root)
    package_root="$2"
    shift
    ;;
  -h|--help)
    echo "${usage}"
    exit 0
    ;;
  *)
    echo "${usage}"
    exit 1
    ;;
  esac
  shift
done

# CWD to script location.
cd "${script_dir}"

# Make sure we have the latest lucicfg. If this fails, please be sure that you
# have a depot_tools checkout on your PATH.
update_depot_tools || echo "update_depot_tools not found"

if ! "${repo_root}/descriptors/generate_proto_descriptors.sh" \
     "${package_root}/proto"; then
  echo "The generation of proto descriptors failed."
  exit 1
fi

# Format the *.star files
lucicfg fmt

# Run the proto generation script
lucicfg generate "${package_root}/main.star"
