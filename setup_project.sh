#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Setup a project.

# Exit if any command fails, print commands and their arguments.
set -ex

function bail() {
  echo "${1}"
  exit 1
}

function usage() {
  echo "Usage: $0 <program> <project>" >&2
  exit 1
}

# Move to this script's directory.
cd "$(dirname "$0")"

if [[ $# -ne 2 ]]; then
  usage
fi

program="${1}"
project="${2}"

project_url="https://chrome-internal.googlesource.com/chromeos/project/${program}/${project}"
project_src="../../src/project/${program}/${project}"

if [[ -d "${project_src}" ]]; then
  bail "${project_src} already exists, exiting."
fi

git clone "${project_url}" "${project_src}"

local_manifests_dir="../../.repo/local_manifests"

if [[ ! -d  "${local_manifests_dir}" ]]; then
  mkdir -p "${local_manifests_dir}"
fi

symlink="${local_manifests_dir}/${project}.xml"
if [[ -e "${symlink}" ]]; then
  bail "${symlink} already exists, exiting."
fi

local_manifest="${project_src}/local_manifest.xml"
if [[ ! -e "${local_manifest}" ]]; then
  bail "Expected local manifest ${local_manifest} does not exist, exiting."
fi

ln -sr "${local_manifest}" "${symlink}"

repo sync --force-sync -j48
