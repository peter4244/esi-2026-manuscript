import pjc_guard
import prose_guard
import word_guard
import display_order
from supp_registry import SUPP_KEYS
#!/usr/bin/env python3
"""Build the CT-free supplement .docx from source.

Same contract as build_manuscript.py: prose here, tables from artifacts,
nothing hand-edited into the document. Table numbering follows order of first
citation in the main text, which is what SUPP_ORDER encodes; the checker at the
end fails if the main text cites a table this file does not produce, or the
reverse, so the two cannot drift apart.

Usage:  python3 /abs/path/to/ctfree/build_supplement.py
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# ROOT holds the retired build_manuscript.py of the earlier paper, which would
# shadow this one's. HERE goes first so the import resolves to ctfree/.
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from docx.shared import Pt                                   # noqa: E402
from build_manuscript import (init_document, add_table, legend,  # noqa: E402
                              emphasis, ASSETS, CATS, read_titlepage,
                              t_risk_common_ref, t_discord_risk, Section,
                              add_figure, read_legend, figure_width, FIGS)

OUT = os.path.join(HERE, "manuscript", "CT-free MD-COPD supplement draft v1.docx")
# SUPP_ORDER is defined after the table functions, from SUPP_TABLES.


def load(path, name):
    with open(os.path.join(path, name)) as f:
        return list(csv.DictReader(f))


def heading(doc, text):
    doc.add_paragraph(text, style="Heading 2")


def para(doc, text):
    emphasis(doc.add_paragraph(), text)


# --------------------------------------------------------------------------
def s1_baseline(doc, num):
    heading(doc, f"Supplemental Table {num}. Baseline characteristics")
    rows = load(ASSETS, "supp_baseline.csv")
    keep = [("stratum", "Stratum"), ("n", "n"), ("age", "Age"),
            ("pct_female", "Female"), ("pct_current", "Current smoker"),
            ("pack_years", "Pack-years"), ("FEV1_pp", "FEV₁ %pred"), ("ESI", "ESI")]
    add_table(doc, [h for _, h in keep],
              [[r[k] for k, _ in keep] for r in rows],
              [0.86, 0.60, 0.86, 0.78, 1.00, 0.86, 0.84, 0.70])
    n_overall = next(r["n"] for r in rows if r["stratum"] == "Overall")
    legend(doc, f"Table {num}.",
           f"Baseline characteristics of the {int(n_overall):,} analytic cohort "
           "subjects by GOLD stratum. Values are mean (SD) unless marked as a "
           "percentage. PRISm = preserved ratio impaired spirometry.")


def s4_sweep(doc, num):
    """The parameter sweep behind the threshold selection."""
    heading(doc, f"Supplemental Table {num}. Threshold selection")
    rows = []
    for r in load(ASSETS, "metric_sweep.csv"):
        sel = r["selected"].upper() == "TRUE"
        lab = r["label"] + (" (selected)" if sel else "")
        rows.append([lab, f"{int(r['n_noCOPD']):,}", f"{int(r['n_aflonly']):,}",
                     f"{int(r['n_minor']):,}", f"{int(r['n_major']):,}",
                     f"{float(r['macroF1']):.3f}", f"{float(r['bal_acc']):.3f}",
                     f"{float(r['kappa']):.3f}"])
    add_table(doc, ["Rule", "noCOPD", "AFL-only", "COPD-minor", "COPD-major",
                    "Macro-F1", "Balanced accuracy", "Cohen's κ"],
              rows, [1.42, 0.68, 0.72, 0.80, 0.80, 0.72, 0.72, 0.64])
    # The legend says the selected rule has the highest macro-F1 of its schema.
    for sch in ("S3", "S4"):
        rs = [r for r in load(ASSETS, "metric_sweep.csv") if r["schema"] == sch]
        sel = [r for r in rs if r["selected"].upper() == "TRUE"]
        assert len(sel) == 1 and float(sel[0]["macroF1"]) == max(float(r["macroF1"]) for r in rs), \
            f"{sch}: selected rule is not the macro-F1 maximum"
    legend(doc, f"Table {num}.",
           "Category sizes and each candidate selection metric across the "
           "thresholds examined, against the MD-COPD reference in the first row. "
           "The selected rules had the highest macro-averaged F1, which weights "
           "the four categories equally. "
           "AFL-only = airflow limitation without other criteria.")


def cell_n(rows, schema, row_cat, col_cat):
    """One cell of the cross-classification, read from the artifact."""
    for r in rows:
        if (r["schema"] == schema and r["row_cat"] == row_cat
                and r["col_cat"] == col_cat):
            return int(r["n"])
    raise SystemExit(f"crossclass.csv has no {schema} {row_cat}/{col_cat} cell")


def data_files(doc):
    heading(doc, "COPDGene files used")
    para(doc, "Analyses in this manuscript draw on the following COPDGene "
              "distribution files.")
    for line in [
        "**COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24**: the main COPD phenotype file in "
        "long format, used for baseline characteristics, spirometry, the visual CT "
        "scores, the symptom criteria and the cohort exclusions.",
        "**COPDGene_Multidimensional_COPD_plus**: the per-subject MD-COPD "
        "classification from the source report (11), used as the MD-COPD reference.",
        "**COPDGene_VitalStatus_SM_NS_Sep23**: vital status and follow-up time, "
        "used for all-cause mortality.",
        "**COPDGene_Mort_COD_Adj**: adjudicated underlying cause of death, used "
        "for respiratory mortality.",
        "**LFU_SidLevel_Comorbd**: the COPDGene Longitudinal Follow-up program "
        "dataset, used for prospective exacerbation counts and years of follow-up.",
    ]:
        para(doc, line)
    para(doc, "Emphysema Severity Index values were computed from the COPDGene "
              "spirometric flow-volume curves as described in the main text.")


def s6_fev1_decline(doc, num):
    heading(doc, f"Supplemental Table {num}. Longitudinal FEV\u2081 decline by group")
    rows_in = load(ASSETS, "fev1_decline.csv")
    name = {"S1": "Fixed ratio", "S2": "MD-COPD",
            "S3": "NoCT classification", "S4": "ESI classification"}
    rows, seen = [], set()
    for r in rows_in:
        sc = r["schema"]; p_ = float(r["p"])
        rows.append([name.get(sc, sc) if sc not in seen else "", r["category"],
                     f"{int(r['n_subj']):,}",
                     f"{float(r['est_mL_yr']):.1f} "
                     f"({float(r['lo']):.1f} to {float(r['hi']):.1f})",
                     "<0.001" if p_ < 0.001 else f"{p_:.3f}"])
        seen.add(sc)
    add_table(doc, ["Classification", "Group", "n",
                    "Difference in decline, mL/yr (95% CI)", "P"],
              rows, [1.20, 1.10, 0.66, 2.44, 1.10])
    legend(doc, f"Table {num}.",
           "Difference in annual FEV\u2081 change against the common noCOPD "
           "reference, from linear mixed models over visits 1 to 3 with a "
           "random intercept per subject, adjusted for height, sex, race, age, "
           "smoking status, pack-years and baseline post-bronchodilator "
           "FEV\u2081, entered as its interaction with follow-up time. A negative "
           "value is faster decline.")


def s12_esi_ct_levels(doc, num):
    """Dose-response of ESI across the two visual CT scales."""
    heading(doc, f"Supplemental Table {num}. Mean ESI by visual CT severity")
    rows, seen = [], set()
    for r in load(ASSETS, "esi_ct_levels.csv"):
        c = r["criterion"]
        rows.append([c if c not in seen else "", r["label"],
                     f"{int(r['n']):,}", f"{float(r['mean_ESI']):.2f}"])
        seen.add(c)
    add_table(doc, ["CT criterion", "Level", "n", "Mean ESI"],
              rows, [1.70, 1.90, 1.30, 1.60])
    legend(doc, f"Table {num}.",
           "Mean ESI at each level of the two visual CT criteria. The MD-COPD framework treats "
           "emphysema as present at mild or greater and wall thickening as "
           "present when definite. Discrimination of these criteria by ESI is "
           "given in Table 2 of the main text.")


def s_crossclass_agreement(doc, num):
    """Cross-classification of each CT-free classification against MD-COPD,
    with the agreement the Results quote: the share of each classification's
    assignments that MD-COPD places in the same group."""
    heading(doc, f"Supplemental Table {num}. Cross-classification against MD-COPD")
    x = load(ASSETS, "crossclass.csv")
    f1 = {r["category"]: r for r in load(ASSETS, "f1_by_category.csv")}
    ag = {r["category"]: r for r in load(ASSETS, "agreement_by_group.csv")}
    rows = []
    for s_, name, key in (("S3", "NoCT classification", "noct"), ("S4", "ESI classification", "esi")):
        for i, rc in enumerate(CATS):
            vals = [cell_n(x, s_, rc, cc) for cc in CATS]
            n_ = sum(vals)
            rows.append([name if i == 0 else "", rc] + [f"{v:,}" for v in vals] +
                        [f"{n_:,}", f"{100 * vals[i] / n_:.1f}",
                         f"{float(f1[rc]['f1_' + key]):.2f}"])
    add_table(doc, ["Classification", "Assigned to", *[f"MD-COPD {c}" for c in CATS],
                    "Assigned, n", "Agreement, %", "F1"],
              rows, [1.10, 0.80, 0.62, 0.62, 0.62, 0.62, 0.64, 0.70, 0.78])
    ps = [float(ag[c]["p_boot"]) for c in CATS]
    floor_p = 2 / min(int(ag[c]["B_eff"]) for c in CATS)
    p_txt = (f"P < {floor_p:.3f} in each of the four groups" if all(p == 0 for p in ps)
             else "; ".join(f"{c} P < {floor_p:.3f}" if p == 0 else f"{c} P = {p:.3f}"
                            for c, p in zip(CATS, ps)))
    legend(doc, f"Table {num}.",
           "Each CT-free classification cross-classified against MD-COPD. Rows are the "
           "group each classification assigned, columns the MD-COPD group, and the "
           "diagonal is agreement. Agreement is the percentage of subjects assigned "
           "to a group that MD-COPD places in the same group. F1 is the harmonic mean of "
           "that percentage and its converse, the percentage of the MD-COPD group the "
           "classification reproduces. Agreement differed between "
           f"the ESI and NoCT classifications by paired bootstrap ({p_txt}). "
           "AFL-only = airflow limitation without other criteria.")


def s_groups_crude(doc, num):
    """Crude risk of every diagnostic group under each multidimensional
    classification against the common reference, and each CT-free
    classification against MD-COPD by a paired bootstrap. Crude only
    (Pete, 2026-09-11); all three groups (Pete, 2026-09-13)."""
    heading(doc, f"Supplemental Table {num}. Crude risk of each diagnostic group under "
                 "each classification")
    cru = {(r["schema"], r["category"], r["outcome"]): r for r in load(ASSETS, "consensus_ref_crude.csv")}
    cmp_ = {(r["schema"], r["category"], r["outcome"]): r for r in load(ASSETS, "group_vs_mdcopd.csv")
            if r["type"] == "crude"}
    ref = load(ASSETS, "consensus_ref_group.csv")[0]
    NM = {"S2": "MD-COPD", "S3": "NoCT classification", "S4": "ESI classification"}
    OUTC = (("all", "All-cause mortality"), ("resp", "Respiratory mortality"), ("exac", "Exacerbations"))
    FLAG = "\u2020"
    ci = lambda v, lo, hi: f"{float(v):.2f} ({float(lo):.2f}\u2013{float(hi):.2f})"
    TRUE = ("TRUE", "T")
    rows = []
    for g in ("AFL-only", "COPD-minor", "COPD-major"):
        rows.append(Section(g))
        for o, olab in OUTC:
            for k, s_ in enumerate(("S2", "S3", "S4")):
                r = cru[(s_, g, o)]
                own = (f"{float(r['rr']):.2f}{FLAG}" if r["few_events"].upper() in TRUE
                       else ci(r["rr"], r["lo"], r["hi"]))
                lead = olab if k == 0 else ""
                if s_ == "S2":
                    rows.append([lead, NM[s_], f"{int(float(r['events'])):,}", own, "reference", ""])
                    continue
                x = cmp_[(s_, g, o)]
                if x["few_events"].upper() in TRUE:
                    vs, pt = f"{float(x['ratio_of_ratios']):.2f}{FLAG}", ""
                else:
                    p_ = float(x["p_boot"]); floor = 2 / int(x["B_eff"])
                    vs = ci(x["ratio_of_ratios"], x["lo"], x["hi"])
                    pt = f"<{floor:.3f}" if p_ == 0 else (f"{p_:.3f}" if p_ < 0.1 else f"{p_:.2f}")
                rows.append([lead, NM[s_], f"{int(float(r['events'])):,}", own, vs, pt])
    add_table(doc, ["Outcome", "Classification", "Events", "Crude ratio versus the common reference (95% CI)",
                    "Ratio versus MD-COPD (95% CI)", "P"],
              rows, [1.25, 1.35, 0.55, 1.35, 1.35, 0.65])
    legend(doc, f"Table {num}.",
           "Each diagnostic group of the three multidimensional classifications against the common "
           f"reference, the {int(ref['n_cohort']):,} subjects all three classifications assign to "
           "noCOPD. Crude rate ratios are the observed event rate in the group divided by the rate in "
           "the reference, with exact Poisson intervals for deaths and subject-bootstrap intervals for "
           "exacerbations. The ratio versus MD-COPD divides each CT-free classification's crude ratio by "
           "that of the same group under MD-COPD; its interval and two-sided P come from a paired "
           "subject bootstrap of 1,000 resamples, refitting every classification on the same draw. "
           f"{FLAG} fewer than 10 events in the group, or, for a ratio versus MD-COPD, in either group "
           "compared: the estimate is given without an interval or P. Events are deaths for the "
           "mortality outcomes and exacerbations for the exacerbation outcome. AFL-only = airflow "
           "limitation without other criteria; CI = confidence interval.")


def s_risk_common_ref(doc, num):
    heading(doc, f"Supplemental Table {num}. Adjusted risk of each group against the common "
                 "noCOPD reference")
    t_risk_common_ref(doc, label=f"Table {num}.")


def s_discord_risk(doc, num):
    heading(doc, f"Supplemental Table {num}. Risk in the COPD-diagnosed subjects grouped by "
                 "agreement of MD-COPD and ESI classifications")
    t_discord_risk(doc, label=f"Table {num}.")


# Registered in citation order; numbers come from position.
SUPP_TABLES = [("baseline", s1_baseline), ("thresholds", s4_sweep),
               ("crossclass", s_crossclass_agreement),
               ("groups_vs_mdcopd", s_groups_crude),
               ("risk_common_ref", s_risk_common_ref),
               ("fev1", s6_fev1_decline), ("discord_risk", s_discord_risk),
               ("esi_by_ct", s12_esi_ct_levels)]
assert [k for k, _ in SUPP_TABLES] == SUPP_KEYS, "supplement order disagrees with supp_registry"
SUPP_ORDER = [f"S{i}" for i in range(1, len(SUPP_TABLES) + 1)]
# Supplemental figures, numbered in citation order like the tables.
SUPP_FIGURES = [("S1", "figureS1_group_risk")]

def check_citations(produced):
    """The main text and this file must agree on which supplemental tables
    exist. A dangling citation is exactly the defect that reaches reviewers."""
    # Read only what the builder actually emits. RESULTS.md and METHODS.md
    # carry trailing working sections that are stripped at build time, so a
    # citation inside one of them reads as satisfied while never reaching the
    # document. The Discussion is included because it cites tables too.
    def built(fn, stop=None):
        t = open(os.path.join(HERE, fn)).read()
        return t.split(stop)[0] if stop and stop in t else t
    body = (built("RESULTS.md", "## Open")
            + built("METHODS.md", "## Still to write")
            + built("DISCUSSION.md"))
    # Prose sources are hard-wrapped, so "Supplemental Table" and its number
    # are routinely split across a line. Matching a literal space made the
    # check report a real citation as missing.
    # Lettered tables (S3a) exist, so the pattern has to admit a suffix or
    # "Supplemental Tables S3a to S3c" registers as a citation of S3.
    # A citation can name several tables at once ("Tables S6 and S8",
    # "Tables S3a to S3c"), so capture every identifier in the span that
    # follows the prefix rather than only the first.
    cited = set()
    for m in re.finditer(r"Supplemental\s+Tables?\s+((?:S\d+[a-z]?)"
                         r"(?:\s*(?:,|and|to)\s*S\d+[a-z]?)*)", body):
        span = m.group(1)
        cited.update(re.findall(r"S\d+[a-z]?", span))
        # "S3a to S3c" cites the intervening letters too.
        for r in re.finditer(r"S(\d+)([a-z])\s*to\s*S?(\d+)?([a-z])", span):
            if r.group(3) and r.group(3) != r.group(1):
                continue          # a range across different numbers is not one
            for o in range(ord(r.group(2)), ord(r.group(4)) + 1):
                cited.add("S" + r.group(1) + chr(o))
    missing = sorted(cited - set(produced))
    unused = sorted(set(produced) - cited)
    if missing:
        raise SystemExit(f"main text cites {missing}, which the supplement "
                         f"does not produce")
    if unused:
        print(f"  note: {unused} produced but never cited in the main text")


def main():
    pjc_guard.check("The supplement build")
    word_guard.check([OUT], "The supplement build")
    prose_guard.check("The supplement build")
    prose_guard.check_owned("The supplement build")
    display_order.check(HERE, {"Supplemental Table": SUPP_ORDER,
                               "Supplemental Figure": [n for n, _ in SUPP_FIGURES]},
                        "The supplement build")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    doc = init_document()
    p = doc.add_paragraph()
    r = p.add_run("Supplement")
    r.bold = True
    r.font.size = Pt(14)
    r.add_break()
    # Same source as the manuscript title, so the two cannot drift apart.
    r = p.add_run(read_titlepage()["TITLE"][0])
    r.bold = True
    r.font.size = Pt(14)
    for i, (_, fn) in enumerate(SUPP_TABLES, 1):
        fn(doc, f"S{i}")
        doc.add_paragraph()
    doc.add_page_break()
    for n, stem in SUPP_FIGURES:
        add_figure(doc, os.path.join(FIGS, stem + ".png"), f"Supplemental Figure {n}.",
                   read_legend(stem), width=figure_width(os.path.join(FIGS, stem + ".meta")))
    data_files(doc)
    doc.save(OUT)
    check_citations(SUPP_ORDER)
    print(f"wrote {OUT}\n  {len(SUPP_ORDER)} supplemental tables")


if __name__ == "__main__":
    main()
