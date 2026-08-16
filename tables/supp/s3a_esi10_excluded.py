"""Supplementary Table S3a — sensitivity: participants at the ESI ceiling
(ESI = 10) excluded."""
from tables import docx_helpers as dh
from tables.supp._s3_sensitivity_common import HEADERS, COL_WIDTHS, build_rows

TABLE_NUM = "S3a"
TITLE = ("Sensitivity analysis: category-level associations after excluding "
         "participants at the ESI ceiling (ESI = 10)")


def build(doc):
    tbl = dh.add_table(doc, HEADERS, build_rows("ESI=10 excluded"),
                       col_widths_in=COL_WIDTHS)
    # Collapse repeated Outcome (3 groups × 6 rows) and Framework
    # (6 groups × 3 rows) headers vertically.
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
