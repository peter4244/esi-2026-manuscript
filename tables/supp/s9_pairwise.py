"""Supplementary Table S9 — pairwise contrasts among the three
cross-classification groups (Both-COPD, Bhatt-only-COPD, ESI-only-COPD),
all three outcomes.

Replaces the earlier separate S9a (mortality) and S9b (exacerbations) tables
— per project convention, closely related analyses live in one table rather
than a lettered suffix pair.
"""
from tables import docx_helpers as dh
from tables.supp._pairwise_common import build_rows

TABLE_NUM = "S9"
TITLE = ("Pairwise contrasts among cross-classification groups "
         "(Both-COPD, Bhatt-only-COPD, ESI-only-COPD), all outcomes")

_OUTCOMES = [
    ("all-cause mortality",  "All-cause mortality",   "HR"),
    ("respiratory mortality", "Respiratory mortality", "HR"),
    ("exacerbations",         "Exacerbations",         "IRR"),
]


def build(doc):
    headers = ["Outcome", "Metric", "Contrast",
               "Estimate (Δlog)", "SE", "Adjusted p"]
    body = []
    for src_label, display_label, metric in _OUTCOMES:
        for row in build_rows(src_label):
            # build_rows yields [contrast, estimate, SE, adj_p]
            body.append([display_label, metric, *row])
    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[1.35, 0.5, 1.9, 1.05, 0.6, 1.0])
    # Vmerge the Outcome column so each outcome heading spans its three rows.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
