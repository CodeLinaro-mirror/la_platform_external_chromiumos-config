# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to firmware configuration."""

import itertools
import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2
from common import proto_utils


def _topo_to_string(topo):
    return "{}:{}".format(topology_pb2.Topology.Type.Name(topo.type), topo.id)


class FirmwareConfigurationConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related to firmware configuration."""

    def check_firmware_configuration_masks(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks firmware configuration masks are valid.

        1. Check that the FirmwareConfigurationSegments defined in the program
           do not overlap.
        2. Check that each mask defined in a FirmwareConfiguration aligns with
           a segment.
        """
        del factory_dir
        fw_cfg_segments = {
            program.id.value: program.firmware_configuration_segments
            for program in program_config.program_list
        }
        for segments in fw_cfg_segments.values():
            for segment_a, segment_b in itertools.combinations(segments, 2):
                overlap = segment_a.mask & segment_b.mask
                self.assertFalse(
                    overlap,
                    msg="Overlap in masks {} and {}: {:b} & {:b} = {:b}".format(
                        segment_a.name,
                        segment_b.name,
                        segment_a.mask,
                        segment_b.mask,
                        overlap,
                    ),
                )

        # For every topology that defines a FirmwareConfiguration, check the
        # mask aligns with a segment.
        for design in project_config.design_list:
            segments = fw_cfg_segments[design.program_id.value]
            for config in design.configs:
                for topology in proto_utils.get_all_fields(
                    config.hardware_topology
                ):
                    mask = topology.hardware_feature.fw_config.mask
                    for seg in segments:
                        overlap = mask & seg.mask
                        if overlap:
                            self.assertEqual(
                                overlap,
                                seg.mask,
                                "Topology {} with fw_config mask 0x{:08X} did "
                                'not specify the complete fw_config field "{}"'
                                " with mask 0x{:08X}".format(
                                    _topo_to_string(topology),
                                    topology.hardware_feature.fw_config.mask,
                                    seg.name,
                                    seg.mask,
                                ),
                            )
                            # Remove the valid seg.mask to keep track of any
                            # extra mask in the topology value.
                            mask -= overlap
                    # After looping through all valid fw_config masks, ensure
                    # that topo's value is empty.
                    self.assertEqual(
                        mask,
                        0,
                        "Topology {} specifies fw_mask that is not known "
                        "0x{:08X}".format(_topo_to_string(topology), mask),
                    )

    def check_firmware_configuration_value_collision(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks that a given firmware value is only used by a single topology.

        More precisely: For a given project, each FirmwareConfiguration.value is
        used by exactly one (Topology.id, Topology.type) pair.

        For example, the following is a violation:

            thermal: <
              id: "DEFAULT_THERMAL"
              type: THERMAL
              hardware_feature: <
                fw_config: <
                  value: 11
                >
              >
            >
            screen: <
              id: "DEFAULT_SCREEN"
              type: SCREEN
              hardware_feature: <
                fw_config: <
                  value: 11
                >
              >
            >

        because both ("DEFAULT_THERMAL", THERMAL) and ("DEFAULT_SCREEN", SCREEN)
        use value 11.
        """
        del program_config, factory_dir

        # Map from FirmwareConfiguration.value -> (Topology.id, Topology.type).
        value_to_topo = {}

        for design in project_config.design_list:
            for config in design.configs:
                for topology in proto_utils.get_all_fields(
                    config.hardware_topology
                ):
                    fw_value = topology.hardware_feature.fw_config.value
                    if not fw_value:
                        continue

                    # Topologies must set id and type.
                    self.assertTrue(topology.id)
                    self.assertTrue(topology.type)
                    topo_key = (topology.id, topology.type)

                    prev_topo_key = value_to_topo.get(fw_value)
                    if prev_topo_key:
                        # We only need to ensure that the types are the same.
                        # Two different types cannot both set/control the same
                        # FW_CONFIG field value. It is allowed for two topology
                        # values of the same type to control the same FW_CONFIG
                        # field value (thus having the same FW_CONFIG value).
                        self.assertEqual(
                            topo_key[1],
                            prev_topo_key[1],
                            msg=(
                                "Topologies ({id1}, {type1}) and"
                                " ({id2}, {type2}) both use"
                                " firmware value {fw_value}"
                                " but have different types"
                            ).format(
                                id1=topo_key[0],
                                type1=topology_pb2.Topology.Type.Name(
                                    topo_key[1]
                                ),
                                id2=prev_topo_key[0],
                                type2=topology_pb2.Topology.Type.Name(
                                    prev_topo_key[1]
                                ),
                                fw_value=fw_value,
                            ),
                        )
                    else:
                        value_to_topo[fw_value] = topo_key
