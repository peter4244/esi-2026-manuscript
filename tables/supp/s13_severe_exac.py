"""Supplemental Table S13: sensitivity analysis — severe exacerbations only."""
from tables import docx_helpers as dh
from tables.supp._sensitivity_common import HEADERS, COL_WIDTHS, build_rows

TABLE_NUM = "S13"
TITLE = ("Sensitivity analysis: category-level associations restricted to severe exacerbations only")


def build(doc):
    tbl = dh.add_table(doc, HEADERS, build_rows("severe exac only"),
                       col_widths_in=COL_WIDTHS)
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
