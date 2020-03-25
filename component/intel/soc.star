# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("//config/util/component.star", comp = "comp")

def _family(name):
  return comp.create_soc_family(name=name)


def _model(family, model, cores):
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


