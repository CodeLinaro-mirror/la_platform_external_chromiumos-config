# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Loads proto descriptors of go.chromium.org/chromiumos/infra/proto protos into
# lucicfg proto registry, so protos defines there can be imported as
# load("@proto//...").

"""Proto descriptor import"""

lucicfg.check_version("1.8.6", "Please update depot_tools")

load("@stdlib//internal/descpb.star", "wellknown_descpb")

chromiumos_descpb = proto.new_descriptor_set(
    name = "chromiumos",
    blob = io.read_file("descpb.bin"),
    deps = [wellknown_descpb],
)
