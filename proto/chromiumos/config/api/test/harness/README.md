# Harness-specific metadata

Sub-directories in this directory house protobuf definitions specific to various
Remote Test Drivers (RTD).

e.g., [tauto/v1/tauto.proto](tauto/v1/tauto.proto) contains a message that
serves as the schema for the payload in [metadata.Information.Details] field
of test metadata for Tauto tests.

The test plans and test scheduling infrastructure *MUST NOT* depend on these
definitions.

Defining the schema for [metadata.Information.Details] payload here has the
following benefits:

- Provides strongly typed parsing of [metadata.Information.Details] at RTD
  execution to modify behavior of the RTD based on test metadata.

- Provides a way to build additional RTD specific analytics solutions from the
  test metadata exported from the Continuous Integration infrastructure.

  - The RTD specific analytics pipelines can build data transformation steps for
    backwards compatibility, similar to that for the generic metadata.

[metadata.Information.Details]: https://chromium.googlesource.com/chromiumos/config/+/6011eafe2029936dae767a7f75fdb965782006fa/proto/chromiumos/config/api/test/metadata/v1/metadata.proto#423
