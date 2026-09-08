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

ASSETS = os.path.join(HERE, "assets")
FIGS   = os.path.join(HERE, "figures")
OUT    = os.path.join(HERE, "manuscript",
                      "CT-free MD-COPD manuscript draft v1.docx")
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
               "S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}

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
    return t


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
def table1(doc):
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
        ["NoCT-MD-COPD", "dyspnea, SGRQ, chronic bronchitis (≥2)",
         n("S3", "noCOPD"), n("S3", "AFL-only"), n("S3", "COPD-minor"), n("S3", "COPD-major")],
        ["ESI-MD-COPD", esi_desc,
         n("S4", "noCOPD"), n("S4", "AFL-only"), n("S4", "COPD-minor"), n("S4", "COPD-major")]]
    add_table(doc, ["Classification", "Minor criteria", "noCOPD", "AFL-only",
                    "COPD-minor", "COPD-major"],
              rows, [1.25, 1.95, 0.72, 0.92, 0.84, 0.82])
    legend(doc, "Table 1.",
           f"The four classifications applied to the same {n_total:,} participants. "
           "The major criterion is post-bronchodilator FEV₁/FVC below 0.70 in all "
           "four, so no participant moves between the airflow-limitation categories "
           "and the preserved-spirometry ones. MD-COPD is the reference NoCT-MD-COPD "
           "and ESI-MD-COPD are compared against.")


def table2(doc):
    """Cross-classification of each CT-free classification against MD-COPD,
    with per-category F1 folded in beside the diagonal it summarizes."""
    x = load("crossclass.csv")
    f1 = {r["category"]: r for r in load("f1_by_category.csv")}
    O = ["noCOPD", "AFL-only", "COPD-minor", "COPD-major"]
    cell = {(r["schema"], r["row_cat"], r["col_cat"]): int(r["n"]) for r in x}

    rows = []
    for schema, name, f1key in (("S3", "NoCT-MD-COPD", "f1_noct"),
                                ("S4", "ESI-MD-COPD", "f1_esi")):
        for i, rc in enumerate(O):
            rows.append([
                name if i == 0 else "", rc,
                *[f"{cell[(schema, rc, cc)]:,}" for cc in O],
                f"{float(f1[rc][f1key]):.2f}"])
    add_table(doc, ["Classification", "Assigned to",
                    *[f"MD-COPD {c}" for c in O], "F1"],
              rows, [1.10, 1.00, 0.92, 0.86, 0.98, 0.96, 0.68])
    legend(doc, "Table 2.",
           "Each CT-free classification cross-classified against MD-COPD. Rows are "
           "the category assigned by the CT-free classification, columns the MD-COPD "
           "category; the diagonal is agreement. F1 is the per-category harmonic mean "
           "of precision and recall against MD-COPD, and the mean of the four is the "
           "macro-averaged F1 the thresholds were fitted on. Both classifications move "
           "participants out of COPD-major into AFL-only, 833 without CT and 350 with "
           "ESI, and that column is where the two differ. "
           "AFL-only, airflow limitation without other criteria; F1, harmonic mean of "
           "precision and recall.")


def table3(doc):
    """Every group of every multidimensional classification against one common
    reference: the participants all three agree are noCOPD. The own-noCOPD
    references used elsewhere differ in composition between classifications,
    so estimates under one are not on the same scale as estimates under
    another. Crude ratios lead; adjusted estimates follow. A cell with fewer
    events than the analysis floor keeps its point estimate and loses its
    interval, because the interval would convey precision the data lack."""
    adj = {(r["schema"], r["category"]): r for r in load("consensus_ref_risk.csv")}
    cru = {(r["schema"], r["category"], r["outcome"]): r
           for r in load("consensus_ref_crude.csv")}
    ref = load("consensus_ref_group.csv")[0]
    NM = {"S2": "MD-COPD", "S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}
    ORDER = ["AFL-only", "COPD-minor", "COPD-major"]
    FLAG = "\u2020"

    def crude(s_, g, outcome):
        r = cru[(s_, g, outcome)]
        if r["few_events"].upper() in ("TRUE", "T"):
            return f"{float(r['rr']):.2f}{FLAG}"
        return (f"{float(r['rr']):.2f} "
                f"({float(r['lo']):.2f}\u2013{float(r['hi']):.2f})")

    def adjusted(s_, g, est, lo, hi, flag):
        r = adj[(s_, g)]
        if r[flag].upper() in ("TRUE", "T"):
            return f"{float(r[est]):.2f}{FLAG}"
        return (f"{float(r[est]):.2f} "
                f"({float(r[lo]):.2f}\u2013{float(r[hi]):.2f})")

    rows = [["Common reference", f"{int(ref['deaths']):,}", "1.00", "reference",
             f"{int(ref['resp_deaths']):,}", "1.00", "reference",
             "1.00", "reference"]]
    n_flagged = 0
    for s_ in ("S2", "S3", "S4"):
        for i, g in enumerate(ORDER):
            r = adj[(s_, g)]
            n_flagged += sum(
                cru[(s_, g, o)]["few_events"].upper() in ("TRUE", "T")
                for o in ("all", "resp", "exac"))
            rows.append([
                f"{NM[s_]} {g}" if i == 0 else g,
                f"{int(r['deaths']):,}",
                crude(s_, g, "all"),
                adjusted(s_, g, "all_HR", "all_LCI", "all_UCI", "all_few_events"),
                f"{int(r['resp_deaths']):,}",
                crude(s_, g, "resp"),
                adjusted(s_, g, "resp_HR", "resp_LCI", "resp_UCI", "resp_few_events"),
                crude(s_, g, "exac"),
                adjusted(s_, g, "exac_IRR", "exac_LCI", "exac_UCI", "all_few_events")])
    add_table(doc, ["Classification and group", "Deaths",
                    "All-cause RR", "All-cause HR (95% CI)",
                    "Resp. deaths", "Resp. RR", "Resp. HR (95% CI)",
                    "Exac. RR", "Exac. IRR (95% CI)"],
              rows, [1.24, 0.42, 0.62, 0.86, 0.48, 0.62, 0.86, 0.58, 0.82])
    afl = {s_: adj[(s_, "AFL-only")] for s_ in ("S2", "S3", "S4")}
    legend(doc, "Table 3.",
           "Every group of the three multidimensional classifications estimated "
           "against one common reference: the "
           f"{int(ref['n_cohort']):,} participants all three classifications agree "
           "are noCOPD. Because every member of that group is noCOPD under each "
           "classification, it is disjoint from all the groups shown, and estimates "
           "under one classification are on the same scale as estimates under "
           "another. Crude rate ratios (RR) are the observed event rate in the group "
           "divided by the rate in the reference. Adjusted models carry age, sex, "
           "race, current smoking status, pack-years and body mass index, with prior "
           "exacerbation frequency added for exacerbations. Respiratory deaths in "
           f"the AFL-only group were {int(afl['S2']['resp_deaths'])} under MD-COPD, "
           f"{int(afl['S3']['resp_deaths'])} under NoCT-MD-COPD and "
           f"{int(afl['S4']['resp_deaths'])} under ESI-MD-COPD. "
           f"{FLAG} fewer than 10 events in the cell: the point estimate is given "
           "without an interval, which would convey precision the data do not "
           "carry. AFL-only, airflow limitation without other criteria; RR, rate "
           "ratio; HR, hazard ratio; IRR, incidence rate ratio; CI, confidence "
           "interval.")


def table4(doc):
    """Cross-classification of MD-COPD against ESI-MD-COPD, preserved
    spirometry. Rates and adjusted estimates in one table so the effect of
    adjustment is readable."""
    rates = {r["group"]: r for r in load("discord_rates.csv")}
    adj = {r["group"]: r for r in load("discord_adjusted.csv")}
    order = ["Both-noCOPD", "ESI-only-COPD", "CT-only-COPD", "Both-COPD"]

    def ci(g, est, lo, hi):
        if g not in adj:
            return "reference"
        r = adj[g]
        # A cell the analysis marked not estimable must print as such, never
        # as a number. See the zero-event guard in the analysis report.
        if r[est] in ("", "NA") or r[lo] in ("", "NA"):
            return "not estimable"
        return f"{float(r[est]):.2f} ({float(r[lo]):.2f}–{float(r[hi]):.2f})"

    rows = []
    for g in order:
        rr = rates[g]
        rows.append([
            g,
            f"{int(rr['n']):,}",
            f"{float(rr['rate_all_100py']):.2f}",
            ci(g, "all_HR", "all_LCI", "all_UCI"),
            f"{float(rr['rate_resp_100py']):.2f}",
            ci(g, "resp_HR", "resp_LCI", "resp_UCI"),
            f"{float(rr['rate_exac_100py']):.1f}",
            ci(g, "exac_IRR", "exac_LCI", "exac_UCI")])
    # Nine columns split the group names and the counts across lines. Prior
    # exacerbation burden is one number per group and is already given in the
    # text, so it moves to the legend rather than squeezing the rest.
    prior_means = ", ".join(f"{float(rates[g]['prior_exac_mean']):.2f}"
                            for g in order[:-1]) + \
        f" and {float(rates[order[-1]]['prior_exac_mean']):.2f}"
    add_table(doc, ["Group", "n", "All-cause rate", "All-cause HR (95% CI)",
                    "Respiratory rate", "Respiratory HR (95% CI)",
                    "Exacerbation rate", "Exacerbation IRR (95% CI)"],
              rows, [1.30, 0.46, 0.58, 1.02, 0.58, 1.02, 0.58, 0.96])
    legend(doc, "Table 4.",
           "Participants cross-classified by MD-COPD and ESI-MD-COPD within the "
           "preserved-spirometry subgroup, where the two can disagree about a "
           "diagnosis. CT-only-COPD is what ESI-MD-COPD misses; ESI-only-COPD is "
           "what it adds. All rates are observed events per 100 person-years. Adjusted "
           "estimates are against the Both-noCOPD group and carry age, sex, race, "
           "current smoking status, pack-years and body mass index, with prior "
           "exacerbation frequency added for exacerbations. Mean exacerbation count "
           f"in the year before enrollment was {prior_means} across the "
           "four groups in the order shown. The respiratory estimate for "
           "CT-only-COPD is not estimable because that group had no respiratory "
           "deaths during follow-up. "
           "AFL-only, airflow limitation without other criteria; HR, hazard ratio; "
           "IRR, incidence rate ratio; CI, confidence interval.")


def table5(doc):
    """ESI's discrimination of the two visual CT criteria, by stratum. This is
    the claim that explains where an ESI criterion helps. The comparison with
    FEV1/FVC belongs in the Supplement: FEV1/FVC cannot serve as the
    replacement criterion at all, so putting the two side by side in the main
    text invites a comparison the framework does not permit."""
    au = load("esi_ct_auc.csv")
    ORDER = ["All participants", "Airflow limitation", "Preserved spirometry"]
    rows, seen = [], set()
    for crit in ("Visual emphysema", "Airway wall thickening"):
        for st in ORDER:
            r = next(x for x in au if x["criterion"] == crit and x["stratum"] == st)
            rows.append([crit if crit not in seen else "", st,
                         f"{int(r['n']):,}", f"{float(r['prevalence']):.1f}",
                         f"{float(r['auc_ESI']):.2f}"])
            seen.add(crit)
    add_table(doc, ["CT criterion", "Stratum", "n", "Prevalence (%)",
                    "AUC for ESI"],
              rows, [1.40, 1.46, 0.76, 1.10, 1.78])
    legend(doc, "Table 5.",
           "How well ESI discriminates each of the two visual CT criteria it "
           "replaces, overall and within stratum of airflow limitation. ESI "
           "discriminates both criteria among participants with airflow "
           "limitation, where the CT criteria determine whether a participant is "
           "COPD-major or AFL-only, and does not among participants with "
           "preserved spirometry, where the COPD-minor pathway operates. The "
           "pooled values reflect the mixture of the two strata rather than "
           "detection within either. Mean ESI at each level of the two scales is "
           "given in Supplemental Table S11 and the corresponding values for "
           "FEV\u2081/FVC in Supplemental Table S12. "
           "AUC, area under the receiver operating characteristic curve.")


def add_figure(doc, png, label, text, width=CONTENT_WIDTH_IN):
    doc.add_picture(png, width=Inches(width))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
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
    prose_guard.check("The manuscript build")
    prose_guard.check_owned("The manuscript build")
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
    table1(doc)
    doc.add_paragraph()
    table2(doc)
    table3(doc)
    table4(doc)
    table5(doc)

    doc.add_page_break()
    doc.add_paragraph("FIGURES", style="Heading 1")
    with open(os.path.join(FIGS, "figure1_flow_legend.md")) as f:
        fig1 = [l for l in f.read().split("\n") if l.strip()]
    add_figure(doc, os.path.join(FIGS, "figure1_flow.png"), "Figure 1.",
               CLAIM_ID.sub("", fig1[-1]))
    ref = load("consensus_ref_group.csv")[0]
    for i, (png, grp, note) in enumerate([
            ("figure2_aflonly.png", "AFL-only",
             "This is the group that withholds a COPD diagnosis from "
             "participants with airflow limitation, so it is the group a "
             "CT-free classification has to keep at low risk."),
            ("figure3_copdminor.png", "COPD-minor",
             "This is the group a replacement criterion must reach among "
             "participants with preserved spirometry."),
            ("figure4_copdmajor.png", "COPD-major",
             "Estimates are largest under NoCT-MD-COPD because that "
             "classification moved 833 of this group's members into AFL-only, "
             "leaving a smaller and more severe group behind.")], start=2):
        add_figure(doc, os.path.join(FIGS, png), f"Figure {i}.",
                   f"Crude (open circles) and adjusted (filled circles) risk "
                   f"for the {grp} group under each multidimensional "
                   f"classification, against a reference common to all three: "
                   f"the {int(ref['n_cohort']):,} participants every "
                   f"classification assigns to noCOPD. A common reference makes "
                   f"an estimate under one classification comparable with an "
                   f"estimate under another. Panels carry separate x scales "
                   f"because the three outcomes differ in magnitude; the "
                   f"comparison the figure supports is between classifications "
                   f"within a panel. A point drawn without an interval had "
                   f"fewer than 10 events in that group, so no interval was "
                   f"estimated. {note} AFL-only, airflow limitation without "
                   f"other criteria.")

    doc.save(OUT)
    print(f"wrote {OUT}\n  {n_i} Introduction, {n_m} Methods, {n_r} Results, "
          f"{n_d} Discussion paragraphs, {n_ref} references")
    # A floor against a source file failing to render, not a target length.
    # Pete's Introduction is four paragraphs by choice.
    assert n_i >= 4 and n_m > 10 and n_r > 10 and n_d > 5, \
        "prose came out suspiciously short"


if __name__ == "__main__":
    main()
