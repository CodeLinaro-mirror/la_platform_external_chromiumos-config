#!/usr/bin/env vpython3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Converts a ConfigBundle JSON file to Android configs.

Reads a single JSON file representing a chromiumos.config.payload.ConfigBundle
message and generates corresponding Android configs, such as HAL XML files
and feature XML files.
"""

# pylint: disable=too-many-lines

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
import struct
import sys
from typing import Optional

from cros_to_android_subcommands import generate_component_xmls
from cros_to_android_subcommands import generate_feature_xml
from google.protobuf import json_format  # pylint: disable=import-error
from lxml import etree  # pylint: disable=import-error


# TODO(b/402027869): Figure out a better way to distribute this proto with the
# script.
try:
    from chromiumos.config.api import android_component_configs_pb2
    from chromiumos.config.api import component_pb2
    from chromiumos.config.api import design_config_id_pb2
    from chromiumos.config.api import design_pb2
    from chromiumos.config.api import proximity_config_pb2
    from chromiumos.config.api import topology_pb2
    from chromiumos.config.api.software import camera_config_pb2
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
    return "_".join(sorted(fw_config.coreboot_customizations))


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


def _gen_camcorder_profiles(camera_id, resolutions):
    elem = etree.Element(
        "CamcorderProfiles", attrib={"cameraId": str(camera_id)}
    )
    for resolution in resolutions:
        elem.extend(
            [
                _gen_encoder_profile(resolution, False),
                _gen_encoder_profile(resolution, True),
            ]
        )
    elem.extend(
        [
            etree.Element("ImageEncoding", attrib={"quality": "90"}),
            etree.Element("ImageEncoding", attrib={"quality": "80"}),
            etree.Element("ImageEncoding", attrib={"quality": "70"}),
            etree.Element("ImageDecoding", attrib={"memCap": "20000000"}),
        ]
    )
    return elem


def _gen_encoder_profile(resolution, timelapse):
    # Default bitrates based on resolution
    default_bitrates = {
        (640, 480): 3000000,  # 3 Mbps for 480p
        (1280, 720): 8000000,  # 8 Mbps for 720p
        (1920, 1080): 12000000,  # 12 Mbps for 1080p
        (2560, 1440): 24000000,  # 24 Mbps for 2160p, ref b/514199715
        (3840, 2160): 42000000,  # 42 Mbps for 2160p, ref b/493987913
    }
    width = resolution.width
    height = resolution.height
    bitrate = (
        resolution.bitrate
        if resolution.bitrate
        else default_bitrates.get((width, height), 8000000)
    )

    quality = "qhd" if height == 1440 else str(height) + "p"
    elem = etree.Element(
        "EncoderProfile",
        attrib={
            "quality": ("timelapse" if timelapse else "") + quality,
            "fileFormat": "mp4",
            "duration": "60",
        },
    )
    elem.append(
        etree.Element(
            "Video",
            attrib={
                "codec": "h264",
                "bitRate": str(bitrate),
                "width": str(width),
                "height": str(height),
                "frameRate": "30",
            },
        )
    )
    elem.append(
        etree.Element(
            "Audio",
            attrib={
                "codec": "aac",
                "bitRate": "96000",
                "sampleRate": "44100",
                "channels": "1",
            },
        )
    )
    return elem


def _gen_video_encoder_cap(
    name,
    min_bit_rate,
    max_bit_rate,
    max_frame_width=1920,
    max_frame_height=1080,
):
    return etree.Element(
        "VideoEncoderCap",
        attrib={
            "name": name,
            "enabled": "true",
            "minBitRate": str(min_bit_rate),
            "maxBitRate": str(max_bit_rate),
            "minFrameWidth": "320",
            "maxFrameWidth": str(max_frame_width),
            "minFrameHeight": "240",
            "maxFrameHeight": str(max_frame_height),
            "minFrameRate": "15",
            "maxFrameRate": "30",
        },
    )


def _gen_audio_encoder_cap(
    name, min_bit_rate, max_bit_rate, min_sample_rate, max_sample_rate
):
    return etree.Element(
        "AudioEncoderCap",
        attrib={
            "name": name,
            "enabled": "true",
            "minBitRate": str(min_bit_rate),
            "maxBitRate": str(max_bit_rate),
            "minSampleRate": str(min_sample_rate),
            "maxSampleRate": str(max_sample_rate),
            "minChannels": "1",
            "maxChannels": "1",
        },
    )


def _generate_media_profiles_xml_string(
    hw_features: topology_pb2.HardwareFeatures,
    sw_config: software_config_pb2.SoftwareConfig,
    dtd_path: Optional[pathlib.Path],
) -> Optional[bytes]:
    """Generates ARC media_profiles.xml file content as a string.

    Similar to _generate_arc_media_profiles in cros_config_proto_converter.py,
    but with dtd_path optional.

    Args:
        hw_features: HardwareFeatures proto message.
        sw_config: SoftwareConfig proto message.
        dtd_path: Full path to media_profiles.dtd file. If None, DTD
          validation is skipped.

    Returns:
        Bytes of the media_profiles.xml content, or None if generation is
        disabled or no camera devices are present.
    """
    camera_config = sw_config.camera_config
    if not camera_config.generate_media_profiles:
        return None

    camera_pb = topology_pb2.HardwareFeatures.Camera
    root = etree.Element("MediaSettings")
    camera_id = 0
    for facing in [camera_pb.FACING_FRONT, camera_pb.FACING_BACK]:
        camera_device = next(
            (
                d
                for d in hw_features.camera.devices
                if not d.detachable and d.facing == facing
            ),
            None,
        )
        if camera_device is None:
            continue
        if camera_config.camcorder_resolutions:
            resolutions = camera_config.camcorder_resolutions
        else:
            resolution = camera_config_pb2.Resolution()
            resolution.width = 1280
            resolution.height = 720
            resolutions = [resolution]
            if camera_device.flags & camera_pb.FLAGS_SUPPORT_1080P:
                resolution_1080p = camera_config_pb2.Resolution()
                resolution_1080p.width = 1920
                resolution_1080p.height = 1080
                resolutions.append(resolution_1080p)
        root.append(_gen_camcorder_profiles(camera_id, resolutions))
        camera_id += 1
    # media_profiles.xml should have at least one CamcorderProfiles.
    if camera_id == 0:
        return None

    root.extend(
        [
            etree.Element("EncoderOutputFileFormat", attrib={"name": "3gp"}),
            etree.Element("EncoderOutputFileFormat", attrib={"name": "mp4"}),
            _gen_video_encoder_cap("h264", 64000, 17000000),
            _gen_video_encoder_cap("h263", 64000, 1000000),
            _gen_video_encoder_cap("m4v", 64000, 2000000),
            _gen_audio_encoder_cap("aac", 758, 288000, 8000, 48000),
            _gen_audio_encoder_cap("heaac", 8000, 64000, 16000, 48000),
            _gen_audio_encoder_cap("aaceld", 16000, 192000, 16000, 48000),
            _gen_audio_encoder_cap("amrwb", 6600, 23050, 16000, 16000),
            _gen_audio_encoder_cap("amrnb", 5525, 12200, 8000, 8000),
            etree.Element(
                "VideoDecoderCap", attrib={"name": "wmv", "enabled": "false"}
            ),
            etree.Element(
                "AudioDecoderCap", attrib={"name": "wma", "enabled": "false"}
            ),
        ]
    )

    xml_content = etree.tostring(root, pretty_print=True)

    # Validate against DTD if dtd_path is provided
    if dtd_path:
        dtd = etree.DTD(str(dtd_path))
        if not dtd.validate(root):
            raise etree.DTDValidateError(
                f"Invalid media_profiles.xml generated:\n{dtd.error_log}"
            )
        logging.info("Media profile XML DTD validation successful.")
    else:
        logging.info("DTD schema not provided, skipping validation.")

    return xml_content


def _generate_media_profiles_from_camera_config(
    # pylint: disable=too-many-locals
    # pylint: disable=too-many-branches
    # pylint: disable=too-many-statements
    camera_config: android_component_configs_pb2.CameraConfigurationType,
    dtd_path: Optional[pathlib.Path],
) -> Optional[bytes]:
    """Generates media profiles XML from a CameraConfigurationType.

    Args:
        camera_config: The CameraConfigurationType protobuf object.
        dtd_path: Path to the media_profiles.dtd file for validation.

    Returns:
        Bytes of the media_profiles.xml content, or None if generation is
        unable to proceed (e.g. no cameras).
    """
    root = etree.Element("MediaSettings")
    camera_id = 0

    has_p4k_cam = False
    # Order by position, front then back.
    position_to_camera = {cam.position: cam for cam in camera_config.cameras}
    for position in [
        android_component_configs_pb2.CameraConfigurationType.FACING_FRONT,
        android_component_configs_pb2.CameraConfigurationType.FACING_BACK,
    ]:
        cam = position_to_camera.get(position)
        if not cam:
            continue

        if cam.resolutions:
            resolutions = []
            for res in cam.resolutions:
                if not (res.resolutionx and res.resolutiony):
                    raise ValueError(
                        f"Camera {cam} has invalid resolution in 'resolutions' "
                        "list. Both resolutionx and resolutiony must be set."
                    )
                resolution = camera_config_pb2.Resolution()
                resolution.width = res.resolutionx
                resolution.height = res.resolutiony
                resolutions.append(resolution)
        else:
            logging.info(
                "Camera %s has no resolutions in 'resolutions' list. "
                "Defaulting to 1280x720.",
                cam,
            )
            resolution = camera_config_pb2.Resolution()
            resolution.width = 1280
            resolution.height = 720
            resolutions = [resolution]

            if (
                cam.p1080_support
                == android_component_configs_pb2.HalConfiguration.PRESENT
            ):
                logging.info(
                    "Camera %s has 1080p support, adding 1920x1080 resolution.",
                    cam,
                )
                resolution_1080p = camera_config_pb2.Resolution()
                resolution_1080p.width = 1920
                resolution_1080p.height = 1080
                resolutions.append(resolution_1080p)

            if (
                cam.p1440_support
                == android_component_configs_pb2.HalConfiguration.PRESENT
            ):
                logging.info(
                    "Camera %s has 1440p support, adding 2560x144 resolution.",
                    cam,
                )
                resolution_1440p = camera_config_pb2.Resolution()
                resolution_1440p.width = 2560
                resolution_1440p.height = 1440
                resolutions.append(resolution_1440p)

            if (
                cam.p4k_support
                == android_component_configs_pb2.HalConfiguration.PRESENT
            ):
                logging.info(
                    "Camera %s has 2160p support, adding 3840x2160 resolution.",
                    cam,
                )
                resolution_p4k = camera_config_pb2.Resolution()
                resolution_p4k.width = 3840
                resolution_p4k.height = 2160
                resolutions.append(resolution_p4k)
                has_p4k_cam = True

        root.append(_gen_camcorder_profiles(camera_id, resolutions))
        camera_id += 1

    if camera_id == 0:
        return None

    (max_bit_rate, max_frame_width, max_frame_height) = (
        (100000000, 3840, 2160) if has_p4k_cam else (17000000, 1920, 1080)
    )

    root.extend(
        [
            etree.Element("EncoderOutputFileFormat", attrib={"name": "3gp"}),
            etree.Element("EncoderOutputFileFormat", attrib={"name": "mp4"}),
            _gen_video_encoder_cap(
                "h264", 64000, max_bit_rate, max_frame_width, max_frame_height
            ),
            _gen_video_encoder_cap("h263", 64000, 1000000),
            _gen_video_encoder_cap("m4v", 64000, 2000000),
            _gen_audio_encoder_cap("aac", 758, 288000, 8000, 48000),
            _gen_audio_encoder_cap("heaac", 8000, 64000, 16000, 48000),
            _gen_audio_encoder_cap("aaceld", 16000, 192000, 16000, 48000),
            _gen_audio_encoder_cap("amrwb", 6600, 23050, 16000, 16000),
            _gen_audio_encoder_cap("amrnb", 5525, 12200, 8000, 8000),
            etree.Element(
                "VideoDecoderCap", attrib={"name": "wmv", "enabled": "false"}
            ),
            etree.Element(
                "AudioDecoderCap", attrib={"name": "wma", "enabled": "false"}
            ),
        ]
    )

    xml_content = etree.tostring(root, pretty_print=True)

    # Validate against DTD if dtd_path is provided
    if dtd_path:
        dtd = etree.DTD(str(dtd_path))
        if not dtd.validate(root):
            raise etree.DTDValidateError(
                f"Invalid media_profiles.xml generated:\n{dtd.error_log}"
            )
        logging.info("Media profile XML DTD validation successful.")
    else:
        logging.info("DTD schema not provided, skipping validation.")

    return xml_content


def _generate_media_profiles_from_hal_config(
    hal_config: android_component_configs_pb2.HalConfiguration,
    output_dir: pathlib.Path,
    dtd_path: Optional[pathlib.Path],
) -> None:
    """Generates media profiles from HalConfiguration.

    Args:
        hal_config: The HalConfiguration protobuf object.
        output_dir: The directory to write the XML files to.
        dtd_path: Path to the media_profiles.dtd file for validation.
    """
    logging.info(
        "Generating Android media profile XML files from HAL config..."
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    for camera_config in hal_config.camera_list:
        xml_content = _generate_media_profiles_from_camera_config(
            camera_config, dtd_path
        )
        if not xml_content:
            logging.info(
                "Skipping media profile for camera config %s",
                camera_config.id,
            )
            continue

        output_file = output_dir / f"media_profiles_{camera_config.id}.xml"
        with open(output_file, "wb") as f:
            f.write(xml_content)
        logging.info(
            "Wrote media profile XML to %s",
            output_file,
        )


def run_generate_media_profiles(opts: argparse.Namespace) -> None:
    """Handles the 'generate-media-profiles' sub-command logic."""
    logging.info("Running generate-media-profiles command...")
    config_bundle = _load_config_bundle(opts.jsonproto_file)

    if opts.from_hal_config:
        _generate_media_profiles_from_hal_config(
            config_bundle.android_hal_config, opts.output_dir, opts.dtd_schema
        )
        return

    for design in config_bundle.design_list:
        for design_config in design.configs:
            model, sku = design_config.id.value.split(":")
            sw_config = _get_sw_config(
                config_bundle.software_configs, design_config.id.value
            )

            xml_content = _generate_media_profiles_xml_string(
                design_config.hardware_features,
                sw_config,
                opts.dtd_schema,
            )
            if not xml_content:
                logging.info(
                    "Skipping media profile for %s:%s as generation was"
                    " disabled or no relevant cameras found.",
                    model,
                    sku,
                )
                continue

            sku_dir = opts.output_dir / f"{model}_{sku}".lower()
            sku_dir.mkdir(parents=True, exist_ok=True)
            output_file = sku_dir / f"media_profiles_{model}_{sku}.xml".lower()
            with open(output_file, "wb") as f:
                f.write(xml_content)
            logging.info(
                "Wrote media profile XML for %s:%s to %s",
                model,
                sku,
                output_file,
            )


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

    if modem_type_enum_str == "MODEM_L850":
        logging.warning("ModemType MODEM_L850 is not supported, skipping.")
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

    # TODO (b/453601065) add back fp_features.board checking when 'board'
    # value for USB FPMCU is ready

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
    if fp_features.board:
        etree.SubElement(fp_config_elem, "board").text = fp_features.board
    etree.SubElement(fp_config_elem, "fingerprint-sensor-type").text = (
        sensor_type_xsd_str
    )
    if fp_features.ro_version:
        etree.SubElement(fp_config_elem, "ro-version").text = (
            fp_features.ro_version
        )
    etree.SubElement(fp_config_elem, "sensor-location").text = location_enum_str


def _get_ufsc_hex_value(
    sw_config: software_config_pb2.SoftwareConfig,
) -> Optional[str]:
    """Packs the Unified Firmware Signing Configuration into a hex string.

    The value is a list of up to 4 dwords, which are padded with zeros,
    packed as little-endian unsigned integers, and concatenated into a hex string.

    Args:
        sw_config: The software config containing the UFSC value.

    Returns:
        The packed hex string, or None if no value is present.
    """
    if not sw_config.unified_fw_config.value:
        return None

    source_dwords = list(sw_config.unified_fw_config.value)
    dwords_to_process = (source_dwords + [0, 0, 0, 0])[:4]
    ufsc_hex_values = [
        struct.pack("<I", int(dword)).hex() for dword in dwords_to_process
    ]
    return "".join(ufsc_hex_values)


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
    firmware_config_elem = etree.SubElement(hal_config, "FirmwareConfiguration")
    fw_main_ro = sw_config.firmware.main_ro_payload
    if fw_main_ro and fw_main_ro.firmware_image_name:
        image_name = fw_main_ro.firmware_image_name.lower()
        customization_id = _get_fw_customization_id(design_config)
        if customization_id:
            image_name += f"_{customization_id}"
        fw_image_name_elem = etree.SubElement(
            firmware_config_elem, "firmware-manifest-key"
        )
        fw_image_name_elem.text = image_name
    else:
        logging.warning(
            "Firmware image name not found for Design.Config ID '%s'."
            "Skipping firmware-manifest-key",
            design_config.id.value,
        )

    boot_config = str(design_config.hardware_features.fw_config.value)
    boot_config_elem = etree.SubElement(firmware_config_elem, "firmware-config")
    boot_config_elem.text = boot_config

    ufsc_cbi_value = _get_ufsc_hex_value(sw_config)
    if ufsc_cbi_value:
        ufsc_elem = etree.SubElement(firmware_config_elem, "ufsc")
        ufsc_elem.text = ufsc_cbi_value


def _add_audio_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds AudioConfiguration to the XML tree for a Design.Config.

    Skips if the Design.Config doesn't have sufficient audio card_config data.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    audio_features = design_config.hardware_features.audio
    if (
        not audio_features.card_configs
        or not audio_features.card_configs[0].card_name
    ):
        logging.debug(
            "[%s] No valid audio card_configs found. Skipping AudioConfiguration.",
            design_config.id.value,
        )
        return

    soundcard_name = audio_features.card_configs[0].card_name

    if len(audio_features.card_configs) > 1:
        logging.warning(
            "[%s] Multiple audio card_configs found (%d). Using the first one ('%s') for HAL XML.",
            design_config.id.value,
            len(audio_features.card_configs),
            soundcard_name,
        )

    # Initialize a list to hold parts of the audio_config_dir string in format
    audio_config_fields = [soundcard_name]

    headphone_codec_name = topology_pb2.HardwareFeatures.Audio.AudioCodec.Name(
        audio_features.headphone_codec
    )
    if headphone_codec_name != "AUDIO_CODEC_UNKNOWN":
        _, _, codec_str = headphone_codec_name.lower().rpartition("_")
        if codec_str:
            audio_config_fields.append(codec_str)

    amplifier_name = topology_pb2.HardwareFeatures.Audio.Amplifier.Name(
        audio_features.speaker_amp
    )
    if amplifier_name != "AMPLIFIER_UNKNOWN":
        _, _, ampl_str = amplifier_name.lower().rpartition("_")
        if ampl_str:
            audio_config_fields.append(ampl_str)

    lid_mic_count = (
        audio_features.lid_microphone.value
        if audio_features.HasField("lid_microphone")
        else 0
    )
    base_mic_count = (
        audio_features.base_microphone.value
        if audio_features.HasField("base_microphone")
        else 0
    )
    total_mic_count = lid_mic_count + base_mic_count

    if total_mic_count > 0:
        audio_config_fields.append(str(total_mic_count))

    # Construct the audio-config-dir string by joining the parts
    audio_config_dir_value = "_".join(audio_config_fields)
    audio_config_elem = etree.SubElement(hal_config, "AudioConfiguration")
    etree.SubElement(audio_config_elem, "audio-config-dir").text = (
        audio_config_dir_value
    )
    etree.SubElement(audio_config_elem, "soundcard").text = soundcard_name


def _add_video_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds VideoConfiguration to the XML tree for a Design.Config.

    Skips if the Design.Config doesn't have arc_media_codecs_suffix.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    soc_features = design_config.hardware_features.soc
    if not soc_features.arc_media_codecs_suffix:
        logging.debug(
            "[%s] No arc_media_codecs_suffix found. Skipping VideoConfiguration.",
            design_config.id.value,
        )
        return

    video_config_elem = etree.SubElement(hal_config, "VideoConfiguration")
    etree.SubElement(video_config_elem, "video-codec-suffix").text = (
        soc_features.arc_media_codecs_suffix
    )


def _add_hardware_features_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds HardwareFeature to the XML tree for a Design.Config.

    Skips if the Design.Config doesn't have form factor defined.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    hw_features = design_config.hardware_features
    if not hw_features.HasField("form_factor"):
        logging.debug(
            "[%s] No form_factor found. Skipping HardwareFeature.",
            design_config.id.value,
        )
        return

    form_factor = hw_features.form_factor.form_factor

    form_factor_names = {
        topology_pb2.HardwareFeatures.FormFactor.CLAMSHELL: "CLAMSHELL",
        topology_pb2.HardwareFeatures.FormFactor.CONVERTIBLE: "CONVERTIBLE",
        topology_pb2.HardwareFeatures.FormFactor.DETACHABLE: "DETACHABLE",
        topology_pb2.HardwareFeatures.FormFactor.CHROMEBASE: "CHROMEBASE",
        topology_pb2.HardwareFeatures.FormFactor.CHROMEBOX: "CHROMEBOX",
        topology_pb2.HardwareFeatures.FormFactor.CHROMEBIT: "CHROMEBIT",
        topology_pb2.HardwareFeatures.FormFactor.CHROMESLATE: "CHROMESLATE",
    }

    if form_factor in form_factor_names:
        hw_feature_elem = etree.SubElement(
            hal_config, "HardwareFeaturesConfiguration"
        )
        etree.SubElement(hw_feature_elem, "form-factor").text = (
            form_factor_names[form_factor]
        )
    else:
        logging.warning(
            "[%s] Unknown form_factor value: %s. Skipping HardwareFeature.",
            design_config.id.value,
            form_factor,
        )
        return

    if not hw_features.HasField("screen"):
        logging.debug(
            "[%s] No screen found. Skipping HardwareFeatures.Screen.",
            design_config.id.value,
        )
        return

    touch_support = "false"
    if (
        hw_features.screen.touch_support
        == topology_pb2.HardwareFeatures.PRESENT
    ):
        touch_support = "true"

    hw_feature_elem = hal_config.find("HardwareFeaturesConfiguration")
    if hw_feature_elem is not None:
        etree.SubElement(hw_feature_elem, "touchscreen-support").text = (
            touch_support
        )


def _add_camera_entry(
    # pylint: disable=too-many-arguments
    hal_config_elem: etree._Element,
    hw_features: topology_pb2.HardwareFeatures,
    sw_config: software_config_pb2.SoftwareConfig,
    model: str,
    sku: str,
) -> None:
    """Adds CameraConfiguration to the XML tree if applicable.

    This entry will point to the expected media_profiles_MODEL_SKU.xml file.

    Args:
        hal_config_elem: The parent <HalConfig> XML element.
        hw_features: HardwareFeatures proto for the design config.
        sw_config: SoftwareConfig proto for the design config.
        model: The model name.
        sku: The SKU ID.
    """

    if not sw_config.camera_config.generate_media_profiles:
        logging.debug(
            "Skipping CameraConfiguration for %s:%s: Media profile generation"
            " disabled in software config.",
            model,
            sku,
        )
        return

    non_detachable_camera_found = any(
        not d.detachable
        and d.facing
        in (
            topology_pb2.HardwareFeatures.Camera.FACING_BACK,
            topology_pb2.HardwareFeatures.Camera.FACING_FRONT,
        )
        for d in hw_features.camera.devices
    )
    if not non_detachable_camera_found:
        logging.debug(
            "Skipping CameraConfiguration for %s:%s: No non-detachable"
            " cameras found.",
            model,
            sku,
        )
        return

    media_profile_suffix = f"_{model.lower()}_{sku.lower()}"
    camera_config_elem = etree.SubElement(
        hal_config_elem, "CameraConfiguration"
    )
    etree.SubElement(camera_config_elem, "media-profile-suffix").text = (
        media_profile_suffix
    )
    logging.debug(
        "Added CameraConfiguration with media-profile-suffix '%s' for %s:%s.",
        media_profile_suffix,
        model,
        sku,
    )


# pylint: disable=too-many-statements
def _build_mtk_entry(parent, mtk_config) -> None:
    """Handle WifiConfiguration for MTKConfig case.

    Args:
        parent: The parent <HalConfig> XML element.
        mtk_config: MtkConfig config.
    """
    sar_elem = etree.SubElement(parent, "MTKConfig")

    def geo_power_chain(parent, power) -> None:
        cfg = etree.SubElement(parent, "PowerConfig.2g")
        etree.SubElement(cfg, "PowerLimit").text = str(power.limit_2g)
        etree.SubElement(cfg, "PowerOffset").text = str(power.offset_2g)

        cfg = etree.SubElement(parent, "PowerConfig.5g")
        etree.SubElement(cfg, "PowerLimit").text = str(power.limit_5g)
        etree.SubElement(cfg, "PowerOffset").text = str(power.offset_5g)

        if power.limit_6g or power.offset_6g:
            cfg = etree.SubElement(parent, "PowerConfig.6g")
            etree.SubElement(cfg, "PowerLimit").text = str(power.limit_6g)
            etree.SubElement(cfg, "PowerOffset").text = str(power.offset_6g)

    if mtk_config.HasField("fcc_power_table"):
        regdom_elem = etree.SubElement(sar_elem, "RegDomain.fcc")
        geo_power_chain(regdom_elem, mtk_config.fcc_power_table)
    if mtk_config.HasField("eu_power_table"):
        regdom_elem = etree.SubElement(sar_elem, "RegDomain.eu")
        geo_power_chain(regdom_elem, mtk_config.eu_power_table)
    if mtk_config.HasField("other_power_table"):
        regdom_elem = etree.SubElement(sar_elem, "RegDomain.other")
        geo_power_chain(regdom_elem, mtk_config.other_power_table)

    def power_chain(power, tablet_mode: bool) -> None:
        if tablet_mode:
            table = etree.SubElement(sar_elem, "PowerTable.tablet")
        else:
            table = etree.SubElement(sar_elem, "PowerTable.clamshell")

        for sband in ("2g", "5g_1", "5g_2", "5g_3", "5g_4"):
            cfg = etree.SubElement(table, f"PowerConfig.{sband}")
            etree.SubElement(cfg, "PowerLimit").text = str(
                getattr(power, f"limit_{sband}")
            )

        # Ignore 6 GHz parameters that are 0, which is the protobuf 3 default
        for sband in ("6g_1", "6g_2", "6g_3", "6g_4", "6g_5", "6g_6"):
            power_limit = getattr(power, f"limit_{sband}")
            if power_limit:
                cfg = etree.SubElement(table, f"PowerConfig.{sband}")
                etree.SubElement(cfg, "PowerLimit").text = str(power_limit)

    if mtk_config.HasField("tablet_mode_power_table"):
        power_chain(mtk_config.tablet_mode_power_table, True)

    if mtk_config.HasField("non_tablet_mode_power_table"):
        power_chain(mtk_config.non_tablet_mode_power_table, False)


# pylint: enable=too-many-statements


def _add_wifi_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
    sw_config: software_config_pb2.SoftwareConfig,
) -> None:
    """Adds WifiConfiguration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
        sw_config: software_config_pb2.SoftwareConfig specific to a design
        config.
    """
    hw_features = design_config.hardware_features

    wifi_config = None
    if hw_features.wifi.HasField("wifi_config"):
        wifi_config = hw_features.wifi.wifi_config
    else:
        wifi_config = sw_config.wifi_config

    config_field = wifi_config.WhichOneof("wifi_config")
    if config_field is not None:
        logging.info("wifi_config is %s", config_field)

        wifi_config_elem = etree.SubElement(hal_config, "WifiConfiguration")
        # skipping "ath10k_config" case as it is outdated,
        # will add "qcom" when chip config is ready
        if config_field in ("intel_config", "legacy_intel_config"):
            etree.SubElement(wifi_config_elem, "Chip").text = "intel"
        elif config_field.startswith("rtw"):
            etree.SubElement(wifi_config_elem, "Chip").text = "rtw"
        elif config_field == "mtk_config":
            etree.SubElement(wifi_config_elem, "Chip").text = "mtk"
            _build_mtk_entry(wifi_config_elem, wifi_config.mtk_config)
        else:
            logging.warning("unknown wifi_config: %s", config_field)


def _add_storage_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds Storage Configuration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    hw_features = design_config.hardware_features
    if not hw_features.HasField("storage"):
        logging.debug(
            "[%s] No storage found. Skipping StorageConfiguration.",
            design_config.id.value,
        )
        return

    storage_type = hw_features.storage.storage_type

    storage_type_names = {
        component_pb2.Component.Storage.StorageType.EMMC: "EMMC",
        component_pb2.Component.Storage.StorageType.NVME: "NVME",
        component_pb2.Component.Storage.StorageType.SATA: "SATA",
        component_pb2.Component.Storage.StorageType.UFS: "UFS",
        component_pb2.Component.Storage.StorageType.BRIDGED_EMMC: (
            "BRIDGED_EMMC"
        ),
    }

    if storage_type in storage_type_names:
        storage_elem = etree.SubElement(hal_config, "StorageConfiguration")
        etree.SubElement(storage_elem, "storage-type").text = (
            storage_type_names[storage_type]
        )
    else:
        logging.warning(
            "[%s] Unknown storage_type value: %s. Skipping StorageConfiguration.",
            design_config.id.value,
            storage_type,
        )


def _add_keyboard_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds Keyboard Configuration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    hw_features = design_config.hardware_features
    if not hw_features.HasField("keyboard"):
        logging.debug(
            "[%s] No keyboard found. Skipping KeyboardConfiguration.",
            design_config.id.value,
        )
        return

    keyboard = hw_features.keyboard
    backlight_support = "false"
    if keyboard.backlight == topology_pb2.HardwareFeatures.PRESENT:
        backlight_support = "true"

    kb_elem = etree.SubElement(hal_config, "KeyboardConfiguration")
    etree.SubElement(kb_elem, "backlight-support").text = backlight_support
    if keyboard.no_als_brightness:
        etree.SubElement(kb_elem, "kb-default-brightness").text = (
            f"{keyboard.no_als_brightness}"
        )
    if keyboard.backlight_user_steps:
        etree.SubElement(kb_elem, "kb-backlight-steps").text = (
            f"{keyboard.backlight_user_steps}"
        )


def _add_stylus_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds Stylus Configuration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    hw_features = design_config.hardware_features
    if not hw_features.HasField("stylus"):
        logging.debug(
            "[%s] No stylus found. Skipping StylusConfiguration.",
            design_config.id.value,
        )
        return

    stylus_type = hw_features.stylus.stylus

    stylus_type_names = {
        topology_pb2.HardwareFeatures.Stylus.NONE: "NONE",
        topology_pb2.HardwareFeatures.Stylus.INTERNAL: "GARAGED",
        topology_pb2.HardwareFeatures.Stylus.EXTERNAL: "NON_GARAGED",
    }

    if stylus_type in stylus_type_names:
        storage_elem = etree.SubElement(hal_config, "StylusConfiguration")
        etree.SubElement(storage_elem, "stylus-type").text = stylus_type_names[
            stylus_type
        ]
    else:
        logging.warning(
            "[%s] Unknown stylus_type value: %s. Skipping SylusConfiguration.",
            design_config.id.value,
            stylus_type,
        )


def _add_screen_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds Screen Configuration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    hw_features = design_config.hardware_features
    if not hw_features.HasField("screen"):
        logging.debug(
            "[%s] No screen found. Skipping ScreenConfiguration.",
            design_config.id.value,
        )
        return

    panel_prop = hw_features.screen.panel_properties
    screen_elem = etree.SubElement(hal_config, "ScreenConfiguration")
    value_text = f"{panel_prop.diagonal_milliinch} diagonal_milliinch"
    etree.SubElement(screen_elem, "screen-size").text = value_text


def _add_proximity_entry(
    hal_config: etree._Element,
    design_config: design_pb2.Design.Config,
) -> None:
    """Adds ProximitySensor Configuration to the XML tree for a Design.Config.

    Args:
        hal_config: The parent <HalConfig> XML element.
        design_config: The design_pb2.Design.Config proto.
    """
    # pylint: disable=too-many-branches

    hw_features = design_config.hardware_features
    if not hw_features.HasField("proximity"):
        logging.debug(
            "[%s] No proximity found. Skipping ProximityConfiguration.",
            design_config.id.value,
        )
        return

    proxm_elem = etree.SubElement(hal_config, "ProximityConfiguration")
    for proximity_config in hw_features.proximity.configs:
        if proximity_config.HasField("semtech_config"):
            semtech_top_elem = etree.SubElement(proxm_elem, "semtech-proximity")
            loc_elem = etree.SubElement(semtech_top_elem, "location")
            for loc in proximity_config.location:
                if (
                    loc.radio_type
                    == proximity_config_pb2.ProximityConfig.Location.RadioType.WIFI
                ):
                    locitem_elem = etree.SubElement(loc_elem, "radio-type-wifi")
                    if loc.modifier:
                        etree.SubElement(locitem_elem, "modifier").text = (
                            loc.modifier
                        )
                if (
                    loc.radio_type
                    == proximity_config_pb2.ProximityConfig.Location.RadioType.CELLULAR
                ):
                    locitem_elem = etree.SubElement(
                        loc_elem, "radio-type-cellular"
                    )
                    if loc.modifier:
                        etree.SubElement(locitem_elem, "modifier").text = (
                            loc.modifier
                        )

            semtech_config = proximity_config.semtech_config
            semtech_elem = etree.SubElement(semtech_top_elem, "semtech-config")
            for i, ch in enumerate(semtech_config.channel_config):
                ch_elem = etree.SubElement(semtech_elem, f"channel{i}")
                etree.SubElement(ch_elem, "channel").text = ch.channel
                if ch.hardwaregain:
                    etree.SubElement(ch_elem, "hardwaregain").text = str(
                        ch.hardwaregain
                    )
                if ch.thresh_falling:
                    etree.SubElement(ch_elem, "thresh-falling").text = str(
                        ch.thresh_falling
                    )
                if ch.thresh_falling_hysteresis:
                    etree.SubElement(
                        ch_elem, "thresh-falling-hysteresis"
                    ).text = str(ch.thresh_falling_hysteresis)
                if ch.thresh_rising:
                    etree.SubElement(ch_elem, "thresh-rising").text = str(
                        ch.thresh_rising
                    )
                if ch.thresh_rising_hysteresis:
                    etree.SubElement(
                        ch_elem, "thresh-rising-hysteresis"
                    ).text = str(ch.thresh_rising_hysteresis)
            if semtech_config.sampling_frequency:
                etree.SubElement(semtech_elem, "sampling-frequency").text = str(
                    semtech_config.sampling_frequency
                )
            if semtech_config.thresh_falling_period:
                etree.SubElement(semtech_elem, "thresh-falling-period").text = (
                    str(semtech_config.thresh_falling_period)
                )
            if semtech_config.thresh_rising_period:
                etree.SubElement(semtech_elem, "sthresh-rising-period").text = (
                    str(semtech_config.thresh_rising_period)
                )


def _add_hal_config_entry(
    root_element: etree._Element,
    design_config: design_pb2.Design.Config,
    sw_config: software_config_pb2.SoftwareConfig,
) -> None:
    """Adds a HalConfig to the XML tree for a Design.Config.

    Args:
        root_element: The root XML element (<HalConfigurations>).
        design_config: The Design.Config proto to process.
        sw_config: The SoftwareConfig proto.
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
    model_elem.text = model.lower()
    frid = sw_config.id_scan_config.frid.removeprefix("Google_")
    frid_elem = etree.SubElement(identity_elem, "frid")
    frid_elem.text = frid.lower()

    _add_cellular_entry(hal_config_elem, design_config)
    _add_fingerprint_entry(hal_config_elem, design_config)
    _add_firmware_entry(hal_config_elem, design_config, sw_config)
    _add_audio_entry(hal_config_elem, design_config)
    _add_video_entry(hal_config_elem, design_config)
    _add_camera_entry(
        hal_config_elem,
        design_config.hardware_features,
        sw_config,
        model,
        sku,
    )
    _add_hardware_features_entry(hal_config_elem, design_config)
    _add_wifi_entry(hal_config_elem, design_config, sw_config)
    _add_storage_entry(hal_config_elem, design_config)
    _add_keyboard_entry(hal_config_elem, design_config)
    _add_stylus_entry(hal_config_elem, design_config)
    _add_screen_entry(hal_config_elem, design_config)
    _add_proximity_entry(hal_config_elem, design_config)


def _convert_to_hal_xml(
    config_bundle: config_bundle_pb2.ConfigBundle,
) -> bytes:
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


def run_generate_component_xmls(opts: argparse.Namespace) -> None:
    """Handles the 'generate-component-xmls' sub-command logic."""
    logging.info("Running generate-component-xmls command...")
    config_bundle = _load_config_bundle(opts.jsonproto_file)
    generate_component_xmls.generate(config_bundle, opts.output_dir)
    logging.info(
        "Component XML generation complete. Files are in %s.", opts.output_dir
    )


def _add_feature_element(
    permissions_element: etree._Element,
    feature_name: str,
) -> None:
    """Adds a <feature> element to the given <permissions> element.

    Args:
        permissions_element: The parent <permissions> XML element.
        feature_name: The string name of the feature
            (e.g., "android.hardware.sensor.accelerometer").
    """
    feature_elem = etree.SubElement(permissions_element, "feature")
    feature_elem.set("name", feature_name)
    logging.debug("Added feature '%s' to XML tree.", feature_name)


def _add_camera_features(
    permissions_elem: etree._Element,
    camera_features: topology_pb2.HardwareFeatures.Camera,
) -> None:
    """Adds camera-related <feature> elements to the <permissions> element."""
    if not camera_features.devices:
        return

    _add_feature_element(permissions_elem, "android.hardware.camera.any")

    has_back_camera = any(
        not d.detachable
        and d.facing == topology_pb2.HardwareFeatures.Camera.FACING_BACK
        for d in camera_features.devices
    )
    if has_back_camera:
        _add_feature_element(permissions_elem, "android.hardware.camera")

    has_front_camera = any(
        not d.detachable
        and d.facing == topology_pb2.HardwareFeatures.Camera.FACING_FRONT
        for d in camera_features.devices
    )
    if has_front_camera:
        _add_feature_element(permissions_elem, "android.hardware.camera.front")

    has_autofocus_back_camera = any(
        not d.detachable
        and d.facing == topology_pb2.HardwareFeatures.Camera.FACING_BACK
        and (
            d.flags
            & topology_pb2.HardwareFeatures.Camera.FLAGS_SUPPORT_AUTOFOCUS
        )
        for d in camera_features.devices
    )
    if has_autofocus_back_camera:
        _add_feature_element(
            permissions_elem, "android.hardware.camera.autofocus"
        )

    # Assumes MIPI cameras support FULL-level.(b/440489318)
    has_level_full_camera = any(
        d.interface == topology_pb2.HardwareFeatures.Camera.INTERFACE_MIPI
        for d in camera_features.devices
    )

    if has_level_full_camera:
        _add_feature_element(
            permissions_elem, "android.hardware.camera.level.full"
        )
        _add_feature_element(
            permissions_elem, "android.hardware.camera.capability.manual_sensor"
        )
        _add_feature_element(
            permissions_elem,
            "android.hardware.camera.capability.manual_post_processing",
        )


def run_generate_feature_xml(opts: argparse.Namespace) -> None:
    """Handles the 'generate-feature-xml' sub-command logic."""
    # pylint: disable=too-many-branches

    logging.info("Running generate-feature-xml command...")
    config_bundle = _load_config_bundle(opts.jsonproto_file)

    if opts.from_hal_config:
        generate_feature_xml.generate_from_hal_config(
            config_bundle.android_hal_config, opts.output_dir
        )
        logging.info(
            "Write feature XMLs to %s.",
            opts.output_dir,
        )
        return

    for design in config_bundle.design_list:
        for design_config in design.configs:
            if not design_config.id.value:
                logging.warning(
                    "Skipping feature XML generation due to missing "
                    "'design_config.id': %s",
                    design_config,
                )
                continue

            sw_config = _get_sw_config(
                config_bundle.software_configs, design_config.id.value
            )
            frid = sw_config.id_scan_config.frid.removeprefix("Google_")
            if not frid:
                logging.warning(
                    "Skipping feature XML generation due to missing 'frid' in"
                    " 'id_scan_config' for Design.Config ID '%s'.",
                    design_config.id.value,
                )
                continue

            _, sku = design_config.id.value.split(":")
            permissions_elem = etree.Element("permissions")

            hw_features = design_config.hardware_features
            present_enum = topology_pb2.HardwareFeatures.PRESENT

            if present_enum in (
                hw_features.accelerometer.base_accelerometer,
                hw_features.accelerometer.lid_accelerometer,
            ):
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.accelerometer"
                )

            if present_enum in (
                hw_features.magnetometer.base_magnetometer,
                hw_features.magnetometer.lid_magnetometer,
            ):
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.compass"
                )

            if present_enum in (
                hw_features.gyroscope.base_gyroscope,
                hw_features.gyroscope.lid_gyroscope,
            ):
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.gyroscope"
                )

            if (
                hw_features.form_factor.form_factor
                == topology_pb2.HardwareFeatures.FormFactor.CONVERTIBLE
            ):
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.hinge_angle"
                )

            if present_enum in (
                hw_features.light_sensor.camera_lightsensor,
                hw_features.light_sensor.lid_lightsensor,
                hw_features.light_sensor.base_lightsensor,
            ):
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.light"
                )

            if hw_features.proximity.configs:
                _add_feature_element(
                    permissions_elem, "android.hardware.sensor.proximity"
                )

            if any(
                prox_conf.WhichOneof("config") == "semtech_config"
                for prox_conf in hw_features.proximity.configs
            ):
                _add_feature_element(permissions_elem, "com.google.sensor.sar")

            if hw_features.screen.touch_support == present_enum:
                _add_feature_element(
                    permissions_elem, "android.hardware.touchscreen"
                )
                _add_feature_element(
                    permissions_elem, "android.hardware.touchscreen.multitouch"
                )
                _add_feature_element(
                    permissions_elem,
                    "android.hardware.touchscreen.multitouch.distinct",
                )
                _add_feature_element(
                    permissions_elem,
                    "android.hardware.touchscreen.multitouch.jazzhand",
                )

            _add_camera_features(permissions_elem, hw_features.camera)

            sku_dir = opts.output_dir / f"{frid}_{sku}".lower()
            sku_dir.mkdir(parents=True, exist_ok=True)
            output_file = sku_dir / "features.xml"
            with open(output_file, "wb") as f:
                f.write(etree.tostring(permissions_elem, pretty_print=True))
            logging.info(
                "Wrote combined feature XML for %s:%s to %s",
                frid,
                sku,
                output_file,
            )


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
        help="Path to the base directory for output.",
    )
    parser_feature_xml.add_argument(
        "--from-hal-config",
        action="store_true",
        help=(
            "Generate feature XMLs from the HalConfiguration (per-component) "
            "instead of Design.Config (per-device)."
        ),
    )
    parser_feature_xml.set_defaults(func=run_generate_feature_xml)

    parser_media_profiles = subparsers.add_parser(
        "generate-media-profiles",
        help="Generate Android media profile XML files.",
    )
    parser_media_profiles.add_argument(
        "jsonproto_file",
        metavar="JSONPROTO_FILE",
        type=pathlib.Path,
        help="Path to the input JSON file representing a ConfigBundle message.",
    )
    parser_media_profiles.add_argument(
        "-o",
        "--output-dir",
        required=True,
        type=pathlib.Path,
        help="Path to the base directory where <Model>_<SkuID> subdirectories "
        "containing media profile XML files will be created.",
    )
    parser_media_profiles.add_argument(
        "--from-hal-config",
        action="store_true",
        help=(
            "Generate feature XMLs from the HalConfiguration (per-component) "
            "instead of Design.Config (per-device)."
        ),
    )
    parser_media_profiles.add_argument(
        "-d",
        "--dtd-schema",
        required=False,
        default=None,
        type=pathlib.Path,
        help="Path to the media_profiles.dtd schema file for validation. "
        "If not provided, validation is skipped.",
    )
    parser_media_profiles.set_defaults(func=run_generate_media_profiles)

    parser_component_xmls = subparsers.add_parser(
        "generate-component-xmls",
        help="Generate individual component XML files for HAL components.",
    )
    parser_component_xmls.add_argument(
        "jsonproto_file",
        metavar="JSONPROTO_FILE",
        type=pathlib.Path,
        help="Path to the input JSON file representing a ConfigBundle message.",
    )
    parser_component_xmls.add_argument(
        "-o",
        "--output-dir",
        required=True,
        type=pathlib.Path,
        help="Path to the directory where component XML files will be created.",
    )
    parser_component_xmls.set_defaults(func=run_generate_component_xmls)

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
