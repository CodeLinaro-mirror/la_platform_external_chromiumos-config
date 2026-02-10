# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates individual component XML files from a ConfigBundle."""

import logging
import pathlib

from chromiumos.config.payload import config_bundle_pb2
from lxml import etree  # pylint: disable=import-error


def _generate_xml_for_component(component_config, output_dir: pathlib.Path):
    """Generates an XML file for a single component configuration.

    Args:
        component_config: A protobuf message for a single component in
           a HalConfiguration message (e.g., AudioConfigurationType).
        output_dir: The directory to write the XML file to.
    """
    descriptor = component_config.DESCRIPTOR

    root_element_name = descriptor.name.removesuffix("Type")
    root = etree.Element(root_element_name)

    component_id = component_config.id
    for field in descriptor.fields:
        # The 'id' field is used for the filename and isn't part of the XML
        # content.
        if field.name == "id":
            continue

        value = getattr(component_config, field.name)

        # Skip default or empty fields.
        if field.label == field.LABEL_REPEATED:
            if not value:
                logging.debug(
                    "Repeated field %s is empty, skipping.", field.name
                )
                continue
        elif field.type == field.TYPE_MESSAGE:
            if not component_config.HasField(field.name):
                logging.debug(
                    "Message field %s is not set, skipping.", field.name
                )
                continue
        elif value == field.default_value:
            logging.debug("Field %s is default, skipping.", field.name)
            continue

        element_name = field.name.replace("_", "-")
        elem = etree.SubElement(root, element_name)
        # TODO(b/449551444): Add a unit test for enums once there are actually
        # enums in the input proto schema.
        value = getattr(component_config, field.name)
        if field.type == field.TYPE_ENUM:
            elem.text = field.enum_type.values_by_number[value].name
        else:
            elem.text = str(value)

    if not component_id:
        logging.warning(
            "Component config is missing an 'id' field, skipping: %s",
            component_config,
        )
        return

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
