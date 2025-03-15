// Copyright 2020 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tls_test

import (
	"bytes"
	"context"
	"fmt"
	"io"

	"go.chromium.org/chromiumos/config/go/api/test/tls"
	"google.golang.org/grpc"
)

func ExampleExecDutCommandRequest() {
	// The RTD will receive this in its invocation spec.
	var (
		addr    string
		dutName string
	)
	conn, err := grpc.Dial(addr)
	if err != nil {
		panic(err)
	}
	defer conn.Close()
	c := tls.NewCommonClient(conn)
	ctx := context.Background()
	req := tls.ExecDutCommandRequest{
		Name:    dutName,
		Command: "echo",
		Args:    []string{"hello world"},
	}
	stream, err := c.ExecDutCommand(ctx, &req)
	if err != nil {
		panic("RPC error")
	}
	// Handle stream in various ways.
	_ = stream
}

func ExampleExecDutCommandRequest_CheckSuccess() {
	// stream from ExecDutCommand,
	// See example for CommonClient.ExecDutCommand.
	var stream tls.Common_ExecDutCommandClient
	var exitInfo *tls.ExecDutCommandResponse_ExitInfo
readStream:
	for {
		resp, err := stream.Recv()
		switch err {
		case nil:
			if v := resp.GetExitInfo(); v != nil {
				exitInfo = v
			}
		case io.EOF:
			break readStream
		default:
			panic("RPC error")
		}
	}
	if exitInfo.GetStatus() != 0 {
		panic("command failed")
	}
}

func ExampleExecDutCommandRequest_CheckSpecificStatus() {
	// stream from ExecDutCommand,
	// See example for CommonClient.ExecDutCommand.
	var stream tls.Common_ExecDutCommandClient
	var exitInfo *tls.ExecDutCommandResponse_ExitInfo
readStream:
	for {
		resp, err := stream.Recv()
		switch err {
		case nil:
			if v := resp.GetExitInfo(); v != nil {
				exitInfo = v
			}
		case io.EOF:
			break readStream
		default:
			panic("RPC error")
		}
	}
	switch {
	case !exitInfo.GetStarted():
		fmt.Printf("process not started: %v", exitInfo.GetErrorMessage())
	case exitInfo.GetSignaled():
		fmt.Printf("process received signal %v", exitInfo.GetStatus())
	default:
		fmt.Printf("process exited with %v", exitInfo.GetStatus())
	}
}

func ExampleExecDutCommandRequest_ReadOutput() {
	// Stream from ExecDutCommand.
	// See example for CommonClient.ExecDutCommand.
	var stream tls.Common_ExecDutCommandClient
	var (
		stdout bytes.Buffer
		stderr bytes.Buffer
	)
readStream:
	for {
		resp, err := stream.Recv()
		switch err {
		case nil:
			stdout.Write(resp.Stdout)
			stderr.Write(resp.Stderr)
		case io.EOF:
			break readStream
		default:
			panic("RPC error")
		}
	}
}
