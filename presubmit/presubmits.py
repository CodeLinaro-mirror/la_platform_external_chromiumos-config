# Copyright 2020 The Chromium OS Authors. All rights reserved.
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
      './generate.sh',
      shell=True,
      stdout=input_api.subprocess.PIPE,
      stderr=input_api.subprocess.PIPE):
    msg = 'Error: generate.sh failed. Please fix and try again.'
    results.append(output_api.PresubmitError(msg))
  elif input_api.subprocess.call(
      'git diff --exit-code',
      shell=True,
      stdout=input_api.subprocess.PIPE,
      stderr=input_api.subprocess.PIPE):
    msg = ('Error: Running generate.sh produced a diff. Please '
           'run the script, amend your changes, and try again.')
    results.append(output_api.PresubmitError(msg))

  return results


_DEFAULT_FAILURE_MESSAGE=(
    'Error: Running gen_config produced a diff. Please '
    'resync your chromiumos checkout, run the gen_config '
    'script, amend your changes, and try again. Repos '
    'needing resyncing could include: '
    'chromiumos/config, '
    'chromeos/program/<your program>, '
    'chromeos/project/<your program>/<your project>'
)

def CheckGenConfig(input_api, output_api,
                   config_file='config.star',
                   gen_config_cmd='./config/bin/gen_config',
                   failure_message=_DEFAULT_FAILURE_MESSAGE):
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
    msg = 'Error: gen_config failed. Please fix and try again.'
    results.append(output_api.PresubmitError(msg))
  elif input_api.subprocess.call(['git', 'diff', '--exit-code']):
    results.append(output_api.PresubmitError(failure_message))

  return results
