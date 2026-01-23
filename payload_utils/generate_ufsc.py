#!/usr/bin/env python3
# Copyright 2025 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates ap-fw-config (.cb) and ec-ufsc-config (.dtsi) files.

This script generates configuration files based on a json schema
and project-specific Starlark definitions. Outputs only include fields
explicitly defined as keys in the project's fw_config_defs struct.

Dependencies:
1.  UNIFIED_FW_CONFIG_SCHEMA: ./config/util/ufsc/unified_fw_config_schema.json
    (Defines the schema as a JSON object with bit fields and used_by target)
2.  Project Definitions: ./fw_config_defs.star
    (Defines project-specific option values in the 'fw_config_defs' struct.
     Keys MUST match the UNIFIED_FW_CONFIG_SCHEMA schema keys.)

Usage:
Run this script from the specific project directory:
  cd src/project/<program>/<project>/
  ./config/payload_utils/generate_fw_config.py [TARGET...]

Where TARGET can be 'ap' or 'ec'. You can specify none, any, or both targets.
- No TARGET: Generates both AP and EC configs.
- 'ap': Generates only AP config.
- 'ec': Generates only EC config.
- 'ap ec': Generates both AP and EC configs.

The project directory (e.g., src/project/<prog>/<proj>) MUST contain a
'./config' symlink pointing to the appropriate configuration directory
(e.g., src/config).

Output files (<project>_ap_fw_config.cb, <project>_ec_ufsc.dtsi)
are created in the current directory.
"""

import argparse
import dataclasses
import json
import logging
from pathlib import Path
import sys
from typing import Any, Optional


class Error(Exception):
    """Base exception for this module."""


class StarlarkError(Error):
    """Error related to Starlark file processing."""


class SchemaError(Error):
    """Error related to schema definition."""


class DefsError(Error):
    """Error related to project definitions."""


class FileError(Error):
    """Error related to file operations."""


class PathError(Error):
    """Error inferring paths from CWD."""


@dataclasses.dataclass(frozen=True)
class ProjectContext:
    """Holds essential path and name information for the project."""

    project_name: str
    project_dir: Path
    schema_path: Path
    defs_path: Path


@dataclasses.dataclass(frozen=True)
class BitField:
    """Holds parsed and calculated bit information for a field."""

    start_bit: int
    end_bit: int
    size: int
    dword: int
    start_bit_in_dword: int


def _parse_starlark_file(file_path: Path) -> dict[str, Any]:
    """Parses a .star file by executing it in a sandbox.

    Args:
        file_path: The path to the .star file.

    Returns:
        A dictionary containing the globals defined in the .star file.

    Raises:
        StarlarkError: If the file is not found, cannot be read, or if there's
            a syntax or runtime error during parsing.
    """
    try:
        content = file_path.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise StarlarkError(f"Error: File not found: {file_path}") from e
    except IOError as e:
        raise StarlarkError(f"Error reading file {file_path}") from e

    def struct(**kwargs) -> dict[str, Any]:
        return kwargs

    def load(*_, **__) -> None:
        pass

    exec_globals = {"struct": struct, "load": load, "__builtins__": {}}
    try:
        # pylint: disable=exec-used
        exec(content, exec_globals)
    except SyntaxError as e:
        raise StarlarkError(
            f"Error parsing Starlark file {file_path}: Invalid syntax"
        ) from e
    except (NameError, TypeError, KeyError) as e:
        raise StarlarkError(f"Error executing Starlark file {file_path}") from e
    return exec_globals


def load_schema_data(
    schema_path: Path,
) -> tuple[dict[str, Any], list[str], list[str]]:
    """Loads the main schema from JSON and categorizes keys by AP/EC usage.

    Args:
        schema_path: Path to the schema .json file.

    Returns:
        A tuple containing the schema dictionary, a list of AP keys, and a list
        of EC keys.

    Raises:
        SchemaError: If the schema file is not found, cannot be read,
            is invalid JSON, or entries are invalid.
    """
    logging.info("Loading schema from: %s", schema_path)
    try:
        content = schema_path.read_text(encoding="utf-8")
    except IOError as e:
        raise SchemaError(
            f"Error reading JSON schema file {schema_path}"
        ) from e

    try:
        schema = json.loads(content)
    except json.JSONDecodeError as e:
        raise SchemaError(
            f"Error parsing JSON schema file {schema_path}: Invalid JSON"
        ) from e

    if not schema or not isinstance(schema, dict):
        raise SchemaError(
            f"Error: JSON schema in {schema_path} is empty or not "
            "valid top-level object."
        )

    ap_keys, ec_keys = [], []
    valid_users = {"AP", "EC", "BOTH"}
    for key, data in schema.items():
        if key.startswith("_"):
            logging.debug("Skipping metadata schema entry '%s'", key)
            continue

        if not isinstance(data, dict):
            logging.warning(
                "Skipping invalid schema entry '%s': Not a struct/dict.", key
            )
            continue

        used_by = data.get("used_by")
        if not used_by or used_by not in valid_users:
            raise SchemaError(
                f"Error: Schema entry '{key}' missing or invalid 'used_by'."
                " Must be 'AP', 'EC', or 'BOTH'."
            )
        if used_by in ("AP", "BOTH"):
            ap_keys.append(key)
        if used_by in ("EC", "BOTH"):
            ec_keys.append(key)

    if not ap_keys:
        logging.warning("No AP keys found in schema.")
    if not ec_keys:
        logging.warning("No EC keys found in schema.")
    return schema, ap_keys, ec_keys


def load_defs_data(defs_path: Path) -> dict[str, Any]:
    """Loads the project-specific definitions from fw_config_defs.star.

    Args:
        defs_path: Path to the project definitions .star file.

    Returns:
        A dictionary containing the project-specific definitions.

    Raises:
        DefsError: If the 'fw_config_defs' struct is not found.
    """
    logging.info("Loading project definitions from: %s", defs_path)
    defs_globals = _parse_starlark_file(defs_path)
    try:
        return defs_globals["fw_config_defs"]
    except KeyError as e:
        raise DefsError(
            f"Error: 'fw_config_defs' struct not found in {defs_path}"
        ) from e


def _get_field_bits(
    field_data: dict[str, Any], key_name: str
) -> Optional[BitField]:
    """Parses schema data and calculates all bit position information.

    Args:
        field_data: The dictionary for a specific schema key.
        key_name: The name of the key (for logging).

    Returns:
        A BitField object with calculated values, or None if data is invalid.
    """
    try:
        dword = int(field_data["dword"])
        start_bit_in_dword = int(field_data["start_bit"])
        end_bit_in_dword = int(field_data["end_bit"])
    except (KeyError, ValueError, TypeError):
        logging.warning(
            "Skipping key %s: missing or invalid dword/start_bit/end_bit.",
            key_name,
        )
        return None

    start_bit = (dword * 32) + start_bit_in_dword
    end_bit = (dword * 32) + end_bit_in_dword
    size = end_bit - start_bit + 1

    return BitField(
        start_bit=start_bit,
        end_bit=end_bit,
        size=size,
        dword=dword,
        start_bit_in_dword=start_bit_in_dword,
    )


def _get_sorted_options(options: Any, key_name: str) -> list[tuple[str, Any]]:
    """Sorts options dict by value (int) or alphabetically as fallback."""
    if not isinstance(options, dict):
        if options is not None:
            logging.warning(
                "Options defined for %s in fw_config_defs.star are not a "
                "valid dictionary/struct.",
                key_name,
            )
        return []
    try:
        return sorted(options.items(), key=lambda item: int(item[1]))
    except (ValueError, TypeError):
        logging.warning(
            "Could not sort options numerically for %s. Sorting "
            "alphabetically.",
            key_name,
        )
        return sorted(options.items())


def _format_ec_value_options(
    sorted_options: list[tuple[str, Any]],
) -> list[str]:
    """Formats the option sub-nodes for the EC project overlay dtsi file."""
    ret = []
    for name, val in sorted_options:
        name_lower = name.lower()
        dts_node_name = name_lower.replace("_", "-")
        dts_label = f"ufsc_{name_lower}"
        ret.extend(
            [
                f"\t{dts_label}: {dts_node_name} {{",
                '\t\tcompatible = "cros-ec,cbi-ufsc-value";',
                '\t\tstatus = "okay";',
                f"\t\tvalue = <{val}>;",
                "\t};",
            ]
        )
    return ret


def _collect_ap_fields(
    schema: dict[str, Any],
    ap_schema_keys: list[str],
    project_defs: dict[str, Any],
) -> list[dict[str, Any]]:
    """Collects and validates data for AP fields defined in project_defs."""
    ret = []
    valid_ap_keys = set(ap_schema_keys)
    for def_key in project_defs.keys():
        if def_key not in valid_ap_keys:
            continue
        field_data = schema.get(def_key)
        if not isinstance(field_data, dict):
            logging.warning(
                "Skipping AP key %s defined in fw_config_defs.star. "
                "But schema data is missing or invalid.",
                def_key,
            )
            continue

        bit_field = _get_field_bits(field_data, def_key)
        if not bit_field:
            continue

        ret.append(
            {
                "key": def_key,
                "start_bit": bit_field.start_bit,
                "end_bit": bit_field.end_bit,
                "options": project_defs.get(def_key),
            }
        )
    return ret


def generate_ap_config(
    schema: dict[str, Any],
    ap_schema_keys: list[str],
    project_defs: dict[str, Any],
    output_path: Path,
):
    """Generates the AP firmware config file (.cb format).

    Raises:
        FileError: If writing the output file fails.
    """
    lines = ["fw_config"]
    fields_to_generate = _collect_ap_fields(
        schema, ap_schema_keys, project_defs
    )

    for field_info in sorted(fields_to_generate, key=lambda x: x["start_bit"]):
        lines.append(
            f"\tfield {field_info['key']} {field_info['start_bit']} "
            f"{field_info['end_bit']}"
        )
        sorted_options = _get_sorted_options(
            field_info["options"], field_info["key"]
        )
        for opt_name, opt_val in sorted_options:
            lines.append(f"\t\toption {opt_name}\t{opt_val}")
        lines.append("\tend")
    lines.append("end")

    try:
        with output_path.open(mode="w", encoding="utf-8") as f:
            f.writelines(f"{x}\n" for x in lines)
    except IOError as e:
        raise FileError(f"Error writing AP config to {output_path}") from e

    logging.info("Successfully generated AP config: %s", output_path)


def _collect_ec_fields_data(
    schema: dict[str, Any],
    ec_schema_keys: list[str],
    project_defs: dict[str, Any],
) -> list[dict[str, Any]]:
    """Collects and validates data needed for EC file generation."""
    ret = []
    valid_ec_keys = set(ec_schema_keys)
    for def_key in sorted(project_defs.keys()):
        if def_key not in valid_ec_keys:
            continue
        field_data = schema.get(def_key)
        if not isinstance(field_data, dict):
            continue

        options = project_defs[def_key]
        ret.append(
            {
                "key": def_key,
                "options": options,
            }
        )
    return ret


def generate_ec_config(
    schema: dict[str, Any],
    ec_schema_keys: list[str],
    project_defs: dict[str, Any],
    output_path: Path,
):
    """Generates the EC UFSC project values overlay file (.dtsi format).

    Raises:
        FileError: If writing the output file fails.
    """
    lines = [
        "/* Auto-generated by generate_ufsc.py */",
        "",
    ]

    fields_data = _collect_ec_fields_data(schema, ec_schema_keys, project_defs)

    for field_info in fields_data:
        def_key = field_info["key"]
        dtsi_ref_label = f"&ufsc_{def_key.lower()}"

        lines.append(f"{dtsi_ref_label} {{")

        sorted_options = _get_sorted_options(field_info["options"], def_key)
        lines.extend(_format_ec_value_options(sorted_options))
        lines.append("};")
        lines.append("")

    try:
        with output_path.open(mode="w", encoding="utf-8") as f:
            f.writelines(f"{x}\n" for x in lines)
    except IOError as e:
        raise FileError(f"Error writing EC config to {output_path}") from e

    logging.info("Successfully generated EC config: %s", output_path)


def _generate_std_schema_dtsi_node_lines(field: dict[str, Any]) -> list[str]:
    """Generates the lines for a single field in the standard schema DTSI file."""
    key_upper = field["key"]
    bf: BitField = field["bit_field"]

    key_lower = key_upper.lower()
    node_name = key_lower.replace("_", "-")
    label = f"ufsc_{key_lower}"
    return [
        f"\t\t{label}: {node_name} {{",
        f'\t\t\tenum-name = "UFSC_{key_upper}";',
        f"\t\t\tstart = <UFSC_BIT({bf.dword}, {bf.start_bit_in_dword})>;",
        f"\t\t\tsize = <{bf.size}>;",
        "\t\t};",
    ]


def generate_ec_schema_file(
    schema: dict[str, Any],
    ec_schema_keys: list[str],
    output_path: Path,
):
    """Generates the EC UFSC standard schema definition file (.dtsi format).

    This generates a file defining the bit layout for all fields relevant to
    the EC (used_by="EC" or "BOTH"), using the standard schema definition.

    Args:
        schema: The full schema dictionary.
        ec_schema_keys: List of keys filtered for EC usage.
        output_path: Path to write the output file.

    Raises:
        FileError: If writing the output file fails.
    """
    lines = [
        "/* Copyright 2025 The ChromiumOS Authors",
        " * Use of this source code is governed by a BSD-style license that can be",
        " * found in the LICENSE file.",
        " */",
        "",
        "#define UFSC_BIT(dword, bit) ((dword) * 32 + (bit))",
        "",
        "/ {",
        "\tcbi_ufsc: cbi-ufsc {",
        '\t\tcompatible = "cros-ec,cbi-ufsc";',
        "",
    ]

    ec_fields = []
    for key in ec_schema_keys:
        data = schema.get(key)
        if not isinstance(data, dict):
            logging.warning("Skipping invalid schema entry %s", key)
            continue

        # Skip OEM customization bits.
        if "EC_OEM" in key:
            continue

        bit_field = _get_field_bits(data, key)
        if not bit_field:
            continue

        ec_fields.append(
            {
                "key": key,
                "bit_field": bit_field,
                "ufsc_start_bit": bit_field.start_bit,
            }
        )

    ec_fields.sort(key=lambda x: x["ufsc_start_bit"])

    for field in ec_fields:
        lines.extend(_generate_std_schema_dtsi_node_lines(field))

    lines.extend(["\t};", "};"])

    try:
        with output_path.open(mode="w", encoding="utf-8") as f:
            f.writelines(f"{x}\n" for x in lines)
    except IOError as e:
        raise FileError(f"Error writing EC schema to {output_path}") from e

    logging.info("Successfully generated EC schema: %s", output_path)


def infer_project_context() -> ProjectContext:
    """Infers project context (name, paths) from the current working directory.

    Returns:
        A ProjectContext object.

    Raises:
        PathError: If the script is not run from the expected directory structure.
    """
    cwd = Path.cwd()
    project_name = cwd.name
    program_dir = cwd.parent
    project_base_dir = program_dir.parent
    src_dir = project_base_dir.parent

    if not (project_base_dir.name == "project" and src_dir.name == "src"):
        raise PathError(
            "Error determining project/program. Please run this script from the "
            "project directory (e.g., src/project/my_program/my_project)."
        )

    program_name = program_dir.name
    logging.info(
        "--- Running for Program: %s, Project: %s ---",
        program_name,
        project_name,
    )

    schema_path = cwd / "config/util/ufsc/unified_fw_config_schema.json"
    defs_path = cwd / "fw_config_defs.star"
    return ProjectContext(project_name, cwd, schema_path, defs_path)


def parse_args(argv: Optional[list[str]]) -> argparse.Namespace:
    """Parses command line arguments."""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "--debug", action="store_true", help="Enable debug logging output."
    )
    parser.add_argument(
        "commands",
        nargs="*",
        choices=["ap", "ec"],
        help="Specify config(s) to generate: 'ap' and/or 'ec'. "
        "If omitted, both are generated.",
        metavar="TARGET",
    )
    return parser.parse_args(argv)


@dataclasses.dataclass(frozen=True)
class ConfigData:
    """Holds loaded schema and definition data."""

    schema: dict[str, Any]
    ap_schema_keys: list[str]
    ec_schema_keys: list[str]
    project_defs: dict[str, Any]


def run_generation(
    opts: argparse.Namespace,
    project_context: ProjectContext,
    config_data: ConfigData,
) -> bool:
    """Runs the generation process based on parsed arguments.

    Args:
        opts: Parsed command line options.
        project_context: The ProjectContext object.
        config_data: The ConfigData object holding schema and defs.

    Returns:
        True if all requested generation steps succeed, False otherwise.
    """
    targets = set(opts.commands)
    generate_ap = not targets or "ap" in targets
    generate_ec = not targets or "ec" in targets

    ap_ok = ec_ok = True
    project_dir = project_context.project_dir
    project_name = project_context.project_name

    if generate_ap:
        logging.info("Generating AP config...")
        ap_output_path = project_dir / f"{project_name}_ap_fw_config.cb"
        try:
            generate_ap_config(
                config_data.schema,
                config_data.ap_schema_keys,
                config_data.project_defs,
                ap_output_path,
            )
        except FileError as e:
            logging.error(e)
            ap_ok = False

    if generate_ec:
        logging.info("Generating EC config...")
        ec_output_path = project_dir / f"{project_name}_ec_ufsc.dtsi"
        ec_schema_output_path = project_dir / "cbi_ufsc_std_schema.dtsi"
        try:
            generate_ec_config(
                config_data.schema,
                config_data.ec_schema_keys,
                config_data.project_defs,
                ec_output_path,
            )
            generate_ec_schema_file(
                config_data.schema,
                config_data.ec_schema_keys,
                ec_schema_output_path,
            )
        except FileError as e:
            logging.error(e)
            ec_ok = False

    return ap_ok and ec_ok


def load_all_data(schema_path: Path, defs_path: Path) -> ConfigData:
    """Loads schema and definitions, returning a ConfigData object."""
    schema, ap_schema_keys, ec_schema_keys = load_schema_data(schema_path)
    project_defs = load_defs_data(defs_path)
    return ConfigData(schema, ap_schema_keys, ec_schema_keys, project_defs)


def main(argv: Optional[list[str]] = None) -> int:
    """Main function to parse arguments and orchestrate file generation."""
    opts = parse_args(argv)

    log_level = logging.DEBUG if opts.debug else logging.INFO
    logging.basicConfig(level=log_level, format="%(levelname)s: %(message)s")

    try:
        project_context = infer_project_context()
        config_data = load_all_data(
            project_context.schema_path, project_context.defs_path
        )

        if not run_generation(opts, project_context, config_data):
            logging.error("--- Completed with errors. ---")
            return 1

        logging.info("--- Done. ---")
        return 0

    except Error as e:
        logging.error("ERROR: %s", e)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
