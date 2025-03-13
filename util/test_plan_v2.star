"""Helper functions for generating v2 TestPlan protos.

These fns. are mostly thin wrappers around the proto constructors. Reading the
proto definitions may give more complete explanations of messages, arguments,
etc.
"""

# TODO(b/196070598): Remove "v2" from file name once these are the only used
# test plan protos.

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load("//config/util/generate.star", "generate")
load(
    "@proto//chromiumos/test/api/plan.proto",
    plan_pb = "chromiumos.test.api",
)
load(
    "@proto//chromiumos/test/api/coverage_rule.proto",
    coverage_rule_pb = "chromiumos.test.api",
)
load(
    "@proto//chromiumos/test/api/dut_attribute.proto",
    dut_attribute_pb = "chromiumos.test.api",
)
load(
    "@proto//chromiumos/test/api/test_suite.proto",
    test_suite_pb = "chromiumos.test.api",
)

def _hw_test_plan(id, hw_test_units):
    """Creates a HWTestPlan proto.

    Args:
        id: Unique name to identify the test plan, recommend reverse domain name
            rooted at chromeos: chromeos.release.wifi..
        hw_test_units: List of HWTestUnit protos.
    """
    return plan_pb.HWTestPlan(
        id = plan_pb.HWTestPlan.TestPlanId(
            value = id,
        ),
        test_units = hw_test_units,
    )

def _hw_test_unit(coverage_rule):
    """Creates a HWTestUnit proto.

    Args:
        coverage_rule: CoverageRule proto describing tests to run and DUTs to
            target.
    """
    return plan_pb.HWTestUnit(
        coverage_rule = coverage_rule,
    )

def _coverage_rule(test_suites, dut_targets, name = None):
    """Creates a CoverageRule proto.

    Args:
        test_suites: List of TestSuite protos.
        dut_targets: List of DutTarget protos.
        name: Optional human-readable name for the rule.
    """
    return coverage_rule_pb.CoverageRule(
        name = name,
        test_suites = test_suites,
        dut_targets = dut_targets,
    )

def _dut_target(dut_criteria, provision_config = None):
    """Creates a DutTarget proto.

    Args:
        dut_criteria: A list of DutCriterion targetting a DUT.
        provision_config: Optional provisioning config for the DUT.
    """
    return dut_attribute_pb.DutTarget(
        criteria = dut_criteria,
        provision_config = provision_config,
    )

def _dut_criterion(attribute_id, values):
    """Creates a DutCriterion proto.

    Args:
        attribute_id: Globally unique string identifier for the attribute.
        values: List of ANY acceptable string values to match (OR logic is
        applied). Values are compared as simple strings case insensitively.
    """
    return dut_attribute_pb.DutCriterion(
        attribute_id = dut_attribute_pb.DutAttribute.Id(
            value = attribute_id,
        ),
        values = values,
    )

def _test_suite_with_tags(name, tags, excluded_tags = None):
    """Creates a TestSuite proto with a tag-based selction criteria.

    Tests are included if they meet the following:
      - MATCH ALL of the [include] tags.
      - DO NOT MATCH ANY of the exclude tags.

    Tags must match exactly (i.e. no regexp, wildcard, etc. allowed).

    Args:
        name: Human-readable name for the test suite.
        tags: Tags to include in the test case selection criteria.
        excluded_tags: Tags to exclude in the test case selection criteria.
    """
    return test_suite_pb.TestSuite(
        name = name,
        test_case_tag_criteria = test_suite_pb.TestSuite.TestCaseTagCriteria(
            tags = tags,
            tag_excludes = excluded_tags,
        ),
    )

def _generate(test_plan):
    """Serialize a test plan to jsonproto.

    The output file name is based on the id of the test plan.

    Args:
        test_plan: A HWTestPlan to serialize.
    """
    file_name = test_plan.id.value.lower().replace(" ", "_")
    generate.generate(test_plan, "{}.jsonproto".format(file_name))

test_plan_v2 = struct(
    generate = _generate,
    dut_criterion = _dut_criterion,
    dut_target = _dut_target,
    hw_test_plan = _hw_test_plan,
    hw_test_unit = _hw_test_unit,
    coverage_rule = _coverage_rule,
    test_suite_with_tags = _test_suite_with_tags,
)
