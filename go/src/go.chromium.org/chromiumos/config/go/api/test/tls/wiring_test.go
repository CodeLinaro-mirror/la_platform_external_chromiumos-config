// Copyright 2020 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tls_test

import (
	"context"
	"fmt"
	"net"
	"net/http"

	"github.com/golang/protobuf/ptypes"
	"github.com/golang/protobuf/ptypes/duration"
	rtd "go.chromium.org/chromiumos/config/go/api/test/rtd/v1"
	"go.chromium.org/chromiumos/config/go/api/test/tls"
	"go.chromium.org/chromiumos/config/go/api/test/tls/dependencies/longrunning"
	"google.golang.org/grpc"
)

func ExampleCacheForDutRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()
	gsURL := "gs://my-bucket/path/to/file"

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()))
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewWiringClient(conn)
	opcli := longrunning.NewOperationsClient(conn)
	ctx := context.Background()

	req := tls.CacheForDutRequest{
		Url:     gsURL,
		DutName: dutName,
	}
	op, err := c.CacheForDut(ctx, &req)
	if err != nil {
		panic("RPC error")
	}

	op, err = opcli.WaitOperation(ctx, &longrunning.WaitOperationRequest{
		Name: op.GetName(),
		Timeout: &duration.Duration{
			Seconds: 300,
		},
	})
	if err != nil {
		panic("RPC error")
	}

	if errStatus := op.GetError(); errStatus != nil {
		panic("Operation error")
	}
	resp := &tls.CacheForDutResponse{}
	if err := ptypes.UnmarshalAny(op.GetResponse(), resp); err != nil {
		panic("Unmarshal response error")
	}
	// Handle the response in various ways.
	_ = resp
}

func ExampleCacheForDutRequest_DownloadCachedFile() {
	var dutName string
	var c tls.CommonClient
	var resp tls.CacheForDutResponse // Response of CacheForDut.

	ctx := context.Background()
	result, err := c.ExecDutCommand(ctx, &tls.ExecDutCommandRequest{
		Name:    dutName,
		Command: "wget",
		Args:    []string{resp.GetUrl()},
	})
	if err != nil {
		panic("RPC error")
	}
	// Check the return code of ExecDutCommand.
	_ = result
}

func ExampleExposePortToDutRequest() {
	var invocation rtd.Invocation

	tlsConfig := invocation.GetTestLabServicesConfig()
	dutName := invocation.GetDuts()[0].GetTlsDutName()

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", tlsConfig.GetTlwAddress(), tlsConfig.GetTlwPort()))
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	c := tls.NewWiringClient(conn)
	ctx := context.Background()

	// Start a service inside RTD to bind to a local port.
	s := http.Server{}
	http.HandleFunc("/foo", func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprint(w, "Hello world!\n")
	})
	// Use port "0" to request OS to assign an unused port number.
	ln, _ := net.Listen("tcp", ":0")
	go func() {
		s.Serve(ln)
	}()
	defer s.Shutdown(context.Background())

	req := tls.ExposePortToDutRequest{
		DutName:   dutName,
		LocalPort: int32(ln.Addr().(*net.TCPAddr).Port),
	}
	resp, err := c.ExposePortToDut(ctx, &req)
	if err != nil {
		panic("RPC error")
	}

	// Handle the response in various ways. For example:
	// Run a client command to access the service started.
	// Trivial example, see ExecDutCommandRequest for a possible implementation.
	runCommandOnDut := func(args []string) {}
	runCommandOnDut([]string{"curl", fmt.Sprintf("%s:%d/foo", resp.ExposedAddress, resp.ExposedPort)})
}
