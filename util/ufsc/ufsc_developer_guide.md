# **Unified Firmware and Second Source Configuration(UFSC) Developer's Guide**

# Introduction & Context

This guide explains the process for developers to add or modify fields within the Unified Firmware and Second Source Configuration (UFSC) system. This system aims to replace the legacy `FW_CONFIG` and `SSFC` mechanisms by providing a consistent, schema-driven approach for defining firmware configurations consumed by AP (coreboot) and EC firmware.

**Key Concepts:**

* **Standardization:** Defines firmware configuration fields (bit position, size, target consumer) centrally.
* **Schema-Driven:** A primary Starlark schema file acts as the source of truth for the layout.
* **Project-Specific Values:** Each project defines the specific integer values for the options relevant to its hardware.
* **Generation Script:** A Python script (`generate_ufsc.py`) uses the schema and project definitions to generate firmware-consumable configuration files.
* **Structure:** The configuration is encoded into multiple 32-bit DWORDs stored in the EC's CBI (CrOS Board Info). The current implementation uses 4 DWORDs for standardized fields. OEM customization fields are provided to define device specific non-standardized firmware configuration.
* **OEM Customization Bits:** These are dedicated, reserved fields within the standardized firmware schema (for AP and EC) that allow OEMs/ODMs to define specific firmware configurations for a particular board. This mechanism provides essential flexibility for board-specific settings. Example: WiFi SAR ID is not part of standardized fields and needs to be managed through OEM customization bits.
* **Consumers:** Fields are explicitly marked for use by "AP", "EC", or "BOTH".

# Overview of Key Files

Making changes involves modifying several related files:

1. **`src/config/util/ufsc/unified_fw_config_schema.json:`**
    * **Purpose:** The **primary source of truth** defining the bit layout. This is a **JSON file** that contains the schema as a single object.
    * **Modification:** Add/modify field entries here first.
        1. Top-level keys are the field names\[uppercase\].
        2. Each entry is an object with keys: **`dword`**, **`start_bit`**, **`end_bit`**, **`used_by`**, and an optional **`description`**.
2. **`src/config/proto/chromiumos/api/software/unified_fw_config.proto`**:
    * **Purpose:** Defines the `FirmwareConfig` protobuf message structure used internally by the configuration system (e.g., in `config.star`).
    * **Modification:** Add/rename fields here to match the schema (**must be lowercase version of the schema key**, `uint32` type).
3. **`src/config/util/ufsc/unified_fw_config.star`**:
    * **Purpose:** Contains Starlark utility functions (`_create_firmware_config`, `_encode_to_dwords`) used by project `config.star` files.
    * **Modification:** Update the `_create_firmware_config` function signature and its internal mapping to match the proto file changes. The `_encode_to_dwords` function is generic and shouldn't need changes if the schema\<-\>proto naming convention is followed.
4. **`src/project/<program>/<project>/fw_config_defs.star`**:
    * **Purpose:** Defines project-specific option names and their corresponding integer values. Contains the `fw_config_defs` struct mapping schema keys to these option structs.
    * **Modification:** Define a local `_<FieldName>` struct for the new/modified field's options. Add/update the entry in the final `fw_config_defs` struct (key **must** match the schema key).
5. **`src/config/payload_utils/generate_ufsc.py`**:
    * **Purpose:** The Python script that reads the schema and project definitions to generate the EC and AP UFSC definitions files.
    * **Modification:** Generally **no modifications needed** unless the schema structure itself changes fundamentally.
6. **`src/project/<program>/<project>/<project>_ap_fw_config.cb`**:
    * **Purpose:** **Generated file** for AP firmware consumption (Coreboot/sconfig). Defines fields and options in a specific text format.
    * **Modification:** **Do not edit directly.** Regenerate using `generate_ufsc.py`.
7. **`src/project/<program>/<project>/<project>_ec_ufsc.dtsi`**:
    * **Purpose:** **Generated file** for EC firmware consumption (Zephyr Devicetree). Defines nodes representing fields and options.
    * **Modification:** **Do not edit directly.** Regenerate using `generate_ufsc.py`.

# Step-by-Step Guide for Adding/Modifying Fields

Follow these steps **in order** to ensure consistency across the system.

**Step 1: Update Schema (`unified_fw_config_schema.star`)**

* Locate `src/config/util/ufsc/unified_fw_config_schema.star`.
* Find the appropriate `DWORD` section or add a new field.
* Add or modify the entry in the `UNIFIED_FW_CONFIG_SCHEMA` struct:

```
MY_NEW_FIELD = struct(DWORD = n, START = x, END = y, USED_BY = "AP|EC|BOTH"),
```

* Choose unique `START` and `END` bits within the `DWORD`. Ensure no overlaps.
* Set `USED_BY` correctly.

**Step 2: Update Proto (`unified_fw_config.proto`)**

* Locate `src/config/proto/chromiumos/api/software/unified_fw_config.proto`.
* Add or rename the corresponding field within the `FirmwareConfig` message.
    * The field name **must** be the **lowercase version** of the schema key (e.g., `MY_NEW_FIELD` \-\> `my_new_field`).
    * The type **must** be `uint32` (even for boolean flags, which use 0/1).
    * Assign the next available unique field number.

```
message FirmwareConfig {
  // ... existing fields ...
  uint32 my_new_field = 35; // Next available number
}
```

* **Regenerate Protobuf Bindings:** This step is critical and depends on your build environment. You might need to run `protoc` or specific build targets to update the generated code used by Starlark and other tools. Failure to do this will cause errors later.

**Step 3: Update Utility (`unified_fw_config.star`)**

* Locate `src/config/util/unified_fw_config.star`.
* Modify the `_create_firmware_config` function:
    * Add/rename the corresponding argument (must be lowercase schema key).
    * Update the `return fw_config_pb.FirmwareConfig(...)` block to correctly map the new argument to the new proto field.

```
def _create_firmware_config(
        # ... existing args ...,
        my_new_field = None): # Add new arg
    """Builds a FirmwareConfig proto."""
    return fw_config_pb.FirmwareConfig(
        # ... existing mappings ...,
        my_new_field = my_new_field, # Add mapping
    )
```

*
The `_encode_to_dwords` function should **not** require changes if the naming convention (SchemaKey \-\> lowercaseschemakey) was followed correctly.

**Step 4: Update Project Definitions (`<project>/fw_config_defs.star`)**

* Navigate to your project directory (e.g., `src/project/fatcat/<project1>/`).
* Open `fw_config_defs.star`.
* Define a new local struct (conventionally prefixed with `_`) listing the specific option names and their integer values for this field *in this project*.

```
_MyNewField = struct(
    MY_NEW_FIELD_OPTION_A = 0,
    MY_NEW_FIELD_OPTION_B = 1,
    MY_NEW_FIELD_OPTION_C = 2,
)
```

*
Ensure values are within the bit range defined in the schema.
* Use `_UNKNOWN = 0` or `_ABSENT = 0` / `_PRESENT = 1` conventions where appropriate.
* Add/Update the entry in the **final `fw_config_defs` struct** at the bottom of the file.
    * The key **must** be the **exact uppercase schema key**.
    * The value is the local `_Struct` you just defined.

```
fw_config_defs = struct(
    # ... existing entries ...
    MY_NEW_FIELD = _MyNewField, # Add this mapping
)
```

**Step 5: Run Generator Script (`generate_ufsc.py`)**

* Make sure you are in the project directory (`src/project/<program>/<project>/`).
* Ensure the `config` symlink (`./config -> src/config`) exists.
* Run the script:

```
 ./config/payload_utils/generate_ufsc.py
```

*
(Or specify `ap` or `ec` to generate only one file).
* Check the generated/updated files (`<project>_ap_fw_config.cb`, `<project>_ec_ufsc.dtsi`) for correctness. Verify the new field appears with the correct bits and options.

**Step 6: Update Consumers (Firmware)**

* **AP (Coreboot):** Developers need to update the mainboard's devicetree (`devicetree.cb` or similar) by adding/modifying the `field` and `option` definitions based on the generated `<project>_ap_fw_config.cb`. Code using the config typically relies on headers generated by `sconfig` from the devicetree.
* **EC (Zephyr):** Developers need to ensure the EC board's devicetree includes or overlays the information from the generated `<project>_ec_ufsc.dtsi`. EC code typically uses `DT_NODELABEL` and Zephyr's devicetree/CBI APIs to check configuration values.
* Commit the generated files along with your changes to the `.star` and `.proto` files.

# Using the `generate_ufsc.py` Script

* **Location:** `src/config/payload_utils/generate_ufsc.py`
* **Purpose:** Reads the central schema (`./config/util/ufsc/unified_fw_config_schema.json`) and the project's definitions (`./fw_config_defs.star`) to create the AP (`.cb`) and EC (`.dtsi`) configuration files specific to that project.
* **Execution:** Must be run from the target project's directory (e.g., `cd src/project/fatcat/<project1>/`).
* **Command:**

```
# Generate both AP and EC files
./config/payload_utils/generate_ufsc.py

# Generate only AP file
./config/payload_utils/generate_ufsc.py ap

# Generate only EC file
./config/payload_utils/generate_ufsc.py ec
```

* **Output:** Creates/overwrites `<project_name>_ap_fw_config.cb` and `<project_name>_ec_ufsc.dtsi` in the current (project) directory. These files are for local reference and should not be committed in repo.
* **Dependencies:** Requires the `./config` symlink to exist and find the schema file. Requires `./fw_config_defs.star` to exist and be valid.

# Sample Generated Files

Running the script in the boxster `project` directory produces:

## \<project\>\_ap\_fw\_config.cb

```
fw_config
	field AUDIO_CODEC 0 2
		option AUDIO_CODEC_UNKNOWN	0
		option AUDIO_CODEC_ALC272	1
	end
	field CAMERA_UFC_NAME 6 8
		option CAMERA_UFC_NAME_UNKNOWN	0
		option CAMERA_UFC_NAME_OVI123	1
	end
	field STORAGE_TYPE 12 14
		option STORAGE_TYPE_UNKNOWN	0
		option STORAGE_TYPE_NVME_GEN4	1
		option STORAGE_TYPE_NVME_GEN5	2
	end
	field TOUCHSCREEN 17 18
		option TOUCHSCREEN_UNKNOWN	0
		option TOUCHSCREEN_COMP1	1
	end
	field FINGERPRINT_PRESENT 24 24
		option FINGERPRINT_ABSENT	0
		option FINGERPRINT_PRESENT	1
	end
	field WIFI_INTERFACE 25 26
		option WIFI_INTERFACE_UNKNOWN	0
		option WIFI_INTERFACE_CNVI	1
	end
	field TRACKPAD 32 34
		option TRACKPAD_UNKNOWN	0
		option TRACKPAD_PCT4802QR	1
	end
	field TRACKPAD_SOC_INTERFACE 37 38
		option TRACKPAD_SOC_INTERFACE_UNKNOWN	0
		option TRACKPAD_SOC_INTERFACE_I2C_LPSS	1
		option TRACKPAD_SOC_INTERFACE_I2C_THC	2
	end
	field KB_BACKLIGHT_PRESENT 43 43
		option KB_BACKLIGHT_ABSENT	0
		option KB_BACKLIGHT_PRESENT	1
	end
end
```

## \<project\>\_ec\_ufsc.dtsi

```
/* Auto-generated by generate_ufsc.py */

&ufsc_kb_backlight_present {
	ufsc_kb_backlight_absent: kb-backlight-absent {
		compatible = "cros-ec,cbi-ufsc-value";
		status = "okay";
		value = <0>;
	};
	ufsc_kb_backlight_present: kb-backlight-present {
		compatible = "cros-ec,cbi-ufsc-value";
		status = "okay";
		value = <1>;
	};
};

```

# Coreboot Changes

* Ensure EC\_GOOGLE\_CHROMEEC\_FW\_CONFIG\_FROM\_UFSC is selected for mainboard or variant
* Manually copy the firmware configuration definitions from **`<project>_ap_fw_config.cb`** into
  variant/\<variant\_name\>/[overritree.cb](http://overritree.cb).
* Make mainboard specific changes in variant specific fw\_config,c or probe definitions in  devicetree and depthcharge as needed.

# EC Changes

* Use **`<project>_ec_ufsc.dtsi`** in project.overlay
* Please refer to [https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform/ec/docs/zephyr/zephyr\_ufsc.md](https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform/ec/docs/zephyr/zephyr_ufsc.md) for more information.


# Tooling

Please refer to tooling details in zephyr UFSC [documentation](https://chromium.googlesource.com/chromiumos/platform/ec/+/refs/heads/main/docs/zephyr/zephyr_ufsc.md#testing-and-debugging)

 # Important Notes

 * **Consistency :** Strictly follow the naming convention: Schema Key (UPPER\_CASE) \-\> Proto Field (lower\_case) \-\> `_create_firmware_config` argument (lower\_case). The final key in `fw_config_defs` must match the Schema Key (UPPER\_CASE).
 * **Regenerate Proto Bindings:** Always remember this step after modifying the `.proto` file. Run [generate.sh](http://generate.sh) in src/config
 * **Run `generate_ufsc.py`:** Always run the script after modifying schema or project definitions to update the generated `.cb` and `.dtsi` files.
 * **Use Generated Files:** The generated `.cb` and `.dtsi` files should be copied over to the coreboot and EC board specific code.

# Revision  History

| Revision | Changelist |
| :---- | :---- |
| Revision 1.0 | First draft |
| Revision 1.1 | Add information on OEM customization fields. Add section for UFSC tooling |
