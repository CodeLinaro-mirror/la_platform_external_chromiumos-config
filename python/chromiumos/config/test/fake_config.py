#!/usr/bin/env python3
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

THIS_DIR = os.path.dirname(__file__)

CONFIG_BINARY = 'config.binaryproto'

FAKE_PROGRAM_CONFIG = '%s/fake_program/%s' % (THIS_DIR, CONFIG_BINARY)
FAKE_PROJECT_CONFIG = '%s/fake_project/%s' % (THIS_DIR, CONFIG_BINARY)
