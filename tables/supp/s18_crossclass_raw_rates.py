"""Supplemental Table S18: observed event rates in the four cross-classification
groups, with the counts and follow-up time behind each rate.

Main Table 2 reports the crude rate ratios these rates produce; this table
shows the rates themselves together with their numerators and denominators, so
each ratio can be reconstructed and the precision of each one judged directly.

Source:
    manuscript_assets/Table_2_raw_rates.csv
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S18"
TITLE = ("Observed event rates, event counts and follow-up time in the four "
         "cross-classification groups defined by concordance and discordance "
         "between the CT-based and ESI-based COPD definitions")

GROUPS = ["Both-noCOPD", "CT-only-COPD", "ESI-only-COPD", "Both-COPD"]

# (display label, event column, n column, person-year column, rate column,
#  decimal places on the rate)
OUTCOMES = [
    ("All-cause mortality",   "ev_allcause", "n_mort", "py_mort", "raw_allcause", 2),
    ("Respiratory mortality", "ev_resp",     "n_mort", "py_mort", "raw_resp",     3),
    ("Exacerbations",         "ev_exac",     "n_exac", "py_exac", "raw_exac",     2),
]


def _load():
    with open(os.path.join(ASSETS, "Table_2_raw_rates.csv")) as f:
        rows = {r["group"]: r for r in csv.DictReader(f)}
    missing = [g for g in GROUPS if g not in rows]
    if missing:
        raise KeyError(f"Table_2_raw_rates.csv is missing groups {missing}; "
                       f"it has {sorted(rows)}")
    needed = {c for _, ev, n, py, rate, _ in OUTCOMES for c in (ev, n, py, rate)}
    absent = sorted(needed - set(next(iter(rows.values()))))
    if absent:
        raise KeyError(f"Table_2_raw_rates.csv has no columns {absent}; "
                       f"re-render the analysis")
    return rows


def build(doc):
    src = _load()
    body_rows = []
    for label, ev_col, n_col, py_col, rate_col, dp in OUTCOMES:
        for g in GROUPS:
            r = src[g]
            rate = float(r[rate_col])
            # Every printed rate must equal its own numerator over its own
            # denominator; a mismatch means the columns were mis-paired here.
            check = 100 * float(r[ev_col]) / float(r[py_col])
            assert abs(rate - check) < 1e-6, (label, g, rate, check)
            body_rows.append([
                label, g,
                f"{int(float(r[n_col])):,}",
                f"{float(r[py_col]):,.0f}",
                f"{int(float(r[ev_col])):,}",
                f"{rate:.{dp}f}",
            ])

    headers = ["Outcome", "Classification group", "n",
               "Person-years", "Events", "Rate per 100 person-years"]
    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[1.25, 1.35, 0.60, 0.95, 0.75, 1.60])
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
