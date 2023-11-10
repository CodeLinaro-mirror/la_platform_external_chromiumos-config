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
brand_config.create(
    # Required arguments.
    device_brand_id,

    # Optional arguments.
    wallpaper = None,
    regulatory_label = None,
    whitelabel_tag = None,
    help_content_id = None,
)
```

#### Arguments {#brand_config.create-args}

* **device_brand_id**: A DeviceBrandId proto that is used to select a BrandConfig at runtime. Required.
* **wallpaper**: Base filename of the default wallpaper to show.
* **regulatory_label**: See chromeos-config readme
* **whitelabel_tag**: "whitelabel_tag" value set in the VPD, used to select a BrandConfig at runtime. See https://chromeos.google.com/partner/dlm/docs/factory/vpd.html#field-whitelabel_tag.
* **help_content_id**: help content identifier

#### Returns  {#brand_config.create-returns}
A BrandConfig proto.




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



### comp.create_cellular {#comp.create_cellular}
Builds a Component proto for Cellular device.

```python
comp.create_cellular()
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



### comp.create_amplifier {#comp.create_amplifier}
Builds a Component.Amplifier proto.

```python
comp.create_amplifier()
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



### comp.append_battery {#comp.append_battery}


```python
comp.append_battery()
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
    extra_hw_config_public_fields = None,
    extra_sw_config_public_fields = None,
    hardware_topology = None,
    firmware = None,
    firmware_build_config = None,
    firmware_info = None,
    bluetooth = None,
    power = None,
    audio = None,
    wifi = None,
    camera = None,
    health = None,
    ui = None,
    device_tree_compatible_match = None,
    smbios_name_match_override = None,
    frid = None,
)
```

#### Arguments {#design.append_configs-args}

* **sw_configs**: An array to append the new SoftwareConfig to. Required.
* **hw_configs**: An array to append the new Design.Config to. Required.
* **design_id**: A DesignId to use for the Design.Config and SoftwareConfig. Required.
* **config_id**: A str or int used to construct the DesignConfigId for the Design.Config and SoftwareConfig. Required.
* **extra_hw_config_public_fields**: A list of str specifying fields on Design.Config that will be made public in addition to the default _DEFAULT_PUBLIC_HW_CONFIG_FIELDS. See PublicReplication proto for details.
* **extra_sw_config_public_fields**: A list of str specifying fields on SoftwareConfig that will be made public in addition to the default _DEFAULT_PUBLIC_SW_CONFIG_FIELDS. See PublicReplication proto for details.
* **hardware_topology**: A HardwareTopology to be used in the Design.Config.
* **firmware**: A FirmwareConfig to be used in the SoftwareConfig.
* **firmware_build_config**: A FirmwareBuildConfig to be used in the SoftwareConfig.
* **firmware_info**: Information related to runtime firmware.
* **bluetooth**: A BluetoothConfig to be used in the SoftwareConfig.
* **power**: A PowerConfig to be used in the SoftwareConfig.
* **audio**: An AudioConfig to be used in the SoftwareConfig. Can be either a single AudioConfig or a list of AudioConfigs.
* **wifi**: A WifiConfig to be used in the SoftwareConfig.
* **camera**: A CameraConfig to be used in the SoftwareConfig.
* **health**: A HealthConfig to be used in the SoftwareConfig.
* **ui**: A UiConfig to be used in the SoftwareConfig.
* **device_tree_compatible_match**: For ARM platform, a str used for device_tree_compatible_match in IdentityScanConfig.
* **smbios_name_match_override**: For x86 platform, a str used for smbios_name_match in IdentityScanConfig. If not specified, the string in DesignId is used. Note only one of device_tree_compatible_match and smbios_name_match_override can be specified.
* **frid**: A str used for frid matching.  Note: This will override device_tree_compatible_match and smbios_name_match_override.


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



### hw_topo.create_als_step {#hw_topo.create_als_step}
Builds a Component.AlsStep.
lux_decrease_threshold: An int containing the sensor value below which the
    previous step should be considered. A value of None indicates negative
    infinity.
lux_increase_threshold: An int containing the sensor value above which the
    next step should be considered. A value of None indicates infinity.
ac_backlight_percent: A double containing the backlight brightness
    percentage to use at this step while on AC power.
battery_backlight_percent: A double containing the backlight brightness
    percentage to use at this step while on battery power. If unset,
    defaults to the ac_backlight_percent value.

```python
hw_topo.create_als_step()
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
hw_topo.create_audio(
    # Optional arguments.
    id = None,
    description = None,
    codec = None,
    speaker_amp = None,
    headphone_codec = None,
    fw_configs = None,
    card_configs = None,
    cras_config = None,
)
```

#### Arguments {#hw_topo.create_audio-args}

* **id**: A string identifier for the Topology.
* **description**: An English description for the Topology.
* **codec**: Deprecated.
* **speaker_amp**: An Amplifier enum value specifying the speaker amplifier.
* **headphone_codec**: An AudioCodec enum value specifying the jack codec.
* **fw_configs**: A list of FirmwareConfiguration protos for this audio topology.
* **card_configs**: A list of CardConfig protos specifying card configs to be installed and used for this audio topology.
* **cras_config**: An AudioConfigStructure enum specifying how card-agnostic cras config files are structured. If unset, defaults to DESIGN if any card_configs are passed, otherwise NONE.


### hw_topo.create_audio_card_config {#hw_topo.create_audio_card_config}
Builds a CardConfig proto for an audio card config.

```python
hw_topo.create_audio_card_config(
    # Optional arguments.
    card_name = None,
    ucm_suffix = None,
    cras_config = None,
    ucm_config = None,
    sound_card_init_config = None,
)
```

#### Arguments {#hw_topo.create_audio_card_config-args}

* **card_name**: A string. This should match the card used by ALSA, with an optional suffix starting with a dot, if a suffix representing hardware details, such as the speaker amplifier or jack codec is required. For example, "sof-rt5682.max98373".
* **ucm_suffix**: An optional format string used to generate the remainder of the UCM suffix not referring to audio components. If unset, the program-wide default suffix is used. The following placeholders may be used:     {design}: The design name.     {camera_count}: The number of cameras (usually 0, 1 or 2).     {headset_codec}: The headset codec name (in lowercase)         specified in the topology containing this card config.     {speaker_amp}: The speaker amp name (in lowercase) specified in         the topology containing this card config.     {mic_description}: A description of the microphone topology, of         the form {user_facing_mic_count}uf{world_facing_mic_count}wf, with         components elided if their count is 0.     {total_mic_count}: The total number of internal microphones.     {user_facing_mic_count}: The number of internal user-facing microphones.     {world_facing_mic_count}: The number of internal world-facing microphones. It is strongly recommended that any details of the speaker amplifier or jack codec not be included in this suffix - they should instead be included as part of card_name.
* **cras_config**: An AudioConfigStructure enum specifying how cras config files are structured for this card. If unset, defaults to DESIGN.
* **ucm_config**: An AudioConfigStructure enum specifying how ALSA UCM config files are structured for this card. If unset, defaults to DESIGN.
* **sound_card_init_config**: An AudioConfigStructure enum specifying how sound card init config files are structured for this card. If unset, defaults to NONE.


### hw_topo.override_audio {#hw_topo.override_audio}


```python
hw_topo.override_audio()
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
    numpad_present = None,
    fw_configs = None,
    id = None,
    description = None,
    backlight_user_steps = None,
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
* **backlight_user_steps**: A list of doubles specifying the user-selectable backlight steps in increasing order, starting from 0. This controls the keyboard_backlight_user_steps powerd pref.
* **mcu_type**: A KeyboardMcuType enum. Optional.


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
)
```

#### Arguments {#hw_topo.create_camera-args}

* **id**: A string identifier for the Topology.
* **description**: An English description for the Topology.
* **fw_configs**: A list of FirmwareConfiguration protos for the form factor.
* **camera_devices**: A list of HardwareFeatures.Camera.Device protos.


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
Builds a Topology proto for proximity sensors.

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



### hw_topo.create_cellular_board {#hw_topo.create_cellular_board}
Builds a Topology proto for a Cellular board.

```python
hw_topo.create_cellular_board()
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



### hw_topo.create_usbc_port {#hw_topo.create_usbc_port}
Builds a UsbC Port.

```python
hw_topo.create_usbc_port(position = None, index_override = None)
```

#### Arguments {#hw_topo.create_usbc_port-args}

* **position**: An optional topo_pb.HardwareFeatures.PortPosition indicating the position of this port on the side of the chassis it occupies. Required if more than one USB-C port is present on the same side of the chassis.
* **index_override**: An optional int specifying the 0-indexed index of this port. For ports with this unset, the motherboard ports will be ordered before the daughter board ports, in the order they are specified, leaving gaps as needed for ports with an override set. If set, this value must be in the range [0, number_of_usb_c_ports).


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



### hw_topo.create_power_supply {#hw_topo.create_power_supply}
Builds a Topology proto for power supply.

```python
hw_topo.create_power_supply(
    # Optional arguments.
    id = None,
    description = None,
    bj_present = None,
    usb_min_ac_watts = None,
    fw_configs = None,
)
```

#### Arguments {#hw_topo.create_power_supply-args}

* **id**: A string identifier for the Topology.
* **description**: An English description for the Topology.
* **bj_present**: A bool containing whether a barreljack power port is present
* **usb_min_ac_watts**: The input power below which a warning should be shown to use a higher-power USB adapter.
* **fw_configs**: A list of firmware configs implied by the Topology.


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


### hw_topo.create_touch {#hw_topo.create_touch}
Builds a Topology proto for touch.

```python
hw_topo.create_touch()
```



### hw_topo.create_microphone_mute_switch {#hw_topo.create_microphone_mute_switch}
Builds a Topology proto for an microphone mute switch.

```python
hw_topo.create_microphone_mute_switch(present = None)
```

#### Arguments {#hw_topo.create_microphone_mute_switch-args}

* **present**: flag indicating whether the device has an microphone mute switch


### hw_topo.create_hdmi {#hw_topo.create_hdmi}
Builds a Topology proto for HDMI.

```python
hw_topo.create_hdmi()
```



### hw_topo.create_hps {#hw_topo.create_hps}
Builds a Topology proto for HPS.

```python
hw_topo.create_hps()
```



### hw_topo.create_dp_converter {#hw_topo.create_dp_converter}
Builds a Topology proto for DisplayPort converters.

```python
hw_topo.create_dp_converter()
```



### hw_topo.create_poe {#hw_topo.create_poe}
Builds a Topology proto for PoE.

```python
hw_topo.create_poe()
```



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



### hw_topo.create_ec {#hw_topo.create_ec}
Builds a Topology proto for an embedded controller.

```python
hw_topo.create_ec(present = None, ec_type = None, id = None)
```

#### Arguments {#hw_topo.create_ec-args}

* **present**: flag indicating whether the device has an EC at all
* **ec_type**: An EmbeddedControllerType enum
* **id**: A string identifier for the Topology. If not passed, a default is provided.


### hw_topo.create_tpm {#hw_topo.create_tpm}
Builds a Topology proto for a trusted platform module.

```python
hw_topo.create_tpm(tpm_type = None, id = None, fw_configs = None)
```

#### Arguments {#hw_topo.create_tpm-args}

* **tpm_type**: A TrustedPlatformModuleType enum
* **id**: A string identifier for the Topology. If not passed, a default is provided.
* **fw_configs**: A list of FirmwareConfiguration protos for the tpm.




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



### program.create_audio_config {#program.create_audio_config}
Builds an AudioConfig proto.

```python
program.create_audio_config()
```



### program.create_platform {#program.create_platform}


```python
program.create_platform()
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



### sw_config.create_camera {#sw_config.create_camera}
Builds a CameraConfig proto.

```python
sw_config.create_camera()
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
Builds a Firmware.BuildTargets proto.

```python
sw_config.create_fw_build_targets()
```



### sw_config.create_health {#sw_config.create_health}
Builds a HealthConfig proto.

```python
sw_config.create_health()
```



### sw_config.create_power {#sw_config.create_power}
Builds a PowerConfig proto.

```python
sw_config.create_power()
```



### sw_config.create_intel_antenna_gain {#sw_config.create_intel_antenna_gain}
Builds AntennaGain for intel drivers.

```python
sw_config.create_intel_antenna_gain(
    # Required arguments.
    ant_gain_5g_1,
    ant_gain_5g_2,
    ant_gain_5g_3,
    ant_gain_5g_4,

    # Optional arguments.
    ant_gain_2g = None,
    ant_gain_5g_5 = None,
    ant_gain_6g_1 = None,
    ant_gain_6g_2 = None,
    ant_gain_6g_3 = None,
    ant_gain_6g_4 = None,
    ant_gain_6g_5 = None,
)
```

#### Arguments {#sw_config.create_intel_antenna_gain-args}

* **ant_gain_2g**: Antenna gain used for 2400MHz frequency.
* **ant_gain_5g_1**: Antenna gain used for 5150–5350MHz frequency. Required.
* **ant_gain_5g_2**: Antenna gain used for 5350–5470MHz frequency. Required.
* **ant_gain_5g_3**: Antenna gain used for 5470–5725MHz frequency. Required.
* **ant_gain_5g_4**: Antenna gain used for 5725–5950MHz frequency. Required.
* **ant_gain_5g_5**: Antenna gain used for 5945–6165MHz frequency. Rev 1 & 2.
* **ant_gain_6g_1**: Antenna gain used for 6165–6405MHz frequency. Rev 1 & 2.
* **ant_gain_6g_2**: Antenna gain used for 6405–6525MHz frequency. Rev 1 & 2.
* **ant_gain_6g_3**: Antenna gain used for 6525–6705MHz frequency. Rev 1 & 2.
* **ant_gain_6g_4**: Antenna gain used for 6705–6865MHz frequency. Rev 1 & 2.
* **ant_gain_6g_5**: Antenna gain used for 6865–7105MHz frequency. Rev 1 & 2.


### sw_config.create_intel_antgain_table {#sw_config.create_intel_antgain_table}
Builds a antenna Gains for intel drivers.

```python
sw_config.create_intel_antgain_table(
    # Optional arguments.
    ant_table_revision = None,
    ant_ppag_mode = None,
    ant_gain_chain_a = None,
    ant_gain_chain_b = None,
)
```

#### Arguments {#sw_config.create_intel_antgain_table-args}

* **ant_table_revision**: Antenna gains table revision
* **ant_ppag_mode**: Defines the mode of the ANT_gain control to be used.
* **ant_gain_chain_a**: Defines the ANT_gain in dBi for chain A to be used.
* **ant_gain_chain_b**: Defines the ANT_gain in dBi for chain B to be used.


### sw_config.create_intel_dsm {#sw_config.create_intel_dsm}
Builds a DSM for intel drivers.

```python
sw_config.create_intel_dsm(
    # Optional arguments.
    disable_active_sdr_channels = None,
    support_indonesia_5g_band = None,
    support_ultra_high_band = None,
    regulatory_configurations = None,
    uart_configurations = None,
    enablement_11ax = None,
    unii_4 = None,
)
```

#### Arguments {#sw_config.create_intel_dsm-args}

* **disable_active_sdr_channels**: Allow OEMs to set ETSI 5.8GHz SRD Channels to Passive/Disabled.
* **support_indonesia_5g_band**: Enable/Disable 5.15-5.35GHz band support in Indonesia.
* **support_ultra_high_band**: Control the enablement of 6 GHz band.
* **regulatory_configurations**: Regulatory special configurations enablements value.
* **uart_configurations**: M.2 UART interface configuration.
* **enablement_11ax**: Control enablement of 11ax on certificated modules.
* **unii_4**: Control enablement of UNII-4 over certificate modules.


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

    # Optional arguments.
    max_6g = None,
    offset_6g_a = None,
    offset_6g_b = None,
)
```

#### Arguments {#sw_config.create_intel_geo_offsets-args}

* **max_2g**: Defines the 2.4 GHz upper value for the allowed power to not be crossed by applying the Geo offset. Required.
* **offset_2g_a**: Value to be added to the 2.4GHz WiFi band for chain a. (0.125 dBm) Required.
* **offset_2g_b**: Value to be added to the 2.4GHz WiFi band for chain b. (0.125 dBm) Required.
* **max_5g**: Defines the 5 GHz upper value for the allowed power to not be crossed by applying the Geo offset. Required.
* **offset_5g_a**: Value to be added to 5GHz WiFi bands for chain a. (0.125 dBm) Required.
* **offset_5g_b**: Value to be added to 5GHz WiFi bands for chain b. (0.125 dBm) Required.
* **max_6g**: Defines the 6 GHz upper value for the allowed power to not be crossed by applying the Geo offset. Rev 1 & 2.
* **offset_6g_a**: Value to be added to 6GHz WiFi bands for chain a. (0.125 dBm) Rev 1 & 2.
* **offset_6g_b**: Value to be added to 6GHz WiFi bands for chain b. (0.125 dBm) Rev 1 & 2.


### sw_config.create_intel_offsets_table {#sw_config.create_intel_offsets_table}
Builds a Geo Offsets proto for use with intel drivers.

```python
sw_config.create_intel_offsets_table(
    # Optional arguments.
    wgds_revision = None,
    fcc_offsets = None,
    eu_offsets = None,
    other_offsets = None,
)
```

#### Arguments {#sw_config.create_intel_offsets_table-args}

* **wgds_revision**: Geo delta table revision,
* **fcc_offsets**: Offsets used for regulatory domains that follow FCC guidelines.
* **eu_offsets**: Offsets used for regulatory domains that follow ESTI guidelines.
* **other_offsets**: Offsets for regulatory domains that don't follow FCC or ETSI guidelines.


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

    # Optional arguments.
    limit_5g_5 = None,
    limit_6g_1 = None,
    limit_6g_2 = None,
    limit_6g_3 = None,
    limit_6g_4 = None,
    limit_6g_5 = None,
)
```

#### Arguments {#sw_config.create_intel_power_chain-args}

* **limit_2g**: 2G band power limit: All 2G band channels. (0.125 dBm). Required.
* **limit_5g_1**: 5G band 1 power limit: 5.15G-5.35G channels. (0.125 dBm). Required.
* **limit_5g_2**: 5G band 2 power limit: 5.35G-5.47G channels. (0.125 dBm). Required.
* **limit_5g_3**: 5G band 3 power limit: 5.47G-5.725G channels. (0.125 dBm). Required.
* **limit_5g_4**: 5G band 4 power limit: 5.725G-5.95G channels. (0.125 dBm). Required.
* **limit_5g_5**: 5G band 5 power limit: 5.95G-6.165G channels. (0.125 dBm). Rev 1 & 2.
* **limit_6g_1**: 6G band 1 power limit: 6.165G-6.405G channels. (0.125 dBm). Rev 1 & 2.
* **limit_6g_2**: 6G band 2 power limit: 6.405G-6.525G channels. (0.125 dBm). Rev 1 & 2.
* **limit_6g_3**: 6G band 3 power limit: 6.525G-6.705G channels. (0.125 dBm). Rev 1 & 2.
* **limit_6g_4**: 6G band 4 power limit: 6.705G-6.865G channels. (0.125 dBm). Rev 1 & 2.
* **limit_6g_5**: 6G band 5 power limit: 6.865G-7.105G channels. (0.125 dBm). Rev 1 & 2.


### sw_config.create_intel_sar_table {#sw_config.create_intel_sar_table}
Builds a SarTable proto for use with intel drivers.

```python
sw_config.create_intel_sar_table(
    # Optional arguments.
    sar_table_revision = None,
    tablet_mode_transmit_power_chain_a = None,
    tablet_mode_transmit_power_chain_b = None,
    non_tablet_mode_transmit_power_chain_a = None,
    non_tablet_mode_transmit_power_chain_b = None,
    cdb_tablet_mode_transmit_power_chain_a = None,
    cdb_tablet_mode_transmit_power_chain_b = None,
    cdb_non_tablet_mode_transmit_power_chain_a = None,
    cdb_non_tablet_mode_transmit_power_chain_b = None,
)
```

#### Arguments {#sw_config.create_intel_sar_table-args}

* **sar_table_revision**: SAR table revision.
* **tablet_mode_transmit_power_chain_a**: Tablet mode power chain for chain a.
* **tablet_mode_transmit_power_chain_b**: Tablet mode power chain for chain b.
* **non_tablet_mode_transmit_power_chain_a**: Non-tablet mode power chain for chain a.
* **non_tablet_mode_transmit_power_chain_b**: Non-tablet mode power chain for chain b.
* **cdb_tablet_mode_transmit_power_chain_a**: Tablet mode concurrency dual band power chain for chain a.
* **cdb_tablet_mode_transmit_power_chain_b**: Tablet mode concurrency dual band power chain for chain b.
* **cdb_non_tablet_mode_transmit_power_chain_a**: Non-tablet mode concurrency dual band power chain for chain a.
* **cdb_non_tablet_mode_transmit_power_chain_b**: Non-tablet mode concurrency dual band power chain for chain b.


### sw_config.create_intel_sar_avg_table {#sw_config.create_intel_sar_avg_table}
Builds a wifi time average SAR proto for use with intel drivers.

```python
sw_config.create_intel_sar_avg_table(
    # Optional arguments.
    wtas_revision = None,
    tas_selection = None,
    tas_list_size = None,
    deny_list_entry_1 = None,
    deny_list_entry_2 = None,
    deny_list_entry_3 = None,
    deny_list_entry_4 = None,
    deny_list_entry_5 = None,
    deny_list_entry_6 = None,
    deny_list_entry_7 = None,
    deny_list_entry_8 = None,
    deny_list_entry_9 = None,
    deny_list_entry_10 = None,
    deny_list_entry_11 = None,
    deny_list_entry_12 = None,
    deny_list_entry_13 = None,
    deny_list_entry_14 = None,
    deny_list_entry_15 = None,
    deny_list_entry_16 = None,
)
```

#### Arguments {#sw_config.create_intel_sar_avg_table-args}

* **wtas_revision**: Wifi time average SAR version.
* **tas_selection**: Enable/disable the TAS feature.
* **tas_list_size**: Represents the number of blocked countries that are not approved by the OEM to support this feature, even if that feature is enabled.
* **deny_list_entry_1**: ISO country code 1 to block.
* **deny_list_entry_2**: ISO country code 2 to block.
* **deny_list_entry_3**: ISO country code 3 to block.
* **deny_list_entry_4**: ISO country code 4 to block.
* **deny_list_entry_5**: ISO country code 5 to block.
* **deny_list_entry_6**: ISO country code 6 to block.
* **deny_list_entry_7**: ISO country code 7 to block.
* **deny_list_entry_8**: ISO country code 8 to block.
* **deny_list_entry_9**: ISO country code 9 to block.
* **deny_list_entry_10**: ISO country code 10 to block.
* **deny_list_entry_11**: ISO country code 11 to block.
* **deny_list_entry_12**: ISO country code 12 to block.
* **deny_list_entry_13**: ISO country code 13 to block.
* **deny_list_entry_14**: ISO country code 14 to block.
* **deny_list_entry_15**: ISO country code 15 to block.
* **deny_list_entry_16**: ISO country code 16 to block.


### sw_config.create_intel_wifi {#sw_config.create_intel_wifi}
Builds a IntelConfig proto for use with intel drivers.

```python
sw_config.create_intel_wifi(
    # Optional arguments.
    sar_table = None,
    wgds_table = None,
    ant_table = None,
    wtas_table = None,
    dsm = None,
)
```

#### Arguments {#sw_config.create_intel_wifi-args}

* **sar_table**: SarTable proto for use with intel driver.
* **wgds_table**: Geo Offsets proto for use with intel driver.
* **ant_table**: Antenna Gains for use with intel driver.
* **wtas_table**: Time average SAR for use with intel driver.
* **dsm**: Device specific methods return values for intel driver.


### sw_config.create_mtk_geo_power_chain {#sw_config.create_mtk_geo_power_chain}
Builds a GeoTransmitPowerChain for mtk drivers.

```python
sw_config.create_mtk_geo_power_chain(
    # Required arguments.
    limit_2g,
    limit_5g,
    offset_2g,
    offset_5g,
)
```

#### Arguments {#sw_config.create_mtk_geo_power_chain-args}

* **limit_2g**: 2G band geo power limit. (0.25 dBm). Required.
* **limit_5g**: 5G band geo power limit. (0.25 dBm). Required.
* **offset_2g**: Value to be added to the 2.4GHz WiFi band. (0.25 dBm). Required.
* **offset_5g**: Value to be added to all 5GHz WiFi bands. (0.25 dBm). Required.


### sw_config.create_mtk_power_chain {#sw_config.create_mtk_power_chain}
Builds a TransmitPowerChain for mtk drivers.

```python
sw_config.create_mtk_power_chain(
    # Required arguments.
    limit_2g,
    limit_5g_1,
    limit_5g_2,
    limit_5g_3,
    limit_5g_4,
)
```

#### Arguments {#sw_config.create_mtk_power_chain-args}

* **limit_2g**: 2G band power limit. (0.25 dBm). Required.
* **limit_5g_1**: 5G band 1 power limit: 5.15G-5.35G frequency. (0.25 dBm). Required.
* **limit_5g_2**: 5G band 2 power limit: 5.35G-5.47G frequency. (0.25 dBm). Required.
* **limit_5g_3**: 5G band 3 power limit: 5.47G-5.725G frequency. (0.25 dBm). Required.
* **limit_5g_4**: 5G band 4 power limit: 5.725G-5.95G frequency. (0.25 dBm). Required.


### sw_config.create_mtk_wifi {#sw_config.create_mtk_wifi}
Builds a WifiConfig proto for use with mtk drivers.

```python
sw_config.create_mtk_wifi(
    # Required arguments.
    non_tablet_mode_transmit_power_chain,
    tablet_mode_transmit_power_chain,

    # Optional arguments.
    fcc_transmit_power_chain = None,
    eu_transmit_power_chain = None,
    other_transmit_power_chain = None,
)
```

#### Arguments {#sw_config.create_mtk_wifi-args}

* **non_tablet_mode_transmit_power_chain**: non-tablet mode power chain. Required.
* **tablet_mode_transmit_power_chain**: tablet mode power chain. Required.
* **fcc_transmit_power_chain**: power chain for regulatory domains that follow FCC guidelines.
* **eu_transmit_power_chain**: power chain for regulatory domains that follow ESTI guidelines.
* **other_transmit_power_chain**: power chain for regulatory domains that don't follow FCC or ETSI guidelines.


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


### sw_config.create_rtw89 {#sw_config.create_rtw89}
Builds a WifiConfig proto for use with rtw89 drivers.

```python
sw_config.create_rtw89(
    # Required arguments.
    non_tablet_mode_transmit_power_chain,
    tablet_mode_transmit_power_chain,

    # Optional arguments.
    fcc_offsets = None,
    eu_offsets = None,
    other_offsets = None,
)
```

#### Arguments {#sw_config.create_rtw89-args}

* **non_tablet_mode_transmit_power_chain**: non-tablet mode power chain. Required.
* **tablet_mode_transmit_power_chain**: tablet mode power chain. Required.
* **fcc_offsets**: Offsets used for regulatory domains that follow FCC guidelines
* **eu_offsets**: Offsets used for regulatory domains that follow ESTI guidelines
* **other_offsets**: Offsets for regulatory domains that don't follow FCC or ETSI guidelines


### sw_config.create_rtw89_geo_offsets {#sw_config.create_rtw89_geo_offsets}
Builds a GeoOffsets from rtw89 drivers.

```python
sw_config.create_rtw89_geo_offsets(offset_2g, offset_5g)
```

#### Arguments {#sw_config.create_rtw89_geo_offsets-args}

* **offset_2g**: Value to be added to the 2.4GHz WiFi band. (0.25 dBm) Required.
* **offset_5g**: Value to be added to all 5GHz WiFi bands. (0.25 dBm) Required.


### sw_config.create_rtw89_power_chain {#sw_config.create_rtw89_power_chain}
Builds a TransmitPowerChain for rtw89 drivers.

```python
sw_config.create_rtw89_power_chain(
    # Required arguments.
    limit_2g,
    limit_5g_1,
    limit_5g_3,
    limit_5g_4,
)
```

#### Arguments {#sw_config.create_rtw89_power_chain-args}

* **limit_2g**: 2G band power limit: All 2G band channels. (0.25 dBm). Required.
* **limit_5g_1**: 5G band 1 power limit: 5.15G-5.35G channels. (0.25 dBm). Required.
* **limit_5g_3**: 5G band 3 power limit: 5.47G-5.725G channels. (0.25 dBm). Required.
* **limit_5g_4**: 5G band 4 power limit: 5.725G-5.95G channels. (0.25 dBm). Required.


### sw_config.create_ui {#sw_config.create_ui}


```python
sw_config.create_ui()
```



### sw_config.create_usb {#sw_config.create_usb}


```python
sw_config.create_usb()
```



### sw_config.make_resolution {#sw_config.make_resolution}


```python
sw_config.make_resolution()
```
