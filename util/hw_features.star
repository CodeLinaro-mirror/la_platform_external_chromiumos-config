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

def _create_form_factor(form_factor):
    """Specify the form factor as a HardwareFeature."""
    return _HW_FEAT(
        form_factor = _HW_FEAT.FormFactor(
            form_factor = form_factor,
        ),
    )

_STORAGE = struct(
    EMMC = comp_pb.Component.Storage.EMMC,
    NVME = comp_pb.Component.Storage.NVME,
    SATA = comp_pb.Component.Storage.SATA,
)

def _create_storage(type):
    """Specify storage type."""
    return _HW_FEAT(
        storage = _HW_FEAT.Storage(
            storage_type = type,
        ),
    )

def _create_touchpad(present = True):
    """Specify whether touchpad is present."""
    return _HW_FEAT(
        touchpad = _HW_FEAT.Touchpad(
            present = _bool_to_present(present),
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

def _create_features(
        bluetooth = None,
        camera = None,
        display = None,
        ec = _create_ec(_EC.CHROME),  # non-chrome ECs are very rare
        form_factor = None,
        hotwording = None,
        storage = None,
        touchpad = None):
    hw_feat = {}

    def _merge(name, feature):
        if feature:
            hw_feat[name] = getattr(feature, name)

    _merge("display", display)
    _merge("camera", camera)
    _merge("bluetooth", bluetooth)
    _merge("embedded_controller", ec)
    _merge("form_factor", form_factor)
    _merge("hotwording", hotwording)
    _merge("storage", storage)
    _merge("touchpad", touchpad)

    return _HW_FEAT(**hw_feat)

hw_feat = struct(
    create_bluetooth = _create_bluetooth,
    create_camera = _create_camera,
    create_cameras = _create_cameras,
    create_display = _create_display,
    create_ec = _create_ec,
    create_features = _create_features,
    create_form_factor = _create_form_factor,
    create_hotwording = _create_hotwording,
    create_storage = _create_storage,
    create_touchpad = _create_touchpad,

    # export enums
    camera_features = _camera_features,
    embedded_controller = _EC,
    form_factor = _FORM_FACTOR,
    present = _PRESENT,
    storage = _STORAGE,
)
