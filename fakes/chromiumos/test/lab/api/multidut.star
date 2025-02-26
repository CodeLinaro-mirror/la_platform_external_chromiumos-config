#!/usr/bin/env generate
#
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Fake multi-device lab setup for testing."""

load("//config/util/generate.star", "generate")
load("//config/util/dut.star", "dut")

_CONFIG = dut.create_dut_topology(
    duts = [
        dut.create_dut("fake_primary_hostname"),
        dut.create_dut("fake_peer_dut_hostname"),
    ],
)

generate.generate(_CONFIG, "multidut.jsonproto")
