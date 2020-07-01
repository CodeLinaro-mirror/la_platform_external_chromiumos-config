# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# For details on the depot tools provided presubmit API see:
# http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts

import sys

sys.path.insert(1, 'presubmit')
import presubmits

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

    err_msg = ("gen_config produced a diff for {}, please amend your changes "
               "and try again.")

    # Followed by fake program and project config.
    for config_file in ["./test/program/fake/config.star",
                        "./test/project/fake/fake/config.star"]:
      results.extend(presubmits.CheckGenConfig(
          input_api, output_api,
          config_file=config_file,
          gen_config_cmd="./bin/gen_config",
          failure_message=err_msg.format(config_file)))

    # The generate.sh in this repo can create files. Make sure repo is clean.
    results.extend(presubmits.CheckUntracked(input_api, output_api))

    return results


def CommonChecks(input_api, output_api):
    results = []
    results.extend(CheckGenerated(input_api, output_api))
    for script in ['./check_examples.sh', './run_py_unittests.sh',
                   './run_go_unittests.sh', './check_starlark.sh']:
      results.extend(presubmits.CheckScript(input_api, output_api, script))
    return results


def CheckChangeOnUpload(input_api, output_api):
    return CommonChecks(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    return CommonChecks(input_api, output_api)
