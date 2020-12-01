#!/usr/bin/env gen_config

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//program.star", "program")
load("//config/util/config_bundle.star", "config_bundle")
load("//config/util/program.star", program_util = "program")

_CONFIG = config_bundle.create(
    components = program.components,
    programs = [program.fake],
)

program_util.generate(_CONFIG)
