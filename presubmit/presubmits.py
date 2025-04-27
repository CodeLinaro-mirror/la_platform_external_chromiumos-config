# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Collection of helper functions that can be used to compose presubmit
# checks. For cross repo usage import and compose into presubmit hooks
# as follows:
#
#   import sys
#   sys.path.insert(1, 'config/presubmit')
#
#   import presubmits
#
#   def CheckChangeOnUpload(input_api, output_api):
#     results = []
#     results.extend(presubmits.CheckGenerated(input_api, output_api))
#     # ... other checks
#     return results
#
# Note that this expects a config symlink to exist that points at this repo.
#
# For more details on the depot tools provided presubmit API see:
# http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts


def CheckScript(input_api, output_api, script, msg=None):
    """Invokes a script with the result per unix error codes.

    Invokes a shell script with the result following the unix error
    code result of the script.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.
        script: str, script to invoke.
        msg: str, message to use when failure.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []
    if input_api.subprocess.call(script, shell=True):
        if not msg:
            msg = "Error: {} failed. Please fix and try again.".format(script)
        results.append(output_api.PresubmitError(msg))
    return results


def CheckChecker(
    input_api,
    output_api,
    checker_cmd="./config/payload_utils/checker.py",
    program="./program/generated/config.jsonproto",
    project="./generated/config.jsonproto",
    factory_dir="./factory",
):
    """Runs the checker.py script as a presubmit check.

    Runs the checker script as a presubmit check checking for successful
    exit.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.
        program: str, path to the program config json proto.
        project: str, path to the project config json proto.
        factory_dir: str, path to the project factory config dir.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []

    cmd = [checker_cmd]
    cmd.extend(["--program", program])
    cmd.extend(["--project", project])
    cmd.extend(["--factory_dir", factory_dir])
    if input_api.subprocess.call(cmd):
        msg = (
            "Error: config checker checker.py failed. Please fix and try again."
        )
        results.append(output_api.PresubmitError(msg))

    return results


def CheckGenerated(input_api, output_api, cmd="./generate.sh"):
    """Runs a script as a presubmit check.

    Runs a script as a presubmit check checking for successful exit and no
    diff generated.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.
        cmd: String, command to run as the "generate" script.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []

    if input_api.subprocess.call(cmd, shell=True):
        msg = "Error: {} failed. Please fix and try again.".format(cmd)
        results.append(output_api.PresubmitError(msg))
    elif input_api.subprocess.call(
        "git diff --exit-code",
        shell=True,
        stdout=input_api.subprocess.PIPE,
        stderr=input_api.subprocess.PIPE,
    ):
        msg = (
            "Error: Running {} produced a diff. Please run the script, amend "
            "your changes, and try again.".format(cmd)
        )
        results.append(output_api.PresubmitError(msg))

    return results


_DEFAULT_FAILURE_MESSAGE = (
    "Error: Running gen_config produced a diff. Please "
    "resync your chromiumos checkout, run the gen_config "
    "script, amend your changes, and try again. Repos "
    "needing resyncing could include: "
    "chromiumos/config, "
    "chromeos/program/<your program>, "
    "chromeos/project/<your program>/<your project>"
)


def CheckGenConfig(
    input_api,
    output_api,
    config_file="config.star",
    gen_config_cmd="./config/bin/gen_config",
    failure_message=_DEFAULT_FAILURE_MESSAGE,
):
    """Runs a gen_config as a presubmit check.

    Runs the gen_config script as a presubmit check checking for successful
    exit and no diff generated.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.
        config_file: str, file to generate from, defaults to config.star.
        gen_config_cmd: str, location of gen_config script
        failure_message: str, message to use when gen_config produces a diff.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []

    # TODO: get on path for recipes, for now expect to find at
    # config/bin/gen_config
    if input_api.subprocess.call([gen_config_cmd, config_file]):
        msg = "Error: gen_config failed. Please fix and try again."
        results.append(output_api.PresubmitError(msg))
    elif input_api.subprocess.call(["git", "diff", "--exit-code"]):
        results.append(output_api.PresubmitError(failure_message))

    return results


def CheckUntracked(input_api, output_api):
    """Looks for untracked files in the repo and fails if found.

    Args:
        input_api: InputApi, provides information about the change.
        output_api: OutputApi, provides the mechanism for returning a response.

    Returns:
        list of PresubmitError, or empty list if no errors.
    """
    results = []
    cmd = ["git", "ls-files", "--others", "--exclude-standard"]
    out = input_api.subprocess.capture(cmd)
    if out:
        msg = "Found untracked files:\n{}".format(out)
        results.append(output_api.PresubmitPromptWarning(msg))

    return results
