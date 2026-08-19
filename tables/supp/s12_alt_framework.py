"""Supplemental Table S12: sensitivity analysis — alternative 4-criterion framework."""
from tables import docx_helpers as dh
from tables.supp._sensitivity_common import HEADERS, COL_WIDTHS, build_rows

TABLE_NUM = "S12"
TITLE = ("Sensitivity analysis: category-level associations under the alternative 4-criterion framework (emphysema criterion replaced)")


def build(doc):
    tbl = dh.add_table(doc, HEADERS, build_rows("4-criterion alt"),
                       col_widths_in=COL_WIDTHS)
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
