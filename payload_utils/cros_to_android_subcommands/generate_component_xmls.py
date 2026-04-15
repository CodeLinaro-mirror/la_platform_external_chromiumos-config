# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates individual component XML files from a ConfigBundle."""

import logging
import pathlib

from chromiumos.config.api import android_component_configs_pb2
from chromiumos.config.payload import config_bundle_pb2
from lxml import etree  # pylint: disable=import-error


def _populate_element_from_message(
    parent_element: etree.Element, message, skip_id: bool = False
):  # pylint: disable=too-many-branches
    """Recursively populates an XML element from a protobuf message.

    Args:
        parent_element: The XML element to attach fields to.
        message: The protobuf message to process.
        skip_id: If True, skips the 'id' field (used for the root component).
    """
    for field in message.DESCRIPTOR.fields:
        if skip_id and field.name == "id":
            continue

        if field.name == "default":
            # The 'default' field is used as a signal for the converter and
            # should not be included in the output XML.
            continue

        value = getattr(message, field.name)

        # Skip default or empty fields.
        if field.label == field.LABEL_REPEATED:
            if not value:
                logging.debug(
                    "Repeated field %s is empty, skipping.", field.name
                )
                continue
        elif field.type == field.TYPE_MESSAGE:
            if not message.HasField(field.name):
                logging.debug(
                    "Message field %s is not set, skipping.", field.name
                )
                continue
        elif value == field.default_value:
            logging.debug("Field %s is default, skipping.", field.name)
            continue

        field_options = field.GetOptions()
        if field_options.HasExtension(
            android_component_configs_pb2.name_override
        ):
            element_name = field_options.Extensions[
                android_component_configs_pb2.name_override
            ]
        else:
            element_name = field.name.replace("_", "-")

        repeated_type = field.label == field.LABEL_REPEATED
        items = value if repeated_type else [value]

        for index, item_value in enumerate(items):
            per_name = (
                element_name + str(index + 1) if repeated_type else element_name
            )
            elem = etree.SubElement(parent_element, per_name)
            if field.type == field.TYPE_MESSAGE:
                _populate_element_from_message(elem, item_value, skip_id=False)
            elif field.type == field.TYPE_ENUM:
                # TODO(b/449551444): Add a unit test for enums once there are actually
                # enums in the input proto schema.
                elem.text = field.enum_type.values_by_number[item_value].name
            else:
                elem.text = str(item_value)


def _generate_xml_for_component(
    component_config, output_dir: pathlib.Path, default: bool = False
):
    """Generates an XML file for a single component configuration.

    Args:
        component_config: A protobuf message for a single component in
           a HalConfiguration message (e.g., AudioConfigurationType).
        output_dir: The directory to write the XML file to.
        default: If True, generates "<prefix>_default.xml" instead of
           "<id>.xml", where "<prefix>" is the first part of the
           "component_id" split by "_". For example, if the component id is
           "Fingerprint_123", the default file will be
           "fingerprint_default.xml".
    """
    descriptor = component_config.DESCRIPTOR

    root_element_name = descriptor.name.removesuffix("Type")
    root = etree.Element(root_element_name)

    component_id = component_config.id
    if not component_id:
        logging.warning(
            "Component config is missing an 'id' field, skipping: %s",
            component_config,
        )
        return

    _populate_element_from_message(root, component_config, skip_id=True)

    if default:
        prefix = component_id.split("_")[0].lower()
        output_file = output_dir / f"{prefix}_default.xml"
    else:
        output_file = output_dir / f"{component_id}.xml"

    with open(output_file, "wb") as f:
        f.write(etree.tostring(root, pretty_print=True, xml_declaration=False))
    logging.info("Wrote component XML to %s", output_file)


def generate(
    config_bundle: config_bundle_pb2.ConfigBundle, output_dir: pathlib.Path
):
    """Generates component XML files from a ConfigBundle.

    This function reads the `android_hal_config` from the provided
    `ConfigBundle` and iterates through its component lists (e.g. `audio_list`).
    For each component configuration it generates a separate XML file.

    Each generated XML file is named after the `id` field of the component
    message. The root element of the XML file is the name of the component
    protobuf message, with the "Type" suffix removed (e.g.,
    "AudioConfiguration"). Each field in the protobuf message becomes a field in
    the element.

    Args:
        config_bundle: The ConfigBundle protobuf object.
        output_dir: The directory to write the XML files to.
    """
    logging.info("Generating component XML files...")
    output_dir.mkdir(parents=True, exist_ok=True)

    hal_config = config_bundle.android_hal_config

    for field in hal_config.DESCRIPTOR.fields:
        for component_config in getattr(hal_config, field.name):
            _generate_xml_for_component(component_config, output_dir)
            if getattr(component_config, "default", False):
                # Generate a default fallback file (e.g.
                # fingerprint_default.xml) in addition to the <id>.xml file.
                # The runtime will fallback to this default if it doesn't find
                # file for the specific id.
                _generate_xml_for_component(
                    component_config, output_dir, default=True
                )
