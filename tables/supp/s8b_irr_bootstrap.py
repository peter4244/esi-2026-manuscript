"""Supplementary Table S8b — paired-bootstrap ΔlogIRR test for framework
equivalence at the category level for exacerbations. One outcome × two
categories = 2 rows. Analog of S8, using the negative-binomial exacerbation
model instead of Cox for mortality.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S8b"
TITLE = ("Paired-bootstrap test of category-level equivalence between "
         "frameworks for exacerbations (ΔlogIRR)")


def _fmt(x, prec=2):
    return f"{float(x):.{prec}f}"


def build(doc):
    with open(os.path.join(ASSETS,
                           "Supp_Table_IRR_Difference_Bootstrap.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Outcome", "Category", "IRR (CT)", "IRR (ESI)",
               "Absolute IRR diff", "Mean ΔlogIRR",
               "95% CI (ΔlogIRR)", "Two-sided p"]

    body_rows = []
    for r in rows:
        ci = f"({_fmt(r['ci_lo_logIRR'], 3)}, {_fmt(r['ci_hi_logIRR'], 3)})"
        body_rows.append([
            r["outcome"], r["category"],
            _fmt(r["IRR_CT"]),  _fmt(r["IRR_ESI"]),
            _fmt(r["abs_IRR_diff"]),
            _fmt(r["mean_logIRR_diff"], 3),
            ci,
            r["two_sided_p_reported"],
        ])

    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[0.9, 0.9, 0.55, 0.55, 0.85, 0.85, 1.2, 0.7])
    # Only one outcome in this table, so no vmerge needed.
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
