# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges all Suites into a single list"""

load("//create.star", "create")
load("//suite_sets/example/example_suites.star", "example_suites")

_suites = []

_suites.extend(example_suites.all_suites())

compiled_suites = create.suite_list(suites = _suites)
