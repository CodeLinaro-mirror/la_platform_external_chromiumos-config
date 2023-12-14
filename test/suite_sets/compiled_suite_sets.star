# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges all SuiteSets into a single list"""

load("//create.star", "create")
load("//suite_sets/example/example_suite_sets.star", "example_suite_sets")

_suite_sets = []

_suite_sets.extend(example_suite_sets.all_suite_sets())

compiled_suite_sets = create.suite_set_list(suite_sets = _suite_sets)
