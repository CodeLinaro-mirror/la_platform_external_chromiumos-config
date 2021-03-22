#!/usr/bin/env python3
# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Run an equivalent to the backfill pipeline locally and generate diffs.

Parse the actual current builder configurations from BuildBucket and run
the join_config_payloads.py script locally.  Generate a diff that shows any
changes using the tip-of-tree code vs what's running in production.
"""

import argparse
import collections
import functools
import itertools
import json
import logging
import multiprocessing
import multiprocessing.pool
import os
import pathlib
import subprocess
import sys
import tempfile
import time

# resolve relative directories
this_dir = pathlib.Path(os.path.dirname(os.path.abspath(__file__)))
hwid_path = (this_dir / "../../platform/chromeos-hwid/v3").resolve()
join_script = (this_dir / "../payload_utils/join_config_payloads.py").resolve()
merge_script = (this_dir / "../payload_utils/aggregate_messages.py").resolve()
public_path = (this_dir / "../../overlays").resolve()
private_path = (this_dir / "../../private-overlays").resolve()
project_path = (this_dir / "../../project").resolve()

# escape sequence to clear the current line and return to column 0
CLEAR_LINE = "\033[2K\r"

# record to store backfiller configuration in
BackfillConfig = collections.namedtuple('BackfillConfig', [
    'program',
    'project',
    'hwid_key',
    'public_model',
    'private_repo',
    'private_model',
])


class Spinner(object):
  """Simple class to print a message and update a little spinning icon."""

  def __init__(self, message):
    self.message = message
    self.spin = itertools.cycle("◐◓◑◒")

  def tick(self):
    sys.stderr.write(CLEAR_LINE + "[%c] %s" % (next(self.spin), self.message))

  def done(self, success=True):
    if success:
      sys.stderr.write(CLEAR_LINE + "[✔] %s\n" % self.message)
    else:
      sys.stderr.write(CLEAR_LINE + "[✘] %s\n" % message)


def call_and_spin(message, stdin, *cmd):
  """Execute a command and print a nice status while we wait.

    Args:
      message (str): message to print while we wait (along with spinner)
      stdin (bytes): array of bytes to send as the stdin (or None)
      cmd   ([str]): command and any options and arguments

    Return:
      tuple of (data, status) containing process stdout and status
  """

  with multiprocessing.pool.ThreadPool(processes=1) as pool:
    result = pool.apply_async(subprocess.run, (cmd,), {
        'input': stdin,
        'capture_output': True,
        'text': True,
    })

    spinner = Spinner(message)
    spinner.tick()

    while not result.ready():
      spinner.tick()
      time.sleep(0.05)

    process = result.get()
    spinner.done(process.returncode == 0)

    return process.stdout, process.returncode


def parse_build_property(build, name):
  """Parse out a property value from a build and return its value.

  Properties are always JSON values, so we decode them and return the
  resulting object

  Args:
    build (dict): json object containing BuildBucket properties
    name (str): name of the property to look up

  Return:
    decoded property value or None if not found
  """

  properties = build["config"]["recipe"]["propertiesJ"]
  for prop in properties:
    if prop.startswith(name):
      return json.loads(prop[len(name) + 1:])
  return None


def jqdiff(filea, fileb, filt="."):
  """Diff two json files using jq to get a semantic diff.

  Args:
    filea (str): first file to compare
    fileb (str): second file to compare
    filt (str): if supplied, jq filter to apply to inputs before comparing
      The filter is quoted with '' for the user so take care when specifying.

  Return:
    diff between inputs
  """

  process = subprocess.run(
      "diff -u <(jq -S '{}' {}) <(jq -S '{}' {})".format(
          filt,
          filea,
          filt,
          fileb,
      ),
      shell=True,
      text=True,
      capture_output=True,
  )
  return process.stdout


def run_backfill(config, logname=None, run_imported=True, run_joined=True):
  """Run a single backfill job, return diff of current and new output.

  Args:
    config: BackfillConfig instance for the backfill operation.
    logname: Filename to redirect stderr to from backfill
      default is to suppress the output
    run_imported: If True, generate a diff for the imported payload
    run_joined: If True, generate a diff for the joined payload
  """

  def run_diff(cmd, current, output):
    """Execute cmd and diff the current and output files"""
    logfile.write("running: {}\n".format(" ".join(map(str, cmd))))

    subprocess.run(cmd, stderr=logfile, check=True)

    # if one or the other file doesn't exist, return the other as a diff
    if current.exists() != output.exists():
      if current.exists():
        return open(current).read()
      return open(output).read()

    # otherwise run diff
    return jqdiff(current, output)

  #### start of function body

  # path to project repo and config bundle
  path_repo = project_path / config.program / config.project
  path_config = path_repo / "generated/config.jsonproto"

  logfile = subprocess.DEVNULL
  if logname:
    logfile = open(logname, "a")

  # reef is currently broken because it _needs_ a real portage environment
  # to pull in common code.
  # TODO(https://crbug.com/1144956): fix when reef is corrected
  if config.program == "reef":
    return None

  cmd = [join_script, "--l", "DEBUG"]
  cmd.extend(["--program-name", config.program])
  cmd.extend(["--project-name", config.project])

  if path_config.exists():
    cmd.extend(["--config-bundle", path_config])

  if config.hwid_key:
    cmd.extend(["--hwid", hwid_path / config.hwid_key])

  if config.public_model:
    cmd.extend(["--public-model", public_path / config.public_model])

  if config.private_model:
    overlay = config.private_repo.split('/')[-1]
    cmd.extend(
        ["--private-model", private_path / overlay / config.private_model])

  # create temporary directory for output
  diff_imported = ""
  diff_joined = ""
  with tempfile.TemporaryDirectory() as scratch:
    scratch = pathlib.Path(scratch)

    # generate diff of imported payloads
    path_imported_old = path_repo / "generated/imported.jsonproto"
    path_imported_new = scratch / "imported.jsonproto"

    if run_imported:
      diff_imported = run_diff(
          cmd + ["--import-only", "--output", path_imported_new],
          path_imported_old,
          path_imported_new,
      )

    # generate diff of joined payloads
    if run_joined and path_config.exists():
      path_joined_old = path_repo / "generated/joined.jsonproto"
      path_joined_new = scratch / "joined.jsonproto"

      diff_joined = run_diff(cmd + ["--output", path_joined_new],
                             path_joined_old, path_joined_new)

  return ("{}-{}".format(config.program,
                         config.project), diff_imported, diff_joined)


def run_backfills(args, configs):
  """Run backfill pipeline for each builder in configs.

  Generate an über diff showing the changes that the current ToT
  join_config_payloads code would generate vs what's currently committed.

  Write the result to the output file specified on the command line.

  Args:
    args: command line arguments from argparse
    configs: list of BackfillConfig instances to execute

  Return:
    nothing
  """

  # create a logfile if requested
  kwargs = {}
  kwargs["run_joined"] = args.joined_diff is not None
  if args.logfile:
    # open and close the logfile to truncate it so backfills can append
    # We can't pickle the file object and send it as an argument with
    # multiprocessing, so this is a workaround for that limitation
    with open(args.logfile, "w"):
      kwargs["logname"] = args.logfile

  nproc = 32
  nconfig = len(configs)
  imported_diffs = {}
  joined_diffs = {}
  with multiprocessing.Pool(processes=nproc) as pool:
    results = pool.imap_unordered(
        functools.partial(run_backfill, **kwargs), configs, chunksize=1)
    for ii, result in enumerate(results, 1):
      sys.stderr.write(
          CLEAR_LINE + "[{}/{}] Processing backfills".format(ii, nconfig),)

      if result:
        key, imported, joined = result
        imported_diffs[key] = imported
        joined_diffs[key] = joined

    sys.stderr.write(CLEAR_LINE + "[✔] Processing backfills")

  # generate final über diff showing all the changes
  with open(args.imported_diff, "w") as ofile:
    for name, result in sorted(imported_diffs.items()):
      ofile.write("## ---------------------\n")
      ofile.write("## diff for {}\n".format(name))
      ofile.write("\n")
      ofile.write(result + "\n")

  if args.joined_diff:
    with open(args.joined_diff, "w") as ofile:
      for name, result in sorted(joined_diffs.items()):
        ofile.write("## ---------------------\n")
        ofile.write("## diff for {}\n".format(name))
        ofile.write("\n")
        ofile.write(result + "\n")


def main():
  parser = argparse.ArgumentParser(
      description=__doc__,
      formatter_class=argparse.RawTextHelpFormatter,
  )

  parser.add_argument(
      "--imported-diff",
      type=str,
      required=True,
      help="target file for diff on imported.jsonproto payload",
  )

  parser.add_argument(
      "--joined-diff",
      type=str,
      help="target file for diff on joined.jsonproto payload",
  )

  parser.add_argument(
      "-l",
      "--logfile",
      type=str,
      help="target file to log output from backfills",
  )
  args = parser.parse_args()

  # query BuildBucket for current builder configurations in the infra bucket
  data, status = call_and_spin(
      "Listing backfill builders",
      json.dumps({
          "project": "chromeos",
          "bucket": "infra",
          "pageSize": 1000,
      }),
      "prpc",
      "call",
      "cr-buildbucket.appspot.com",
      "buildbucket.v2.Builders.ListBuilders",
  )

  if status != 0:
    print(
        "Error executing prpc call to list builders.  Try 'prpc login' first.",
        file=sys.stderr,
    )
    sys.exit(status)

  # filter out just the backfill builders and sort them by name
  builders = json.loads(data)["builders"]
  builders = [
      bb for bb in builders if bb["id"]["builder"].startswith("backfill")
  ]

  # construct backfill config from the configured builder properties
  configs = []
  for builder in builders:
    public_yaml = parse_build_property(builder, "public_yaml") or {}
    private_yaml = parse_build_property(builder, "private_yaml") or {}

    config = BackfillConfig(
        program=parse_build_property(builder, "program_name"),
        project=parse_build_property(builder, "project_name"),
        hwid_key=parse_build_property(builder, "hwid_key"),
        public_model=public_yaml.get("path"),
        private_repo=private_yaml.get("repo"),
        private_model=private_yaml.get("path"),
    )

    path_repo = project_path / config.program / config.project
    if not path_repo.exists():
      logging.warning("{}/{} does not exist locally, skipping".format(
          config.program, config.project))
      continue

    configs.append(config)

  run_backfills(args, configs)


if __name__ == "__main__":
  main()
