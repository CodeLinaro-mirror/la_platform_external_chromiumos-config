# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# For details on the depot tools provided presubmit API see:
# http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts


def CheckGenerated(input_api, output_api):
    """Runs a generate.sh script as a presubmit check.

  Runs a generate.sh script as a presubmit check checking for successful
  exit and no diff generated. Thus it expects a generate.sh to exist in
  the root of the repo.

  Args:
    input_api: InputApi, provides information about the change.
    output_api: OutputApi, provides the mechanism for returning a response.

  Returns:
    list of PresubmitError, or empty list if no errors.
  """
    results = []

    if input_api.subprocess.call(
        "./generate.sh",
        shell=True,
        stdout=input_api.subprocess.PIPE,
        stderr=input_api.subprocess.PIPE,
    ):
        msg = "Error: generate.sh failed. Please fix and try again."
        results.append(output_api.PresubmitError(msg))
    elif input_api.subprocess.call(
        "git diff --exit-code",
        shell=True,
        stdout=input_api.subprocess.PIPE,
        stderr=input_api.subprocess.PIPE,
    ):
        msg = (
            "Error: Running generate.sh produced a diff. Please "
            "run the script, amend your changes, and try again."
        )
        results.append(output_api.PresubmitError(msg))

    return results


def CheckExamples(input_api, output_api):
    results = []
    ret = input_api.subprocess.call(
        ["./check_examples.sh"],
        stdout=input_api.subprocess.PIPE,
        stderr=input_api.subprocess.PIPE,
    )
    if ret:
        results.append(
            output_api.PresubmitError(
                "go test failed. Please run check_examples.sh for details."
            )
        )
    return results


def CheckChangeOnUpload(input_api, output_api):
    results = []
    results.extend(CheckGenerated(input_api, output_api))
    results.extend(CheckExamples(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    results = []
    results.extend(CheckGenerated(input_api, output_api))
    results.extend(CheckExamples(input_api, output_api))
    return results

