# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import itertools
import multiprocessing
import subprocess
import sys
import time


# escape sequence to clear the current line and return to column 0
CLEAR_LINE = "\033[2K\r"


def clear_line(value):
    """Return value with line clearing prefix added to it."""
    return CLEAR_LINE + value


class Spinner:
    """Simple class to print a message and update a little spinning icon."""

    def __init__(self, message):
        self.message = message
        self.spin = itertools.cycle("◐◓◑◒")

    def tick(self):
        sys.stderr.write(
            CLEAR_LINE + "[%c] %s" % (next(self.spin), self.message)
        )

    def done(self, success=True):
        if success:
            sys.stderr.write(CLEAR_LINE + "[✔] %s\n" % self.message)
        else:
            sys.stderr.write(CLEAR_LINE + "[✘] %s\n" % self.message)


def call_and_spin(message, stdin, *cmd):
    """Execute a command and print a nice status while we wait.

    Args:
        message (str): message to print while we wait (along with spinner)
        stdin (bytes): array of bytes to send as the stdin (or None)
        cmd   ([str]): command and any options and arguments

    Returns:
        tuple of (data, status) containing process stdout and status
    """

    with multiprocessing.pool.ThreadPool(processes=1) as pool:
        result = pool.apply_async(
            subprocess.run,
            (cmd,),
            {
                "input": stdin,
                "capture_output": True,
                "text": True,
            },
        )

        spinner = Spinner(message)
        spinner.tick()

        while not result.ready():
            spinner.tick()
            time.sleep(0.05)

        process = result.get()
        spinner.done(process.returncode == 0)

        return process.stdout, process.returncode


def jqdiff(filea, fileb):
    """Diff two json files using jq with ordered keys.

    Args:
        filea (str): first file to compare
        fileb (str): second file to compare

    Returns:
        Diff between jq output with -S (sorted keys) enabled
    """

    # Enable recursive sort on arrays
    filt = """
def safeget(f):
  if type == "object" then
     f
  else
     .
  end;

walk(
  if type == "array" then
    sort_by(safeget(.hwidLabel), safeget(.id), .)
  else
    .
  end
)
"""

    # if inputs aren't declared, use a file that will (almost surely) never
    # exist and pass -N to diff so it treats it as an empty file and gives a
    # full diff
    input0 = "<(jq -S '{}' {})".format(filt, filea) if filea else "/dev/__empty"
    input1 = "<(jq -S '{}' {})".format(filt, fileb) if fileb else "/dev/__empty"

    process = subprocess.run(
        "diff -uN {} {}".format(input0, input1),
        check=False,  # diff returns non-zero error status if there's a diff
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return process.stdout
