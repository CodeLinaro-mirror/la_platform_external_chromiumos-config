"""Functions related to hardware features.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
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
            present = _bool_to_present(types[(internal, external)]),
        ),
    )

def _create_touchpad(present = True):
    """Specify whether touchpad is present."""
    return _HW_FEAT(
        display = _HW_FEAT.Touchpad(
            present = _bool_to_present(present),
        ),
    )

_FORM_FACTOR = struct(
    CLAMSHELL = topo_pb.HardwareFeatures.FormFactor.CLAMSHELL,
    CONVERTIBLE = topo_pb.HardwareFeatures.FormFactor.CONVERTIBLE,
    DETACHABLE = topo_pb.HardwareFeatures.FormFactor.DETACHABLE,
    CHROMEBASE = topo_pb.HardwareFeatures.FormFactor.CHROMEBASE,
    CHROMEBOX = topo_pb.HardwareFeatures.FormFactor.CHROMEBOX,
    CHROMEBIT = topo_pb.HardwareFeatures.FormFactor.CHROMEBIT,
    CHROMESLATE = topo_pb.HardwareFeatures.FormFactor.CHROMESLATE,
)

def _create_form_factor(form_factor):
    """Specify the form factor as a HardwareFeature"""
    return _HW_FEAT(
        form_factor = _HW_FEAT.FormFactor(
            form_factor = form_factor,
        ),
    )

def _create_features(
        form_factor = None,
        hotwording = None,
        display = None,
        touchpad = None):
    hw_feat = {}

    def _merge(name, feature):
        if feature:
            hw_feat[name] = getattr(feature, name)

    _merge("display", display)
    _merge("form_factor", form_factor)
    _merge("hotwording", hotwording)
    _merge("touchpad", touchpad)

    return _HW_FEAT(**hw_feat)

hw_feat = struct(
    create_features = _create_features,
    create_form_factor = _create_form_factor,
    create_hotwording = _create_hotwording,
    create_display = _create_display,
    create_touchpad = _create_touchpad,
    present = _PRESENT,
    form_factor = _FORM_FACTOR,
)
