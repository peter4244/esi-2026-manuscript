"""Supplementary Table S4c — 'other-cause' mortality by Bhatt category (all
mortality events with a cause code that is neither cardiovascular nor cancer).
"""
from tables import docx_helpers as dh
from tables.supp._cause_specific_common import (
    HEADERS, COL_WIDTHS, build_rows,
)

TABLE_NUM = "S4c"
TITLE = ("Other-cause (non-cardiovascular, non-cancer) mortality by "
         "Bhatt-framework diagnostic category under both frameworks")


def build(doc):
    dh.add_table(doc, HEADERS, build_rows("Other"),
                 col_widths_in=COL_WIDTHS)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
