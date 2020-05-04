# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for proto_utils."""

import unittest

from google.protobuf.timestamp_pb2 import Timestamp

from common import proto_utils


class ProtoUtilsTest(unittest.TestCase):
  """Tests for proto_utils."""

  def test_get_all_fields(self):
    """Tests getting all fields on a proto."""
    timestamp = Timestamp(seconds=1, nanos=2)
    self.assertSequenceEqual([1, 2], proto_utils.get_all_fields(timestamp))
