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
                "label-platform",
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

def _software_attributes():
    """Return list of device attributes related to software config."""
    return [
        _config_attribute(
            "sw-build-target",
            ["sw_config.system_build_target.portage_build_target.overlay_name"],
        ),
        _config_attribute(
            "sw-firmware-ro-major-version",
            ["sw_config.firmware.main_ro_payload.version.major"],
        ),
        _config_attribute(
            "sw-firmware-ro-minor-version",
            ["sw_config.firmware.main_ro_payload.version.minor"],
        ),
        _config_attribute(
            "sw-firmware-ro-patch-version",
            ["sw_config.firmware.main_ro_payload.version.patch"],
        ),
    ]

# List of DutAttributes to generate. Add new DutAttributes here.
_dut_attribute_list = dut_attribute_pb.DutAttributeList(
    dut_attributes =
        _device_attributes() +
        _device_features() +
        _hwid_attributes() +
        _software_attributes(),
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
