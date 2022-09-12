// Copyright 2020 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"path"
	"strings"

	"go.chromium.org/luci/lucicfg/docgen"
)

// Returns a func which returns the contents of a Starlark module relative to
// starlarkRoot.
//
// Some modules are skipped, e.g. "@stdlib" modules.
func getSourceFn(starlarkRoot string) func(string) (string, error) {
	return func(module string) (string, error) {
		if strings.HasPrefix(module, "@stdlib") || strings.HasPrefix(module, "@proto") {
			log.Printf("Skipping module %v", module)
			return "", nil
		}

		if !strings.HasPrefix(module, "//") {
			return "", fmt.Errorf("Expected module to start with '//', actual %v", module)
		}

		log.Printf("Reading module %v\n", module)

		fileBytes, err := ioutil.ReadFile(
			path.Join(
				starlarkRoot,
				strings.TrimLeft(module, "/"),
			),
		)

		if err != nil {
			return "", err
		}

		return string(fileBytes), nil
	}
}

func main() {
	template := flag.String("template", "", "Path to a markdown template file. Required.")
	output := flag.String("output", "", "Path to output a markdown file to. Required.")
	starlarkRoot := flag.String(
		"starlarkRoot",
		"",
		"Path to the root of the Starlark package. This is the directory "+
			"load statements are relative to, i.e. if //config/util/liba.star "+
			"is pointing to ~/chromiumos/src/config/util/liba.star, "+
			"starlarkRoot is ~/chromiumos/src. Required.",
	)

	flag.Parse()

	if len(*template) == 0 {
		log.Fatalln("template must be specified.")
	}

	if len(*output) == 0 {
		log.Fatalln("output must be specified.")
	}

	if len(*starlarkRoot) == 0 {
		log.Fatalln("starlarkRoot must be specified.")
	}

	templateBytes, err := ioutil.ReadFile(*template)
	if err != nil {
		log.Fatalln(err)
	}

	generator := &docgen.Generator{Starlark: getSourceFn(*starlarkRoot)}

	outputBytes, err := generator.Render(string(templateBytes))
	if err != nil {
		log.Fatalln(err)
	}

	if err = ioutil.WriteFile(*output, outputBytes, 0640); err != nil {
		log.Fatalln(err)
	}

	log.Printf("Wrote output to %v\n", *output)
}
