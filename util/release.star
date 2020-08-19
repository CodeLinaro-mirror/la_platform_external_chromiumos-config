"""Functions related to release configs.

See proto definitions for config details.
"""

load(
    "@proto//chromiumos/config/api/release/channel.proto",
    channel_pb = "chromiumos.config.api.release",
)

_CHANNEL = struct(
    CANARY = channel_pb.Channel.CANARY,
    DEV = channel_pb.Channel.DEV,
    BETA = channel_pb.Channel.BETA,
    STABLE = channel_pb.Channel.STABLE,
    LTS = channel_pb.Channel.LTS,
)

release = struct(
    channel = _CHANNEL,
)
