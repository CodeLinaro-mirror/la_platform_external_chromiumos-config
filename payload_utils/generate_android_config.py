#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Developer script for generating the Android configurations.

This script can be used to test unsubmitted config changes on local Android devices.

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


logger = logging.getLogger(__name__)
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
        logger.debug("Cleanup performed on temp directory at %s", to_clean_path)


def util_run_command(command: list[str]) -> None:
    """Runs a command and logs its output based on global log level.

    Args:
        command: List of command line and parameters.

    Raises:
        FileNotFoundError: An error occurred invoking the command, with
            possible cause being the command cannot be found, or else.
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    command_str = f"{command[0]}"
    logger.debug("Running command: %s", command_str)
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=True
        )

        if result.stdout:
            logger.debug("Command output (stdout):\n%s", result.stdout.strip())

        logger.debug("Command finished successfully: %s", command_str)

    except FileNotFoundError:
        logger.error("Command not found: %s", command[0])
        raise
    except subprocess.CalledProcessError as e:
        logger.error("Command failed with exit code %s", e.returncode)
        if e.stderr:
            logger.error("Error output (stderr):\n%s", e.stderr.strip())
        raise


def regenerate_config_jsonproto(program: str, project: str) -> bool:
    """Re-Generate config.jsonproto.

    Args:
        program: Name of device program or reference design.
        project: Name of device project.

    Returns:
        Whether the operation was successful.

    Raises:
        FileNotFoundError: An error occurred invoking the command, with
            possible cause being the command cannot be found, or else.
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    gen_config_file = THIS_CONFIG_DIR / "bin/gen_config"
    config_star_file = THIS_SRC_DIR / f"project/{program}/{project}/config.star"
    command = [
        gen_config_file,
        config_star_file,
    ]
    try:
        util_run_command(command)
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error("Exit with failure at running gen_config.sh command")
        raise

    logger.info(
        "Regenerate-ed config.jsonproto of %s/%s"
        " by calling src/config/bin/gen_config.",
        program,
        project,
    )
    return True


def sync_halconfig_xsd_with_alrepo(alrepo: Path) -> bool:
    """Sync with latest Hal_Config.XSD from Android repo.

    Args:
        alrepo: Path to the local repo of Android source code.

    Returns:
        A boolean with True meaning success and False meaning failure.

    Raises:
        FileNotFoundError: An error occurred invoking the command, with
            possible cause being the command cannot be found, or else.
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    cros_xsd_file = THIS_CONFIG_DIR / "payload_utils/test_data/hal_config.xsd"
    if not cros_xsd_file.exists():
        logger.error(
            "Error in accessing copy destination or it does not exist: %s",
            cros_xsd_file,
        )
        return False

    al_xsd_file = alrepo / "device/google/desktop/common/config/hal_config.xsd"
    if not al_xsd_file.exists():
        logger.error("Cannot find the copy source at %s", al_xsd_file)
        return False

    command = ["cp", "-v", al_xsd_file, cros_xsd_file]
    try:
        util_run_command(command)
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error(
            "Failure with copying hal_config.xsd to working directory."
        )
        raise

    logger.info('Sync-ed with latest Hal_Config.XSD from "al_device_repo".')
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
        FileNotFoundError: An error occurred invoking the command, with
            possible cause being the command cannot be found, or else.
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    cros_to_android_script = (
        THIS_CONFIG_DIR / "payload_utils/cros_to_android.py"
    )
    config_jsonproto = (
        THIS_SRC_DIR / f"project/{program}/{device}/generated/config.jsonproto"
    )
    cros_xsd_file = THIS_CONFIG_DIR / "payload_utils/test_data/hal_config.xsd"
    dtd_schema_file = THIS_CONFIG_DIR / "payload_utils/media_profiles.dtd"

    # Create temp folder for storing generated config xmls.
    temp_dir = tempfile.mkdtemp()
    config_output_path = Path(temp_dir)

    # Run cros_to_android.py with subcommand generate-hal-xml.
    hal_config_xml = config_output_path / "hal_config.xml"
    logger.debug("Run generate-hal-xml for %s", device)
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
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error("Failed in calling cros_to_android for generate-hal-xml")
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
        logger.error(
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
        logger.error(
            "Failed in calling cros_to_android for generate-media-profiles"
        )
        raise

    logger.info("Generated new copy of device cofiguration XMLs.")
    return config_output_path


def copy_config_xml_to_android(
    args: argparse.Namespace, cros_xmls_path: Path
) -> bool:
    """Copy the generated config xmls to the Android device repo.

    Args:
        args: argparse.Namespace for parsed result of command line inputs.
        cros_xmls_path: Path to temp folder holding the generated xmls.

    Returns:
        A boolean with True meaning success and False meaning failure.

    Raises:
        FileNotFoundError: An error occurred invoking the command, with
            possible cause being the command cannot be found, or else.
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
        shutil.Error: An error raised while executing shutil.copytree
    """

    def verbose_copy(src, dst):
        """Custom copy function that logs the operation.

        Args:
            src: Source path of this copy operation.
            dst: Destination path of this copy operation.
        """
        logger.debug("Copying '%s' to '%s'", src, dst)
        shutil.copy(src, dst)

    device = args.device_name
    alrepo = args.device_repo
    al_config_path = alrepo / f"device/google/desktop/{device}/configs/"
    logger.debug("al_config_path is %s", al_config_path)

    if not cros_xmls_path.is_dir():
        logger.error(
            "Error: Source directory does not exist: %s", cros_xmls_path
        )
        return False

    try:
        # The main copy operation.
        shutil.copytree(
            cros_xmls_path,
            al_config_path,
            copy_function=verbose_copy,
            dirs_exist_ok=True,  # Key for overwriting
        )
        logger.info(
            'Copied the generated configuration XMLs to the "al_device_repo".'
        )
        return True
    except shutil.Error as e:
        logger.error("An error occurred: %s", e)
        raise


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse command-line args.

    Args:
        argv: A list of args passed into the script; i.e., sys.argv[1:].

    Returns:
        A namespace with the following attributes.
    """
    parser = argparse.ArgumentParser(description=__doc__)
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
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose debug logging.",
    )

    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    """The main function"""

    opts = parse_args(argv)
    log_level = logging.DEBUG if opts.verbose else logging.INFO
    log_format = "[%(levelname)s] %(message)s"
    logging.basicConfig(level=log_level, format=log_format)

    logger.info(
        "program=%s\ndevice_name=%s\nal_device_repo=%s",
        opts.program,
        opts.device_name,
        opts.device_repo,
    )
    logger.debug(
        "Note that this script assumes it is called from ChromeOS repo with"
        " current working directory (CWD) as src/project/%s/%s",
        opts.program,
        opts.device_name,
    )
    if not opts.verbose:
        logger.info(
            'Some steps may take longer delay, use "-v" for more detailed prints.'
        )

    # Step-1: Re-generate config.jsonproto.
    try:
        if not regenerate_config_jsonproto(opts.program, opts.device_name):
            logger.error("Failure in re-generating config.jsonproto.")
            return 1
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error("Failure in re-generating config.jsonproto.")
        raise

    # Step-2: Sync with latest Hal_Config.XSD from Android repo.
    try:
        if not sync_halconfig_xsd_with_alrepo(opts.device_repo):
            logger.error("Failure in copying Hal_Config.XSD from Android repo.")
            return 1
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error("Failure in copying Hal_Config.XSD from Android repo.")
        raise

    # Step-3: Run cros_to_antroid.py.
    try:
        cros_xml_path = run_cros_to_android_config(
            opts.program, opts.device_name
        )
        if cros_xml_path is None:
            logger.error(
                "Failure in running cros_to_android.py with all its subcommands"
            )
            return 1
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.error(
            "Failure in running cros_to_android.py with all its subcommands"
        )
        raise
    atexit.register(util_temp_folder_cleanup, cros_xml_path)

    # Step-4: Copy the generated config xmls to the Android device repo.
    try:
        if not copy_config_xml_to_android(opts, cros_xml_path):
            logger.error(
                "Failure in copying the generated config xmls to the Android device repo"
            )
            return 1
    except (FileNotFoundError, subprocess.CalledProcessError, shutil.Error):
        logger.error(
            "Failure in copying the generated config xmls to the Android device repo"
        )
        raise

    logger.info(
        "The full script completed successfully.\n"
        'Run git status command in the "al_device_repo" for the updates to configuraion XMLs.'
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
