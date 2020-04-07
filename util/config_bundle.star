"""Functions related to config bundles.

See proto definitions for descriptions of arguments.
"""

load("@proto//payload/config_bundle.proto", config_bundle_pb = "chromiumos.config.payload")
load("//config/util/component.star", "comp")
load("//config/util/design.star", "design")
load("//config/util/device_brand.star", "device_brand")
load("//config/util/partner.star", "partner")
load("//config/util/program.star", "program")
load("//config/util/bindings/proto.star", "protos")

protos.register()

def _create(
        components = None,
        designs = None,
        device_brands = None,
        partners = None,
        programs = None,
        build_targets = None,
        software_configs = None,
        brand_configs = None):
    """Builds a ConfigBundle proto."""
    return config_bundle_pb.ConfigBundle(
        components = comp.create_list(components),
        designs = design.create_design_list(designs),
        device_brands = device_brand.create_list(device_brands),
        partners = partner.create_list(partners),
        programs = program.create_list(programs),
        build_targets = build_targets,
        software_configs = software_configs,
        brand_configs = brand_configs,
    )

config_bundle = struct(
    create = _create,
)
