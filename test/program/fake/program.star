# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/bindings/proto.star", "protos")

protos.register()

load("//config/util/component.star", "comp")
load("//config/util/design.star", "design")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/program.star", program_util = "program")
load("//config/util/build_target.star", bt_util = "build_target")

_FAKE_SOC = comp.create_soc_model(
    family=comp.create_soc_family(name="FAKE_FAMILY"),
    model="FAKE_MODEL",
    cores=2,
    id="FAKE_MODEL_2",
)

_SOC_MODELS = [_FAKE_SOC]

_FAKE_BT_COMP = comp.create_bt("0001", "0002", "0003")

_BT_COMPS = [_FAKE_BT_COMP]

_QUALIFIED_COMPS = _SOC_MODELS + _BT_COMPS

_COMPONENTS = comp.create_list(
    _QUALIFIED_COMPS,
)

_QUAL_CONSTRAINTS = comp.create_quals(
    [comp.id for comp in _QUALIFIED_COMPS],
    comp.qual_status.QUALIFIED,
)

_FEATURE_CONSTRAINTS = design.create_constraints(
    hw_topo.create_features(),
)  # Default for now

_FAKE = program_util.create(
    name = "FAKE_PROGRAM",
    component_quals = _QUAL_CONSTRAINTS,
    constraints = _FEATURE_CONSTRAINTS,
)

_BUILD_TARGETS = [bt_util.create("fake", "overlay-fake-private")]

program = struct(
    fake = _FAKE,
    components = _COMPONENTS,
    build_targets = _BUILD_TARGETS
)
