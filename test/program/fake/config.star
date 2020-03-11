#!/usr/bin/env lucicfg

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/config_bundle.proto", config_bundle_pb = "chromiumos.config.api")

load("//program.star", program = "program")
load("//config/util/program.star", program_util = "program")

_CONFIG = config_bundle_pb.ConfigBundle(
    components = program.components,
    build_targets = program.build_targets,
    programs = program_util.create_list([program.fake]),)

program_util.generate(_CONFIG)
