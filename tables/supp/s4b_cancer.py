"""Supplementary Table S4b — cancer-specific mortality by Bhatt category."""
from tables import docx_helpers as dh
from tables.supp._cause_specific_common import (
    HEADERS, COL_WIDTHS, build_rows,
)

TABLE_NUM = "S4b"
TITLE = ("Cancer-specific mortality by MD-COPD diagnostic category "
         "under both frameworks")


def build(doc):
    dh.add_table(doc, HEADERS, build_rows("Cancer"),
                 col_widths_in=COL_WIDTHS)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
