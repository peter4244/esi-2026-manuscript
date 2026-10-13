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

from docx.shared import Pt, Inches                           # noqa: E402
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER  # noqa: E402
from docx.oxml import OxmlElement                            # noqa: E402
from docx.oxml.ns import qn                                  # noqa: E402
from build_manuscript import (init_document, add_table, legend,  # noqa: E402
                              emphasis, ASSETS, CATS, read_titlepage, fmt_p,
                              t_risk_common_ref, t_discord_risk, Section,
                              add_figure, read_legend, figure_width, FIGS,
                              CONTENT_WIDTH_IN, new_section)
import paginate                                              # noqa: E402

OUT = os.path.join(HERE, "manuscript", "CT-free MD-COPD supplement draft v6.docx")
# SUPP_ORDER is defined after the table functions, from SUPP_TABLES.


def load(path, name):
    with open(os.path.join(path, name)) as f:
        return list(csv.DictReader(f))


def para(doc, text):
    emphasis(doc.add_paragraph(), text)


HEADINGS = []      # Heading 2 texts in document order, for the contents
BS, TAB = chr(92), chr(9)


def heading(doc, text):
    p = doc.add_paragraph(text, style="Heading 2")
    p.paragraph_format.keep_with_next = True
    HEADINGS.append(text)


def _field(par, kind, instr=None):
    """One piece of a Word field: a begin, separate or end mark, or its instruction."""
    r = par.add_run()
    if instr is not None:
        el = OxmlElement("w:instrText")
        el.set(qn("xml:space"), "preserve")
        el.text = instr
    else:
        el = OxmlElement("w:fldChar")
        el.set(qn("w:fldCharType"), kind)
    r._r.append(el)


def add_page_numbers(doc):
    p = doc.sections[0].footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _field(p, "begin")
    _field(p, None, " PAGE ")
    _field(p, "separate")
    p.add_run("1")
    _field(p, "end")


def add_toc(doc, entries):
    """A Word contents field over the Heading 2 headings. Its displayed result is
    written with the page numbers found by rendering, so it reads correctly on
    opening, and the document asks Word to refresh fields when it is opened."""
    p = doc.add_paragraph()
    r = p.add_run("Contents")
    r.bold = True
    r.font.size = Pt(12)
    for k, (text, page) in enumerate(entries):
        par = doc.add_paragraph()
        fmt = par.paragraph_format
        fmt.tab_stops.add_tab_stop(Inches(CONTENT_WIDTH_IN), WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS)
        fmt.space_after = Pt(3)
        if k == 0:
            _field(par, "begin")
            _field(par, None, f' TOC {BS}o "2-2" {BS}h {BS}z {BS}u ')
            _field(par, "separate")
        par.add_run(f"{text}{TAB}{page}")
        if k == len(entries) - 1:
            _field(par, "end")


def figure_title(stem):
    """The title sentence of a figure's legend sidecar, without its final period."""
    return read_legend(stem).split(". ", 1)[0].rstrip(".")


# --------------------------------------------------------------------------
def supp_methods(doc):
    """Massimo's Supplemental Methods (2026-09-20): the detail the main text
    Methods point to rather than carry."""
    heading(doc, "Supplemental Methods")
    para(doc, "**Visual CT assessment**")
    para(doc, "Visual emphysema was assessed according to the Fleischner Society visual "
              "classification and categorized as none, trace, mild, moderate, confluent, or "
              "advanced destructive emphysema (S1, S2). For MD-COPD-CT classification, visual "
              "emphysema was considered present at mild severity or greater (score \u22652); "
              "thus, trace emphysema did not satisfy the imaging criterion. Airway wall "
              "thickening was visually categorized as absent, borderline, or definite and was "
              "considered present for MD-COPD-CT only when definite (score 2). Participants with "
              "missing visual CT scores (n = 4) were considered not to meet the corresponding "
              "imaging criterion.")
    para(doc, "**Unadjusted outcome comparisons and bootstrap procedures**")
    para(doc, "Unadjusted rate ratios were calculated by dividing the observed event rate in each "
              "diagnostic group (events per 100 person-years) by that of the corresponding reference "
              "group. For mortality, "
              "95% confidence intervals were calculated as exact conditional intervals for the "
              "ratio of two Poisson rates. For respiratory exacerbations, 95% confidence "
              "intervals were obtained from 1,000 participant-level bootstrap resamples, with the "
              "reference rate recalculated in each resample. When either the diagnostic group "
              "or the reference group had fewer than 10 events, unadjusted rate ratios and adjusted "
              "HRs or IRRs were reported without confidence intervals or P values.")
    para(doc, "For direct comparisons among classifications, the unadjusted event rate in each "
              "MD-NoCT and MD-COPD-ESI group was divided by that in the corresponding MD-COPD-CT group (rate "
              "ratio versus MD-COPD-CT), and its adjusted HR or IRR by that of the corresponding "
              "MD-COPD-CT group (ratio of HRs or IRRs). Confidence intervals and P values for these "
              "comparisons "
              "were obtained from 1,000 paired participant-level bootstrap resamples.")
    para(doc, "**Discordant classification analyses**")
    para(doc, "In analyses of MD-COPD-CT and MD-COPD-ESI discordance, participants classified as noCOPD "
              "by both approaches served as the reference group among those without airflow "
              "limitation, whereas participants classified as AFL-only by both approaches "
              "served as the reference group among those with airflow limitation.")


def s1_baseline(doc, num):
    heading(doc, f"Supplemental Table {num}. Baseline characteristics of the 9,240 participants in the "
            f"analytic cohort according to spirometric category")
    rows = load(ASSETS, "supp_baseline.csv")
    keep = [("stratum", "Stratum"), ("n", "n"), ("age", "Age"),
            ("pct_female", "Female"), ("pct_current", "Current smoker"),
            ("pack_years", "Pack-years"), ("FEV1_pp", "FEV₁ %pred"), ("ESI", "ESI")]
    add_table(doc, [h for _, h in keep],
              [[re.sub(r"^GOLD(\d)$", r"GOLD \1", r[k]) if k == "stratum" else
                f"{int(r[k]):,}" if k == "n" else r[k] for k, _ in keep] for r in rows],
              [0.86, 0.60, 0.86, 0.78, 1.00, 0.86, 0.84, 0.70])
    n_overall = next(r["n"] for r in rows if r["stratum"] == "Overall")
    legend(doc, f"Table {num}.",
           "Values are mean (SD) unless otherwise indicated. The overall analytic "
           f"cohort comprised {int(n_overall):,} participants. PRISm = preserved ratio "
           "impaired spirometry; GOLD = Global Initiative for Chronic Obstructive Lung Disease; "
           "FEV\u2081 %pred = FEV\u2081 percent predicted; ESI = Emphysema Severity Index.")


def s4_sweep(doc, num):
    """The parameter sweep behind the threshold selection."""
    heading(doc, f"Supplemental Table {num}. Selection of thresholds for MD-NoCT and MD-COPD-ESI "
            f"classifications")
    sweep = load(ASSETS, "metric_sweep.csv")
    fit = {r["schema"]: r for r in load(ASSETS, "schema_fit.csv")}
    sel_s3 = next(r for r in sweep if r["schema"] == "S3" and r["selected"].upper() == "TRUE")
    sel_s4 = next(r for r in sweep if r["schema"] == "S4" and r["selected"].upper() == "TRUE")
    rows = []
    for r in sweep:
        sel = r["selected"].upper() == "TRUE"
        lab = r["label"].replace(">= ", "\u2265").replace("MD-COPD (reference)", "MD-COPD-CT (reference)") + (" (selected)" if sel else "")
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
           "Category sizes and performance metrics are shown for each candidate rule "
           "against MD-COPD-CT as the reference classification. The selected rules were "
           f"\u2265{int(float(sel_s3['parameter']))} of 3 symptom criteria for MD-NoCT and, for "
           f"MD-COPD-ESI, \u22652 of 4 criteria with ESI \u2265{float(sel_s4['parameter']):.2f} "
           "defining the ESI criterion; both had the "
           "highest macro-averaged F1 (macro-F1). F1 is the harmonic mean of sensitivity and positive "
           "predictive value within a diagnostic category, and macro-F1 is its mean across the four "
           "categories, which weights them equally; balanced accuracy is the mean per-category sensitivity. Thresholds were refitted within each training fold of five-fold "
           "cross-validation repeated five times: held-out agreement with MD-COPD-CT was "
           f"{100 * float(fit['S4']['agreement_heldout']):.1f}% for MD-COPD-ESI and "
           f"{100 * float(fit['S3']['agreement_heldout']):.1f}% for MD-NoCT, against "
           f"{100 * float(fit['S4']['agreement_insample']):.1f}% and "
           f"{100 * float(fit['S3']['agreement_insample']):.1f}% in the full cohort. "
           "AFL-only = airflow limitation without other criteria; ESI = Emphysema "
           "Severity Index.")


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
        "**COPDGene_Multidimensional_COPD_plus**: the per-participant MD-COPD-CT "
        "classification from the source report (S3), used as the MD-COPD-CT reference classification.",
        "**COPDGene_VitalStatus_SM_NS_Sep23**: vital status and follow-up time, "
        "used for all-cause mortality.",
        "**COPDGene_Mort_COD_Adj**: adjudicated underlying cause of death, used "
        "for respiratory mortality, with coverage through December 31, 2018, which bounds "
        "respiratory-mortality follow-up.",
        "**LFU_SidLevel_Comorbd**: the COPDGene Longitudinal Follow-up program "
        "dataset, used for prospective exacerbation counts and years of follow-up.",
    ]:
        para(doc, line)
    para(doc, "Emphysema Severity Index values were computed from the COPDGene "
              "spirometric flow-volume curves as described in the main text.")


# The Online Supplement's own references, numbered S1, S2, ... in order of first
# citation in the supplement (AJRCCM). S1 and S2 are main-text references 18 and
# 19, S3 is reference 11; the entries are those of the main list, AJRCCM style.
SUPP_REFS = [
    'Lynch DA, Austin JH, Hogg JC, Grenier PA, Kauczor HU, Bankier AA, et al. CT-definable subtypes of chronic obstructive pulmonary disease: a statement of the Fleischner Society. Radiology. 2015;277(1):192-205.',
    'Lynch DA, Moore CM, Wilson C, Nevrekar D, Jennermann T, Humphries SM, et al. CT-based visual classification of emphysema: association with mortality in the COPDGene Study. Radiology. 2018;288(3):859-866.',
    'Bhatt SP, Abadi E, Anzueto A, Bodduluri S, Casaburi R, Castaldi PJ, et al; COPDGene 2025 Diagnosis Working Group and CanCOLD Investigators. A multidimensional diagnostic approach for chronic obstructive pulmonary disease. JAMA. 2025;333(24):2164-2175.',
]


def supp_references(doc):
    heading(doc, "References")
    for i, ref in enumerate(SUPP_REFS, 1):
        para(doc, f"S{i}. {ref}")


def s6_fev1_decline(doc, num):
    heading(doc, f"Supplemental Table {num}. Longitudinal FEV\u2081 decline by diagnostic group "
            f"under each multidimensional classification")
    rows_in = load(ASSETS, "fev1_decline.csv")
    ne = {r["category"]: r for r in load(ASSETS, "fev1_noct_vs_esi.csv")}
    one = lambda v: f"{float(v):.1f}".replace("-0.0", "0.0").replace("-", "\u2212")   # no negative zero
    mm = lambda e, lo, hi: f"{one(e)} [{one(lo)} to {one(hi)}]"
    name = {"S1": "Fixed ratio", "S2": "MD-COPD-CT",
            "S3": "MD-NoCT", "S4": "MD-COPD-ESI"}
    rows, seen = [], set()
    for r in rows_in:
        sc = r["schema"]; p_ = float(r["p"])
        x = ne[r["category"]] if sc == "S4" else None
        rows.append([name.get(sc, sc) if sc not in seen else "", r["category"],
                     f"{int(r['n_subj']):,}", mm(r["est_mL_yr"], r["lo"], r["hi"]), fmt_p(p_),
                     mm(x["diff_noct_minus_esi"], x["lo"], x["hi"]) if x else "",
                     fmt_p(float(x["p_boot"])) if x else ""])
        seen.add(sc)
    add_table(doc, ["Classification", "Group", "n",
                    "Difference in decline versus the common reference, mL/yr [95% CI]", "P",
                    "MD-NoCT minus MD-COPD-ESI, mL/yr [95% CI]", "P"],
              rows, [1.35, 0.95, 0.55, 1.40, 0.55, 1.15, 0.55])
    legend(doc, f"Table {num}.",
           "Differences in annual FEV\u2081 change are relative to the common noCOPD "
           "reference and were estimated using linear mixed-effects models over visits 1 to 3 "
           "with a participant-specific random intercept, adjusted for height, sex, race, age, "
           "smoking status, pack-years, and baseline post-bronchodilator FEV\u2081 entered as "
           "an interaction with follow-up time. Negative values indicate faster FEV\u2081 "
           "decline relative to the reference. The MD-NoCT minus MD-COPD-ESI column compares corresponding "
           "MD-NoCT and ESI groups, with confidence intervals and P values from 1,000 paired "
           "participant-level bootstrap resamples; negative values indicate faster decline under MD-NoCT. AFL-only = airflow limitation without other "
           "criteria; CI = confidence interval.")


def s_fev1_random_slope(doc, num):
    heading(doc, f"Supplemental Table {num}. Sensitivity analysis of longitudinal FEV\u2081 decline "
                 f"with participant-specific random slopes")
    rows_in = load(ASSETS, "fev1_decline_random_slope.csv")
    one = lambda v: f"{float(v):.1f}".replace("-0.0", "0.0").replace("-", "\u2212")   # no negative zero
    mm = lambda e, lo, hi: f"{one(e)} [{one(lo)} to {one(hi)}]"
    name = {"S2": "MD-COPD-CT", "S3": "MD-NoCT", "S4": "MD-COPD-ESI"}
    rows, seen, sd = [], set(), {}
    for r in rows_in:
        sc = r["schema"]
        rows.append([name.get(sc, sc) if sc not in seen else "", r["category"],
                     f"{int(r['n_subj']):,}", mm(r["est_mL_yr"], r["lo"], r["hi"]),
                     fmt_p(float(r["p"]))])
        seen.add(sc); sd[sc] = float(r["sd_slope_mL_yr"])
    assert set(sd) == {"S2", "S3", "S4"}, "random-slope table must cover the three MD classifications"
    add_table(doc, ["Classification", "Group", "n",
                    "Difference in decline versus the common reference, mL/yr [95% CI]", "P"],
              rows, [1.45, 1.15, 0.65, 2.55, 0.70])
    legend(doc, f"Table {num}.",
           "Models were as in Table S6, with a participant-specific random slope for follow-up "
           "time in addition to the random intercept. Negative values indicate faster FEV\u2081 "
           "decline relative to the common noCOPD reference. The standard deviation of the "
           f"participant-specific slopes was {sd['S2']:.1f}, {sd['S3']:.1f}, and {sd['S4']:.1f} "
           "mL/yr in the models for MD-COPD-CT, MD-NoCT, and MD-COPD-ESI. AFL-only = airflow "
           "limitation without other criteria; CI = confidence interval.")


def s_crossclass_agreement(doc, num):
    """Cross-classification of each CT-free classification against MD-COPD,
    with the agreement the Results quote: the share of each classification's
    assignments that MD-COPD places in the same group."""
    heading(doc, f"Supplemental Table {num}. Cross-classification of MD-NoCT and MD-COPD-ESI "
                 f"against MD-COPD-CT")
    x = load(ASSETS, "crossclass.csv")
    f1 = {r["category"]: r for r in load(ASSETS, "f1_by_category.csv")}
    ag = {r["category"]: r for r in load(ASSETS, "agreement_by_group.csv")}
    rows = []
    for s_, name, key in (("S3", "MD-NoCT", "noct"), ("S4", "MD-COPD-ESI", "esi")):
        for i, rc in enumerate(CATS):
            vals = [cell_n(x, s_, rc, cc) for cc in CATS]
            n_ = sum(vals)
            rows.append([name if i == 0 else "", rc] + [f"{v:,}" for v in vals] +
                        [f"{n_:,}", f"{float(ag[rc]['recall_' + key]):.1f}",
                         f"{100 * vals[i] / n_:.1f}",
                         f"{float(f1[rc]['f1_' + key]):.2f}"])
    add_table(doc, ["Classification", "Assigned to", *[f"MD-COPD-CT {c}" for c in CATS],
                    "Assigned, n", "Sensitivity, %", "PPV, %", "F1"],
              rows, [1.05, 0.78, 0.58, 0.58, 0.58, 0.58, 0.60, 0.62, 0.55, 0.58])
    ps = [float(ag[c]["p_boot"]) for c in CATS]
    p_txt = ("P < 0.005 in each of the four groups" if all(p < 0.005 for p in ps)
             else "; ".join(f"{c} P {'< 0.005' if p < 0.005 else '= ' + fmt_p(p)}" for c, p in zip(CATS, ps)))
    legend(doc, f"Table {num}.",
           "Cross-classification of MD-NoCT and MD-COPD-ESI against MD-COPD-CT. Rows indicate the "
           "category assigned by each modified classification and columns the corresponding "
           "MD-COPD-CT category; diagonal cells indicate concordant classification. Positive "
           "predictive value (PPV) is the proportion of participants assigned to a category by the "
           "modified classification who were assigned to the same category by MD-COPD-CT. F1 is the "
           "harmonic mean of PPV and sensitivity, where sensitivity is the proportion of each "
           "MD-COPD-CT category reproduced by the modified classification. PPV differed between "
           f"MD-NoCT and MD-COPD-ESI by paired bootstrap ({p_txt}). "
           "AFL-only = airflow limitation without other criteria; ESI = Emphysema Severity Index.")


def s_groups_crude(doc, num):
    """Crude risk of every diagnostic group under each multidimensional
    classification against the common reference, and each CT-free
    classification against MD-COPD by a paired bootstrap. Crude only
    (Pete, 2026-09-11); all three groups (Pete, 2026-09-13)."""
    heading(doc, f"Supplemental Table {num}. Unadjusted risk of clinical outcomes by diagnostic "
                 "group under each multidimensional classification")
    cru = {(r["schema"], r["category"], r["outcome"]): r for r in load(ASSETS, "consensus_ref_crude.csv")}
    cmp_ = {(r["schema"], r["category"], r["outcome"]): r for r in load(ASSETS, "group_vs_mdcopd.csv")
            if r["type"] == "crude"}
    ref = load(ASSETS, "consensus_ref_group.csv")[0]
    NM = {"S2": "MD-COPD-CT", "S3": "MD-NoCT", "S4": "MD-COPD-ESI"}
    OUTC = (("all", "All-cause mortality"), ("resp", "Respiratory mortality"), ("exac", "Exacerbations"))
    FLAG = "\u2020"
    ci = lambda v, lo, hi: f"{float(v):.2f} [{float(lo):.2f}-{float(hi):.2f}]"
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
                rate = f"{float(r['rate_100py']):.{1 if o == 'exac' else 2}f}"
                if s_ == "S2":
                    rows.append([lead, NM[s_], f"{int(float(r['events'])):,}", rate, own, "reference", ""])
                    continue
                x = cmp_[(s_, g, o)]
                if x["few_events"].upper() in TRUE:
                    vs, pt = f"{float(x['ratio_of_ratios']):.2f}{FLAG}", ""
                else:
                    p_ = float(x["p_boot"]); floor = 2 / int(x["B_eff"])
                    vs = ci(x["ratio_of_ratios"], x["lo"], x["hi"])
                    pt = fmt_p(p_)
                rows.append([lead, NM[s_], f"{int(float(r['events'])):,}", rate, own, vs, pt])
    add_table(doc, ["Outcome", "Classification", "Events", "Rate per 100 person-years",
                    "Rate ratio versus the common reference [95% CI]",
                    "Rate ratio versus MD-COPD-CT [95% CI]", "P"],
              rows, [1.05, 1.15, 0.55, 0.70, 1.25, 1.20, 0.60])
    legend(doc, f"Table {num}.",
           "Each diagnostic group was compared with the common reference comprising the "
           f"{int(ref['n_cohort']):,} participants classified as noCOPD by all three "
           f"multidimensional classifications ({int(ref['n_mort']):,} in mortality analyses and "
           f"{int(ref['n_exac']):,} in exacerbation analyses). Rates are events per 100 person-years. Unadjusted rate "
           "ratios were calculated as the event rate in each group divided by that in the "
           "common reference, with "
           "exact Poisson confidence intervals for mortality and participant-level bootstrap "
           "confidence intervals for respiratory exacerbations. Rate ratios versus MD-COPD-CT divide "
           "the event rate in each modified classification group by that in the corresponding "
           "MD-COPD-CT group; 95% confidence intervals and two-sided P values were "
           "obtained from 1,000 paired participant-level bootstrap resamples. "
           f"{FLAG} Fewer than 10 events in the group, or in either group for comparisons with "
           "MD-COPD-CT; the estimate is shown without a confidence interval or P value. "
           "AFL-only = airflow limitation without other criteria; CI = confidence interval.")


def s_risk_common_ref(doc, num):
    heading(doc, f"Supplemental Table {num}. Adjusted risk of clinical outcomes by diagnostic "
                 "group under each multidimensional classification")
    t_risk_common_ref(doc, label=f"Table {num}.")


def s_discord_risk(doc, num):
    heading(doc, f"Supplemental Table {num}. Clinical outcomes according to concordance and "
                 "discordance between MD-COPD-CT and MD-COPD-ESI classifications")
    t_discord_risk(doc, label=f"Table {num}.")


# Registered in citation order; numbers come from position.
SUPP_TABLES = [("baseline", s1_baseline), ("thresholds", s4_sweep),
               ("crossclass", s_crossclass_agreement),
               ("groups_vs_mdcopd", s_groups_crude),
               ("risk_common_ref", s_risk_common_ref),
               ("fev1", s6_fev1_decline), ("fev1_rs", s_fev1_random_slope),
               ("discord_risk", s_discord_risk)]
assert [k for k, _ in SUPP_TABLES] == SUPP_KEYS, "supplement order disagrees with supp_registry"
SUPP_ORDER = [f"S{i}" for i in range(1, len(SUPP_TABLES) + 1)]
# Supplemental figures, numbered in citation order like the tables.
SUPP_FIGURES = [("S1", "figureS1_group_risk"), ("S2", "figureS2_profile")]

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
    # An S-prefixed identifier is supplemental whether or not the citation spells
    # out "Supplemental": Massimo's draft writes "Table S4" (2026-09-20).
    for m in re.finditer(r"(?:Supplemental\s+)?Tables?\s+((?:S\d+[a-z]?)"
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


def build(out, toc):
    """Write the supplement to out with the given contents entries; return the
    headings in document order."""
    HEADINGS.clear()
    doc = init_document()
    add_page_numbers(doc)
    # AJRCCM cover sheet for an Online Supplement: the manuscript title, the
    # authors without affiliations, and the words "Online Supplement". Title and
    # authors come from TITLEPAGE.md, as in the manuscript, so they cannot drift.
    tp = read_titlepage()
    p = doc.add_paragraph()
    r = p.add_run("Online Supplement")
    r.bold = True
    r.font.size = Pt(14)
    p = doc.add_paragraph()
    r = p.add_run(tp["TITLE"][0])
    r.bold = True
    r.font.size = Pt(14)
    authors = re.sub(r"[⁰¹²³⁴-⁹]+(?:,[⁰¹²³⁴-⁹]+)*",
                     "", " ".join(tp["AUTHORS"]))
    assert not re.search(r"[⁰¹²³⁴-⁹]", authors), "affiliation marks left in the author list"
    doc.add_paragraph(authors)
    doc.add_page_break()
    if toc:
        add_toc(doc, toc)
        doc.add_page_break()
    supp_methods(doc)
    for i, (_, fn) in enumerate(SUPP_TABLES, 1):
        fn(doc, f"S{i}")
        doc.add_paragraph()
    doc.add_page_break()
    # A figure wider than the content width was rendered for a landscape page and
    # must be placed at that width, or its fonts land smaller than validated.
    landscape_now = False
    for n, stem in SUPP_FIGURES:
        w = figure_width(os.path.join(FIGS, stem + ".meta"))
        want = w > CONTENT_WIDTH_IN + 0.01
        if want != landscape_now:
            new_section(doc, landscape=want)
            landscape_now = want
        heading(doc, f"Supplemental Figure {n}. {figure_title(stem)}")
        add_figure(doc, os.path.join(FIGS, stem + ".png"), f"Supplemental Figure {n}.",
                   read_legend(stem), width=w)
    if landscape_now:
        new_section(doc, landscape=False)
    data_files(doc)
    supp_references(doc)
    upd = OxmlElement("w:updateFields")
    upd.set(qn("w:val"), "true")
    doc.settings.element.append(upd)
    doc.save(out)
    return list(HEADINGS)


def main(out=OUT):
    pjc_guard.check("The supplement build")
    word_guard.check([out], "The supplement build")
    prose_guard.check("The supplement build")
    prose_guard.check_owned("The supplement build")
    display_order.check(HERE, {"Supplemental Table": SUPP_ORDER,
                               "Supplemental Figure": [n for n, _ in SUPP_FIGURES]},
                        "The supplement build")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    # Page numbers exist only after a rendering. Pass 1 collects the headings;
    # pass 2 lays out the contents with placeholder numbers so they take their
    # final space; pass 3 writes the rendered pages; a last rendering confirms
    # that no heading moved.
    heads = build(out, [])
    build(out, [(h, 99) for h in heads])
    first = paginate.pdf_pages(out)
    toc = [(h, paginate.last_page_of(first, h)) for h in heads]
    build(out, toc)
    final = paginate.pdf_pages(out)
    moved = [(h, pg, paginate.last_page_of(final, h)) for h, pg in toc
             if paginate.last_page_of(final, h) != pg]
    if moved:
        raise SystemExit(f"contents page numbers moved on the final rendering: {moved}")
    check_citations(SUPP_ORDER)
    for h, pg in toc:
        print(f"  p{pg:>2}  {h}")
    print(f"wrote {out}\n  {len(SUPP_ORDER)} supplemental tables; contents with {len(toc)} entries")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else OUT)
