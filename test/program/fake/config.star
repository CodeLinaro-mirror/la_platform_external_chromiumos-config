#!/usr/bin/env gen_config

# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/config_bundle.star", "config_bundle")
load("//config/util/program.star", program_util = "program")
load("//program.star", "program")

_CONFIG = config_bundle.create(
    components = program.components,
    programs = [program.fake, program.fake_a],
)

program_util.generate(_CONFIG)
