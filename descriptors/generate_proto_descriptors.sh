#!/bin/bash -e
# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Obtain the most recent proto descriptors from chromiumos/infra/proto protos.
# This is needed to work with these protos from *.star code.

if [[ -z "$1" ]] ; then
  echo "ERROR: $0 argument required: destination folder for descpb.bin."
  exit 1
fi

set -eu

PROTO_REPO="https://chromium.googlesource.com/chromiumos/infra/proto"
CROS_CONFIG_REPO="https://chromium.googlesource.com/chromiumos/config"

CIPD_PROTOC_VERSION='v3.17.0'
CIPD_PROTOC_GEN_GO_VERSION='v1.3.2'

script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
readonly script_dir

readonly target="$1/descpb.bin"


work_dir=$(mktemp --tmpdir -d genprotodescXXXXXX)
readonly work_dir
trap 'rm -rf ${work_dir}' EXIT
echo "Using temporary directory ${work_dir}"

if [[ -n ${CHROMIUMOS_PROTO_DIR+x} ]]; then
  echo "CHROMIUMOS_PROTO_DIR is set: " \
    "Copying sources from ${CHROMIUMOS_PROTO_DIR}/"
  cp -r "${CHROMIUMOS_PROTO_DIR}/" "${work_dir}/proto"
else
  echo "Creating a shallow clone of ${PROTO_REPO}"
  git clone -q --depth=1 --shallow-submodules "${PROTO_REPO}" \
    "${work_dir}/proto"
fi
readonly proto_subdir="proto/src"

if [[ -n ${CHROMIUMOS_CONFIG_DIR+x} ]]; then
  echo "CHROMIUMOS_CONFIG_DIR is set: " \
    "Copying sources from ${CHROMIUMOS_CONFIG_DIR}/"
  cp -r "${CHROMIUMOS_CONFIG_DIR}/" "${work_dir}/config"
else
  echo "Creating a shallow clone of ${CROS_CONFIG_REPO}"
  git clone -q --depth=1 --shallow-submodules "${CROS_CONFIG_REPO}" \
    "${work_dir}/config"
fi
readonly cros_config_subdir="config/proto"

echo "Grabbing protoc from CIPD"
cipd_root="${script_dir}/.cipd_bin"
cipd ensure \
  -log-level warning \
  -root "${cipd_root}" \
  -ensure-file - \
  <<ENSURE_FILE
infra/tools/protoc/\${platform} protobuf_version:${CIPD_PROTOC_VERSION}
chromiumos/infra/tools/protoc-gen-go version:${CIPD_PROTOC_GEN_GO_VERSION}
ENSURE_FILE

export PATH="${cipd_root}:${PATH}"

mapfile -t all_protos < <(
  cd "${work_dir}" &&
  find \
    "${proto_subdir}" \
    "${cros_config_subdir}" \
    -name "*.proto" | sort
)
readonly all_protos
(
  cd "${work_dir}" &&
  export LC_ALL=C  # for stable sorting order
  protoc \
    -I"${proto_subdir}" \
    -I"${cros_config_subdir}" \
    --descriptor_set_out=descpb.bin "${all_protos[@]}"
)

echo "Copying generated descriptors"
cp "${work_dir}/descpb.bin" "${target}"
