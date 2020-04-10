# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from distutils.core import setup

setup(name='chromiumos',
      version='1.0',
      description='Module to access Config API python proto bindings',
      packages=['chromiumos'],
      package_data={'chromiumos': [
          'config/api/*.py',
          'config/api/software/*.py',
          'config/api/software/**/*.py',
          'config/payload/*.py',
          'config/test/*.py',
          'config/test/fake_program/*',
          'config/test/fake_project/*',
      ]},)
