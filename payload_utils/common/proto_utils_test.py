# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for proto_utils."""

import unittest

from google.protobuf import field_mask_pb2
from google.protobuf import timestamp_pb2

from chromiumos.config.api.software import system_image_pb2

from chromiumos.config.public_replication.public_replication_pb2 import (
    PublicReplication)
from chromiumos.config.public_replication.testdata.public_replication_testdata_pb2 import (
    PublicReplicationTestdata,
    WrapperTestdata1,
    WrapperTestdata2,
    WrapperTestdata3,
    RecursiveMessage,
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
        proto_utils.get_dep_graph(system_image_pb2.SystemImage.BuildTarget()), {
            'chromiumos.config.api.software.Portage.BuildTarget': [],
            'chromiumos.config.api.software.SystemImage.BuildTarget': [
                'chromiumos.config.api.software.Portage.BuildTarget'
            ]
        }
    )



  def test_get_dep_order(self):
    """Tests getting the dependency order of a proto."""
    self.assertSequenceEqual(
        proto_utils.get_dep_order(system_image_pb2.SystemImage.BuildTarget()), [
            'chromiumos.config.api.software.Portage.BuildTarget',
            'chromiumos.config.api.software.SystemImage.BuildTarget'
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

  def test_apply_public_replication_unreplicated_repeated_field(self):
    """Tests applying the PublicReplication message in the case where a message
    in a repeated field is not replicated.

    Messages that have no fields replicated should not appear in the final
    output.
    """
    src = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(
            n1=1,
            repeated_pr_testdata=[
                PublicReplicationTestdata(
                    str1='abc',
                    str2='def',
                ),
                PublicReplicationTestdata(
                    str1='abc',
                    str2='def',
                    public_replication=PublicReplication(
                        public_fields=field_mask_pb2.FieldMask(paths=['str2'])),
                ),
            ]))

    # Note that only the second PublicReplicationTestdata field appears in the
    # output; the first has no fields replicated, so is deleted.
    expected = WrapperTestdata2(
        wrapper_testdata1=WrapperTestdata1(repeated_pr_testdata=[
            PublicReplicationTestdata(str2='def'),
        ]))

    dst = WrapperTestdata2()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_stacked_messages(self):
    """Tests applying PublicReplication messages that appear on top of each
    other in the dependency tree.
    """
    src = WrapperTestdata3(
        public_replication=PublicReplication(
            public_fields=field_mask_pb2.FieldMask(paths=['b1'])),
        b1=True,
        pr_testdata=PublicReplicationTestdata(
            public_replication=PublicReplication(
                public_fields=field_mask_pb2.FieldMask(paths=['str2'])),
            str1='teststr1',
            str2='teststr2',
        ),
    )

    expected = WrapperTestdata3(
        b1=True,
        pr_testdata=PublicReplicationTestdata(str2='teststr2',),
    )

    dst = WrapperTestdata3()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_stacked_messages_overlap(self):
    """Tests applying PublicReplication messages that appear on top of each
    other in the dependency tree, where there is overlap in the fields they
    specify.
    """
    # WrapperTestdata3 specifies that "pr_testdata" should be replicated. This
    # means the entire PublicReplicationTestdata message is replicated, even
    # though it specifies only "str2" should be replicated.
    src = WrapperTestdata3(
        public_replication=PublicReplication(
            public_fields=field_mask_pb2.FieldMask(paths=['pr_testdata'])),
        pr_testdata=PublicReplicationTestdata(
            public_replication=PublicReplication(
                public_fields=field_mask_pb2.FieldMask(paths=['str2'])),
            str1='teststr1',
            str2='teststr2',
        ),
    )

    expected = WrapperTestdata3(
        pr_testdata=PublicReplicationTestdata(
            public_replication=PublicReplication(
                public_fields=field_mask_pb2.FieldMask(paths=['str2'])),
            str1='teststr1',
            str2='teststr2',
        ),)

    dst = WrapperTestdata3()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, expected)

  def test_apply_public_replication_empty_paths(self):
    """Tests applying the PublicReplication message with empty paths.

    If the FieldMask has empty paths, no fields should be replicated. Also test
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

  def test_apply_public_replication_recursive_message(self):
    """Tests that a message that references itself as a field doesn't cause
    infinite recursion.
    """
    src = RecursiveMessage(
        b1=True,
        recursive_message=RecursiveMessage(b1=False),
    )
    dst = RecursiveMessage()
    proto_utils.apply_public_replication(src, dst)
    self.assertEqual(dst, RecursiveMessage())

  def test_create_symbol_db(self):
    """Test that we get a good symbol from the symbol database."""
    self.assertIsNot(
        proto_utils.create_symbol_db().GetSymbol(
            "chromiumos.config.payload.ConfigBundle"),
        None,
    )
