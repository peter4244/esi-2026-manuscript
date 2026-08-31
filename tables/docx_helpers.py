"""Shared docx-table helpers for the ESI manuscript v10.2 rebuild.

Consolidates font constants, table construction, borders, vertical merging,
TOC anchoring, and hyperlinks so v10.2 and any future revision reuse the
identical style. See v10_2_supplement_restructure_plan_2026.7.19.md.

Font hierarchy (post header-bump):
  BODY_FS         = 11  # main body prose
  TABLE_HEADER_FS = 11  # bold header row inside tables
  TABLE_BODY_FS   = 10
  CAPTION_NOTE_FS = 9   # small gray caption notes
"""
from docx.shared import Pt, Inches, RGBColor
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph

# ---- Single source of truth for text styles -------------------------------
FONT_NAME       = "Arial"
BODY_FS         = 11
TABLE_HEADER_FS = 11  # bumped from 10 pt per plan-agent should-fix (approved)
TABLE_BODY_FS   = 10
CAPTION_NOTE_FS = 9
CONTENT_WIDTH_IN = 6.5  # US Letter, 1 in margins

# ---- Border ---------------------------------------------------------------

def set_cell_border(cell, top=True, bottom=True, left=True, right=True):
    tc_pr = cell._tc.get_or_add_tcPr()
    # Remove any pre-existing tcBorders so we're the sole authority
    for e in tc_pr.findall(qn("w:tcBorders")):
        tc_pr.remove(e)
    tc_borders = OxmlElement("w:tcBorders")
    edges = {"top": top, "left": left, "bottom": bottom, "right": right}
    for edge, on in edges.items():
        b = OxmlElement(f"w:{edge}")
        if on:
            b.set(qn("w:val"), "single")
            b.set(qn("w:sz"), "6")
            b.set(qn("w:color"), "000000")
        else:
            b.set(qn("w:val"), "nil")
        tc_borders.append(b)
    tc_pr.append(tc_borders)


def strip_horizontal_border_inside_vmerge(anchor_cell, continuation_cells, last_cell):
    """After vmerge, hide horizontal lines *inside* the merged span.
    - anchor keeps its top border.
    - continuations have top and bottom hidden.
    - last (final continuation) keeps its bottom border.
    """
    set_cell_border(anchor_cell, top=True, bottom=False, left=True, right=True)
    for c in continuation_cells:
        set_cell_border(c, top=False, bottom=False, left=True, right=True)
    set_cell_border(last_cell, top=False, bottom=True, left=True, right=True)


# ---- Vertical merge via raw XML (plan-agent-recommended idiom) ------------

def _set_vmerge(cell, val):
    tc_pr = cell._tc.get_or_add_tcPr()
    for e in tc_pr.findall(qn("w:vMerge")):
        tc_pr.remove(e)
    m = OxmlElement("w:vMerge")
    if val is not None:
        m.set(qn("w:val"), val)
    tc_pr.append(m)


def _clear_cell_text(cell):
    for p in cell.paragraphs:
        for r in p.runs:
            r.text = ""


def vmerge_col(tbl, col_idx, header_rows=1):
    """Vertically merge consecutive cells in `col_idx` with identical text.
    Uses raw `w:vMerge` so text stays only in the anchor and borders behave.
    Also strips horizontal borders inside the merged span so Word does not
    render an interior line.
    """
    rows = list(tbl.rows)
    i = header_rows
    while i < len(rows):
        anchor_txt = rows[i].cells[col_idx].text
        j = i + 1
        while j < len(rows) and rows[j].cells[col_idx].text == anchor_txt:
            j += 1
        if j > i + 1:
            _set_vmerge(rows[i].cells[col_idx], "restart")
            continuations = []
            for k in range(i + 1, j):
                cell = rows[k].cells[col_idx]
                _set_vmerge(cell, None)
                _clear_cell_text(cell)
                continuations.append(cell)
            strip_horizontal_border_inside_vmerge(
                anchor_cell=rows[i].cells[col_idx],
                continuation_cells=continuations[:-1],
                last_cell=continuations[-1] if continuations else rows[i].cells[col_idx],
            )
        i = j


# ---- Table construction ---------------------------------------------------

# Canonical display labels for the MD-COPD diagnostic categories.
#
# The analysis writes "COPD-minor" / "COPD-major" as factor levels and every
# artifact carries those strings; this maps them to what the paper prints. On
# co-author review the earlier labels were judged to imply that COPD itself can
# be major or minor, rather than naming the diagnostic pathway.
#
# Renaming at display time keeps one vocabulary in the artifacts, so the
# verification registry keeps matching on the values it always matched on.
# Four modules previously carried their own identity copy of this map; they now
# share this one, so a future change cannot land in three places out of four.
CATEGORY_DISPLAY = {
    "noCOPD":          "noCOPD",
    "AFL-only-NoCOPD": "AFL-only-noCOPD",
    "AFL-only-noCOPD": "AFL-only-noCOPD",
    "COPD-minor":      "COPD minor pathway",
    "COPD-major":      "COPD major pathway",
}


def cat_label(x):
    """Display label for a diagnostic category; unknown values pass through."""
    return CATEGORY_DISPLAY.get(x, x)


def _keep_block_together(tbl):
    """Stop a supplemental table and its legend straddling a page boundary.

    Three separate Word behaviours have to be set; leaving any one of them out
    still lets the block split:
      * cantSplit on every row -- a single row never breaks across pages;
      * tblHeader on the header row -- if a table is genuinely taller than a
        page, the header repeats rather than leaving orphaned numbers;
      * keepNext on every cell paragraph -- rows stay with the following row,
        and the last row stays with the legend paragraph beneath it, so Word
        moves the whole table-plus-legend unit to the next page rather than
        breaking it.
    """
    for i, row in enumerate(tbl.rows):
        trPr = row._tr.get_or_add_trPr()
        cant = OxmlElement("w:cantSplit"); trPr.append(cant)
        if i == 0:
            hdr = OxmlElement("w:tblHeader"); trPr.append(hdr)
        for cell in row.cells:
            for para in cell.paragraphs:
                para.paragraph_format.keep_with_next = True


def add_table(doc, headers, rows, col_widths_in=None,
              body_fs=None, header_fs=None, max_width_in=None):
    """Create a bordered table with a bold header row + Arial body.
    Optionally set explicit column widths (list of inches summing to
    ≤ max_width_in, default CONTENT_WIDTH_IN = 6.5 for portrait; pass
    max_width_in=LANDSCAPE_CONTENT_WIDTH_IN when in a landscape section).
    body_fs / header_fs override the module defaults for a single table (use
    when a table's content is unusually dense — see S2 baseline)."""
    body_fs = body_fs if body_fs is not None else TABLE_BODY_FS
    header_fs = header_fs if header_fs is not None else TABLE_HEADER_FS
    max_w = max_width_in if max_width_in is not None else CONTENT_WIDTH_IN
    tbl = doc.add_table(rows=1 + len(rows), cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    try:
        tbl.style = "Table Grid"
    except KeyError:
        pass

    if col_widths_in:
        assert sum(col_widths_in) <= max_w + 0.01, \
            f"column widths sum {sum(col_widths_in)}\" > content width {max_w}\""
        for row in tbl.rows:
            for j, w in enumerate(col_widths_in):
                row.cells[j].width = Inches(w)
        # Also update the tblGrid gridCol widths — LibreOffice (and some
        # newer Word versions) honor tblGrid over per-cell width. Without
        # this, all columns render at the default equal width regardless
        # of what we asked for. Widths in tblGrid are in twips (1/1440 in).
        tblGrid = tbl._element.find(qn("w:tblGrid"))
        if tblGrid is not None:
            existing = tblGrid.findall(qn("w:gridCol"))
            for gc, w in zip(existing, col_widths_in):
                gc.set(qn("w:w"), str(int(round(w * 1440))))
                gc.set(qn("w:type"), "dxa")
        # Also disable "Automatically resize to fit contents" so the
        # widths we set actually stick when Word re-lays out the table.
        tblPr = tbl._element.find(qn("w:tblPr"))
        if tblPr is not None:
            tblLayout = tblPr.find(qn("w:tblLayout"))
            if tblLayout is None:
                tblLayout = OxmlElement("w:tblLayout")
                tblPr.append(tblLayout)
            tblLayout.set(qn("w:type"), "fixed")

    # Header
    for j, h in enumerate(headers):
        cell = tbl.rows[0].cells[j]
        cell.text = ""
        r = cell.paragraphs[0].add_run(h)
        r.bold = True
        r.font.size = Pt(header_fs)
        r.font.name = FONT_NAME
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_border(cell)

    # Body
    for i, row_data in enumerate(rows, start=1):
        for j, val in enumerate(row_data):
            cell = tbl.rows[i].cells[j]
            cell.text = ""
            r = cell.paragraphs[0].add_run(str(val))
            r.font.size = Pt(body_fs)
            r.font.name = FONT_NAME
            set_cell_border(cell)

    _keep_block_together(tbl)
    return tbl


# ---- Landscape/portrait section helpers -----------------------------------

def begin_landscape(doc):
    """Insert a section break and switch the following content to landscape
    US-Letter (11" wide × 8.5" tall). Returns the new section object.

    Use for wide tables (e.g. S2 baseline) that don't fit in portrait 6.5".
    Pair with `end_landscape(doc)` after the wide content.

    Idempotent: if the current section is already landscape, does nothing —
    prevents redundant new-page section breaks when back-to-back tables both
    call begin_landscape (which would otherwise leave a blank portrait page
    between them from the intervening end_landscape)."""
    if doc.sections and doc.sections[-1].orientation == WD_ORIENT.LANDSCAPE:
        return doc.sections[-1]
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    section.orientation = WD_ORIENT.LANDSCAPE
    section.page_width = Inches(11)
    section.page_height = Inches(8.5)
    # Narrower left/right margins in landscape than in portrait — landscape
    # is used only for wide tables (ST1, ST2), so pushing text closer to
    # the page edge is fine and gains 1.30" of usable content width for
    # multi-column tables.
    section.left_margin = Inches(0.35)
    section.right_margin = Inches(0.35)
    return section


def end_landscape(doc):
    """Insert a section break and revert to portrait US-Letter (8.5" × 11").
    Idempotent — see begin_landscape."""
    if doc.sections and doc.sections[-1].orientation == WD_ORIENT.PORTRAIT:
        return doc.sections[-1]
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    section.orientation = WD_ORIENT.PORTRAIT
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    return section


LANDSCAPE_CONTENT_WIDTH_IN = 10.30  # 11" page − 0.35" margins each side


# ---- Body helpers ---------------------------------------------------------

def body(doc, text, indent=True):
    p = doc.add_paragraph()
    if indent:
        p.paragraph_format.first_line_indent = Inches(0.25)
    r = p.add_run(text)
    r.font.size = Pt(BODY_FS)
    r.font.name = FONT_NAME
    return p


def caption(doc, text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.bold = True
    r.font.size = Pt(TABLE_BODY_FS)
    r.font.name = FONT_NAME
    return p


def caption_note(doc, text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.size = Pt(CAPTION_NOTE_FS)
    r.font.name = FONT_NAME
    r.font.color.rgb = RGBColor(60, 60, 60)
    return p


def H1(doc, text, bookmark_id=None):
    p = doc.add_paragraph(text, style="Heading 1")
    if bookmark_id is not None:
        add_bookmark(p, bookmark_id)
    return p


def H2(doc, text): return doc.add_paragraph(text, style="Heading 2")


# ---- Bookmarks and internal hyperlinks (TOC navigation) -------------------

_bookmark_counter = [0]


def add_bookmark(paragraph, bookmark_name):
    """Wrap the paragraph's content in <w:bookmarkStart>/<w:bookmarkEnd> so
    the name can be the target of an internal hyperlink."""
    _bookmark_counter[0] += 1
    bmk_id = str(_bookmark_counter[0])
    p_el = paragraph._p

    start = OxmlElement("w:bookmarkStart")
    start.set(qn("w:id"), bmk_id)
    start.set(qn("w:name"), bookmark_name)
    p_el.insert(0, start)

    end = OxmlElement("w:bookmarkEnd")
    end.set(qn("w:id"), bmk_id)
    p_el.append(end)


def add_internal_hyperlink(paragraph, anchor_name, text, bold=False):
    """Append an internal hyperlink run to the paragraph."""
    hyperlink = OxmlElement("w:hyperlink")
    hyperlink.set(qn("w:anchor"), anchor_name)

    r = OxmlElement("w:r")
    rPr = OxmlElement("w:rPr")
    rFonts = OxmlElement("w:rFonts")
    for k in ("w:ascii", "w:hAnsi", "w:cs"):
        rFonts.set(qn(k), FONT_NAME)
    rPr.append(rFonts)
    sz = OxmlElement("w:sz"); sz.set(qn("w:val"), str(BODY_FS * 2))
    rPr.append(sz)
    if bold:
        b = OxmlElement("w:b"); rPr.append(b)
    color = OxmlElement("w:color"); color.set(qn("w:val"), "0563C1")  # Word default blue
    rPr.append(color)
    u = OxmlElement("w:u"); u.set(qn("w:val"), "single")
    rPr.append(u)
    r.append(rPr)

    t = OxmlElement("w:t")
    t.text = text
    t.set(qn("xml:space"), "preserve")
    r.append(t)
    hyperlink.append(r)

    paragraph._p.append(hyperlink)


def body_toc(doc, entries):
    """Render a body-text TOC.
    `entries` is a list of dicts: {"num": "S3a", "title": "Sensitivity — ESI=10 excluded", "anchor": "tbl_S3a"}

    The table-number column ("S1", "S2", ...) carries the reading order; no
    separate leading "1. 2. 3." integer is emitted (supp review §8).
    """
    heading_para = doc.add_paragraph()
    r = heading_para.add_run("Table of Contents")
    r.bold = True
    r.font.size = Pt(BODY_FS + 1)
    r.font.name = FONT_NAME
    heading_para.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER

    for entry in entries:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Inches(0.5)
        # Compact "STN" label for the TOC (e.g. "S3" → "ST3"); leaves the
        # long form "Supplemental Table N" for prose and legend usage.
        num = entry['num']
        if num.startswith("S") and not num.startswith("ST"):
            num_display = f"ST{num[1:]}"
        else:
            num_display = num
        # Table-number column — bold, right-padded to a stable width so
        # titles line up.
        r1 = p.add_run(f"{num_display:>5}  |  ")
        r1.font.size = Pt(BODY_FS); r1.font.name = FONT_NAME; r1.bold = True
        # Title as an internal hyperlink
        add_internal_hyperlink(p, entry["anchor"], entry["title"])

    doc.add_paragraph("")


# ---- Composite: render one supplement table block -------------------------

def render_supp_table(doc, table_num, title, body_text, headers, rows,
                      caption_note_text=None, col_widths_in=None,
                      vmerge_cols=None):
    """One-call helper: heading (with bookmark) → body prose → table →
    caption note → spacer. Optional vmerge_cols is an iterable of column
    indices to vertically merge post-population.
    """
    bookmark = f"tbl_{table_num.replace('.', '_')}"
    H1(doc, f"Supplemental Table {table_num} — {title}", bookmark_id=bookmark)
    body(doc, body_text, indent=False)
    tbl = add_table(doc, headers, rows, col_widths_in=col_widths_in)
    if vmerge_cols:
        for col in vmerge_cols:
            vmerge_col(tbl, col)
    if caption_note_text:
        caption_note(doc, caption_note_text)
    doc.add_paragraph("")
    return tbl


# ============================================================================
# v9 rebuild — new primitives (add_legend, resolve_markers, render_markdown_to_docx)
# ============================================================================
import re
import importlib

# ---- add_legend: unified caption for both tables and figures --------------

def format_label(table_num):
    """Turn a bare token into a display label.
    '1' or '2'   → 'Table 1' / 'Table 2'
    'S3'         → 'Supplemental Table S3'
    'S6a.1'      → 'Supplemental Table S6a.1'
    'F1'         → 'Figure 1'
    """
    if table_num.startswith("F"):
        return f"Figure {table_num[1:]}"
    if table_num.startswith("S"):
        # Long form drops the "S" prefix ("S6" → "Supplemental Table 6");
        # the compact form ("ST6") is emitted only by the section-style
        # legend prefix below.
        return f"Supplemental Table {table_num[1:]}"
    return f"Table {table_num}"


def add_legend(doc, legend_body, table_or_fig_num, title=None, abbreviations=None,
               bookmark_id=None, style="caption"):
    """Emit a legend combining title, body, and (optionally) an Abbreviations
    block.

    style="caption" (default) — single paragraph beginning with a bold
        "Table N|Figure N. <title>." prefix, followed by legend body and
        (optionally) Abbreviations. Used for main-manuscript tables/figures
        where the caption prefix is the only place the title appears.

    style="section" — the legend is emitted as a distinct section below the
        artifact: an empty spacer paragraph, then a bold "Legend." prefix,
        then the legend body, then (optionally) Abbreviations. Used for
        supplement tables/figures where an H1 heading above the artifact
        already carries the number + title so no bold caption is needed.
    """
    if style not in ("caption", "section"):
        raise ValueError(f"add_legend style must be 'caption' or 'section', got {style!r}")

    if style == "section":
        # Blank spacer so the legend reads as an independent block, not a
        # subscript of the table/figure above.
        _spacer = doc.add_paragraph("")
        # The spacer sits between the table and its legend. Without keepNext
        # here the chain set on the table's last row ends at this empty
        # paragraph, and the legend is free to fall onto the next page while
        # the table stays behind (ST17 did exactly that).
        _spacer.paragraph_format.keep_with_next = True

    p = doc.add_paragraph()
    if bookmark_id is not None:
        add_bookmark(p, bookmark_id)

    if style == "caption":
        label = format_label(table_or_fig_num)
        prefix = f"{label}." if title is None else f"{label}. {title}."
        r_bold = p.add_run(prefix + " ")
    else:  # section
        # Compact form "STN. Title." for supp tables ("S1" → "ST1"; "F1"
        # would map to "SF1" but figures rarely use section style here).
        # The supp artifact no longer has an H1 heading above it; the legend
        # itself carries the table number + title.
        if table_or_fig_num.startswith("S"):
            compact = f"ST{table_or_fig_num[1:]}"
        elif table_or_fig_num.startswith("F"):
            compact = f"F{table_or_fig_num[1:]}"
        else:
            compact = table_or_fig_num
        prefix = (f"{compact}." if title is None
                  else f"{compact}. {title}.")
        r_bold = p.add_run(prefix + " ")
    r_bold.bold = True
    r_bold.font.name = FONT_NAME
    r_bold.font.size = Pt(TABLE_BODY_FS)

    # Strip leading whitespace so we don't get double-spacing between the
    # bold prefix and the legend body (Phase G #9).
    r_body = p.add_run(legend_body.lstrip())
    r_body.font.name = FONT_NAME
    r_body.font.size = Pt(TABLE_BODY_FS)

    if abbreviations:
        if isinstance(abbreviations, dict):
            abbr_pairs = [f"{k}, {v}" for k, v in abbreviations.items()]
        else:  # list of (abbr, expansion) tuples or preformatted strings
            abbr_pairs = []
            for item in abbreviations:
                if isinstance(item, (tuple, list)):
                    abbr_pairs.append(f"{item[0]}, {item[1]}")
                else:
                    abbr_pairs.append(str(item))
        abbr_str = "; ".join(abbr_pairs) + "."
        # Leading space if legend_body did not end in whitespace
        sep = "" if legend_body.endswith((" ", "\n", "\t")) else " "
        r_abb_prefix = p.add_run(f"{sep}Abbreviations: ")
        r_abb_prefix.italic = True
        r_abb_prefix.font.name = FONT_NAME
        r_abb_prefix.font.size = Pt(TABLE_BODY_FS)
        r_abb = p.add_run(abbr_str)
        r_abb.font.name = FONT_NAME
        r_abb.font.size = Pt(TABLE_BODY_FS)

    # A legend is one paragraph, so keeping its lines together is enough to
    # stop it straddling a page. Combined with keepNext on the table above,
    # the table and its legend move to the next page as a unit.
    p.paragraph_format.keep_together = True
    return p


# ---- Marker resolution ---------------------------------------------------
#
# Grammar (see v9_rebuild_plan_v2 §"Marker grammar"):
#   {{TABLE:N}}           → hyperlinked "Table N"
#   {{FIGURE:N}}          → hyperlinked "Figure N"
#   {{REF:Sn}}            → hyperlinked "Supplemental Table Sn"
#   {{REFS:Sa,Sb,Sc}}     → "Supplemental Tables Sa, Sb, and Sc" (Oxford)
#   {{INSERT:tableN}}     → deferred to callback (table.build(doc))
#   {{INSERT:figureN}}    → deferred to callback (image embed)
#
# Escaping: `\{{` → literal `{{`; `\}}` → literal `}}`.
# Skipping: inside triple-backtick fenced code blocks, markers pass through.
# Errors: unknown marker names (e.g., {{FOO:1}}) raise ValueError.

_MARKER_PAT = re.compile(
    r"(?<!\\)\{\{"
    r"(TABLE|FIGURE|REF|REFS|INSERT):"
    r"([^{}\n]+?)"
    r"\}\}"
)
_CODE_FENCE_PAT = re.compile(r"```.*?```", re.DOTALL)


def _protect_code_fences(md_text):
    """Replace fenced code blocks with placeholders; return (protected, mapping)."""
    placeholders = {}
    def _sub(m):
        key = f"@@CODEFENCE{len(placeholders)}@@"
        placeholders[key] = m.group(0)
        return key
    return _CODE_FENCE_PAT.sub(_sub, md_text), placeholders


def _restore_code_fences(md_text, placeholders):
    for k, v in placeholders.items():
        md_text = md_text.replace(k, v)
    return md_text


def _validate_no_marker_in_link_targets(md_text):
    """Prohibit markers inside markdown link targets: [text]({{REF:S3}}).
    Errors on any such usage.
    """
    for m in re.finditer(r"\]\(([^)]*?)\)", md_text):
        target = m.group(1)
        if "{{" in target and "}}" in target:
            raise ValueError(
                f"Marker inside markdown link target is prohibited: "
                f"{m.group(0)!r}. Use a bare marker instead."
            )


def _resolve_one(kind, arg, insertion_registry):
    """Resolve a single marker to (plain-text, optional-hyperlink-anchor,
    optional-insertion-key)."""
    if kind == "TABLE":
        return (format_label(arg), f"tbl_{arg}", None)
    if kind == "FIGURE":
        return (format_label(f"F{arg}"), f"fig_{arg}", None)
    if kind == "REF":
        return (format_label(arg), f"tbl_{arg.replace('.', '_')}", None)
    if kind == "REFS":
        tokens = [t.strip() for t in arg.split(",")]
        if len(tokens) == 1:
            return (format_label(tokens[0]), f"tbl_{tokens[0].replace('.', '_')}", None)
        # Oxford join: "Supplemental Tables A, B, and C"
        if len(tokens) == 2:
            joined = f"{tokens[0]} and {tokens[1]}"
        else:
            joined = ", ".join(tokens[:-1]) + f", and {tokens[-1]}"
        return (f"Supplemental Tables {joined}", None, None)
    if kind == "INSERT":
        if arg not in insertion_registry:
            raise ValueError(f"{{{{INSERT:{arg}}}}} references unknown artifact.")
        return (None, None, arg)
    raise ValueError(f"Unknown marker kind: {kind}")


def resolve_markers(md_text, insertion_registry):
    """Substitute markers in `md_text`.

    Returns (resolved_text, insertion_sequence).
      - resolved_text: markdown with TABLE/FIGURE/REF/REFS replaced with plain
        text (hyperlinks are lost at this stage — the MD walker later re-adds
        them by inspecting the running text).
      - insertion_sequence: list of (position_marker, insertion_key), where
        position_marker is a synthetic string that appears in resolved_text
        exactly where the {{INSERT:*}} was, so the walker can split the text
        on it and call the artifact's build() at that point.

    Errors on unknown markers, malformed markers, markers inside link targets,
    and unresolved {{...}} tokens that survive parsing.
    """
    _validate_no_marker_in_link_targets(md_text)

    # 1) Protect fenced code blocks so markers inside them pass through.
    protected, fences = _protect_code_fences(md_text)

    # 2) Protect ESCAPED braces so they don't participate in marker matching
    #    OR survivor-check. `\{{` → @@ESCLBRACE@@; `\}}` → @@ESCRBRACE@@.
    ESC_L, ESC_R = "@@ESCLBRACE@@", "@@ESCRBRACE@@"
    protected = protected.replace(r"\{{", ESC_L).replace(r"\}}", ESC_R)

    # 3) Iteratively resolve — the substitution can shift positions but is
    #    single-pass because our regex has no self-embedding.
    insertions = []
    def _sub(m):
        kind, arg = m.group(1), m.group(2)
        text, anchor, insertion_key = _resolve_one(kind, arg, insertion_registry)
        if insertion_key is not None:
            token = f"@@INSERT_{len(insertions)}_{insertion_key}@@"
            insertions.append((token, insertion_key))
            return token
        return text
    resolved = _MARKER_PAT.sub(_sub, protected)

    # 4) Guard: any surviving {{...}} that looks like a marker means an unknown
    #    marker slipped past our regex. Fail loud.  (Runs BEFORE we restore
    #    escaped braces, so real escapes don't trigger a false positive.)
    survivors = re.findall(r"\{\{[^}]*\}\}", resolved)
    if survivors:
        raise ValueError(
            f"Unresolved markers survived parsing (typos or unknown grammar): "
            f"{survivors!r}"
        )

    # 5) Restore escaped braces to their literal forms.
    resolved = resolved.replace(ESC_L, "{{").replace(ESC_R, "}}")

    # 6) Restore code fences.
    resolved = _restore_code_fences(resolved, fences)

    return resolved, insertions


# ---- Markdown → docx walker (hand-rolled via markdown-it-py) -------------

def render_markdown_to_docx(doc, md_text, insertion_callbacks=None):
    """Render standard markdown into `doc` as python-docx paragraphs.

    insertion_callbacks: dict {insertion_key: callable(doc)} — called when an
    "@@INSERT_..._<key>@@" token is encountered, in the position of that token.

    Supports: paragraphs, ## and ### headings, **bold**, *italic*, single-level
    lists (- or 1.), inline `code`, unicode.
    Explicitly rejects: nested lists, tables, images, fenced code, blockquotes,
    footnotes. If a manuscript section needs any of these, move it to prose_py/.
    """
    from markdown_it import MarkdownIt
    md = MarkdownIt("commonmark", {"breaks": False, "html": False})
    tokens = md.parse(md_text)

    insertion_callbacks = insertion_callbacks or {}
    INSERT_TOKEN_PAT = re.compile(r"@@INSERT_(\d+)_([A-Za-z0-9_.-]+)@@")

    i = 0
    n = len(tokens)
    while i < n:
        tok = tokens[i]
        ttype = tok.type

        if ttype == "heading_open":
            level = int(tok.tag[1])
            style = f"Heading {min(level, 3)}"
            # Next token is the inline content, then heading_close
            inline = tokens[i + 1]
            p = doc.add_paragraph(style=style)
            _emit_inline(p, inline.children or [], insertion_callbacks, doc,
                         INSERT_TOKEN_PAT)
            i += 3

        elif ttype == "paragraph_open":
            inline = tokens[i + 1]
            # Detect single-INSERT paragraphs: prose that is just `{{INSERT:x}}`
            # on its own line. Skip the wrapper paragraph so we don't emit an
            # empty paragraph above the inserted artifact (Phase G review #8).
            inline_children = inline.children or []
            single_insert_key = _single_insert_key(inline_children, INSERT_TOKEN_PAT)
            if single_insert_key is not None:
                cb = insertion_callbacks.get(single_insert_key)
                if cb is None:
                    # Missing callback — fail loud. The section-level try/except
                    # in build_manuscript / build_supplement catches this and
                    # emits its own red-flag paragraph while marking the section
                    # FAIL, so the build_log is honest (Phase K review §5).
                    raise ValueError(
                        f"prose {{{{INSERT:{single_insert_key}}}}} has no "
                        f"registered callback; check manifest.INSERT_KEYS and "
                        f"the make_*_callback wiring in the orchestrator."
                    )
                cb(doc)
                i += 3
                continue
            # Normal paragraph — no blanket first-line-indent (callers set it
            # explicitly for body-prose sections if desired; Phase G review #7).
            p = doc.add_paragraph()
            _emit_inline(p, inline_children, insertion_callbacks, doc,
                         INSERT_TOKEN_PAT)
            i += 3

        elif ttype == "bullet_list_open" or ttype == "ordered_list_open":
            list_style = "List Bullet" if ttype == "bullet_list_open" else "List Number"
            # Consume list_items until close
            i += 1
            while i < n and tokens[i].type not in ("bullet_list_close",
                                                    "ordered_list_close"):
                if tokens[i].type == "list_item_open":
                    # find the inline within the list item
                    j = i + 1
                    while j < n and tokens[j].type != "list_item_close":
                        if tokens[j].type == "paragraph_open":
                            inline = tokens[j + 1]
                            p = doc.add_paragraph(style=list_style)
                            _emit_inline(p, inline.children or [],
                                         insertion_callbacks, doc, INSERT_TOKEN_PAT)
                            j += 3
                        elif tokens[j].type in ("bullet_list_open",
                                                "ordered_list_open"):
                            raise ValueError(
                                "Nested lists not supported; move this section "
                                "to prose_py/."
                            )
                        else:
                            j += 1
                    i = j + 1
                else:
                    i += 1
            i += 1

        elif ttype in ("blockquote_open", "table_open", "fence", "image",
                       "footnote_open"):
            raise ValueError(
                f"Markdown feature '{ttype}' is not supported by "
                f"render_markdown_to_docx. Move this section to prose_py/."
            )

        else:
            i += 1


def _single_insert_key(inline_tokens, insert_token_pat):
    """If the inline children contain exactly one text token whose entire
    trimmed content is a single `@@INSERT_..._<key>@@`, return the key.
    Otherwise return None.
    """
    if len(inline_tokens) != 1:
        return None
    tok = inline_tokens[0]
    if tok.type != "text":
        return None
    m = insert_token_pat.fullmatch(tok.content.strip())
    if m is None:
        return None
    return m.group(2)


def _emit_inline(paragraph, inline_tokens, insertion_callbacks, doc,
                 insert_token_pat):
    """Emit runs into `paragraph` from a flat list of inline tokens.

    Handles @@INSERT_..._<key>@@ tokens inside text runs by ending the
    current paragraph, calling the callback, and starting a new paragraph.
    Every emission uses `current_par` (which advances after each INSERT) so
    subsequent bold/italic/code/softbreak tokens land AFTER the inserted
    artifact, not back in the pre-INSERT paragraph (Phase G checkpoint #1).
    """
    bold = False
    italic = False
    current_par = paragraph
    for tok in inline_tokens:
        if tok.type == "text":
            current_par = _emit_text_with_inserts(
                current_par, tok.content, bold, italic,
                insertion_callbacks, doc, insert_token_pat)
        elif tok.type == "strong_open":
            bold = True
        elif tok.type == "strong_close":
            bold = False
        elif tok.type == "em_open":
            italic = True
        elif tok.type == "em_close":
            italic = False
        elif tok.type == "softbreak" or tok.type == "hardbreak":
            r = current_par.add_run(" ")
            r.font.name = FONT_NAME
            r.font.size = Pt(BODY_FS)
        elif tok.type == "code_inline":
            r = current_par.add_run(tok.content)
            r.font.name = "Courier New"
            r.font.size = Pt(BODY_FS)
        elif tok.type == "link_open":
            # External markdown links are not supported by this walker
            # (finding 4 from the Phase G review). Internal cross-references
            # go through the marker resolver instead. If a manuscript section
            # genuinely needs an external URL, move that section to prose_py/.
            raise ValueError(
                "External markdown links [text](url) are not supported by "
                "render_markdown_to_docx. Move this section to prose_py/ or "
                "remove the link."
            )
        elif tok.type == "link_close":
            pass
        else:
            # Unrecognized token — skip silently rather than fail; guard against
            # markdown-it emitting stray inline tokens we don't model.
            pass


def _emit_text_with_inserts(paragraph, text, bold, italic, insertion_callbacks,
                            doc, insert_token_pat):
    """Split `text` on @@INSERT_..._<key>@@ tokens.

    The tricky case is inline INSERT — `See {{INSERT:figure1}} which shows...`.
    After the callback runs, `which shows...` must appear AFTER the inserted
    artifact, not tacked back onto the current paragraph before it. Solution:
    when we hit a callback in the middle of a paragraph and there is a tail,
    open a fresh paragraph for the tail with the same first-line-indent
    behavior (none — indent is set by the caller if needed).

    Returns the paragraph that any subsequent inline tokens should be emitted
    into (either the original `paragraph`, or a newly-created tail paragraph).
    """
    doc_part = paragraph._parent  # the Document

    def _run(par, txt, is_bold, is_italic, is_red=False):
        r = par.add_run(txt)
        r.font.name = FONT_NAME
        r.font.size = Pt(BODY_FS)
        r.bold = is_bold
        r.italic = is_italic
        if is_red:
            r.font.color.rgb = RGBColor(0xC0, 0x00, 0x00)

    current_par = paragraph
    pos = 0
    matches = list(insert_token_pat.finditer(text))
    for m in matches:
        before = text[pos:m.start()]
        if before:
            _run(current_par, before, bold, italic)
        key = m.group(2)
        cb = insertion_callbacks.get(key)
        if cb is None:
            raise ValueError(
                f"prose {{{{INSERT:{key}}}}} has no registered callback; "
                f"check manifest.INSERT_KEYS and the make_*_callback wiring "
                f"in the orchestrator."
            )
        cb(doc_part)
        pos = m.end()
        # After a callback, ALWAYS open a fresh paragraph — even if the
        # remainder of THIS text token is empty. Later inline tokens (bold,
        # italic, code, softbreak) from _emit_inline must land in the fresh
        # paragraph, not back in the pre-INSERT paragraph. Phase G checkpoint #1.
        current_par = doc_part.add_paragraph()
    tail = text[pos:]
    if tail:
        _run(current_par, tail, bold, italic)
    return current_par


# ---- Build helpers used by orchestrators ---------------------------------

def render_prose_section(doc, section_source, insertion_registry,
                          insertion_callbacks):
    """Render a single prose section. `section_source` is either a
    'prose_py.<module>' import path or a 'prose/<name>.md' relative path.
    """
    if section_source.startswith("prose_py."):
        mod = importlib.import_module(section_source)
        mod.build(doc)
    elif section_source.endswith(".md"):
        import os
        with open(os.path.join(os.path.dirname(os.path.dirname(__file__)),
                               section_source)) as f:
            md_text = f.read()
        resolved, _insertions = resolve_markers(md_text, insertion_registry)
        render_markdown_to_docx(doc, resolved, insertion_callbacks=insertion_callbacks)
    else:
        raise ValueError(f"Unknown prose source: {section_source}")


def build_supp_toc(doc, entries):
    """First-pass TOC generator for the supplement — uses body_toc()."""
    body_toc(doc, entries)


def bookmark_for(table_num):
    """Return the canonical bookmark name for a given TABLE_NUM.
    Every per-table module's build(doc) MUST call add_legend_from_sibling()
    (which anchors the bookmark), or if it emits its legend directly then it
    must call add_bookmark(paragraph, bookmark_for(TABLE_NUM)) on the legend
    paragraph so that {{TABLE:1}} / {{REF:S3}} internal hyperlinks target it.

    'S6a.1' → 'tbl_S6a_1' (dots become underscores because Word bookmarks
    do not permit '.').
    """
    return f"tbl_{table_num.replace('.', '_')}"


def add_legend_from_sibling(doc, module_file, table_num):
    """Convenience wrapper for per-table modules (Phase G checkpoint #7).
    Reads <module_dir>/<module_basename>_legend.md, parses it, and calls
    add_legend() with a bookmark set to bookmark_for(table_num).

    Rendering style is chosen from `table_num`:
      * Supplementary artifacts (table_num starts with 'S' or 'F' where
        the artifact was placed under its own H1 heading — currently every
        supp table) render with style="section" so the legend reads as a
        distinct block below the table, not a bold caption subscript.
      * Main-manuscript artifacts (table_num like '1', '2', or 'F1'/'F2'
        embedded via {{INSERT:...}} without a preceding H1 title) render
        with style="caption" so the bold "Table N. Title." run is the
        artifact's caption.

    Args:
        module_file: pass __file__ from the calling module.
        table_num: the module's TABLE_NUM constant.
    Returns:
        The legend Paragraph object (so callers can add more runs if needed).
    """
    import os
    mod_dir = os.path.dirname(os.path.abspath(module_file))
    mod_basename = os.path.splitext(os.path.basename(module_file))[0]
    leg_path = os.path.join(mod_dir, f"{mod_basename}_legend.md")
    if not os.path.exists(leg_path):
        raise FileNotFoundError(
            f"Legend .md missing for {mod_basename}: expected {leg_path}"
        )
    with open(leg_path) as f:
        leg_md = f.read()
    title, body, abbrs = parse_legend_md(leg_md)
    style = "section" if table_num.startswith("S") else "caption"
    return add_legend(doc, body, table_num, title=title,
                       abbreviations=abbrs,
                       bookmark_id=bookmark_for(table_num),
                       style=style)


def parse_legend_md(md_text):
    """Parse a table/figure legend .md into (title, body, abbreviations).

    Expected structure:

        **Figure N. <one-sentence title>.**

        <body prose, may span multiple paragraphs>

        **Abbreviations:** k1, v1; k2, v2; ...

    Returns:
        title:   str or None (extracted from the first **bold** line, minus
                 the "Figure N." or "Table N." prefix)
        body:    str — everything between the title line and the abbreviations
                 line, JOINED WITH SINGLE SPACES (multi-paragraph legends are
                 collapsed to one docx paragraph by add_legend). This matches
                 the v10.3 rule that legends are single-paragraph — if a
                 multi-paragraph legend is genuinely needed, split the table
                 or move to prose_py/.
        abbrs:   list of "k, v" strings or None (semicolon-separated in the
                 source; rendered by add_legend as
                 "Abbreviations: k1, v1; k2, v2; ...").
    """
    lines = md_text.strip().splitlines()
    title = None
    body_lines = []
    abbr_str = None
    in_body = False
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        # Title line: **Figure N. <title>.** or **Table N. <title>.**
        if title is None and stripped.startswith("**") and stripped.endswith("**"):
            inner = stripped[2:-2]
            # Strip leading "Figure N." / "Table N." (with optional space)
            m = re.match(
                r"^(?:Figure\s+|Table\s+|Supplemental Table\s+|ST|F)[\w.]+\.\s*(.*?)\.?$",
                inner, re.IGNORECASE)
            if m:
                title = m.group(1)
            else:
                title = inner
            in_body = True
            continue
        # Abbreviations block
        if stripped.startswith("**Abbreviations:**"):
            abbr_str = stripped.replace("**Abbreviations:**", "").strip()
            if abbr_str.endswith("."):
                abbr_str = abbr_str[:-1]
            break
        if in_body:
            body_lines.append(stripped)
    body = " ".join(body_lines)
    abbrs = None
    if abbr_str:
        # Split on semicolons; each entry is "abbr, expansion"
        abbrs = [a.strip() for a in abbr_str.split(";") if a.strip()]
    return title, body, abbrs


def tidy_stats_text(s):
    """Normalise analysis-generated strings for publication display.

    The analysis writes model labels and test summaries in the plain-text form
    R produces -- "FEV1/FVC" from the column name, "chi2=8.30, df=1, p=0.004"
    from sprintf. Those are correct in a CSV and wrong in a typeset table, so
    they are fixed here at render time rather than in the analysis, which keeps
    the artifacts ASCII and avoids a re-render for a presentation change.
    """
    if s is None:
        return s
    s = str(s)
    s = s.replace("FEV1/FVC", "FEV\u2081/FVC")
    s = s.replace("chi2=", "\u03c7\u00b2 = ")
    s = s.replace("df=", "df = ")
    s = s.replace("p=", "p = ")
    return s
