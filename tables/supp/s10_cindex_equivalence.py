"""Supplemental Table S10 — Framework-level discrimination equivalence
(C-index) between the CT-based and ESI-based diagnostic frameworks."""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S10"
TITLE = ("Discrimination-level equivalence between the CT-based and "
         "ESI-based frameworks (C-index, paired TOST)")


_OUTCOME_DISPLAY = {
    "all-cause":   "All-cause mortality",
    "respiratory": "Respiratory mortality",
}


def _fmt(x, prec=3):
    return f"{float(x):.{prec}f}"


def _fmt_p(p):
    p = float(p)
    return "<0.001" if p < 0.001 else f"{p:.3f}"


def _fmt_ci(lo, hi):
    return f"({_fmt(lo)}, {_fmt(hi)})"


def build(doc):
    with open(os.path.join(ASSETS,
                           "Table_1_Cindex_Equivalence.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Outcome", "CT C-index", "ESI C-index",
               "Δ C-index (CT − ESI)", "95% CI (Δ)",
               "TOST p (lower)", "TOST p (upper)", "Equivalent"]

    body = []
    for r in rows:
        equiv = "Yes" if r["equivalent_within_margin"].strip().upper() == "TRUE" else "No"
        body.append([
            _OUTCOME_DISPLAY.get(r["outcome"], r["outcome"]),
            _fmt(r["c_ct"]),
            _fmt(r["c_esi"]),
            _fmt(r["delta_c"]),
            _fmt_ci(r["ci_lo"], r["ci_hi"]),
            _fmt_p(r["tost_p_low"]),
            _fmt_p(r["tost_p_high"]),
            equiv,
        ])

    # 8 columns won't fit portrait 6.5"; use landscape.
    dh.begin_landscape(doc)
    dh.add_table(doc, headers, body,
                 col_widths_in=[1.60, 1.00, 1.05, 1.35, 1.30, 1.15, 1.15, 1.10],
                 max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    dh.end_landscape(doc)
