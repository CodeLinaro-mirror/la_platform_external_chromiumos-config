def _generate(config):
  def _generate_impl(ctx):
    ctx.output["config.cfg"] = proto.to_textpb(config)
    ctx.output["config.binaryproto"] = proto.to_wirepb(config)
  lucicfg.generator(impl = _generate_impl)

generate = struct(
    generate = _generate,
)
