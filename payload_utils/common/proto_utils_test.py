# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for proto_utils."""

import unittest

from chromiumos.config.api.software import build_target_pb2
from common import proto_utils
from google.protobuf import timestamp_pb2


class ProtoUtilsTest(unittest.TestCase):
  """Tests for proto_utils."""

  def test_get_all_fields(self):
    """Tests getting all fields on a proto."""
    timestamp = timestamp_pb2.Timestamp(seconds=1, nanos=2)
    self.assertSequenceEqual([1, 2], proto_utils.get_all_fields(timestamp))

  def test_get_dep_graph(self):
    """Tests getting the depgraph of a proto."""
    self.assertDictEqual(
        proto_utils.get_dep_graph(build_target_pb2.BuildTarget()), {
            'chromiumos.config.api.software.BuildTarget': [
                'chromiumos.config.api.software.BuildTarget.ArcBuildProperties',
                'chromiumos.config.api.software.BuildTargetId'
            ],
            'chromiumos.config.api.software.BuildTarget.ArcBuildProperties': [],
            'chromiumos.config.api.software.BuildTargetId': []
        })

  def test_get_dep_order(self):
    """Tests getting the dependency order of a proto."""
    self.assertSequenceEqual(
        proto_utils.get_dep_order(build_target_pb2.BuildTarget()), [
            'chromiumos.config.api.software.BuildTarget.ArcBuildProperties',
            'chromiumos.config.api.software.BuildTargetId',
            'chromiumos.config.api.software.BuildTarget'
        ])
