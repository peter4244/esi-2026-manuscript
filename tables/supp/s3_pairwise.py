"""Supplemental Table S3 — pairwise contrasts among the three
cross-classification groups (Both-COPD, CT-only-COPD, ESI-only-COPD),
all three outcomes.

"""
from tables import docx_helpers as dh
from tables.supp._pairwise_common import build_rows

TABLE_NUM = "S3"
TITLE = ("Pairwise contrasts among cross-classification groups "
         "(Both-COPD, CT-only-COPD, ESI-only-COPD), all outcomes")

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
    # Contrast column body values like "CT-only-COPD / ESI-only-COPD"
    # (28 chars) need at least 2.0"; Metric widened so "Metric" header
    # doesn't wrap; Estimate widened so "(Δlog)" fits with the parent.
    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[1.30, 0.70, 2.05, 1.05, 0.50, 0.90])
    # Vmerge the Outcome column so each outcome heading spans its three rows.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
