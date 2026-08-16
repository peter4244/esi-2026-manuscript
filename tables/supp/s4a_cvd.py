"""Supplementary Table S4a — CVD-specific mortality by Bhatt category."""
from tables import docx_helpers as dh
from tables.supp._cause_specific_common import (
    HEADERS, COL_WIDTHS, build_rows,
)

TABLE_NUM = "S4a"
TITLE = ("Cardiovascular-disease-specific mortality by Bhatt-framework "
         "diagnostic category under both frameworks")


def build(doc):
    dh.add_table(doc, HEADERS, build_rows("CVD"),
                 col_widths_in=COL_WIDTHS)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
