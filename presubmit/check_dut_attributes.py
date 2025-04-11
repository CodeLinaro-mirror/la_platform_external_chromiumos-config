#!/usr/bin/env vpython3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import re
import subprocess

from google.protobuf import json_format
from google.protobuf.descriptor import FieldDescriptor


# Move to the script's directory for running commands and importing proto
# bindings.
config_dir = (
    subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        check=True,
        capture_output=True,
    )
    .stdout.decode("utf-8")
    .strip()
)
os.chdir(config_dir)

import sys


sys.path.append(os.path.join(config_dir, "payload_utils"))
sys.path.append(os.path.join(config_dir, "python"))

from chromiumos.config.api import component_pb2
from chromiumos.config.payload import flat_config_pb2
from chromiumos.test.api import dut_attribute_pb2
from common import proto_utils


SKIP_FOOTER = "Skip-Dut-Attrs-Check"


class DutAttributeChangeError(Exception):
    """Raised when a commit makes an invalid change to DutAttributes."""


def attributes_at_ref(
    ref: str, id_only=False
) -> dut_attribute_pb2.DutAttributeList:
    """Returns dut_attributes.jsonproto at a particular git ref.

    Args:
        ref: Git ref to read the DutAttributeList proto from.
        id_only: If true, return a set of unique DutAttribute.Id values.
    """

    proc = subprocess.run(
        [
            "git",
            "cat-file",
            "blob",
            f"{ref}:generated/dut_attributes.jsonproto",
        ],
        check=True,
        capture_output=True,
    )

    # parse into DutAttributeList
    dut_attr_list = dut_attribute_pb2.DutAttributeList()
    json_format.Parse(proc.stdout, dut_attr_list)

    if id_only:
        return set([da.id.value for da in dut_attr_list.dut_attributes])
    return dut_attr_list.dut_attributes


def check_attributes_removed():
    """Enforce semantics that DutAttributes cannot be removed once committed."""

    git_footers_proc = subprocess.run(
        ["git-footers", "--key", SKIP_FOOTER, "HEAD"],
        check=True,
        capture_output=True,
    )

    if git_footers_proc.stdout:
        print(f"{SKIP_FOOTER} footer set, skipping DUT attributes check.")
        return

    try:
        prev_dut_attrs = attributes_at_ref("HEAD~1", id_only=True)
    except subprocess.CalledProcessError:
        print("No current DutAttributes, skipping removal check.")
        return

    curr_dut_attrs = attributes_at_ref("HEAD", id_only=True)

    removed_attr_ids = prev_dut_attrs - curr_dut_attrs
    if removed_attr_ids:
        print(
            "DutAttributes cannot be removed because branched code may depend "
            "on them.\n\n"
            "To override this dcheck, add a footer to your commit:\n"
            f"    '{SKIP_FOOTER}: <explanation>'\n\n"
            "Removed attributes:\n"
            + "\n".join(f"  {attr_id}" for attr_id in removed_attr_ids)
        )
        sys.exit(1)

    print("no DutAttributes removed.")


# Define the message we're rooted in for each config source
ROOT_MSG_MAP = {
    "flat_config_source": flat_config_pb2.FlatConfig,
    "hwid_source": component_pb2.Component,
}


def check_valid_attributes():
    """Check that attributes are valid."""

    NON_VALUE_TYPES = [
        FieldDescriptor.TYPE_MESSAGE,
        FieldDescriptor.TYPE_GROUP,
        FieldDescriptor.TYPE_BYTES,
    ]

    FLOAT_TYPES = [
        FieldDescriptor.TYPE_DOUBLE,
        FieldDescriptor.TYPE_FLOAT,
    ]

    def format_error(attr, msg):
        """Format an error message for the given attribute."""
        return "error in id '{attr}': {msg}".format(attr=attr.id.value, msg=msg)

    def validate_attr_fields(attr):
        """Validate the field specs of an attribute, return list of errors."""
        # Find oneof field (if any) to check
        fields = []
        name = attr.WhichOneof("data_source")
        if name:
            if name == "tle_source":
                print("Skipping '{}', no fields are defined.".format(name))
                return []
            fields = getattr(attr, name).fields

        root_msg = ROOT_MSG_MAP.get(name)
        if not root_msg:
            print("Skipping '{}', no root message defined.".format(name))
            return []

        errors = []
        for field_spec in fields:
            field_infos = proto_utils.resolve_field_path(
                root_msg, field_spec.path
            )

            fields = field_spec.path.split(".")
            for ii, (field, info) in enumerate(zip(fields, field_infos)):
                # Check for non-existent fields
                if not info:
                    msg_name = root_msg.DESCRIPTOR.name
                    if ii > 0:
                        msg_name = field_infos[ii - 1].typename

                    errors.append(
                        format_error(
                            attr,
                            f"'{field_spec.path}' -- field '{field}' does not "
                            f"exist in message '{msg_name}'",
                        )
                    )
                    break

                # Check for repeated fields
                if info.repeated:
                    errors.append(
                        format_error(
                            attr,
                            f"'{field_spec.path}' -- field '{field}' is "
                            "repeated, must be singular",
                        )
                    )

            # Check that the terminal field is a value type
            terminal_info = field_infos[-1]
            if terminal_info:
                if terminal_info.typeid in NON_VALUE_TYPES:
                    errors.append(
                        format_error(
                            attr,
                            f"'{field_spec.path}' -- last field "
                            f"'{terminal_info.name}' must be value type",
                        )
                    )

                # and that it's not a floating point value
                if terminal_info.typeid in FLOAT_TYPES:
                    errors.append(
                        format_error(
                            attr,
                            f"'{field_spec.path}' -- floating point fields "
                            "are not allowed",
                        )
                    )

        return errors

    # Check dut attribute ids and build a map of name => attribute id
    def validate_attr(attr):
        """Validate the properties of an attribute and return list of errors."""
        attr_map = {}

        def maybe_add_label(attr, label):
            """Record a label for an attribute if it doesn't already exist."""
            if label in attr_map:
                return [
                    format_error(
                        attr,
                        "label '{}' already exists in attribute '{}'".format(
                            label, attr_map[label]
                        ),
                    )
                ]
            attr_map[label] = attr.id.value
            return []

        # Check dut attributes names are formatted properly and not repeated
        errors = []
        if not re.match("^([a-zA-Z0-9]+-?)+[a-zA-Z0-9]+$", attr.id.value):
            errors.append(
                format_error(attr, "has invalid id '{}'".format(attr.id.value))
            )

        errors += maybe_add_label(attr, attr.id.value)
        for label in attr.aliases:
            errors += maybe_add_label(attr, label)
        return errors

    curr_dut_attrs = attributes_at_ref("HEAD")

    # Multiple loops to preserve error ordering
    errors = []
    for attr in curr_dut_attrs:
        errors += validate_attr(attr)

    for attr in curr_dut_attrs:
        errors += validate_attr_fields(attr)

    if not errors:
        return

    print("One or more errors checking DutAttributes:")
    for error in errors:
        print("  {}".format(error))
    sys.exit(1)


def main():
    stages = [
        ("Check for removed attributes", check_attributes_removed),
        ("Validate attribute definitions", check_valid_attributes),
    ]

    for msg, stage in stages:
        print(f"== {msg}")
        stage()
        print()


if __name__ == "__main__":
    main()
