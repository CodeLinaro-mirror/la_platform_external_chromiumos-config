"""Functions related to hardware topology.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/topology.proto",
    topo_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/hardware_topology.proto",
    hw_topo_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/component.proto",
    comp_pb = "chromiumos.config.api",
)

_FF = struct(
    CLAMSHELL = topo_pb.HardwareFeatures.FormFactor.CLAMSHELL,
    CONVERTIBLE = topo_pb.HardwareFeatures.FormFactor.CONVERTIBLE,
    DETACHABLE = topo_pb.HardwareFeatures.FormFactor.DETACHABLE,
    CHROMEBASE = topo_pb.HardwareFeatures.FormFactor.CHROMEBASE,
    CHROMEBOX = topo_pb.HardwareFeatures.FormFactor.CHROMEBOX,
    CHROMEBIT = topo_pb.HardwareFeatures.FormFactor.CHROMEBIT,
    CHROMESLATE = topo_pb.HardwareFeatures.FormFactor.CHROMESLATE,
)

_AUDIO_CODEC = struct(
    RT5682 = topo_pb.HardwareFeatures.Audio.RT5682,
    ALC5682I = topo_pb.HardwareFeatures.Audio.ALC5682I,
    ALC5682 = topo_pb.HardwareFeatures.Audio.ALC5682,
    MAX98357 = topo_pb.HardwareFeatures.Audio.MAX98357,
    MAX98373 = topo_pb.HardwareFeatures.Audio.MAX98373,
    MAX98360 = topo_pb.HardwareFeatures.Audio.MAX98360,
)

_MEMORY = struct(
    DDR = comp_pb.Component.Memory.DDR,
    DDR2 = comp_pb.Component.Memory.DDR2,
    DDR3 = comp_pb.Component.Memory.DDR3,
    DDR4 = comp_pb.Component.Memory.DDR4,
    LP_DDR3 = comp_pb.Component.Memory.LP_DDR3,
    LP_DDR4 = comp_pb.Component.Memory.LP_DDR4,
)

_FP_LOC = struct(
    NOT_PRESENT = topo_pb.HardwareFeatures.Fingerprint.NOT_PRESENT,
    POWER_BUTTON_TOP_LEFT = topo_pb.HardwareFeatures.Fingerprint.POWER_BUTTON_TOP_LEFT,
    KEYBOARD_BOTTOM_LEFT = topo_pb.HardwareFeatures.Fingerprint.KEYBOARD_BOTTOM_LEFT,
    KEYBOARD_BOTTOM_RIGHT = topo_pb.HardwareFeatures.Fingerprint.KEYBOARD_BOTTOM_RIGHT,
    KEYBOARD_TOP_RIGHT = topo_pb.HardwareFeatures.Fingerprint.KEYBOARD_TOP_RIGHT,
    POWER_BUTTON_SIDE_RIGHT = topo_pb.HardwareFeatures.Fingerprint.POWER_BUTTON_SIDE_RIGHT,
)

_STORAGE = struct(
    EMMC = topo_pb.HardwareFeatures.Storage.EMMC,
    NVME = topo_pb.HardwareFeatures.Storage.NVME,
)

_KB_TYPE = struct(
    NONE = topo_pb.HardwareFeatures.Keyboard.NONE,
    INTERNAL = topo_pb.HardwareFeatures.Keyboard.INTERNAL,
    DETACHABLE = topo_pb.HardwareFeatures.Keyboard.DETACHABLE,
)

_STYLUS = struct(
    NONE = topo_pb.HardwareFeatures.Stylus.NONE,
    INTERNAL = topo_pb.HardwareFeatures.Stylus.INTERNAL,
    EXTERNAL = topo_pb.HardwareFeatures.Stylus.EXTERNAL,
)

_REGION = struct(
    SCREEN = topo_pb.HardwareFeatures.Button.SCREEN,
    KEYBOARD = topo_pb.HardwareFeatures.Button.KEYBOARD,
)

_EDGE = struct(
    LEFT = topo_pb.HardwareFeatures.Button.LEFT,
    RIGHT = topo_pb.HardwareFeatures.Button.RIGHT,
    TOP = topo_pb.HardwareFeatures.Button.TOP,
    BOTTOM = topo_pb.HardwareFeatures.Button.BOTTOM,
)

# Starlark doesn't support converting enums to their names. Add helper fns. to
# do so.
def _button_region_to_str(region):
    return {
        _REGION.SCREEN: "SCREEN",
        _REGION.KEYBOARD: "KEYBOARD",
    }.get(region, "UNKNOWN")

def _button_edge_to_str(edge):
    return {
        _EDGE.LEFT: "LEFT",
        _EDGE.RIGHT: "RIGHT",
        _EDGE.TOP: "TOP",
        _EDGE.BOTTOM: "BOTTOM",
    }.get(edge, "UNKNOWN")

def _make_fw_config(mask, id):
    """Builds a HardwareFeatures.FirmwareConfiguration proto.

    Takes a 32-bit mask for the field and an id. Shifts the id
    into the mask region and checks that the value fits within the bit mask.
    """
    lsb_bit_set = (~mask + 1) & mask
    shifted_id = id * lsb_bit_set
    if shifted_id & mask != shifted_id:
        fail("Specified id %d out of range [0, %d]" % (id, mask // lsb_bit_set))

    return topo_pb.HardwareFeatures.FirmwareConfiguration(
        value = shifted_id,
        mask = mask,
    )

def _accumulate_fw_config(existing_fw_config, new_fw_config):
    """Adds fw config to existing fw config."""
    if existing_fw_config.mask & new_fw_config.mask:
        fail("FW_CONFIG masks cannot overlap! 0x%x and 0x%x" %
             (existing_fw_config.mask, new_fw_config.mask))

    existing_fw_config.value += new_fw_config.value
    existing_fw_config.mask += new_fw_config.mask

def _accumulate_fw_configs(result_hw_features, fw_configs):
    for fw_config in fw_configs:
        _accumulate_fw_config(result_hw_features.fw_config, fw_config)

def _create_design_features(form_factor = _FF.CLAMSHELL):
    """Builds a HardwareFeatures proto with form_factor."""
    return topo_pb.HardwareFeatures(
        form_factor = topo_pb.HardwareFeatures.FormFactor(
            form_factor = form_factor,
        ),
    )

def _create_features(form_factors = [_FF.CLAMSHELL, _FF.CONVERTIBLE]):
    """Builds a HardwareFeatures proto for each of form_factors."""
    return [_create_design_features(ff) for ff in form_factors]

def _bool_to_present(value):
    """Returns correct value of present enum depending on value"""
    if value == None:
        return topo_pb.HardwareFeatures.PRESENT_UNKNOWN
    elif value:
        return topo_pb.HardwareFeatures.PRESENT
    else:
        return topo_pb.HardwareFeatures.NOT_PRESENT

def _create_screen(
        id = "SCREEN",
        description = "Default screen",
        inches = None,
        width_px = None,
        height_px = None,
        pixels_per_in = None,
        touch = False,
        fw_configs = []):
    """Builds a Topology proto for a screen."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.screen.panel_properties = comp_pb.Component.DisplayPanel.Properties(
        diagonal_milliinch = inches * 1000,
        width_px = width_px,
        height_px = height_px,
        pixels_per_in = pixels_per_in,
    )
    hw_features.screen.touch_support = _bool_to_present(touch)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.SCREEN,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_form_factor(form_factor, fw_configs = [], id = None, description = None):
    """Builds a Topology proto for a form factor.

    Args:
        form_factor: A FormFactorType enum. Required.
        fw_configs: A list of FirmwareConfiguration protos for the form factor.
        id: A string identifier for the Topology. If not passed, a default is
            provided based on form_factor.
        description: An English description for the Topology. If not passed, a
            default is provided based on form_factor.
    """
    if not id:
        id = {
            _FF.CLAMSHELL: "CLAMSHELL",
            _FF.CONVERTIBLE: "CONVERTIBLE",
            _FF.CHROMEBOX: "CHROMEBOX",
        }[form_factor]

    if not description:
        description = {
            _FF.CLAMSHELL: "Device cannot rotate past 180 degrees",
            _FF.CONVERTIBLE: "Device can rotate 360 degrees",
            _FF.CHROMEBOX: "Desktop chrome device.",
        }[form_factor]

    hw_features = topo_pb.HardwareFeatures()

    hw_features.form_factor.form_factor = form_factor

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.FORM_FACTOR,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_audio(id, description, codec = None, speaker_amp = None, headphone_codec = None, fw_configs = []):
    """Builds a Topology proto for audio."""
    hw_features = topo_pb.HardwareFeatures()

    if codec:
        hw_features.audio.audio_codec = codec
    if speaker_amp:
        hw_features.audio.speaker_amp = speaker_amp
    if headphone_codec:
        hw_features.audio.headphone_codec = headphone_codec

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.AUDIO,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_stylus(id, description, stylus_type, fw_configs = []):
    """Builds a Topology proto for a stylus."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.stylus.stylus = stylus_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.STYLUS,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_keyboard(backlight, pwr_btn_present, kb_type, fw_configs = [], id = None, description = None):
    """Builds a Topology proto for a keyboard.

    Args:
        backlight: True if a backlight is present. Required.
        pwr_btn_present: True if a power button is present. Required.
        kb_type: A KeyboardType enum. Required.
        fw_configs: A list of FirmwareConfiguration protos for the form factor.
        id: A string identifier for the Topology. If not passed, a default is
            provided.
        description: An English description for the Topology. If not passed, a
            default is provided.
    """

    if not id:
        id = "KB_{backlight}".format(
            backlight = "BL" if backlight else "NO_BL",
        )

    if not description:
        # Starlark doesn't seem to have a way to find the enum name with
        # reflection.
        if kb_type == topo_pb.HardwareFeatures.Keyboard.INTERNAL:
            type_str = "Internal"
        elif kb_type == topo_pb.HardwareFeatures.Keyboard.DETACHABLE:
            type_str = "Detachable"
        else:
            type_str = "Unknown type"

        description = "{type} keyboard {backlight} backlight".format(
            type = type_str,
            backlight = "with" if backlight else "without",
        )

    hw_features = topo_pb.HardwareFeatures()

    hw_features.keyboard.keyboard_type = kb_type
    hw_features.keyboard.backlight = _bool_to_present(backlight)
    hw_features.keyboard.power_button = _bool_to_present(pwr_btn_present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.KEYBOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_thermal(id, description, fw_configs = []):
    """Builds a Topology proto for thermal."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.THERMAL,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_camera(id, description, fw_configs = [], has_a_panel_camera = None, has_b_panel_camera = None, count = 0):
    """Builds a Topology proto for a camera."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.camera.a_panel_camera = _bool_to_present(has_a_panel_camera)
    hw_features.camera.b_panel_camera = _bool_to_present(has_b_panel_camera)
    if count:
        hw_features.camera.count.value = count

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.CAMERA,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_sensor(
        id,
        description,
        fw_configs = [],
        lid_accel_present = None,
        base_accel_present = None,
        lid_gyro_present = None,
        base_gyro_present = None,
        lid_magno_present = None,
        base_magno_present = None):
    """Builds a Topology proto for accelerometer/gyroscrope/magnometer sensors."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    if lid_accel_present:
        hw_features.accelerometer.lid_accelerometer = _bool_to_present(lid_accel_present)

    if base_accel_present:
        hw_features.accelerometer.base_accelerometer = _bool_to_present(base_accel_present)

    if lid_gyro_present:
        hw_features.gyroscope.lid_gyroscope = _bool_to_present(lid_gyro_present)

    if base_gyro_present:
        hw_features.gyroscope.base_gyroscope = _bool_to_present(base_gyro_present)

    if lid_magno_present:
        hw_features.magnetometer.lid_magnetometer = _bool_to_present(lid_magno_present)

    if base_magno_present:
        hw_features.magnetometer.base_magnetometer = _bool_to_present(base_magno_present)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.ACCELEROMETER_GYROSCOPE_MAGNETOMETER,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_fingerprint(id, description, location, board = None, fw_configs = []):
    """Builds a Topology proto for a fingerprint reader."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.fingerprint.location = location
    if board:
        hw_features.fingerprint.board = board

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.FINGERPRINT,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_proximity_sensor(id, description, fw_configs = []):
    """Builds a Topology proto for a proximity sensor."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.PROXIMITY_SENSOR,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_daughter_board(
        id,
        description,
        fw_configs = [],
        usbc_count = 0,
        usba_count = 0,
        lte_support = False,
        hdmi_support = False):
    """Builds a Topology proto for a daughter board."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    hw_features.usb_c.count.value = usbc_count
    hw_features.usb_a.count.value = usba_count
    hw_features.lte.present = _bool_to_present(lte_support)
    hw_features.hdmi.present = _bool_to_present(hdmi_support)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.DAUGHTER_BOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_non_volatile_storage(id, description, storage_type, fw_configs = []):
    """Builds a Topology proto for non-volatile storage."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.storage.storage_type = storage_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.NON_VOLATILE_STORAGE,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_ram(id, description, gigabytes, type, speed_mhz, fw_configs = []):
    """Builds a Topology proto for RAM."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.memory.profile.type = type
    hw_features.memory.profile.speed_mhz = speed_mhz
    hw_features.memory.profile.size_megabytes = gigabytes * 1024

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.RAM,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_wifi(id, description, fw_configs = []):
    """Builds a Topology proto for a WiFi chip."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.WIFI,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_lte_board(id, description, lte_present, fw_configs = []):
    """Builds a Topology proto for a LTE board."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.lte.present = _bool_to_present(lte_present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.LTE_BOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_sd_reader(id, description, fw_configs = []):
    """Builds a Topology proto for a SD reader."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.SD_READER,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_motherboard_usb(
        id,
        description,
        fw_configs = [],
        usbc_count = 0,
        usba_count = 0):
    """Builds a Topology proto for a motherboard."""
    hw_features = topo_pb.HardwareFeatures()

    _accumulate_fw_configs(hw_features, fw_configs)

    hw_features.usb_c.count.value = usbc_count
    hw_features.usb_a.count.value = usba_count

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.MOTHERBOARD_USB,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_bluetooth(id, description, bt_component, fw_configs = []):
    """Builds a Topology proto for bluetooth."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.bluetooth.component = bt_component

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.BLUETOOTH,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_barreljack(id, description, bj_present, fw_configs = []):
    """Builds a Topology proto for barreljack."""
    hw_features = topo_pb.HardwareFeatures()

    hw_features.barreljack.present = _bool_to_present(bj_present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.BARRELJACK,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_power_button(region, edge, position, id = None, description = None):
    """Builds a Topology proto for a power button.

    Args:
        region: A HardwareFeatures.Button.Region enum. Required.
        edge: A HardwareFeatures.Button.Edge enum. Required.
        position: The percentage for button center position to the display's
            width/height in primary landscape screen orientation. If edge is
            LEFT or RIGHT, specifies the button's center position as a fraction
            of region's height relative to the top of region. For TOP and
            BOTTOM, specifies the position as a fraction of region width
            relative to the left side of region. Must be in the range
            [0.0, 1.0]. Required.
        id: A string identifier for the Topology. If not passed, a default is
            provided.
        description: An English description for the Topology. If not passed, a
            default is provided.
    """
    if not id:
        id = "{region}_{edge}_POWER_BUTTON".format(
            region = _button_region_to_str(region),
            edge = _button_edge_to_str(edge),
        )

    if not description:
        description = "Power button on the {edge} edge of the {region}".format(
            region = _button_region_to_str(region).lower(),
            edge = _button_edge_to_str(edge).lower(),
        )
    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.POWER_BUTTON,
        description = {"EN": description},
        hardware_feature = topo_pb.HardwareFeatures(
            power_button = topo_pb.HardwareFeatures.Button(
                region = region,
                edge = edge,
                position = position,
            ),
        ),
    )

def _create_volume_button(region, edge, position, id = None, description = None):
    """Builds a Topology proto for a volume button.

    Args:
        region: A HardwareFeatures.Button.Region enum. Required.
        edge: A HardwareFeatures.Button.Edge enum. Required.
        position: The percentage for button center position to the display's
            width/height in primary landscape screen orientation. If edge is
            LEFT or RIGHT, specifies the button's center position as a fraction
            of region's height relative to the top of region. For TOP and
            BOTTOM, specifies the position as a fraction of region width
            relative to the left side of region. Must be in the range
            [0.0, 1.0]. Required.
        id: A string identifier for the Topology. If not passed, a default is
            provided.
        description: An English description for the Topology. If not passed, a
            default is provided.
    """
    if not id:
        id = "{region}_{edge}_VOLUME_BUTTON".format(
            region = _button_region_to_str(region),
            edge = _button_edge_to_str(edge),
        )

    if not description:
        description = "Volume button on the {edge} edge of the {region}".format(
            region = _button_region_to_str(region).lower(),
            edge = _button_edge_to_str(edge).lower(),
        )
    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.POWER_BUTTON,
        description = {"EN": description},
        hardware_feature = topo_pb.HardwareFeatures(
            volume_button = topo_pb.HardwareFeatures.Button(
                region = region,
                edge = edge,
                position = position,
            ),
        ),
    )

def _create_hardware_topology(
        screen = None,
        form_factor = None,
        audio = None,
        stylus = None,
        keyboard = None,
        thermal = None,
        camera = None,
        accelerometer_gyroscope_magnetometer = None,
        fingerprint = None,
        proximity_sensor = None,
        daughter_board = None,
        non_volatile_storage = None,
        ram = None,
        wifi = None,
        lte_board = None,
        sd_reader = None,
        motherboard_usb = None,
        bluetooth = None,
        barreljack = None,
        power_button = None,
        volume_button = None):
    """Builds a HardwareTopology proto from Topology protos."""

    # Only allow form_factor topologies for form factors
    if screen and screen.type != topo_pb.Topology.SCREEN:
        fail("Invalid screen topology")

    if form_factor and form_factor.type != topo_pb.Topology.FORM_FACTOR:
        fail("Invalid form factor topology")

    if audio and audio.type != topo_pb.Topology.AUDIO:
        fail("Invalid audio topology")

    if stylus and stylus.type != topo_pb.Topology.STYLUS:
        fail("Invalid stylus topology")

    if keyboard and keyboard.type != topo_pb.Topology.KEYBOARD:
        fail("Invalid keyboard topology")

    if thermal and thermal.type != topo_pb.Topology.THERMAL:
        fail("Invalid thermal topology")

    if camera and camera.type != topo_pb.Topology.CAMERA:
        fail("Invalid camera topology")

    if accelerometer_gyroscope_magnetometer and accelerometer_gyroscope_magnetometer.type != topo_pb.Topology.ACCELEROMETER_GYROSCOPE_MAGNETOMETER:
        fail("Invalid accelerometer/gyroscope/magnetometer topology")

    if fingerprint and fingerprint.type != topo_pb.Topology.FINGERPRINT:
        fail("Invalid fingerprint topology")

    if proximity_sensor and proximity_sensor.type != topo_pb.Topology.PROXIMITY_SENSOR:
        fail("Invalid proximity sensor topology")

    if daughter_board and daughter_board.type != topo_pb.Topology.DAUGHTER_BOARD:
        fail("Invalid daughter board topology")

    if non_volatile_storage and non_volatile_storage.type != topo_pb.Topology.NON_VOLATILE_STORAGE:
        fail("Invalid non-volatile storage topology")

    if ram and ram.type != topo_pb.Topology.RAM:
        fail("Invalid ram topology")

    if wifi and wifi.type != topo_pb.Topology.WIFI:
        fail("Invalid wifi topology")

    if lte_board and lte_board.type != topo_pb.Topology.LTE_BOARD:
        fail("Invalid lte board topology")

    if sd_reader and sd_reader.type != topo_pb.Topology.SD_READER:
        fail("Invalid lte board topology")

    if motherboard_usb and motherboard_usb.type != topo_pb.Topology.MOTHERBOARD_USB:
        fail("Invalid motherboard usb board topology")

    if bluetooth and bluetooth.type != topo_pb.Topology.BLUETOOTH:
        fail("Invalid bluetooth topology")

    if barreljack and barreljack.type != topo_pb.Topology.BARRELJACK:
        fail("Invalid barreljack topology")

    if power_button and power_button.type != topo_pb.Topology.POWER_BUTTON:
        fail("Invalid power button topology")

    if volume_button and volume_button.type != topo_pb.Topology.POWER_BUTTON:
        fail("Invalid volume button topology")

    return hw_topo_pb.HardwareTopology(
        screen = screen,
        form_factor = form_factor,
        audio = audio,
        stylus = stylus,
        keyboard = keyboard,
        thermal = thermal,
        camera = camera,
        accelerometer_gyroscope_magnetometer = accelerometer_gyroscope_magnetometer,
        fingerprint = fingerprint,
        proximity_sensor = proximity_sensor,
        daughter_board = daughter_board,
        non_volatile_storage = non_volatile_storage,
        ram = ram,
        wifi = wifi,
        lte_board = lte_board,
        sd_reader = sd_reader,
        motherboard_usb = motherboard_usb,
        bluetooth = bluetooth,
        barreljack = barreljack,
        power_button = power_button,
        volume_button = volume_button,
    )

def _accumulate_presence(existing_present, new_present):
    if existing_present == topo_pb.HardwareFeatures.PRESENT:
        return existing_present
    elif new_present != topo_pb.HardwareFeatures.PRESENT_UNKNOWN:
        return new_present
    else:
        return existing_present

def _accumulate_usbc(existing_usbc, new_usbc):
    existing_usbc.count.value += new_usbc.count.value

def _accumulate_usba(existing_usba, new_usba):
    existing_usba.count.value += new_usba.count.value

def _accumulate_lte(existing_lte, new_lte):
    existing_lte.present = _accumulate_presence(existing_lte.present, new_lte.present)

def _accumulate_hdmi(existing_hdmi, new_hdmi):
    existing_hdmi.present = _accumulate_presence(existing_hdmi.present, new_hdmi.present)

def _convert_to_hw_features(base_hw_features, hardware_topology):
    """Converts a HardwareTopology proto to a HardwareFeatures proto."""
    result = topo_pb.HardwareFeatures()

    # Need to make deep-copy otherwise we change the has_ message serialization
    copy = proto.from_textpb(hw_topo_pb.HardwareTopology, proto.to_textpb(hardware_topology))

    # Handle all possible screen hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.screen.hardware_feature.fw_config)

    if copy.screen.hardware_feature.screen != topo_pb.HardwareFeatures.Screen():
        result.screen = copy.screen.hardware_feature.screen

    # Handle all possible form factor hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.form_factor.hardware_feature.fw_config)

    if copy.form_factor.hardware_feature.form_factor != topo_pb.HardwareFeatures.FormFactor():
        result.form_factor = copy.form_factor.hardware_feature.form_factor

    # Handle all possible audio features attributes
    _accumulate_fw_config(result.fw_config, copy.audio.hardware_feature.fw_config)

    if copy.audio.hardware_feature.audio != topo_pb.HardwareFeatures.Audio():
        result.audio = copy.audio.hardware_feature.audio

    # Handle all possible stylus hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.stylus.hardware_feature.fw_config)

    if copy.stylus.hardware_feature.stylus != topo_pb.HardwareFeatures.Stylus():
        result.stylus = copy.stylus.hardware_feature.stylus

    # Handle all possible keyboard hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.keyboard.hardware_feature.fw_config)

    if copy.keyboard.hardware_feature.keyboard != topo_pb.HardwareFeatures.Keyboard():
        result.keyboard = copy.keyboard.hardware_feature.keyboard

    # Handle all possible thermal features attributes
    _accumulate_fw_config(result.fw_config, copy.thermal.hardware_feature.fw_config)

    # Handle all possible camera features attributes
    _accumulate_fw_config(result.fw_config, copy.camera.hardware_feature.fw_config)

    if copy.camera.hardware_feature.camera != topo_pb.HardwareFeatures.Camera():
        result.camera = copy.camera.hardware_feature.camera

    # Handle all possible sensor attributes
    _accumulate_fw_config(result.fw_config, copy.accelerometer_gyroscope_magnetometer.hardware_feature.fw_config)

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.accelerometer != topo_pb.HardwareFeatures.Accelerometer():
        result.accelerometer = copy.accelerometer_gyroscope_magnetometer.hardware_feature.accelerometer

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.gyroscope != topo_pb.HardwareFeatures.Gyroscope():
        result.gyroscope = copy.accelerometer_gyroscope_magnetometer.hardware_feature.gyroscope

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.magnetometer != topo_pb.HardwareFeatures.Magnetometer():
        result.magnetometer = copy.accelerometer_gyroscope_magnetometer.hardware_feature.magnetometer

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.light_sensor != topo_pb.HardwareFeatures.LightSensor():
        result.light_sensor = copy.accelerometer_gyroscope_magnetometer.hardware_feature.light_sensor

    # Handle all possible fingerprint hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.fingerprint.hardware_feature.fw_config)

    if copy.fingerprint.hardware_feature.fingerprint != topo_pb.HardwareFeatures.Fingerprint():
        result.fingerprint = copy.fingerprint.hardware_feature.fingerprint

    # Handle all possible proximity sensor hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.proximity_sensor.hardware_feature.fw_config)

    # Handle all possible daughter board hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.daughter_board.hardware_feature.fw_config)

    if copy.daughter_board.hardware_feature.usb_c != topo_pb.HardwareFeatures.UsbC():
        _accumulate_usbc(result.usb_c, copy.daughter_board.hardware_feature.usb_c)

    if copy.daughter_board.hardware_feature.usb_a != topo_pb.HardwareFeatures.UsbA():
        _accumulate_usba(result.usb_a, copy.daughter_board.hardware_feature.usb_a)

    if copy.daughter_board.hardware_feature.lte != topo_pb.HardwareFeatures.Lte():
        _accumulate_lte(result.lte, copy.daughter_board.hardware_feature.lte)

    if copy.daughter_board.hardware_feature.hdmi != topo_pb.HardwareFeatures.Hdmi():
        _accumulate_hdmi(result.hdmi, copy.daughter_board.hardware_feature.hdmi)

    # Handle all possible non volatile storage hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.non_volatile_storage.hardware_feature.fw_config)

    if copy.non_volatile_storage.hardware_feature.storage != topo_pb.HardwareFeatures.Storage():
        result.storage = copy.non_volatile_storage.hardware_feature.storage

    # Handle all possible ram hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.ram.hardware_feature.fw_config)

    if copy.ram.hardware_feature.memory != topo_pb.HardwareFeatures.Memory():
        result.memory = copy.ram.hardware_feature.memory

    # Handle all possible wifi hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.wifi.hardware_feature.fw_config)

    # Handle all possible lte board attributes
    _accumulate_fw_config(result.fw_config, copy.lte_board.hardware_feature.fw_config)

    if copy.lte_board.hardware_feature.lte != topo_pb.HardwareFeatures.Lte():
        result.lte.present = _accumulate_presence(result.lte.present, copy.lte_board.hardware_feature.lte.present)

    # Handle all possible sd reader hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.sd_reader.hardware_feature.fw_config)

    # Handle all possible motherboard usb features attributes
    _accumulate_fw_config(result.fw_config, copy.motherboard_usb.hardware_feature.fw_config)

    if copy.motherboard_usb.hardware_feature.usb_c != topo_pb.HardwareFeatures.UsbC():
        _accumulate_usbc(result.usb_c, copy.motherboard_usb.hardware_feature.usb_c)

    if copy.motherboard_usb.hardware_feature.usb_a != topo_pb.HardwareFeatures.UsbA():
        _accumulate_usba(result.usb_a, copy.motherboard_usb.hardware_feature.usb_a)

    # Handle all possible bluetooth features attributes
    _accumulate_fw_config(result.fw_config, copy.bluetooth.hardware_feature.fw_config)

    if copy.bluetooth.hardware_feature.bluetooth != topo_pb.HardwareFeatures.Bluetooth():
        result.bluetooth = copy.bluetooth.hardware_feature.bluetooth

    # Handle all possible barreljack features
    _accumulate_fw_config(result.fw_config, copy.barreljack.hardware_feature.fw_config)

    if copy.barreljack.hardware_feature.barreljack != topo_pb.HardwareFeatures.BarrelJack():
        result.barreljack = copy.barreljack.hardware_feature.barreljack
    return result

hw_topo = struct(
    create_design_features = _create_design_features,
    create_features = _create_features,
    create_screen = _create_screen,
    create_form_factor = _create_form_factor,
    create_audio = _create_audio,
    create_stylus = _create_stylus,
    create_keyboard = _create_keyboard,
    create_thermal = _create_thermal,
    create_camera = _create_camera,
    create_sensor = _create_sensor,
    create_fingerprint = _create_fingerprint,
    create_proximity_sensor = _create_proximity_sensor,
    create_daughter_board = _create_daughter_board,
    create_non_volatile_storage = _create_non_volatile_storage,
    create_ram = _create_ram,
    create_wifi = _create_wifi,
    create_lte_board = _create_lte_board,
    create_sd_reader = _create_sd_reader,
    create_motherboard_usb = _create_motherboard_usb,
    create_bluetooth = _create_bluetooth,
    create_barreljack = _create_barreljack,
    create_hardware_topology = _create_hardware_topology,
    create_power_button = _create_power_button,
    create_volume_button = _create_volume_button,
    convert_to_hw_features = _convert_to_hw_features,
    make_fw_config = _make_fw_config,
    ff = _FF,
    audio_codec = _AUDIO_CODEC,
    memory = _MEMORY,
    fp_loc = _FP_LOC,
    storage = _STORAGE,
    kb_type = _KB_TYPE,
    stylus = _STYLUS,
    region = _REGION,
    edge = _EDGE,
)
