"""Shared row-builder for Supplementary Tables S3a/S3b/S3c.

Each of the three sensitivity analyses (ESI=10 excluded, 4-criterion alt,
severe-exacerbations-only) shares the same source CSV
(Table_S3_sensitivity.csv) and cell format. This helper factors the row
construction so the three per-analysis modules stay minimal.
"""
import csv
import os

from manifest import ASSETS


def _fmt_p(p):
    p = float(p)
    return "<0.001" if p < 0.001 else f"{p:.2f}"


def _fmt_est(est, lci, uci):
    return f"{float(est):.2f} ({float(lci):.2f}–{float(uci):.2f})"


_CAT_DISPLAY = {
    "AFL-only-NoCOPD": "AFL-only-noCOPD",
    "COPD-minor":      "COPD-minor",
    "COPD-major":      "COPD-major",
}


_OUTCOME_ORDER   = ["all-cause", "respiratory", "exacerbations"]
_FRAMEWORK_ORDER = ["CT-based", "ESI-based"]
_CATEGORY_ORDER  = ["AFL-only-NoCOPD", "COPD-minor", "COPD-major"]


def build_rows(sensitivity_label):
    """Load Table_S3_sensitivity.csv, filter to the given sensitivity variant,
    and return rows sorted (outcome, framework, category) so the natural
    grouping columns (Outcome, Framework) render as vertical blocks under
    vmerge_col."""
    with open(os.path.join(ASSETS, "Table_S3_sensitivity.csv")) as f:
        rows = [r for r in csv.DictReader(f)
                if r["sensitivity"] == sensitivity_label]
    if not rows:
        raise ValueError(
            f"Table_S3_sensitivity.csv has no rows for "
            f"sensitivity={sensitivity_label!r}; check the source CSV."
        )

    def _key(r):
        return (
            _OUTCOME_ORDER.index(r["outcome"])
                if r["outcome"] in _OUTCOME_ORDER else 99,
            _FRAMEWORK_ORDER.index(r["framework"])
                if r["framework"] in _FRAMEWORK_ORDER else 99,
            _CATEGORY_ORDER.index(r["group"])
                if r["group"] in _CATEGORY_ORDER else 99,
        )
    rows.sort(key=_key)

    return [[
        r["outcome"],
        r["framework"],
        _CAT_DISPLAY.get(r["group"], r["group"]),
        _fmt_est(r["estimate"], r["LCI"], r["UCI"]),
        _fmt_p(r["p"]),
    ] for r in rows]


HEADERS = ["Outcome", "Framework", "Category", "Estimate (95% CI)", "p"]
COL_WIDTHS = [1.1, 1.0, 1.5, 1.9, 0.9]
