# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This is an example of a Suite definition."""

load("//create.star", "create")

def _example_suite():
    return create.suite(
        # Globally unique identifier across all SuiteSets and Suites.
        suite_id = "example_suite",
        # Email contacts of owners that gate changes to the Suite and
        # should be notified regarding any Suite issues (e.g. flakiness,
        # runtime).
        owners = [
            "jackgelinas@google.com",
            "dbeckett@google.com",
            "bbrotherton@google.com",
        ],
        # The Buganizer component to issue bugs against regarding the
        # Suite.
        bug_component = "b:1234567",
        # A short summary capturing the quality guarantee validated by the
        # Suite.
        criteria = "Validates validates some things are working",
        # A list test Id's contained within the Suite.
        tests = [
            "tast.example.Pass",
            "tast.example.Fail",
            "tauto.stub_PassServer",
            "tauto.stub_FailServer",
        ],
    )

def _all_suites():
    return [
        _example_suite(),
    ]

example_suites = struct(
    all_suites = _all_suites,
)
