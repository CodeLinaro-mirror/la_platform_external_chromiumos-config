#!/usr/bin/env lucicfg

load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/config_bundle.proto", config_bundle_pb = "chromiumos.config.api")

load("//config/util/design.star", design = "design")
load("//program_fake/program.star", program = "program")


_REF_DESIGN_NAME = "FAKE-REF-DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)

_DESIGN = design.create_design(
    id=_DESIGN_ID,
    program_id=program.fake.id,
    odm_id=None,
)

_CONFIG = config_bundle_pb.ConfigBundle(designs=design.create_design_list([_DESIGN]))

design.generate(_CONFIG)
