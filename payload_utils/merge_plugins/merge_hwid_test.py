# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Test for Hwid merging plugin"""

import unittest
from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle
from .merge_hwid import MergeHwid


def _mock_hwid_component(type_name, label, values):
  return {
      'components': {
          type_name: {
              'items': {
                  label: {
                      'values': values
                  },
              },
          },
      },
  }


class MergeHWidTests(unittest.TestCase):
  """Tests for MergeHwid plugin."""

  def test_audio_codec(self):
    """Test basic audio codec functionality."""
    test_label = 'ACLABEL123'
    test_name = 'ACLABEL:123'

    hwid = _mock_hwid_component(
        'audio_codec',
        test_label,
        {'name': test_name},
    )

    bundle = ConfigBundle()
    merger = MergeHwid(hwid_data=hwid)
    merger.merge(bundle)

    self.assertEqual(len(bundle.components), 1)
    component = bundle.components[0]
    self.assertEqual(component.hwid_type, 'audio_codec')
    self.assertEqual(component.hwid_label, test_label)
    self.assertEqual(component.id.value, test_label)
    self.assertEqual(component.name, test_name)
    self.assertEqual(component.audio_codec.name, test_name)

    # Should be nothing unparsed
    self.assertEqual(merger.residual(), {})
