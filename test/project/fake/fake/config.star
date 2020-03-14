#!/usr/bin/env lucicfg

load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/config_bundle.proto", config_bundle_pb = "chromiumos.config.api")

load("//config/util/sw_config.star", sc = "sw_config")
load("//config/util/brand_config.star", brand_config = "brand_config")
load("//config/util/design.star", design = "design")
load("//config/util/device_brand.star", device_brand = "device_brand")
load("//config/util/hw_topology.star", hw_topo = "hw_topo")
load("//config/util/partner.star", partner = "partner")
load("//program_fake/program.star", program = "program")

_FAKE_ODM = partner.create("FAKE-ODM")
_FAKE_OEM = partner.create("FAKE-OEM")

_PARTNERS = partner.create_list([_FAKE_ODM, _FAKE_OEM])

_REF_DESIGN_NAME = "FAKE-REF-DESIGN"

_DESIGN_ID = design.create_design_id(_REF_DESIGN_NAME)

_BASE_HW_FEATURE = hw_topo.create_base_hw_feature(usbc_count = 1, usba_count = 1)
_CLAMSHELL = hw_topo.create_form_factor("CLAMSHELL", "Device can only rotate 200 degrees", hw_topo.ff.CLAMSHELL)

_AUDIO_CARD = "fakeaudiocard"

_SW_CONFIG = sc.create(
    scan_config=sc.create_x86_identity(
        smbios_name_match="Fake",
        fw_sku=0x7fffffff),
    audio=sc.create_audio(card_name=_AUDIO_CARD,
                          card_config_file="audio/%s/%s" % (_AUDIO_CARD, _AUDIO_CARD),
                          dsp_file="audio/%s/dsp.ini" % _AUDIO_CARD,
                          ucm_file="audio/%s/HiFi.conf" % _AUDIO_CARD,
                          ucm_master_file="audio/%s/%s.conf" % (_AUDIO_CARD, _AUDIO_CARD)),
    firmware=sc.create_fw_config(
        ro=sc.create_fw_payload(
            name="Fake", build_target_name="fake", major_version=11111),
        rw=sc.create_fw_payload(
            name="Fake", build_target_name="fake", major_version=11111),
        ec=sc.create_fw_payload(name="Fake_EC",
                                build_target_name="fake",
                                fw_type=sc.fw_type.EC,
                                major_version=11111,
                                minor_version=2),
        ec_extras=["fake-ec-extra1", "fake-ec-extra2", ],
        pd=sc.create_fw_payload(
            name="Fake_PD",
            build_target_name="fake",
            fw_type=sc.fw_type.PD,
            major_version=11111),
    )
)

_FP = hw_topo.create_fingerprint(
    id="AA_BB",
    description="Fingerprint sensor",
    location=hw_topo.fp_loc.KEYBOARD_BOTTOM_LEFT,
    board="fake-fingerprint-board")

_HW_DESIGN_CONFIG = design.create_config(
  design_id = _DESIGN_ID,
  config_id = "1",
  sw_config_id = _SW_CONFIG.id,
  base_hw_features = _BASE_HW_FEATURE,
  hardware_topology = hw_topo.create_hardware_topology(
    form_factor = _CLAMSHELL,
    fingerprint = _FP,
  ),
)

_DESIGN = design.create_design(
    id=_DESIGN_ID,
    program_id=program.fake.id,
    odm_id=_FAKE_ODM.id,
    build_target="fake",
    configs=[_HW_DESIGN_CONFIG,],
)

_DEVICE_BRAND = device_brand.create(
    brand_name = "Fake ChromeOS Device Brandname",
    design_id = _DESIGN_ID,
    oem_id = _FAKE_OEM.id,
    brand_code = 'AAAA',
)

_CONFIG = config_bundle_pb.ConfigBundle(
    partners=_PARTNERS,
    designs=design.create_design_list([_DESIGN]),
    device_brands=device_brand.create_list([_DEVICE_BRAND]),
    software_configs=[_SW_CONFIG,],
    brand_configs=[
        brand_config.create(device_brand_id=_DEVICE_BRAND.id,
                            wallpaper='fake-wallpaper'),
    ],
)

design.generate(_CONFIG)
