"""Supplementary Table S6a — continuous-ESI models for all-cause mortality,
compared with FEV1/FVC and combined-model likelihood-ratio tests.
"""
from tables import docx_helpers as dh
from tables.supp._continuous_esi_common import (
    HEADERS_HR, COL_WIDTHS, load_and_filter,
)

TABLE_NUM = "S6a"
TITLE = ("Continuous ESI vs FEV1/FVC as predictors of all-cause mortality, "
         "and combined-model likelihood-ratio test")


def build(doc):
    rows = load_and_filter("Table_S6a_continuous_mortality.csv",
                            outcome_label="all-cause", effect_prefix="HR")
    dh.add_table(doc, HEADERS_HR, rows, col_widths_in=COL_WIDTHS)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
