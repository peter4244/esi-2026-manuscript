"""Supplemental Table S9 — FEV1 decline (mL/yr) by Bhatt category, both
frameworks. Uses the mixed-effects slope estimates from Table_BhattDecline.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S9"
TITLE = ("FEV₁ decline (mL/yr) by MD-COPD diagnostic category under "
         "both frameworks")


CATEGORY_ORDER = ["AFL-only-NoCOPD", "COPD-minor", "COPD-major"]
CATEGORY_DISPLAY = {
    "AFL-only-NoCOPD": "AFL-only-noCOPD",
    "COPD-minor":      "COPD-minor",
    "COPD-major":      "COPD-major",
}


def _fmt_p(p):
    p = float(p)
    return "<0.001" if p < 0.001 else f"{p:.2f}"


def _fmt(x):
    return f"{float(x):.2f}"


def build(doc):
    with open(os.path.join(ASSETS, "Table_BhattDecline.csv")) as f:
        rows = list(csv.DictReader(f))
    by_group = {r["group"]: r for r in rows}

    body_rows = []
    for cat in CATEGORY_ORDER:
        r = by_group[cat]
        body_rows.append([
            CATEGORY_DISPLAY[cat],
            _fmt(r["bhatt_est"]), _fmt(r["bhatt_se"]), _fmt_p(r["bhatt_p"]),
            _fmt(r["esi_est"]),   _fmt(r["esi_se"]),   _fmt_p(r["esi_p"]),
        ])

    headers = ["Category", "CT-based estimate (mL/yr)", "SE", "p",
               "ESI-based estimate (mL/yr)", "SE", "p"]
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[1.55, 1.25, 0.5, 0.5, 1.25, 0.5, 0.5])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
