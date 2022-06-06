"""Functions to generate proto payloads."""

def _generate(config, output = "config.jsonproto"):
    """Serializes a ConfigBundle to a file.

    A json proto is written. Note that there is some post processing done
    by the gen_config script to convert this json output into a json
    output that uses ints for encoding enums.
    """

    def _generate_impl(ctx):
        ctx.output[output] = proto.to_jsonpb(config)

    lucicfg.generator(impl = _generate_impl)

def _gen_file(content, output = "new_generated_file"):
    """Create a new file with open file name and free content.

    We can define the file name and file content freely.
    The new file will be created in the same directory of jsonproto files
    in each project repo. Example: project/fake/fake/generated/newfile
    """

    def _gen_file_impl(ctx):
        ctx.output[output] = content

    lucicfg.generator(impl = _gen_file_impl)

generate = struct(
    generate = _generate,
    gen_file = _gen_file,
)
