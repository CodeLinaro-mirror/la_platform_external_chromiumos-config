# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Proto-related helper functions."""

from typing import Any, List

from google.protobuf import message as pb_message


def get_all_fields(message: pb_message.Message) -> List[Any]:
  """Returns the value of each field in message.

  Note that the value, not the name, is returned. For example, given a Timestamp
  message:

  {
    "seconds": 1,
    "nanos": 2
  }

  the result is [1, 2].
  """
  fields = []
  for field_descriptor in message.DESCRIPTOR.fields:
    fields.append(getattr(message, field_descriptor.name))
  return fields
