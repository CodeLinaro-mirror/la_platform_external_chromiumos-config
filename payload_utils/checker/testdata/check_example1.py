# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""An example constraint file for use in tests"""

from checker import constraint_suite


class Example1ConstraintSuite(constraint_suite.ConstraintSuite):

    def check_first_thing(self, program_config, project_config):
        pass

    def check_second_thing(self, program_config, project_config):
        pass
