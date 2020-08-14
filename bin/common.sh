# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Common bash functions used for configuration generation and transforms.
function summarize() {
  if [[ $? -eq 0 ]]; then
    echo "Config generation step succeeded"
  else
    echo "Config generation step failed!!!" >&2
  fi
}

function config_usage() {
  echo "Usage: $0 <config_file>" >&2
  echo "  where <config_file> is a main starlark" >&2
  echo "  configuration file, typically config.star" >&2
  exit 1
}
