#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Setup a project.

function bail() {
  echo "${1}"
  exit 1
}

function prompt_continue() {
  read -p "${1} (y/N) " answer

  if [[ "${answer^^}" != "Y" ]]; then
    exit 0
  fi
}

function usage() {
  echo "Usage: $0 <program> [<project>]" >&2
  echo "  for setups with a single repo for the program with" >&2
  echo "  projects in subdirectories, only the program argument" >&2
  echo "  is provided." >&2
  exit 1
}

# Exit if any command fails.
set -e

prompt_continue "
If you are a googler and are working with an internal checkout you do
not need to run this script as you already have a full repo checkout.
Do you want to continue running this script?"

# Move to this script's directory.
cd "$(dirname "$0")"

readonly program="${1}"
# Will be empty if this is a single program repository project.
readonly project="${2}"

readonly local_manifests_dir="../../.repo/local_manifests"

if [[ -z "${project}" ]]; then
  readonly clone_url="https://chrome-internal.googlesource.com/chromeos/program/${program}"
  readonly clone_src="../../src/program/${program}"
  readonly symlink="${local_manifests_dir}/${program}.xml"
else
  readonly clone_url="https://chrome-internal.googlesource.com/chromeos/project/${program}/${project}"
  readonly clone_src="../../src/project/${program}/${project}"
  readonly symlink="${local_manifests_dir}/${project}.xml"
fi

if [[ -d "${clone_src}" ]]; then
  # If ${clone_src} is already present the user is likely running
  # a second time when their first run failed. Users would do this
  # when they found they didn't have adequate permissions on a first
  # run. In this case we wipe the artifacts from the previous run and
  # try again.
  prompt_continue "
${clone_src} appears to already exist. If you are
attempting to recover from a previous failed setup_project.sh attempt
this will attempt to fix it by removing it and resyncing. If you have
unsaved changes in ${clone_src} they will be lost.
Do you want to continue with the removal and resync?"

  echo "Founding existing ${clone_src} checkout, removing."
  rm -rf "${clone_src}"
  rm -f "${symlink}"
fi

# We only need the local_manifest.xml but have to clone to get it.
# Removing the rest of what we clone before we do the sync prevents
# a confusing error message from being shown to the user. The
# --force-sync below actually causes it to not be a problem, but we'd
# rather avoid the user having to interpret the error.
git clone "${clone_url}" "${clone_src}"
find "${clone_src}" -mindepth 1 ! -name local_manifest.xml -exec rm -rf {} +

if [[ ! -d  "${local_manifests_dir}" ]]; then
  mkdir -p "${local_manifests_dir}"
fi

local_manifest="${clone_src}/local_manifest.xml"
if [[ ! -e "${local_manifest}" ]]; then
  bail "Expected local manifest ${local_manifest} does not exist, exiting."
fi

ln -sr "${local_manifest}" "${symlink}"

repo sync --force-sync -j48
