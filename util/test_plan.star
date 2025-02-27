"""Functions related to test planning.

See proto definitions for descriptions of arguments.
"""

load(
    "@proto//chromiumos/config/api/test/plan/v1/plan.proto",
    plan_pb = "chromiumos.config.api.test.plan.v1",
)
load("//config/util/generate.star", "generate")

# TODO (b/237300719): determine if this needs to be fixed.
# def _get_exclusion_type(type):
#     """Get the exclusion type enum.

#     Args:
#         type: the exclusion type string.
#     Returns:
#         Exclusion type enum
#     """

#     if type == "PERMANENT":
#         return plan_pb.Exclusion.PERMANENT
#     if type == "TEMPORARY_NEW_TEST":
#         return plan_pb.Exclusion.TEMPORARY_NEW_TEST
#     if type == "TEMPORARY_PENDING_FIX":
#         return plan_pb.Exclusion.TEMPORARY_PENDING_FIX

#     return plan_pb.Exclusion.TYPE_UNSPECIFIED

# def _get_exclusion_action(action):
#     """Get the exclusion action enum.

#     Args:
#         action: the action type string.
#     Returns:
#         Exclusion action enum
#     """
#     if action == "DO_NOT_SCHEDULE":
#         return plan_pb.Exclusion.DO_NOT_SCHEDULE
#     if action == "MARK_NON_CRITICAL":
#         return plan_pb.Exclusion.MARK_NON_CRITICAL

#     return plan_pb.Exclusion.ACTION_UNSPECIFIED

# def _create_exclusion(
#         type = None,
#         action = None,
#         references = None):
#     """Builds a test exclusion proto.

#     Args:
#         type: the exclusion type.
#         action: the exclusion action.
#         references: list of reference(s) associated.
#     Returns:
#         the Exclusion protobuf.
#     """
#     return plan_pb.Exclusion(
#         type = _get_exclusion_type(type),
#         action = _get_exclusion_action(action),
#         references = references if references else None,
#     )

def _create_dut_criterion(attribute, values):
    """Builds a DutCriterion proto (see proto for args)
    """
    return plan_pb.DutCriterion(
        attribute = attribute,
        values = values,
    )

def _create_coverage_rule(name, dut_criteria, exclusion = None):
    """Builds a CoverageRule proto (see proto for args)
    """
    return plan_pb.CoverageRule(
        name = name,
        dut_criteria = dut_criteria,
        exclusion = exclusion,
    )

def _append_unit(
        units,
        name,
        suite_names = None,
        coverage_rules = None,
        exclusion = None):
    """Appends a test unit proto to existing units

    Args:
        units: the existing unit(s) to append to
        name: name of the unit.
        suite_names: list of test suite names to run.
        coverage_rules: list of coverage rules that must be fulfilled.
        exclusion: optional Exclusion for the entire unit.
    Returns:
        the Unit protobuf.
    """
    units.append(_create_unit(name, suite_names, coverage_rules, exclusion))

def _create_unit(
        name,
        suite_names = None,
        coverage_rules = None,
        exclusion = None):
    """Builds a test unit proto.

    Args:
        name: name of the unit.
        suite_names: list of test suite names to run.
        coverage_rules: list of coverage rules that must be fulfilled.
        exclusion: optional Exclusion for the entire unit.
    Returns:
        the Unit protobuf.
    """
    suites = None
    if suite_names:
        suites = [plan_pb.Unit.Suite(name = name) for name in suite_names]

    return plan_pb.Unit(
        name = name,
        suites = suites,
        coverage_rules = coverage_rules,
        exclusion = exclusion,
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

def _generate_plan(test_plan):
    """Compiles the starkark to generate a jsonproto output file

    Args:
        test_plan: test plan
    """
    file_name = test_plan.name.lower().replace(" ", "_")
    generate.generate(_create_spec([test_plan]), "%s.jsonproto" % file_name)

def _read_plan(file_path):
    """Reads the test plan Specification proto and returns it

    Args:
        file_path: Source jsonproto file path
    """
    return proto.from_jsonpb(
        plan_pb.Specification,
        io.read_file(file_path),
    )

test_plan = struct(
    create = _create_plan,
    generate = _generate_plan,
    read = _read_plan,
    dut_criterion = struct(
        create = _create_dut_criterion,
    ),
    coverage_rule = struct(
        create = _create_coverage_rule,
    ),
    unit = struct(
        append = _append_unit,
        create = _create_unit,
    ),
    spec = struct(
        create = _create_spec,
    ),
)
