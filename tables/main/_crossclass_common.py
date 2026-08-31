"""Shared shape for the two cross-classification tables.

Tables 2 and 3 hold the same four groups, in the same order, in the same
four-column layout, and differ only in whether the estimate is crude or
adjusted. Keeping the group list, the number format and the cell rendering in
one place is what makes them render as a matched pair; when they drifted apart
visually it was because each table set its own alignment and spacing.
"""
from docx.shared import Pt
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH

from tables import docx_helpers as dh

GROUPS = ["Both-noCOPD", "CT-only-COPD", "ESI-only-COPD", "Both-COPD"]
REFERENCE = "Both-noCOPD"

BODY_FS = 9
COL_WIDTHS = [1.70, 1.60, 1.60, 1.60]


def fmt(est, lci, uci):
    return f"{float(est):.2f} ({float(lci):.2f}–{float(uci):.2f})"


def render(doc, headers, body_rows):
    """Render one cross-classification table: values centered, labels left,
    every cell vertically centered on tight paragraph spacing."""
    assert abs(sum(COL_WIDTHS) - dh.CONTENT_WIDTH_IN) < 0.011, sum(COL_WIDTHS)
    tbl = dh.add_table(doc, headers, body_rows, col_widths_in=COL_WIDTHS,
                       body_fs=BODY_FS, header_fs=BODY_FS)
    for row in tbl.rows:
        for j, cell in enumerate(row.cells):
            p = cell.paragraphs[0]
            pf = p.paragraph_format
            pf.space_before = Pt(1)
            pf.space_after = Pt(1)
            pf.line_spacing = 1.0
            if j:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
    return tbl
