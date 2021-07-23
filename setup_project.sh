#!/bin/bash
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

mkdir /tmp/setup_project 2>/dev/null
cipd install -force -root /tmp/setup_project \
  chromiumos/infra/setup_project/\$\{platform\} prod
if ! /tmp/setup_project/setup_project auth-info 1>/dev/null 2>&1;
then
  /tmp/setup_project/setup_project auth-login
fi
/tmp/setup_project/setup_project setup-project "$@"
