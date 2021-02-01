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
  read -r -p "${1} (y/N) " answer

  if [[ "${answer^^}" != "Y" ]]; then
    exit 0
  fi
}

function usage() {
  echo "Usage: $0 <program> <project> [<branch>]" >&2
  echo "  optionally pass branch to sync the project" >&2
  echo "  from the local manifest at the given branch." >&2
  exit 1
}

# Exit if any command fails.
set -e


if [[ $# -lt 2 ]]; then
  usage
fi

readonly program="${1}"
readonly project="${2}"
readonly branch="${3}"

prompt_continue "
If you are a googler and are working with an internal checkout you do
not need to run this script as you already have a full repo checkout.
Do you want to continue running this script?"

# Move to this script's directory.
cd "$(dirname "$0")"

readonly local_manifests_dir="../../.repo/local_manifests"

readonly clone_url="https://chrome-internal.googlesource.com/chromeos/project/${program}/${project}"
readonly clone_src="../../src/project/${program}/${project}"
readonly symlink="${local_manifests_dir}/${project}.xml"

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
if [[ -z "${branch}" ]]; then
  git clone "${clone_url}" "${clone_src}"
else
  git clone "${clone_url}" "${clone_src}" --branch "${branch}"
fi

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
