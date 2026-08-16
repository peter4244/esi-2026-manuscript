"""Foundation smoke tests for Phase G's completed contracts.

Covers the gaps the Phase-G review identified:
  T1  inline INSERT — tail text lands AFTER the artifact, not before.
  T2  missing-callback path emits red flag inline.
  T3  legend .md → docx round-trip via parse_legend_md + add_legend produces
      a single paragraph (not three) with title + body + abbreviations.
  T4  end-to-end: one stub table + one stub figure through the orchestrator
      contract. Verifies alias-map wiring and INSERT dispatch.

Run: `python -m tests.test_foundation`.
"""
import sys, os, io, importlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from docx import Document
from tables.docx_helpers import (
    resolve_markers, render_markdown_to_docx, add_legend, parse_legend_md,
    FONT_NAME,
)

PASS = 0
FAIL = 0

def ok(msg):
    global PASS; PASS += 1; print(f"  PASS  {msg}")

def bad(msg):
    global FAIL; FAIL += 1; print(f"  FAIL  {msg}")

# ---------------------------------------------------------------------------
# T1 — inline INSERT, tail-text ordering
# ---------------------------------------------------------------------------
print("\nT1 — inline INSERT tail-text ordering")
doc = Document()
resolved, _ = resolve_markers(
    "See {{INSERT:mytable}} which shows the effect.",
    {"mytable"})

call_order = []
def stub_table_cb(d):
    call_order.append(("callback", len(d.paragraphs)))
    p = d.add_paragraph()
    r = p.add_run("[STUB TABLE INSERTED HERE]")
    r.bold = True

render_markdown_to_docx(doc, resolved,
                        insertion_callbacks={"mytable": stub_table_cb})

# Expected paragraph order:
# 0: "See "
# 1: "[STUB TABLE INSERTED HERE]"
# 2: " which shows the effect."
paragraphs = [p.text for p in doc.paragraphs]
if len(paragraphs) >= 3:
    if "See" in paragraphs[0] and paragraphs[0].strip().endswith("See"):
        ok("head text is in first paragraph")
    else:
        bad(f"head text placement: para 0 = {paragraphs[0]!r}")
    if "STUB TABLE" in paragraphs[1]:
        ok("stub table inserted at second paragraph")
    else:
        bad(f"stub not at para 1: {paragraphs[1]!r}")
    if "which shows" in paragraphs[2]:
        ok("tail text lands AFTER the stub (not before)")
    else:
        bad(f"tail misplaced: para 2 = {paragraphs[2]!r}")
else:
    bad(f"expected >=3 paragraphs, got {len(paragraphs)}: {paragraphs}")

# ---------------------------------------------------------------------------
# T2 — missing callback raises loudly (Phase K review §5: silent red-flag
# emission previously caused the build to log OK while shipping broken docx).
# ---------------------------------------------------------------------------
print("\nT2 — missing callback path")
doc = Document()
resolved, _ = resolve_markers("Body {{INSERT:knownkey}}.", {"knownkey"})
raised = False
try:
    render_markdown_to_docx(doc, resolved, insertion_callbacks={})
except ValueError as e:
    if "knownkey" in str(e) and "no registered callback" in str(e):
        ok("missing INSERT raises ValueError naming the offending key")
        raised = True
    else:
        bad(f"ValueError raised but wrong message: {e}")
        raised = True
if not raised:
    bad("missing INSERT should raise ValueError; nothing was raised")

# ---------------------------------------------------------------------------
# T3 — legend .md round-trip via parse_legend_md + add_legend
# ---------------------------------------------------------------------------
print("\nT3 — legend .md → single-paragraph legend")
leg_md = """**Figure 1. Distribution of participants across categories.**

The stacked bars display the classification distribution. Both frameworks
produce similar diagnostic categories.

**Abbreviations:** HR, hazard ratio; CI, confidence interval; ESI, Emphysema Severity Index."""

title, body, abbrs = parse_legend_md(leg_md)
if title and "Distribution" in title:
    ok(f"title parsed: {title!r}")
else:
    bad(f"title parse: {title!r}")
if body and "stacked bars" in body and "Both frameworks" in body:
    ok("body parsed and joined across lines")
else:
    bad(f"body parse: {body!r}")
if abbrs and len(abbrs) == 3 and "HR, hazard ratio" in abbrs[0]:
    ok(f"abbreviations parsed: {abbrs}")
else:
    bad(f"abbrs parse: {abbrs}")

doc = Document()
add_legend(doc, body, "F1", title=title, abbreviations=abbrs)
# CRITICAL: exactly ONE paragraph
if len(doc.paragraphs) == 1:
    ok("add_legend produces exactly ONE paragraph (not three)")
else:
    bad(f"add_legend produced {len(doc.paragraphs)} paragraphs, expected 1")

p = doc.paragraphs[0]
if "Figure 1" in p.text and "Distribution" in p.text and "Abbreviations" in p.text:
    ok("legend paragraph contains title + body + abbreviations")
else:
    bad(f"legend content: {p.text!r}")

# ---------------------------------------------------------------------------
# T4 — end-to-end: stub table + stub figure through orchestrator wiring
# ---------------------------------------------------------------------------
print("\nT4 — end-to-end alias-map + INSERT dispatch")
# Simulate what build_manuscript does: an insertion_registry of aliases + a
# callback map from aliases to callables. Prose uses short aliases.
def stub_table1(d):
    p = d.add_paragraph()
    r = p.add_run("Stub Table 1 rendered."); r.bold = True

def stub_figure1(d):
    p = d.add_paragraph()
    r = p.add_run("[Stub Figure 1 image + legend]"); r.italic = True

registry = {"table1", "figure1"}
callbacks = {"table1": stub_table1, "figure1": stub_figure1}

md = """## Results

Prose sentence one referencing {{TABLE:1}}.

{{INSERT:table1}}

Prose after table. Now the figure.

{{INSERT:figure1}}

Final closing prose referencing {{FIGURE:1}}."""
resolved, _ = resolve_markers(md, registry)
doc = Document()
render_markdown_to_docx(doc, resolved, insertion_callbacks=callbacks)

texts = [p.text for p in doc.paragraphs]
# Look for the expected sequence
found_seq = 0
for t in texts:
    if found_seq == 0 and t.startswith("Results"):
        found_seq = 1
    elif found_seq == 1 and "Prose sentence one referencing Table 1" in t:
        found_seq = 2
    elif found_seq == 2 and "Stub Table 1" in t:
        found_seq = 3
    elif found_seq == 3 and "Prose after table" in t:
        found_seq = 4
    elif found_seq == 4 and "Stub Figure 1" in t:
        found_seq = 5
    elif found_seq == 5 and "Final closing prose referencing Figure 1" in t:
        found_seq = 6

if found_seq == 6:
    ok("end-to-end sequence renders in correct order (prose→table→prose→figure→prose)")
else:
    bad(f"end-to-end sequence broken at stage {found_seq}. Got:\n" +
        "\n".join(f"   [{i}] {t!r}" for i, t in enumerate(texts)))

# ---------------------------------------------------------------------------
# T5 — inline INSERT with bold/italic after it (Phase G checkpoint #1)
# ---------------------------------------------------------------------------
print("\nT5 — inline INSERT followed by bold/italic")
resolved, _ = resolve_markers(
    "See {{INSERT:mytable}} which shows **the key result** clearly.",
    {"mytable"})

def stub_cb(d):
    p = d.add_paragraph()
    r = p.add_run("[ARTIFACT]")

doc = Document()
render_markdown_to_docx(doc, resolved,
                        insertion_callbacks={"mytable": stub_cb})
texts = [p.text for p in doc.paragraphs]

# The bold text and trailing prose MUST come AFTER [ARTIFACT], not before.
artifact_idx = None
for i, t in enumerate(texts):
    if "[ARTIFACT]" in t:
        artifact_idx = i
        break
if artifact_idx is None:
    bad(f"artifact not found in {texts}")
elif artifact_idx == 0:
    bad(f"artifact at position 0 (nothing before): {texts}")
else:
    # Check that "the key result" appears AFTER artifact
    after_texts = " ".join(texts[artifact_idx + 1:])
    if "the key result" in after_texts and "clearly" in after_texts:
        ok("bold text and trailing prose correctly after the artifact")
    else:
        bad(f"bold/tail landed wrong. Paragraphs:\n" +
            "\n".join(f"   [{i}] {t!r}" for i, t in enumerate(texts)))
    before_texts = " ".join(texts[:artifact_idx])
    if "the key result" in before_texts or "clearly" in before_texts:
        bad(f"bold/tail leaked back BEFORE artifact: {texts}")
    else:
        ok("no bold-text or tail leakage back to pre-insert paragraph")

# ---------------------------------------------------------------------------
# T6 — manifest cross-check catches drift (Phase G checkpoint #2)
# ---------------------------------------------------------------------------
print("\nT6 — manifest cross-check")
# The manifest module runs its cross-check at import time. Try to break it
# by tampering with copies of the exposed lists.
import manifest
try:
    # Snapshot the current sets — they must agree
    tables_in_keys = {p.rsplit(".", 1)[1] for p in manifest.INSERT_KEYS.values()
                      if p.startswith("tables.main.")}
    if tables_in_keys == set(manifest.MAIN_TABLES):
        ok("manifest currently agrees (INSERT_KEYS ↔ MAIN_TABLES)")
    else:
        bad("manifest DRIFT undetected — cross-check should have raised at import")

    # Directly call _cross_check with tampered globals
    saved = manifest.MAIN_TABLES.copy()
    manifest.MAIN_TABLES = ["table99_notreal"]
    try:
        manifest._cross_check()
        bad("cross-check FAILED to detect drift")
    except AssertionError:
        ok("cross-check raises AssertionError on manifest drift")
    finally:
        manifest.MAIN_TABLES = saved
except Exception as e:
    bad(f"cross-check test threw unexpected: {e}")


# ---------------------------------------------------------------------------
# T7 — bookmark_for + add_legend_from_sibling (Phase G checkpoint #3 + #7)
# ---------------------------------------------------------------------------
print("\nT7 — bookmark contract + sibling-legend convention")
from tables.docx_helpers import bookmark_for, add_legend_from_sibling

assert bookmark_for("1")     == "tbl_1"
assert bookmark_for("S3")    == "tbl_S3"
assert bookmark_for("S6a.1") == "tbl_S6a_1"
ok("bookmark_for handles main/supp/dotted IDs")

# Create a temporary sibling legend + module to test add_legend_from_sibling
import tempfile, textwrap
with tempfile.TemporaryDirectory() as tmp:
    mod_path = os.path.join(tmp, "sN_test.py")
    leg_path = os.path.join(tmp, "sN_test_legend.md")
    with open(mod_path, "w") as f: f.write("# fake\n")
    with open(leg_path, "w") as f:
        f.write("**Supplementary Table S99. Fake title for testing.**\n\n"
                "Body prose here.\n\n"
                "**Abbreviations:** X, exemplar.")
    doc = Document()
    add_legend_from_sibling(doc, mod_path, "S99")
    # Supp artifacts (TABLE_NUM starts with "S") render section-style:
    # spacer paragraph + legend paragraph. Main-manuscript artifacts render
    # caption-style: single legend paragraph.
    if len(doc.paragraphs) == 2:
        ok("add_legend_from_sibling (supp) emits spacer + legend paragraph")
    else:
        bad(f"expected 2 paragraphs (spacer + legend), got {len(doc.paragraphs)}")
    # Legend content lives on the second paragraph; bookmark should be there too.
    p = doc.paragraphs[1]
    from docx.oxml.ns import qn
    bmk = p._p.findall(qn("w:bookmarkStart"))
    if bmk and bmk[0].get(qn("w:name")) == "tbl_S99":
        ok("bookmark 'tbl_S99' anchored on the legend paragraph")
    else:
        bad(f"bookmark missing or wrong; got: {[b.get(qn('w:name')) for b in bmk]}")
    # Section style now emits: bold "S99 — <title>." prefix, then body,
    # then italic "Abbreviations:" + text (the H1 heading is gone; the
    # legend itself carries the number + title).
    if ("S99 — Fake title" in p.text
            and "Body prose" in p.text
            and "Abbreviations" in p.text):
        ok("sibling legend (supp) rendered as 'SN — Title. body. Abbreviations: …'")
    else:
        bad(f"legend content: {p.text!r}")


# ---------------------------------------------------------------------------
# T8 — ensure_figure_fresh raises on missing required upstream (checkpoint #6)
# ---------------------------------------------------------------------------
print("\nT8 — ensure_figure_fresh missing-upstream behaviour")
# Setup a temp figure dir with a broken requirements.txt
import build_manuscript
with tempfile.TemporaryDirectory() as tmp:
    fig_name = "fake_fig"
    fig_dir = os.path.join(tmp, fig_name)
    os.makedirs(fig_dir)
    r_path = os.path.join(fig_dir, f"{fig_name}.R")
    with open(r_path, "w") as f: f.write("# stub\n")
    with open(os.path.join(fig_dir, "requirements.txt"), "w") as f:
        f.write("/absolutely/does/not/exist.csv\n")
    # Monkey-patch FIGURES_DIR
    saved_fd = build_manuscript.FIGURES_DIR
    build_manuscript.FIGURES_DIR = tmp
    try:
        build_manuscript.ensure_figure_fresh(fig_name)
        bad("ensure_figure_fresh should have raised on missing upstream")
    except FileNotFoundError:
        ok("ensure_figure_fresh raises on missing required upstream")
    except Exception as e:
        bad(f"ensure_figure_fresh raised unexpected: {type(e).__name__}: {e}")
    finally:
        build_manuscript.FIGURES_DIR = saved_fd

# ---------------------------------------------------------------------------
print(f"\n===== {PASS} PASS, {FAIL} FAIL =====")
sys.exit(1 if FAIL else 0)
