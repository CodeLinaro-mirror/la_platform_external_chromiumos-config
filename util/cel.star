"""Functions related to CEL language operations.

"""

def _merge(*expressions):
    """Merge CEL expressions together with && clause.

    Args:
        *expressions: expressions to merge
    Returns:
        merged expression or None if there's no args
    """
    clauses = []
    for exp in expressions:
        if exp not in clauses:
            clauses.append(exp)

    if not clauses:
        return None

    clause_expr = "({})"

    return " && ".join(
        [
            clause_expr.format(clause)
            for clause in clauses
        ],
    )

cel = struct(
    merge = _merge,
)
