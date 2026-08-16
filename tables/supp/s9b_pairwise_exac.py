"""Supplementary Table S9b — FDR-adjusted pairwise log-IRR contrasts among
COPD-classification groups for exacerbations.
"""
from tables import docx_helpers as dh
from tables.supp._pairwise_common import build_rows

TABLE_NUM = "S9b"
TITLE = ("Pairwise log-IRR contrasts among cross-classification groups for "
         "exacerbations")


def build(doc):
    headers = ["Contrast", "Estimate (log IRR)", "SE", "Adjusted p"]
    rows = build_rows("exacerbations")
    dh.add_table(doc, headers, rows,
                 col_widths_in=[2.6, 1.5, 0.9, 1.2])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
