#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

# Allows the recursive glob for proto files below to work.
shopt -s globstar

readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
# Move to this script's directory.
cd "${script_dir}"
# Uses ${script_dir}
source "./setup_cipd.sh"

# Remove files from prior python protocol buffer code generation in
# case any .proto files have been removed.
find python/ -type f -name '*_pb2.py' -delete
find python/chromiumos -mindepth 1 -type d -not -name __pycache__ \
  -exec rm -f '{}/__init__.py' \;

# Collect all the protos.
protos=(proto/**/*.proto)

protoc -Iproto --descriptor_set_out=util/bindings/descpb.bin \
  --python_out=python "${protos[@]}"
find python/chromiumos -mindepth 1 -type d -not -name __pycache__ \
  -exec touch '{}/__init__.py' \;


# Go bindings are already namespaced under go.chromium.org/chromiumos/config/go
# We remove the "chromiumos/config" prefix from local path to avoid redundant
# namespaceing.

# Remove files from prior go protocol buffer code generation in
# case any .proto files have been removed.
find go/ -name '*pb.go' -delete

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
