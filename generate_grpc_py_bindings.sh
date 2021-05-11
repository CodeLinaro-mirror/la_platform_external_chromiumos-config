#!/bin/bash -e
#
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Generates python proto bindings that include the grpc bindings.

readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"

cd "${script_dir}"

readonly venv_path=.venv
/usr/bin/python3 -m venv "${venv_path}"
source "${venv_path}/bin/activate"

echo "Installing grpcio-tools"
# TODO(crbug.com/1207957) Remove once this is included in vpython by default
pip install -q grpcio-tools==1.32.0

echo "Generating proto and grpc bindings"
python3 -m grpc_tools.protoc \
    -Iproto \
    --python_out=python \
    --grpc_python_out=python \
    proto/chromiumos/test/api/test_service.proto

deactivate
