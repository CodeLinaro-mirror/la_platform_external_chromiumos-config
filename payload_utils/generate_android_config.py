#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Developer script for generating the Android configurations.

This script is used to test unsubmitted config changes on local Android devices.

There are three modes of operation:
  'classic': Regenerates config.jsonproto, syncs Hal_Config.XSD, runs
             cros_to_android.py for classic HAL, feature, and media profile
             XMLs, and copies them to the Android device repo. This mode is for
             devices with classic ChromeOS DesignConfigID provisioned.
             The steps are:
             1) Re-generate config.jsonproto by calling gen_config.sh.
             2) Sync with latest Hal_Config.XSD from Android repo.
             3) Run cros_to_android.py with generate-hal-xml,
                generate-feature-xml, and generate-media-profiles subcommands.
             4) Copy generated XMLs to the Android device repo.

  'fetch-component-star': Fetches the component_ids.star artifact for the
                          specified device from Busytown.

  'generate-component-xmls': Regenerates config.jsonproto and runs
                             cros_to_android.py to generate component-based
                             XMLs, feature XMLs from HAL, and media profiles
                             from HAL, copying them to the Android device repo.
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
    logging.debug("Running command: %s", command)
    try:
        result = subprocess.run(command, check=True)

        if result.stdout:
            logging.debug("Command output (stdout):\n%s", result.stdout.strip())

        logging.debug("Command finished successfully: %s", command[0])

    except subprocess.CalledProcessError as e:
        logging.error("Command failed with exit code %s", e.returncode)
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
    device_name: str, device_repo: Path, cros_xmls_path: Path
) -> None:
    """Copy the generated config xmls to the Android device repo.

    Args:
        device_name: Name of the Android device project.
        device_repo: Path to the ARSP repo for the same device.
        cros_xmls_path: Path to temp folder holding the generated xmls.

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

    al_config_path = (
        device_repo / "device/google/desktop" / device_name / "configs/"
    )
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
        help="Path of ARSP repo for the Android device",
    )
    parser.add_argument(
        "--mode",
        default="classic",
        choices=("classic", "fetch-component-star", "generate-component-xmls"),
        help="Which operation mode to run. See module docstring for details.",
    )

    return parser.parse_args(argv)


def main_classic(program: str, device_name: str, device_repo: Path) -> int:
    """Run cros_to_android.py with subcommand generate-hal-xml.

    Args:
        program: Name of device program or reference design.
        device_name: Name of the Android device project.
        device_repo: Path to the ARSP repo for the same device.

    Returns:
        0 for success, or error code otherwise.
    """
    # Step-1: Re-generate config.jsonproto.
    try:
        regenerate_config_jsonproto(program, device_name)
    except subprocess.CalledProcessError:
        logging.error("Failure in regenerating config.jsonproto.")
        raise

    # Step-2: Sync with latest Hal_Config.XSD from Android repo.
    if not sync_halconfig_xsd_with_alrepo(device_repo):
        logging.error("Failure in copying Hal_Config.XSD from Android repo.")
        return 1

    # Step-3: Run cros_to_antroid.py.
    cros_xml_path = run_cros_to_android_config(program, device_name)
    if cros_xml_path is None:
        logging.error(
            "Failure in running cros_to_android.py with all its subcommands"
        )
        return 1
    atexit.register(util_temp_folder_cleanup, cros_xml_path)

    # Step-4: Copy the generated config xmls to the Android device repo.
    try:
        copy_config_xml_to_android(device_name, device_repo, cros_xml_path)
    except shutil.Error:
        logging.error(
            "Failure in copying the generated xmls to Android device repo"
        )
        raise

    return 0


FETCH_ARTIFACT_CMD = "/google/data/ro/projects/android/fetch_artifact"


def fetch_artifact_bid_target(target: str, artname: str) -> None:
    """Run fetch_artifact to download BUILD_INFO file.

    Args:
        target: Name of build target to look for on Android Build server.
        artname: Name of the artifact to be fetched.

    Raises:
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    command = [
        FETCH_ARTIFACT_CMD,
        "--latest",
        "--branch",
        "arsp-main",
        "--target",
        target,
        artname,
        "android_component_ids.star",
    ]
    util_run_command(command)
    logging.info("successfully downloaded %s for target=%s", artname, target)


def main_handle_fetch_component_star(device: str) -> None:
    """Handle fetch component.star artifact.

    Args:
        device: Name of the Android device project.

    Raises:
        subprocess.CalledProcessError: An error raised while executing
            the subproccess call.
    """
    target = f"{device}-trunk_staging-userdebug"
    artifact_name = f"{device}-component_ids.star"
    fetch_artifact_bid_target(target, artifact_name)


def main_handle_generate_xmls(program: str, device: str, repo: Path) -> int:
    """Generate the per component configuration xmls.

    Args:
        program: Name of device program or reference design.
        device: Name of the Android device project.
        repo: Path to the ARSP repo for the same device.

    Returns:
        0 for success, or error code otherwise.
    """
    cros_to_android_script = (
        THIS_CONFIG_DIR / "payload_utils/cros_to_android.py"
    )
    config_jsonproto = Path.cwd() / "generated/config.jsonproto"
    dtd_schema_file = THIS_CONFIG_DIR / "payload_utils/media_profiles.dtd"

    # Create temp folder for storing generated config xmls.
    temp_dir = tempfile.mkdtemp()
    config_output_root = Path(temp_dir)
    atexit.register(util_temp_folder_cleanup, config_output_root)

    # Re-generate config.jsonproto.
    try:
        regenerate_config_jsonproto(program, device)
    except subprocess.CalledProcessError:
        logging.error("Failure in regenerating config.jsonproto.")
        raise

    # Generate component based config xmls
    # example command -
    # ./config/payload_utils/cros_to_android.py generate-component-xmls
    # ./generated/config.jsonproto --output-dir ./generated/
    logging.debug("Run generate-component-xmls for %s", device)
    command = [
        cros_to_android_script,
        "generate-component-xmls",
        config_jsonproto,
        "--output-dir",
        config_output_root / "components",
    ]
    try:
        util_run_command(command)
    except subprocess.CalledProcessError:
        logging.error(
            "Failed in calling cros_to_android for generate-component-xmls"
        )
        raise

    # Generate features config xmls
    # example command -
    # ./config/payload_utils/cros_to_android.py generate-feature-xml
    # --from-hal-config --output-dir ./generated/ ./generated/config.jsonproto
    logging.debug("Run generate-feature-xml for %s", device)
    command = [
        cros_to_android_script,
        "generate-feature-xml",
        "--from-hal-config",
        "--output-dir",
        config_output_root / "features_from_hal",
        config_jsonproto,
    ]
    try:
        util_run_command(command)
    except subprocess.CalledProcessError:
        logging.error(
            "Failed in calling cros_to_android for generate-feature-xml"
        )
        raise

    # Generate media profiles xmls
    # example command -
    # ./config/payload_utils/cros_to_android.py generate-media-profiles
    # --from-hal-config  -o ./generated/  -d media_profiles.dtd
    # ./generated/config.jsonproto
    logging.debug("Run generate-media-profiles for %s", device)
    command = [
        cros_to_android_script,
        "generate-media-profiles",
        "--from-hal-config",
        "--output-dir",
        config_output_root / "media_profiles_from_hal",
        "--dtd-schema",
        dtd_schema_file,
        config_jsonproto,
    ]
    try:
        util_run_command(command)
    except subprocess.CalledProcessError:
        logging.error(
            "Failed in calling cros_to_android for generate-media-profiles "
        )
        raise

    # Copy the generated config xmls to the Android device repo.
    try:
        copy_config_xml_to_android(device, repo, config_output_root)
    except shutil.Error:
        logging.error(
            "Failure in copying the generated xmls to Android device repo"
        )
        raise

    logging.info("Generated new copy of device component based config XMLs.")
    logging.info(
        "Please run git status -c %s/device/google/desktop/%s", repo, device
    )
    return 0


def main(argv: Optional[list[str]] = None) -> int:
    """The main function"""

    opts = parse_args(argv)
    logging_utils.config_logging(opts)

    logging.info(
        "program=%s\ndevice_name=%s\nal_device_repo=%s\nmode=%s",
        opts.program,
        opts.device_name,
        opts.device_repo,
        opts.mode,
    )

    if opts.mode == "classic":
        return main_classic(opts.program, opts.device_name, opts.device_repo)
    if opts.mode == "fetch-component-star":
        main_handle_fetch_component_star(opts.device_name)
        return 0
    if opts.mode == "generate-component-xmls":
        return main_handle_generate_xmls(
            opts.program, opts.device_name, opts.device_repo
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
