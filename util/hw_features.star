"""Functions related to hardware features.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/component.proto",
    comp_pb = "chromiumos.config.api",
)
load(
    "@proto//chromiumos/config/api/topology.proto",
    topo_pb = "chromiumos.config.api",
)

_HW_FEAT = topo_pb.HardwareFeatures

_PRESENT = struct(
    UNKNOWN = topo_pb.HardwareFeatures.PRESENT_UNKNOWN,
    PRESENT = topo_pb.HardwareFeatures.PRESENT,
    NOT_PRESENT = topo_pb.HardwareFeatures.NOT_PRESENT,
)

def _bool_to_present(value):
    """Returns correct value of present enum depending on value"""
    if value == None:
        return _PRESENT.UNKNOWN
    elif value:
        return _PRESENT.PRESENT
    else:
        return _PRESENT.NOT_PRESENT

def _create_bluetooth(present = True):
    """Specify whether bluetooth is present"""
    return _HW_FEAT(
        bluetooth = _HW_FEAT.Bluetooth(
            present = _bool_to_present(present),
        ),
    )

def _create_hotwording(supported = True):
    """Specify whether hotwording is supported"""
    return _HW_FEAT(
        hotwording = _HW_FEAT.Hotwording(
            present = _bool_to_present(supported),
        ),
    )

def _create_display(internal, external):
    """Specify type of display support present."""
    types = {
        (False, False): _HW_FEAT.Display.TYPE_UNKNOWN,
        (True, False): _HW_FEAT.Display.TYPE_INTERNAL,
        (False, True): _HW_FEAT.Display.TYPE_EXTERNAL,
        (True, True): _HW_FEAT.Display.TYPE_INTERNAL_EXTERNAL,
    }

    return _HW_FEAT(
        display = _HW_FEAT.Display(
            type = types[(internal, external)],
        ),
    )

_FORM_FACTOR = struct(
    CLAMSHELL = _HW_FEAT.FormFactor.CLAMSHELL,
    CONVERTIBLE = _HW_FEAT.FormFactor.CONVERTIBLE,
    DETACHABLE = _HW_FEAT.FormFactor.DETACHABLE,
    CHROMEBASE = _HW_FEAT.FormFactor.CHROMEBASE,
    CHROMEBOX = _HW_FEAT.FormFactor.CHROMEBOX,
    CHROMEBIT = _HW_FEAT.FormFactor.CHROMEBIT,
    CHROMESLATE = _HW_FEAT.FormFactor.CHROMESLATE,
)

_RECOVERY_INPUT = struct(
    KEYBOARD = _HW_FEAT.FormFactor.KEYBOARD,
    POWER_BUTTON = _HW_FEAT.FormFactor.POWER_BUTTON,
    RECOVERY_BUTTON = _HW_FEAT.FormFactor.RECOVERY_BUTTON,
)

_EC = struct(
    CHROME = _HW_FEAT.EmbeddedController.EC_CHROME,
    WILCO = _HW_FEAT.EmbeddedController.EC_WILCO,
)

def _create_ec(ec_type, present = True):
    """Specify the embedded controller type."""
    return _HW_FEAT(
        embedded_controller = _HW_FEAT.EmbeddedController(
            present = _bool_to_present(present),
            ec_type = ec_type,
        ),
    )

_LOCATION = struct(
    UNKNOWN = _HW_FEAT.Fingerprint.LOCATION_UNKNOWN,
    SCREEN_TOP_LEFT = _HW_FEAT.Fingerprint.POWER_BUTTON_TOP_LEFT,
    KEYBOARD_BOTTOM_LEFT = _HW_FEAT.Fingerprint.KEYBOARD_BOTTOM_LEFT,
    KEYBOARD_BOTTOM_RIGHT = _HW_FEAT.Fingerprint.KEYBOARD_BOTTOM_RIGHT,
    KEYBOARD_TOP_RIGHT = _HW_FEAT.Fingerprint.KEYBOARD_TOP_RIGHT,
    SIDE_RIGHT = _HW_FEAT.Fingerprint.RIGHT_SIDE,
    SIDE_LEFT = _HW_FEAT.Fingerprint.LEFT_SIDE,
    LEFT_OF_POWER_BUTTON_TOP_RIGHT = _HW_FEAT.Fingerprint.LEFT_OF_POWER_BUTTON_TOP_RIGHT,
    POWER_BUTTON_TOP_RIGHT_KEY = _HW_FEAT.Fingerprint.POWER_BUTTON_TOP_RIGHT_KEY,
    POWER_BUTTON_LEFT_EDGE_TOP = _HW_FEAT.Fingerprint.POWER_BUTTON_LEFT_EDGE_TOP,
)

def _create_fingerprint(
        present = False,
        location = _LOCATION.UNKNOWN,
        board = "",
        ro_version = "",
        fingerprint_diag = None):
    """Specify fingerprint settings"""
    return _HW_FEAT(
        fingerprint = _HW_FEAT.Fingerprint(
            location = location,
            board = board,
            ro_version = ro_version,
            fingerprint_diag = fingerprint_diag,
            present = present,
        ),
    )

def _create_form_factor(form_factor, recovery_input = None):
    """Specify the form factor as a HardwareFeature."""
    return _HW_FEAT(
        form_factor = _HW_FEAT.FormFactor(
            form_factor = form_factor,
            recovery_input = recovery_input,
        ),
    )

_KB_TYPE = struct(
    NONE = _HW_FEAT.Keyboard.NONE,
    INTERNAL = _HW_FEAT.Keyboard.INTERNAL,
    DETACHABLE = _HW_FEAT.Keyboard.DETACHABLE,
)

def _create_keyboard(
        kb_type,
        backlight = False,
        pwr_btn_present = False,
        numpad_present = False):
    """Builds a Topology proto for a keyboard.

    Args:
        kb_type: A KeyboardType enum. Required.
        backlight: True if a backlight is present. Required.
        pwr_btn_present: True if a power button is present. Required.
        numpad_present: True if numeric pad is present.
    """
    return _HW_FEAT(
        keyboard = _HW_FEAT.Keyboard(
            keyboard_type = kb_type,
            backlight = _bool_to_present(backlight),
            power_button = _bool_to_present(pwr_btn_present),
            numeric_pad = _bool_to_present(numpad_present),
        ),
    )

_STORAGE = struct(
    EMMC = comp_pb.Component.Storage.EMMC,
    NVME = comp_pb.Component.Storage.NVME,
    SATA = comp_pb.Component.Storage.SATA,
    UFS = comp_pb.Component.Storage.UFS,
    BRIDGED_EMMC = comp_pb.Component.Storage.BRIDGED_EMMC,
)

def _create_storage(type):
    """Specify storage type."""
    return _HW_FEAT(
        storage = _HW_FEAT.Storage(
            storage_type = type,
        ),
    )

def _create_screen(
        touch = False,
        inches = 0,
        width_px = None,
        height_px = None,
        pixels_per_in = None,
        privacy_screen = False):
    """Specify features of screen"""

    return _HW_FEAT(
        screen = _HW_FEAT.Screen(
            touch_support = _bool_to_present(touch),
            panel_properties = comp_pb.Component.DisplayPanel.Properties(
                diagonal_milliinch = inches * 1000,
                width_px = width_px,
                height_px = height_px,
                pixels_per_in = pixels_per_in,
            ),
        ),
        privacy_screen = _HW_FEAT.PrivacyScreen(
            present = _bool_to_present(privacy_screen),
        ),
    )

def _create_touchpad(present = True):
    """Specify whether touchpad is present."""
    return _HW_FEAT(
        touchpad = _HW_FEAT.Touchpad(
            present = _bool_to_present(present),
        ),
    )

def _create_microphone_mute_switch(present = False):
    """Specify whether audio input mute switch is present."""
    return _HW_FEAT(
        microphone_mute_switch = _HW_FEAT.MicrophoneMuteSwitch(
            present = _bool_to_present(present),
        ),
    )

def _create_battery(no_battery_boot_supported = False):
    """Specify whether no battery boot is supported."""
    return _HW_FEAT(
        battery = _HW_FEAT.Battery(
            no_battery_boot_supported = no_battery_boot_supported,
        ),
    )

# build struct of enums to configure camera
_camera_features = struct(
    facing = struct(
        UNKNOWN = _HW_FEAT.Camera.FACING_UNKNOWN,
        FRONT = _HW_FEAT.Camera.FACING_FRONT,
        BACK = _HW_FEAT.Camera.FACING_BACK,
    ),
    interface = struct(
        UNKNOWN = _HW_FEAT.Camera.INTERFACE_UNKNOWN,
        USB = _HW_FEAT.Camera.INTERFACE_USB,
        MIPI = _HW_FEAT.Camera.INTERFACE_MIPI,
    ),
    orientation = struct(
        UNKNOWN = _HW_FEAT.Camera.ORIENTATION_UNKNOWN,
        _0_DEG = _HW_FEAT.Camera.ORIENTATION_0,
        _90_DEG = _HW_FEAT.Camera.ORIENTATION_90,
        _180_DEG = _HW_FEAT.Camera.ORIENTATION_180,
        _270_DEG = _HW_FEAT.Camera.ORIENTATION_270,
    ),
)

def _create_camera(
        facing = _camera_features.facing.UNKNOWN,
        flags = 0,
        ids = [],
        interface = _camera_features.interface.UNKNOWN,
        orientation = _camera_features.orientation.UNKNOWN,
        privacy_switch = None):
    """Take camera features and create a Camera.Device instance.

    Pass one or more of these instances to create_cameras() to build
    a full HardwareFeature proto from them.
    """
    return _HW_FEAT.Camera.Device(
        facing = facing,
        flags = flags,
        ids = ids,
        interface = interface,
        orientation = orientation,
        privacy_switch = _bool_to_present(privacy_switch),
    )

def _create_cameras(*args):
    """Take one or more cameras and create HardwareFeature from them."""
    return _HW_FEAT(
        camera = _HW_FEAT.Camera(
            devices = args,
        ),
    )

_STYLUS_TYPE = struct(
    NONE = _HW_FEAT.Stylus.NONE,
    INTERNAL = _HW_FEAT.Stylus.INTERNAL,
    EXTERNAL = _HW_FEAT.Stylus.EXTERNAL,
)

def _create_stylus(stylus_type):
    """Create stylus feature."""
    return _HW_FEAT(
        stylus = _HW_FEAT.Stylus(
            stylus = stylus_type,
        ),
    )

def _create_features(
        battery = None,
        bluetooth = None,
        camera = None,
        display = None,
        ec = _create_ec(_EC.CHROME),  # non-chrome ECs are very rare
        fingerprint = None,
        form_factor = None,
        hotwording = None,
        keyboard = None,
        proximity = None,
        screen = None,
        storage = None,
        stylus = None,
        touchpad = None,
        microphone_mute_switch = None):
    hw_feat = {}

    def _merge(name, feature):
        if feature:
            hw_feat[name] = getattr(feature, name)

    _merge("battery", battery)
    _merge("bluetooth", bluetooth)
    _merge("camera", camera)
    _merge("display", display)
    _merge("embedded_controller", ec)
    _merge("fingerprint", fingerprint)
    _merge("form_factor", form_factor)
    _merge("hotwording", hotwording)
    _merge("keyboard", keyboard)
    _merge("proximity", proximity)
    _merge("screen", screen)
    _merge("storage", storage)
    _merge("stylus", stylus)
    _merge("touchpad", touchpad)
    _merge("microphone_mute_switch", microphone_mute_switch)

    return _HW_FEAT(**hw_feat)

hw_feat = struct(
    create_battery = _create_battery,
    create_bluetooth = _create_bluetooth,
    create_camera = _create_camera,
    create_cameras = _create_cameras,
    create_display = _create_display,
    create_ec = _create_ec,
    create_fingerprint = _create_fingerprint,
    create_features = _create_features,
    create_form_factor = _create_form_factor,
    create_hotwording = _create_hotwording,
    create_keyboard = _create_keyboard,
    create_screen = _create_screen,
    create_storage = _create_storage,
    create_stylus = _create_stylus,
    create_touchpad = _create_touchpad,
    create_microphone_mute_switch = _create_microphone_mute_switch,

    # export enums
    camera_features = _camera_features,
    embedded_controller = _EC,
    form_factor = _FORM_FACTOR,
    recovery_input = _RECOVERY_INPUT,
    keyboard_type = _KB_TYPE,
    present = _PRESENT,
    storage = _STORAGE,
    stylus_type = _STYLUS_TYPE,
    location = _LOCATION,
)
