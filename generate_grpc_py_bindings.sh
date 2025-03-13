#!/bin/bash -e
#
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Generates python proto bindings that include the grpc bindings.

readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"

cd "${script_dir}"

echo "Generating proto and grpc bindings"
find proto/ -type f -name '*_service.proto' -exec \
vpython3 -m grpc_tools.protoc \
    -Iproto \
    --python_out=python \
    --grpc_python_out=python \
    {} +
