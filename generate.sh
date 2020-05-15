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

readonly google_api_repo_dir=$(mktemp -d)
readonly go_temp_dir=$(mktemp -d)
trap "rm -rf ${google_api_repo_dir} ${go_temp_dir}" EXIT

# We need `google.longrunning` from the below repo for long running operations,
# see http://aip.dev/151 for details.
readonly google_apis_repo_url="https://github.com/googleapis/api-common-protos"
readonly google_apis_repo_version="1.50.0"
wget -q -O - ${google_apis_repo_url}/tarball/${google_apis_repo_version} | \
  tar xz --strip-components=1 -C "${google_api_repo_dir}"
# We must generate descriptor for `google.longrunning.operations` separately
# since it is imported by not included in `descpb.bin` in below.
protoc -I${google_api_repo_dir} \
  --descriptor_set_out=util/bindings/google_longrunning_operations_descpb.bin \
  google/longrunning/operations.proto \
  google/api/annotations.proto \
  google/api/http.proto \
  google/rpc/status.proto

# Collect all the protos.
protos=(proto/**/*.proto)

readonly protoc_opts="-Iproto -I${google_api_repo_dir}"

PATH="${CIPD_ROOT}" protoc ${protoc_opts} \
  --descriptor_set_out=util/bindings/descpb.bin \
  --python_out=python "${protos[@]}"
find python/chromiumos -mindepth 1 -type d -not -name __pycache__ \
  -exec touch '{}/__init__.py' \;


# Go bindings are already namespaced under go.chromium.org/chromiumos/config/go
# We remove the "chromiumos/config" prefix from local path to avoid redundant
# namespaceing.

# Remove files from prior go protocol buffer code generation in
# case any .proto files have been removed.
find go/ -name '*pb.go' -delete

# Go files need to be processed individually until this is fixed:
# https://github.com/golang/protobuf/issues/39
for proto in "${protos[@]}"; do
  PATH="${CIPD_ROOT}" protoc ${protoc_opts} \
    --go_out=plugins=grpc,paths=source_relative:"${go_temp_dir}" \
    "${proto}"
done
cp -rf "${go_temp_dir}"/chromiumos/config/* go/
