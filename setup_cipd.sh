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
#
# Upon completion of this script the $PATH has been adjusted and other
# environment variables, such as $CIPD_ROOT, also exist for finer grained
# control.

if [[ -z "${script_dir}" ]]; then
     echo "The script_dir variable must be set when setup_cipd.sh is called."
     exit 1
fi

# Versions of packages to get from CIPD.
readonly CIPD_PROTOC_VERSION='v3.6.1'
readonly CIPD_PROTOC_GEN_GO_VERSION='v1.3.2'

readonly CIPD_ROOT="${script_dir}/.cipd_bin"
cipd ensure \
     -log-level warning \
     -root "${CIPD_ROOT}" \
     -ensure-file - \
     <<ENSURE_FILE
infra/tools/protoc/\${platform} protobuf_version:${CIPD_PROTOC_VERSION}
chromiumos/infra/tools/protoc-gen-go version:${CIPD_PROTOC_GEN_GO_VERSION}
infra/3pp/tools/go/\${platform} latest
ENSURE_FILE
PATH="${CIPD_ROOT}:${PATH}"
PATH="${CIPD_ROOT}/bin:${PATH}"

# Install buildifier (Starlark formatter) and add to PATH.
GOROOT="${CIPD_ROOT}"
go get github.com/bazelbuild/buildtools/buildifier
PATH="$(go env GOPATH)/bin:${PATH}"
