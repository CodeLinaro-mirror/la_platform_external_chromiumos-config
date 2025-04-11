#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Regenerate all program and project configs and create commits.

Example usage:
./gen_all_configs.py -r src/program -b testbranch -j 8 -m "Regen configs."
"""

import argparse
import collections
import functools
import multiprocessing
import os
import subprocess
from typing import List
import warnings


# The root of the Chromiumos checkout.
SRC_ROOT = os.path.realpath(os.path.join(__file__, "../../../../.."))

# Describes a repo. Name is like 'chromeos/program/testprogram', path is like
# 'src/program/testprogram'.
RepoInfo = collections.namedtuple("RepoInfo", ["name", "path"])


class ConfigGenerationError(Exception):
    """Exception raised for errors during config generation."""


def get_repos(regexes: List[str]) -> List[RepoInfo]:
    """Returns a list of RepoInfo for repos matching regexes.

    Args:
        regexes: A list of regexes, in format expected by `repo forall`.
    """
    cmd = "repo forall -r {} -c 'echo $REPO_PROJECT,$REPO_PATH'".format(
        " ".join(regexes)
    )
    repo_process = subprocess.run(
        cmd, shell=True, check=True, capture_output=True
    )

    repo_infos: List[RepoInfo] = []
    for line in repo_process.stdout.decode().strip().split():
        name, path = line.split(",")
        repo_infos.append(RepoInfo(name, path))

    if not repo_infos:
        raise ValueError("No repos matched regexes {}".format(regexes))

    return repo_infos


def regen_configs(path: str, branch: str, message: str):
    """Generates all configs found under path and makes a commit if necessary.

    Args:
        path: A path, relative to the Chromiumos checkout, e.g.
            'src/program/testprogram'.
        branch: See add_argument help string.
        message: See add_argument help string.
    """
    print("Generating configs for {}...".format(path))
    fullpath = os.path.join(SRC_ROOT, path)

    # Change to the project directory, which will be necessary for `git commit`
    # anyway.
    os.chdir(fullpath)
    subprocess.run(
        ["repo", "start", branch, "."], check=True, capture_output=True
    )

    config_paths = []
    for dirpath, _, filenames in os.walk(".", followlinks=False):
        if "config.star" in filenames:
            config_paths.append(os.path.join(dirpath, "config.star"))

    if not config_paths:
        warnings.warn("No config.star files found in {}".format(path))

    for config in config_paths:
        try:
            subprocess.run(["./config/bin/gen_config", config], check=True)
        except subprocess.CalledProcessError as ex:
            raise ConfigGenerationError(
                "Failed to generate config for {}".format(path)
            ) from ex

    # Check if any files were changed.
    status_process = subprocess.run(
        ["git", "status", "--porcelain"], check=True, capture_output=True
    )
    if status_process.stdout:
        print("Committing config changes in {}.".format(path))
        subprocess.run(
            ["git", "commit", "-a", "-m", message],
            check=True,
            capture_output=True,
        )
    else:
        print("No config changes in {}".format(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-r",
        "--regex",
        nargs="*",
        default=["src/program", "src/project"],
        help=(
            "Generate configs on projects matching regex. Defaults to"
            "['src/program', 'src/project']. Format is as expected by `repo "
            "forall`"
        ),
    )
    parser.add_argument(
        "-b",
        "--branch",
        required=True,
        help=(
            "Name of the branch to commit config changes to. Does not need to"
            " already exist. Passed to `repo start`."
        ),
    )
    parser.add_argument(
        "-m",
        "--message",
        required=True,
        help="Commit message for each of the config changes.",
    )
    parser.add_argument(
        "--no-sync",
        action="store_true",
        help="Skip syncing before generating configs.",
    )
    parser.add_argument(
        "-j",
        "--jobs",
        default=1,
        type=int,
        help="Number of commands to execute simultaneously",
    )

    args = parser.parse_args()

    repo_infos = get_repos(args.regex)
    repo_names, repo_paths = zip(*repo_infos)

    # repo doesn't like when sync is run concurrently, so run in the main
    # thread.
    if not args.no_sync:
        print("Syncing repos: {}".format(", ".join(repo_names)))
        subprocess.run(
            ["repo", "sync", "-j", str(args.jobs), *repo_names],
            check=True,
            capture_output=True,
        )

    pool = multiprocessing.Pool(args.jobs)

    # map doesn't accept lambdas, so use functools.partial.
    pool.map(
        functools.partial(
            regen_configs,
            branch=args.branch,
            message=args.message,
        ),
        repo_paths,
    )

    print(
        "Upload changes with 'repo upload --br={} --ht={}'".format(
            args.branch, args.branch
        )
    )


if __name__ == "__main__":
    main()
