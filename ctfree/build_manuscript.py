#!/usr/bin/env python3
"""Build the CT-free manuscript .docx from source.

Unlike the v15 build, this one stays runnable. Its prose lives in METHODS.md
and RESULTS.md, its tables are constructed from the artifacts in assets/ rather
than typed, and its figures are the PNGs the figure scripts emit. Nothing here
is hand-edited into the .docx, so rebuilding never destroys anything, which is
what retired build_manuscript.py in the parent directory.

Prose files carry two kinds of editorial marking that must not reach the
document: claim ids in braces, {RISK-01}, which tie a sentence to its registry
entry, and provenance notes, **[v15 para 67, verbatim]**, which record reuse.
Both are stripped here so the sources stay annotated while the output is clean.

Usage, from anywhere:
    python3 /abs/path/to/ctfree/build_manuscript.py
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

from docx import Document                                    # noqa: E402
from docx.shared import Pt, Inches, RGBColor                 # noqa: E402
from docx.oxml import OxmlElement                            # noqa: E402
from docx.oxml.ns import qn                                  # noqa: E402
from docx.enum.text import WD_ALIGN_PARAGRAPH                # noqa: E402
from docx.enum.table import WD_ALIGN_VERTICAL                # noqa: E402

from tables.docx_helpers import FONT_NAME, CONTENT_WIDTH_IN  # noqa: E402
import pjc_guard
import prose_guard                                             # noqa: E402
import word_guard
import display_order                                           # noqa: E402
from supp_registry import supp_num                             # noqa: E402

ASSETS = os.path.join(HERE, "assets")
FIGS   = os.path.join(HERE, "figures")
OUT    = os.path.join(HERE, "manuscript",
                      "CT-free MD-COPD manuscript draft v3.docx")
BODY_FS, TBL_FS = 11, 9
CATS = ["noCOPD", "AFL-only", "COPD-minor", "COPD-major"]
# Mortality and exacerbation models are fitted on different participant sets,
# so the denominator shown must follow the outcome rather than being one number
# reused for all three.
N_COL = {"all": "n_mort", "resp": "n_mort", "exac": "n_exac"}
# Short names agreed for the manuscript, defined in Methods and restated in
# Results. They replace the numbered "schema N" labels, which required the
# reader to hold a lookup table to parse a sentence.
SCHEMA_NAME = {"S1": "Fixed ratio", "S2": "MD-COPD",
               "S3": "NoCT classification", "S4": "ESI classification"}

CLAIM_ID   = re.compile(r"\s*\{[A-Z][A-Za-z0-9-]*(?:,\s*[A-Z][A-Za-z0-9-]*)*\}")
# Any bracketed bold line is an editorial provenance note, not prose.
PROVENANCE = re.compile(r"^\*\(.*\)\*$|^\*\*\[.*\]\*\*$")


def load(name):
    with open(os.path.join(ASSETS, name)) as f:
        return list(csv.DictReader(f))


def init_document():
    doc = Document()
    for s in doc.sections:
        s.page_width, s.page_height = Inches(8.5), Inches(11)
        s.top_margin = s.bottom_margin = Inches(1)
        s.left_margin = s.right_margin = Inches(1)
    normal = doc.styles["Normal"]
    normal.font.name = FONT_NAME
    normal.font.size = Pt(BODY_FS)
    rPr = normal.element.get_or_add_rPr()
    rF = rPr.find(qn("w:rFonts"))
    if rF is None:
        rF = OxmlElement("w:rFonts"); rPr.append(rF)
    for k in ("w:ascii", "w:hAnsi", "w:cs"):
        rF.set(qn(k), FONT_NAME)
    for name, size in [("Heading 1", 14), ("Heading 2", 12), ("Heading 3", 11)]:
        st = doc.styles[name]
        st.font.name, st.font.size, st.font.bold = FONT_NAME, Pt(size), True
        st.font.color.rgb = RGBColor(0, 0, 0)
        st.paragraph_format.space_before = Pt(12)
        st.paragraph_format.space_after = Pt(4)
    normal.paragraph_format.space_after = Pt(8)
    normal.paragraph_format.line_spacing = 1.0
    return doc


def emphasis(par, text, size=BODY_FS):
    """Render **bold** spans; everything else plain."""
    for i, chunk in enumerate(re.split(r"(\*\*[^*]+\*\*)", text)):
        if not chunk:
            continue
        r = par.add_run(chunk[2:-2] if chunk.startswith("**") else chunk)
        r.bold = chunk.startswith("**")
        r.font.name, r.font.size = FONT_NAME, Pt(size)


def add_prose(doc, md_path, skip_after=None):
    """Render a prose source, stopping at `skip_after` so the editorial
    'Still to write' and 'Open' sections never reach the document."""
    with open(md_path) as f:
        lines = f.read().split("\n")
    # Everything before the first section heading is editorial front matter
    # explaining the annotations, and belongs in the source rather than the
    # document.
    first = next((i for i, l in enumerate(lines) if l.startswith("## ")), 0)
    lines = lines[first:]
    para, emitted = [], 0

    def flush():
        nonlocal para, emitted
        if not para:
            return
        text = CLAIM_ID.sub("", " ".join(para)).strip()
        para = []
        if not text or PROVENANCE.match(text):
            return
        emphasis(doc.add_paragraph(), text)
        emitted += 1

    for ln in lines:
        t = ln.rstrip()
        if t.startswith("#"):
            title = t.lstrip("#").strip()
            if skip_after and title.lower().startswith(skip_after.lower()):
                flush()
                return emitted
            flush()
            if t.startswith("## ") and title.lower() not in ("introduction", "discussion"):
                doc.add_paragraph(title, style="Heading 2")
        elif t.startswith("---") or t.startswith("|") or t.startswith("```"):
            flush()
        elif not t.strip():
            flush()
        else:
            para.append(t.strip())
    flush()
    return emitted


def set_cell_margins(tbl, inches):
    """Word's default cell padding is 0.08 inch a side, which is 0.16 inch of
    every column lost to whitespace. At nine columns that is the difference
    between a number fitting on one line and wrapping mid-value."""
    tblPr = tbl._element.find(qn("w:tblPr"))
    mar = tblPr.find(qn("w:tblCellMar"))
    if mar is None:
        mar = OxmlElement("w:tblCellMar"); tblPr.append(mar)
    for side in ("top", "left", "bottom", "right"):
        el = mar.find(qn("w:" + side))
        if el is None:
            el = OxmlElement("w:" + side); mar.append(el)
        el.set(qn("w:w"), str(int(round(inches * 1440))))
        el.set(qn("w:type"), "dxa")


def fmt_p(p):
    """P values as Pete writes them (2026-09-24): below 0.005 as '< 0.005',
    otherwise three decimals under 0.1 and two above."""
    p = float(p)
    return "< 0.005" if p < 0.005 else (f"{p:.3f}" if p < 0.1 else f"{p:.2f}")


class Section(str):
    """A table row that names the group of rows beneath it, spanning every column."""


def add_table(doc, headers, rows, widths, body_fs=TBL_FS, pad_in=0.05):
    assert abs(sum(widths) - CONTENT_WIDTH_IN) < 0.02, sum(widths)
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Table Grid"
    grid = t._element.find(qn("w:tblGrid"))
    for gc, w in zip(grid.findall(qn("w:gridCol")), widths):
        gc.set(qn("w:w"), str(int(round(w * 1440))))
        gc.set(qn("w:type"), "dxa")
    tblPr = t._element.find(qn("w:tblPr"))
    lay = tblPr.find(qn("w:tblLayout"))
    if lay is None:
        lay = OxmlElement("w:tblLayout"); tblPr.append(lay)
    lay.set(qn("w:type"), "fixed")
    set_cell_margins(t, pad_in)
    for i, row in enumerate([headers] + rows):
        if isinstance(row, Section):
            cell = t.rows[i].cells[0].merge(t.rows[i].cells[-1])
            cell.text = ""
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(3)
            p.paragraph_format.space_after = Pt(1)
            r = p.add_run(str(row))
            r.bold = True
            r.font.name, r.font.size = FONT_NAME, Pt(body_fs)
            continue
        for j, val in enumerate(row):
            cell = t.rows[i].cells[j]
            cell.width = Inches(widths[j])
            cell.text = ""
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(1)
            if j:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(str(val))
            r.bold = (i == 0)
            r.font.name, r.font.size = FONT_NAME, Pt(body_fs)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
    keep_table_together(t)
    return t


def keep_table_together(t):
    """Keep a table on one page, and on the page of the legend that follows it.

    Every row is marked cannot-split and every paragraph in it keep-with-next,
    so Word moves the whole table to the next page rather than breaking it. A
    table longer than a page still breaks, because the chain cannot be honored.
    The last row keeps with the legend paragraph after the table, and the header
    row repeats on the next page when a table is longer than a page."""
    hdr = t.rows[0]._tr.get_or_add_trPr()
    if hdr.find(qn("w:tblHeader")) is None:
        hdr.append(OxmlElement("w:tblHeader"))
    for row in t.rows:
        trPr = row._tr.get_or_add_trPr()
        if trPr.find(qn("w:cantSplit")) is None:
            trPr.append(OxmlElement("w:cantSplit"))
        for cell in row.cells:
            for p in cell.paragraphs:
                p.paragraph_format.keep_with_next = True


def legend(doc, label, text):
    p = doc.add_paragraph()
    r = p.add_run(label + " ")
    r.bold = True
    r.font.name, r.font.size = FONT_NAME, Pt(BODY_FS - 1)
    r2 = p.add_run(text)
    r2.font.name, r2.font.size = FONT_NAME, Pt(BODY_FS - 1)


# --------------------------------------------------------------------------
# Tables, built from the artifacts
# --------------------------------------------------------------------------
def t_classifications(doc, label="Table 1."):
    lab = {(r["schema"], r["category"]): int(r["n"]) for r in load("schema_labels.csv")}
    n = lambda s, c: f"{lab[(s, c)]:,}" if (s, c) in lab else "—"
    n_total = sum(lab[(s, c)] for (s, c) in lab if s == "S2")
    # ESI threshold read from the fitted-schema artifact so this cannot drift
    # from the actual model.
    fit = {r["schema"]: r for r in load("schema_fit.csv")}
    esi_t = float(fit["S4"]["t_low"])
    esi_desc = f"ESI ≥ {esi_t:.2f}, dyspnea, SGRQ, chronic bronchitis (≥2)"
    rows = [
        ["Fixed ratio", "none; COPD is airflow limitation",
         n("S1", "noCOPD"), "—", "—", n("S1", "COPD")],
        ["MD-COPD", "emphysema, wall thickening, dyspnea, SGRQ, chronic bronchitis (≥3)",
         n("S2", "noCOPD"), n("S2", "AFL-only"), n("S2", "COPD-minor"), n("S2", "COPD-major")],
        ["NoCT classification", "dyspnea, SGRQ, chronic bronchitis (≥2)",
         n("S3", "noCOPD"), n("S3", "AFL-only"), n("S3", "COPD-minor"), n("S3", "COPD-major")],
        ["ESI classification", esi_desc,
         n("S4", "noCOPD"), n("S4", "AFL-only"), n("S4", "COPD-minor"), n("S4", "COPD-major")]]
    add_table(doc, ["Classification", "Minor criteria", "noCOPD", "AFL-only",
                    "COPD-minor", "COPD-major"],
              rows, [1.25, 1.95, 0.72, 0.92, 0.84, 0.82])
    legend(doc, label,
           f"Distribution of the {n_total:,} participants according to the four "
           "classification approaches. "
           "The fixed-ratio classification defines COPD by post-bronchodilator "
           "FEV\u2081/FVC < 0.70 alone. MD-COPD incorporates airflow limitation as the major "
           "criterion and visual emphysema, definite airway wall thickening, dyspnea, SGRQ, "
           "and chronic bronchitis as minor criteria. The NoCT and ESI classifications use the "
           "modified criteria shown in the table. In participants with coronary artery disease "
           "or congestive heart failure, the COPD-minor pathway requires both CT criteria "
           "under MD-COPD, is unavailable under the NoCT classification, and requires the ESI "
           "criterion under the ESI classification. AFL-only = airflow limitation without other "
           "criteria; ESI = Emphysema Severity Index; SGRQ = St. George\u2019s Respiratory "
           "Questionnaire.")


def t_risk_common_ref(doc, label="Table 3."):
    """Adjusted risk of every group of every multidimensional classification
    against the common reference, and each CT-free group against the same MD-COPD
    group as a ratio of adjusted estimates. Laid out like the crude table (S4) so
    the two read the same way (Pete, 2026-09-24). A cell under the event floor
    keeps its point estimate and loses its interval and P."""
    adj = {(r["schema"], r["category"]): r for r in load("consensus_ref_risk.csv")}
    cru = {(r["schema"], r["category"], r["outcome"]): r for r in load("consensus_ref_crude.csv")}
    cmp_ = {(r["schema"], r["category"], r["outcome"]): r for r in load("group_vs_mdcopd.csv")
            if r["type"] == "adjusted"}
    ref = load("consensus_ref_group.csv")[0]
    NM = {"S2": "MD-COPD", "S3": "NoCT classification", "S4": "ESI classification"}
    OUTC = (("all", "All-cause mortality", "all_HR", "all_LCI", "all_UCI", "all_few_events"),
            ("resp", "Respiratory mortality", "resp_HR", "resp_LCI", "resp_UCI", "resp_few_events"),
            ("exac", "Exacerbations", "exac_IRR", "exac_LCI", "exac_UCI", None))
    FLAG, TRUE = "\u2020", ("TRUE", "T")
    ci = lambda v, lo, hi: f"{float(v):.2f} ({float(lo):.2f}\u2013{float(hi):.2f})"
    rows = []
    for g in ("AFL-only", "COPD-minor", "COPD-major"):
        rows.append(Section(g))
        for o, olab, est, lo, hi, fewcol in OUTC:
            for k, s_ in enumerate(("S2", "S3", "S4")):
                r = adj[(s_, g)]
                few = fewcol is not None and r[fewcol].upper() in TRUE
                own = f"{float(r[est]):.2f}{FLAG}" if few else ci(r[est], r[lo], r[hi])
                events = f"{int(float(cru[(s_, g, o)]['events'])):,}"
                lead = olab if k == 0 else ""
                if s_ == "S2":
                    rows.append([lead, NM[s_], events, own, "reference", ""])
                    continue
                x = cmp_[(s_, g, o)]
                if x["few_events"].upper() in TRUE:
                    vs, pt = f"{float(x['ratio_of_ratios']):.2f}{FLAG}", ""
                else:
                    p_ = float(x["p_boot"]); floor = 2 / int(x["B_eff"])
                    vs = ci(x["ratio_of_ratios"], x["lo"], x["hi"])
                    pt = fmt_p(p_)
                rows.append([lead, NM[s_], events, own, vs, pt])
    add_table(doc, ["Outcome", "Classification", "Events",
                    "HR or IRR versus the common reference (95% CI)",
                    "Ratio of HRs or IRRs versus MD-COPD (95% CI)", "P"],
              rows, [1.25, 1.35, 0.55, 1.35, 1.35, 0.65])
    legend(doc, label,
           "Adjusted hazard ratios (HRs) for all-cause and respiratory mortality and incidence "
           "rate ratios (IRRs) for respiratory exacerbations are shown relative to the common "
           f"reference comprising the {int(ref['n_cohort']):,} participants classified as "
           "noCOPD by all three classifications. Models were adjusted for age, sex, race, "
           "current smoking status, pack-years, and body mass index; exacerbation models were "
           "additionally adjusted for baseline exacerbation frequency. Ratios versus MD-COPD "
           "divide the HR or IRR of each CT-free classification's group by that of the "
           "corresponding MD-COPD group; 95% confidence intervals and two-sided P values were "
           "obtained from 1,000 paired subject-level bootstrap resamples. Corresponding unadjusted "
           f"rate ratios are shown in Supplemental Table {supp_num('groups_vs_mdcopd')}. "
           f"{FLAG} Fewer than 10 events in the group, or in either group for comparisons with "
           "MD-COPD; the estimate is shown without a confidence interval or P value. "
           "AFL-only = airflow limitation without other criteria; HR = hazard ratio; "
           "IRR = incidence rate ratio; CI = confidence interval.")

def t_discord_risk(doc, label="Table 4."):
    """Cross-classification of MD-COPD and the ESI classification: each group
    against its own stratum's reference, crude ratios only, respiratory mortality
    out for too few deaths (Pete, 2026-09-11),
    as in Figure 6. One table with a header row per stratum; each stratum
    carries its own reference row, because the references differ (both call
    noCOPD where spirometry is preserved, both call AFL-only where it is not).
    The event floor applies to the group and to its reference alike."""
    FLOOR, FLAG = 10, "\u2020"
    STRATA = [("Preserved spirometry", "discord_rates.csv", "Both-noCOPD"),
              ("Airflow limitation", "discord_rates_afl.csv", "Both-AFL-only")]
    ORDER = ["CT-only-COPD", "ESI-only-COPD", "Both-COPD"]
    cru = {(r["stratum"], r["group"], r["outcome"]): r for r in load("discord_crude_strata.csv")}

    def cell(r, n_ev, n_ref):
        if n_ev == 0:
            return "not estimable"
        if n_ev < FLOOR or n_ref < FLOOR or r["lo"] in ("", "NA"):
            return f"{float(r['rr']):.2f}{FLAG}"
        return f"{float(r['rr']):.2f} ({float(r['lo']):.2f}\u2013{float(r['hi']):.2f})"

    rows = []
    for title, rf, refg in STRATA:
        rates = {r["group"]: r for r in load(rf)}
        R = rates[refg]
        ref_ev = {"all": int(R["deaths"]), "resp": int(R["resp_deaths"]), "exac": 10 ** 9}
        rows.append(Section(title))
        rows.append([f"\u2003{refg} (reference)", f"{int(R['n']):,}", f"{int(R['deaths']):,}", "1.00",
                     "1.00"])
        for g in ORDER:
            c = {o: cru[(title, g, o)] for o in ("all", "resp", "exac")}
            ev = {o: int(float(c[o]["events"])) for o in c}
            assert ev["all"] == int(rates[g]["deaths"]) and ev["resp"] == int(rates[g]["resp_deaths"]), g
            rows.append(["\u2003" + g, f"{int(rates[g]['n']):,}", f"{ev['all']:,}",
                         cell(c["all"], ev["all"], ref_ev["all"]),
                         cell(c["exac"], ev["exac"], ref_ev["exac"])])
    # With respiratory mortality out, every cell clears the floor; the legend
    # carries no flag note, so a flagged cell appearing later must stop the build.
    assert not any(FLAG in str(v) for r in rows if not isinstance(r, Section) for v in r), \
        "S7 has a cell under the event floor; restore the flag note in its legend"
    add_table(doc, ["Group", "n", "Deaths", "All-cause mortality rate ratio (95% CI)",
                    "Exacerbation rate ratio (95% CI)"],
              rows, [2.00, 0.70, 0.80, 1.50, 1.50])
    legend(doc, label,
           "Participants were cross-classified by MD-COPD and the ESI classification within "
           "strata defined by airflow-limitation status. Among participants with preserved "
           "spirometry, those classified as noCOPD by both approaches served as the reference; "
           "among participants with airflow limitation, those classified as AFL-only by both "
           "approaches served as the reference. Unadjusted rate ratios are the event rate (events per "
           "100 person-years) in each group divided by that in the corresponding reference; confidence "
           "intervals are exact Poisson intervals for mortality and subject-level bootstrap "
           "intervals for respiratory exacerbations. CT-only-COPD = classified as COPD by "
           "MD-COPD only; ESI-only-COPD = classified as COPD by the ESI classification only; "
           "Both-COPD = classified as COPD by both; AFL-only = airflow limitation without "
           "other criteria; CI = confidence interval. Respiratory mortality is not shown "
           "because of the small number of respiratory deaths.")

def figure_width(meta_path, default=CONTENT_WIDTH_IN):
    """Content width a figure was rendered for, from the sidecar its script
    writes. Absent a sidecar the figure is a portrait one."""
    if not os.path.exists(meta_path):
        return default
    for line in open(meta_path):
        k, _, v = line.strip().partition("=")
        if k == "content_width_in":
            w = float(v)
            if not (CONTENT_WIDTH_IN <= w <= 9.0 + 1e-6):
                raise SystemExit(f"{meta_path}: content width {w} outside 6.5 to 9 in")
            return w
    raise SystemExit(f"{meta_path}: no content_width_in")


def new_section(doc, landscape):
    """Start a new page in the given orientation, 1 in margins either way."""
    from docx.enum.section import WD_ORIENT, WD_SECTION
    sec = doc.add_section(WD_SECTION.NEW_PAGE)
    sec.orientation = WD_ORIENT.LANDSCAPE if landscape else WD_ORIENT.PORTRAIT
    sec.page_width, sec.page_height = ((Inches(11), Inches(8.5)) if landscape
                                       else (Inches(8.5), Inches(11)))
    for m in ("left_margin", "right_margin", "top_margin", "bottom_margin"):
        setattr(sec, m, Inches(1))
    return sec


def read_legend(stem):
    """Legend text from a figure's sidecar: its title sentence, then its body.
    The title used to be dropped, leaving a legend that opened on panel (A)."""
    lines = [l.strip() for l in open(os.path.join(FIGS, stem + "_legend.md")) if l.strip()]
    m = re.match(r"^\*\*(?:Supplemental )?Figure S?\d+\.\s*(.*?)\*\*$", lines[0])
    if not m:
        raise SystemExit(f"{stem}_legend.md: first line is not a bold figure title")
    return f"{m.group(1).strip()} {CLAIM_ID.sub('', lines[-1])}"


def add_figure(doc, png, label, text, width=CONTENT_WIDTH_IN):
    doc.add_picture(png, width=Inches(width))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    doc.paragraphs[-1].paragraph_format.keep_with_next = True   # figure stays with its legend
    legend(doc, label, text)


def check_references():
    """The reference list and the citations in the prose must agree, in both
    directions. A dangling citation and an uncited entry are both defects that
    reach reviewers, and renumbering is exactly when they appear."""
    body = ""
    for fn, stop in (("ABSTRACT.md", None), ("INTRODUCTION.md", None),
                     ("METHODS.md", "## Still to write"),
                     ("RESULTS.md", "## Open"), ("DISCUSSION.md", None)):
        t = open(os.path.join(HERE, fn)).read()
        body += t.split(stop)[0] if stop and stop in t else t
    cited = set()
    for m in re.finditer(r"\((\d+(?:\s*[,\u2013-]\s*\d+)*)\)", body):
        for part in m.group(1).split(","):
            part = part.strip()
            if re.fullmatch(r"\d+", part):
                cited.add(int(part))
            else:
                r = re.fullmatch(r"(\d+)\s*[\u2013-]\s*(\d+)", part)
                if r:
                    cited.update(range(int(r.group(1)), int(r.group(2)) + 1))
    listed = set()
    for line in open(os.path.join(HERE, "REFERENCES.md")):
        m = re.match(r"^(\d+)\.\s+\S", line)
        if m:
            listed.add(int(m.group(1)))
    dangling = sorted(cited - listed)
    uncited = sorted(listed - cited)
    gaps = [n for n in range(1, max(listed) + 1) if n not in listed] if listed else []
    if dangling:
        raise SystemExit(f"prose cites {dangling}, absent from REFERENCES.md")
    if gaps:
        raise SystemExit(f"REFERENCES.md skips {gaps}; numbering must be contiguous")
    if uncited:
        print(f"  note: references {uncited} listed but never cited")
    return len(listed)


def read_titlepage():
    """TITLEPAGE.md is the single source of truth for the title, author list,
    affiliations and key words. It is Pete's text; nothing regenerates it."""
    sections, key = {}, None
    for line in open(os.path.join(HERE, "TITLEPAGE.md")):
        line = line.rstrip("\n")
        if line.startswith("<!--") or line.startswith("     ") and key is None:
            continue
        if line.startswith("# "):
            key = line[2:].strip()
            sections[key] = []
        elif key and line.strip():
            sections[key].append(line.strip())
    for k in ("TITLE", "AUTHORS", "AFFILIATIONS", "KEYWORDS"):
        if not sections.get(k):
            raise SystemExit(f"TITLEPAGE.md is missing the {k} section")
    return sections


def add_front_matter(doc):
    tp = read_titlepage()

    p = doc.add_paragraph()
    r = p.add_run(" ".join(tp["TITLE"]))
    r.bold = True
    r.font.name, r.font.size = FONT_NAME, Pt(12)

    p = doc.add_paragraph()
    r = p.add_run(" ".join(tp["AUTHORS"]))
    r.font.name, r.font.size = FONT_NAME, Pt(BODY_FS)

    doc.add_paragraph()
    for aff in tp["AFFILIATIONS"]:
        p = doc.add_paragraph()
        r = p.add_run(aff)
        r.font.name, r.font.size = FONT_NAME, Pt(BODY_FS)

    doc.add_paragraph()
    p = doc.add_paragraph()
    r = p.add_run("Key words:")
    r.bold = True
    r.font.name, r.font.size = FONT_NAME, Pt(BODY_FS)
    r = p.add_run(" " + " ".join(tp["KEYWORDS"]))
    r.font.name, r.font.size = FONT_NAME, Pt(BODY_FS)


def heading_on_new_page(doc, text):
    """Start a section on its own page. page_break_before travels with the
    heading, so reflow above it cannot leave the break stranded mid-page the
    way a separately inserted break can."""
    p = doc.add_paragraph(text, style="Heading 1")
    p.paragraph_format.page_break_before = True
    return p


def main():
    pjc_guard.check("The manuscript build")
    word_guard.check([OUT], "The manuscript build")
    prose_guard.check("The manuscript build")
    prose_guard.check_owned("The manuscript build")
    display_order.check(HERE, {"Table": ["1"],
                               "Figure": [str(i) for i in range(1, 5)]},
                        "The manuscript build")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    doc = init_document()

    add_front_matter(doc)

    heading_on_new_page(doc, "ABSTRACT")
    add_prose(doc, os.path.join(HERE, "ABSTRACT.md"))
    heading_on_new_page(doc, "INTRODUCTION")
    n_i = add_prose(doc, os.path.join(HERE, "INTRODUCTION.md"))
    doc.add_paragraph("METHODS", style="Heading 1")
    n_m = add_prose(doc, os.path.join(HERE, "METHODS.md"), skip_after="Still to write")
    doc.add_paragraph("RESULTS", style="Heading 1")
    n_r = add_prose(doc, os.path.join(HERE, "RESULTS.md"), skip_after="Open")

    doc.add_paragraph("DISCUSSION", style="Heading 1")
    n_d = add_prose(doc, os.path.join(HERE, "DISCUSSION.md"))

    doc.add_paragraph("REFERENCES", style="Heading 1")
    n_ref = check_references()
    for line in open(os.path.join(HERE, "REFERENCES.md")):
        if re.match(r"^\d+\.\s+\S", line):
            doc.add_paragraph(line.strip())

    doc.add_page_break()
    doc.add_paragraph("TABLES", style="Heading 1")
    t_classifications(doc, "Table 1.")

    # Each figure declares its own content width. A figure rendered for a
    # landscape page must be placed at that width, or every font in it lands
    # smaller than the size the figure was validated at, so the page turns
    # where a width needs it to. Numbering follows Massimo's 2026-09-20 draft.
    doc.add_page_break()
    doc.add_paragraph("FIGURES", style="Heading 1")
    landscape_now = False
    for n, stem in ((1, "figure1_esi_ct"), (2, "figure2_flow"),
                    (3, "figure3_group_risk"), (4, "figure4_discord_risk")):
        w = figure_width(os.path.join(FIGS, stem + ".meta"))
        want = w > CONTENT_WIDTH_IN + 0.01
        if want != landscape_now:
            new_section(doc, landscape=want)
            landscape_now = want
        add_figure(doc, os.path.join(FIGS, stem + ".png"), f"Figure {n}.",
                   read_legend(stem), width=w)
    if landscape_now:
        new_section(doc, landscape=False)

    doc.save(OUT)
    print(f"wrote {OUT}\n  {n_i} Introduction, {n_m} Methods, {n_r} Results, "
          f"{n_d} Discussion paragraphs, {n_ref} references")
    # A floor against a source file failing to render, not a target length.
    # Massimo's Introduction is three paragraphs by choice (2026-09-20); v3 merged
    # two pairs of Results paragraphs, leaving ten.
    assert n_i >= 3 and n_m > 10 and n_r >= 8 and n_d > 5, \
        "prose came out suspiciously short"


if __name__ == "__main__":
    main()
