# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates Android feature XML files from a ConfigBundle."""

import logging
import pathlib

from chromiumos.config.api import android_component_configs_pb2
from lxml import etree  # pylint: disable=import-error


def _add_feature_element(
    permissions_element: etree._Element, feature_name: str
):
    """Adds a <feature> element to the given <permissions> element.

    Args:
        permissions_element: The parent <permissions> XML element.
        feature_name: The string name of the feature
            (e.g., "android.hardware.fingerprint").
    """
    feature_elem = etree.SubElement(permissions_element, "feature")
    feature_elem.set("name", feature_name)
    logging.debug("Added feature '%s' to XML tree.", feature_name)


def _generate_xml_for_fingerprint(
    _component_config: android_component_configs_pb2.FingerprintConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for FingerprintConfiguration.

    Args:
        component_config: The FingerprintConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    _add_feature_element(permissions_elem, "android.hardware.fingerprint")


def _generate_xml_for_camera(
    component_config: android_component_configs_pb2.CameraConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for CameraConfiguration.

    Args:
        component_config: The CameraConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    has_back_camera = False
    has_front_camera = False
    has_autofocus = False

    for camera in component_config.cameras:
        if (
            camera.position
            == android_component_configs_pb2.CameraConfigurationType.FACING_BACK
        ):
            has_back_camera = True
        if (
            camera.position
            == android_component_configs_pb2.CameraConfigurationType.FACING_FRONT
        ):
            has_front_camera = True
        if (
            camera.autofocus_support
            == android_component_configs_pb2.HalConfiguration.PRESENT
        ):
            has_autofocus = True

    if has_back_camera or has_front_camera:
        _add_feature_element(permissions_elem, "android.hardware.camera.any")

    if has_back_camera:
        _add_feature_element(permissions_elem, "android.hardware.camera")

    if has_front_camera:
        _add_feature_element(permissions_elem, "android.hardware.camera.front")

    if has_autofocus:
        _add_feature_element(
            permissions_elem, "android.hardware.camera.autofocus"
        )


def _generate_xml_for_hardware_feature(
    component_config: android_component_configs_pb2.HardwareFeaturesConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for HardwareFeaturesConfiguration.

    Args:
        component_config: The HardwareFeaturesConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    if component_config.form_factor == "CONVERTIBLE":
        _add_feature_element(
            permissions_elem, "android.hardware.sensor.hinge_angle"
        )

    if component_config.touchscreen_support == "true":
        _add_feature_element(permissions_elem, "android.hardware.touchscreen")
        _add_feature_element(
            permissions_elem, "android.hardware.touchscreen.multitouch"
        )


def _generate_xml_for_accelerometer(
    component_config: android_component_configs_pb2.AccelerometerConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for AccelerometerConfiguration.

    Args:
        component_config: The AccelerometerConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    if (
        component_config.feature_accelerometer
        == android_component_configs_pb2.HalConfiguration.PRESENT
    ):
        _add_feature_element(
            permissions_elem, "android.hardware.sensor.accelerometer"
        )


def _generate_xml_for_gyroscope(
    component_config: android_component_configs_pb2.GyroscopeConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for GyroscopeConfiguration.

    Args:
        component_config: The GyroscopeConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    if (
        component_config.feature_gyroscope
        == android_component_configs_pb2.HalConfiguration.PRESENT
    ):
        _add_feature_element(
            permissions_elem, "android.hardware.sensor.gyroscope"
        )


def _generate_xml_for_lightsensor(
    component_config: android_component_configs_pb2.LightSensorConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for LightSensorConfiguration.

    Args:
        component_config: The LightSensorConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    if (
        component_config.feature_lightsensor
        == android_component_configs_pb2.HalConfiguration.PRESENT
    ):
        _add_feature_element(permissions_elem, "android.hardware.sensor.light")


def _generate_xml_for_magnetometer(
    component_config: android_component_configs_pb2.MagnetometerConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for MagnetometerConfiguration.

    Args:
        component_config: The MagnetometerConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    if (
        component_config.feature_magnetometer
        == android_component_configs_pb2.HalConfiguration.PRESENT
    ):
        _add_feature_element(
            permissions_elem, "android.hardware.sensor.compass"
        )


def _generate_xml_for_proximity(
    component_config: android_component_configs_pb2.ProximityConfigurationType,
    permissions_elem: etree._Element,
):
    """Generates feature XML content for ProximityConfiguration.

    Args:
        component_config: The ProximityConfigurationType proto.
        permissions_elem: The parent permissions element.
    """
    _add_feature_element(permissions_elem, "android.hardware.sensor.proximity")

    if component_config.HasField(
        "semtech_proximity"
    ) and component_config.semtech_proximity.HasField("semtech_config"):
        _add_feature_element(permissions_elem, "com.google.sensor.sar")


_COMPONENT_HANDLERS = {
    "CameraConfiguration": _generate_xml_for_camera,
    "FingerprintConfiguration": _generate_xml_for_fingerprint,
    "HardwareFeaturesConfiguration": _generate_xml_for_hardware_feature,
    "AccelerometerConfiguration": _generate_xml_for_accelerometer,
    "GyroscopeConfiguration": _generate_xml_for_gyroscope,
    "LightSensorConfiguration": _generate_xml_for_lightsensor,
    "MagnetometerConfiguration": _generate_xml_for_magnetometer,
    "ProximityConfiguration": _generate_xml_for_proximity,
}


def _generate_xml_for_component(component_config, output_dir: pathlib.Path):
    """Generates an XML file for a single component configuration.

    Args:
        component_config: A protobuf message for a single component in
           a HalConfiguration message (e.g., FingerprintConfiguration).
        output_dir: The directory to write the XML file to.
    """
    descriptor = component_config.DESCRIPTOR
    component_type = descriptor.name.removesuffix("Type")

    handler = _COMPONENT_HANDLERS.get(component_type)
    if not handler:
        logging.debug(
            "No feature handler for component type: %s", component_type
        )
        return

    component_id = component_config.id
    if not component_id:
        logging.warning(
            "Component config is missing an 'id' field, skipping: %s",
            component_config,
        )
        return

    root = etree.Element("permissions")
    handler(component_config, root)

    # File naming convention: <ComponentID>.xml
    output_file = output_dir / f"{component_id}.xml"

    with open(output_file, "wb") as f:
        f.write(etree.tostring(root, pretty_print=True, xml_declaration=False))
    logging.info("Wrote feature XML to %s", output_file)


def generate_from_hal_config(
    hal_config: android_component_configs_pb2.HalConfiguration,
    output_dir: pathlib.Path,
):
    """Generates feature XML files from a HalConfiguration.

    Args:
        hal_config: The HalConfiguration protobuf object.
        output_dir: The directory to write the XML files to.
    """
    logging.info("Generating Android feature XML files...")
    output_dir.mkdir(parents=True, exist_ok=True)

    for field in hal_config.DESCRIPTOR.fields:
        for component_config in getattr(hal_config, field.name):
            _generate_xml_for_component(component_config, output_dir)
