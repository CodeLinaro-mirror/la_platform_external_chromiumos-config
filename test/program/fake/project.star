# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/proto/proto.star", "protos")

protos.register()

def _defaults():
    pass  # TODO: generate defaults

project = struct(
    defaults = _defaults,
)
