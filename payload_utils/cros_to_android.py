#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts a ConfigBundle JSON file to Android configs.

Reads a single JSON file representing a chromiumos.config.payload.ConfigBundle
message and generates corresponding Android configs, such as HAL XML files
and feature XML files.
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
    from chromiumos.config.api import design_config_id_pb2
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


def _get_sw_config(
    sw_configs: list[software_config_pb2.SoftwareConfig],
    design_config_id: design_config_id_pb2.DesignConfigId.value,
) -> software_config_pb2.SoftwareConfig:
    """Returns the correct software config match for `design_config_id`.

    If no such config or multiple such configs are found an exception is raised.

    Args:
        sw_configs: list of all software configs in a config bundle.
        design_config_id: unique identifier mapped to a design config

    Returns:
        A software_config_pb2.SoftwareConfig matching design config ID.
    """
    sw_config_matches = [
        x for x in sw_configs if x.design_config_id.value == design_config_id
    ]
    if len(sw_config_matches) == 1:
        return sw_config_matches[0]
    if len(sw_config_matches) > 1:
        raise ValueError(
            f"Multiple software configs found for: { design_config_id}"
        )
    raise ValueError(f"Software config is required for: {design_config_id}")


def _get_fw_customization_id(design_config: design_pb2.Design.Config) -> str:
    """Returns firmware config customization string

    Args:
        design_config: The Design.Config proto.

    Returns:
        Firmware config customization string
    """
    fw_config = design_config.hardware_features.fw_config
    return "_".join(
        f"_{customization}"
        for customization in sorted(fw_config.coreboot_customizations)
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
    etree.SubElement(
        fp_config_elem, "fingerprint-sensor-type"
    ).text = sensor_type_xsd_str
    if fp_features.ro_version:
        etree.SubElement(
            fp_config_elem, "ro-version"
        ).text = fp_features.ro_version
    etree.SubElement(fp_config_elem, "sensor-location").text = location_enum_str


def _add_firmware_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
    sw_config: software_config_pb2.SoftwareConfig,
) -> None:
    """Adds FirmwareConfiguration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
        sw_config: software_config_pb2.SoftwareConfig specific to a design
        config.
    """
    fw_main_ro = sw_config.firmware.main_ro_payload
    if fw_main_ro and fw_main_ro.firmware_image_name:
        image_name = (
            fw_main_ro.firmware_image_name.lower()
            + _get_fw_customization_id(design_config)
        )
    else:
        logging.warning(
            "Firmware image name not found for Design.Config ID '%s'."
            "Skipping FirmwareConfiguration.",
            design_config.id.value,
        )
        return

    firmware_config_elem = etree.SubElement(hal_config, "FirmwareConfiguration")
    fw_image_name_elem = etree.SubElement(
        firmware_config_elem, "firmware-manifest-key"
    )
    fw_image_name_elem.text = image_name


def _add_hal_config_entry(
    root_element: etree._Element,
    design_config: design_pb2.Design.Config,
    sw_config: software_config_pb2.SoftwareConfig,
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
    _add_firmware_entry(hal_config_elem, design_config, sw_config)


def _convert_to_hal_xml(config_bundle: config_bundle_pb2.ConfigBundle) -> bytes:
    """Converts a ConfigBundle proto to HAL XML.

    Args:
        config_bundle: The ConfigBundle proto.

    Returns:
        The generated HAL XML content as bytes.
    """
    logging.info("Starting XML conversion from ConfigBundle...")

    root = etree.Element("HalConfigurations")

    for design in config_bundle.design_list:
        for design_config in design.configs:
            sw_config = _get_sw_config(
                config_bundle.software_configs, design_config.id.value
            )
            _add_hal_config_entry(root, design_config, sw_config)

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
    xml_string = _convert_to_hal_xml(config_bundle)
    _validate_xml(xml_string, opts.xsd_schema)

    opts.output_xml.parent.mkdir(parents=True, exist_ok=True)
    with open(opts.output_xml, "wb") as f:
        f.write(xml_string)
    logging.info("XML written to %s.", opts.output_xml)


def _generate_fingerprint_feature_xml(
    design_config: design_pb2.Design.Config, output_dir: pathlib.Path
) -> None:
    """Generates the fingerprint feature XML if the feature is present.

    Args:
        design_config: The Design.Config proto.
        output_dir: The base directory to write the feature XML into.
    """
    if not design_config.id.value:
        logging.warning(
            "Skipping Design.config due to missing 'design_config.id': %s",
            design_config,
        )
        return

    if not design_config.hardware_features.fingerprint.present:
        logging.debug(
            "Skipping fingerprint feature XML for %s: feature not present.",
            design_config.id.value,
        )
        return

    model, sku = design_config.id.value.split(":")

    config_dir_name = f"{model}_{sku}"
    config_output_dir = output_dir / config_dir_name
    output_file = config_output_dir / "android.hardware.fingerprint.xml"

    permissions_elem = etree.Element("permissions")
    feature_elem = etree.SubElement(permissions_elem, "feature")
    feature_elem.set("name", "android.hardware.fingerprint")

    xml_bytes = etree.tostring(
        permissions_elem,
        pretty_print=True,
    )

    config_output_dir.mkdir(parents=True, exist_ok=True)
    with open(output_file, "wb") as f:
        f.write(xml_bytes)
    logging.info(
        "Writing fingerprint feature XML for %s:%s to %s",
        model,
        sku,
        output_file,
    )


def run_generate_feature_xml(opts: argparse.Namespace) -> None:
    """Handles the 'generate-feature-xml' sub-command logic."""
    logging.info("Running generate-feature-xml command...")
    config_bundle = _load_config_bundle(opts.jsonproto_file)

    output_dir = opts.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    for design in config_bundle.design_list:
        for design_config in design.configs:
            _generate_fingerprint_feature_xml(design_config, output_dir)


def _get_parser() -> argparse.ArgumentParser:
    """Sets up the main argument parser and sub-parsers."""
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose debug logging.",
    )

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
        help="Path to write the output HAL XML file.",
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
    parser_hal_xml.set_defaults(func=run_generate_hal_xml)

    parser_feature_xml = subparsers.add_parser(
        "generate-feature-xml",
        help="Generate Android feature XML files based on hardware presence.",
    )
    parser_feature_xml.add_argument(
        "jsonproto_file",
        metavar="JSONPROTO_FILE",
        type=pathlib.Path,
        help="Path to the input JSON file representing a ConfigBundle message.",
    )
    parser_feature_xml.add_argument(
        "-o",
        "--output-dir",
        required=True,
        type=pathlib.Path,
        help="Path to the base directory where <Model>_<SkuID> subdirectories "
        "containing feature XML files will be created.",
    )
    parser_feature_xml.set_defaults(func=run_generate_feature_xml)

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
