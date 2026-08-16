"""Supplementary Table S9a — FDR-adjusted pairwise log-HR contrasts among the
three COPD-classification groups (Both-COPD, Bhatt-only, ESI-only) for both
mortality outcomes (all-cause first, then respiratory). Six rows total.

Referenced from tables/main/table2_cross_classification_legend.md, which cites
the all-cause p-values directly from this table.
"""
from tables import docx_helpers as dh
from tables.supp._pairwise_common import build_rows

TABLE_NUM = "S9a"
TITLE = ("Pairwise log-HR contrasts among cross-classification groups for "
         "all-cause and respiratory mortality")

_OUTCOMES = [
    ("all-cause mortality",  "All-cause mortality"),
    ("respiratory mortality", "Respiratory mortality"),
]


def build(doc):
    headers = ["Outcome", "Contrast", "Estimate (log HR)", "SE", "Adjusted p"]
    body = []
    for src_label, display_label in _OUTCOMES:
        for row in build_rows(src_label):
            body.append([display_label, *row])
    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[1.5, 2.1, 1.15, 0.65, 1.1])
    # Each outcome (all-cause, respiratory) has 3 contrast rows — collapse.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
