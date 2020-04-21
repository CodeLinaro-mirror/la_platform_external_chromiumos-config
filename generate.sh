#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

# Allows the recursive glob for proto files below to work.
shopt -s globstar

# Versions of packages to get from CIPD.
CIPD_PROTOC_VERSION='v3.6.1'
CIPD_PROTOC_GEN_GO_VERSION='v1.3.2'

# Move to this script's directory.
cd "$(dirname "$0")"

# Get protobuf compiler from CIPD.
cipd_root=.cipd_bin
cipd ensure \
  -log-level warning \
  -root "${cipd_root}" \
  -ensure-file - \
  <<ENSURE_FILE
infra/tools/protoc/\${platform} protobuf_version:${CIPD_PROTOC_VERSION}
chromiumos/infra/tools/protoc-gen-go version:${CIPD_PROTOC_GEN_GO_VERSION}
ENSURE_FILE

PATH="${cipd_root}:${PATH}"

# Collect all the protos.
protos=(proto/**/*.proto)

protoc -Iproto --descriptor_set_out=util/bindings/descpb.bin \
  --python_out=python "${protos[@]}"


# Go bindings are already namespaced under go.chromium.org/chromiumos/config/go
# We remove the "chromiumos/config" prefix from local path to avoid redundant
# namespaceing.
readonly GO_TEMP_DIR=$(mktemp -d)
trap "rm -rf ${GO_TEMP_DIR}" EXIT
# Go files need to be processed individually until this is fixed:
# https://github.com/golang/protobuf/issues/39
for proto in "${protos[@]}"; do
  protoc -I"proto" \
    --go_out=plugins=grpc,paths=source_relative:"${GO_TEMP_DIR}" \
    "${proto}"
done
cp -rf "${GO_TEMP_DIR}"/chromiumos/config/* go/
