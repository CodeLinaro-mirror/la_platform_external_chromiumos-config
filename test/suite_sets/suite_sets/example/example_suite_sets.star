# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This is an example of a SuiteSet definition."""

load("//create.star", "create")

def _example_suite_set():
    return create.suite_set(
        # Globally unique identifier across all SuiteSets and Suites.
        suite_set_id = "example_suite_set",
        # Email contacts of owners that gate changes to the SuiteSet and
        # should be notified regarding any SuiteSet issues (e.g. flakiness,
        # runtime).
        owners = [
            "dbeckett@google.com",
            "bbrotherton@google.com",
        ],
        # The Buganizer component to issue bugs against regarding the
        # SuiteSet.
        bug_component = "b:1234567",
        # A short summary capturing the quality guarantee validated by the
        # SuiteSet (e.g. “Validates a device passes Engineering Verification
        # Testing and is ready to continue to Design Verification Testing”).
        criteria = "Validates fail/pass tests with pass/fail.",
        # A list SuiteSet Id's contained within the SuiteSet.
        suite_sets = [],
        # A list Suite Id's contained within the SuiteSet.
        suites = [
            "example_pass",
            "example_fail",
        ],
    )

def _all_suite_sets():
    return [
        _example_suite_set(),
    ]

example_suite_sets = struct(
    all_suite_sets = _all_suite_sets,
)
