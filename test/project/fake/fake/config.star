#!/usr/bin/env lucicfg

load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/config_bundle.proto", config_bundle_pb = "chromiumos.config.api")

load("//config/util/build_config.star", bc = "build_config")
load("//config/util/design.star", design = "design")
load("//config/util/partner.star", partner = "partner")
load("//program_fake/program.star", program = "program")

_FAKE_ODM = partner.create("FAKE-ODM")

_PARTNERS = partner.create_list([_FAKE_ODM])

_REF_DESIGN_NAME = "FAKE-REF-DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)

_DESIGN = design.create_design(
    id=_DESIGN_ID,
    program_id=program.fake.id,
    odm_id=_FAKE_ODM.id,
)

_AUDIO_CARD = "fake-audio-card"

_BUILD_CONFIG = bc.create(
    build_target="fake",
    software_configs=[
        bc.create_software_config(
            scan_config=bc.create_x86_identity(
                smbios_name_match="Fake",
                fw_sku=0x7fffffff),
            audio=bc.create_audio(card_name=_AUDIO_CARD,
                                  ucm_file="audio/%s/HiFi.conf" % _AUDIO_CARD),
            firmware=bc.create_fw_config(
                ro=bc.create_fw_payload(
                    name="Fake", major_version=11111),
                ec=bc.create_fw_payload(
                    name="Fake", fw_type=bc.fw_type.EC, major_version=11111),
            )),
    ]
)

_CONFIG = config_bundle_pb.ConfigBundle(
    partners=_PARTNERS,
    designs=design.create_design_list([_DESIGN]),
    build_configs=[_BUILD_CONFIG],
)

design.generate(_CONFIG)
