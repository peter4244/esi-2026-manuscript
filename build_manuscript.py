"""Top-level orchestrator — v9 main manuscript build.

Walks MAIN_PROSE_ORDER, resolving markers, invoking prose_py modules, and
calling per-table build(doc) via {{INSERT:tableN}} callbacks. Every artifact
and every prose section is wrapped in try/except; failures render as a red
paragraph and the build continues. mtime-checks figures against their source
scripts; fail-loud on stale.

Usage:
    python build_manuscript.py
"""
import sys, os, importlib, subprocess, shutil, traceback, time
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from manifest import (MAIN_PROSE_ORDER, MAIN_TABLES, FIGURES, INSERT_KEYS,
                       MANUSCRIPT_OUT, BUILD_LOG_MAIN, FIGURES_DIR)
from tables.docx_helpers import (
    FONT_NAME, BODY_FS, resolve_markers, render_markdown_to_docx,
    add_legend, parse_legend_md,
)

# ---------------------------------------------------------------------------
# Style setup (AJRCCM: Arial 11 pt body, US Letter, 1" margins, single-space)
# ---------------------------------------------------------------------------
def init_document():
    doc = Document()
    for section in doc.sections:
        section.page_width  = Inches(8.5); section.page_height = Inches(11)
        section.top_margin  = section.bottom_margin = Inches(1)
        section.left_margin = section.right_margin  = Inches(1)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = FONT_NAME
    normal.font.size = Pt(BODY_FS)
    rPr = normal.element.get_or_add_rPr()
    rFonts = rPr.find(qn("w:rFonts"))
    if rFonts is None:
        rFonts = OxmlElement("w:rFonts"); rPr.append(rFonts)
    for k in ("w:ascii", "w:hAnsi", "w:cs"):
        rFonts.set(qn(k), FONT_NAME)
    for name, size in [("Heading 1", 14), ("Heading 2", 12), ("Heading 3", 11)]:
        st = styles[name]
        st.font.name = FONT_NAME; st.font.size = Pt(size); st.font.bold = True
        st.font.color.rgb = RGBColor(0, 0, 0)
        st.paragraph_format.space_before = Pt(12); st.paragraph_format.space_after = Pt(4)
    normal.paragraph_format.space_after = Pt(8)
    # AJRCCM: single-space (not the 1.5 used in v10.2). Journal preference.
    normal.paragraph_format.line_spacing = 1.0
    return doc


# ---------------------------------------------------------------------------
# Build log
# ---------------------------------------------------------------------------
class BuildLog:
    def __init__(self, path):
        self.path = path
        self.entries = []
    def note(self, kind, name, msg):
        self.entries.append(f"[{kind}] {name}: {msg}")
    def save(self):
        with open(self.path, "w") as f:
            f.write("\n".join(self.entries) + "\n")


def red_paragraph(doc, msg):
    p = doc.add_paragraph()
    r = p.add_run(f"[{msg}]")
    r.bold = True
    r.font.color.rgb = RGBColor(0xC0, 0x00, 0x00)
    r.font.name = FONT_NAME
    r.font.size = Pt(BODY_FS)
    return p


# ---------------------------------------------------------------------------
# Figure freshness check (fail-loud)
# ---------------------------------------------------------------------------
def ensure_figure_fresh(figure_name):
    """Verify figures/<figure_name>/<figure_name>.png is fresh vs every listed
    upstream input. Auto-re-runs via Rscript when stale; fail-loud on missing
    binary, non-zero exit, or missing output.

    Freshness checks (Phase G review #5):
      - figures/<figure_name>/<figure_name>.R  (always)
      - figures/style.R                        (always — shared style)
      - figures/validate_layout.R              (always)
      - any path listed in figures/<figure_name>/requirements.txt (optional
        sibling file, one path per line, relative to project root or absolute)
    """
    fig_dir = os.path.join(FIGURES_DIR, figure_name)
    r_path   = os.path.join(fig_dir, f"{figure_name}.R")
    png_path = os.path.join(fig_dir, f"{figure_name}.png")

    if not os.path.exists(r_path):
        raise FileNotFoundError(f"Figure source missing: {r_path}")

    upstream = [r_path,
                os.path.join(FIGURES_DIR, "style.R"),
                os.path.join(FIGURES_DIR, "validate_layout.R")]
    req_txt = os.path.join(fig_dir, "requirements.txt")
    if os.path.exists(req_txt):
        with open(req_txt) as f:
            for line in f:
                p = line.strip()
                if not p or p.startswith("#"):
                    continue
                if not os.path.isabs(p):
                    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), p)
                upstream.append(p)

    # Fail loud on missing required upstream (Phase G checkpoint #6). Do not
    # let a missing data file quietly pass as "not stale".
    missing = [u for u in upstream if not os.path.exists(u)]
    if missing:
        raise FileNotFoundError(
            f"Figure {figure_name} requires missing upstream file(s):\n  "
            + "\n  ".join(missing)
        )

    if not os.path.exists(png_path):
        stale = True
    else:
        png_mtime = os.path.getmtime(png_path)
        stale = any(os.path.getmtime(u) > png_mtime for u in upstream)

    if not stale:
        return png_path

    rscript = shutil.which("Rscript")
    if rscript is None:
        raise RuntimeError(
            f"Figure {figure_name} is stale and Rscript is not on PATH. "
            f"Install R or manually re-render: cd {fig_dir} && Rscript {os.path.basename(r_path)}"
        )
    print(f"  [FIGURE STALE] rerunning: cd {fig_dir} && Rscript {os.path.basename(r_path)}")
    # cwd=fig_dir so scripts using relative paths (`source('../style.R')` etc.)
    # resolve correctly (Phase G review #6).
    result = subprocess.run([rscript, os.path.basename(r_path)],
                             capture_output=True, text=True, cwd=fig_dir)
    if result.returncode != 0:
        raise RuntimeError(
            f"Rscript exited {result.returncode} while rendering {figure_name}:\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    if not os.path.exists(png_path):
        raise RuntimeError(
            f"Rscript for {figure_name} exited 0 but did not produce {png_path}"
        )
    return png_path


# ---------------------------------------------------------------------------
# Build one prose section (with per-section try/except)
# ---------------------------------------------------------------------------
def build_section(doc, section_label, section_source, insertion_registry,
                  insertion_callbacks, log):
    try:
        if section_source.startswith("prose_py."):
            mod = importlib.import_module(section_source)
            mod.build(doc)
        elif section_source.endswith(".md"):
            src_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                     section_source)
            with open(src_path) as f:
                md_text = f.read()
            resolved, _ = resolve_markers(md_text, insertion_registry)
            render_markdown_to_docx(doc, resolved,
                                    insertion_callbacks=insertion_callbacks)
        else:
            raise ValueError(f"Unknown prose source: {section_source}")
        log.note("OK", section_label, "rendered")
    except Exception as e:
        tb = traceback.format_exc(limit=4)
        red_paragraph(doc, f"BUILD FAILED: {section_label} — {e}")
        log.note("FAIL", section_label, f"{e}\n{tb}")
        print(f"  [FAIL] {section_label}: {e}")


# ---------------------------------------------------------------------------
# Callback builders for tables and figures
# ---------------------------------------------------------------------------
def make_table_callback(alias_key, module_path, log):
    """alias_key: short prose key (e.g. 'table1'); module_path: full import path
    from manifest.INSERT_KEYS (e.g. 'tables.main.table1_by_category')."""
    def _cb(doc):
        try:
            mod = importlib.import_module(module_path)
            mod.build(doc)
            log.note("OK", alias_key, f"table rendered via {module_path}")
        except Exception as e:
            red_paragraph(doc, f"BUILD FAILED: {alias_key} — {e}")
            log.note("FAIL", alias_key, str(e))
    return _cb


def make_figure_callback(alias_key, module_path, log):
    """alias_key: short prose key ('figure1'); module_path: full import path
    ('figures.figure1_agreement'). Legend rendered via add_legend to satisfy
    v10.3 fix-list item 6 (single-paragraph legend, no separate caption note)
    — Phase G review #2.
    """
    figure_dir_name = module_path.split(".", 1)[1]  # drop 'figures.' prefix
    def _cb(doc):
        try:
            png = ensure_figure_fresh(figure_dir_name)
            # Embed image in an unindented paragraph
            para = doc.add_paragraph()
            para.paragraph_format.first_line_indent = None
            run = para.add_run()
            run.add_picture(png, width=Inches(6.5))
            log.note("OK", alias_key, "figure embedded")
            # Legend via add_legend (single paragraph) — parse the .md into
            # (title, body, abbreviations) and hand off. Never emit a separate
            # caption-note paragraph.
            leg_path = os.path.join(FIGURES_DIR, figure_dir_name,
                                    f"{figure_dir_name}_legend.md")
            if os.path.exists(leg_path):
                with open(leg_path) as f:
                    leg_md = f.read()
                title, body, abbrs = parse_legend_md(leg_md)
                # Extract figure number from alias_key: 'figure1' → 'F1', 'figure2' → 'F2'
                if alias_key.startswith("figure"):
                    fig_num = alias_key[6:]  # '1', '2', etc.
                    add_legend(doc, body, f"F{fig_num}",
                               title=title, abbreviations=abbrs)
                else:
                    add_legend(doc, body, alias_key, title=title,
                               abbreviations=abbrs)
        except Exception as e:
            red_paragraph(doc, f"BUILD FAILED: {alias_key} — {e}")
            log.note("FAIL", alias_key, str(e))
    return _cb


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    log = BuildLog(BUILD_LOG_MAIN)
    doc = init_document()

    # Insertion registry drawn from the alias map (Phase G review #14) — prose
    # uses short keys ({{INSERT:table1}}, {{INSERT:figure2}}); this maps them
    # to filesystem module paths.
    insertion_registry = set(INSERT_KEYS.keys())

    insertion_callbacks = {}
    for alias, module_path in INSERT_KEYS.items():
        if module_path.startswith("tables."):
            insertion_callbacks[alias] = make_table_callback(alias, module_path, log)
        elif module_path.startswith("figures."):
            insertion_callbacks[alias] = make_figure_callback(alias, module_path, log)
        else:
            raise ValueError(f"INSERT_KEYS[{alias!r}] must point at tables.* or figures.*: got {module_path!r}")

    # Walk manifest.
    for label, source in MAIN_PROSE_ORDER:
        print(f"[section] {label} ← {source}")
        build_section(doc, label, source, insertion_registry,
                      insertion_callbacks, log)

    doc.save(MANUSCRIPT_OUT)
    log.save()
    print(f"\nSaved: {MANUSCRIPT_OUT}")
    print(f"Build log: {BUILD_LOG_MAIN}")
    n_ok   = sum(1 for e in log.entries if e.startswith("[OK]"))
    n_fail = sum(1 for e in log.entries if e.startswith("[FAIL]"))
    print(f"Build summary: {n_ok} OK, {n_fail} FAIL")


if __name__ == "__main__":
    main()
