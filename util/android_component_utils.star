# Copyright 2025 Google LLC. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Starlark API for creating and encoding component_id based device configurations.

This module provides API for constructing the protobuf messages defined in
android_component_configs.proto.
"""

load(
    "@proto//chromiumos/config/api/android_component_configs.proto",
    android_component_pb = "chromiumos.config.api",
)

# Needed to load from @proto.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/generate.star", "generate")

_PRESENT = struct(
    UNKNOWN = android_component_pb.HalConfiguration.PRESENT_UNKNOWN,
    PRESENT = android_component_pb.HalConfiguration.PRESENT,
    NOT_PRESENT = android_component_pb.HalConfiguration.NOT_PRESENT,
)

def _create_audio(
        id,
        soundcard = None,
        dmics_count = None,
        audio_config_dir = None,
        default = False):
    """Builds android_hal_config proto for an audio component."""

    return android_component_pb.AudioConfigurationType(
        id = id,
        soundcard = soundcard,
        dmics_count = dmics_count,
        audio_config_dir = audio_config_dir,
        default = default,
    )

_FP_LOC = struct(
    UNKNOWN = android_component_pb.FingerprintConfigurationType.LOCATION_UNKNOWN,
    POWER_BUTTON_TOP_LEFT = android_component_pb.FingerprintConfigurationType.POWER_BUTTON_TOP_LEFT,
    KEYBOARD_BOTTOM_LEFT = android_component_pb.FingerprintConfigurationType.KEYBOARD_BOTTOM_LEFT,
    KEYBOARD_BOTTOM_RIGHT = android_component_pb.FingerprintConfigurationType.KEYBOARD_BOTTOM_RIGHT,
    KEYBOARD_TOP_RIGHT = android_component_pb.FingerprintConfigurationType.KEYBOARD_TOP_RIGHT,
    RIGHT_SIDE = android_component_pb.FingerprintConfigurationType.RIGHT_SIDE,
    LEFT_SIDE = android_component_pb.FingerprintConfigurationType.LEFT_SIDE,
    LEFT_OF_POWER_BUTTON_TOP_RIGHT = android_component_pb.FingerprintConfigurationType.LEFT_OF_POWER_BUTTON_TOP_RIGHT,
    POWER_BUTTON_TOP_RIGHT_KEY = android_component_pb.FingerprintConfigurationType.POWER_BUTTON_TOP_RIGHT_KEY,
    POWER_BUTTON_LEFT_EDGE_TOP = android_component_pb.FingerprintConfigurationType.POWER_BUTTON_LEFT_EDGE_TOP,
)

def _create_fingerprint(
        id,
        board,
        fingerprint_sensor_type = None,
        sensor_location = None,
        ro_version = None,
        default = False):
    """Builds android_hal_config proto for a fingerprint reader."""

    return android_component_pb.FingerprintConfigurationType(
        id = id,
        board = board,
        fingerprint_sensor_type = fingerprint_sensor_type,
        sensor_location = sensor_location,
        ro_version = ro_version,
        default = default,
    )

_MODEM = struct(
    MODEM_UNKNOWN = android_component_pb.CellularConfigurationType.MODEM_UNKNOWN,
    MODEM_L850 = android_component_pb.CellularConfigurationType.MODEM_L850,
    MODEM_NL668 = android_component_pb.CellularConfigurationType.MODEM_NL668,
    MODEM_FM101 = android_component_pb.CellularConfigurationType.MODEM_FM101,
    MODEM_FM350 = android_component_pb.CellularConfigurationType.MODEM_FM350,
    MODEM_SC7180 = android_component_pb.CellularConfigurationType.MODEM_SC7180,
    MODEM_SC7280 = android_component_pb.CellularConfigurationType.MODEM_SC7280,
    MODEM_EM060 = android_component_pb.CellularConfigurationType.MODEM_EM060,
    MODEM_RW101 = android_component_pb.CellularConfigurationType.MODEM_RW101,
    MODEM_RW135 = android_component_pb.CellularConfigurationType.MODEM_RW135,
    MODEM_LCUK54 = android_component_pb.CellularConfigurationType.MODEM_LCUK54,
    MODEM_RW350 = android_component_pb.CellularConfigurationType.MODEM_RW350,
)

def _create_cellular(
        id,
        modem_type = None,
        firmware_variant = None,
        default = False):
    """Builds android_hal_config proto for a cellular modem."""

    return android_component_pb.CellularConfigurationType(
        id = id,
        modem_type = modem_type,
        firmware_variant = firmware_variant,
        default = default,
    )

_CAM_INTERFACE = struct(
    INTERFACE_UNKNOWN = android_component_pb.CameraConfigurationType.FACING_UNKNOWN,
    INTERFACE_USB = android_component_pb.CameraConfigurationType.INTERFACE_USB,
    INTERFACE_MIPI = android_component_pb.CameraConfigurationType.INTERFACE_MIPI,
)
_CAM_FACING = struct(
    FACING_UNKNOWN = android_component_pb.CameraConfigurationType.FACING_UNKNOWN,
    FACING_FRONT = android_component_pb.CameraConfigurationType.FACING_FRONT,
    FACING_BACK = android_component_pb.CameraConfigurationType.FACING_BACK,
)

def _create_resolution(
        resolutionx = None,
        resolutiony = None):
    """Builds android_hal_config proto for a resolution."""

    return android_component_pb.CameraConfigurationType.Resolution(
        resolutionx = resolutionx,
        resolutiony = resolutiony,
    )

def _create_camerahwconfig(
        interface = None,
        position = None,
        autofocus_support = None,
        p1080_support = None,
        p4k_support = None,
        p1440_support = None,
        resolutions = []):
    """Builds android_hal_config proto for a camerahwconfig."""

    return android_component_pb.CameraConfigurationType.CameraHWConfig(
        interface = interface,
        position = position,
        autofocus_support = autofocus_support,
        p1080_support = p1080_support,
        p4k_support = p4k_support,
        p1440_support = p1440_support,
        resolutions = resolutions,
    )

def _create_camera(
        id,
        media_profile_suffix = None,
        cameras = [],
        default = False):
    """Builds android_hal_config proto for a camera."""

    return android_component_pb.CameraConfigurationType(
        id = id,
        media_profile_suffix = media_profile_suffix,
        cameras = cameras,
        default = default,
    )

def _create_storage(
        id,
        storage_type = None,
        default = False):
    """Builds android_hal_config proto for a Storage."""

    return android_component_pb.StorageConfigurationType(
        id = id,
        storage_type = storage_type,
        default = default,
    )

def _create_keyboard(
        id,
        backlight_support = None,
        kb_default_brightness = None,
        kb_backlight_steps = None,
        default = False):
    """Builds android_hal_config proto for a keyboard."""

    return android_component_pb.KeyboardConfigurationType(
        id = id,
        backlight_support = backlight_support,
        kb_default_brightness = kb_default_brightness,
        kb_backlight_steps = kb_backlight_steps,
        default = default,
    )

_STYLUS = struct(
    UNKNOWN = android_component_pb.StylusConfigurationType.STYLUS_UNKNOWN,
    NONE = android_component_pb.StylusConfigurationType.NONE,
    INTERNAL = android_component_pb.StylusConfigurationType.INTERNAL,
    EXTERNAL = android_component_pb.StylusConfigurationType.EXTERNAL,
)

def _create_stylus(
        id,
        stylus_type = None,
        default = False):
    """Builds android_hal_config proto for a stylus."""

    return android_component_pb.StylusConfigurationType(
        id = id,
        stylus_type = stylus_type,
        default = default,
    )

def _create_firmware(
        id,
        firmware_manifest_key = None,
        firmware_config = None,
        ufsc = None,
        default = False):
    """Builds android_hal_config proto for a firmware config."""

    return android_component_pb.FirmwareConfigurationType(
        id = id,
        firmware_manifest_key = firmware_manifest_key,
        firmware_config = firmware_config,
        ufsc = ufsc,
        default = default,
    )

def _create_touchscreen(
        id,
        screen_size = None,
        default = False):
    """Builds android_hal_config proto for a touch screen."""

    return android_component_pb.TouchscreenConfigurationType(
        id = id,
        screen_size = screen_size,
        default = default,
    )

def _create_touchpad(
        id,
        default = False):
    """Builds android_hal_config proto for a touchpad."""

    return android_component_pb.TouchpadConfigurationType(
        id = id,
        default = default,
    )

def _create_video(
        id,
        video_codec_suffix = None,
        default = False):
    """Builds android_hal_config proto for a video codec."""

    return android_component_pb.VideoConfigurationType(
        id = id,
        video_codec_suffix = video_codec_suffix,
        default = default,
    )

def _create_hwfeature(
        id,
        form_factor = None,
        touchscreen_support = None,
        default = False):
    """Builds android_hal_config proto for a hw_feature."""

    return android_component_pb.HardwareFeaturesConfigurationType(
        id = id,
        form_factor = form_factor,
        touchscreen_support = touchscreen_support,
        default = default,
    )

def _create_gyroscope(
        id,
        feature_gyroscope = None,
        default = False):
    """Builds android_hal_config proto for gyroscope configuration."""

    return android_component_pb.GyroscopeConfigurationType(
        id = id,
        feature_gyroscope = feature_gyroscope,
        default = default,
    )

def _create_accelerometer(
        id,
        feature_accelerometer = None,
        default = False):
    """Builds android_hal_config proto for accelerometer configuration."""

    return android_component_pb.AccelerometerConfigurationType(
        id = id,
        feature_accelerometer = feature_accelerometer,
        default = default,
    )

def _create_lightsensor(
        id,
        feature_lightsensor = None,
        default = False):
    """Builds android_hal_config proto for light sensor configuration."""

    return android_component_pb.LightSensorConfigurationType(
        id = id,
        feature_lightsensor = feature_lightsensor,
        default = default,
    )

def _create_magnetometer(
        id,
        feature_magnetometer = None,
        default = False):
    """Builds android_hal_config proto for magnetometer configuration."""

    return android_component_pb.MagnetometerConfigurationType(
        id = id,
        feature_magnetometer = feature_magnetometer,
        default = default,
    )

_WIFI_CHIP = struct(
    UNKNOWN = android_component_pb.WifiConfigurationType.UNKNOWN,
    INTEL = android_component_pb.WifiConfigurationType.INTEL,
    MTK = android_component_pb.WifiConfigurationType.MTK,
    RTW = android_component_pb.WifiConfigurationType.RTW,
    QCOM = android_component_pb.WifiConfigurationType.QCOM,
)

def _create_powerconfig(
        powerlimit = None,
        poweroffset = None):
    """Builds android_hal_config proto for power configuration."""

    return android_component_pb.WifiConfigurationType.SarSpecType.PowerConfigType(
        powerlimit = powerlimit,
        poweroffset = poweroffset,
    )

def _create_regdomain(
        powerconfig_2g = None,
        powerconfig_5g = None,
        powerconfig_6g = None):
    """Builds android_hal_config proto for RegDomainType configuration."""

    return android_component_pb.WifiConfigurationType.SarSpecType.RegDomainType(
        powerconfig_2g = powerconfig_2g,
        powerconfig_5g = powerconfig_5g,
        powerconfig_6g = powerconfig_6g,
    )

def _create_powertable(
        powerconfig_2g = None,
        powerconfig_5g = None,
        powerconfig_5g_1 = None,
        powerconfig_5g_2 = None,
        powerconfig_5g_3 = None,
        powerconfig_5g_4 = None,
        powerconfig_6g_1 = None,
        powerconfig_6g_2 = None,
        powerconfig_6g_3 = None,
        powerconfig_6g_4 = None,
        powerconfig_6g_5 = None,
        powerconfig_6g_6 = None):
    """Builds android_hal_config proto for PowerTableType configuration."""

    return android_component_pb.WifiConfigurationType.SarSpecType.PowerTableType(
        powerconfig_2g = powerconfig_2g,
        powerconfig_5g = powerconfig_5g,
        powerconfig_5g_1 = powerconfig_5g_1,
        powerconfig_5g_2 = powerconfig_5g_2,
        powerconfig_5g_3 = powerconfig_5g_3,
        powerconfig_5g_4 = powerconfig_5g_4,
        powerconfig_6g_1 = powerconfig_6g_1,
        powerconfig_6g_2 = powerconfig_6g_2,
        powerconfig_6g_3 = powerconfig_6g_3,
        powerconfig_6g_4 = powerconfig_6g_4,
        powerconfig_6g_5 = powerconfig_6g_5,
        powerconfig_6g_6 = powerconfig_6g_6,
    )

def _create_sarspec(
        regdomain_fcc = None,
        regdomain_eu = None,
        regdomain_other = None,
        powertable_tablet = None,
        powertable_clamshell = None):
    """Builds android_hal_config proto for SarSpecType configuration."""

    return android_component_pb.WifiConfigurationType.SarSpecType(
        regdomain_fcc = regdomain_fcc,
        regdomain_eu = regdomain_eu,
        regdomain_other = regdomain_other,
        powertable_tablet = powertable_tablet,
        powertable_clamshell = powertable_clamshell,
    )

def _create_wificonfig(
        id,
        chip = None,
        mtkconfig = None,
        rtwconfig = None,
        feature_aware = None,
        feature_direct = None,
        feature_passport = None,
        feature_rtt = None,
        default = False):
    """Builds android_hal_config proto for WifiConfigurationType configuration."""

    return android_component_pb.WifiConfigurationType(
        id = id,
        chip = chip,
        mtkconfig = mtkconfig,
        rtwconfig = rtwconfig,
        feature_aware = feature_aware,
        feature_direct = feature_direct,
        feature_passport = feature_passport,
        feature_rtt = feature_rtt,
        default = default,
    )

def _create_location(
        modifier = None):
    """Builds android_hal_config proto for Proximity sensor location configuration."""

    return android_component_pb.ProximityConfigurationType.LocationType(
        modifier = modifier,
    )

def _create_proximitylocation(
        radio_type_wifi = None,
        radio_type_cellular = None):
    """Builds android_hal_config proto for Proximity sensor location configuration."""

    return android_component_pb.ProximityConfigurationType.ProximityLocationType(
        radio_type_wifi = radio_type_wifi,
        radio_type_cellular = radio_type_cellular,
    )

def _create_semtech_channel(
        channel = None,
        hardwaregain = None,
        thresh_falling = None,
        thresh_falling_hysteresis = None,
        thresh_rising = None,
        thresh_rising_hysteresis = None):
    """Builds android_hal_config proto for SemtechChannelType configuration."""

    return android_component_pb.ProximityConfigurationType.SemtechChannelType(
        channel = channel,
        hardwaregain = hardwaregain,
        thresh_falling = thresh_falling,
        thresh_falling_hysteresis = thresh_falling_hysteresis,
        thresh_rising = thresh_rising,
        thresh_rising_hysteresis = thresh_rising_hysteresis,
    )

def _create_semtech_sensorconfig(
        channel = [],
        sampling_frequency = None,
        thresh_falling_period = None,
        thresh_rising_period = None):
    """Builds android_hal_config proto for SemtechSensorConfigurationType configuration."""

    return android_component_pb.ProximityConfigurationType.SemtechSensorConfigurationType(
        channel = channel,
        sampling_frequency = sampling_frequency,
        thresh_falling_period = thresh_falling_period,
        thresh_rising_period = thresh_rising_period,
    )

def _create_semtech_proximity(
        location = None,
        semtech_config = None):
    """Builds android_hal_config proto for SemtechProximityConfigurationType configuration."""

    return android_component_pb.ProximityConfigurationType.SemtechProximityConfigurationType(
        location = location,
        semtech_config = semtech_config,
    )

def _create_proximity(
        id,
        semtech_proximity = None,
        default = False):
    """Builds android_hal_config proto for ProximityConfigurationType configuration."""

    return android_component_pb.ProximityConfigurationType(
        id = id,
        semtech_proximity = semtech_proximity,
        default = default,
    )

def _create_hal_config(
        audio_configurations = None,
        fingerprint_configurations = None,
        cellular_configurations = None,
        camera_configurations = None,
        storage_configurations = None,
        keyboard_configurations = None,
        stylus_configurations = None,
        firmware_configurations = None,
        touchscreen_configurations = None,
        touchpad_configurations = None,
        video_configurations = None,
        hwfeature_configurations = None,
        gyroscope_configurations = None,
        accelerometer_configurations = None,
        lightsensor_configurations = None,
        magnetometer_configurations = None,
        wifi_configurations = None,
        proximity_configurations = None):
    """Builds a HalConfiguration proto."""

    return android_component_pb.HalConfiguration(
        audio_list = audio_configurations,
        fingerprint_list = fingerprint_configurations,
        cellular_list = cellular_configurations,
        camera_list = camera_configurations,
        storage_list = storage_configurations,
        keyboard_list = keyboard_configurations,
        stylus_list = stylus_configurations,
        firmware_list = firmware_configurations,
        touchscreen_list = touchscreen_configurations,
        touchpad_list = touchpad_configurations,
        video_list = video_configurations,
        hwfeature_list = hwfeature_configurations,
        gyroscope_list = gyroscope_configurations,
        accelerometer_list = accelerometer_configurations,
        lightsensor_list = lightsensor_configurations,
        magnetometer_list = magnetometer_configurations,
        wifi_list = wifi_configurations,
        proximity_list = proximity_configurations,
    )

android_hal_config = struct(
    create_audio = _create_audio,
    create_fingerprint = _create_fingerprint,
    create_cellular = _create_cellular,
    create_resolution = _create_resolution,
    create_camerahwconfig = _create_camerahwconfig,
    create_camera = _create_camera,
    create_storage = _create_storage,
    create_keyboard = _create_keyboard,
    create_stylus = _create_stylus,
    create_firmware = _create_firmware,
    create_touchscreen = _create_touchscreen,
    create_touchpad = _create_touchpad,
    create_video = _create_video,
    create_hwfeature = _create_hwfeature,
    create_gyroscope = _create_gyroscope,
    create_accelerometer = _create_accelerometer,
    create_lightsensor = _create_lightsensor,
    create_magnetometer = _create_magnetometer,
    create_powerconfig = _create_powerconfig,
    create_regdomain = _create_regdomain,
    create_powertable = _create_powertable,
    create_sarspec = _create_sarspec,
    create_wificonfig = _create_wificonfig,
    create_location = _create_location,
    create_proximitylocation = _create_proximitylocation,
    create_semtech_channel = _create_semtech_channel,
    create_semtech_sensorconfig = _create_semtech_sensorconfig,
    create_semtech_proximity = _create_semtech_proximity,
    create_proximity = _create_proximity,
    create_hal_config = _create_hal_config,
    gen_file = generate.gen_file,
    generate = generate.generate,
    present = _PRESENT,
    fp_loc = _FP_LOC,
    modem = _MODEM,
    cam_pos = _CAM_FACING,
    cam_intf = _CAM_INTERFACE,
    stylus = _STYLUS,
    wifichip = _WIFI_CHIP,
)
