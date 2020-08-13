# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for proto_utils."""

import unittest

from google.protobuf import field_mask_pb2
from google.protobuf import timestamp_pb2

from chromiumos.config.api.software import build_target_pb2

from chromiumos.config.public_replication.public_replication_pb2 import (
    PublicReplication)
from chromiumos.config.public_replication.testdata.public_replication_testdata_pb2 import (
    PublicReplicationTestdata,
    WrapperTestdata1,
    WrapperTestdata2,
    WrapperTestdata3,
)

from common import proto_utils


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

  def test_apply_public_replication(self):
    """Tests applying the PublicReplication message in the case where it is a
    field on the src argument.

    In this case, since PublicReplication is a field on
    PublicReplicationTestdata, no recursion is needed.
    """
    src = PublicReplicationTestdata(
        str1='abc',
        str2='def',
        public_replication=PublicReplication(
            public_fields=field_mask_pb2.FieldMask(paths=['str1'])),
    )

    expected = PublicReplicationTestdata(str1='abc')

    dst = PublicReplicationTestdata()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_nested_field(self):
    """Tests applying the PublicReplication message in the case where it is in
    a nested field on the src argument.

    In this case, recursion is required: src is a WrapperTestdata2, which has a
    WrapperTestdata1, which has a PublicReplicationTestdata.
    """
    src = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(
            n1=1,
            pr_testdata=PublicReplicationTestdata(
                str1='abc',
                str2='def',
                public_replication=PublicReplication(
                    public_fields=field_mask_pb2.FieldMask(paths=['str1'])),
            )))

    expected = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(
            pr_testdata=PublicReplicationTestdata(str1='abc',)))

    dst = WrapperTestdata2()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_nested_repeated_field(self):
    """Tests applying the PublicReplication message in the case where it is in
    a nested repeated field on the src argument.

    This case is similar to test_apply_public_replication_nested_field, but the
    PublicReplicationTestdata field is repeated. Note that the two
    PublicReplicationTestdata messages set different public_fields; this is
    possible, but not necessarily expected.
    """
    src = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(
            n1=1,
            repeated_pr_testdata=[
                PublicReplicationTestdata(
                    str1='abc',
                    str2='def',
                    public_replication=PublicReplication(
                        public_fields=field_mask_pb2.FieldMask(paths=['str1'])),
                ),
                PublicReplicationTestdata(
                    str1='abc',
                    str2='def',
                    public_replication=PublicReplication(
                        public_fields=field_mask_pb2.FieldMask(paths=['str2'])),
                ),
            ]))

    expected = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(repeated_pr_testdata=[
            PublicReplicationTestdata(str1='abc'),
            PublicReplicationTestdata(str2='def'),
        ]))

    dst = WrapperTestdata2()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_stacked_messages(self):
    """Tests that a PublicReplication message appearing on top of another in the
    dependency tree raises an Error.
    """
    with self.assertRaisesRegex(
        ValueError,
        'PublicReplication messages may not be defined on top of each other. '
        'Violating message: chromiumos.config.public_replication.testdata.PublicReplicationTestdata'
    ):
      proto_utils.apply_public_replication(WrapperTestdata3(),
                                           WrapperTestdata3())

  def test_apply_public_replication_empty_paths(self):
    """Tests applying the PublicReplication message with empty paths.

    If the FieldMask has empty paths, not fields should be replicated. Also test
    similar cases where public_replication and public_fields are not set.
    """
    srcs = [
        PublicReplicationTestdata(
            str1='abc',
            str2='def',
            public_replication=PublicReplication(
                public_fields=field_mask_pb2.FieldMask(paths=[])),
        ),
        PublicReplicationTestdata(
            str1='abc',
            str2='def',
        ),
        PublicReplicationTestdata(
            str1='abc',
            str2='def',
            public_replication=PublicReplication(),
        )
    ]

    expected = PublicReplicationTestdata()

    for src in srcs:
      dst = PublicReplicationTestdata()
      proto_utils.apply_public_replication(src, dst)
      self.assertEqual(dst, expected)

  def test_apply_public_replication_different_messages(self):
    """Tests that passing different messages to apply_public_replication raises
    an Error.
    """
    with self.assertRaisesRegex(
        ValueError, 'src and dst must be the same message type. Got '
        'chromiumos.config.public_replication.testdata.PublicReplicationTestdata'
        ' and chromiumos.config.public_replication.testdata.WrapperTestdata1'):
      proto_utils.apply_public_replication(PublicReplicationTestdata(),
                                           WrapperTestdata1())
