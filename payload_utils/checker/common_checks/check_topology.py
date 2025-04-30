# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Constraint checks related to topologies."""

import pathlib

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2
from common import proto_utils


class TopologyConstraintSuite(constraint_suite.ConstraintSuite):
    """Constraint checks related to program and project ids."""

    __error_message_template = """
Two different messages found for id and type ({id}, {type})

First message:
{first_message}

Second message:

{second_message}
"""

    def check_topologies_consistent(
        self,
        program_config: config_bundle_pb2.ConfigBundle,
        project_config: config_bundle_pb2.ConfigBundle,
        factory_dir: pathlib.Path,
    ):
        """Checks all topologies in a project are consistent.

        Consistency is defined as: For a given Topology id and type, the entire
        Topology message is equal, where two messages are equal iff their binary
        serializations are equal.

        For example:

        {
          {
            "id": "part1",
            "type": "SCREEN",
            "description": {
              "EN": "The first type of screen"
            }
          },
          {
            "id": "part1",
            "type": "SCREEN",
            "description": {
              "EN": "The second type of screen"
            }
          }
        }

        is inconsistent because a given id and type ("part1" and "SCREEN") are
        used in different messages (descriptions are different.)
        """
        # program_config and factory_dir not used.
        del program_config, factory_dir

        # Map from (Topology.id, Topology.type) -> Topology.
        topology_map = {}

        for design in project_config.design_list:
            for config in design.configs:
                for topology in proto_utils.get_all_fields(
                    config.hardware_topology
                ):
                    key = (topology.id, topology.type)
                    prev_topology = topology_map.get(key)
                    if prev_topology:
                        # Consider two messages equal iff their serialized form
                        # is the same. Include a human-readable error message as
                        # well.
                        self.assertEqual(
                            prev_topology.SerializeToString(deterministic=True),
                            topology.SerializeToString(deterministic=True),
                            msg=self.__error_message_template.format(
                                id=key[0],
                                type=topology_pb2.Topology.Type.Name(key[1]),
                                first_message=prev_topology,
                                second_message=topology,
                            ),
                        )
                    else:
                        topology_map[key] = topology
