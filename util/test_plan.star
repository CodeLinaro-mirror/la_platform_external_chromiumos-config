"""Functions related to test planning.

See proto definitions for descriptions of arguments.
"""

# Needed to load from @proto. Add @unused to silence lint.
load("//config/util/bindings/proto.star", "protos")
load(
    "@proto//chromiumos/config/api/test/plan/v1/plan.proto",
    plan_pb = "chromiumos.config.api.test.plan.v1",
)

def _get_exclusion_type(type):
    """Get the exclusion type enum.

    Args:
        type: the exclusion type string.
    Returns:
        Exclusion type enum
    """

    if type == "PERMANENT":
        return plan_pb.Exclusion.PERMANENT
    if type == "TEMPORARY_NEW_TEST":
        return plan_pb.Exclusion.TEMPORARY_NEW_TEST
    if type == "TEMPORARY_PENDING_FIX":
        return plan_pb.Exclusion.TEMPORARY_PENDING_FIX

    return plan_pb.Exclusion.TYPE_UNSPECIFIED

def _get_exclusion_action(action):
    """Get the exclusion action enum.

    Args:
        action: the action type string.
    Returns:
        Exclusion action enum
    """
    if action == "DO_NOT_SCHEDULE":
        return plan_pb.Exclusion.DO_NOT_SCHEDULE
    if action == "MARK_NON_CRITICAL":
        return plan_pb.Exclusion.MARK_NON_CRITICAL

    return plan_pb.Exclusion.ACTION_UNSPECIFIED

def _create_exclusion(
        type = None,
        action = None,
        test_constraint = None,
        dut_constraint = None,
        references = None):
    """Builds a test exclusion proto.

    Args:
        type: the exclusion type.
        action: the exclusion action.
        test_constraint: the test constraint protobuf.
        dut_constraint: the dut exclusion constraint protobuf.
        references: list of reference(s) associated.
    Returns:
        the Exclusion protobuf.
    """
    return plan_pb.Exclusion(
        type = _get_exclusion_type(type),
        action = _get_exclusion_action(action),
        test_constraint = _create_test_constraint(test_constraint),
        dut_constraint = _create_dut_exclusion_constraint(dut_constraint),
        references = references if references else None,
    )

def _create_code_constraint(expression = None):
    """Builds a code coverage proto.

    Args:
        expression: Code coverage expression.
    Returns:
        the CodeCovarage protobuf.
    """
    return plan_pb.CodeCoverage(
        expression = expression,
    ) if expression else None

def _create_dut_constraint(expression = None):
    """Builds a dut coverage constraint proto.

    Args:
        expression: DUT coverage constraint expression.
    Returns:
        the DUTCoverageConstraint protobuf.
    """
    return plan_pb.DUTCoverageConstraint(
        expression = expression,
    ) if expression else None

def _dut_design_configs(*design_configs):
    """Include the given design config(s) as dut constraints.

    Args:
        *design_configs: list of design configs to constraint.
    Returns:
        the dut constraint expression.
    """
    if not design_configs:
        return None

    design_configs_expr = "duts.all(dut, {})"
    predicate_expr = "dut.design_config_id.value == '{}'"

    predicates = " || ".join(
        [
            predicate_expr.format(design_config)
            for design_config in sorted(design_configs)
        ],
    )
    return design_configs_expr.format(predicates)

def _dut_wifi_chips(*wifi_chips):
    """Include the given design config(s) as dut constraints.

    Args:
        *wifi_chips: list of wifi chips used to constrain.
    Returns:
        the dut constraint expression.
    """
    if not wifi_chips:
        return None

    wifi_chip_expr = ("duts.all(" +
                      "dut, dut.hardware_features.wifi.wifi_chips.exists(" +
                      "chip, chip == {}))")

    return " || ".join(
        [
            wifi_chip_expr.format(wifi_chip.upper())
            for wifi_chip in sorted(wifi_chips)
        ],
    )

def _create_dut_exclusion_constraint(expression = None):
    """Builds a dut exclusion constraint proto.

    Args:
        expression: DUT exclusion constraint expression.
    Returns:
        the DUTCoverageConstraint protobuf.
    """
    return plan_pb.DUTExclusionConstraint(
        expression = expression,
    ) if expression else None

def _create_test_constraint(expression = None):
    """Builds a test constraint proto.

    Args:
        expression: test constraint expression.
    Returns:
        the TestConstraint protobuf.
    """
    return plan_pb.TestConstraint(
        expression = expression,
    ) if expression else None

def _test_suites(*suites):
    """Add the given suite(s) as test constraints.

    Args:
        *suites: list of suite(s) to include in the constraint.
    Returns:
        test constraint expression.
    """
    return " || ".join(
        ["suite:{}".format(suite) for suite in suites],
    )

def _append_unit(
        units,
        name,
        test_constraint = None,
        dut_coverage_constraint = None,
        code_coverage = None,
        exclusions = None):
    """Appends a test unit proto to existing units

    Args:
        units: the existing unit(s) to append to
        name: name of the unit.
        test_constraint: TestConstraint protobuf.
        dut_coverage_constraint: DUTCoverageConstraint protobuf.
        code_coverage: CodeCoverage protobuf.
        exclusions: list of Exclusion protobuf(s).
    Returns:
        the Unit protobuf.
    """
    units.append(_create_unit(name, test_constraint, dut_coverage_constraint, code_coverage, exclusions))

def _create_unit(name, test_constraint = None, dut_coverage_constraint = None, code_coverage = None, exclusions = None):
    """Builds a test unit proto.

    Args:
        name: name of the unit.
        test_constraint: TestConstraint protobuf.
        dut_coverage_constraint: DUTCoverageConstraint protobuf.
        code_coverage: CodeCoverage protobuf.
        exclusions: list of Exclusion protobuf(s).
    Returns:
        the Unit protobuf.
    """
    return plan_pb.Unit(
        name = name,
        test_constraint = test_constraint,
        dut_coverage_constraint = dut_coverage_constraint,
        code_coverage = code_coverage,
        exclusions = exclusions if exclusions else None,
    )

def _create_plan(name, units = None):
    """Builds a test plan proto.

    Args:
        name: name of the plan.
        units: list of test units to include in the plan.
    Returns:
        the Plan protobuf.
    """
    sorted_units = sorted(units, key = lambda u: u.name) if units else None
    return plan_pb.Plan(name = name, units = sorted_units)

def _create_spec(plans):
    """Builds a test specification proto.

    Args:
        plans: list of test plans
    Returns:
        the Specification protobuf.
    """
    return plan_pb.Specification(plans = plans if plans else None)

test_plan = struct(
    code = struct(
        constraint = _create_code_constraint,
    ),
    create = _create_plan,
    dut = struct(
        constraint = _create_dut_constraint,
        exclusion_constraint = _create_dut_exclusion_constraint,
        design_configs = _dut_design_configs,
        wifi_chips = _dut_wifi_chips,
    ),
    test = struct(
        constraint = _create_test_constraint,
        suites = _test_suites,
    ),
    exclusion = struct(
        create = _create_exclusion,
    ),
    unit = struct(
        append = _append_unit,
        create = _create_unit,
    ),
    spec = struct(
        create = _create_spec,
    ),
)
