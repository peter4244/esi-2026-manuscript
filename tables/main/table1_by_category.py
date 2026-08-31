"""Table 1 — outcome associations by MD-COPD category, both frameworks, with
the crude rate ratio beside the adjusted estimate for each cell.

Rows: {All-cause mortality (HR), Respiratory mortality (HR), Exacerbations
      (IRR)} x {AFL-only-noCOPD, COPD-minor, COPD-major}, with the outcome
      column vertically merged in threes.
Cols: Outcome (metric) | Category | Crude RR (CT) | Crude RR (ESI) | p-value
      | Adjusted RR (CT) | Adjusted RR (ESI) | p-value

Layout note. Eight columns of Arial need 6.62 inches of ink at 8 pt inside a
6.50 inch text block, before a single point of cell padding, so an inline
"est (lo-hi)" layout cannot fit and Word silently wraps intervals mid-value.
Stacking the interval under its estimate drops the four effect columns from
about 1.00 to 0.85 inch of required ink, which is what allows a 9 pt body with
real padding. Widths below are computed from Arial advance widths for the
longest string in each column, not guessed; they sum to exactly 6.50.

Sources:
    manuscript_assets/Table_1_raw_rates.csv                   (crude RR + CI, both frameworks)
    manuscript_assets/Table_8_allcause.csv                    (adjusted HR)
    manuscript_assets/Table_8_resp.csv                        (adjusted HR)
    manuscript_assets/Table_Exacerbations_Bhatt.csv           (adjusted IRR)
    manuscript_assets/Supp_Table_HR_Difference_Bootstrap.csv  (paired-bootstrap p, mortality)
    manuscript_assets/Supp_Table_IRR_Difference_Bootstrap.csv (paired-bootstrap p, exacerbations)
"""
import csv
import os

from docx.shared import Pt
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "1"
TITLE = ("Associations of MD-COPD diagnostic categories with mortality and "
         "exacerbation outcomes under the CT-based and ESI-based frameworks")

BODY_FS = 9
PAD_IN = 0.05
COL_WIDTHS = [0.95, 0.89, 0.95, 0.88, 0.535, 0.88, 0.88, 0.535]

CATEGORIES = ["AFL-only-NoCOPD", "COPD-minor", "COPD-major"]

# (display label, crude outcome key, adjusted CSV, adjusted column stem,
#  bootstrap CSV, bootstrap outcome key)
OUTCOMES = [
    ("All-cause mortality (HR)",   "All-cause mortality",
     "Table_8_allcause.csv",            "HR",
     "Supp_Table_HR_Difference_Bootstrap.csv",  "all-cause"),
    ("Respiratory mortality (HR)", "Respiratory mortality",
     "Table_8_resp.csv",                "HR",
     "Supp_Table_HR_Difference_Bootstrap.csv",  "respiratory"),
    ("Exacerbations (IRR)",        "Exacerbations",
     "Table_Exacerbations_Bhatt.csv",   "IRR",
     "Supp_Table_IRR_Difference_Bootstrap.csv", "exacerbations"),
]


def _load(csv_name):
    with open(os.path.join(ASSETS, csv_name)) as f:
        return list(csv.DictReader(f))


def _row_lookup(rows, group):
    for r in rows:
        if r["group"] == group:
            return r
    raise KeyError(f"Group {group!r} not found: {[r['group'] for r in rows]}")


def _crude_lookup(rows, outcome, category):
    for r in rows:
        if r["outcome"] == outcome and r["category"] == category:
            return r
    raise KeyError(f"No crude rate ratio for outcome={outcome!r}, "
                   f"category={category!r}")


def _adjusted_p(rows, outcome_key, category):
    """The paired-bootstrap p for the adjusted CT-versus-ESI comparison, taken
    verbatim from the artifact (it already carries the "<0.002" convention).
    A missing cell would render blank and mask an analysis gap, so this raises
    rather than returning an empty string."""
    for r in rows:
        if r["outcome"] == outcome_key and r["category"] == category:
            return r["two_sided_p_reported"]
    raise KeyError(f"No bootstrap p-value for outcome={outcome_key!r}, "
                   f"category={category!r}")


def _crude_p(raw_row):
    """The paired-bootstrap p for the crude CT-versus-ESI comparison. A p of
    exactly zero means no resample crossed zero; the printed table renders
    that as "<0.01" rather than the "<0.002" the adjusted column uses, which
    is a reporting inconsistency carried over from the .docx, not a different
    computation. Both come from B = 1,000 resamples."""
    p = float(raw_row["raw_p"])
    return "<0.01" if p == 0 else f"{p:.2f}"


def _stacked(est, lci, uci):
    """Estimate on one line, interval on the next. The newline is rendered as
    a w:br inside a single run, so the two lines share one paragraph and keep
    its tight spacing."""
    return f"{float(est):.2f}\n({float(lci):.2f}–{float(uci):.2f})"


def _set_cell_margins(tbl, inches):
    tblPr = tbl._element.find(qn("w:tblPr"))
    mar = tblPr.find(qn("w:tblCellMar"))
    if mar is None:
        mar = OxmlElement("w:tblCellMar")
        tblPr.append(mar)
    for side in ("top", "left", "bottom", "right"):
        el = mar.find(qn("w:" + side))
        if el is None:
            el = OxmlElement("w:" + side)
            mar.append(el)
        el.set(qn("w:w"), str(int(round(inches * 1440))))
        el.set(qn("w:type"), "dxa")


def _write_cell(cell, text, bold=False, align=None):
    for p in cell.paragraphs[1:]:
        p._element.getparent().remove(p._element)
    p = cell.paragraphs[0]
    for r in list(p.runs):
        r._element.getparent().remove(r._element)
    pf = p.paragraph_format
    pf.space_before = Pt(1)
    pf.space_after = Pt(1)
    pf.line_spacing = 1.0
    if align is not None:
        p.alignment = align
    run = p.add_run()
    run.bold = bold
    run.font.size = Pt(BODY_FS)
    run.font.name = dh.FONT_NAME
    for k, line in enumerate(text.split("\n")):
        if k:
            run._element.append(OxmlElement("w:br"))
        t = OxmlElement("w:t")
        t.set(qn("xml:space"), "preserve")
        t.text = line
        run._element.append(t)
    cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER


def build_rows():
    """Return the nine body rows as lists of eight strings. Split out from
    build() so the test suite can check the values without a Document."""
    crude = _load("Table_1_raw_rates.csv")
    body_rows = []
    for (label, crude_key, adj_csv, stem, boot_csv, boot_key) in OUTCOMES:
        adj = _load(adj_csv)
        boot = _load(boot_csv)
        for cat in CATEGORIES:
            c = _crude_lookup(crude, crude_key, cat)
            a = _row_lookup(adj, cat)
            body_rows.append([
                label,
                dh.cat_label(cat),
                _stacked(c["rr_ct"],  c["rr_ct_lo"],  c["rr_ct_hi"]),
                _stacked(c["rr_esi"], c["rr_esi_lo"], c["rr_esi_hi"]),
                _crude_p(c),
                _stacked(a[f"bhatt_{stem}"], a["bhatt_LCI"], a["bhatt_UCI"]),
                _stacked(a[f"esi_{stem}"],   a["esi_LCI"],   a["esi_UCI"]),
                _adjusted_p(boot, boot_key, cat),
            ])
    return body_rows


HEADERS = ["Outcome (metric)", "Category",
           "Crude RR (CT)", "Crude RR (ESI)", "p-value",
           "Adjusted RR (CT)", "Adjusted RR (ESI)", "p-value"]


def build(doc):
    body_rows = build_rows()
    assert abs(sum(COL_WIDTHS) - dh.CONTENT_WIDTH_IN) < 1e-9, sum(COL_WIDTHS)

    # add_table sets the widths, the tblGrid and the fixed layout; the cells
    # are then rewritten here so the stacked runs and the 9 pt body apply.
    tbl = dh.add_table(doc, HEADERS, body_rows, col_widths_in=COL_WIDTHS,
                       body_fs=BODY_FS, header_fs=BODY_FS)
    _set_cell_margins(tbl, PAD_IN)

    CENTER = WD_ALIGN_PARAGRAPH.CENTER
    for j, h in enumerate(HEADERS):
        _write_cell(tbl.rows[0].cells[j], h, bold=True,
                    align=CENTER if j >= 2 else None)
    for i, row_data in enumerate(body_rows, start=1):
        for j, val in enumerate(row_data):
            _write_cell(tbl.rows[i].cells[j], val,
                        align=CENTER if j >= 2 else None)

    # Each outcome heading spans its three category rows.
    dh.vmerge_col(tbl, col_idx=0, header_rows=1)

    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    return tbl
