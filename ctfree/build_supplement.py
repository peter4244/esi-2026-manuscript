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
                              emphasis, ASSETS, CATS, SCHEMA_NAME,
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
           "participants by GOLD stratum. Values are mean (SD) unless marked as a "
           "percentage. The cohort follows the exclusion chain of the source MD-COPD "
           "report, which removes never-smokers, so there is no never-smoker stratum. "
           "PRISm is preserved ratio impaired spirometry.")


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
    legend(doc, f"Table {num}.",
           "Category sizes and each candidate selection metric across the "
           "thresholds examined, against the MD-COPD reference in the first row. "
           "Macro-averaged F1 weights the four categories equally and penalizes "
           "both over- and under-assignment; balanced accuracy averages recall "
           "alone and Cohen's κ is not category-weighted, so neither penalizes "
           "over-assignment, and their optima sit where AFL-only is respectively "
           "almost empty and more than triple the reference. "
           "AFL-only, airflow limitation without other criteria.")


def cell_n(rows, schema, row_cat, col_cat):
    """One cell of the cross-classification, read from the artifact."""
    for r in rows:
        if (r["schema"] == schema and r["row_cat"] == row_cat
                and r["col_cat"] == col_cat):
            return int(r["n"])
    raise SystemExit(f"crossclass.csv has no {schema} {row_cat}/{col_cat} cell")


def s4_fitting(doc, num):
    heading(doc, f"Supplemental Table {num}. Fitted rules and cross-validated performance")
    fit = load(ASSETS, "schema_fit.csv")
    cvd = load(ASSETS, "schema_fit_cv_diff.csv")[0]
    nm = {"S3": "NoCT classification", "S4": "ESI classification"}
    rows = [[nm[r["schema"]], f"≥ {int(float(r['k']))}",
             "—" if r["t_low"] in ("", "NA") else f"{float(r['t_low']):.2f}",
             f"{float(r['macroF1_insample']):.4f}",
             f"{float(r['macroF1_heldout']):.4f}"]
            for r in fit if r["schema"] in nm]
    add_table(doc, ["Schema", "Count threshold", "ESI threshold",
                    "In-sample macro-F1", "Held-out macro-F1"], rows,
              [1.55, 1.20, 1.05, 1.32, 1.38])
    tst = load(ASSETS, "schema_fit_cv_test.csv")[0]
    p_txt = ("< 0.001" if float(tst["p_value"]) < 0.001
             else f"= {float(tst['p_value']):.3f}")
    legend(doc, f"Table {num}.",
           "Thresholds fitted to approximate the CT-based classification, by "
           "macro-averaged F1 across the four groups, over the full parameter "
           "space of each schema. Held-out values are from "
           f"{int(tst['n_repeats'])} repeats of {int(tst['k'])}-fold "
           "cross-validation stratified on the CT-based categories, with "
           "thresholds refitted inside every training fold. The ESI-based schema "
           f"exceeds the symptoms-only schema by {float(tst['diff_mean']):.4f} "
           f"(95% CI: {float(tst['ci_lo']):.4f} to {float(tst['ci_hi']):.4f}; "
           f"P {p_txt}), and did so in {int(tst['folds_favoring_S4'])} of "
           f"{int(tst['n_folds'])} held-out folds. The interval and P value are "
           "from the corrected resampled t-test: cross-validation folds share "
           "training data, so a paired t-test on the per-fold differences treats "
           "that shared data as new information; the correction inflates the "
           "variance accordingly. The range of the per-fold differences "
           f"themselves was {float(cvd['diff_lo']):.4f} to "
           f"{float(cvd['diff_hi']):.4f}.")


def s5_discrimination(doc, num):
    heading(doc, f"Supplemental Table {num}. Discrimination under each schema")
    d = load(ASSETS, "schema_discrimination.csv")
    add_table(doc, ["Schema", "All-cause C-index", "Respiratory C-index",
                    "Exacerbation AIC"],
              [[SCHEMA_NAME[r["schema"]], f"{float(r['c_allcause']):.4f}",
                f"{float(r['c_resp']):.4f}", f"{float(r['exac_AIC']):.0f}"] for r in d],
              [1.70, 1.60, 1.65, 1.55])
    hr = [float(r["resp_HR"]) for r in load(ASSETS, "schema_risk.csv")
          if r["schema"] == "S3" and r["category"] == "AFL-only"][0]
    legend(doc, f"Table {num}.",
           "Discrimination for each schema, every model carrying the same "
           "covariates. The symptoms-only schema has the highest C-index for both "
           "mortality outcomes and the lowest exacerbation AIC. Figures 2 to 4 and "
           "Supplemental Tables S3a to S3c show what that costs: its AFL-only "
           f"category carries {hr:.1f} times the respiratory mortality of its own "
           "reference after adjustment.")


def data_files(doc):
    heading(doc, "COPDGene files used")
    para(doc, "Analyses in this manuscript draw on the following COPDGene "
              "distribution files.")
    for line in [
        "**COPDGene_VitalStatus_SM_NS_Sep23.csv** — vital status and follow-up time, "
        "used for all-cause mortality.",
        "**COPDGene_Mort_COD_Adj.csv** — adjudicated underlying cause of death, used "
        "for respiratory mortality.",
        "**LFU_SidLevel_Comorbid_SM_30SEP21.txt** — the COPDGene Longitudinal "
        "Follow-up program dataset, used for prospective exacerbation counts and "
        "person-time at risk.",
        "**COPDGene_P1P2P3_SM_NS_Long_Sep24.csv** — the main COPD phenotype file in "
        "long format, used for baseline characteristics and the diagnostic criteria.",
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
           "random intercept per participant, adjusted for height, sex, race, age, "
           "smoking status, pack-years and baseline post-bronchodilator "
           "FEV\u2081, as the source MD-COPD report was. Baseline FEV\u2081 enters "
           "through its interaction with time; a main effect would have the "
           "visit 1 outcome predicting itself. Because the groups differ sharply "
           "in baseline lung function, the estimate asks whether a group declines "
           "faster than others starting from the same FEV\u2081. A negative value "
           "is faster decline.")


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
           "Mean ESI at each level of the two visual CT criteria. ESI rises "
           "monotonically across both scales. The MD-COPD framework treats "
           "emphysema as present at mild or greater and wall thickening as "
           "present when definite. Discrimination of these criteria by ESI and "
           "by FEV\u2081/FVC is given in Table 4 of the main text.")


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
           "diagonal is agreement. Agreement is the percentage of participants assigned "
           "to a group that MD-COPD places in the same group. F1 is the harmonic mean of "
           "that percentage and its converse, the percentage of the MD-COPD group the "
           "classification reproduces; the mean of the four F1 values is the "
           "macro-averaged F1 the thresholds were fitted on. Agreement differed between "
           f"the ESI and NoCT classifications by paired bootstrap ({p_txt}). "
           "AFL-only, airflow limitation without other criteria.")


def s_copd_binary(doc, num):
    """COPD versus no COPD under each classification: the event rate in each group
    with its units, the crude rate ratio, and each classification against MD-COPD
    by a paired bootstrap (Pete, 2026-09-11: MD-COPD first per outcome;
    2026-09-13: show the rates and their units)."""
    heading(doc, f"Supplemental Table {num}. Event rates in COPD versus no COPD under each classification")
    b = {r["schema"]: r for r in load(ASSETS, "schema_binary.csv")}
    v = {(r["schema"], r["outcome"]): r for r in load(ASSETS, "binary_vs_mdcopd.csv")}
    NM = {"S2": "MD-COPD", "S1": "Fixed ratio", "S3": "NoCT classification",
          "S4": "ESI classification"}
    OUT = [("all", "All-cause mortality, deaths per 100 person-years", 2),
           ("resp", "Respiratory mortality, deaths per 100 person-years", 3),
           ("exac", "Exacerbations, exacerbations per 100 person-years", 1)]
    assert all(int(r["resp_nocopd"]) >= 10 and int(r["resp_copd"]) >= 10 for r in b.values()), \
        "a COPD versus no COPD cell is under the event floor"
    ci = lambda x, lo, hi: f"{float(x):.2f} ({float(lo):.2f}\u2013{float(hi):.2f})"
    rows = []
    for o, title, dp in OUT:
        rows.append(Section(title))
        for s_ in ("S2", "S1", "S3", "S4"):
            r = b[s_]
            rate_c, rate_n = float(r[f"rate_{o}_copd"]), float(r[f"rate_{o}_nocopd"])
            assert abs(rate_c / rate_n - float(r[f"{o}_rr"])) < 1e-9, f"{s_} {o}: rates do not reproduce the ratio"
            crude = ci(r[f"{o}_rr"], r[f"{o}_rr_lo"], r[f"{o}_rr_hi"])
            lead = ["\u2003" + NM[s_], f"{rate_c:.{dp}f}", f"{rate_n:.{dp}f}", crude]
            if s_ == "S2":
                rows.append(lead + ["reference", ""])
                continue
            x = v[(s_, o)]; p_ = float(x["p_boot"]); floor = 2 / int(x["B_eff"])
            pt = f"<{floor:.3f}" if p_ == 0 else (f"{p_:.3f}" if p_ < 0.1 else f"{p_:.2f}")
            rows.append(lead + [ci(x["ratio_of_ratios"], x["lo"], x["hi"]), pt])
    add_table(doc, ["Classification", "Rate, COPD", "Rate, no COPD",
                    "Crude rate ratio (95% CI)", "Ratio versus MD-COPD (95% CI)", "P"],
              rows, [1.55, 0.80, 0.80, 1.35, 1.35, 0.65])
    n = {s_: f"{int(b[s_]['n_copd']):,}" for s_ in b}
    legend(doc, f"Table {num}.",
           "Each classification's COPD group (COPD-minor and COPD-major; for the fixed "
           "ratio, post-bronchodilator FEV\u2081/FVC below 0.70) against its own no-COPD "
           "group (noCOPD and AFL-only). Rates are events per 100 person-years of follow-up, "
           "in the unit named in each section heading. The crude rate ratio is the rate in the "
           "COPD group divided by the rate in the no-COPD group and has no units, with exact "
           "Poisson intervals for deaths and subject-bootstrap intervals for exacerbations. The "
           "ratio versus MD-COPD divides each classification's crude rate ratio by that of "
           "MD-COPD and has no units; its interval and two-sided P come from a paired subject "
           "bootstrap of 1,000 resamples, and P < 0.002 means no resample fell on the other side "
           f"of 1. COPD groups: MD-COPD {n['S2']}, fixed ratio {n['S1']}, NoCT classification "
           f"{n['S3']} and ESI classification {n['S4']} of 9,240 participants.")

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
           f"reference, the {int(ref['n_cohort']):,} participants all three classifications assign to "
           "noCOPD. Crude rate ratios are the observed event rate in the group divided by the rate in "
           "the reference, with exact Poisson intervals for deaths and subject-bootstrap intervals for "
           "exacerbations. The ratio versus MD-COPD divides each CT-free classification's crude ratio by "
           "that of the same group under MD-COPD; its interval and two-sided P come from a paired "
           "subject bootstrap of 1,000 resamples, refitting every classification on the same draw. "
           f"{FLAG} fewer than 10 events in the group, or, for a ratio versus MD-COPD, in either group "
           "compared: the estimate is given without an interval or P. Events are deaths for the "
           "mortality outcomes and exacerbations for the exacerbation outcome. AFL-only, airflow "
           "limitation without other criteria; CI, confidence interval.")


def s_risk_common_ref(doc, num):
    heading(doc, f"Supplemental Table {num}. Adjusted risk of each group against the common "
                 "noCOPD reference")
    t_risk_common_ref(doc, label=f"Table {num}.")


def s_discord_risk(doc, num):
    heading(doc, f"Supplemental Table {num}. Risk in the groups on which MD-COPD and "
                 "the ESI classification agree or disagree")
    t_discord_risk(doc, label=f"Table {num}.")


# Registered in citation order; numbers come from position. s5_discrimination
# and s4_fitting stay defined but unregistered: Methods still describes the
# analyses behind them and no result cites them, pending Pete's ruling.
SUPP_TABLES = [("baseline", s1_baseline), ("thresholds", s4_sweep),
               ("crossclass", s_crossclass_agreement), ("copd_binary", s_copd_binary),
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
    r = p.add_run("Supplement: Preserving the diagnostic benefit of a "
                  "multidimensional COPD framework without chest CT")
    r.bold = True
    r.font.size = Pt(14)
    doc.add_paragraph("Draft v1. All tables generated from ctfree/assets/.")
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
