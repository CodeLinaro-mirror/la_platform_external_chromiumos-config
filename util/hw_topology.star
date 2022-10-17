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
load("//config/util/hw_features.star", "hw_feat")

_HW_FEAT = topo_pb.HardwareFeatures

_PRESENT = struct(
    UNKNOWN = _HW_FEAT.PRESENT_UNKNOWN,
    PRESENT = _HW_FEAT.PRESENT,
    NOT_PRESENT = _HW_FEAT.NOT_PRESENT,
)

_AUDIO_CODEC = struct(
    RT5682 = _HW_FEAT.Audio.RT5682,
    ALC5682I = _HW_FEAT.Audio.ALC5682I,
    ALC5682 = _HW_FEAT.Audio.ALC5682,
    DA7219 = _HW_FEAT.Audio.DA7219,
    NAU88L25B = _HW_FEAT.Audio.NAU88L25B,
    CS42L42 = _HW_FEAT.Audio.CS42L42,
    ALC5682IVS = _HW_FEAT.Audio.ALC5682IVS,
    WCD9385 = _HW_FEAT.Audio.WCD9385,
)

_AMPLIFIER = struct(
    MAX98357 = _HW_FEAT.Audio.MAX98357,
    MAX98373 = _HW_FEAT.Audio.MAX98373,
    MAX98360 = _HW_FEAT.Audio.MAX98360,
    RT1015 = _HW_FEAT.Audio.RT1015,
    ALC1011 = _HW_FEAT.Audio.ALC1011,
    RT1015P = _HW_FEAT.Audio.RT1015P,
    ALC1019 = _HW_FEAT.Audio.ALC1019,
    MAX98390 = _HW_FEAT.Audio.MAX98390,
    MAX98396 = _HW_FEAT.Audio.MAX98396,
    CS35L41 = _HW_FEAT.Audio.CS35L41,
)

_CELLULAR = struct(
    NOT_PRESENT = _HW_FEAT.Cellular.NOT_PRESENT,
    CELLULAR_LTE = _HW_FEAT.Cellular.CELLULAR_LTE,
    CELLULAR_5G = _HW_FEAT.Cellular.CELLULAR_5G,
)

_FP_LOC = struct(
    NOT_PRESENT = _HW_FEAT.Fingerprint.NOT_PRESENT,
    POWER_BUTTON_TOP_LEFT = _HW_FEAT.Fingerprint.POWER_BUTTON_TOP_LEFT,
    KEYBOARD_BOTTOM_LEFT = _HW_FEAT.Fingerprint.KEYBOARD_BOTTOM_LEFT,
    KEYBOARD_BOTTOM_RIGHT = _HW_FEAT.Fingerprint.KEYBOARD_BOTTOM_RIGHT,
    KEYBOARD_TOP_RIGHT = _HW_FEAT.Fingerprint.KEYBOARD_TOP_RIGHT,
    RIGHT_SIDE = _HW_FEAT.Fingerprint.RIGHT_SIDE,
    LEFT_SIDE = _HW_FEAT.Fingerprint.LEFT_SIDE,
    LEFT_OF_POWER_BUTTON_TOP_RIGHT = _HW_FEAT.Fingerprint.LEFT_OF_POWER_BUTTON_TOP_RIGHT,
)

_STORAGE = struct(
    UNKNOWN = comp_pb.Component.Storage.STORAGE_TYPE_UNKNOWN,
    EMMC = comp_pb.Component.Storage.EMMC,
    NVME = comp_pb.Component.Storage.NVME,
    SATA = comp_pb.Component.Storage.SATA,
    UFS = comp_pb.Component.Storage.UFS,
)

_KB_TYPE = struct(
    NONE = _HW_FEAT.Keyboard.NONE,
    INTERNAL = _HW_FEAT.Keyboard.INTERNAL,
    DETACHABLE = _HW_FEAT.Keyboard.DETACHABLE,
)

_KB_MCU_TYPE = struct(
    NONE = _HW_FEAT.Keyboard.KEYBOARD_MCU_NOT_PRESENT,
    MCU_PRISM = _HW_FEAT.Keyboard.KEYBOARD_MCU_PRISM,
)

_STYLUS = struct(
    NONE = _HW_FEAT.Stylus.NONE,
    INTERNAL = _HW_FEAT.Stylus.INTERNAL,
    EXTERNAL = _HW_FEAT.Stylus.EXTERNAL,
)

_REGION = struct(
    SCREEN = _HW_FEAT.Button.SCREEN,
    KEYBOARD = _HW_FEAT.Button.KEYBOARD,
)

_EDGE = struct(
    LEFT = _HW_FEAT.Button.LEFT,
    RIGHT = _HW_FEAT.Button.RIGHT,
    TOP = _HW_FEAT.Button.TOP,
    BOTTOM = _HW_FEAT.Button.BOTTOM,
)

_CAMERA_FLAGS = struct(
    SUPPORT_1080P = _HW_FEAT.Camera.FLAGS_SUPPORT_1080P,
    SUPPORT_AUTOFOCUS = _HW_FEAT.Camera.FLAGS_SUPPORT_AUTOFOCUS,
)

_EC_TYPE = struct(
    UNKNOWN = _HW_FEAT.EmbeddedController.EC_TYPE_UNKNOWN,
    CHROME = _HW_FEAT.EmbeddedController.EC_CHROME,
    WILCO = _HW_FEAT.EmbeddedController.EC_WILCO,
)

_TPM_TYPE = struct(
    UNKNOWN = _HW_FEAT.TrustedPlatformModule.TPM_TYPE_UNKNOWN,
    THIRD_PARTY = _HW_FEAT.TrustedPlatformModule.THIRD_PARTY,
    GSC_H1B = _HW_FEAT.TrustedPlatformModule.GSC_H1B,
    GSC_H1D = _HW_FEAT.TrustedPlatformModule.GSC_H1D,
)

_PORT_POSITION = struct(
    LEFT = _HW_FEAT.LEFT,
    RIGHT = _HW_FEAT.RIGHT,
    BACK = _HW_FEAT.BACK,
    FRONT = _HW_FEAT.FRONT,
)

_AUDIO_CONFIG_STRUCTURE = struct(
    NONE = _HW_FEAT.Audio.AUDIO_CONFIG_STRUCTURE_NONE,
    DESIGN = _HW_FEAT.Audio.DESIGN,
    COMMON = _HW_FEAT.Audio.COMMON,
)

_RECOVERY_INPUT = struct(
    UNKNOWN = _HW_FEAT.FormFactor.RECOVERY_INPUT_UNKNOWN,
    KEYBOARD = _HW_FEAT.FormFactor.KEYBOARD,
    POWER_BUTTON = _HW_FEAT.FormFactor.POWER_BUTTON,
    RECOVERY_BUTTON = _HW_FEAT.FormFactor.RECOVERY_BUTTON,
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

def _make_fw_config(mask, id, coreboot_customizations = None):
    """Builds a HardwareFeatures.FirmwareConfiguration proto.

    Takes a 32-bit mask for the field and an id. Shifts the id
    into the mask region and checks that the value fits within the bit mask.
    """
    lsb_bit_set = (~mask + 1) & mask
    shifted_id = id * lsb_bit_set
    if shifted_id & mask != shifted_id:
        fail("Specified id %d out of range [0, %d]" % (id, mask // lsb_bit_set))

    return _HW_FEAT.FirmwareConfiguration(
        value = shifted_id,
        mask = mask,
        coreboot_customizations = coreboot_customizations,
    )

def _accumulate_fw_config(existing_fw_config, new_fw_config):
    """Adds fw config to existing fw config."""
    if existing_fw_config.mask & new_fw_config.mask:
        fail("FW_CONFIG masks cannot overlap! 0x%x and 0x%x" %
             (existing_fw_config.mask, new_fw_config.mask))

    existing_fw_config.value += new_fw_config.value
    existing_fw_config.mask += new_fw_config.mask
    existing_fw_config.coreboot_customizations += new_fw_config.coreboot_customizations

def _accumulate_fw_configs(result_hw_features, fw_configs):
    for fw_config in fw_configs:
        _accumulate_fw_config(result_hw_features.fw_config, fw_config)

def _create_design_features(form_factor = hw_feat.form_factor.CLAMSHELL):
    """Builds a HardwareFeatures proto with form_factor."""
    return _HW_FEAT(
        form_factor = _HW_FEAT.FormFactor(
            form_factor = form_factor,
        ),
    )

_DEFAULT_FF = [hw_feat.form_factor.CLAMSHELL, hw_feat.form_factor.CONVERTIBLE]

def _create_features(form_factors = _DEFAULT_FF):
    """Builds a HardwareFeatures proto for each of form_factors."""
    return [_create_design_features(ff) for ff in form_factors]

def _bool_to_present(value):
    """Returns correct value of present enum depending on value"""
    if value == None:
        return _PRESENT.UNKNOWN
    elif value:
        return _PRESENT.PRESENT
    else:
        return _PRESENT.NOT_PRESENT

def _create_screen(
        id = None,
        description = None,
        inches = 0,
        width_px = None,
        height_px = None,
        pixels_per_in = None,
        touch = False,
        no_als_battery_brightness = None,
        no_als_battery_brightness_nits = None,
        no_als_ac_brightness = None,
        no_als_ac_brightness_nits = None,
        max_brightness_nits = None,
        min_visible_backlight_level = None,
        turn_off_screen_timeout_ms = None,
        als_steps = None,
        fw_configs = [],
        seamless_refresh_rate_switching = False):
    """Builds a Topology proto for a screen."""
    hw_features = _HW_FEAT()

    if no_als_battery_brightness and no_als_battery_brightness_nits:
        fail("no_als_battery_brightness: Specify percentage or nits, not both")
    if no_als_ac_brightness and no_als_ac_brightness_nits:
        fail("no_als_ac_brightness: Specify percentage or nits, not both")

    if (no_als_battery_brightness_nits or no_als_ac_brightness_nits) and not max_brightness_nits:
        fail("max_brightness_nits must be specified when using " +
             "no_als_battery_brightness_nits or no_als_ac_brightness_nits.")

    if als_steps:
        for step in als_steps:
            if (step.battery_backlight_nits or step.ac_backlight_nits) and not max_brightness_nits:
                fail("max_brightness_nits must be specified when using " +
                     "AlsStep with battery_backlight_nits or " +
                     "ac_backlight_nits.")
            else:
                step.max_screen_brightness = max_brightness_nits

    if max_brightness_nits:
        # The default battery brightnesses can be assumed to be 80 nits if omitted.
        if not no_als_battery_brightness and not no_als_battery_brightness_nits:
            no_als_battery_brightness_nits = 80

    hw_features.screen.panel_properties = comp_pb.Component.DisplayPanel.Properties(
        diagonal_milliinch = inches * 1000,
        width_px = width_px,
        height_px = height_px,
        pixels_per_in = pixels_per_in,
    )
    hw_features.screen.touch_support = _bool_to_present(touch)
    hw_features.screen.panel_properties.no_als_battery_brightness = no_als_battery_brightness
    hw_features.screen.panel_properties.no_als_battery_brightness_nits = no_als_battery_brightness_nits
    hw_features.screen.panel_properties.no_als_ac_brightness = no_als_ac_brightness
    hw_features.screen.panel_properties.no_als_ac_brightness_nits = no_als_ac_brightness_nits
    hw_features.screen.panel_properties.min_visible_backlight_level = min_visible_backlight_level
    hw_features.screen.panel_properties.als_steps = als_steps
    hw_features.screen.panel_properties.max_screen_brightness = max_brightness_nits
    if turn_off_screen_timeout_ms != None:
        hw_features.screen.panel_properties.turn_off_screen_timeout_ms.value = turn_off_screen_timeout_ms

    _accumulate_fw_configs(hw_features, fw_configs)

    if touch:
        screen_id = id if id else "TOUCHSCREEN"
        screen_desc = description if description else "Touchscreen"
    else:
        screen_id = id if id else "SCREEN"
        screen_desc = description if description else "Default screen"

    if seamless_refresh_rate_switching:
        hw_features.screen.panel_properties.features.append(comp_pb.Component.DisplayPanel.SEAMLESS_REFRESH_RATE_SWITCHING)

    return topo_pb.Topology(
        id = screen_id,
        type = topo_pb.Topology.SCREEN,
        description = {"EN": screen_desc},
        hardware_feature = hw_features,
    )

def _create_als_step(
        lux_decrease_threshold,
        lux_increase_threshold,
        ac_backlight_percent = None,
        battery_backlight_percent = None,
        ac_backlight_nits = None,
        battery_backlight_nits = None):
    """Builds a Component.AlsStep.

    Args:
    lux_decrease_threshold: An int containing the sensor value below which the
        previous step should be considered. A value of None indicates negative
        infinity.
    lux_increase_threshold: An int containing the sensor value above which the
        next step should be considered. A value of None indicates infinity.
    ac_backlight_percent: A double containing the backlight brightness
        percentage to use at this step while on AC power. One of
        ac_backlight_percent or ac_backlight_nits must be set.
    ac_backlight_nits: A double containing the backlight brightess in nits to
        use at this step while on AC power. One of ac_backlight_percent or
        ac_backlight_nits must be set.
    battery_backlight_percent: A double containing the backlight brightness
        percentage to use at this step while on battery power. If unset,
        defaults to the ac_backlight_percent value. Only oen of
        battery_backlight_percent or backlight_battery_nits can be set.
    battery_backlight_nits: A double containing the backlight brighness in nits
        to use at this step while on battery power. If unset, defaults to the
        ac_backlight_nits value. Only one of battery_backlight_percent or
        battery_backlight_nits can be set.
    """
    if ac_backlight_percent and ac_backlight_nits:
        fail("ac_backlight: Specify percentage or nits, not both")
    if not ac_backlight_percent and not ac_backlight_nits:
        fail("One of ac_backlight_percent and ac_backlight_nits must be set")
    if battery_backlight_percent and battery_backlight_nits:
        fail("battery_backlight: Specify percentage or nits, not both")

    step = comp_pb.Component.AlsStep()
    step.lux_increase_threshold = lux_increase_threshold if lux_increase_threshold != None else -1
    step.lux_decrease_threshold = lux_decrease_threshold if lux_decrease_threshold != None else -1
    step.ac_backlight_percent = ac_backlight_percent
    step.ac_backlight_nits = ac_backlight_nits
    if battery_backlight_percent != None:
        step.battery_backlight_percent = battery_backlight_percent
    else:
        step.battery_backlight_percent = step.ac_backlight_percent
    if battery_backlight_nits != None:
        step.battery_backlight_nits = battery_backlight_nits
    else:
        step.battery_backlight_nits = step.ac_backlight_nits
    return step

def _create_form_factor(form_factor, recovery_input = None, fw_configs = [], id = None, description = None):
    """Builds a Topology proto for a form factor.

    Args:
        form_factor: A FormFactorType enum. Required.
        recovery_input: A RecoveryInputType enum. Will be auto-generated if not specified.
        fw_configs: A list of FirmwareConfiguration protos for the form factor.
        id: A string identifier for the Topology. If not passed, a default is
            provided based on form_factor.
        description: An English description for the Topology. If not passed, a
            default is provided based on form_factor.
    """
    if not id:
        id = {
            hw_feat.form_factor.CLAMSHELL: "CLAMSHELL",
            hw_feat.form_factor.CONVERTIBLE: "CONVERTIBLE",
            hw_feat.form_factor.CHROMEBASE: "CHROMEBASE",
            hw_feat.form_factor.CHROMEBOX: "CHROMEBOX",
            hw_feat.form_factor.DETACHABLE: "DETACHABLE",
            hw_feat.form_factor.CHROMESLATE: "CHROMESLATE",
        }[form_factor]

    if not description:
        description = {
            hw_feat.form_factor.CLAMSHELL: "Device cannot rotate past 180 degrees",
            hw_feat.form_factor.CONVERTIBLE: "Device can rotate 360 degrees",
            hw_feat.form_factor.CHROMEBASE: "Desktop chrome all-in-one.",
            hw_feat.form_factor.CHROMEBOX: "Desktop chrome device.",
            hw_feat.form_factor.DETACHABLE: "Device can detach from its keyboard.",
            hw_feat.form_factor.CHROMESLATE: "Tablet chrome device.",
        }[form_factor]

    if not recovery_input:
        recovery_input = {
            hw_feat.form_factor.CLAMSHELL: hw_feat.recovery_input.KEYBOARD,
            hw_feat.form_factor.CONVERTIBLE: hw_feat.recovery_input.KEYBOARD,
            hw_feat.form_factor.DETACHABLE: hw_feat.recovery_input.POWER_BUTTON,
            hw_feat.form_factor.CHROMEBASE: hw_feat.recovery_input.RECOVERY_BUTTON,
            hw_feat.form_factor.CHROMEBOX: hw_feat.recovery_input.RECOVERY_BUTTON,
            hw_feat.form_factor.CHROMEBIT: hw_feat.recovery_input.RECOVERY_BUTTON,
            hw_feat.form_factor.CHROMESLATE: hw_feat.recovery_input.POWER_BUTTON,
        }[form_factor]

    hw_features = _HW_FEAT()

    hw_features.form_factor.form_factor = form_factor
    hw_features.form_factor.recovery_input = recovery_input

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.FORM_FACTOR,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_audio_card_config(
        card_name,
        ucm_suffix = None,
        cras_config = _AUDIO_CONFIG_STRUCTURE.DESIGN,
        ucm_config = _AUDIO_CONFIG_STRUCTURE.DESIGN,
        sound_card_init_config = _AUDIO_CONFIG_STRUCTURE.NONE):
    """Builds a CardConfig proto for an audio card config.

    Args:
        card_name: A string. This should match the card used by ALSA, with an
            optional suffix starting with a dot, if a suffix representing
            hardware details, such as the speaker amplifier or jack codec is
            required. For example, "sof-rt5682.max98373".
        ucm_suffix: An optional format string used to generate the remainder of
            the UCM suffix not referring to audio components. If unset, the
            program-wide default suffix is used. The following placeholders
            may be used:
                {design}: The design name.
                {camera_count}: The number of cameras (usually 0, 1 or 2).
                {headset_codec}: The headset codec name (in lowercase)
                    specified in the topology containing this card config.
                {speaker_amp}: The speaker amp name (in lowercase) specified in
                    the topology containing this card config.
                {mic_description}: A description of the microphone topology, of
                    the form {user_facing_mic_count}uf{world_facing_mic_count}wf, with
                    components elided if their count is 0.
                {total_mic_count}: The total number of internal microphones.
                {user_facing_mic_count}: The number of internal user-facing microphones.
                {world_facing_mic_count}: The number of internal world-facing microphones.
            It is strongly recommended that any details of the speaker
            amplifier or jack codec not be included in this suffix - they
            should instead be included as part of card_name.
        cras_config: An AudioConfigStructure enum specifying how cras config
            files are structured for this card. If unset, defaults to DESIGN.
        ucm_config: An AudioConfigStructure enum specifying how ALSA UCM config
            files are structured for this card. If unset, defaults to DESIGN.
        sound_card_init_config: An AudioConfigStructure enum specifying how
            sound card init config files are structured for this card. If unset,
            defaults to NONE.
    """
    if ucm_config == _AUDIO_CONFIG_STRUCTURE.NONE:
        fail("ucm_config cannot be NONE.")

    config = _HW_FEAT.Audio.CardConfig(
        card_name = card_name,
        sound_card_init_config = sound_card_init_config,
        cras_config = cras_config,
        ucm_config = ucm_config,
    )
    if ucm_suffix != None:
        config.ucm_suffix.value = ucm_suffix
    return config

def _create_audio(
        id,
        description,
        codec = None,
        speaker_amp = None,
        headphone_codec = None,
        fw_configs = [],
        card_configs = [],
        cras_config = None):
    """Builds a Topology proto for audio.

    Args:
        id: A string identifier for the Topology.
        description: An English description for the Topology.
        codec: Deprecated.
        speaker_amp: An Amplifier enum value specifying the speaker amplifier.
        headphone_codec: An AudioCodec enum value specifying the jack codec.
        fw_configs: A list of FirmwareConfiguration protos for this audio
            topology.
        card_configs: A list of CardConfig protos specifying card configs to be
            installed and used for this audio topology.
        cras_config: An AudioConfigStructure enum specifying how card-agnostic
            cras config files are structured. If unset, defaults to
            DESIGN if any card_configs are passed, otherwise NONE.
    """
    hw_features = _HW_FEAT()

    if codec:
        hw_features.audio.audio_codec = codec
    if speaker_amp:
        hw_features.audio.speaker_amp = speaker_amp
    if headphone_codec:
        hw_features.audio.headphone_codec = headphone_codec
    if card_configs:
        hw_features.audio.card_configs = card_configs
    if cras_config != None:
        hw_features.audio.cras_config = cras_config
    elif card_configs:
        hw_features.audio.cras_config = _AUDIO_CONFIG_STRUCTURE.DESIGN

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.AUDIO,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _override_audio(
        source_topo,
        fw_configs = None,
        ucm_suffix = None,
        cras_config = None,
        ucm_config = None,
        sound_card_init_config = None):
    if source_topo.type != topo_pb.Topology.AUDIO:
        fail("Invalid audio topology")

    topo = proto.clone(source_topo)
    hw_features = topo.hardware_feature
    if fw_configs != None:
        hw_features.fw_config = _HW_FEAT.FirmwareConfiguration()
        _accumulate_fw_configs(hw_features, fw_configs)
    for card_config in hw_features.audio.card_configs:
        if ucm_config != None:
            if ucm_config == _AUDIO_CONFIG_STRUCTURE.NONE:
                fail("ucm_config cannot be NONE.")
            card_config.ucm_config = ucm_config
        if ucm_suffix != None:
            card_config.ucm_suffix.value = ucm_suffix
        if cras_config != None:
            card_config.cras_config = cras_config
        if sound_card_init_config != None:
            card_config.sound_card_init_config = sound_card_init_config
    if cras_config != None:
        hw_features.audio.cras_config = cras_config
    return topo

def _create_stylus(id, description, stylus_type, fw_configs = []):
    """Builds a Topology proto for a stylus."""
    hw_features = _HW_FEAT()

    hw_features.stylus.stylus = stylus_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.STYLUS,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_keyboard(backlight, pwr_btn_present, kb_type, numpad_present = False, fw_configs = [], id = None, description = None, backlight_user_steps = None, mcu_type = _KB_MCU_TYPE.NONE):
    """Builds a Topology proto for a keyboard.

    Args:
        backlight: True if a backlight is present. Required.
        pwr_btn_present: True if a power button is present. Required.
        kb_type: A KeyboardType enum. Required.
        numpad_present: True if numeric pad is present.
        fw_configs: A list of FirmwareConfiguration protos for the form factor.
        id: A string identifier for the Topology. If not passed, a default is
            provided.
        description: An English description for the Topology. If not passed, a
            default is provided.
        backlight_user_steps: A list of doubles specifying the user-selectable
            backlight steps in increasing order, starting from 0. This controls
            the keyboard_backlight_user_steps powerd pref.
        mcu_type: A KeyboardMcuType enum. Optional.
    """

    if not id:
        id = "KB_{backlight}".format(
            backlight = "BL" if backlight else "NO_BL",
        )

    if not description:
        # Starlark doesn't seem to have a way to find the enum name with
        # reflection.
        if kb_type == _HW_FEAT.Keyboard.INTERNAL:
            type_str = "Internal"
        elif kb_type == _HW_FEAT.Keyboard.DETACHABLE:
            type_str = "Detachable"
        else:
            type_str = "Unknown type"

        description = "{type} keyboard {backlight} backlight".format(
            type = type_str,
            backlight = "with" if backlight else "without",
        )

    hw_features = _HW_FEAT()

    hw_features.keyboard.keyboard_type = kb_type
    hw_features.keyboard.backlight = _bool_to_present(backlight)
    hw_features.keyboard.power_button = _bool_to_present(pwr_btn_present)
    hw_features.keyboard.numeric_pad = _bool_to_present(numpad_present)
    hw_features.keyboard.backlight_user_steps = backlight_user_steps
    hw_features.keyboard.mcu_type = mcu_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.KEYBOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_thermal(id, description, fw_configs = []):
    """Builds a Topology proto for thermal."""
    hw_features = _HW_FEAT()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.THERMAL,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _make_camera_device(
        interface,
        facing,
        orientation,
        flags,
        ids,
        privacy_switch_present = None,
        microphone_count = None,
        detachable = False):
    """Builds a HardwareFeatures.Camera.Device proto."""
    camera_pb = _HW_FEAT.Camera
    device = camera_pb.Device()

    device.interface = {
        "usb": camera_pb.INTERFACE_USB,
        "mipi": camera_pb.INTERFACE_MIPI,
    }[interface]
    device.facing = {
        "back": camera_pb.FACING_BACK,
        "front": camera_pb.FACING_FRONT,
    }[facing]
    device.orientation = {
        0: camera_pb.ORIENTATION_0,
        90: camera_pb.ORIENTATION_90,
        180: camera_pb.ORIENTATION_180,
        270: camera_pb.ORIENTATION_270,
    }[orientation]
    device.flags = flags
    device.ids = ids

    if privacy_switch_present:
        device.privacy_switch = _bool_to_present(privacy_switch_present)

    if microphone_count != None:
        device.microphone_count.value = microphone_count

    device.detachable = detachable

    return device

def _create_camera(
        id,
        description,
        fw_configs = [],
        camera_devices = []):
    """Builds a Topology proto for cameras.

    Args:
        id: A string identifier for the Topology.
        description: An English description for the Topology.
        fw_configs: A list of FirmwareConfiguration protos for the form factor.
        camera_devices: A list of HardwareFeatures.Camera.Device protos.
    """
    hw_features = _HW_FEAT()

    camera = hw_features.camera
    camera.devices = camera_devices

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
        base_magno_present = None,
        lid_light_present = None,
        base_light_present = None):
    """Builds a Topology proto for accelerometer/gyroscrope/magnometer sensors."""
    hw_features = _HW_FEAT()

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

    if lid_light_present:
        hw_features.light_sensor.lid_lightsensor = _bool_to_present(lid_light_present)

    if base_light_present:
        hw_features.light_sensor.base_lightsensor = _bool_to_present(base_light_present)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.ACCELEROMETER_GYROSCOPE_MAGNETOMETER,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_fingerprint(id, description, location, board = None, fw_configs = []):
    """Builds a Topology proto for a fingerprint reader."""
    hw_features = _HW_FEAT()

    hw_features.fingerprint.location = location
    if board:
        hw_features.fingerprint.board = board
        if board == "bloonchipper":
            hw_features.fingerprint.ro_version = "bloonchipper_v2.0.5938-197506c1"

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.FINGERPRINT,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_hps(id, description, present = False, fw_configs = []):
    """Builds a Topology proto for HPS."""
    hw_features = _HW_FEAT()

    hw_features.hps.present = _bool_to_present(present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.HPS,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_dp_converter(id, description, names = []):
    """Builds a Topology proto for DisplayPort converters."""
    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.DP_CONVERTER,
        description = {"EN": description},
        hardware_feature = _HW_FEAT(
            dp_converter = _HW_FEAT.DisplayPortConverter(
                converters = [
                    comp_pb.Component.DisplayPortConverter(name = name)
                    for name in names
                ],
            ),
        ),
    )

def _create_poe(id, description, present = False, fw_configs = []):
    """Builds a Topology proto for PoE."""
    hw_features = _HW_FEAT()

    hw_features.poe.present = _bool_to_present(present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.POE,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_proximity_sensor(id, description, fw_configs = []):
    """Builds a Topology proto for a proximity sensor."""
    hw_features = _HW_FEAT()

    hw_features.proximity = {}

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.PROXIMITY_SENSOR,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_hdmi(id, description, fw_configs = []):
    """Builds a Topology proto for HDMI."""
    hw_features = _HW_FEAT()

    _accumulate_fw_configs(hw_features, fw_configs)

    hw_features.hdmi.present = _PRESENT.PRESENT

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.HDMI,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_daughter_board(
        id,
        description,
        fw_configs = [],
        usbc_count = 0,
        usba_count = 0,
        usb4 = False,
        defer_external_display_timeout = None,
        cellular_support = False,
        cellular_model = None,
        cellular_type = _CELLULAR.NOT_PRESENT,
        cellular_dynamic_power_reduction_config = None,
        hdmi_support = False,
        side = None,
        usbc_ports = None):
    """Builds a Topology proto for a daughter board."""
    hw_features = _HW_FEAT()

    _accumulate_fw_configs(hw_features, fw_configs)

    hw_features.usb_c = _build_usbc(
        side,
        usbc_ports,
        usbc_count,
        usb4,
        defer_external_display_timeout,
    )
    hw_features.usb_a.count.value = usba_count

    hw_features.cellular.present = _bool_to_present(cellular_support)
    hw_features.cellular.model = cellular_model
    hw_features.cellular.type = cellular_type
    hw_features.cellular.dynamic_power_reduction_config = cellular_dynamic_power_reduction_config

    hw_features.hdmi.present = _bool_to_present(hdmi_support)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.DAUGHTER_BOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_non_volatile_storage(id, description, storage_type, fw_configs = []):
    """Builds a Topology proto for non-volatile storage."""
    hw_features = _HW_FEAT()

    hw_features.storage.storage_type = storage_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.NON_VOLATILE_STORAGE,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_wifi(id, description, fw_configs = [], wifi_config = None):
    """Builds a Topology proto for a WiFi chip."""
    hw_features = _HW_FEAT()

    if wifi_config:
        hw_features.wifi.wifi_config = wifi_config

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.WIFI,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_cellular_board(
        id,
        description,
        present,
        type = _CELLULAR.NOT_PRESENT,
        fw_configs = [],
        model = None,
        attach_apn_required = None,
        dynamic_power_reduction_config = None):
    """Builds a Topology proto for a Cellular board."""
    hw_features = _HW_FEAT()

    hw_features.cellular.present = _bool_to_present(present)
    hw_features.cellular.model = model
    hw_features.cellular.type = type
    hw_features.cellular.attach_apn_required = attach_apn_required
    hw_features.cellular.dynamic_power_reduction_config = dynamic_power_reduction_config

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.CELLULAR_BOARD,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _make_cellular_dynamic_power_reduction_config(
        gpio = None,
        modem_manager = False,
        tablet_mode = None):
    """Builds a configuration for cellular dynamic power reduction."""
    config = _HW_FEAT.Cellular.DynamicPowerReductionConfig()

    if gpio != None:
        config.gpio = gpio
    elif modem_manager:
        config.modem_manager = True
    else:
        fail("A Cellular.DynamicPowerReductionConfig must configure a GPIO or the use of modem manager.")

    if tablet_mode:
        config.tablet_mode.value = tablet_mode
    return config

def _create_sd_reader(id, description, fw_configs = []):
    """Builds a Topology proto for a SD reader."""
    hw_features = _HW_FEAT()

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.SD_READER,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

_USB_PORT_POSITIONS = {
    _PORT_POSITION.LEFT: {
        _PORT_POSITION.FRONT: _HW_FEAT.LEFT_FRONT,
        _PORT_POSITION.BACK: _HW_FEAT.LEFT_BACK,
        _HW_FEAT.UNKNOWN: _PORT_POSITION.LEFT,
    },
    _PORT_POSITION.RIGHT: {
        _PORT_POSITION.FRONT: _HW_FEAT.RIGHT_FRONT,
        _PORT_POSITION.BACK: _HW_FEAT.RIGHT_BACK,
        _HW_FEAT.UNKNOWN: _PORT_POSITION.RIGHT,
    },
    _PORT_POSITION.BACK: {
        _PORT_POSITION.LEFT: _HW_FEAT.BACK_LEFT,
        _PORT_POSITION.RIGHT: _HW_FEAT.BACK_RIGHT,
        _HW_FEAT.UNKNOWN: _PORT_POSITION.BACK,
    },
}

def _normalize_usbc_port(side, port):
    position = _USB_PORT_POSITIONS.get(side, {}).get(
        port.position,
        _HW_FEAT.UNKNOWN,
    )
    normalized_port = _HW_FEAT.UsbC.Port()
    normalized_port.position = position
    if proto.has(port, "index_override"):
        normalized_port.index_override = port.index_override
    return normalized_port

def _build_usbc(side, ports, count, usb4, defer_external_display_timeout):
    if ports != None:
        count = len(ports)
    else:
        ports = [_create_usbc_port()] * count

    result = _HW_FEAT.UsbC()
    result.usb4 = usb4
    result.count.value = count

    if defer_external_display_timeout:
        result.defer_external_display_timeout = defer_external_display_timeout

    if side:
        result.ports = [_normalize_usbc_port(side, port) for port in ports]
    return result

def _create_usbc_port(position = _HW_FEAT.UNKNOWN, index_override = None):
    """Builds a UsbC Port.

    Args:
        position: An optional _HW_FEAT.PortPosition indicating
            the position of this port on the side of the chassis it occupies.
            Required if more than one USB-C port is present on the same side of
            the chassis.
        index_override: An optional int specifying the 0-indexed index of this
            port. For ports with this unset, the motherboard ports will be
            ordered before the daughter board ports, in the order they are
            specified, leaving gaps as needed for ports with an override set.
            If set, this value must be in the range [0, number_of_usb_c_ports).
    """
    port = _HW_FEAT.UsbC.Port()
    port.position = position
    if index_override != None:
        port.index_override.value = index_override
    return port

def _create_motherboard_usb(
        id,
        description,
        fw_configs = [],
        usbc_count = 0,
        usba_count = 0,
        usb4 = False,
        defer_external_display_timeout = None,
        side = None,
        usbc_ports = None):
    """Builds a Topology proto for a motherboard."""
    hw_features = _HW_FEAT()

    _accumulate_fw_configs(hw_features, fw_configs)

    hw_features.usb_c = _build_usbc(
        side,
        usbc_ports,
        usbc_count,
        usb4,
        defer_external_display_timeout,
    )
    hw_features.usb_a.count.value = usba_count

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.MOTHERBOARD_USB,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_bluetooth(id, description, bt_component, fw_configs = [], present = True):
    """Builds a Topology proto for bluetooth."""
    hw_features = _HW_FEAT()

    hw_features.bluetooth.present = _bool_to_present(present)
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
    hw_features = _HW_FEAT()

    hw_features.barreljack.present = _bool_to_present(bj_present)

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.BARRELJACK,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_power_supply(id, description, bj_present = False, usb_min_ac_watts = None, fw_configs = []):
    """Builds a Topology proto for power supply.

    Args:
        id: A string identifier for the Topology.
        description: An English description for the Topology.
        bj_present: A bool containing whether a barreljack power port is present
        usb_min_ac_watts: The input power below which a warning should be shown
            to use a higher-power USB adapter.
        fw_configs: A list of firmware configs implied by the Topology.

    """
    hw_features = _HW_FEAT()

    hw_features.power_supply.barreljack = _bool_to_present(bj_present)

    if usb_min_ac_watts:
        hw_features.power_supply.usb_min_ac_watts = usb_min_ac_watts

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.POWER_SUPPLY,
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
        hardware_feature = _HW_FEAT(
            power_button = _HW_FEAT.Button(
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
        hardware_feature = _HW_FEAT(
            volume_button = _HW_FEAT.Button(
                region = region,
                edge = edge,
                position = position,
            ),
        ),
    )

def _create_ec(present = True, ec_type = _EC_TYPE.CHROME, id = None):
    """Builds a Topology proto for an embedded controller.

    Args:
        present: flag indicating whether the device has an EC at all
        ec_type: An EmbeddedControllerType enum
        id: A string identifier for the Topology. If not passed, a default is
            provided.
    """
    hw_features = _HW_FEAT()
    hw_features.embedded_controller.ec_type = ec_type
    hw_features.embedded_controller.present = _bool_to_present(present)

    return topo_pb.Topology(
        id = id or "ec",
        type = topo_pb.Topology.EC,
        hardware_feature = hw_features,
    )

# enumerate the common cases
_EC_NONE = _create_ec(present = False, ec_type = _EC_TYPE.UNKNOWN)
_EC_CHROME = _create_ec(ec_type = _EC_TYPE.CHROME)
_EC_WILCO = _create_ec(ec_type = _EC_TYPE.WILCO)

def _create_touch(id, description, fw_configs = [], touch_slop_distance = None):
    """Builds a Topology proto for touch."""
    hw_features = _HW_FEAT()
    if touch_slop_distance != None:
        hw_features.touch.touch_slop_distance.value = touch_slop_distance

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id,
        type = topo_pb.Topology.TOUCH,
        description = {"EN": description},
        hardware_feature = hw_features,
    )

def _create_tpm(tpm_type = _TPM_TYPE.GSC_H1B, id = None, fw_configs = []):
    """Builds a Topology proto for a trusted platform module.

    Args:
        tpm_type: A TrustedPlatformModuleType enum
        id: A string identifier for the Topology. If not passed, a default is
            provided.
        fw_configs: A list of FirmwareConfiguration protos for the tpm.
    """
    hw_features = _HW_FEAT()
    hw_features.trusted_platform_module.tpm_type = tpm_type

    _accumulate_fw_configs(hw_features, fw_configs)

    return topo_pb.Topology(
        id = id or "TPM",
        type = topo_pb.Topology.TPM,
        hardware_feature = hw_features,
    )

def _create_microphone_mute_switch(present = False):
    """Builds a Topology proto for an microphone mute switch.

    Args:
        present: flag indicating whether the device has an microphone mute
	         switch
    """
    hw_features = _HW_FEAT()
    hw_features.microphone_mute_switch.present = _bool_to_present(present)

    return topo_pb.Topology(
        id = "Default",
        type = topo_pb.Topology.MICROPHONE_MUTE_SWITCH,
        hardware_feature = hw_features,
    )

# enumerate the common cases
_TPM_THIRD_PARTY = _create_tpm(tpm_type = _TPM_TYPE.THIRD_PARTY)
_TPM_GSC_H1B = _create_tpm(tpm_type = _TPM_TYPE.GSC_H1B)
_TPM_GSC_H1D = _create_tpm(tpm_type = _TPM_TYPE.GSC_H1D)

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
        wifi = None,
        cellular_board = None,
        sd_reader = None,
        motherboard_usb = None,
        bluetooth = None,
        barreljack = None,
        power_supply = None,
        power_button = None,
        volume_button = None,
        ec = None,
        touch = None,
        tpm = None,
        microphone_mute_switch = None,
        hdmi = None,
        hps = None,
        dp_converter = None,
        poe = None):
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

    if wifi and wifi.type != topo_pb.Topology.WIFI:
        fail("Invalid wifi topology")

    if cellular_board and cellular_board.type != topo_pb.Topology.CELLULAR_BOARD:
        fail("Invalid cellular board topology")

    if sd_reader and sd_reader.type != topo_pb.Topology.SD_READER:
        fail("Invalid sd_reader topology")

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

    if ec and ec.type != topo_pb.Topology.EC:
        fail("Invalid ec type")

    if touch and touch.type != topo_pb.Topology.TOUCH:
        fail("Invalid touch topology")

    if tpm and tpm.type != topo_pb.Topology.TPM:
        fail("Invalid tpm type")

    if microphone_mute_switch and microphone_mute_switch.type != topo_pb.Topology.MICROPHONE_MUTE_SWITCH:
        fail("Invalid microphone mute switch type")

    if hdmi and hdmi.type != topo_pb.Topology.HDMI:
        fail("Invalid hdmi topology")

    if hps and hps.type != topo_pb.Topology.HPS:
        fail("Invalid hps topology")

    if dp_converter and dp_converter.type != topo_pb.Topology.DP_CONVERTER:
        fail("Invalid cp_converters topology")

    if poe and poe.type != topo_pb.Topology.POE:
        fail("Invalid PoE topology")

    if power_supply and power_supply.type != topo_pb.Topology.POWER_SUPPLY:
        fail("Invalid power supply topology")

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
        wifi = wifi,
        cellular_board = cellular_board,
        sd_reader = sd_reader,
        motherboard_usb = motherboard_usb,
        bluetooth = bluetooth,
        barreljack = barreljack,
        power_button = power_button,
        volume_button = volume_button,
        ec = ec,
        touch = touch,
        tpm = tpm,
        microphone_mute_switch = microphone_mute_switch,
        hdmi = hdmi,
        hps = hps,
        dp_converter = dp_converter,
        poe = poe,
        power_supply = power_supply,
    )

def _accumulate_presence(existing_present, new_present):
    if existing_present == _PRESENT.PRESENT:
        return existing_present
    elif new_present != _PRESENT.UNKNOWN:
        return new_present
    else:
        return existing_present

def _accumulate_usbc(existing_usbc, new_usbc):
    existing_usbc.count.value += new_usbc.count.value
    existing_usbc.usb4 = existing_usbc.usb4 or new_usbc.usb4
    existing_usbc.ports += new_usbc.ports

def _accumulate_usba(existing_usba, new_usba):
    existing_usba.count.value += new_usba.count.value

def _accumulate_cellular(existing_cellular, new_cellular):
    existing_cellular.present = _accumulate_presence(existing_cellular.present, new_cellular.present)
    if new_cellular.present == _PRESENT.PRESENT:
        existing_cellular.model = new_cellular.model
        existing_cellular.type = new_cellular.type
        existing_cellular.attach_apn_required = new_cellular.attach_apn_required
        if proto.has(new_cellular, "dynamic_power_reduction_config"):
            existing_cellular.dynamic_power_reduction_config = new_cellular.dynamic_power_reduction_config

def _accumulate_hdmi(existing_hdmi, new_hdmi):
    existing_hdmi.present = _accumulate_presence(existing_hdmi.present, new_hdmi.present)

def _convert_to_hw_features(hardware_topology):
    """Converts a HardwareTopology proto to a HardwareFeatures proto."""
    result = _HW_FEAT()

    # Need to make deep-copy otherwise we change the has_ message serialization
    copy = proto.from_textpb(hw_topo_pb.HardwareTopology, proto.to_textpb(hardware_topology))

    # Handle all possible screen hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.screen.hardware_feature.fw_config)

    if copy.screen.hardware_feature.screen != _HW_FEAT.Screen():
        result.screen = copy.screen.hardware_feature.screen

    # Handle all possible form factor hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.form_factor.hardware_feature.fw_config)

    if copy.form_factor.hardware_feature.form_factor != _HW_FEAT.FormFactor():
        result.form_factor = copy.form_factor.hardware_feature.form_factor

    # Handle all possible audio features attributes
    _accumulate_fw_config(result.fw_config, copy.audio.hardware_feature.fw_config)

    if copy.audio.hardware_feature.audio != _HW_FEAT.Audio():
        result.audio = copy.audio.hardware_feature.audio

    # Handle all possible stylus hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.stylus.hardware_feature.fw_config)

    if copy.stylus.hardware_feature.stylus != _HW_FEAT.Stylus():
        result.stylus = copy.stylus.hardware_feature.stylus

    # Handle all possible tpm features attributes
    _accumulate_fw_config(result.fw_config, copy.tpm.hardware_feature.fw_config)

    # Handle all possible keyboard hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.keyboard.hardware_feature.fw_config)

    if copy.keyboard.hardware_feature.keyboard != _HW_FEAT.Keyboard():
        result.keyboard = copy.keyboard.hardware_feature.keyboard

    # Handle all possible thermal features attributes
    _accumulate_fw_config(result.fw_config, copy.thermal.hardware_feature.fw_config)

    # Handle all possible camera features attributes
    _accumulate_fw_config(result.fw_config, copy.camera.hardware_feature.fw_config)

    if copy.camera.hardware_feature.camera != _HW_FEAT.Camera():
        result.camera = copy.camera.hardware_feature.camera

    # Handle all possible sensor attributes
    _accumulate_fw_config(result.fw_config, copy.accelerometer_gyroscope_magnetometer.hardware_feature.fw_config)

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.accelerometer != _HW_FEAT.Accelerometer():
        result.accelerometer = copy.accelerometer_gyroscope_magnetometer.hardware_feature.accelerometer

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.gyroscope != _HW_FEAT.Gyroscope():
        result.gyroscope = copy.accelerometer_gyroscope_magnetometer.hardware_feature.gyroscope

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.magnetometer != _HW_FEAT.Magnetometer():
        result.magnetometer = copy.accelerometer_gyroscope_magnetometer.hardware_feature.magnetometer

    if copy.accelerometer_gyroscope_magnetometer.hardware_feature.light_sensor != _HW_FEAT.LightSensor():
        result.light_sensor = copy.accelerometer_gyroscope_magnetometer.hardware_feature.light_sensor

    # Handle all possible fingerprint hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.fingerprint.hardware_feature.fw_config)

    if copy.fingerprint.hardware_feature.fingerprint != _HW_FEAT.Fingerprint():
        result.fingerprint = copy.fingerprint.hardware_feature.fingerprint

    # Handle all possible hps hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.hps.hardware_feature.fw_config)

    if copy.hps.hardware_feature.hps != _HW_FEAT.Hps():
        result.hps = copy.hps.hardware_feature.hps

    # Handle all possible poe hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.poe.hardware_feature.fw_config)

    if copy.poe.hardware_feature.poe != _HW_FEAT.PoE():
        result.poe = copy.poe.hardware_feature.poe

    # Handle all possible proximity sensor hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.proximity_sensor.hardware_feature.fw_config)

    if proto.has(copy.proximity_sensor.hardware_feature, "proximity"):
        result.proximity = copy.proximity_sensor.hardware_feature.proximity

    # Handle all possible hdmi hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.hdmi.hardware_feature.fw_config)

    if copy.hdmi.hardware_feature.hdmi != _HW_FEAT.Hdmi():
        result.hdmi = copy.hdmi.hardware_feature.hdmi

    # Handle all possible motherboard usb features attributes
    _accumulate_fw_config(result.fw_config, copy.motherboard_usb.hardware_feature.fw_config)

    if copy.motherboard_usb.hardware_feature.usb_c != _HW_FEAT.UsbC():
        _accumulate_usbc(result.usb_c, copy.motherboard_usb.hardware_feature.usb_c)

    if copy.motherboard_usb.hardware_feature.usb_a != _HW_FEAT.UsbA():
        _accumulate_usba(result.usb_a, copy.motherboard_usb.hardware_feature.usb_a)

    # Handle all possible daughter board hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.daughter_board.hardware_feature.fw_config)

    if copy.daughter_board.hardware_feature.usb_c != _HW_FEAT.UsbC():
        _accumulate_usbc(result.usb_c, copy.daughter_board.hardware_feature.usb_c)

    if copy.daughter_board.hardware_feature.usb_a != _HW_FEAT.UsbA():
        _accumulate_usba(result.usb_a, copy.daughter_board.hardware_feature.usb_a)

    if copy.daughter_board.hardware_feature.cellular != _HW_FEAT.Cellular():
        _accumulate_cellular(result.cellular, copy.daughter_board.hardware_feature.cellular)

    if copy.daughter_board.hardware_feature.hdmi != _HW_FEAT.Hdmi():
        _accumulate_hdmi(result.hdmi, copy.daughter_board.hardware_feature.hdmi)

    # Handle all possible non volatile storage hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.non_volatile_storage.hardware_feature.fw_config)

    if copy.non_volatile_storage.hardware_feature.storage != _HW_FEAT.Storage():
        result.storage = copy.non_volatile_storage.hardware_feature.storage

    # Handle all possible wifi hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.wifi.hardware_feature.fw_config)

    if copy.wifi.hardware_feature.wifi != _HW_FEAT.Wifi():
        result.wifi = copy.wifi.hardware_feature.wifi

    # Handle all possible cellular board attributes
    _accumulate_fw_config(result.fw_config, copy.cellular_board.hardware_feature.fw_config)

    if copy.cellular_board.hardware_feature.cellular != _HW_FEAT.Cellular():
        _accumulate_cellular(result.cellular, copy.cellular_board.hardware_feature.cellular)

    # Handle all possible sd reader hardware features attributes
    _accumulate_fw_config(result.fw_config, copy.sd_reader.hardware_feature.fw_config)

    # Handle all possible bluetooth features attributes
    _accumulate_fw_config(result.fw_config, copy.bluetooth.hardware_feature.fw_config)

    if copy.bluetooth.hardware_feature.bluetooth != _HW_FEAT.Bluetooth():
        result.bluetooth = copy.bluetooth.hardware_feature.bluetooth

    # Handle all possible barreljack features
    _accumulate_fw_config(result.fw_config, copy.barreljack.hardware_feature.fw_config)

    if copy.barreljack.hardware_feature.barreljack != _HW_FEAT.BarrelJack():
        result.barreljack = copy.barreljack.hardware_feature.barreljack

    # Handle all possible power supply features
    _accumulate_fw_config(result.fw_config, copy.power_supply.hardware_feature.fw_config)

    if copy.power_supply.hardware_feature.power_supply != _HW_FEAT.PowerSupply():
        result.power_supply = copy.power_supply.hardware_feature.power_supply

    if copy.power_button.hardware_feature.power_button != _HW_FEAT.Button():
        result.power_button = copy.power_button.hardware_feature.power_button

    if copy.volume_button.hardware_feature.volume_button != _HW_FEAT.Button():
        result.volume_button = copy.volume_button.hardware_feature.volume_button

    if copy.microphone_mute_switch.hardware_feature.microphone_mute_switch != _HW_FEAT.MicrophoneMuteSwitch():
        result.microphone_mute_switch = copy.microphone_mute_switch.hardware_feature.microphone_mute_switch

    # Handle all possible touch hardware features
    _accumulate_fw_config(result.fw_config, copy.touch.hardware_feature.fw_config)

    return result

hw_topo = struct(
    create_design_features = _create_design_features,
    create_features = _create_features,
    create_screen = _create_screen,
    create_als_step = _create_als_step,
    create_form_factor = _create_form_factor,
    create_audio = _create_audio,
    create_audio_card_config = _create_audio_card_config,
    override_audio = _override_audio,
    create_stylus = _create_stylus,
    create_keyboard = _create_keyboard,
    create_thermal = _create_thermal,
    create_camera = _create_camera,
    create_sensor = _create_sensor,
    create_fingerprint = _create_fingerprint,
    create_proximity_sensor = _create_proximity_sensor,
    create_daughter_board = _create_daughter_board,
    create_non_volatile_storage = _create_non_volatile_storage,
    create_wifi = _create_wifi,
    create_cellular_board = _create_cellular_board,
    create_sd_reader = _create_sd_reader,
    create_motherboard_usb = _create_motherboard_usb,
    create_usbc_port = _create_usbc_port,
    create_bluetooth = _create_bluetooth,
    create_barreljack = _create_barreljack,
    create_power_supply = _create_power_supply,
    create_hardware_topology = _create_hardware_topology,
    create_power_button = _create_power_button,
    create_volume_button = _create_volume_button,
    create_touch = _create_touch,
    create_microphone_mute_switch = _create_microphone_mute_switch,
    create_hdmi = _create_hdmi,
    create_hps = _create_hps,
    create_dp_converter = _create_dp_converter,
    create_poe = _create_poe,
    convert_to_hw_features = _convert_to_hw_features,
    make_camera_device = _make_camera_device,
    make_cellular_dynamic_power_reduction_config = _make_cellular_dynamic_power_reduction_config,
    make_fw_config = _make_fw_config,
    ff = hw_feat.form_factor,
    amplifier = _AMPLIFIER,
    audio_codec = _AUDIO_CODEC,
    cellular = _CELLULAR,
    fp_loc = _FP_LOC,
    storage = _STORAGE,
    kb_type = _KB_TYPE,
    kb_mcu_type = _KB_MCU_TYPE,
    stylus = _STYLUS,
    region = _REGION,
    edge = _EDGE,
    camera_flags = _CAMERA_FLAGS,
    present = _PRESENT,
    port_position = _PORT_POSITION,
    audio_config_structure = _AUDIO_CONFIG_STRUCTURE,
    recovery_input = _RECOVERY_INPUT,

    # embedded controller exports
    ec_type = _EC_TYPE,
    create_ec = _create_ec,
    EC_NONE = _EC_NONE,
    EC_CHROME = _EC_CHROME,
    EC_WILCO = _EC_WILCO,

    # trusted platform module exports
    tpm_type = _TPM_TYPE,
    create_tpm = _create_tpm,
    TPM_THIRD_PARTY = _TPM_THIRD_PARTY,
    TPM_GSC_H1B = _TPM_GSC_H1B,
    TPM_GSC_H1D = _TPM_GSC_H1D,
)
