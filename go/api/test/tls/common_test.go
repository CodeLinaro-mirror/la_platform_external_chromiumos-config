// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tls_test

import (
	"context"
	"fmt"

	"github.com/golang/protobuf/ptypes/duration"
	rtd "go.chromium.org/chromiumos/config/go/api/test/rtd/v1"
	"go.chromium.org/chromiumos/config/go/api/test/tls"
	"go.chromium.org/chromiumos/config/go/api/test/tls/dependencies/longrunning"
	"google.golang.org/grpc"
)

func ExampleProvisionRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	req := tls.ProvisionRequest{
		Name: dutName,
		Image: &tls.ProvisionRequest_ChromeOSImage{
			PathOneof: &tls.ProvisionRequest_ChromeOSImage_GsPathPrefix{
				GsPathPrefix: "gs://chromeos-image-archive/eve-release/R87-13457.0.0",
			},
		},
		DlcSpecs: []*tls.ProvisionRequest_DLCSpec{
			&tls.ProvisionRequest_DLCSpec{
				Id: "dummy-dlc",
			},
		},
	}

	ctx := context.Background()
	op, err := c.Provision(ctx, &req)
	if err != nil {
		panic(err)
	}

	opcli := longrunning.NewOperationsClient(conn)
	op, err = opcli.WaitOperation(ctx, &longrunning.WaitOperationRequest{
		Name: op.GetName(),
		Timeout: &duration.Duration{
			Seconds: 3600,
		},
	})
	if err != nil {
		panic("RPC error")
	}

	if errStatus := op.GetError(); errStatus != nil {
		panic(fmt.Sprintf("Operation error details: %v", errStatus.GetDetails()))
	}

	// Provisioned OS + DLC.
}
