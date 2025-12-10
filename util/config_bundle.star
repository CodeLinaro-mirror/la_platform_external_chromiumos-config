"""Functions related to config bundles.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/payload/config_bundle.proto",
    config_bundle_pb = "chromiumos.config.payload",
)
load("//config/util/generate.star", "generate")

def _create(
        components = None,
        designs = None,
        device_brands = None,
        partners = None,
        programs = None,
        software_configs = None,
        brand_configs = None,
        android_hal_config = None):
    """Builds a ConfigBundle proto."""
    return config_bundle_pb.ConfigBundle(
        components = components,
        design_list = designs,
        device_brand_list = device_brands,
        partner_list = partners,
        program_list = programs,
        software_configs = software_configs,
        brand_configs = brand_configs,
        android_hal_config = android_hal_config,
    )

config_bundle = struct(
    create = _create,
    generate = generate.generate,
)
