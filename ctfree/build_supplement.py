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
                              emphasis, ASSETS, CATS, SCHEMA_NAME)

OUT = os.path.join(HERE, "manuscript", "CT-free MD-COPD supplement draft v1.docx")
SUPP_ORDER = ["S1", "S2", "S3a", "S3b", "S3c", "S4", "S5", "S6",
               "S7", "S8", "S9", "S10", "S11", "S12", "S13"]


def load(path, name):
    with open(os.path.join(path, name)) as f:
        return list(csv.DictReader(f))


def heading(doc, text):
    doc.add_paragraph(text, style="Heading 2")


def para(doc, text):
    emphasis(doc.add_paragraph(), text)


# --------------------------------------------------------------------------
def s1_baseline(doc):
    heading(doc, "Supplemental Table S1. Baseline characteristics")
    rows = load(ASSETS, "supp_baseline.csv")
    keep = [("stratum", "Stratum"), ("n", "n"), ("age", "Age"),
            ("pct_female", "Female"), ("pct_current", "Current smoker"),
            ("pack_years", "Pack-years"), ("FEV1_pp", "FEV₁ %pred"), ("ESI", "ESI")]
    add_table(doc, [h for _, h in keep],
              [[r[k] for k, _ in keep] for r in rows],
              [0.86, 0.60, 0.86, 0.78, 1.00, 0.86, 0.84, 0.70])
    n_overall = next(r["n"] for r in rows if r["stratum"] == "Overall")
    legend(doc, "Table S1.",
           f"Baseline characteristics of the {int(n_overall):,} analytic cohort "
           "participants by GOLD stratum. Values are mean (SD) unless marked as a "
           "percentage. The cohort follows the exclusion chain of the source MD-COPD "
           "report, which removes never-smokers, so there is no never-smoker stratum. "
           "PRISm is preserved ratio impaired spirometry.")


def s2_ct(doc):
    heading(doc, "Supplemental Table S2. ESI and quantitative CT")
    rows = load(ASSETS, "supp_esi_ct.csv")
    keep = [("stratum", "Stratum"),
            ("n_LAA", "n"), ("r_LAA", "r (ESI, LAA-950)"),
            ("n_PRM", "n"), ("r_PRM", "r (ESI, PRM emphysema)")]
    def cell(r, k):
        v = r[k]
        return f"{float(v):.3f}" if k.startswith("r_") else v
    add_table(doc, [h for _, h in keep],
              [[cell(r, k) for k, _ in keep] for r in rows],
              [1.30, 0.75, 1.85, 0.75, 1.85])
    legend(doc, "Table S2.",
           "Pearson correlations between ESI and quantitative CT emphysema, overall "
           "and within GOLD stratum. LAA-950 is the percentage of lung voxels below "
           "−950 Hounsfield units on inspiratory CT; PRM emphysema is the parametric "
           "response map emphysema percentage. Correlations are computed on "
           "participants with both measures available, so n varies by column.")


def s3_risk_by_outcome(doc):
    """Risk by outcome, every group against the common noCOPD reference. The
    fixed ratio is not carried: its comparison with the multidimensional
    framework is the source report's question, not this one."""
    risk = {(r["schema"], r["category"]): r
            for r in load(ASSETS, "consensus_ref_risk.csv")}
    crd = {(r["schema"], r["category"], r["outcome"]): r
           for r in load(ASSETS, "consensus_ref_crude.csv")}
    ref = load(ASSETS, "consensus_ref_group.csv")[0]
    NAME = {"S2": "MD-COPD", "S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}
    GRPS = ["AFL-only", "COPD-minor", "COPD-major"]
    FLAG = "\u2020"

    def few(r, key):
        return r is not None and r[key].upper() in ("TRUE", "T")

    for suffix, okey, olabel, est_col, n_col, flag_col in (
            ("a", "all",  "all-cause mortality",   "all_HR",   "n_mort", "all_few_events"),
            ("b", "resp", "respiratory mortality", "resp_HR",  "n_mort", "resp_few_events"),
            ("c", "exac", "exacerbations",         "exac_IRR", "n_exac", "all_few_events")):
        heading(doc, f"Supplemental Table S3{suffix}. Risk of {olabel} "
                     f"against the common noCOPD reference")
        rows, seen = [], set()
        for sc in ("S2", "S3", "S4"):
            for c in GRPS:
                r = risk.get((sc, c)); k = crd.get((sc, c, okey))
                if r is None:
                    continue
                stem = "exac" if okey == "exac" else okey
                lci = "exac_LCI" if okey == "exac" else stem + "_LCI"
                uci = "exac_UCI" if okey == "exac" else stem + "_UCI"
                ci = (f"{float(r[est_col]):.2f}{FLAG}" if few(r, flag_col)
                      else f"{float(r[est_col]):.2f} "
                           f"({float(r[lci]):.2f}\u2013{float(r[uci]):.2f})")
                cr = ("not estimable" if k is None else
                      f"{float(k['rr']):.2f}{FLAG}" if few(k, "few_events")
                      else f"{float(k['rr']):.2f} "
                           f"({float(k['lo']):.2f}\u2013{float(k['hi']):.2f})")
                rows.append([NAME[sc] if sc not in seen else "", c,
                             f"{int(r[n_col]):,}", cr, ci])
                seen.add(sc)
        add_table(doc, ["Classification", "Group", "n",
                        "Crude rate ratio (95% CI)",
                        "Adjusted HR or IRR (95% CI)"],
                  rows, [1.24, 1.10, 0.62, 1.76, 1.78])
        legend(doc, f"Table S3{suffix}.",
               f"Crude and adjusted risk of {olabel}, every group estimated "
               f"against the same reference: the {int(ref['n_cohort']):,} "
               "participants all three multidimensional classifications assign "
               "to noCOPD. Because that group is noCOPD under each "
               "classification, it shares no participant with any group shown, "
               "and an estimate under one classification is on the same scale as "
               "an estimate under another. Adjusted models carry age, sex, race, "
               "current smoking status, pack-years and body mass index, with "
               "prior exacerbation frequency added for exacerbations. "
               f"{FLAG} fewer than 10 events in the group: the point estimate is "
               "given without an interval. AFL-only, airflow limitation without "
               "other criteria; HR, hazard ratio; IRR, incidence rate ratio; CI, "
               "confidence interval.")
        doc.add_paragraph()


def s4_sweep(doc):
    """The parameter sweep behind the threshold selection."""
    heading(doc, "Supplemental Table S4. Threshold selection")
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
    legend(doc, "Table S11.",
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


def s3_crossclass(doc):
    heading(doc, "Supplemental Table S10. Reclassification against the CT-based framework")
    x = load(ASSETS, "crossclass.csv")
    nm = {"S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}
    for s in ("S3", "S4"):
        para(doc, f"**{nm[s]}.** Rows are this classification; columns are MD-COPD.")
        cell = {(r["row_cat"], r["col_cat"]): int(r["n"]) for r in x if r["schema"] == s}
        rows = []
        for rc in CATS:
            vals = [cell[(rc, cc)] for cc in CATS]
            rows.append([rc] + [f"{v:,}" for v in vals] + [f"{sum(vals):,}"])
        tot = [sum(cell[(rc, cc)] for rc in CATS) for cc in CATS]
        rows.append(["Total"] + [f"{v:,}" for v in tot] + [f"{sum(tot):,}"])
        add_table(doc, ["", *CATS, "Total"], rows,
                  [1.30, 1.02, 1.02, 1.06, 1.06, 1.04])
        doc.add_paragraph()
    lost = {s_: cell_n(x, s_, "AFL-only", "COPD-major") for s_ in ("S3", "S4")}
    legend(doc, "Table S10.",
           "Full cross-classification of each CT-free schema against the CT-based "
           "framework. Diagonal cells are participants both schemas place in the "
           "same category. The COPD-major column shows where the two schemas differ: "
           f"{lost['S3']:,} of those participants fall into AFL-only without CT, "
           f"against {lost['S4']:,} with ESI.")


def s4_fitting(doc):
    heading(doc, "Supplemental Table S11. Fitted rules and cross-validated performance")
    fit = load(ASSETS, "schema_fit.csv")
    cvd = load(ASSETS, "schema_fit_cv_diff.csv")[0]
    nm = {"S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}
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
    legend(doc, "Table S11.",
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


def s5_discrimination(doc):
    heading(doc, "Supplemental Table S5. Discrimination under each schema")
    d = load(ASSETS, "schema_discrimination.csv")
    add_table(doc, ["Schema", "All-cause C-index", "Respiratory C-index",
                    "Exacerbation AIC"],
              [[SCHEMA_NAME[r["schema"]], f"{float(r['c_allcause']):.4f}",
                f"{float(r['c_resp']):.4f}", f"{float(r['exac_AIC']):.0f}"] for r in d],
              [1.70, 1.60, 1.65, 1.55])
    hr = [float(r["resp_HR"]) for r in load(ASSETS, "schema_risk.csv")
          if r["schema"] == "S3" and r["category"] == "AFL-only"][0]
    legend(doc, "Table S5.",
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


def s6_fev1_decline(doc):
    heading(doc, "Supplemental Table S6. Longitudinal FEV\u2081 decline by group")
    rows_in = load(ASSETS, "fev1_decline.csv")
    name = {"S1": "Fixed ratio", "S2": "MD-COPD",
            "S3": "NoCT-MD-COPD", "S4": "ESI-MD-COPD"}
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
    legend(doc, "Table S6.",
           "Difference in annual FEV\u2081 change against each classification's own "
           "noCOPD group, from linear mixed models over visits 1 to 3 with a "
           "random intercept per participant, adjusted for height, sex, race, age, "
           "smoking status, pack-years and baseline post-bronchodilator "
           "FEV\u2081, as the source MD-COPD report was. Baseline FEV\u2081 enters "
           "through its interaction with time; a main effect would have the "
           "visit 1 outcome predicting itself. Because the groups differ sharply "
           "in baseline lung function, the estimate asks whether a group declines "
           "faster than others starting from the same FEV\u2081. A negative value "
           "is faster decline.")


def s7_continuous_esi(doc):
    heading(doc, "Supplemental Table S7. Continuous ESI and FEV₁/FVC")
    rows_in = load(ASSETS, "continuous_esi_mortality.csv")
    rows = []
    for r in rows_in:
        def hr(a, b, c, d):
            return (f"{float(r[a]):.3f} ({float(r[b]):.3f}–{float(r[c]):.3f}), "
                    f"P {'<0.001' if float(r[d]) < 0.001 else f'= {float(r[d]):.3f}'}")
        lp = float(r["lr_p"])
        rows.append([
            r["outcome"].capitalize(),
            hr("ESI_HR", "ESI_LCI", "ESI_UCI", "ESI_p"),
            hr("FF_HR", "FF_LCI", "FF_UCI", "FF_p"),
            f"χ² = {float(r['lr_chisq']):.1f}, "
            f"P {'<0.001' if lp < 0.001 else f'= {lp:.3f}'}"])
    add_table(doc, ["Outcome", "ESI, per 1 unit", "FEV₁/FVC, per 0.1",
                    "Adding ESI to FEV₁/FVC"],
              rows, [1.16, 1.86, 1.78, 1.70])
    legend(doc, "Table S7.",
           "Hazard ratios from a single Cox model containing both ESI and "
           "FEV₁/FVC, adjusted for age, sex, race, current smoking status, "
           "pack-years and GOLD stratum. The final column is a likelihood ratio "
           "test on 1 degree of freedom comparing that model with one containing "
           "FEV₁/FVC but not ESI. FEV₁/FVC is scaled per 0.1 unit so the two "
           "coefficients are on comparable scales.")


def s8_esi_trajectory(doc):
    heading(doc, "Supplemental Table S8. Change in ESI over follow-up")
    rows_in = load(ASSETS, "esi_trajectory.csv")
    rows = [[r["stratum"], r["visitnum"], f"{int(r['n']):,}",
             f"{float(r['mean_dESI']):.3f}", f"{float(r['sd_dESI']):.3f}"]
            for r in rows_in]
    add_table(doc, ["Baseline stratum", "Visit", "n",
                    "Mean change from baseline", "SD"],
              rows, [1.50, 0.80, 0.80, 1.90, 1.50])
    legend(doc, "Table S8.",
           "Within-participant change in post-bronchodilator ESI from the "
           "enrollment visit, among participants whose baseline stratum was GOLD 0 "
           "or PRISm. Positive values indicate a rise in ESI, meaning a "
           "flow-volume curve shape further from normal.")


def s9_paired_bootstrap(doc):
    """Whether the two classifications assign different effect sizes to the
    same category. Adjusted only: the crude comparison is not yet computed."""
    heading(doc, "Supplemental Table S9. ESI-MD-COPD compared with MD-COPD")
    rows, seen = [], set()
    label = {"all-cause mortality": "All-cause mortality",
             "respiratory mortality": "Respiratory mortality",
             "exacerbations": "Exacerbations"}
    for r in load(ASSETS, "schema_diff_bootstrap.csv"):
        o = r["outcome"]; pv = float(r["p_two_sided"])
        rows.append([label.get(o, o) if o not in seen else "", r["category"],
                     f"{float(r['ratio_S4_over_S2']):.2f} "
                     f"({float(r['lo']):.2f}–{float(r['hi']):.2f})",
                     "<0.001" if pv < 0.001 else f"{pv:.3f}",
                     f"{int(r['B_eff']):,}"])
        seen.add(o)
    add_table(doc, ["Outcome", "Category", "Ratio of adjusted estimates (95% CI)",
                    "P", "Resamples"],
              rows, [1.52, 1.14, 2.08, 0.86, 0.90])
    legend(doc, "Table S9.",
           "Ratio of the adjusted effect size ESI-MD-COPD assigns to a category "
           "to the one MD-COPD assigns to the same category. Participants were "
           "resampled and both classifications refitted within every resample, so "
           "each pair of estimates comes from the same people; the interval and P "
           "are percentile values from the distribution of the difference in log "
           "estimates. A ratio of 1 means the two assign the same effect size. "
           "Respiratory resamples number fewer than 1,000 because a resample with "
           "too few respiratory events cannot be fitted, and those are dropped for "
           "that outcome only. CI, confidence interval.")


def s12_esi_ct_levels(doc):
    """Dose-response of ESI across the two visual CT scales."""
    heading(doc, "Supplemental Table S12. Mean ESI by visual CT severity")
    rows, seen = [], set()
    for r in load(ASSETS, "esi_ct_levels.csv"):
        c = r["criterion"]
        rows.append([c if c not in seen else "", r["label"],
                     f"{int(r['n']):,}", f"{float(r['mean_ESI']):.2f}"])
        seen.add(c)
    add_table(doc, ["CT criterion", "Level", "n", "Mean ESI"],
              rows, [1.70, 1.90, 1.30, 1.60])
    legend(doc, "Table S12.",
           "Mean ESI at each level of the two visual CT criteria. ESI rises "
           "monotonically across both scales. The MD-COPD framework treats "
           "emphysema as present at mild or greater and wall thickening as "
           "present when definite. Discrimination of these criteria by ESI and "
           "by FEV\u2081/FVC is given in Table 4 of the main text.")


def s13_esi_vs_ffvc(doc):
    """The comparison held out of the main text, with the reason it cannot be
    read as a recommendation."""
    heading(doc, "Supplemental Table S13. ESI and FEV\u2081/FVC compared as "
                 "detectors of the visual CT criteria")
    au = load(ASSETS, "esi_ct_auc.csv")
    ORDER = ["All participants", "Airflow limitation", "Preserved spirometry"]
    rows, seen = [], set()
    for crit in ("Visual emphysema", "Airway wall thickening"):
        for st in ORDER:
            r = next(x for x in au if x["criterion"] == crit and x["stratum"] == st)
            rows.append([crit if crit not in seen else "", st,
                         f"{int(r['n']):,}",
                         f"{float(r['auc_ESI']):.3f}",
                         f"{float(r['auc_FEV1FVC']):.3f}"])
            seen.add(crit)
    add_table(doc, ["CT criterion", "Stratum", "n", "AUC, ESI",
                    "AUC, FEV\u2081/FVC"],
              rows, [1.34, 1.40, 0.74, 1.51, 1.51])
    legend(doc, "Table S13.",
           "FEV\u2081/FVC discriminates both visual CT criteria at least as well as "
           "ESI in five of these six comparisons, and equally to two decimal "
           "places in the sixth. This does not make it a candidate replacement "
           "criterion. FEV\u2081/FVC below 0.70 is already the major criterion, so a "
           "minor criterion defined by a threshold above 0.70 is met by every "
           "participant with airflow limitation and empties the AFL-only category "
           "entirely, while a threshold below 0.70 is met by no participant with "
           "preserved spirometry and so cannot contribute to the COPD-minor "
           "pathway. A replacement criterion has to carry information not already "
           "used by the major criterion. "
           "AUC, area under the receiver operating characteristic curve.")


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
    # A citation can name several tables at once ("Tables S7 and S8",
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
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    doc = init_document()
    p = doc.add_paragraph()
    r = p.add_run("Supplement: Preserving the diagnostic benefit of a "
                  "multidimensional COPD framework without chest CT")
    r.bold = True
    r.font.size = Pt(14)
    doc.add_paragraph("Draft v1. All tables generated from ctfree/assets/.")
    for fn in (s1_baseline, s2_ct, s3_risk_by_outcome, s4_sweep,
               s5_discrimination, s6_fev1_decline, s7_continuous_esi,
               s8_esi_trajectory, s9_paired_bootstrap, s3_crossclass, s4_fitting,
               s12_esi_ct_levels, s13_esi_vs_ffvc):
        fn(doc)
        doc.add_paragraph()
    data_files(doc)
    doc.save(OUT)
    check_citations(SUPP_ORDER)
    print(f"wrote {OUT}\n  {len(SUPP_ORDER)} supplemental tables")


if __name__ == "__main__":
    main()
