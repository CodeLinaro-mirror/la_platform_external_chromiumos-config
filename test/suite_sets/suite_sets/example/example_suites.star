# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This is an example of a Suite definition."""

load("//create.star", "create")

def _example_pass():
    return create.suite(
        # Globally unique identifier across all SuiteSets and Suites.
        suite_id = "example_pass",
        # Email contacts of owners that gate changes to the Suite and
        # should be notified regarding any Suite issues (e.g. flakiness,
        # runtime).
        owners = [
            "dbeckett@google.com",
            "bbrotherton@google.com",
        ],
        # The Buganizer component to issue bugs against regarding the
        # Suite.
        bug_component = "b:1234567",
        # A short summary capturing the quality guarantee validated by the
        # Suite.
        criteria = "Validates basic pass tests will pass.",
        # A list test Id's contained within the Suite.
        tests = [
            "tast.example.Pass",
            "tauto.stub_PassServer",
        ],
    )

def _example_fail():
    return create.suite(
        # Globally unique identifier across all SuiteSets and Suites.
        suite_id = "example_fail",
        # Email contacts of owners that gate changes to the Suite and
        # should be notified regarding any Suite issues (e.g. flakiness,
        # runtime).
        owners = [
            "dbeckett@google.com",
            "bbrotherton@google.com",
        ],
        # The Buganizer component to issue bugs against regarding the
        # Suite.
        bug_component = "b:1234567",
        # A short summary capturing the quality guarantee validated by the
        # Suite.
        criteria = "Validates fail pass tests will fail.",
        # A list test Id's contained within the Suite.
        tests = [
            "tast.example.Fail",
            "tauto.stub_FailServer",
        ],
    )

def _all_suites():
    return [
        _example_pass(),
        _example_fail(),
    ]

example_suites = struct(
    all_suites = _all_suites,
)
