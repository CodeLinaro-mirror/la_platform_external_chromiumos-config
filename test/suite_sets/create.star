# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Exposes functions that construct SuiteSet related proto messages."""

load(
    "@proto//chromiumos/test/api/suite_set.proto",
    suite_set_pb = "chromiumos.test.api",
)
load(
    "@proto//chromiumos/test/api/test_case.proto",
    test_case_pb = "chromiumos.test.api",
)
load(
    "@proto//chromiumos/test/api/test_case_metadata.proto",
    test_case_metadata_pb = "chromiumos.test.api",
)

def _create_suite_list(suites):
    return suite_set_pb.SuiteList(suites = suites)

def _create_suite(suite_id, owners, bug_component, criteria, tests):
    return suite_set_pb.Suite(
        id = _create_suite_id(suite_id),
        metadata = _create_metadata(owners, bug_component, criteria),
        tests = [_create_test_id(test) for test in tests],
    )

def _create_suite_set_list(suite_sets):
    return suite_set_pb.SuiteSetList(suite_sets = suite_sets)

def _create_suite_set(
        suite_set_id,
        owners,
        bug_component,
        criteria,
        suite_sets,
        suites):
    return suite_set_pb.SuiteSet(
        id = _create_suite_set_id(suite_set_id),
        metadata = _create_metadata(owners, bug_component, criteria),
        suite_sets = [_create_suite_set_id(suite_set) for suite_set in suite_sets],
        suites = [_create_suite_id(suite) for suite in suites],
    )

def _create_suite_id(suite_id):
    return suite_set_pb.Suite.Id(value = suite_id)

def _create_suite_set_id(suite_set_id):
    return suite_set_pb.SuiteSet.Id(value = suite_set_id)

def _create_test_id(test_id):
    return test_case_pb.TestCase.Id(value = test_id)

def _create_metadata(owners, bug_component, criteria):
    return suite_set_pb.Metadata(
        owners = [_create_owner(owner) for owner in owners],
        bug_component = _create_bug_component(bug_component),
        criteria = _create_criteria(criteria),
    )

def _create_bug_component(bug_component):
    return test_case_metadata_pb.BugComponent(value = bug_component)

def _create_criteria(criteria):
    return test_case_metadata_pb.Criteria(value = criteria)

def _create_owner(owner):
    return test_case_metadata_pb.Contact(email = owner)

create = struct(
    suite = _create_suite,
    suite_list = _create_suite_list,
    suite_set = _create_suite_set,
    suite_set_list = _create_suite_set_list,
)
