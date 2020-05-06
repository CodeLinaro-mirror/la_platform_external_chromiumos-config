# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/bindings/proto.star", "protos")
load("//config/util/component.star", "comp")
load("//config/util/design.star", "design")
load("//config/util/hw_topology.star", "hw_topo")
load("//config/util/program.star", program_util = "program")
load("//config/util/build_target.star", bt_util = "build_target")

_FAKE_SOC = comp.create_soc_model(
    family = comp.create_soc_family(name = "FAKE_FAMILY"),
    model = "FAKE_MODEL",
    cores = 2,
    id = "FAKE_MODEL_2",
)

_SOC_MODELS = [_FAKE_SOC]

_FAKE_BT_COMP = comp.create_bt("0001", "0002", "0003")

_BT_COMPS = [_FAKE_BT_COMP]

_QUALIFIED_COMPS = _SOC_MODELS + _BT_COMPS

_QUAL_CONSTRAINTS = comp.create_quals(
    [comp.id for comp in _QUALIFIED_COMPS],
    comp.qual_status.QUALIFIED,
)

_FEATURE_CONSTRAINTS = design.create_constraints(
    hw_topo.create_features(),
)  # Default for now

_SIGNER_CONFIG = [
    program_util.create_signer_config("AAAA", "DEFAULT"),  # Ref design
    program_util.create_signer_config("FDAA", "KEYA"),  # Follow up design A
    program_util.create_signer_config("FDBB", "KEYB"),  # Follow up design B
    program_util.create_signer_config("FDCC", "KEYC"),  # Follow up design C
    program_util.create_signer_config("WLAA", "KEYD"),  # White label A
    program_util.create_signer_config("WLBB", "KEYE"),  # White label B
    program_util.create_signer_config("WLCC", "KEYF"),  # White label C
]

_FAKE = program_util.create(
    name = "FAKE_PROGRAM",
    component_quals = _QUAL_CONSTRAINTS,
    constraints = _FEATURE_CONSTRAINTS,
    device_signer_configs = _SIGNER_CONFIG,
)

_BUILD_TARGETS = [bt_util.create("fake", "overlay-fake-private")]

program = struct(
    fake = _FAKE,
    components = _QUALIFIED_COMPS,
    bluetooth_component = _FAKE_BT_COMP,
    build_targets = _BUILD_TARGETS,
)
