load("//config/util/bindings/proto.star", "protos")
protos.register()

load("@proto//api/partner.proto", partner_pb = "chromiumos.config.api")
load("@proto//api/partner_id.proto", partner_id_pb = "chromiumos.config.api")

def _create(name):
  partner_id  = partner_id_pb.PartnerId(value = name)
  return partner_pb.Partner(id = partner_id, name=name)

def _create_list(partners):
  return partner_pb.PartnerList(value=partners)

partner = struct(
    create = _create,
    create_list = _create_list,
)
