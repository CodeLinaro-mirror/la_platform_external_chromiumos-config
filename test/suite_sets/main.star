#!/usr/bin/env lucicfg generate
# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Main entry point to generate the Suite and SuiteSet protos."""

load("//proto/proto.star", "chromiumos_descpb")

chromiumos_descpb.register()

load("//compiled_suites.star", "compiled_suites")
load("//compiled_suite_sets.star", "compiled_suite_sets")

def suites_generator(ctx):
    ctx.output["suites.jsonpb"] = proto.to_jsonpb(compiled_suites)

def suite_sets_generator(ctx):
    ctx.output["suite_sets.jsonpb"] = proto.to_jsonpb(compiled_suite_sets)

def main():
    lucicfg.generator(impl = suites_generator)
    lucicfg.generator(impl = suite_sets_generator)

main()
