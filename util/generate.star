"""Functions to generate proto payloads."""

def _generate(config):
    """Serializes a ConfigBundle to files.

    A text proto and binary proto are written. The text proto is usually used
    for human readability and diffing, the binary proto is for machine
    consumption.
    """

    def _generate_impl(ctx):
        ctx.output["config.cfg"] = proto.to_textpb(config)
        ctx.output["config.binaryproto"] = proto.to_wirepb(config)

    lucicfg.generator(impl = _generate_impl)

generate = struct(
    generate = _generate,
)
