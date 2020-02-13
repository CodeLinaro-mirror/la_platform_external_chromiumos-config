#!/bin/bash -e
#
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Runs protoc over the configuration protos to produce generated proto code.

# Versions of packages to get from CIPD.
CIPD_PROTOC_VERSION='v3.6.1'

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
ENSURE_FILE

PATH="${cipd_root}:${PATH}"

protoc -I../../ --descriptor_set_out=proto/descpb.bin \
  --python_out=payload_utils/bindings \
  src/config/api/build_config.proto \
  src/config/api/component.proto \
  src/config/api/component_id.proto \
  src/config/api/config_bundle.proto \
  src/config/api/design.proto \
  src/config/api/design_config_id.proto \
  src/config/api/design_id.proto \
  src/config/api/device_brand.proto \
  src/config/api/device_brand_id.proto \
  src/config/api/hardware_topology.proto \
  src/config/api/mfg_config.proto \
  src/config/api/mfg_config_id.proto \
  src/config/api/partner.proto \
  src/config/api/partner_id.proto \
  src/config/api/program.proto \
  src/config/api/program_id.proto \
  src/config/api/topology.proto \
  src/third_party/chromiumos-overlay/proto/audio_config.proto \
  src/third_party/chromiumos-overlay/proto/brand_config.proto \
  src/third_party/chromiumos-overlay/proto/build_target_id.proto \
  src/third_party/chromiumos-overlay/proto/design_config_build_payload.proto \
  src/third_party/chromiumos-overlay/proto/firmware_config.proto \
  src/platform2/bluetooth/proto/config.proto \
  src/platform2/chromeos-config/proto/identity_scan_config.proto \
  src/platform2/power_manager/config.proto
