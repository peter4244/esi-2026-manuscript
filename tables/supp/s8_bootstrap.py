"""Supplementary Table S8 — paired-bootstrap framework-equivalence test at
the diagnostic-category level, all three outcomes.

Combines the HR bootstrap (all-cause + respiratory mortality) and the IRR
bootstrap (exacerbations) into a single table with a Metric column so the
scale of each row is unambiguous. Six rows total (3 outcomes × 2 categories).

Replaces the earlier separate S8 (mortality) and S8b (exacerbations) tables
— per project convention, closely related analyses live in one table rather
than a lettered suffix pair.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S8"
TITLE = ("Paired-bootstrap test of category-level equivalence between "
         "frameworks (Δlog-effect), all outcomes")


def _fmt(x, prec=2):
    return f"{float(x):.{prec}f}"


def _load(csv_name):
    with open(os.path.join(ASSETS, csv_name)) as f:
        return list(csv.DictReader(f))


def build(doc):
    hr_rows  = _load("Supp_Table_HR_Difference_Bootstrap.csv")
    irr_rows = _load("Supp_Table_IRR_Difference_Bootstrap.csv")

    outcome_display = {
        "all-cause":     ("All-cause mortality",   "HR"),
        "respiratory":   ("Respiratory mortality", "HR"),
        "exacerbations": ("Exacerbations",         "IRR"),
    }

    headers = ["Outcome", "Metric", "Category", "CT", "ESI",
               "Absolute diff", "Mean Δlog", "95% CI (Δlog)", "Two-sided p"]

    body = []
    def add(rows, ct_col, esi_col, absdiff_col, mean_col, cilo_col, cihi_col):
        for r in rows:
            display, metric = outcome_display[r["outcome"]]
            ci = f"({_fmt(r[cilo_col], 3)}, {_fmt(r[cihi_col], 3)})"
            body.append([display, metric, r["category"],
                         _fmt(r[ct_col]), _fmt(r[esi_col]),
                         _fmt(r[absdiff_col]),
                         _fmt(r[mean_col], 3),
                         ci,
                         r["two_sided_p_reported"]])

    add(hr_rows,  "HR_CT",  "HR_ESI",  "abs_HR_diff",
        "mean_logHR_diff",  "ci_lo_logHR",  "ci_hi_logHR")
    add(irr_rows, "IRR_CT", "IRR_ESI", "abs_IRR_diff",
        "mean_logIRR_diff", "ci_lo_logIRR", "ci_hi_logIRR")

    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[0.9, 0.5, 0.75, 0.5, 0.5, 0.7,
                                      0.7, 1.15, 0.7])
    # Vmerge the Outcome column so each outcome heading spans its two rows.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
