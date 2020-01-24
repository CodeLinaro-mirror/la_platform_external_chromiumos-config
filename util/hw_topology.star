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

def _create_features(form_factors = [_FF.CLAMSHELL,_FF.CONVERTIBLE]):
  hw_features = []
  for ff in form_factors:
    hw_features.append(hw_topo_pb.HardwareFeatures(
        form_factor = hw_topo_pb.HardwareFeatures.FormFactor(
            form_factor = ff,
        ),
      ),
    )

  return hw_features

hw_topo = struct(
    create_features = _create_features,
    ff = _FF,
)