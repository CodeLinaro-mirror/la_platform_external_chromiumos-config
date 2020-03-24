// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package main

import (
	"context"
	"flag"
	"io/ioutil"
	"log"
	"os"

	"github.com/golang/protobuf/jsonpb"

	"github.com/google/subcommands"
	"go.chromium.org/chromiumos/config/go/internal/experimental/convert"

	"go.chromium.org/chromiumos/infra/proto/go/device"
)

type convertCmd struct {
	input  string
	output string
}

func (c *convertCmd) Name() string { return "convert" }

func (c *convertCmd) Synopsis() string {
	return "EXPERIMENTAL: Convert a device.AllConfigs proto to a chromiumos.config.api.ConfigBundle proto."
}

func (c *convertCmd) Usage() string {
	return `convert -input <input config> -output <output config>:
Convert a device.AllConfigs proto to a chromiumos.config.api.ConfigBundle proto.

Note this tool is currently experimental, and makes no guarantees around correctness,
completeness, speed, interface stability, etc. It shoud NOT be use on
production-critical paths.

ConfigBundle is the second generation of AllConfigs, this tool is meant to aid translation.

See https://godoc.org/go.chromium.org/chromiumos/infra/proto/go/device#AllConfigs and
https://godoc.org/go.chromium.org/chromiumos/config/go/api#ConfigBundle for respective
proto definitions.
`
}

func (c *convertCmd) SetFlags(f *flag.FlagSet) {
	f.StringVar(&c.input, "input", "", "Path to the input config binary proto file.")
	f.StringVar(&c.output, "output", "", "Path to write the converted config to.")
}

func (c *convertCmd) Execute(_ context.Context, _ *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	if len(c.input) == 0 {
		log.Fatal("-input must be set.")
	}

	if len(c.output) == 0 {
		log.Fatal("-output must be set.")
	}

	allConfigs := &device.AllConfigs{}

	f, err := os.Open(c.input)
	if err != nil {
		log.Fatal(err)
	}

	err = jsonpb.Unmarshal(f, allConfigs)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Read device.AllConfigs from %s", c.input)

	configBundle, err := convert.GenerateConfigBundle(allConfigs)
	if err != nil {
		log.Fatal(err)
	}

	marshaler := &jsonpb.Marshaler{Indent: "  "}
	jsonString, err := marshaler.MarshalToString(configBundle)
	if err != nil {
		log.Fatal(err)
	}

	err = ioutil.WriteFile(c.output, []byte(jsonString), os.ModePerm)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Wrote ConfigBundle to %s", c.output)

	return subcommands.ExitSuccess
}

func main() {
	subcommands.Register(subcommands.HelpCommand(), "")
	subcommands.Register(subcommands.FlagsCommand(), "")
	subcommands.Register(subcommands.CommandsCommand(), "")
	subcommands.Register(&convertCmd{}, "")

	flag.Parse()
	ctx := context.Background()
	os.Exit(int(subcommands.Execute(ctx)))
}
