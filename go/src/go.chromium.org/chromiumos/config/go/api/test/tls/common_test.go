// Copyright 2020 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tls_test

import (
	"context"
	"fmt"
	"io"

	"github.com/golang/protobuf/ptypes/duration"
	rtd "go.chromium.org/chromiumos/config/go/api/test/rtd/v1"
	"go.chromium.org/chromiumos/config/go/api/test/tls"
	"go.chromium.org/chromiumos/config/go/api/test/tls/dependencies/longrunning"
	"google.golang.org/grpc"
)

func ExampleProvisionDutRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	req := tls.ProvisionDutRequest{
		Name: dutName,
		TargetBuild: &tls.ChromeOsImage{
			PathOneof: &tls.ChromeOsImage_GsPathPrefix{
				GsPathPrefix: "gs://chromeos-image-archive/eve-release/R87-13457.0.0",
			},
		},
		DlcSpecs: []*tls.ProvisionDutRequest_DLCSpec{
			&tls.ProvisionDutRequest_DLCSpec{
				Id: "sample-dlc",
			},
		},
	}

	ctx := context.Background()
	op, err := c.ProvisionDut(ctx, &req)
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

func ExampleProvisionLacrosRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	req := tls.ProvisionLacrosRequest{
		Name: dutName,
		Image: &tls.ProvisionLacrosRequest_LacrosImage{
			PathOneof: &tls.ProvisionLacrosRequest_LacrosImage_GsPathPrefix{
				GsPathPrefix: "gs://some/path",
			},
		},
	}

	ctx := context.Background()
	op, err := c.ProvisionLacros(ctx, &req)
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

	// Provisioned Lacros.
}

func ExampleProvisionLacrosRequest_SuccessForAutoupdate() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	// A request for Autoupdate tests.
	req := tls.ProvisionLacrosRequest{
		Name: dutName,
		Image: &tls.ProvisionLacrosRequest_LacrosImage{
			PathOneof: &tls.ProvisionLacrosRequest_LacrosImage_DeviceFilePrefix{
				DeviceFilePrefix: "file:///some/path",
			},
		},
		OverrideVersion:     "9999.0.0.0",
		OverrideInstallPath: "/home/chronos/cros-components/lacros-dogfood-dev",
	}

	ctx := context.Background()
	op, err := c.ProvisionLacros(ctx, &req)
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
}

func ExampleFetchCrashesRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	req := tls.FetchCrashesRequest{
		Dut:       dutName,
		FetchCore: true,
	}

	ctx := context.Background()
	stream, err := c.FetchCrashes(ctx, &req)
	if err != nil {
		panic(err)
	}

	crashes := make(map[int64]*tls.CrashInfo)
	cores := make(map[int64][]byte)
	blobs := make(map[int64]map[string][]byte)

readStream:
	for {
		resp, err := stream.Recv()
		if err != nil {
			if err == io.EOF {
				break readStream
			}
			panic(fmt.Sprintf("RPC error: %v", err))
		}

		id := resp.CrashId
		switch x := resp.Data.(type) {
		case *tls.FetchCrashesResponse_Crash:
			crashes[id] = x.Crash
			// Start on next crash -- assume we get CrashInfo before
			// any blobs.
			blobs[id] = make(map[string][]byte)
		case *tls.FetchCrashesResponse_Blob:
			b := x.Blob
			blobs[id][b.Key] = append(blobs[id][b.Key], b.Blob...)
		case *tls.FetchCrashesResponse_Core:
			cores[id] = append(cores[id], x.Core...)
		default:
			panic(fmt.Sprintf("invalid type %T", x))
		}
	}
}

func ExampleCreateFakeOmahaRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlsAddress(), tlsConfig.GetTlsPort()), grpc.WithInsecure())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewCommonClient(conn)

	req := tls.CreateFakeOmahaRequest{
		FakeOmaha: &tls.FakeOmaha{
			Dut: dutName,
			TargetBuild: &tls.ChromeOsImage{
				PathOneof: &tls.ChromeOsImage_GsPathPrefix{
					GsPathPrefix: "gs://chromeos-image-archive/eve-release/R87-13457.0.0",
				},
			},
			Payloads: []*tls.FakeOmaha_Payload{
				&tls.FakeOmaha_Payload{
					Id:   "ROOTFS",
					Type: tls.FakeOmaha_Payload_FULL,
				},
			},
		},
	}

	ctx := context.Background()
	omaha, err := c.CreateFakeOmaha(ctx, &req)
	if err != nil {
		panic("RPC CreateFakeOmaha error")
	}
	defer c.DeleteFakeOmaha(ctx, &tls.DeleteFakeOmahaRequest{Name: omaha.GetName()})

	result, err := c.ExecDutCommand(ctx, &tls.ExecDutCommandRequest{
		Name:    dutName,
		Command: "update_engine_client",
		Args:    []string{"--update_url", omaha.GetOmahaUrl(), "--update"},
	})
	if err != nil {
		panic("RPC ExecDutCommand error")
	}

	// Check the return code of ExecDutCommand.
	_ = result
}
