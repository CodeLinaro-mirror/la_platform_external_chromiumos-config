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
    public_fields = None,
    overlay_name = None,
    arc_device = None,
    first_api_level = None,
)
```

#### Arguments {#build_target.create-args}

* **name**: Name of the build target, e.g. "galaxy". Required.
* **public_fields**: Fields replicated to public configs. See PublicReplication proto for details.
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



### comp.create_audio_codec {#comp.create_audio_codec}
Builds a Component.AudioCodec proto.

```python
comp.create_audio_codec()
```



### comp.create_battery {#comp.create_battery}


```python
comp.create_battery()
```



### comp.create_ec_flash_chip {#comp.create_ec_flash_chip}
Build a Component.FlashChip proto.

```python
comp.create_ec_flash_chip()
```



### comp.create_flash_chip {#comp.create_flash_chip}
Build a Component.FlashChip proto.

```python
comp.create_flash_chip()
```



### comp.create_embedded_controller {#comp.create_embedded_controller}
Build a Component.EmbeddedController proto.

```python
comp.create_embedded_controller()
```



### comp.create_storage_mmc {#comp.create_storage_mmc}
Build a Component.Storage proto for an MMC device.

```python
comp.create_storage_mmc()
```



### comp.create_tpm {#comp.create_tpm}
Build a Component.Tpm proto.

```python
comp.create_tpm()
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



### comp.append_display_panel {#comp.append_display_panel}


```python
comp.append_display_panel()
```



### comp.append_touchpad {#comp.append_touchpad}


```python
comp.append_touchpad()
```



### comp.append_touchscreen {#comp.append_touchscreen}


```python
comp.append_touchscreen()
```





## //config/util/config_bundle.star

### config_bundle.create {#config_bundle.create}
Builds a ConfigBundle proto.

```python
config_bundle.create()
```



### config_bundle.generate {#config_bundle.generate}
Serializes a ConfigBundle to a file.

A json proto is written. Note that there is some post processing done
by the gen_config script to convert this json output into a json
output that uses ints for encoding enums.

```python
config_bundle.generate()
```





## //config/util/design.star

### design.append_configs {#design.append_configs}
Creates and appends new SW and HW configs.

Create new Software and Hardware Design Configuration with the
specified properties and then append them to the sw_configs and hw_configs
arrays respectively. This ensures that all IDs are consistent.

```python
design.append_configs(
    # Required arguments.
    sw_configs,
    hw_configs,
    design_id,
    config_id,

    # Optional arguments.
    extra_hw_config_public_fields = [],
    extra_sw_config_public_fields = [],
    hardware_topology = None,
    firmware = None,
    firmware_build_config = None,
    bluetooth = None,
    power = None,
    audio = None,
    wifi = None,
    ui = None,
    device_tree_compatible_match = None,
    smbios_name_match_override = None,
)
```

#### Arguments {#design.append_configs-args}

* **sw_configs**: An array to append the new SoftwareConfig to. Required.
* **hw_configs**: An array to append the new Design.Config to. Required.
* **design_id**: A DesignId to use for the Design.Config and SoftwareConfig. Required.
* **config_id**: A str or int used to construct the DesignConfigId for the Design.Config and SoftwareConfig. Required.
* **extra_hw_config_public_fields**: A list of additional str specifying fields on Design.Config that will be made public. See PublicReplication proto for details.
* **extra_sw_config_public_fields**: A list of additional str specifying fields on SoftwareConfig that will be made public. See PublicReplication proto for details.
* **hardware_topology**: A HardwareTopology to be used in the Design.Config.
* **firmware**: A FirmwareConfig to be used in the SoftwareConfig.
* **firmware_build_config**: A FirmwareBuildConfig to be used in the SoftwareConfig.
* **bluetooth**: A BluetoothConfig to be used in the SoftwareConfig.
* **power**: A PowerConfig to be used in the SoftwareConfig.
* **audio**: An AudioConfig to be used in the SoftwareConfig. Can be either a single AudioConfig or a list of AudioConfigs.
* **wifi**: A WifiConfig to be used in the SoftwareConfig.
* **ui**: A UiConfig to be used in the SoftwareConfig.
* **device_tree_compatible_match**: For ARM platform, a str used for device_tree_compatible_match in IdentityScanConfig.
* **smbios_name_match_override**: For x86 platform, a str used for smbios_name_match in IdentityScanConfig. If not specified, the string in DesignId is used.


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
    numpad_present,
    fw_configs = None,
    id = None,
    description = None,
)
```

#### Arguments {#hw_topo.create_keyboard-args}

* **backlight**: True if a backlight is present. Required.
* **pwr_btn_present**: True if a power button is present. Required.
* **kb_type**: A KeyboardType enum. Required.
* **numpad_present**: True if numeric pad is present.
* **fw_configs**: A list of FirmwareConfiguration protos for the form factor.
* **id**: A string identifier for the Topology. If not passed, a default is provided.
* **description**: An English description for the Topology. If not passed, a default is provided.


### hw_topo.create_thermal {#hw_topo.create_thermal}
Builds a Topology proto for thermal.

```python
hw_topo.create_thermal()
```



### hw_topo.create_camera {#hw_topo.create_camera}
Builds a Topology proto for cameras.

```python
hw_topo.create_camera(
    # Optional arguments.
    id = None,
    description = None,
    fw_configs = None,
    camera_devices = None,
    has_user_facing_camera = None,
    has_world_facing_camera = None,
    count = None,
)
```

#### Arguments {#hw_topo.create_camera-args}

* **id**: A string identifier for the Topology.
* **description**: An English description for the Topology.
* **fw_configs**: A list of FirmwareConfiguration protos for the form factor.
* **camera_devices**: A list of HardwareFeatures.Camera.Device protos.
* **has_user_facing_camera**: If there is a user(front)-facing camera. Deprecated, use |camera_devices| instead.
* **has_world_facing_camera**: If there is a world(back)-facing camera. Deprecated, use |camera_devices| instead.
* **count**: The number of cameras. Deprecated, use |camera_devices| instead.


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



### hw_topo.create_barreljack {#hw_topo.create_barreljack}
Builds a Topology proto for barreljack.

```python
hw_topo.create_barreljack()
```



### hw_topo.create_hardware_topology {#hw_topo.create_hardware_topology}
Builds a HardwareTopology proto from Topology protos.

```python
hw_topo.create_hardware_topology()
```



### hw_topo.create_power_button {#hw_topo.create_power_button}
Builds a Topology proto for a power button.

```python
hw_topo.create_power_button(
    # Required arguments.
    region,
    edge,
    position,

    # Optional arguments.
    id = None,
    description = None,
)
```

#### Arguments {#hw_topo.create_power_button-args}

* **region**: A HardwareFeatures.Button.Region enum. Required.
* **edge**: A HardwareFeatures.Button.Edge enum. Required.
* **position**: The percentage for button center position to the display's width/height in primary landscape screen orientation. If edge is LEFT or RIGHT, specifies the button's center position as a fraction of region's height relative to the top of region. For TOP and BOTTOM, specifies the position as a fraction of region width relative to the left side of region. Must be in the range [0.0, 1.0]. Required.
* **id**: A string identifier for the Topology. If not passed, a default is provided.
* **description**: An English description for the Topology. If not passed, a default is provided.


### hw_topo.create_volume_button {#hw_topo.create_volume_button}
Builds a Topology proto for a volume button.

```python
hw_topo.create_volume_button(
    # Required arguments.
    region,
    edge,
    position,

    # Optional arguments.
    id = None,
    description = None,
)
```

#### Arguments {#hw_topo.create_volume_button-args}

* **region**: A HardwareFeatures.Button.Region enum. Required.
* **edge**: A HardwareFeatures.Button.Edge enum. Required.
* **position**: The percentage for button center position to the display's width/height in primary landscape screen orientation. If edge is LEFT or RIGHT, specifies the button's center position as a fraction of region's height relative to the top of region. For TOP and BOTTOM, specifies the position as a fraction of region width relative to the left side of region. Must be in the range [0.0, 1.0]. Required.
* **id**: A string identifier for the Topology. If not passed, a default is provided.
* **description**: An English description for the Topology. If not passed, a default is provided.


### hw_topo.convert_to_hw_features {#hw_topo.convert_to_hw_features}
Converts a HardwareTopology proto to a HardwareFeatures proto.

```python
hw_topo.convert_to_hw_features()
```



### hw_topo.make_camera_device {#hw_topo.make_camera_device}
Builds a HardwareFeatures.Camera.Device proto.

```python
hw_topo.make_camera_device()
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





## //config/util/program.star

### program.create {#program.create}
Builds a Program proto.

```python
program.create()
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





## //config/util/public_replication.star

### public_replication.create {#public_replication.create}
Creates a PublicReplication proto.

```python
public_replication.create(public_fields)
```

#### Arguments {#public_replication.create-args}

* **public_fields**: A list of strings specifying fields that should be made public. See comment on the PublicReplication proto for semantics and example of how the proto works. Required.

#### Returns  {#public_replication.create-returns}
A PublicReplication proto, None if public_fields evaluates to False.




## //config/util/sw_config.star

### sw_config.create_ath10k {#sw_config.create_ath10k}
Builds a WifiConfig proto for use with ath10k drivers.

```python
sw_config.create_ath10k(non_tablet_mode_transmit_power_chain, tablet_mode_transmit_power_chain)
```

#### Arguments {#sw_config.create_ath10k-args}

* **non_tablet_mode_transmit_power_chain**: non-tablet mode power chain. Required.
* **tablet_mode_transmit_power_chain**: tablet mode power chain. Required.


### sw_config.create_ath10k_power_chain {#sw_config.create_ath10k_power_chain}
Builds a TransmitPowerChain for ath10k drivers.

```python
sw_config.create_ath10k_power_chain(limit_2g, limit_5g)
```

#### Arguments {#sw_config.create_ath10k_power_chain-args}

* **limit_2g**: 2G band power limit (dBm). Required.
* **limit_5g**: 5G band power limit (dBm). Required.


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



### sw_config.create_intel_geo_offsets {#sw_config.create_intel_geo_offsets}
Builds a GeoOffsets for intel drivers.

```python
sw_config.create_intel_geo_offsets(
    # Required arguments.
    max_2g,
    offset_2g_a,
    offset_2g_b,
    max_5g,
    offset_5g_a,
    offset_5g_b,
)
```

#### Arguments {#sw_config.create_intel_geo_offsets-args}

* **max_2g**: Defines the 2.4 GHz upper value for the allowed power to not be crossed by applying the Geo offset. Required.
* **offset_2g_a**: Value to be added to the 2.4GHz WiFi band for chain a. (0.125 dBm) Required.
* **offset_2g_b**: Value to be added to the 2.4GHz WiFi band for chain b. (0.125 dBm) Required.
* **max_5g**: Defines the 5 GHz upper value for the allowed power to not be crossed by applying the Geo offset. Required.
* **offset_5g_a**: Value to be added to 5GHz WiFi bands for chain a. (0.125 dBm) Required.
* **offset_5g_b**: Value to be added to 5GHz WiFi bands for chain b. (0.125 dBm) Required.


### sw_config.create_intel_power_chain {#sw_config.create_intel_power_chain}
Builds a TransmitPowerChain for intel drivers.

```python
sw_config.create_intel_power_chain(
    # Required arguments.
    limit_2g,
    limit_5g_1,
    limit_5g_2,
    limit_5g_3,
    limit_5g_4,
)
```

#### Arguments {#sw_config.create_intel_power_chain-args}

* **limit_2g**: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
* **limit_5g_1**: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
* **limit_5g_2**: 5G band 2 power limit: 5.35G-5.47G channels. (0.125 dBm). Required.
* **limit_5g_3**: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
* **limit_5g_4**: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.


### sw_config.create_intel_wifi {#sw_config.create_intel_wifi}
Builds a WifiConfig proto for use with intel drivers.

```python
sw_config.create_intel_wifi(
    # Required arguments.
    non_tablet_mode_transmit_power_chain_a,
    non_tablet_mode_transmit_power_chain_b,
    tablet_mode_transmit_power_chain_a,
    tablet_mode_transmit_power_chain_b,
    fcc_offsets,
    eu_offsets,
    other_offsets,
)
```

#### Arguments {#sw_config.create_intel_wifi-args}

* **non_tablet_mode_transmit_power_chain_a**: non-tablet mode power chain for chain a. Required.
* **non_tablet_mode_transmit_power_chain_b**: non-tablet mode power chain for chain b. Required.
* **tablet_mode_transmit_power_chain_a**: tablet mode power chain for chain a. Required.
* **tablet_mode_transmit_power_chain_b**: tablet mode power chain for chain b. Required.
* **fcc_offsets**: Offsets used for regulatory domains that follow FCC guidelines. Required.
* **eu_offsets**: Offsets used for regulatory domains that follow ESTI guidelines. Required.
* **other_offsets**: Offsets for regulatory domains that don't follow FCC or ETSI guidelines. Required.


### sw_config.create_rtw88 {#sw_config.create_rtw88}
Builds a WifiConfig proto for use with rtw88 drivers.

```python
sw_config.create_rtw88(
    # Required arguments.
    non_tablet_mode_transmit_power_chain,
    tablet_mode_transmit_power_chain,

    # Optional arguments.
    fcc_offsets = None,
    eu_offsets = None,
    other_offsets = None,
)
```

#### Arguments {#sw_config.create_rtw88-args}

* **non_tablet_mode_transmit_power_chain**: non-tablet mode power chain. Required.
* **tablet_mode_transmit_power_chain**: tablet mode power chain. Required.
* **fcc_offsets**: Offsets used for regulatory domains that follow FCC guidelines
* **eu_offsets**: Offsets used for regulatory domains that follow ESTI guidelines
* **other_offsets**: Offsets for regulatory domains that don't follow FCC or ETSI guidelines


### sw_config.create_rtw88_geo_offsets {#sw_config.create_rtw88_geo_offsets}
Builds a GeoOffsets from rtw88 drivers.

```python
sw_config.create_rtw88_geo_offsets(offset_2g, offset_5g)
```

#### Arguments {#sw_config.create_rtw88_geo_offsets-args}

* **offset_2g**: Value to be added to the 2.4GHz WiFi band. (0.125 dBm) Required.
* **offset_5g**: Value to be added to all 5GHz WiFi bands. (0.125 dBm) Required.


### sw_config.create_rtw88_power_chain {#sw_config.create_rtw88_power_chain}
Builds a TransmitPowerChain for rtw88 drivers.

```python
sw_config.create_rtw88_power_chain(
    # Required arguments.
    limit_2g,
    limit_5g_1,
    limit_5g_3,
    limit_5g_4,
)
```

#### Arguments {#sw_config.create_rtw88_power_chain-args}

* **limit_2g**: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
* **limit_5g_1**: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
* **limit_5g_3**: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
* **limit_5g_4**: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.



