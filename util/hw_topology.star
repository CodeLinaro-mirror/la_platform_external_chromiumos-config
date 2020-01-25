load("//config/proto/proto.star", "protos")
protos.register()

load("@proto//src/config/api/hardware_topology.proto", hw_topo_pb = "chromiumos.config.api")

_FF = struct(
    CLAMSHELL = hw_topo_pb.HardwareFeatures.FormFactor.CLAMSHELL,
    CONVERTIBLE = hw_topo_pb.HardwareFeatures.FormFactor.CONVERTIBLE,
    DETACHABLE = hw_topo_pb.HardwareFeatures.FormFactor.DETACHABLE,
    CHROMEBASE = hw_topo_pb.HardwareFeatures.FormFactor.CHROMEBASE,
    CHROMEBOX = hw_topo_pb.HardwareFeatures.FormFactor.CHROMEBOX,
    CHROMEBIT = hw_topo_pb.HardwareFeatures.FormFactor.CHROMEBIT,
    CHROMESLATE = hw_topo_pb.HardwareFeatures.FormFactor.CHROMESLATE,
)

def _create_design_features(form_factor = _FF.CLAMSHELL):
  return hw_topo_pb.HardwareFeatures(
      form_factor=hw_topo_pb.HardwareFeatures.FormFactor(
          form_factor=form_factor,
      ),
  )

def _create_features(form_factors = [_FF.CLAMSHELL,_FF.CONVERTIBLE]):
  return [_create_design_features(ff) for ff in form_factors]

hw_topo = struct(
    create_design_features = _create_design_features,
    create_features = _create_features,
    ff = _FF,
)
