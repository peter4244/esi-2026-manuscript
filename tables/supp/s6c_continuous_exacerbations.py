"""Supplementary Table S6c — continuous-ESI negative-binomial models for
exacerbations, with FEV1/FVC comparator and combined-model LR test.
"""
from tables import docx_helpers as dh
from tables.supp._continuous_esi_common import (
    HEADERS_IRR, COL_WIDTHS, load_and_filter,
)

TABLE_NUM = "S6c"
TITLE = ("Continuous ESI vs FEV1/FVC as predictors of exacerbation counts, "
         "and combined-model likelihood-ratio test")


def build(doc):
    rows = load_and_filter("Table_S6b_continuous_exacerbations.csv",
                            outcome_label="exacerbations",
                            effect_prefix="IRR")
    dh.add_table(doc, HEADERS_IRR, rows, col_widths_in=COL_WIDTHS)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
