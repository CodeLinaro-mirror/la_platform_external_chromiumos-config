# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

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

_FW_MASKS = struct(
    DB = 0x0000000F,
    CAMERA = 0x000000F0,
    SENSOR = 0x00000F00,
)

_FIRMWARE_CONFIGURATION_SEGMENTS = [
    program_util.create_firmware_configuration_segment("Daughter board", _FW_MASKS.DB),
    program_util.create_firmware_configuration_segment("Camera", _FW_MASKS.CAMERA),
    program_util.create_firmware_configuration_segment("Sensor", _FW_MASKS.SENSOR),
]

_FEATURE_CONSTRAINTS = design.create_constraints(
    hw_topo.create_features(),
)  # Default for now

_SIGNER_BRAND_CONFIGS = program_util.create_signer_configs_by_brand(
    {
        "WLAA": "KEYD",  # White label A
        "WLBB": "KEYE",  # White label B
        "WLCC": "KEYF",  # White label C
    },
)

_SIGNER_DESIGN_CONFIGS = program_util.create_signer_configs_by_design(
    {
        "FAKE-REF-DESIGN": "DEFAULT",
        "PROJECT-A": "KEYA",  # Follow up design A
        "PROJECT-B": "KEYB",  # Follow up design B
        "PROJECT-C": "KEYC",  # Follow up design C
    },
)

_SIGNER_CONFIG = _SIGNER_BRAND_CONFIGS + _SIGNER_DESIGN_CONFIGS

_FAKE = program_util.create(
    name = "FAKE_PROGRAM",
    component_quals = _QUAL_CONSTRAINTS,
    constraints = _FEATURE_CONSTRAINTS,
    firmware_configuration_segments = _FIRMWARE_CONFIGURATION_SEGMENTS,
    device_signer_configs = _SIGNER_CONFIG,
)

_BUILD_TARGETS = [bt_util.create("fake", "overlay-fake-private")]

program = struct(
    fake = _FAKE,
    fw_masks = _FW_MASKS,
    components = _QUALIFIED_COMPS,
    bluetooth_component = _FAKE_BT_COMP,
    build_targets = _BUILD_TARGETS,
)
