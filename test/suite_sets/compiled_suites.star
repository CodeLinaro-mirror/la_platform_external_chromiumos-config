# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges all Suites into a single list"""

load("//create.star", "create")
load("//suite_sets/cq/bvt-cq.star", "bvt_cq")
load("//suite_sets/cq/bvt-inline.star", "bvt_inline")
load("//suite_sets/cq/bvt-tast-cq.star", "bvt_tast_cq")
load("//suite_sets/example/example_suites.star", "example_suites")

_suites = []

_suites.extend(bvt_cq.all_suites())
_suites.extend(bvt_inline.all_suites())
_suites.extend(bvt_tast_cq.all_suites())
_suites.extend(example_suites.all_suites())

compiled_suites = create.suite_list(suites = _suites)
