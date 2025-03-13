# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# pylint: skip-file

"""An example unittest on a ConstraintSuite."""

# Note that this file is currently only here to test the case where a
# ConstraintSuite appears as an attribute in two files (in the actual class def
# and as an import here), thus there are no actual unit tests.
from check_example1 import Example1ConstraintSuite
