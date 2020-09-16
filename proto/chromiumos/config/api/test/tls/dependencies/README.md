# ChromeOS TLS/TLW dependencies

[TOC]

## Overview

This is a temporary directory including dependent proto files for TLS/TLW to
workaround importing issues when we build proto descriptor sets.

## longrunning/operations.proto

This is a copy of [google.longrunning][1] with below modifications:

1. Removed the dependency of google/api/annotations.proto. We don't need in
   annotations in TLS/TLW.

1. Append an RPC of WaitOperation defined in [here](2).

1. Appended with a copy of google.rpc.status from "google/rpc/status.proto" and
   renamed it to just "Status".

1. All necessary proto and go package name changes.

[1]:
https://github.com/googleapis/api-common-protos/blob/1.50.0/google/longrunning/operations.proto
[2]:
https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto#L122
