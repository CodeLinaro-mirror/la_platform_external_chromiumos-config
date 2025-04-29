#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts a ConfigBundle JSON file to Android configs.

Reads a single JSON file representing a chromiumos.config.payload.ConfigBundle
message and generates corresponding Android configs, such as HAL XML files.
"""

# [VPYTHON:BEGIN]
# python_version: "3.11"
# wheel: <
#   name: "infra/python/wheels/lxml/${vpython_platform}"
#   version: "version:4.9.3"
# >
# wheel: <
#   name: "infra/python/wheels/protobuf-py2_py3"
#   version: "version:3.18.1"
# >
# [VPYTHON:END]

import argparse
import logging
import pathlib
import sys
from typing import Optional

from google.protobuf import json_format  # pylint: disable=import-error
from lxml import etree  # pylint: disable=import-error


# TODO(b/402027869): Figure out a better way to distribute this proto with the
# script.
try:
    from chromiumos.config.api import design_pb2
    from chromiumos.config.api import topology_pb2
    from chromiumos.config.payload import config_bundle_pb2
except ImportError:
    sys.exit(
        "Could not import chromiumos.config protobuf bindings. "
        "Make sure the files exist and the directory structure "
        "(e.g., chromiumos/config/api/) is correct relative to the script's"
        " execution directory or in your PYTHONPATH."
    )


def _load_config_bundle(
    file_path: pathlib.Path,
) -> config_bundle_pb2.ConfigBundle:
    """Loads and parses data from a single JSON-encoded ConfigBundle file.

    Args:
        file_path: The path to the input JSON file.

    Returns:
        A ConfigBundle protobuf object
    """
    logging.info("Attempting to load protobuf JSON file: %s", file_path)
    with open(file_path, "r", encoding="utf-8") as f:
        json_content = f.read()
    bundle = config_bundle_pb2.ConfigBundle()
    json_format.Parse(json_content, bundle, ignore_unknown_fields=True)
    logging.info("Successfully parsed file: %s", file_path)
    return bundle


def _add_cellular_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds CellularConfiguration to the XML tree for a Design.Config.

    Skips if the Design.Config doesn't have cellular.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The Design.Config proto.
    """
    cellular_features = design_config.hardware_features.cellular
    if cellular_features.present != topology_pb2.HardwareFeatures.PRESENT:
        return

    modem_type_enum_val = cellular_features.modem_type
    modem_type_enum_str = topology_pb2.HardwareFeatures.Cellular.ModemType.Name(
        modem_type_enum_val
    )

    # TODO(b/402027869): We can add a fallback to guess the modem type from the
    # firmware, see
    # https://googleplex-android-review.git.corp.google.com/c/device/google/desktop/common/+/32855134/4..9/config/hal_config.xsd#b13.
    if modem_type_enum_str == "MODEM_UNKNOWN":
        logging.warning("ModemType is MODEM_UNKNOWN, skipping.")
        return

    if modem_type_enum_str.startswith("MODEM_"):
        modem_type_xsd_str = modem_type_enum_str.removeprefix("MODEM_")
    else:
        logging.warning(
            "Unexpected ModemType enum string format, skipping: %s.",
            modem_type_enum_str,
        )
        return
    cell_config_elem = etree.SubElement(hal_config, "CellularConfiguration")
    fw_variant_elem = etree.SubElement(cell_config_elem, "firmware-variant")
    fw_variant_elem.text = cellular_features.model
    modem_type_elem = etree.SubElement(cell_config_elem, "modem-type")
    modem_type_elem.text = modem_type_xsd_str


def _add_fingerprint_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds FingerprintConfiguration to the XML tree for a Design.Config.

    Infers fingerprint-sensor-type based on the location enum value, as there
    is no direct field for it in the proto.

    Skips if the Design.Config doesn't have fingerprint features marked present
    or if mandatory fields are missing/invalid in the proto.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    fp_features = design_config.hardware_features.fingerprint
    if not fp_features.present:
        return

    if not fp_features.board:
        logging.warning(
            "Fingerprint config missing mandatory 'board' field for "
            "Design.Config '%s'. Skipping FingerprintConfiguration.",
            design_config.id.value,
        )
        return

    location_enum_str = topology_pb2.HardwareFeatures.Fingerprint.Location.Name(
        fp_features.location
    )

    if location_enum_str == "LOCATION_UNKNOWN":
        logging.warning(
            "Fingerprint config has invalid 'sensor_location' ('%s') for "
            "Design.Config '%s'. Skipping FingerprintConfiguration.",
            location_enum_str,
            design_config.id.value,
        )
        return

    # This field is required by XSD but not directly present in the proto.
    # Infer based on whether 'POWER_BUTTON' is in the location name.
    sensor_type_xsd_str = (
        "POWER_BUTTON" if "POWER_BUTTON" in location_enum_str else "STAND_ALONE"
    )

    logging.debug(
        "Inferred fingerprint-sensor-type '%s' from location '%s'",
        sensor_type_xsd_str,
        location_enum_str,
    )

    fp_config_elem = etree.SubElement(hal_config, "FingerprintConfiguration")
    etree.SubElement(fp_config_elem, "board").text = fp_features.board
    etree.SubElement(fp_config_elem, "fingerprint-sensor-type").text = (
        sensor_type_xsd_str
    )
    if fp_features.ro_version:
        etree.SubElement(fp_config_elem, "ro-version").text = (
            fp_features.ro_version
        )
    etree.SubElement(fp_config_elem, "sensor-location").text = location_enum_str


def _add_hal_config_entry(
    root_element: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds a HalConfig to the XML tree for a Design.Config.

    Args:
        root_element: The root XML element (<HalConfigurations>).
        design_config: The Design.Config proto to process.
    """
    if not design_config.id.value:
        logging.warning(
            "Skipping Design.config due to missing 'design_config.id': %s",
            design_config,
        )
        return

    hal_config_elem = etree.SubElement(root_element, "HalConfig")

    identity_elem = etree.SubElement(hal_config_elem, "Identity")
    model, sku = design_config.id.value.split(":")
    sku_elem = etree.SubElement(identity_elem, "sku-id")
    sku_elem.text = sku
    model_elem = etree.SubElement(identity_elem, "model")
    model_elem.text = model

    _add_cellular_entry(hal_config_elem, design_config)
    _add_fingerprint_entry(hal_config_elem, design_config)


def _convert_to_xml(config_bundle: config_bundle_pb2.ConfigBundle) -> bytes:
    """Converts a ConfigBundle proto to XML.

    Args:
        config_bundle: The ConfigBundle proto.

    Returns:
        The generated XML content as bytes.
    """
    logging.info("Starting XML conversion from ConfigBundle...")

    root = etree.Element("HalConfigurations")

    for design in config_bundle.design_list:
        for design_config in design.configs:
            _add_hal_config_entry(root, design_config)

    return etree.tostring(
        root,
        pretty_print=True,
    )


def _validate_xml(xml_string: bytes, xsd_file_path: pathlib.Path) -> None:
    """Validates XML content against an XSD schema file.

    Args:
        xml_string: The XML content.
        xsd_file_path: Path to the XSD schema file.
    """
    logging.info("Validating generated XML against schema: %s", xsd_file_path)
    with open(xsd_file_path, "rb") as f:
        xsd_doc = etree.XML(f.read())
    schema = etree.XMLSchema(xsd_doc)
    logging.debug("Schema parsed successfully.")

    xml_doc = etree.fromstring(xml_string)
    logging.debug("Generated XML parsed successfully.")

    schema.assertValid(xml_doc)
    logging.info("XML validation successful.")


def run_generate_hal_xml(opts: argparse.Namespace) -> None:
    """Handles the 'generate-hal-xml' sub-command logic."""
    logging.info("Running generate-hal-xml command...")
    config_bundle = _load_config_bundle(opts.jsonproto_file)
    xml_string = _convert_to_xml(config_bundle)
    _validate_xml(xml_string, opts.xsd_schema)

    opts.output_xml.parent.mkdir(parents=True, exist_ok=True)
    with open(opts.output_xml, "wb") as f:
        f.write(xml_string)
    logging.info("XML written to %s.", opts.output_xml)


def _get_parser() -> argparse.ArgumentParser:
    """Sets up the main argument parser and sub-parsers."""
    parser = argparse.ArgumentParser(description=__doc__)

    subparsers = parser.add_subparsers(required=True)

    parser_hal_xml = subparsers.add_parser(
        "generate-hal-xml",
        help="Generate the HAL XML configuration file and validate it.",
    )
    parser_hal_xml.add_argument(
        "jsonproto_file",
        metavar="JSONPROTO_FILE",
        type=pathlib.Path,
        help="Path to the input JSON file representing a ConfigBundle message.",
    )
    parser_hal_xml.add_argument(
        "-o",
        "--output-xml",
        required=True,
        type=pathlib.Path,
        help="Path to write the output XML file.",
    )
    parser_hal_xml.add_argument(
        "-x",
        "--xsd-schema",
        required=True,
        type=pathlib.Path,
        help=(
            "Path to the XSD schema file for validation. For example "
            "https://googleplex-android.googlesource.com/"
            "device/google/desktop/common/+/main/config/hal_config.xsd."
        ),
    )
    parser_hal_xml.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose debug logging.",
    )
    parser_hal_xml.set_defaults(func=run_generate_hal_xml)

    return parser


def main(argv: Optional[list[str]] = None) -> int:
    """Parses args and dispatches to the appropriate sub-command function."""
    parser = _get_parser()
    opts = parser.parse_args(argv)

    log_level = logging.DEBUG if opts.verbose else logging.INFO
    logging.basicConfig(level=log_level)

    opts.func(opts)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
