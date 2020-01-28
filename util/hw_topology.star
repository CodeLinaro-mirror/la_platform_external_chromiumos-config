load("//config/proto/proto.star", "protos")
protos.register()

load("@proto//src/config/api/topology.proto", topo_pb = "chromiumos.config.api")
load("@proto//src/config/api/hardware_topology.proto", hw_topo_pb = "chromiumos.config.api")

_FF = struct(
    CLAMSHELL = topo_pb.HardwareFeatures.FormFactor.CLAMSHELL,
    CONVERTIBLE = topo_pb.HardwareFeatures.FormFactor.CONVERTIBLE,
    DETACHABLE = topo_pb.HardwareFeatures.FormFactor.DETACHABLE,
    CHROMEBASE = topo_pb.HardwareFeatures.FormFactor.CHROMEBASE,
    CHROMEBOX = topo_pb.HardwareFeatures.FormFactor.CHROMEBOX,
    CHROMEBIT = topo_pb.HardwareFeatures.FormFactor.CHROMEBIT,
    CHROMESLATE = topo_pb.HardwareFeatures.FormFactor.CHROMESLATE,
)

def _create_design_features(form_factor = _FF.CLAMSHELL):
  return topo_pb.HardwareFeatures(
      form_factor=topo_pb.HardwareFeatures.FormFactor(
          form_factor=form_factor,
      ),
  )

def _create_features(form_factors = [_FF.CLAMSHELL,_FF.CONVERTIBLE]):
  return [_create_design_features(ff) for ff in form_factors]

def _create_form_factor(id, description, form_factor):
  hw_features = topo_pb.HardwareFeatures()

  hw_features.form_factor.form_factor = form_factor

  return topo_pb.Topology(
    id = id,
    type = topo_pb.Topology.FORM_FACTOR,
    description = { "EN": description},
    hardware_feature = hw_features,
  )

def _bool_to_present(value):
  if value:
    return topo_pb.HardwareFeatures.PRESENT
  else:
    return topo_pb.HardwareFeatures.NOT_PRESENT

def _create_db(id, description, fw_config_value, usbc_count = 0, usba_count = 0, lte_support = False, hdmi_support = False):
  hw_features = topo_pb.HardwareFeatures()

  hw_features.fw_config.value = fw_config_value
  hw_features.usb_c.count.value = usbc_count
  hw_features.usb_a.count.value = usba_count
  hw_features.lte.present = _bool_to_present(lte_support)
  hw_features.hdmi.present = _bool_to_present(hdmi_support)

  return topo_pb.Topology(
    id = id,
    type = topo_pb.Topology.DAUGHTER_BOARD,
    description = { "EN": description},
    hardware_feature = hw_features,
    )

def _create_hardware_topology(form_factor = None, daughter_board = None):
  # Only allow form_factor topologies for form factors
  if form_factor and form_factor.type != topo_pb.Topology.FORM_FACTOR:
    fail("Invalid form factor topology")

  if daughter_board and daughter_board.type != topo_pb.Topology.DAUGHTER_BOARD:
    fail("Invalid daughterboard topology")

  return hw_topo_pb.HardwareTopology(
    form_factor = form_factor,
    daughter_board = daughter_board,
  )

def _accumulate_presence(existing_present, new_present):
  if existing_present == topo_pb.HardwareFeatures.PRESENT:
    return existing_present
  elif new_present != topo_pb.HardwareFeatures.PRESENT_UNKNOWN:
    return new_present


def _convert_to_hw_features(base_hw_features, hardware_topology):
  # Start with a empty default if None was provided
  if not base_hw_features:
    base_hw_features = topo_pb.HardwareFeatures()

  # Start with a copy of the base hardware features, so we don't change it
  result = proto.from_textpb(topo_pb.HardwareFeatures, proto.to_textpb(base_hw_features))

  # Need to make deep-copy otherwise we change the has_ message serialization
  copy = proto.from_textpb(hw_topo_pb.HardwareTopology, proto.to_textpb(hardware_topology))

  # Handle all possible screen hardware features attributes
  result.fw_config.value += copy.screen.hardware_feature.fw_config.value
  if copy.screen.hardware_feature.screen != topo_pb.HardwareFeatures.Screen():
    result.screen = copy.screen.hardware_feature.screen

  # Handle all possible form factor hardware features attributes
  result.fw_config.value += copy.form_factor.hardware_feature.fw_config.value
  if copy.form_factor.hardware_feature.form_factor != topo_pb.HardwareFeatures.FormFactor():
    result.form_factor = copy.form_factor.hardware_feature.form_factor

  # Handle all possible daughter board hardware features attributes
  result.fw_config.value += copy.daughter_board.hardware_feature.fw_config.value

  if copy.daughter_board.hardware_feature.usb_c != topo_pb.HardwareFeatures.UsbC():
    result.usb_c.count.value += copy.daughter_board.hardware_feature.usb_c.count.value

  if copy.daughter_board.hardware_feature.usb_a != topo_pb.HardwareFeatures.UsbA():
    result.usb_a.count.value += copy.daughter_board.hardware_feature.usb_a.count.value

  if copy.daughter_board.hardware_feature.lte != topo_pb.HardwareFeatures.Lte():
    result.lte.present = _accumulate_presence(result.lte.present, copy.daughter_board.hardware_feature.lte.present)

  if copy.daughter_board.hardware_feature.hdmi != topo_pb.HardwareFeatures.Hdmi():
    result.hdmi.present = _accumulate_presence(result.hdmi.present, copy.daughter_board.hardware_feature.hdmi.present)

  return result

def _create_base_hw_feature(usbc_count, usba_count):
  result = topo_pb.HardwareFeatures()
  result.usb_c.count.value = usbc_count
  result.usb_a.count.value = usba_count
  return result

hw_topo = struct(
    create_base_hw_feature = _create_base_hw_feature,
    create_design_features = _create_design_features,
    create_features = _create_features,
    create_form_factor = _create_form_factor,
    create_hardware_topology = _create_hardware_topology,
    convert_to_hw_features = _convert_to_hw_features,
    ff = _FF,
    create_db = _create_db,
)
