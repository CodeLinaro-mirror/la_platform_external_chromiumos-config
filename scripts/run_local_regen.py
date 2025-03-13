#!/usr/bin/env python3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Regenerate all project configs locally and generate a diff for them."""

import argparse
import functools
import glob
import multiprocessing
import multiprocessing.pool
import os
import pathlib
import subprocess
import sys
import tempfile

from common import utilities


# resolve relative directories
this_dir = pathlib.Path(os.path.dirname(os.path.abspath(__file__)))
path_projects = this_dir / "../../project"


def run_config(config, logname=None):
    """Run a single config job, return diff of current and new output.

    Args:
        config: (program, project) to configure
        logname: Filename to redirect stderr to from config
            default is to suppress the output
    """

    # open logfile as /dev/null by default so we don't have to check for it
    logfile = open("/dev/null", "w")
    if logname:
        logfile = open(logname, "a")

    def run_diff(cmd, current, output):
        """Execute cmd and diff the current and output files"""
        stdout = ""
        try:
            stdout = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
                text=True,
                shell=True,
            ).stdout
        finally:
            logfile.write(stdout)

        # otherwise run diff
        return utilities.jqdiff(
            current if current.exists() else None,
            output if output.exists() else None,
        )

    #### start of function body
    program, project = config

    logfile.write("== {}/{} ==================\n".format(program, project))

    # path to project repo and config bundle
    path_repo = (path_projects / program / project).resolve()
    path_config = (path_repo / "generated/config.jsonproto").resolve()

    # create temporary directory for output
    diff = ""
    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)

        cmd = "cd {}; {} --no-proto --output-dir {} {}".format(
            path_repo.resolve(),
            (path_repo / "config/bin/gen_config").resolve(),
            scratch,
            path_repo / "config.star",
        )

        path_config_new = scratch / "generated/config.jsonproto"

        logfile.write("repo path:  {}\n".format(path_repo))
        logfile.write("old config: {}\n".format(path_config))
        logfile.write("new config: {}\n".format(path_config_new))
        logfile.write("running:    {}\n".format(cmd))
        logfile.write("\n")

        diff = run_diff(cmd, path_config, path_config_new)
        logfile.write("\n\n")
        logfile.close()

    return ("{}-{}".format(program, project), diff)


def run_configs(args, configs):
    """Regenerate configuration for each project in configs.

    Generate an über diff showing the changes that the current ToT
    configuration code would generate vs what's currently committed.

    Write the result to the output file specified on the command line.

    Args:
        args: command line arguments from argparse
        configs: list of BackfillConfig instances to execute

    Returns:
        nothing
    """

    # create a logfile if requested
    kwargs = {}
    if args.logfile:
        # open and close the logfile to truncate it so backfills can append
        # We can't pickle the file object and send it as an argument with
        # multiprocessing, so this is a workaround for that limitation
        with open(args.logfile, "w"):
            kwargs["logname"] = args.logfile

    nproc = 32
    diffs = {}
    nconfig = len(configs)
    with multiprocessing.Pool(processes=nproc) as pool:
        results = pool.imap_unordered(
            functools.partial(run_config, **kwargs), configs, chunksize=1
        )
        for ii, result in enumerate(results, 1):
            sys.stderr.write(
                utilities.clear_line(
                    "[{}/{}] Processing configs".format(ii, nconfig)
                )
            )

            if result:
                key, diff = result
                diffs[key] = diff

        sys.stderr.write(utilities.clear_line("[✔] Processing configs"))

    # generate final über diff showing all the changes
    with open(args.diff, "w") as ofile:
        for name, result in sorted(diffs.items()):
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
        "--diff",
        type=str,
        required=True,
        help="target file for diff on config.jsonproto payload",
    )

    parser.add_argument(
        "-l",
        "--logfile",
        type=str,
        help="target file to log output from regens",
    )
    args = parser.parse_args()

    # glob out all the config.stars in the project directory
    strpath = str(path_projects)
    config_stars = [
        os.path.relpath(fname, strpath)
        for fname in glob.glob(strpath + "/*/*/config.star")
    ]

    # break program/project out of path
    configs = [
        tuple(
            config_star.split("/")[0:2],
        )
        for config_star in config_stars
    ]
    run_configs(args, sorted(configs))


if __name__ == "__main__":
    main()
