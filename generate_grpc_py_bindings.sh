#!/bin/bash -e
#
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Generates python proto bindings that include the grpc bindings.

readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"

cd "${script_dir}"

source "${script_dir}/bin/common.sh"
create_venv

echo "Generating proto and grpc bindings"
python3 -m grpc_tools.protoc \
    -Iproto \
    --python_out=python \
    --grpc_python_out=python \
    proto/chromiumos/test/api/callbox_service.proto \
    proto/chromiumos/test/api/dut_service.proto \
    proto/chromiumos/test/api/execution_service.proto \
    proto/chromiumos/test/api/provision_service.proto

deactivate
