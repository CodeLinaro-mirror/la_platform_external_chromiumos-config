# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Sets up cipd packages for presubmit scripts.
#
# Scripts should set the script_dir variable and source this file:
#
#   readonly script_dir="$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")"
#   source "${script_dir}/setup_cipd.sh"
#
# Upon completion of this script the $PATH has been adjusted and other
# environment variables, such as $CIPD_ROOT, also exist for finer grained
# control.

if [[ -z "${script_dir}" ]]; then
     echo "The script_dir variable must be set when setup_cipd.sh is called."
     exit 1
fi

# Versions of packages to get from CIPD.
readonly CIPD_PROTOC_VERSION='3.17.1'
readonly CIPD_BUF_VERSION='0.46.0'

GOBIN="${script_dir}/.go_bin"
readonly CIPD_ROOT="${script_dir}/.cipd_bin"
cipd ensure \
     -log-level warning \
     -root "${CIPD_ROOT}" \
     -ensure-file - \
     <<ENSURE_FILE
fuchsia/third_party/jq/\${platform} latest
infra/3pp/tools/protoc/\${platform} version:2@${CIPD_PROTOC_VERSION}
infra/3pp/tools/go/\${platform} latest
infra/3pp/go/github.com/bufbuild/buf/\${platform} version:2@${CIPD_BUF_VERSION}
infra/3pp/go/github.com/protocolbuffers/protoc-gen-go/\${platform} protoc
infra/3pp/go/github.com/grpc/protoc-gen-go-grpc/\${platform} protoc
ENSURE_FILE

PATH="${GOBIN}:${PATH}"
PATH="${CIPD_ROOT}/bin:${CIPD_ROOT}:${PATH}"