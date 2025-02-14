# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# For details on the depot tools provided presubmit API see:
# http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts

"""Hook to run unit tests on upload."""

import sys


sys.path.insert(1, "presubmit")
# pylint: disable=wrong-import-position
import presubmits


# pylint: enable=wrong-import-position


USE_PYTHON3 = True


def CheckGenerated(input_api, output_api):
    """Checks all scripts that produce generated output.

    Checks that all of the scripts that produce generated output in this
    repository have been ran and that the generated output is up to date.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []

    # Starting with generate.sh.
    results.extend(presubmits.CheckGenerated(input_api, output_api))

    # The generate.sh in this repo can create files. Make sure repo is clean.
    results.extend(presubmits.CheckUntracked(input_api, output_api))

    return results


def CommonChecks(input_api, output_api):
    """Code to check the generated code and .star files."""
    file_filter = lambda x: x.LocalPath() == "infra/config/recipes.cfg"
    results = input_api.canned_checks.CheckJsonParses(
        input_api, output_api, file_filter=file_filter
    )
    results.extend(CheckGenerated(input_api, output_api))
    for script in [
        "./run_py_unittests.sh",
        "./run_go_unittests.sh",
        "presubmit/check_dut_attributes.py",
    ]:
        results.extend(presubmits.CheckScript(input_api, output_api, script))
    return results


def CheckChangeOnUpload(input_api, output_api):
    """Upload hook.

    Normally disabled on ChromeOS, but used in config to validate the generated code.

    """
    return CommonChecks(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    """Commit hook."""
    return CommonChecks(input_api, output_api)
