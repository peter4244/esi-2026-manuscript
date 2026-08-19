"""Supplemental Table S5 — Per-stratum Pearson correlations between ESI and
quantitative CT emphysema metrics (%LAA-950HU and PRM emphysema)."""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S5"
TITLE = ("Per-stratum Pearson correlations between ESI and quantitative CT "
         "emphysema metrics")


_STRATA_ORDER = ["Never", "GOLD0", "PRISm", "GOLD1", "GOLD2", "GOLD3",
                 "GOLD4", "All strata"]
_STRATUM_DISPLAY = {
    "GOLD0": "GOLD 0",
    "GOLD1": "GOLD 1",
    "GOLD2": "GOLD 2",
    "GOLD3": "GOLD 3",
    "GOLD4": "GOLD 4",
}


def _load(name):
    with open(os.path.join(ASSETS, name)) as f:
        return {r["stratum"]: r for r in csv.DictReader(f)}


def _fmt_r(x):
    return f"{float(x):.2f}"


def build(doc):
    laa = _load("Table_2.csv")            # r_LAA vs Insp_LAA950
    prm = _load("Table_2_PRMversion.csv")  # r_PRM vs PRM emphysema

    headers = ["Stratum",
               "N (ESI, %LAA-950HU)", "r (ESI, %LAA-950HU)",
               "N (ESI, PRM emphysema)", "r (ESI, PRM emphysema)"]

    body = []
    for s in _STRATA_ORDER:
        rL = laa[s]
        rP = prm[s]
        body.append([
            _STRATUM_DISPLAY.get(s, s),
            rL["n_LAA"], _fmt_r(rL["r_LAA"]),
            rP["n_PRM"], _fmt_r(rP["r_PRM"]),
        ])

    dh.add_table(doc, headers, body,
                 col_widths_in=[1.10, 1.30, 1.30, 1.35, 1.35])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
