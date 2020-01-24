load("//config/proto/proto.star", "protos")
protos.register()

load("@proto//src/config/api/component.proto", comp_pb = "chromiumos.config.api")
load("@proto//src/config/api/component_id.proto", comp_id_pb = "chromiumos.config.api")

def _create_soc_family(name, arch=comp_pb.Component.Soc.X86_64):
  return comp_pb.Component.Soc.Family(
      arch = arch,
      name = name,
  )

def _create_soc_model(family, model, cores, id):
  id_value = comp_id_pb.ComponentId(value = id)
  soc = comp_pb.Component.Soc(
      family = family,
      model = model,
      cores = cores,
  )
  return comp_pb.Component(id = id_value, soc = soc)

def _create_bt(vendor_id, product_id, bcd_device):
  component_id = comp_id_pb.ComponentId(
      value = "%s:%s:%s" % (vendor_id, product_id, bcd_device))
  comp = comp_pb.Component(
      id = component_id,
      bluetooth = comp_pb.Component.Bluetooth(
          vendor_id = vendor_id,
          product_id = product_id,
          bcd_device = bcd_device)
  )
  return comp

def _create_list(comps):
  return comp_pb.ComponentList(value = comps)

comp = struct(
    create_soc_family = _create_soc_family,
    create_soc_model = _create_soc_model,
    create_bt = _create_bt,
    create_list = _create_list,
)