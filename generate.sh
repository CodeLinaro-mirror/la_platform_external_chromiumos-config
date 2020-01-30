#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

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

all_protos=(
  chromite/infra/proto/src/chromiumos/common.proto
  src/config/api/build_config.proto
  src/config/api/component.proto
  src/config/api/component_id.proto
  src/config/api/config_bundle.proto
  src/config/api/design.proto
  src/config/api/design_config_id.proto
  src/config/api/design_id.proto
  src/config/api/device_brand.proto
  src/config/api/device_brand_id.proto
  src/config/api/hardware_topology.proto
  src/config/api/partner.proto
  src/config/api/partner_id.proto
  src/config/api/program.proto
  src/config/api/program_id.proto
  src/config/api/topology.proto
  src/third_party/chromiumos-overlay/proto/audio_config.proto
  src/third_party/chromiumos-overlay/proto/brand_config.proto
  src/third_party/chromiumos-overlay/proto/build_target_config_id.proto
  src/third_party/chromiumos-overlay/proto/design_variant_config.proto
  src/third_party/chromiumos-overlay/proto/firmware_config.proto
  src/platform2/bluetooth/proto/config.proto
  src/platform2/chromeos-config/proto/design_variant_id_scan_config.proto
  src/platform2/chromeos-config/proto/brand_id_scan_config.proto
  src/platform2/power_manager/config.proto
)

protoc -I../../ --descriptor_set_out=proto/descpb.bin "${all_protos[@]}"

# Clean up existing generated Go files.
find go -name '*.pb.go' -exec rm '{}' \;

# Go files need to be processed individually until this is fixed:
# https://github.com/golang/protobuf/issues/39
for proto in "${all_protos[@]}"; do
  # platform2 protos currently do not specify a go_package, so any proto
  # importing them specifies an invalid import path and cannot compile.
  # TODO(crbug.com/1046074): Compile platform2 protos once crrev.com/c/2023308
  # is submitted.
  if [[ $proto == src/config/* && $proto != src/config/api/build_config.proto ]]
  then
    protoc -I../../ --go_out=paths=source_relative:go "${proto}"
  fi
done

cd ./go
go test ./...