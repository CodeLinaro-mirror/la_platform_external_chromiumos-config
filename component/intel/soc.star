# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Functions related to Intel Soc components.

See proto definitions for descriptions of arguments.
"""

load("//config/util/component.star", "comp")

def _family(name):
    """Builds a Component.Soc.Family proto."""
    return comp.create_soc_family(name = name)

def _model(family, model, cores):
    """Builds a Component proto for an Intel Soc."""
    return comp.create_soc_model(
        family = family,
        model = "Intel(R) Celeron(R) N{} CPU @ 1.10GHz".format(model),
        cores = cores,
        id = "IntelR_CeleronR_N{}_CPU_1_10GHz".format(model),
    )

intel_soc = struct(
    family = _family,
    model = _model,
)
