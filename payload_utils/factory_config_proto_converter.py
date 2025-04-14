#!/usr/bin/env vpython3
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Transforms config from /config/proto/api proto format to factory JSON."""

import argparse
import json
import os
import re
import sys

from chromiumos.config.api import design_pb2
from chromiumos.config.api import topology_pb2
from chromiumos.config.payload import config_bundle_pb2
from google.protobuf import json_format


_DESGIN_CONFIG_ID_RE = re.compile(r"^(\S+):(\d+)$")


def ParseArgs(argv):
    """Parse the available arguments.

    Invalid arguments or -h cause this function to print a message and exit.

    Args:
        argv: List of string arguments (excluding program name / argv[0])

    Returns:
        argparse.Namespace object containing the attributes.
    """
    parser = argparse.ArgumentParser(
        description="Converts source proto config into factory JSON config."
    )
    parser.add_argument(
        "-c",
        "--project_configs",
        nargs="+",
        type=str,
        default=[],
        help="Space delimited list of source protobinary project config files.",
    )
    parser.add_argument(
        "-p",
        "--program_config",
        required=True,
        type=str,
        help="Path to the source program-level protobinary file",
    )
    parser.add_argument(
        "-o", "--output", type=str, help="Output file that will be generated"
    )
    return parser.parse_args(argv)


def WriteOutput(configs, output=None):
    """Writes a list of configs to factory JSON format.

    Args:
        configs: List of config dicts
        output: Target file output (if None, prints to stdout)
    """
    json_output = json.dumps(
        configs, sort_keys=True, indent=2, separators=(",", ": ")
    )
    if output:
        with open(output, "w") as output_stream:
            # Using print function adds proper trailing newline.
            print(json_output, file=output_stream)
    else:
        print(json_output)


def GetFeatures(topology, component, keys=None):
    topology_info = getattr(topology, component)
    if topology_info.type == 0:
        # This topology is not defined.
        return None
    if keys:
        features = topology_info.hardware_feature
        for key in keys:
            features = getattr(features, key)
        return features
    else:
        # Indicate that the component presents.
        return True


def CastPresent(value):
    if value == topology_pb2.HardwareFeatures.PRESENT:
        return True
    if value == topology_pb2.HardwareFeatures.NOT_PRESENT:
        return False
    return None


def GetAudioEnumName(
    audio_enum: topology_pb2.HardwareFeatures.Audio, numeric_value: int
) -> str:
    """Get name from last underscore."""
    name = audio_enum.Name(numeric_value)
    if numeric_value != 0:
        # skip for unknown type
        _, _, name = name.rpartition("_")
    return name


def CastAmplifier(value):
    if value is None:
        return None
    return GetAudioEnumName(
        topology_pb2.HardwareFeatures.Audio.Amplifier, value
    )


def CastAudioCodec(value):
    if value is None:
        return None
    return GetAudioEnumName(
        topology_pb2.HardwareFeatures.Audio.AudioCodec, value
    )


def CastConvertible(value):
    if value is None:
        return None
    return value == topology_pb2.HardwareFeatures.FormFactor.CONVERTIBLE


def _GetModelNameForDesignId(design_id):
    if design_id.HasField("model_name_design_id_override"):
        return design_id.model_name_design_id_override.value
    return design_id.value


def TransformDesignTable(design_config, design_table):
    """Transforms config proto to model_sku."""
    # TODO(cyueh): Find out how to get all component.has_* and
    # component.match_sku_components from design_config.
    #
    # The list of missing component.has_*:
    # has_lid_lightsensor, has_base_lightsensor, has_camera_lightsensor
    camera_pb = topology_pb2.HardwareFeatures.Camera
    features = design_config.hardware_features
    topology = design_config.hardware_topology
    design_table.update(
        {
            "fw_config": features.fw_config.value,
            "component.has_touchscreen": CastPresent(
                features.screen.touch_support
            ),
            "component.has_daughter_board_usb_a": GetFeatures(
                topology, "daughter_board", ["usb_a", "count", "value"]
            ),
            "component.has_daughter_board_usb_c": GetFeatures(
                topology, "daughter_board", ["usb_c", "count", "value"]
            ),
            "component.has_mother_board_usb_a": GetFeatures(
                topology, "motherboard_usb", ["usb_a", "count", "value"]
            ),
            "component.has_mother_board_usb_c": GetFeatures(
                topology, "motherboard_usb", ["usb_c", "count", "value"]
            ),
            "component.has_front_camera": (
                any(
                    (
                        d.facing == camera_pb.FACING_FRONT
                        for d in features.camera.devices
                    )
                )
                if len(features.camera.devices) > 0
                else None
            ),
            "component.has_rear_camera": (
                any(
                    (
                        d.facing == camera_pb.FACING_BACK
                        for d in features.camera.devices
                    )
                )
                if len(features.camera.devices) > 0
                else None
            ),
            "component.has_stylus": GetFeatures(
                topology, "stylus", ["stylus", "stylus"]
            )
            in [
                topology_pb2.HardwareFeatures.Stylus.INTERNAL,
                topology_pb2.HardwareFeatures.Stylus.EXTERNAL,
            ],
            "component.has_fingerprint": GetFeatures(
                topology, "fingerprint", ["fingerprint", "present"]
            ),
            "component.fingerprint_board": GetFeatures(
                topology, "fingerprint", ["fingerprint", "board"]
            ),
            "component.has_keyboard_backlight": CastPresent(
                GetFeatures(topology, "keyboard", ["keyboard", "backlight"])
            ),
            "component.has_proximity_sensor": GetFeatures(
                topology, "proximity_sensor"
            ),
            "component.speaker_amp": CastAmplifier(
                GetFeatures(topology, "audio", ["audio", "speaker_amp"])
            ),
            "component.headphone_codec": CastAudioCodec(
                GetFeatures(topology, "audio", ["audio", "headphone_codec"])
            ),
            "component.has_sd_reader": GetFeatures(topology, "sd_reader"),
            "component.has_lid_accelerometer": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["accelerometer", "lid_accelerometer"],
                )
            ),
            "component.has_base_accelerometer": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["accelerometer", "base_accelerometer"],
                )
            ),
            "component.has_lid_gyroscope": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["gyroscope", "lid_gyroscope"],
                )
            ),
            "component.has_base_gyroscope": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["gyroscope", "base_gyroscope"],
                )
            ),
            "component.has_lid_magnetometer": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["magnetometer", "lid_magnetometer"],
                )
            ),
            "component.has_base_magnetometer": CastPresent(
                GetFeatures(
                    topology,
                    "accelerometer_gyroscope_magnetometer",
                    ["magnetometer", "base_magnetometer"],
                )
            ),
            "component.has_wifi": GetFeatures(topology, "wifi"),
            "component.has_lte": CastPresent(features.cellular.present),
            "component.has_tabletmode": CastConvertible(
                GetFeatures(
                    topology, "form_factor", ["form_factor", "form_factor"]
                )
            ),
        }
    )
    if features.audio.card_configs:
        audio_card_name = features.audio.card_configs[0].card_name.partition(
            "."
        )[0]
        design_table.update({"component.audio_card_name": audio_card_name})
    design_table.update(
        {
            "component.match_sku_components": [
                ["camera", "==", len(features.camera.devices)],
                [
                    "touchscreen",
                    "==",
                    1 if design_table["component.has_touchscreen"] else 0,
                ],
                [
                    "usb_host",
                    "==",
                    features.usb_a.count.value + features.usb_c.count.value,
                ],
                [
                    "stylus",
                    "==",
                    1 if design_table["component.has_stylus"] else 0,
                ],
            ]
        }
    )
    if CastPresent(
        GetFeatures(topology, "keyboard", ["keyboard", "numeric_pad"])
    ):
        design_table.update(
            {
                "component.has_numeric_pad": True,
            }
        )
    if CastPresent(GetFeatures(topology, "hps", ["hps", "present"])):
        design_table.update({"component.has_hps": True})
    if CastPresent(GetFeatures(topology, "poe", ["poe", "present"])):
        design_table.update({"component.has_poe_peripheral_support": True})


def CreateCommonTable(design_table):
    """Extract elements which are the same among a design."""
    if not design_table:
        return {}
    design_table_list = list(design_table.values())
    common_table = dict(design_table_list[0])
    for config in design_table_list[1:]:
        # keep only keys that are in all configs
        # where the values are the same in all configs
        common_table = {
            key: value
            for key, value in config.items()
            if key in common_table and value == common_table[key]
        }
    # delete the common keys from all configs
    for config in design_table.values():
        for key in common_table:
            del config[key]
    return common_table


def ParseDesignConfigId(value):
    match = _DESGIN_CONFIG_ID_RE.match(value)
    if not match:
        return (None, None)
    return (match.group(1), int(match.group(2)))


def GetFactoryConfigs(config):
    """Writes factory conf files for every design config id.

    Args:
        config: Source ConfigBundle to process.

    Returns:
        dict that maps the design id onto the factory test config.
    """
    product_sku = {}
    oem_name = {}
    partners = {x.id.value: x for x in config.partner_list}
    brand_configs = {x.brand_id.value: x for x in config.brand_configs}
    design_name_to_testing_design_name = {}

    # Enumerate designs.
    for hw_design in config.design_list:
        design_name = hw_design.id.value
        testing_design_name = _GetModelNameForDesignId(hw_design.id)
        design_name_to_testing_design_name[design_name] = testing_design_name
        design_table = product_sku.setdefault(testing_design_name, {})
        custom_type = hw_design.custom_type
        # Convert spi_flash_transform proto map in json map
        spi_flash_transform = dict(hw_design.spi_flash_transform)
        # Enumerate design config id (sku id).
        for design_config in hw_design.configs:
            second_design_name, sku_id = ParseDesignConfigId(
                design_config.id.value
            )
            if design_name != second_design_name:
                continue
            design_config_table = design_table.setdefault(sku_id, {})
            TransformDesignTable(design_config, design_config_table)
            if custom_type == design_pb2.Design.CustomType.WHITELABEL:
                design_config_table.update({"custom_type": "whitelabel"})
            elif custom_type == design_pb2.Design.CustomType.REBRAND:
                design_config_table.update({"custom_type": "rebrand"})
            # Add spi_flash_transform from project/design level to each config
            # so it can be pulled out as common later. Omit if empty
            if spi_flash_transform:
                design_config_table.update(
                    {"spi_flash_transform": spi_flash_transform}
                )
    # Create map from custom label to oem name.
    if config.device_brand_list:
        for device_brand in config.device_brand_list:
            device_brand_id = device_brand.id.value
            # Design names should be lowercase, to be consistent with `model`.
            design_name = _GetModelNameForDesignId(
                device_brand.design_id
            ).lower()
            design_oem_name_table = oem_name.setdefault(design_name, {})
            if not partners.get(device_brand.oem_id.value):
                print(
                    "OEM %r for the device_brand %r is not found in "
                    "partner_list %r."
                    % (
                        device_brand.oem_id.value,
                        device_brand_id,
                        list(partners.keys()),
                    ),
                    file=sys.stderr,
                )
                continue
            key = ""
            value = partners[device_brand.oem_id.value].name
            brand_config = brand_configs.get(device_brand_id)
            if brand_config and brand_config.scan_config:
                custom_label_tag = (
                    brand_config.scan_config.whitelabel_tag
                    or brand_config.scan_config.custom_label_tag
                )
                key = custom_label_tag
            design_oem_name_table.setdefault(key, value)
    # Enumerate (design, sku id).
    for sw_design in config.software_configs:
        design_name, sku_id = ParseDesignConfigId(
            sw_design.design_config_id.value
        )
        if design_name is None:
            continue
        design_table = product_sku.setdefault(
            design_name_to_testing_design_name.get(design_name, design_name)
        )
        design_config_table = design_table.setdefault(sku_id, {})
        if "component.audio_card_name" not in design_config_table:
            audio_card_name = ""
            if sw_design.audio_configs:
                audio_card_name = sw_design.audio_configs[0].card_name
            design_config_table.update(
                {"component.audio_card_name": audio_card_name}
            )
    # Create common table.
    model = {}
    new_product_sku = {}
    for design_name, design_table in product_sku.items():
        if not design_table:
            # A design is defined but without a design id under it. Skip it.
            continue
        model[design_name.lower()] = CreateCommonTable(design_table)
        for sku_id, content in design_table.items():
            product_name = design_name.lower()
            product_name_table = new_product_sku.setdefault(product_name, {})
            if sku_id in product_name_table:
                print(
                    "The sku_id %s duplicates in product name %s"
                    % (sku_id, product_name),
                    file=sys.stderr,
                )
            else:
                product_name_table[sku_id] = content
    return {
        "model": model,
        "oem_name": oem_name,
        "product_sku": new_product_sku,
    }


def _ReadConfig(path):
    """Reads a ConfigBundle proto from a json pb file.

    Args:
        path: Path to the file encoding the json pb proto.
    """
    config = config_bundle_pb2.ConfigBundle()
    with open(path, "r") as f:
        return json_format.Parse(f.read(), config)


def _MergeConfigs(configs):
    result = config_bundle_pb2.ConfigBundle()
    for config in configs:
        result.MergeFrom(config)

    return result


def Main(project_configs, program_config, output):
    """Transforms source proto config into factory JSON.

    Args:
        project_configs: List of source project configs to transform.
        program_config: Program config for the given set of projects.
        output: Output file that will be generated by the transform.
    """
    # Abort if the write will fail.
    if output is not None:
        output_dir = os.path.dirname(output)
        if not os.path.isdir(output_dir):
            raise FileNotFoundError("No such directory: %s" % output_dir)

    configs = _MergeConfigs(
        [_ReadConfig(program_config)]
        + [_ReadConfig(config) for config in project_configs]
    )
    WriteOutput(GetFactoryConfigs(configs), output)


def main(argv=None):
    """Main program which parses args and runs

    Args:
        argv: List of command line arguments, if None uses sys.argv.
    """
    if argv is None:
        argv = sys.argv[1:]
    opts = ParseArgs(argv)
    Main(opts.project_configs, opts.program_config, opts.output)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
