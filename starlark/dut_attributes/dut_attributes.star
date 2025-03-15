#!/usr/bin/env generate

"""Defines DutAttributes that can be used for test scheduling.

Generates a file containing a DutAttributeList of valid DutAttributes.

Add DutAttributes by appending to _dut_attribute_list.

Note that a DutAttribute used on any branch cannot be deleted or modified,
because this may break the test plan on the branch.
"""

# Needed to load from @proto.
exec("//config/util/bindings/proto.star")

load("@proto//chromiumos/test/api/dut_attribute.proto", dut_attribute_pb = "chromiumos.test.api")
load("//config/util/generate.star", "generate")

def _dut_attribute_id(value):
    """Create a DutAttribute.Id instance."""
    if not value:
        fail("Empty DutAttribute id")
    return dut_attribute_pb.DutAttribute.Id(value = value)

def _field_spec_list(field_specs):
    """Create a DutAttribute.FieldList instance."""
    return [
        dut_attribute_pb.DutAttribute.FieldSpec(
            path = path,
        )
        for path in field_specs
    ]

def _config_attribute(
        name,
        field_specs = [],
        aliases = [],
        allowed_values = [],
        exclude_values = []):
    """Build a DutAttribute with a FlatConfigSource.

    These are attributes that directly reference a config value from the
    associated FlatConfig payload.
    """

    return dut_attribute_pb.DutAttribute(
        id = _dut_attribute_id(name),
        aliases = aliases,
        allowed_values = allowed_values,
        exclude_values = exclude_values,
        flat_config_source = dut_attribute_pb.DutAttribute.FlatConfigSource(
            fields = _field_spec_list(field_specs),
        ),
    )

def _hwid_attribute(
        name,
        component_type,
        field_specs = [],
        aliases = [],
        allowed_values = [],
        exclude_values = []):
    """Build a DutAttribute with a HwidSource.

    These are attributes whose value's are mediate by HwidServer at runtime.
    """

    return dut_attribute_pb.DutAttribute(
        id = _dut_attribute_id(name),
        aliases = aliases,
        allowed_values = allowed_values,
        exclude_values = exclude_values,
        hwid_source = dut_attribute_pb.DutAttribute.HwidSource(
            component_type = component_type,
            fields = _field_spec_list(field_specs),
        ),
    )

def _tle_attribute(
        name,
        aliases = [],
        allowed_values = [],
        exclude_values = []):
    """Build a DutAttribute with a TleSource.

    These are attributes whose values are determined by the caller TLE at
    runtime. Field specs are not maintained here as each TLE should have its own
    implementation on how to match the label to the desired value.
    """

    return dut_attribute_pb.DutAttribute(
        id = _dut_attribute_id(name),
        aliases = aliases,
        allowed_values = allowed_values,
        exclude_values = exclude_values,
        tle_source = dut_attribute_pb.DutAttribute.TleSource(),
    )

def _device_attributes():
    """Return list of generic device attribute definitions."""
    return [
        _config_attribute(
            "attr-cts-abi",
            ["program.platform.soc_arch"],
            aliases = [
                "label-cts_abi",
                "label-cts_cpu",
            ],
        ),
        _config_attribute(
            "attr-design",
            ["hw_design.id.value"],
            aliases = [
                "attr-model",
                "label-model",
            ],
        ),
        _config_attribute(
            "attr-ec-type",
            ["hw_design_config.hardware_features.embedded_controller.ec_type"],
            aliases = [
                "label-ec_type",
            ],
        ),
        _config_attribute(
            "attr-fingerprint-location",
            # Note: need to reference REQUIRED design config constraints too
            ["hw_design_config.hardware_features.fingerprint.location"],
        ),
        _config_attribute(
            "attr-program",
            ["program.id.value"],
            aliases = [
                "attr-board",
                "label-platform",
                "label-board",
            ],
        ),
    ]

def _device_features():
    """Return list of device features."""
    return [
        _config_attribute(
            "feature-bluetooth",
            ["hw_design_config.hardware_features.bluetooth.present"],
            aliases = [
                "label-bluetooth",
            ],
        ),
        _config_attribute(
            "feature-fingerprint",
            ["hw_design_config.hardware_features.fingerprint.location"],
            exclude_values = ["LOCATION_UNKNOWN", "NOT_PRESENT"],
            aliases = [
                "label-fingerprint",
            ],
        ),
        _config_attribute(
            "feature-hotwording",
            ["hw_design_config.hardware_features.hotwording.present"],
            aliases = [
                "label-hotwording",
            ],
        ),
        _config_attribute(
            "feature-internal-display",
            ["hw_design_config.hardware_features.display.type"],
            allowed_values = ["TYPE_INTERNAL", "TYPE_INTERNAL_EXTERNAL"],
            aliases = [
                "label-internal_display",
            ],
        ),
        _config_attribute(
            "feature-stylus",
            ["hw_design_config.hardware_features.stylus.stylus"],
            allowed_values = ["INTERNAL", "EXTERNAL"],
            aliases = [
                "label-stylus",
            ],
        ),
        _config_attribute(
            "feature-touchpad",
            ["hw_design_config.hardware_features.touchpad.present"],
            aliases = [
                "label-touchpad",
            ],
        ),
        _config_attribute(
            "feature-touchscreen",
            ["hw_design_config.hardware_features.screen.touch_support"],
            allowed_values = ["PRESENT"],
            aliases = [
                "label-touchscreen",
            ],
        ),
    ]

def _hwid_attributes():
    """Return list of device attributes looked up through hwid."""
    return [
        _hwid_attribute(
            "hw-wireless",
            component_type = "wifi",
            field_specs = ["hwid_label"],
            aliases = [
                "label-wifi_chip",
            ],
        ),
    ]

def _tle_attributes():
    """Return list of device attributes to be looked up by a TLE."""
    return [
        _tle_attribute(
            "attr-cr50-phase",
            aliases = [
                "label-cr50_phase",
            ],
        ),
        _tle_attribute(
            "attr-cr50-key-env",
            aliases = [
                "label-cr50_ro_keyid",
            ],
        ),
        _tle_attribute(
            "attr-dut-id",
            aliases = [
                "dut_id",
            ],
        ),
        _tle_attribute(
            "attr-dut-name",
            aliases = [
                "dut_name",
            ],
        ),
        _tle_attribute(
            "misc-license",
            aliases = [
                "label-license",
            ],
        ),
        _tle_attribute(
            "peripheral-arc",
            aliases = [
                "label-arc",
            ],
        ),
        _tle_attribute(
            "peripheral-atrus",
            aliases = [
                "label-atrus",
            ],
        ),
        _tle_attribute(
            "peripheral-audio-board",
            aliases = [
                "label-audio_board",
            ],
        ),
        _tle_attribute(
            "peripheral-audio-box",
            aliases = [
                "label-audio_box",
            ],
        ),
        _tle_attribute(
            "peripheral-audio-cable",
            aliases = [
                "label-audio_cable",
            ],
        ),
        _tle_attribute(
            "peripheral-audio-loopback",
            aliases = [
                "label-audio_loopback_dongle",
            ],
        ),
        _tle_attribute(
            "peripheral-bluetooth-state",
            aliases = [
                "label-bluetooth_state",
            ],
        ),
        _tle_attribute(
            "peripheral-camerabox-facing",
            aliases = [
                "label-camerabox_facing",
            ],
        ),
        _tle_attribute(
            "peripheral-camerabox-light",
            aliases = [
                "label-camerabox_light",
            ],
        ),
        _tle_attribute(
            "peripheral-carrier",
            aliases = [
                "label-carrier",
            ],
        ),
        _tle_attribute(
            "peripheral-chameleon",
            aliases = [
                "label-chameleon",
            ],
        ),
        _tle_attribute(
            "peripheral-chaos",
            aliases = [
                "label-chaos_dut",
            ],
        ),
        _tle_attribute(
            "peripheral-mimo",
            aliases = [
                "label-mimo",
            ],
        ),
        _tle_attribute(
            "peripheral-num-btpeer",
            aliases = [
                "label-working_bluetooth_btpeer",
            ],
        ),
        _tle_attribute(
            "peripheral-power",
            aliases = [
                "label-power",
            ],
        ),
        _tle_attribute(
            "peripheral-servo",
            aliases = [
                "label-servo",
            ],
        ),
        _tle_attribute(
            "peripheral-servo-component",
            aliases = [
                "label-servo_component",
            ],
        ),
        _tle_attribute(
            "peripheral-servo-state",
            aliases = [
                "label-servo_state",
            ],
        ),
        _tle_attribute(
            "peripheral-servo-usb-state",
            aliases = [
                "label-servo_usb_state",
                "servo_usb_state",
            ],
        ),
        _tle_attribute(
            "peripheral-wificell",
            aliases = [
                "label-wificell",
            ],
        ),
        _tle_attribute(
            "peripheral-wifi-state",
            aliases = [
                "label-wifi_state",
            ],
        ),
        _tle_attribute(
            "swarming-pool",
            aliases = [
                "label-pool",
            ],
        ),
    ]

# List of DutAttributes to generate. Add new DutAttributes here.
_dut_attribute_list = dut_attribute_pb.DutAttributeList(
    dut_attributes =
        _device_attributes() +
        _device_features() +
        _hwid_attributes() +
        _tle_attributes(),
)

def _validate_dut_attribute_list(dut_attribute_list):
    """Performs basic validation checks on a DutAttributeList.

    For example, ids must be unique.
    """
    ids = set()
    for attribute in dut_attribute_list.dut_attributes:
        if attribute.id.value in ids:
            fail("DutAttribute.Id {} declared multiple times.".format(attribute.id))

        ids = ids.union([attribute.id.value])

# Validate the DutAttributeList and write to a file.
_validate_dut_attribute_list(_dut_attribute_list)

generate.generate(_dut_attribute_list, "dut_attributes.jsonproto")
