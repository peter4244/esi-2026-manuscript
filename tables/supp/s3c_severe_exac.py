"""Supplementary Table S3c — sensitivity: analyses restricted to severe
exacerbations only."""
from tables import docx_helpers as dh
from tables.supp._s3_sensitivity_common import HEADERS, COL_WIDTHS, build_rows

TABLE_NUM = "S3c"
TITLE = ("Sensitivity analysis: category-level associations for severe "
         "exacerbations only")


def build(doc):
    tbl = dh.add_table(doc, HEADERS, build_rows("severe exac only"),
                       col_widths_in=COL_WIDTHS)
    # S3c has only one outcome (exacerbations), so col 0 vmerge would span
    # the whole body — visually fine and preserves layout symmetry with S3a/b.
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
