#!/usr/bin/env vpython3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Marshal device stability configs. Store them into the UFS datastore
through the Google datastore API.

This script converts the DeviceStabilityList from
'.../chromiumos/infra/config/testingconfig/generated/device_stability.cfg'
into datastore entities.
"""

import argparse
import datetime
import logging
import os

from checker import io_utils
from common import logging_utils
from common import proto_utils
from google.cloud import datastore


# type constants
DEV_STAB_INPUT_TYPE = "chromiumos.test.dut.DeviceStabilityList"
DEV_STAB_OUTPUT_TYPE = "chromiumos.test.dut.DeviceStability"

# UFS services
UFS_DEV_PROJECT = "unified-fleet-system-dev"
UFS_PROD_PROJECT = "unified-fleet-system"

# datastore constants
DEVICE_STABILITY_KIND = "DeviceStability"


def get_ufs_project(env):
    """Return project name based on env argument."""
    if env == "dev":
        return UFS_DEV_PROJECT
    if env == "prod":
        return UFS_PROD_PROJECT
    raise RuntimeError("get_ufs_project: environment %s not supported" % env)


def handle_device_stability_list(dev_stab_list_path, client):
    """Take a path to a DeviceStabilityList, iterate through the list and store
    into UFS datastore based on env.
    """
    dev_stab_list = io_utils.read_json_proto(
        protodb.GetSymbol(DEV_STAB_INPUT_TYPE)(), dev_stab_list_path
    )

    all_boards = {}
    for dev_stab in dev_stab_list.values:
        update_device_stability(dev_stab, client)
        for eid in dev_stab.dut_criteria[0].values:
            all_boards[eid] = True

    clean_up_device_stability(all_boards, client)


def clean_up_device_stability(all_boards, client):
    """Clean up boards/models that are deleted from device stability config files"""
    query = client.query(kind=DEVICE_STABILITY_KIND)
    query.keys_only()
    to_delete_keys = []
    for record in query.fetch():
        if record.key.name not in all_boards:
            to_delete_keys.append(record.key)

    client.delete_multi(to_delete_keys)


def update_device_stability(dev_stab, client):
    """Take a DeviceStability and store it in the UFS datastore as a
    DeviceStabilityEntity.
    """
    # TODO (justinsuen): May need to change this eventually. This assumes the
    # use of a single model (DutAttribute ID design_id) when defining a
    # DeviceStability entry.
    # http://cs/chromeos_internal/infra/config/testingconfig/target_test_requirements_config_helper.star?l=155
    for eid in dev_stab.dut_criteria[0].values:
        logging.info("update_device_stability: handling %s", eid)

        key = client.key(DEVICE_STABILITY_KIND, eid)
        entity = datastore.Entity(
            key=key,
            exclude_from_indexes=["StabilityData"],
        )
        entity["StabilityData"] = dev_stab.SerializeToString()
        entity["Updated"] = datetime.datetime.now()

        logging.info(
            "update_device_stability: putting entity into datastore for %s", eid
        )
        client.put(entity)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    logging_utils.parser_add_argument(parser)

    parser.add_argument(
        "--env",
        type=str,
        default="dev",
        help="environment flag for UFS service",
    )

    # load database of protobuffer name -> Type
    protodb = proto_utils.create_symbol_db()
    options = parser.parse_args()
    logging_utils.config_logging(options)
    ufs_ds_client = datastore.Client(
        project=get_ufs_project(options.env),
        namespace="os",
    )
    script_dir = os.path.dirname(os.path.realpath(__file__))
    handle_device_stability_list(
        os.path.realpath(
            os.path.join(
                script_dir,
                "../../config-internal/board_config/generated/device_stability.cfg",
            )
        ),
        ufs_ds_client,
    )
