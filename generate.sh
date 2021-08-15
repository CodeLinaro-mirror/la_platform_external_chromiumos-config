#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

# Allows the recursive glob for proto files below to work.
shopt -s globstar

readonly golden_file="gen/golden_descriptors.json"
readonly gen_owners="gen/OWNERS"

regenerate_golden() {
    # We want to split --path from the filenames so silence warning.
    # shellcheck disable=2068
    buf build --exclude-imports -o -#format=json ${proto_paths[@]} \
        | jq -S > "${golden_file}"
}

allow_breaking=0
regen_golden=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --allow-breaking)
            allow_breaking=1
            shift
            ;;
        --force-regen-golden)
            regen_golden=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
readonly script_dir

cd "${script_dir}"
./generate_grpc_py_bindings.sh
source "./setup_cipd.sh" # uses script_dir

if [[ "${regen_golden}" -eq 1 ]]; then
  echo "Forcing regenerating of golden proto descriptors."
  regenerate_golden
  exit 0
fi

echo "protoc version: $(protoc --version)"
echo "buf version:    $(buf --version 2>&1)"

#### protobuffer checks
mapfile -t proto_files < <(find proto/ -type f -name '*.proto')
mapfile -t proto_paths < \
        <(find proto/ -type f -name '*.proto' -exec echo '--path {} ' \;)

echo
echo "== Checking for breaking protobuffer changes"
if ! buf breaking --against "${golden_file}"; then
    if [[ "${allow_breaking}" -eq 0 ]]; then
      (
          echo
          cat <<-EOF
One or more breaking changes detected.  If these are intentional, re-run
with --allow-breaking to allow the changes.
EOF
      ) >&2
      exit 1
    else
      cat <<EOF >&2
One or more breaking changes, but --allow-breaking specified, continuing.
EOF
    fi
fi

echo "No breaking changes, regenerating '${golden_file}'"
# We want to split --path from the filenames so suppress warning about quotes.
# shellcheck disable=2068
buf build --exclude-imports --exclude-source-info \
    -o -#format=json ${proto_paths[@]}            \
    | jq -S > "${golden_file}"

# Check if golden file changed and offer to submit it for the user.
if ! git diff --quiet "${golden_file}"; then
  echo
  echo "Please commit ${golden_file} with your change"
else
  echo "Clean diff on ${golden_file}, nothing else to do." >&2
fi

echo
echo "== Linting protobuffers"

# We want to split --path from the filenames so suppress warning about quotes.
# shellcheck disable=2068
if ! buf lint ${proto_paths[@]}; then
  echo "One or more files need cleanup" >&2
  exit
else
  echo "Files are clean"
fi

echo
echo "== Generating Python bindings"

# Remove files from prior python protocol buffer code generation in
# case any .proto files have been removed.
find python/ -type f -name '*_pb2.py' -delete
find python/chromiumos -mindepth 1 -type d -not -name __pycache__ \
  -exec rm -f '{}/__init__.py' \;

PATH="${CIPD_ROOT}" protoc -Iproto \
  --descriptor_set_out=util/bindings/descpb.bin \
  --python_out=python "${proto_files[@]}"
find python/chromiumos -mindepth 1 -type d -not -name __pycache__ \
  -exec touch '{}/__init__.py' \;

echo
echo "== Generating Go bindings"

# Go bindings are already namespaced under go.chromium.org/chromiumos/config/go
# We remove the "chromiumos/config" prefix from local path to avoid redundant
# namespaceing.

# Remove files from prior go protocol buffer code generation in
# case any .proto files have been removed.
find go/ -name '*pb.go' -delete

GO_TEMP_DIR=$(mktemp -d)
readonly GO_TEMP_DIR
trap 'rm -rf ${GO_TEMP_DIR}' EXIT

# Go files need to be processed individually until this is fixed:
# https://github.com/golang/protobuf/issues/39
for proto in "${proto_files[@]}"; do
  PATH="${CIPD_ROOT}" protoc -I"proto" \
    --go_out=plugins=grpc,paths=source_relative:"${GO_TEMP_DIR}" \
    "${proto}"
done

echo
echo "== Generating OWNERS file for generated code paths"
echo "##### AUTO-GENERATED FILE #####" > "${gen_owners}"
echo "##### See generate.sh     #####" >> "${gen_owners}"
find proto/* -type f -name "OWNERS*" | xargs cat | grep -E ^include | sort | uniq >> "${gen_owners}"
find proto/* -type f -name "OWNERS*" | xargs cat | grep -E ^[a-z0-9]+@.+\..+ | sort | uniq >> "${gen_owners}"

if ! git diff --quiet "${gen_owners}"; then
  echo
  echo "An OWNERS file was updated in the src/config/proto directory."
  echo "${gen_owners} was automatically updated based on this change."
  echo "Please commit ${gen_owners} with your change."
fi

cp -rf "${GO_TEMP_DIR}"/chromiumos/config/* go/
cp "${GO_TEMP_DIR}"/chromiumos/*.go go/
cp "${GO_TEMP_DIR}"/chromiumos/longrunning/*.go go/longrunning
cp -rf "${GO_TEMP_DIR}"/chromiumos/build/* go/build/
cp -rf "${GO_TEMP_DIR}"/chromiumos/test/* go/test
