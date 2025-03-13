#!/usr/bin/env python3
# Copyright 2021 The ChromiumOS Authors
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
import json
import logging
import multiprocessing
import multiprocessing.pool
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

from common import utilities


# resolve relative directories
this_dir = pathlib.Path(os.path.dirname(os.path.abspath(__file__)))
hwid_path = (this_dir / "../../platform/chromeos-hwid/v3").resolve()
join_script = (this_dir / "../payload_utils/join_config_payloads.py").resolve()
merge_script = (this_dir / "../payload_utils/aggregate_messages.py").resolve()
public_path = (this_dir / "../../overlays").resolve()
private_path = (this_dir / "../../private-overlays").resolve()
project_path = (this_dir / "../../project").resolve()

# record to store backfiller configuration in
BackfillConfig = collections.namedtuple(
    "BackfillConfig",
    [
        "program",
        "project",
        "hwid_key",
        "public_model",
        "private_repo",
        "private_model",
    ],
)


def parse_build_property(build, name):
    """Parse out a property value from a build and return its value.

    Properties are always JSON values, so we decode them and return the
    resulting object

    Args:
        build (dict): json object containing BuildBucket properties
        name (str): name of the property to look up

    Returns:
        decoded property value or None if not found
    """
    return json.loads(build["config"]["properties"]).get(name)


def run_backfill(
    config, args, logname=None, run_imported=True, run_joined=True
):
    """Run a single backfill job, return diff of current and new output.

    Args:
        config: BackfillConfig instance for the backfill operation.
        args: Commandline arguments
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
        return utilities.jqdiff(current, output)

    #### start of function body

    # path to project repo and config bundle
    path_repo = project_path / config.program / config.project
    path_config = path_repo / "generated/config.jsonproto"

    logfile = subprocess.DEVNULL
    if logname:
        logfile = open(logname, "a")

    # reef/fizz are currently broken because it _needs_ a real portage
    # environment to pull in common code.
    # TODO(https://crbug.com/1144956): fix when reef is corrected
    if config.program in ["reef", "fizz"]:
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
        overlay = config.private_repo.split("/")[-1]
        cmd.extend(
            ["--private-model", private_path / overlay / config.private_model]
        )

    # create output directory if it doesn't exist
    if args.save_imported_payloads:
        os.makedirs(
            os.path.join(args.save_imported_payloads, config.project),
            exist_ok=True,
        )

    if args.save_joined_payloads:
        os.makedirs(
            os.path.join(args.save_joined_payloads, config.project),
            exist_ok=True,
        )

    # create temporary directory for output
    diff_imported = ""
    diff_joined = ""
    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)

        old_imported_prefix = path_repo / "generated"
        if args.diff_imported_against:
            old_imported_prefix = pathlib.Path(
                os.path.join(
                    args.diff_imported_against,
                    config.project,
                )
            )

        # generate diff of imported payloads
        path_imported_old = old_imported_prefix / "imported.jsonproto"
        path_imported_new = scratch / "imported.jsonproto"

        if run_imported:
            diff_imported = run_diff(
                cmd + ["--import-only", "--output", path_imported_new],
                path_imported_old,
                path_imported_new,
            )

            if args.save_imported_payloads:
                shutil.copyfile(
                    path_imported_new,
                    os.path.join(
                        args.save_imported_payloads,
                        config.project,
                        "imported.jsonproto",
                    ),
                )

        old_joined_prefix = path_repo / "generated"
        if args.diff_joined_against:
            old_joined_prefix = pathlib.Path(
                os.path.join(
                    args.diff_joined_against,
                    config.project,
                )
            )

        # generate diff of joined payloads
        if run_joined and path_config.exists():
            path_joined_old = old_joined_prefix / "joined.jsonproto"
            path_joined_new = scratch / "joined.jsonproto"

            diff_joined = run_diff(
                cmd + ["--output", path_joined_new],
                path_joined_old,
                path_joined_new,
            )

            if args.save_joined_payloads:
                shutil.copyfile(
                    path_joined_new,
                    os.path.join(
                        args.save_joined_payloads,
                        config.project,
                        "joined.jsonproto",
                    ),
                )

    return (
        "{}-{}".format(config.program, config.project),
        diff_imported,
        diff_joined,
    )


def run_backfills(args, configs):
    """Run backfill pipeline for each builder in configs.

    Generate an über diff showing the changes that the current ToT
    join_config_payloads code would generate vs what's currently committed.

    Write the result to the output file specified on the command line.

    Args:
        args: command line arguments from argparse
        configs: list of BackfillConfig instances to execute

    Returns:
        nothing
    """

    # create a logfile if requested
    kwargs = {}
    kwargs["run_joined"] = args.joined_diff is not None
    kwargs["args"] = args
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
            functools.partial(run_backfill, **kwargs), configs, chunksize=1
        )
        for ii, result in enumerate(results, 1):
            sys.stderr.write(
                utilities.clear_line(
                    "[{}/{}] Processing backfills".format(ii, nconfig)
                )
            )

            if result:
                key, imported, joined = result
                imported_diffs[key] = imported
                joined_diffs[key] = joined

        sys.stderr.write(utilities.clear_line("Processing backfills"))

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
        "--save-imported-payloads",
        type=str,
        help="target directory to save individual imported.jsonproto payloads",
    )

    parser.add_argument(
        "--diff-imported-against",
        type=str,
        help="source directory of individual imported.jsonproto payloads",
    )

    parser.add_argument(
        "--joined-diff",
        type=str,
        help="target file for diff on joined.jsonproto payload",
    )

    parser.add_argument(
        "--save-joined-payloads",
        type=str,
        help="target directory to save individual joined.jsonproto payloads",
    )

    parser.add_argument(
        "--diff-joined-against",
        type=str,
        help="source directory of individual joined.jsonproto payloads",
    )

    parser.add_argument(
        "-l",
        "--logfile",
        type=str,
        help="target file to log output from backfills",
    )
    args = parser.parse_args()

    # query BuildBucket for current builder configurations in the infra bucket
    data, status = utilities.call_and_spin(
        "Listing backfill builder",
        json.dumps(
            {
                "id": {
                    "project": "chromeos",
                    "bucket": "infra",
                    "builder": "backfiller",
                }
            }
        ),
        "prpc",
        "call",
        "cr-buildbucket.appspot.com",
        "buildbucket.v2.Builders.GetBuilder",
    )

    if status != 0:
        print(
            "Error executing prpc call to list builders.  Try: prpc login",
            file=sys.stderr,
        )
        sys.exit(status)

    builder = json.loads(data)

    # construct backfill config from the configured builder properties
    configs = []
    for builder_config in parse_build_property(builder, "configs"):
        config = BackfillConfig(
            program=builder_config["program_name"],
            project=builder_config["project_name"],
            hwid_key=builder_config.get("hwid_key"),
            public_model=builder_config.get("public_yaml_path"),
            private_repo=builder_config.get("private_yaml", {}).get("repo"),
            private_model=builder_config.get("private_yaml", {}).get("path"),
        )

        path_repo = project_path / config.program / config.project
        if not path_repo.exists():
            logging.warning(
                "{}/{} does not exist locally, skipping".format(
                    config.program, config.project
                )
            )
            continue

        configs.append(config)

    run_backfills(args, configs)


if __name__ == "__main__":
    main()
