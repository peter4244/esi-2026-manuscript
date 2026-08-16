"""Supplementary Table S8 — paired-bootstrap ΔlogHR test for framework
equivalence at the category level. Two outcomes × two categories = 4 rows.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S8"
TITLE = ("Paired-bootstrap test of category-level equivalence between "
         "frameworks (ΔlogHR)")


def _fmt(x, prec=2):
    return f"{float(x):.{prec}f}"


def build(doc):
    with open(os.path.join(ASSETS, "Supp_Table_HR_Difference_Bootstrap.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Outcome", "Category", "HR (CT)", "HR (ESI)",
               "Absolute HR diff", "Mean ΔlogHR",
               "95% CI (ΔlogHR)", "Two-sided p"]

    body_rows = []
    for r in rows:
        ci = f"({_fmt(r['ci_lo_logHR'], 3)}, {_fmt(r['ci_hi_logHR'], 3)})"
        body_rows.append([
            r["outcome"], r["category"],
            _fmt(r["HR_CT"]),  _fmt(r["HR_ESI"]),
            _fmt(r["abs_HR_diff"]),
            _fmt(r["mean_logHR_diff"], 3),
            ci,
            r["two_sided_p_reported"],
        ])

    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[0.9, 0.9, 0.55, 0.55, 0.85, 0.85, 1.2, 0.7])
    # Each outcome (all-cause, respiratory) has 2 category rows — collapse.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
