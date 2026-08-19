"""Supplemental Table S11: sensitivity analysis — ESI = 10 excluded."""
from tables import docx_helpers as dh
from tables.supp._sensitivity_common import HEADERS, COL_WIDTHS, build_rows

TABLE_NUM = "S11"
TITLE = ("Sensitivity analysis: category-level associations after excluding participants at the ESI ceiling (ESI = 10)")


def build(doc):
    tbl = dh.add_table(doc, HEADERS, build_rows("ESI=10 excluded"),
                       col_widths_in=COL_WIDTHS)
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
