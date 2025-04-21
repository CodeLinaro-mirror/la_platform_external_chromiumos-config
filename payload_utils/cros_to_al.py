#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts a ConfigBundle JSON file to XML and validates it via XSD.

Reads a single JSON file representing a chromiumos.config.payload.ConfigBundle
message and generates an XML file conforming to an XSD schema.

The standard XSD is checked in at
https://googleplex-android.googlesource.com/device/google/desktop/common/+/main/config/hal_config.xsd
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
    from chromiumos.config.api.software import software_config_pb2
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


def _build_lookup_map(
    design_list: list[design_pb2.Design],
) -> dict[str, design_pb2.Design.Config]:
    """Builds a dict for lookup of Design.Configs.

    Args:
        design_list: A list of Design protos.

    Returns:
        A map from DesignConfigId.value to Design.Config.
    """
    design_config_map = {}

    for design in design_list:
        if not design.id.value:
            logging.warning("Design missing id, skipping: %s", design)
            continue
        for config in design.configs:
            if not config.id.value:
                logging.warning(
                    "Design.Config missing id, skipping: %s", config
                )
                continue
            design_config_map[config.id.value] = config
    return design_config_map


def _add_cellular_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds CellularConfiguration to the XML tree for a Design.Config.

    Skips if the Design.Config doesn't have cellular.

    Args:
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
    fw_variant_elem = etree.SubElement(cell_config_elem, "FirmwareVariant")
    fw_variant_elem.text = cellular_features.model
    modem_type_elem = etree.SubElement(cell_config_elem, "ModemType")
    modem_type_elem.text = modem_type_xsd_str


def _add_hal_config_entry(
    root_element: etree._Element,
    sw_config: software_config_pb2.SoftwareConfig,
    design_config_map: dict[str, design_pb2.Design.Config],
) -> None:
    """Adds a HalConfig to the XML tree for a SoftwareConfig.

    Args:
        root_element: The root XML element (<HalConfigurations>).
        sw_config: The SoftwareConfig proto to process.
        design_config_map: The lookup map for Design.Configs.
    """
    if not sw_config.design_config_id.value:
        logging.warning(
            "Skipping software config due to missing 'design_config_id': %s",
            sw_config,
        )
        return

    design_config = design_config_map.get(sw_config.design_config_id.value)
    if not design_config:
        logging.warning(
            "Could not find Design.Config for ID: %s. Skipping.",
            sw_config.design_config_id.value,
        )
        return

    hal_config_elem = etree.SubElement(root_element, "HalConfig")

    identity_elem = etree.SubElement(hal_config_elem, "Identity")
    model, sku = sw_config.design_config_id.value.split(":")
    sku_elem = etree.SubElement(identity_elem, "SkuID")
    sku_elem.text = sku
    model_elem = etree.SubElement(identity_elem, "Model")
    model_elem.text = model

    _add_cellular_entry(hal_config_elem, design_config)


def _convert_to_xml(config_bundle: config_bundle_pb2.ConfigBundle) -> bytes:
    """Converts a ConfigBundle proto to XML.

    Args:
        config_bundle: The ConfigBundle proto.

    Returns:
        The generated XML content as bytes.
    """
    logging.info("Starting XML conversion from ConfigBundle...")

    design_config_map = _build_lookup_map(config_bundle.design_list)
    logging.info(
        "Built lookup map: %d design configs.",
        len(design_config_map),
    )

    root = etree.Element("HalConfigurations")

    for sw_config in config_bundle.software_configs:
        _add_hal_config_entry(root, sw_config, design_config_map)

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


def _get_parser() -> argparse.ArgumentParser:
    """Sets up the argument parser."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "jsonproto_file",
        metavar="JSONPROTO_FILE",
        type=pathlib.Path,
        help="Path to the input JSON file representing a ConfigBundle message.",
    )
    parser.add_argument(
        "-o",
        "--output-xml",
        required=True,
        type=pathlib.Path,
        help="Path to write the output XML file.",
    )
    parser.add_argument(
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
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose debug logging.",
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    """Parses args, loads input, converts to XML, validates, and writes."""
    parser = _get_parser()
    opts = parser.parse_args(argv)

    log_level = logging.DEBUG if opts.verbose else logging.INFO
    logging.basicConfig(level=log_level)

    config_bundle = _load_config_bundle(opts.jsonproto_file)
    xml_string = _convert_to_xml(config_bundle)

    _validate_xml(xml_string, opts.xsd_schema)

    with open(opts.output_xml, "wb") as f:
        f.write(xml_string)
    logging.info("XML written to %s.", opts.output_xml)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
