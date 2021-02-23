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
import itertools
import json
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


def run_backfill(config):
  """Run a single backfill job, return diff of current and new output."""

  # reef is currently broken because it _needs_ a real portage environment
  # to pull in common code.
  # TODO(https://crbug.com/1144956): fix when reef is corrected

  if config.program == "reef":
    return None

  cmd = [join_script, "-v"]
  cmd.extend(["--program-name", config.program])
  cmd.extend(["--project-name", config.project])

  if config.hwid_key:
    cmd.extend(["--hwid", hwid_path / config.hwid_key])

  if config.public_model:
    cmd.extend(["--public-model", public_path / config.public_model])

  if config.private_model:
    overlay = config.private_repo.split('/')[-1]
    cmd.extend(
        ["--private-model", private_path / overlay / config.private_model])

  # create temporary directory for output
  with tempfile.TemporaryDirectory() as tmpdir:
    imported = project_path / config.program / config.project / "generated/imported.jsonproto"
    output = pathlib.Path(tmpdir) / "output.jsonproto"
    cmd.extend(["--output", output])

    # execute the backfill
    result = subprocess.run(cmd, stderr=subprocess.DEVNULL)
    if result.returncode != 0:
      print("Error executing backfill for {}-{}".format(config.program,
                                                        config.project))
      return None

    # use jq to generate a nice diff of the output if it exists
    if imported.exists():
      process = subprocess.run(
          "diff -u <(jq -S . {}) <(jq -S . {})".format(imported, output),
          shell=True,
          text=True,
          capture_output=True)

      return ("{}-{}".format(config.program, config.project), process.stdout)
    return None


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

  nproc = 32
  nconfig = len(configs)
  output = {}
  with multiprocessing.Pool(processes=nproc) as pool:
    results = pool.imap_unordered(run_backfill, configs, chunksize=1)
    for ii, result in enumerate(results, 1):
      sys.stderr.write(
          CLEAR_LINE + "[{}/{}] Processing backfills".format(ii, nconfig),)

      if result:
        id, data = result
        output[id] = data

    sys.stderr.write(CLEAR_LINE + "[✔] Processing backfills")

  # generate final über diff showing all the changes
  with open(args.output, "w") as ofile:
    all_empty = True
    for name, result in sorted(output.items()):
      ofile.write("## ---------------------\n")
      ofile.write("## diff for {}\n".format(name))
      ofile.write("\n")
      ofile.write(result + "\n")

      all_empty = all_empty and result.strip() == ""

    if all_empty:
      print("No diffs detected!\n")


def main():
  parser = argparse.ArgumentParser(
      description=__doc__,
      formatter_class=argparse.RawTextHelpFormatter,
  )

  parser.add_argument(
      "-o",
      "--output",
      type=str,
      required=True,
      help="target file for diff information",
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

    configs.append(
        BackfillConfig(
            program=parse_build_property(builder, "program_name"),
            project=parse_build_property(builder, "project_name"),
            hwid_key=parse_build_property(builder, "hwid_key"),
            public_model=public_yaml.get("path"),
            private_repo=private_yaml.get("repo"),
            private_model=private_yaml.get("path"),
        ))

  run_backfills(args, configs)


if __name__ == "__main__":
  main()
