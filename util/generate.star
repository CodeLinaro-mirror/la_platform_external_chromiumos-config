"""Functions to generate proto payloads."""

def _generate(config):
    """Serializes a ConfigBundle to a file.

    A json proto is written. Note that there is some post processing done
    by the gen_config script to convert this json output into a json
    output that uses ints for encoding enums.
    """

    def _generate_impl(ctx):
        ctx.output["config.jsonproto"] = proto.to_jsonpb(config)

    lucicfg.generator(impl = _generate_impl)

generate = struct(
    generate = _generate,
)
