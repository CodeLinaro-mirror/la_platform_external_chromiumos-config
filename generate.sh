#!/bin/bash -e
#
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

# Allows the recursive glob for proto files below to work.
shopt -s globstar

sha256_even_empty() {
  sha256sum <( [ -e "${1}" ] || echo )
}

script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
readonly script_dir
cd "${script_dir}"

readonly desc_file="generated/descriptors.json"
readonly gen_owners="generated/OWNERS"

desc_file_sha=$(sha256_even_empty "${desc_file}")
readonly desc_file_sha

gen_owners_sha=$(sha256_even_empty "${gen_owners}")
readonly gen_owners_sha

regenerate_golden() {
    # We want to split --path from the filenames so silence warning.
    # shellcheck disable=2068
    buf build --exclude-imports -o -#format=json ${proto_paths[@]} \
        | jq -S > "${desc_file}"
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

./generate_grpc_py_bindings.sh

source "setup_cipd.sh"

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
if ! buf breaking --against "${desc_file}"; then
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

echo "No breaking changes, regenerating '${desc_file}'"
# We want to split --path from the filenames so suppress warning about quotes.
# shellcheck disable=2068
buf build --exclude-imports --exclude-source-info \
    -o -#format=json ${proto_paths[@]}            \
    | jq -S > "${desc_file}"

# Check if golden file changed and inform use to commit it.
if [[ "$(sha256_even_empty "${desc_file}")" != "${desc_file_sha}" ]]; then
  echo
  echo "Please commit ${desc_file} with your change"
else
  echo "Clean diff on ${desc_file}, nothing else to do." >&2
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

protoc -Iproto \
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

protoc -Iproto \
  --go_out="${GO_TEMP_DIR}" --go_opt=paths=source_relative \
  "${proto_files[@]}" \
  --go-grpc_out="${GO_TEMP_DIR}" \
  --go-grpc_opt=require_unimplemented_servers=false,paths=source_relative \
  "${proto_files[@]}";

echo
echo "== Generating OWNERS file for generated code paths"
{
  echo "##### AUTO-GENERATED FILE #####"
  echo "##### See generate.sh     #####"
  # Use C locale for sorting to get stability between systems.
  find proto/* -type f -name "OWNERS*" -exec grep -h -E '^include' {} + | LC_COLLATE=C sort -u
  find proto/* -type f -name "OWNERS*" -exec grep -h -E '^[a-z0-9]+@.+\..+' {} + | LC_COLLATE=C sort -u
} > "${gen_owners}"

if [[ $(sha256_even_empty "${gen_owners}") != "${gen_owners_sha}" ]]; then
  echo
  echo "An OWNERS file was updated in the src/config/proto directory."
  echo "${gen_owners} was automatically updated based on this change."
  echo "Please commit ${gen_owners} with your change."
fi

GO_OUT_DIR="go/src/go.chromium.org/chromiumos/config/go"

cp -rf "${GO_TEMP_DIR}"/chromiumos/config/* "${GO_OUT_DIR}"/
cp "${GO_TEMP_DIR}"/chromiumos/*.go "${GO_OUT_DIR}"/
cp "${GO_TEMP_DIR}"/chromiumos/longrunning/*.go "${GO_OUT_DIR}"/longrunning/
cp -rf "${GO_TEMP_DIR}"/chromiumos/build/* "${GO_OUT_DIR}"/build/
cp -rf "${GO_TEMP_DIR}"/chromiumos/test/* "${GO_OUT_DIR}"/test/

echo
echo "== Regenerating DutAttributes"
starlark/dut_attributes/generate
