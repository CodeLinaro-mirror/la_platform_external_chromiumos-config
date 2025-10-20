#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Developer script for generating the Android configurations.

This script is used to test unsubmitted config changes on local Android devices.

Detailed steps conducted by this script is the following:
1) Re-generate config.jsonproto by calling gen_config.sh.
2) Sync with latest Hal_Config.XSD from Android repo.
3) Run cros_to_android.py with all sub-commands.
"""

import argparse
import atexit
import logging
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Optional

from common import logging_utils


THIS_SCRIPT_FILE = Path(__file__).resolve()
THIS_CONFIG_DIR = THIS_SCRIPT_FILE.parent.parent
THIS_SRC_DIR = THIS_CONFIG_DIR.parent


def util_temp_folder_cleanup(to_clean_path: Path) -> None:
    """Utility function for cleaning up a temperaory directory.

    Args:
        to_clean_path: Path to the directory to clean up.
    """
    if to_clean_path.exists():
        shutil.rmtree(to_clean_path)
        logging.debug(
            "Cleanup performed on temp directory at %s", to_clean_path
        )


def util_run_command(command: list[str]) -> None:
    """Runs a command and logs its output based on global log level.

    Args:
        command: List of command line and parameters.

    Raises:
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=True
        )

        if result.stdout:
            logging.debug("Command output (stdout):\n%s", result.stdout.strip())

        logging.debug("Command finished successfully: %s", command[0])

    except subprocess.CalledProcessError as e:
        logging.error("Command failed with exit code %s", e.returncode)
        if e.stderr:
            logging.error("Error output (stderr):\n%s", e.stderr.strip())
        raise


def regenerate_config_jsonproto(program: str, project: str) -> None:
    """Regenerate config.jsonproto.

    Args:
        program: Name of device program or reference design.
        project: Name of device project.

    Raises:
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    gen_config_file = THIS_CONFIG_DIR / "bin/gen_config"
    star_file = THIS_SRC_DIR / "project" / program / project / "config.star"
    util_run_command([gen_config_file, star_file])

    logging.info(
        "Regenerate-ed config.jsonproto of %s/%s"
        " by calling src/config/bin/gen_config.",
        program,
        project,
    )


def sync_halconfig_xsd_with_alrepo(alrepo: Path) -> bool:
    """Sync with latest Hal_Config.XSD from Android repo.

    Args:
        alrepo: Path to the local repo of Android source code.
    """
    cros_xsd_file = THIS_CONFIG_DIR / "payload_utils/test_data/hal_config.xsd"
    if not cros_xsd_file.exists():
        logging.error(
            "Error in accessing copy destination or it does not exist: %s",
            cros_xsd_file,
        )
        return False

    al_xsd_file = alrepo / "device/google/desktop/common/config/hal_config.xsd"
    if not al_xsd_file.exists():
        logging.error("Cannot find the copy source at %s", al_xsd_file)
        return False

    shutil.copy(al_xsd_file, cros_xsd_file)

    logging.info('Sync-ed with latest Hal_Config.XSD from "al_device_repo".')
    return True


def run_cros_to_android_config(program: str, device: str) -> Optional[Path]:
    """Run cros_to_android.py with subcommand generate-hal-xml.

    Args:
        program: Name of device program or reference design.
        device: Name of the Android device project.

    Returns:
        A pathlib.Path to the folder for generated xmls on success,
        otherwise None.

    Raises:
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    cros_to_android_script = (
        THIS_CONFIG_DIR / "payload_utils/cros_to_android.py"
    )
    config_jsonproto = (
        THIS_SRC_DIR
        / "project"
        / program
        / device
        / "generated/config.jsonproto"
    )
    cros_xsd_file = THIS_CONFIG_DIR / "payload_utils/test_data/hal_config.xsd"
    dtd_schema_file = THIS_CONFIG_DIR / "payload_utils/media_profiles.dtd"

    # Create temp folder for storing generated config xmls.
    temp_dir = tempfile.mkdtemp()
    config_output_path = Path(temp_dir)

    # Run cros_to_android.py with subcommand generate-hal-xml.
    hal_config_xml = config_output_path / "hal_config.xml"
    logging.debug("Run generate-hal-xml for %s", device)
    command = [
        cros_to_android_script,
        "generate-hal-xml",
        config_jsonproto,
        "--output-xml",
        hal_config_xml,
        "--xsd-schema",
        cros_xsd_file,
    ]
    try:
        util_run_command(command)
    except subprocess.CalledProcessError:
        logging.error("Failed in calling cros_to_android for generate-hal-xml")
        raise

    # Run cros_to_android.py with subcommand generate-feature-xml.
    features_xml_path = config_output_path / "features"
    features_xml_path.mkdir(exist_ok=True)
    command = [
        cros_to_android_script,
        "generate-feature-xml",
        config_jsonproto,
        "--output-dir",
        features_xml_path,
    ]
    try:
        util_run_command(command)
    except (FileNotFoundError, subprocess.CalledProcessError):
        logging.error(
            "Failed in calling cros_to_android for generate-feature-xml"
        )
        raise

    # Run cros_to_android.py with subcommand generate-media-profiles.
    media_profiles_path = config_output_path / "media_profiles"
    media_profiles_path.mkdir(exist_ok=True)
    command = [
        cros_to_android_script,
        "generate-media-profiles",
        config_jsonproto,
        "--output-dir",
        media_profiles_path,
        "--dtd-schema",
        dtd_schema_file,
    ]
    try:
        util_run_command(command)
    except (FileNotFoundError, subprocess.CalledProcessError):
        logging.error(
            "Failed in calling cros_to_android for generate-media-profiles"
        )
        raise

    logging.info("Generated new copy of device configuration XMLs.")
    return config_output_path


def copy_config_xml_to_android(
    args: argparse.Namespace, cros_xmls_path: Path
) -> None:
    """Copy the generated config xmls to the Android device repo.

    Args:
        args: argparse.Namespace for parsed result of command line inputs.
        cros_xmls_path: Path to temp folder holding the generated xmls.

    Returns:
        A boolean with True meaning success and False meaning failure.

    Raises:
        shutil.Error: An error raised while executing shutil.copytree
    """

    def verbose_copy(src, dst):
        """Custom copy function that logs the operation.

        Args:
            src: Source path of this copy operation.
            dst: Destination path of this copy operation.
        """
        logging.debug("Copying '%s' to '%s'", src, dst)
        shutil.copy(src, dst)

    device = args.device_name
    alrepo = args.device_repo
    al_config_path = alrepo / "device/google/desktop" / device / "configs/"
    logging.debug("al_config_path is %s", al_config_path)

    try:
        shutil.copytree(
            cros_xmls_path,
            al_config_path,
            copy_function=verbose_copy,
            dirs_exist_ok=True,  # Key for overwriting
        )
        logging.info(
            'Copied the generated configuration XMLs to the "al_device_repo".'
        )
    except shutil.Error as e:
        logging.error("An error occurred: %s", e)
        raise


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse command-line args.

    Args:
        argv: A list of args passed into the script; i.e., sys.argv[1:].

    Returns:
        A namespace with the following attributes.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    logging_utils.parser_add_argument(parser)
    parser.add_argument(
        "--program",
        required=True,
        help="Name of device program or reference design",
    )
    parser.add_argument(
        "--device-name",
        required=True,
        help="Name of device project",
    )
    parser.add_argument(
        "--device-repo",
        required=True,
        type=Path,
        help="Path in Android repo for the Android device",
    )

    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    """The main function"""

    opts = parse_args(argv)
    logging_utils.config_logging(opts)

    logging.info(
        "program=%s\ndevice_name=%s\nal_device_repo=%s",
        opts.program,
        opts.device_name,
        opts.device_repo,
    )

    # Step-1: Re-generate config.jsonproto.
    try:
        regenerate_config_jsonproto(opts.program, opts.device_name)
    except subprocess.CalledProcessError:
        logging.error("Failure in regenerating config.jsonproto.")
        raise

    # Step-2: Sync with latest Hal_Config.XSD from Android repo.
    if not sync_halconfig_xsd_with_alrepo(opts.device_repo):
        logging.error("Failure in copying Hal_Config.XSD from Android repo.")
        return 1

    # Step-3: Run cros_to_antroid.py.
    cros_xml_path = run_cros_to_android_config(opts.program, opts.device_name)
    if cros_xml_path is None:
        logging.error(
            "Failure in running cros_to_android.py with all its subcommands"
        )
        return 1
    atexit.register(util_temp_folder_cleanup, cros_xml_path)

    # Step-4: Copy the generated config xmls to the Android device repo.
    try:
        copy_config_xml_to_android(opts, cros_xml_path)
    except shutil.Error:
        logging.error(
            "Failure in copying the generated xmls to Android device repo"
        )
        raise

    logging.info(
        "The full script completed successfully.\n"
        "Run git status command in the android device repo for the updates"
        " to configuration XMLs."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
