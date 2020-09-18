// Copyright 2020 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tls_test

import (
	"context"
	"fmt"
	"time"

	"github.com/golang/protobuf/ptypes"
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

	for {
		if op.GetDone() {
			break
		}
		time.Sleep(5 * time.Second)
		op, err = opcli.GetOperation(ctx, &longrunning.GetOperationRequest{
			Name: op.GetName(),
		})
		if err != nil {
			panic("RPC error")
		}
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
