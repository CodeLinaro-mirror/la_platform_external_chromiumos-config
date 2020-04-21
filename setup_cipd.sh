# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Sets up cipd packages for presubmit scripts.
#
# Scripts should set the script_dir variable and source this file:
#
#   readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
#   source "${script_dir}/setup_cipd.sh"

# Versions of packages to get from CIPD.
readonly CIPD_PROTOC_VERSION='v3.6.1'
readonly CIPD_PROTOC_GEN_GO_VERSION='v1.3.2'

readonly cipd_root="${script_dir}/.cipd_bin"
cipd ensure \
     -log-level warning \
     -root "${cipd_root}" \
     -ensure-file - \
     <<ENSURE_FILE
infra/tools/protoc/\${platform} protobuf_version:${CIPD_PROTOC_VERSION}
chromiumos/infra/tools/protoc-gen-go version:${CIPD_PROTOC_GEN_GO_VERSION}
infra/3pp/tools/go/\${platform} latest
ENSURE_FILE
PATH="${cipd_root}:${PATH}"
PATH="${cipd_root}/bin:${PATH}"
