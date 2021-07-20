#!/usr/bin/env generate
#
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Fake multi-device lab setup for testing."""

load("//config/util/generate.star", "generate")
load("//config/util/dut.star", "dut")

_CONFIG = dut.create_dut_topology(
    dut = dut.create_dut("fake_primary_hostname"),
    peer_duts = [
        dut.create_dut("fake_peer_dut_hostname"),
    ],
)

generate.generate(_CONFIG, "multidut.jsonproto")
