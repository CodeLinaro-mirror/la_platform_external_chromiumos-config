# Config API Reference

[TOC]


## Updating this Reference

This reference is automatically generated based on Starlark docstrings. If you
change a Starlark util function, run `util/docgen/generate.sh` to regenerate. A
few tips:

- Templating is based on Go's [`text/template`](https://golang.org/pkg/text/template/)
package. Usually, the contents this template file won't need to be changed in
order to regenerate.

- Generation is based on docstrings, not the actual Starlark signatures. Thus,
an "Args" section needs to be specified in the docstring in order for args to
be picked up. Similarly, a "Returns" section needs to be specified in the
docstring for returns to get picked up.

- Specify "Required." after an argument to make it a required argument in the
generated documentation.















## //config/util/brand_config.star

### brand_config.create {#brand_config.create}
Builds a BrandConfig proto.

```python
brand_config.create(device_brand_id, wallpaper = None, whitelabel_tag = None)
```

#### Arguments {#brand_config.create-args}

* **device_brand_id**: A DeviceBrandId proto that is used to select a BrandConfig at runtime. Required.
* **wallpaper**: Base filename of the default wallpaper to show.
* **whitelabel_tag**: "whitelabel_tag" value set in the VPD, used to select a BrandConfig at runtime. See https://chromeos.google.com/partner/dlm/docs/factory/vpd.html#field-whitelabel_tag.

#### Returns  {#brand_config.create-returns}
A BrandConfig proto.




## //config/util/build_target.star

### build_target.create {#build_target.create}
Builds a BuildTarget proto.

```python
build_target.create(
    # Required arguments.
    name,

    # Optional arguments.
    overlay_name = None,
    arc_device = None,
    first_api_level = None,
)
```

#### Arguments {#build_target.create-args}

* **name**: Name of the build target, e.g. "galaxy". Required.
* **overlay_name**: Name of the Portage overlay, e.g. "overlay-galaxy-private". If not specified, "name" is used.
* **arc_device**: Device name to report in ‘ro.product.device’. If not specified, "name"_cheets is used.
* **first_api_level**: The first Android API level that this build shipped with.

#### Returns  {#build_target.create-returns}
A BuildTarget proto.




## //config/util/component.star

### comp.create_soc_family {#comp.create_soc_family}
Builds a Component.Soc.Family proto.

```python
comp.create_soc_family()
```



### comp.create_soc_model {#comp.create_soc_model}
Builds a Component proto for an Soc.

```python
comp.create_soc_model()
```



### comp.create_bt {#comp.create_bt}
Builds a Component proto for Bluetooth.

```python
comp.create_bt()
```



### comp.create_display_panel {#comp.create_display_panel}
Builds a Component.DisplayPanel proto for touchscreen.

```python
comp.create_display_panel()
```



### comp.create_touchscreen {#comp.create_touchscreen}
Builds a Component.Touch proto for touchscreen.

```python
comp.create_touchscreen()
```



### comp.create_touchpad {#comp.create_touchpad}
Builds a Component.Touch proto for touchpad.

```python
comp.create_touchpad()
```



### comp.create_wifi {#comp.create_wifi}
Builds a Component proto for Wifi.

```python
comp.create_wifi()
```



### comp.create_qual {#comp.create_qual}
Builds a Component.Qualification proto.

```python
comp.create_qual()
```



### comp.create_quals {#comp.create_quals}
Builds a Component.Qualification proto for each of component_ids.

```python
comp.create_quals()
```



### comp.create_usb {#comp.create_usb}
Builds a Interface.Usb proto.

```python
comp.create_usb()
```



### comp.create_pci {#comp.create_pci}
Builds a Interface.Pci proto.

```python
comp.create_pci()
```





## //config/util/config_bundle.star

### config_bundle.create {#config_bundle.create}
Builds a ConfigBundle proto.

```python
config_bundle.create()
```





## //config/util/design.star

### design.append_configs {#design.append_configs}
Creates and appends new SW and HW configs.

Create new Software and Hardware Design Configuration with the
specified properties and then append them to the sw_configs and hw_configs
arrays respectively. This ensures that all IDs are consistent.

```python
design.append_configs()
```



### design.create_constraint {#design.create_constraint}
Builds a Design.Config.Constraint proto.

```python
design.create_constraint()
```



### design.create_constraints {#design.create_constraints}
Builds a Design.Config.Constrain proto for each of hw_features.

```python
design.create_constraints()
```



### design.create_design_id {#design.create_design_id}
Builds a DesignId proto.

```python
design.create_design_id()
```



### design.create_design {#design.create_design}
Builds a Design proto.

```python
design.create_design()
```



### design.create_design_list {#design.create_design_list}
Builds a DesignList proto.

```python
design.create_design_list()
```



### design.generate {#design.generate}
Serializes a ConfigBundle to a file.

A json proto is written. Note that there is some post processing done
by the gen_config script to convert this json output into a json
output that uses ints for encoding enums.

```python
design.generate()
```





## //config/util/device_brand.star

### device_brand.create {#device_brand.create}
Builds a DeviceBrand proto.

```python
device_brand.create()
```



### device_brand.create_list {#device_brand.create_list}
Builds a DeviceBrandList proto.

```python
device_brand.create_list()
```





## //config/util/hw_topology.star

### hw_topo.create_design_features {#hw_topo.create_design_features}
Builds a HardwareFeatures proto with form_factor.

```python
hw_topo.create_design_features()
```



### hw_topo.create_features {#hw_topo.create_features}
Builds a HardwareFeatures proto for each of form_factors.

```python
hw_topo.create_features()
```



### hw_topo.create_screen {#hw_topo.create_screen}
Builds a Topology proto for a screen.

```python
hw_topo.create_screen()
```



### hw_topo.create_form_factor {#hw_topo.create_form_factor}
Builds a Topology proto for a form factor.

```python
hw_topo.create_form_factor(
    # Required arguments.
    form_factor,

    # Optional arguments.
    fw_configs = None,
    id = None,
    description = None,
)
```

#### Arguments {#hw_topo.create_form_factor-args}

* **form_factor**: A FormFactorType enum. Required.
* **fw_configs**: A list of FirmwareConfiguration protos for the form factor.
* **id**: A string identifier for the Topology. If not passed, a default is provided based on form_factor.
* **description**: An English description for the Topology. If not passed, a default is provided based on form_factor.


### hw_topo.create_audio {#hw_topo.create_audio}
Builds a Topology proto for audio.

```python
hw_topo.create_audio()
```



### hw_topo.create_stylus {#hw_topo.create_stylus}
Builds a Topology proto for a stylus.

```python
hw_topo.create_stylus()
```



### hw_topo.create_keyboard {#hw_topo.create_keyboard}
Builds a Topology proto for a keyboard.

```python
hw_topo.create_keyboard(
    # Required arguments.
    backlight,
    pwr_btn_present,
    kb_type,

    # Optional arguments.
    fw_configs = None,
    id = None,
    description = None,
)
```

#### Arguments {#hw_topo.create_keyboard-args}

* **backlight**: True if a backlight is present. Required.
* **pwr_btn_present**: True if a power button is present. Required.
* **kb_type**: A KeyboardType enum. Required.
* **fw_configs**: A list of FirmwareConfiguration protos for the form factor.
* **id**: A string identifier for the Topology. If not passed, a default is provided.
* **description**: An English description for the Topology. If not passed, a default is provided.


### hw_topo.create_thermal {#hw_topo.create_thermal}
Builds a Topology proto for thermal.

```python
hw_topo.create_thermal()
```



### hw_topo.create_camera {#hw_topo.create_camera}
Builds a Topology proto for a camera.

```python
hw_topo.create_camera()
```



### hw_topo.create_sensor {#hw_topo.create_sensor}
Builds a Topology proto for accelerometer/gyroscrope/magnometer sensors.

```python
hw_topo.create_sensor()
```



### hw_topo.create_fingerprint {#hw_topo.create_fingerprint}
Builds a Topology proto for a fingerprint reader.

```python
hw_topo.create_fingerprint()
```



### hw_topo.create_proximity_sensor {#hw_topo.create_proximity_sensor}
Builds a Topology proto for a proximity sensor.

```python
hw_topo.create_proximity_sensor()
```



### hw_topo.create_daughter_board {#hw_topo.create_daughter_board}
Builds a Topology proto for a daughter board.

```python
hw_topo.create_daughter_board()
```



### hw_topo.create_non_volatile_storage {#hw_topo.create_non_volatile_storage}
Builds a Topology proto for non-volatile storage.

```python
hw_topo.create_non_volatile_storage()
```



### hw_topo.create_ram {#hw_topo.create_ram}
Builds a Topology proto for RAM.

```python
hw_topo.create_ram()
```



### hw_topo.create_wifi {#hw_topo.create_wifi}
Builds a Topology proto for a WiFi chip.

```python
hw_topo.create_wifi()
```



### hw_topo.create_lte_board {#hw_topo.create_lte_board}
Builds a Topology proto for a LTE board.

```python
hw_topo.create_lte_board()
```



### hw_topo.create_sd_reader {#hw_topo.create_sd_reader}
Builds a Topology proto for a SD reader.

```python
hw_topo.create_sd_reader()
```



### hw_topo.create_motherboard_usb {#hw_topo.create_motherboard_usb}
Builds a Topology proto for a motherboard.

```python
hw_topo.create_motherboard_usb()
```



### hw_topo.create_bluetooth {#hw_topo.create_bluetooth}
Builds a Topology proto for bluetooth.

```python
hw_topo.create_bluetooth()
```



### hw_topo.create_hardware_topology {#hw_topo.create_hardware_topology}
Builds a HardwareTopology proto from Topology protos.

```python
hw_topo.create_hardware_topology()
```



### hw_topo.convert_to_hw_features {#hw_topo.convert_to_hw_features}
Converts a HardwareTopology proto to a HardwareFeatures proto.

```python
hw_topo.convert_to_hw_features()
```



### hw_topo.make_fw_config {#hw_topo.make_fw_config}
Builds a HardwareFeatures.FirmwareConfiguration proto.

Takes a 32-bit mask for the field and an id. Shifts the id
into the mask region and checks that the value fits within the bit mask.

```python
hw_topo.make_fw_config()
```





## //config/util/partner.star

### partner.create {#partner.create}
Builds a Partner proto.

```python
partner.create()
```



### partner.create_list {#partner.create_list}
Builds a PartnerList proto.

```python
partner.create_list()
```





## //config/util/program.star

### program.create {#program.create}
Builds a Program proto.

```python
program.create()
```



### program.create_list {#program.create_list}
Builds a ProgramList proto.

```python
program.create_list()
```



### program.create_firmware_configuration_segment {#program.create_firmware_configuration_segment}
Builds a FirmwareConfigurationSegment proto.

```python
program.create_firmware_configuration_segment()
```



### program.create_design_config_id_segment {#program.create_design_config_id_segment}
Builds a DesignConfigIdSegment proto.

```python
program.create_design_config_id_segment()
```



### program.create_signer_config {#program.create_signer_config}
Builds a DeviceSignerConfig proto.

```python
program.create_signer_config()
```



### program.create_signer_config_by_brand {#program.create_signer_config_by_brand}


```python
program.create_signer_config_by_brand()
```



### program.create_signer_configs_by_brand {#program.create_signer_configs_by_brand}


```python
program.create_signer_configs_by_brand()
```



### program.create_signer_config_by_design {#program.create_signer_config_by_design}


```python
program.create_signer_config_by_design()
```



### program.create_signer_configs_by_design {#program.create_signer_configs_by_design}


```python
program.create_signer_configs_by_design()
```



### program.generate {#program.generate}
Serializes a ConfigBundle to a file.

A json proto is written. Note that there is some post processing done
by the gen_config script to convert this json output into a json
output that uses ints for encoding enums.

```python
program.generate()
```





## //config/util/sw_config.star

### sw_config.create {#sw_config.create}
Deprecated. Use append_configs instead.

```python
sw_config.create()
```



### sw_config.create_audio {#sw_config.create_audio}
Builds an AudioConfig proto.

```python
sw_config.create_audio()
```



### sw_config.create_bluetooth {#sw_config.create_bluetooth}
Builds a BluetoothConfig proto.

```python
sw_config.create_bluetooth()
```



### sw_config.create_x86_id_scan {#sw_config.create_x86_id_scan}
Deprecated. Use design.append_configs

```python
sw_config.create_x86_id_scan()
```



### sw_config.create_arm_id_scan {#sw_config.create_arm_id_scan}
Deprecated. Use design.append_configs

```python
sw_config.create_arm_id_scan()
```



### sw_config.create_fw_version {#sw_config.create_fw_version}
Builds a firmware Version proto.

If major_version is not specified, None is returned.

```python
sw_config.create_fw_version()
```



### sw_config.create_fw_payload {#sw_config.create_fw_payload}
Builds a FirmwarePayload proto.

```python
sw_config.create_fw_payload()
```



### sw_config.create_fw_config {#sw_config.create_fw_config}
Builds a FirmwareConfig proto.

```python
sw_config.create_fw_config()
```



### sw_config.create_fw_payloads_by_names {#sw_config.create_fw_payloads_by_names}
Builds a FirmwareConfig proto using common naming patterns.

```python
sw_config.create_fw_payloads_by_names()
```



### sw_config.create_fw_build_config {#sw_config.create_fw_build_config}
Builds a FirmwareBuildConfig proto.

```python
sw_config.create_fw_build_config()
```



### sw_config.create_fw_build_config_by_names {#sw_config.create_fw_build_config_by_names}
Builds a FirmwareBuildConfig proto using common naming patterns.

Build targets are set to be coreboot_name unless they are otherwise
specified, e.g. depthcharge is set to coreboot_name unless
depthcharge_name is specified. This function is provided as a convenience,
as different firmware build targets often share the same name.

```python
sw_config.create_fw_build_config_by_names()
```



### sw_config.create_fw_build_targets {#sw_config.create_fw_build_targets}
Builds a FirmwareBuildConfig.BuildTargets proto.

```python
sw_config.create_fw_build_targets()
```



### sw_config.create_power {#sw_config.create_power}
Builds a PowerConfig proto.

```python
sw_config.create_power()
```




