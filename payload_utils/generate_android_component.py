#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates android configurations for hardware components in starlark file.

Dependencies:
1.  android_component_ids.star
2.  hal_config.xml

Usage:
Run this script from the specific project directory:
  cd src/project/<program>/<project>/
  ./config/payload_utils/generate_android_component.py --help

Output files android_hal_configs.star file is created in the designated directory.
"""

import argparse
import logging
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Optional

from common import logging_utils
from lxml import etree  # pylint: disable=import-error


THIS_SCRIPT_FILE = Path(__file__).resolve()
THIS_CONFIG_DIR = THIS_SCRIPT_FILE.parent.parent
THIS_SRC_DIR = THIS_CONFIG_DIR.parent

# HAL_COMPONENT_ID_FIELD_MAP:
# Maps the component name in the HAL config XML to the fields used in the
# Starlark file.
#   "id_field": used to uniquely identify a configuration for this component.
#   "comp_name_star": used for starlark configuration related to this component.
HAL_COMPONENT_ID_FIELD_MAP = {
    "AudioConfiguration": {
        "id_field": "audio-config-dir",
        "comp_name_star": "audio",
    },
    "FingerprintConfiguration": {
        "id_field": "board",
        "comp_name_star": "fingerprint",
    },
    "CellularConfiguration": {
        "id_field": "modem-type",
        "comp_name_star": "cellular",
    },
    "CameraConfiguration": {
        "id_field": "media-profile-suffix",
        "comp_name_star": "camera",
    },
    "StorageConfiguration": {
        "id_field": "storage-type",
        "comp_name_star": "storage",
    },
    "KeyboardConfiguration": {
        "id_field": "backlight-support",
        "comp_name_star": "keyboard",
    },
    "StylusConfiguration": {
        "id_field": "stylus-type",
        "comp_name_star": "stylus",
    },
}


def util_run_command(command: list[str]) -> None:
    """Runs a command and logs its output based on global log level.

    Args:
        command: List of command line parameters.

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


def run_cros_to_android_config(
    cros_xsd_file: Path, program: str, device: str, output_path: Path
) -> None:
    """Run cros_to_android.py with subcommand generate-hal-xml.

    Args:
        cros_xsd_file: Path to the XSD schema file
        program: Name of device program or reference design.
        device: Name of the Android device project.
        output_path: Parent path to the output file hal_config.xml.

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

    # Run cros_to_android.py with subcommand generate-hal-xml.
    hal_config_xml = output_path / "hal_config.xml"
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

    logging.info("Generated new copy of hal_config at file %s.", hal_config_xml)


def load_xml_tree(filepath: Path) -> Optional[etree._ElementTree]:
    """Parses an XML file and returns its ElementTree object.

    Args:
        filepath: The path to the XML file.

    Returns:
        The parsed ElementTree object, or None if an error occurs.
    """
    try:
        tree = etree.parse(filepath)
        logging.info("Successfully parsed '%s'", filepath)
        return tree
    except IOError as e:
        logging.error(
            "Error: The file '%s' could not be found or read: %s", filepath, e
        )
        return None
    except etree.XMLSyntaxError as e:
        logging.error(
            "Error: XML syntax error in '%s'. Details: %s", filepath, e
        )
        return None


def process_halconfig_tree(
    root: etree._Element, component: str
) -> Optional[list]:
    """Processes the halconfig to extract unique configuration of a component.

    Args:
        root: The root of the XML tree.
        component: The name of the component to process.

    Returns:
        A list of the unique configurations of a given component, or None if error.
    """
    logging.info(
        "The root element is <%s> and it has %d children.", root.tag, len(root)
    )
    comp_id_field = HAL_COMPONENT_ID_FIELD_MAP[component]["id_field"]
    unique_configs = {}
    for config_sku in root.findall("HalConfig"):
        hal_comp_elem = config_sku.find(component)
        if hal_comp_elem is None:
            continue
        hal_comp_id_elem = hal_comp_elem.find(comp_id_field)
        if hal_comp_id_elem is None:
            continue
        dict_comp_elem = unique_configs.setdefault(
            hal_comp_id_elem.text, hal_comp_elem
        )
        curr_elem_str = etree.tostring(hal_comp_elem).strip()
        dict_elem_str = etree.tostring(dict_comp_elem).strip()
        if curr_elem_str != dict_elem_str:
            logging.error(
                "[%s] configs same in id field should be same in other fields.",
                component,
            )
            return None
    return list(unique_configs.values())


def generate_configstar_per_component(
    comp_name: str, comp_configs: list, star_content: list
) -> dict:
    """Generates Starlark configuration for a single component type.

    Args:
        comp_name: The component name to be used in
            Starlark variables.
        comp_configs: A list of unique configurations for the component.
        star_content: A list to append the generated Starlark lines to.

    Returns:
        A dictionary containing the component name and a list of generated
        Starlark variable names.
    """
    logging.info("%s  - %s", comp_name, comp_configs)
    component_star_vars = {}
    listed_items = []
    for i, hal_comp_elem in enumerate(comp_configs, start=1):
        # Create a unique local temporary variable name.
        listed_item = f"_ANDROID_HAL_{comp_name.upper()}_Id{i}"
        listed_items.append(listed_item)
        id_field_name = HAL_COMPONENT_ID_FIELD_MAP[
            f"{comp_name.capitalize()}Configuration"
        ]["id_field"]
        star_content.append(
            f"\n{listed_item} = android_hal_config.create_{comp_name}("
        )
        for child in hal_comp_elem.iterchildren():
            if child.tag == id_field_name:
                name = child.text.upper()
                star_content.append(
                    f"    id = android_component_ids.{comp_name}.{name},\n"
                    f'    {child.tag} =  "{child.text}",'
                )
            else:
                star_content.append(f'    {child.tag} =  "{child.text}",')
        star_content.append(")")

    component_star_vars.setdefault(comp_name, listed_items)
    return component_star_vars


def generate_configstar(opts: argparse.Namespace) -> bool:
    """Generates the hardware components Starlark file based on the parsed XML.

    Args:
        opts: The command line arguments.

    Returns:
        True if the Starlark file was generated successfully, False otherwise.
    """
    lines = '''#!/usr/bin/env gen_config
"""Auto-generated by generate_android_component.py"""
"""Generates a Android_Component_Configs proto for the project."""

load("//config/util/android_component_utils.star", "android_hal_config")
load("//android_component_ids.star", "android_component_ids")
'''.splitlines()

    with tempfile.TemporaryDirectory() as tmpdirname:
        output_path = Path(tmpdirname)
        try:
            run_cros_to_android_config(
                opts.xsd_schema, opts.program, opts.device, output_path
            )
        except subprocess.CalledProcessError as e:
            logging.error("Command failed with exit code %s", e.returncode)
            return False
        # Parse the hal_config.xml.
        final_configstar_components = []
        halconfig_tree = load_xml_tree(output_path / "hal_config.xml")
        if not halconfig_tree:
            return False
        root = halconfig_tree.getroot()
        for component, value in HAL_COMPONENT_ID_FIELD_MAP.items():
            component_configs = process_halconfig_tree(root, component)
            if component_configs is None:
                return False
            configstar_component = generate_configstar_per_component(
                value["comp_name_star"],
                component_configs,
                lines,
            )
            final_configstar_components.append(configstar_component)

        lines.append(
            "\nANDROID_HAL_CONIFG = android_hal_config.create_hal_config("
        )
        for configstar_component in final_configstar_components:
            for key, value in configstar_component.items():
                lines.append(f"    {key}_configurations = {value},")
        lines.append(")")

        opts.output_file.write_text("".join(f"{x}\n" for x in lines))
        return True


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parses command-line arguments.

    Args:
        argv: A list of arguments passed to the script.

    Returns:
        The parsed arguments.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    logging_utils.parser_add_argument(parser)
    parser.add_argument(
        "-x",
        "--xsd-schema",
        required=True,
        type=Path,
        help="Path to the XSD schema file for validation.",
    )
    parser.add_argument(
        "--program",
        required=True,
        help="Name of device program or reference design",
    )
    parser.add_argument(
        "--device",
        required=True,
        help="Name of device project",
    )
    parser.add_argument(
        "-o",
        "--output-file",
        required=True,
        type=Path,
        help="Output Starlark file path",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    """Main function to generate the Android component Starlark file.

    Args:
        argv: Command line arguments.

    Returns:
        Exit code (0 for success).
    """

    opts = parse_args(argv)
    logging_utils.config_logging(opts)
    logging.info("program=%s device=%s", opts.program, opts.device)

    # Call the config starlark generating function.
    return 0 if generate_configstar(opts) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
