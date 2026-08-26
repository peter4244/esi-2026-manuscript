"""Supplemental Table S2 — paired-bootstrap framework-equivalence test at
the diagnostic-category level, all three outcomes.

Combines the HR bootstrap (all-cause + respiratory mortality) and the IRR
bootstrap (exacerbations) into a single table with a Metric column so the
scale of each row is unambiguous. Six rows total (3 outcomes × 2 categories).

"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S2"
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
               "Difference (CT − ESI)", "Observed Δlog", "95% CI (Δlog)", "Two-sided p"]

    body = []
    def add(rows, ct_col, esi_col, absdiff_col, est_col, cilo_col, cihi_col):
        for r in rows:
            display, metric = outcome_display[r["outcome"]]
            ci = f"({_fmt(r[cilo_col], 3)}, {_fmt(r[cihi_col], 3)})"
            body.append([display, metric, r["category"],
                         _fmt(r[ct_col]), _fmt(r[esi_col]),
                         _fmt(r[absdiff_col]),
                         _fmt(r[est_col], 3),
                         ci,
                         r["two_sided_p_reported"]])

    # The CI is on the log scale, so the estimate beside it is the OBSERVED
    # log-scale difference. It was previously `mean_log*_diff`, the mean of the
    # bootstrap replicates, which carries resampling bias and is not the
    # quantity the interval brackets. The unlogged difference stays as a
    # descriptive column; the Metric column says whether it is an HR or an IRR.
    add(hr_rows,  "HR_CT",  "HR_ESI",  "HR_diff_unlogged",
        "obs_logHR_diff",  "ci_lo_logHR",  "ci_hi_logHR")
    add(irr_rows, "IRR_CT", "IRR_ESI", "IRR_diff_unlogged",
        "obs_logIRR_diff", "ci_lo_logIRR", "ci_hi_logIRR")

    # 9 columns with mixed long headers ("Absolute diff", "Mean Δlog",
    # "95% CI (Δlog)", "Two-sided p") won't fit in portrait 6.5" without
    # header wraps. Landscape gives 10.3" of usable width; every header
    # and every body value fits on one line.
    dh.begin_landscape(doc)
    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[1.55, 0.60, 1.10, 0.55, 0.55, 1.05,
                                      0.95, 1.55, 0.90],
                       max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    # Vmerge the Outcome column so each outcome heading spans its two rows.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    dh.end_landscape(doc)
