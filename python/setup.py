# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from distutils.core import setup

setup(name='config',
      version='1.0',
      description='Module to access Config API python proto bindings',
      packages=['config'],
      package_data={'config': [
          'api/*.py',
          'api/software/*.py',
          'api/software/**/*.py',
          'test/*.py',
          'test/fake_program/*',
          'test/fake_project/*',
      ]},)
