"""Util functions to help manage dut configurations.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/test/lab/api/dut.proto",
    lab_pb = "chromiumos.test.lab.api",
)
load(
    "@proto//chromiumos/test/lab/api/ip_endpoint.proto",
    ip_pb = "chromiumos.test.lab.api",
)

def _create_dut(address, port = 22):
    return lab_pb.Dut(
        id = lab_pb.Dut.Id(value = address),
        chromeos = lab_pb.Dut.ChromeOS(
            ssh = ip_pb.IpEndpoint(
                address = address,
                port = port,
            ),
        ),
    )

def _create_dut_topology(dut, peer_duts = None):
    return lab_pb.DutTopology(
        id = lab_pb.DutTopology.Id(value = dut.id.value),
        dut = dut,
        peer_duts = peer_duts,
    )

dut = struct(
    create_dut = _create_dut,
    create_dut_topology = _create_dut_topology,
)
