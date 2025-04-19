# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from setuptools import find_packages
from setuptools import setup


setup(
    name="chromiumos",
    version="1.0",
    description="Module to access Config API python proto bindings",
    packages=find_packages(),
    package_data={
        "chromiumos.config.test": ["fake_program/*", "fake_project/*"]
    },
)
