#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Setup a project.

function bail() {
  echo "${1}"
  exit 1
}

function usage() {
  echo "Usage: $0 <program> <project>" >&2
  exit 1
}

if [[ $# -ne 2 ]]; then
  usage
fi

# Exit if any command fails, print commands and their arguments.
set -ex

# Move to this script's directory.
cd "$(dirname "$0")"

readonly program="${1}"
readonly project="${2}"

readonly project_url="https://chrome-internal.googlesource.com/chromeos/project/${program}/${project}"
readonly project_src="../../src/project/${program}/${project}"

readonly local_manifests_dir="../../.repo/local_manifests"
readonly symlink="${local_manifests_dir}/${project}.xml"

if [[ -d "${project_src}" ]]; then
  # If ${project_src} is already present the user is likely running
  # a second time when their first run failed. Users would do this
  # when they found they didn't have adequate permissions on a first
  # run. In this case we wipe the artifacts from the previous run and
  # try again.
  echo "Founding existing ${project_src} checkout, removing."
  rm -rf "${project_src}"
  rm -f "${symlink}"
fi

git clone "${project_url}" "${project_src}"

if [[ ! -d  "${local_manifests_dir}" ]]; then
  mkdir -p "${local_manifests_dir}"
fi

local_manifest="${project_src}/local_manifest.xml"
if [[ ! -e "${local_manifest}" ]]; then
  bail "Expected local manifest ${local_manifest} does not exist, exiting."
fi

ln -sr "${local_manifest}" "${symlink}"

repo sync --force-sync -j48
