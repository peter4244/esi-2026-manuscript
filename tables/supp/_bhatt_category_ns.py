"""Shared Bhatt-framework category totals (N at risk).

Sourced from manuscript_assets/Table_6.csv row sums (Bhatt is the row axis of
Table 6, so row-sums are Bhatt-framework participant counts). Totals verified
to sum to 9,463 (the analytic-cohort N).

Used by S4a/S4b/S4c and S5 legends to state at-risk denominators without
repeating the numbers in each legend .md.
"""
BHATT_CATEGORY_NS = {
    "noCOPD":            4225,
    "AFL-only-noCOPD":    170,
    "COPD-minor":       1_099,
    "COPD-major":       3_969,
}
assert sum(BHATT_CATEGORY_NS.values()) == 9_463, (
    "Bhatt-category totals do not sum to analytic-cohort N; check Table_6.csv "
    "row sums."
)


def at_risk_sentence(include_noCOPD=False):
    """Return a legend-ready sentence enumerating the Bhatt-framework category
    totals used as at-risk denominators in ST4/ST5. By default lists the three
    non-reference categories (noCOPD is the reference and rarely quoted)."""
    def _fmt(n):
        return f"{n:,}"
    if include_noCOPD:
        cats = ["noCOPD", "AFL-only-noCOPD", "COPD-minor", "COPD-major"]
    else:
        cats = ["AFL-only-noCOPD", "COPD-minor", "COPD-major"]
    parts = [f"{c} n={_fmt(BHATT_CATEGORY_NS[c])}" for c in cats]
    return "Category totals (MD-COPD, at risk): " + ", ".join(parts) + "."
