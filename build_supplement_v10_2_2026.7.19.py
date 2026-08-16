"""Build the v10.2 supplement docx from scratch.

Differences from v10.1:
- Table of Contents (bookmarks + hyperlinks) at the top.
- S3 split into S3a, S3b, S3c (three sensitivity variants — each a stand-alone re-fit).
- S4 split into S4a, S4b, S4c (three cause-specific Cox models).
- S6a split into S6a.1, S6a.2 (all-cause vs respiratory — distinct fit families).
- S9 split into S9a, S9b (respiratory Cox vs exacerbations NB).
- All retained multi-row tables use vertically-merged cells (via raw w:vMerge).
- Table headers bumped 10 pt bold → 11 pt bold (single source of truth in docx_helpers).
- All shared styling routed through docx_helpers.py (no scattered font-size literals).
"""
import csv, os, sys
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from docx_helpers import (
    FONT_NAME, BODY_FS, TABLE_HEADER_FS, TABLE_BODY_FS, CAPTION_NOTE_FS,
    add_table, body, caption_note, H1, H2,
    render_supp_table, body_toc, add_bookmark, add_internal_hyperlink,
    vmerge_col,
)

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI manuscript supplement v10.2 2026.7.19_PJC.docx"

def norm_group(s):
    """Normalize category labels to lowercase-n convention."""
    if s is None: return s
    return s.replace("AFL-only-NoCOPD", "AFL-only-noCOPD")

def read_csv_(name):
    with open(os.path.join(ASSETS, name)) as f:
        return list(csv.DictReader(f))

def fmt_num(v, digits=2):
    try: f = float(v)
    except (TypeError, ValueError): return str(v) if v is not None else "—"
    if f != f: return "—"
    return f"{f:.{digits}f}"

def fmt_p(v):
    try: f = float(v)
    except (TypeError, ValueError): return str(v) if v is not None else "—"
    if f != f: return "—"
    if f < 0.001: return "<0.001"
    if f < 0.01:  return f"{f:.3f}"
    return f"{f:.2f}"

def fmt_ci(hr, lci, uci):
    try: return f"{float(hr):.2f} ({float(lci):.2f}–{float(uci):.2f})"
    except (TypeError, ValueError): return "—"

# ============================================================================
# Document skeleton
# ============================================================================
doc = Document()
for section in doc.sections:
    section.page_width  = Inches(8.5); section.page_height = Inches(11)
    section.top_margin  = section.bottom_margin = Inches(1)
    section.left_margin = section.right_margin  = Inches(1)

styles = doc.styles
normal = styles["Normal"]; normal.font.name = FONT_NAME; normal.font.size = Pt(BODY_FS)
rPr = normal.element.get_or_add_rPr()
rFonts = rPr.find(qn("w:rFonts"))
if rFonts is None: rFonts = OxmlElement("w:rFonts"); rPr.append(rFonts)
for k in ("w:ascii", "w:hAnsi", "w:cs"): rFonts.set(qn(k), FONT_NAME)

for name, size in [("Heading 1", 14), ("Heading 2", 12), ("Heading 3", 11)]:
    st = styles[name]
    st.font.name = FONT_NAME; st.font.size = Pt(size); st.font.bold = True
    st.font.color.rgb = RGBColor(0, 0, 0)
    st.paragraph_format.space_before = Pt(12); st.paragraph_format.space_after = Pt(4)
normal.paragraph_format.space_after = Pt(8)
normal.paragraph_format.line_spacing = 1.5

# ---- Title page -----------------------------------------------------------
t = doc.add_paragraph(); t.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = t.add_run(
    "Supplementary Materials to "
    "The Emphysema Severity Index: A Spirometric Representation of "
    "CT-Defined Structural Abnormalities in a Multidimensional COPD Framework")
r.font.size = Pt(14); r.bold = True; r.font.name = FONT_NAME

au = doc.add_paragraph(); au.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = au.add_run(
    "Peter J. Castaldi; Matteo Paoletti; Mariaelena Occhipinti; Alessandra Sorano; "
    "Federico Lavorini; Enrico Maiorino; Craig P. Hersh; Edwin K. Silverman; "
    "Massimo Pistolesi")
r.font.size = Pt(BODY_FS); r.font.name = FONT_NAME

dt = doc.add_paragraph(); dt.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = dt.add_run("Supplement v10.2 — 19 July 2026"); r.italic = True
r.font.size = Pt(CAPTION_NOTE_FS); r.font.name = FONT_NAME
r.font.color.rgb = RGBColor(100, 100, 100)

doc.add_paragraph("")

# ============================================================================
# TABLE OF CONTENTS
# ============================================================================
toc_entries = [
    {"num": "S1",    "anchor": "tbl_S1",     "title": "Selection and performance of ESI thresholds"},
    {"num": "S2",    "anchor": "tbl_S2",     "title": "Baseline characteristics of the analytic cohort by stratum"},
    {"num": "S3a",   "anchor": "tbl_S3a",    "title": "Sensitivity analysis — ESI = 10 excluded"},
    {"num": "S3b",   "anchor": "tbl_S3b",    "title": "Sensitivity analysis — 4-criterion alternative framework"},
    {"num": "S3c",   "anchor": "tbl_S3c",    "title": "Sensitivity analysis — severe exacerbations only"},
    {"num": "S4a",   "anchor": "tbl_S4a",    "title": "Cause-specific mortality by category — cardiovascular disease"},
    {"num": "S4b",   "anchor": "tbl_S4b",    "title": "Cause-specific mortality by category — cancer"},
    {"num": "S4c",   "anchor": "tbl_S4c",    "title": "Cause-specific mortality by category — other causes"},
    {"num": "S5",    "anchor": "tbl_S5",     "title": "Longitudinal FEV₁ decline by diagnostic category"},
    {"num": "S6a.1", "anchor": "tbl_S6a_1",  "title": "Continuous ESI as an all-cause mortality predictor"},
    {"num": "S6a.2", "anchor": "tbl_S6a_2",  "title": "Continuous ESI as a respiratory-mortality predictor"},
    {"num": "S6b",   "anchor": "tbl_S6b",    "title": "Continuous ESI as an exacerbation predictor"},
    {"num": "S6c",   "anchor": "tbl_S6c",    "title": "Continuous ESI as a longitudinal FEV₁-decline predictor"},
    {"num": "S7",    "anchor": "tbl_S7",     "title": "Longitudinal ESI trajectories, GOLD 0 versus PRISm"},
    {"num": "S8",    "anchor": "tbl_S8",     "title": "Per-category paired-bootstrap HR difference"},
    {"num": "S9a",   "anchor": "tbl_S9a",    "title": "Table 2 pairwise contrasts — respiratory mortality"},
    {"num": "S9b",   "anchor": "tbl_S9b",    "title": "Table 2 pairwise contrasts — exacerbations"},
]
body_toc(doc, toc_entries)

# ============================================================================
# S1 — Threshold selection
# ============================================================================
s1 = read_csv_("Supp_Table_Thresholds.csv")
render_supp_table(doc,
    table_num="S1",
    title="Selection and performance of ESI thresholds",
    body_text=(
        "Ten candidate two-threshold ESI-scoring configurations were evaluated for "
        "their ability to reproduce the CT-based multidimensional classification. "
        "For each configuration, the ESI-based classification was compared with the "
        "original CT-based framework on the presence-versus-absence of COPD. "
        "The 5-criterion configuration with lower threshold ESI ≤ 1.0 and upper "
        "threshold ESI ≥ 2.5 (denoted [SELECTED]) was retained as the primary framework. "
        "Threshold-selection was informed by a single-variable classification tree "
        "(rpart) developed in a randomly-selected 80% training cohort and evaluated "
        "in the remaining 20%."),
    headers=["Variant", "N COPD", "Sensitivity", "Specificity", "κ"],
    rows=[[r["variant"], r["n_COPD"], fmt_num(r["sens"], 3),
           fmt_num(r["spec"], 3), fmt_num(r["kappa"], 3)] for r in s1],
    caption_note_text=(
        "Comparison is against the CT-based framework on the presence-versus-absence "
        "of COPD. The selected configuration provides the optimal balance among κ, "
        "sensitivity, specificity, and clinical interpretability of the threshold values."))

# ============================================================================
# S2 — Baseline characteristics
# ============================================================================
s2 = read_csv_("Table_S2_baseline_characteristics.csv")
render_supp_table(doc,
    table_num="S2",
    title="Baseline characteristics of the analytic cohort by stratum",
    body_text=(
        "Demographic characteristics, smoking exposure, symptom burden, spirometric "
        "measurements, ESI values, and CT-derived measures across the 9,463-subject "
        "analytic cohort (participants with complete baseline data on all criteria "
        "of the multidimensional diagnostic framework at Visit 1)."),
    headers=["Stratum", "N", "Age", "% female", "% current smoker",
             "BMI", "Pack-years", "FEV1 %pred", "FEV1/FVC", "ESI",
             "%LAA-950HU", "% mMRC ≥ 2", "% SGRQ ≥ 25", "% chronic bronchitis"],
    rows=[[norm_group(r["stratum"]), r["n"], r["age"], r["pct_female"], r["pct_current"],
           r["BMI"], r["pack_years"], r["FEV1_pp"], r["FEV1_FVC"], r["ESI"],
           r["LAA950"], r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]] for r in s2],
    caption_note_text=(
        "Continuous variables are reported as mean (SD); dichotomous variables as %. "
        "Never, GOLD 0, PRISm, and GOLD 1–4 refer to smoking and spirometric status "
        "at baseline. The Overall row is the pooled 9,463-subject analytic cohort."))

# ============================================================================
# S3a / S3b / S3c — three sensitivity variants (SPLIT from v10.1 S3)
# ============================================================================
s3_all = read_csv_("Table_S3_sensitivity.csv")

def render_sensitivity_table(variant_name, variant_label, body_prose, cap_note):
    variant_rows = [r for r in s3_all if r["sensitivity"] == variant_name]
    # Sort by outcome then framework so the merge grouping is consecutive
    outcome_order = {"all-cause": 0, "respiratory": 1, "exacerbations": 2}
    framework_order = {"CT-based": 0, "ESI-based": 1}
    group_order = {"AFL-only-NoCOPD": 0, "COPD-minor": 1, "COPD-major": 2}
    variant_rows.sort(key=lambda r: (
        outcome_order.get(r["outcome"], 99),
        framework_order.get(r["framework"], 99),
        group_order.get(r["group"], 99)))
    return render_supp_table(doc,
        table_num=variant_label,
        title=f"Sensitivity analysis — {body_prose['title_frag']}",
        body_text=body_prose["body"],
        headers=["Outcome", "Framework", "Category", "Estimate (95% CI)", "p"],
        rows=[[r["outcome"], r["framework"], norm_group(r["group"]),
               fmt_ci(r["estimate"], r["LCI"], r["UCI"]), fmt_p(r["p"])] for r in variant_rows],
        caption_note_text=cap_note,
        vmerge_cols=[0, 1])

render_sensitivity_table(
    variant_name="ESI=10 excluded",
    variant_label="S3a",
    body_prose={
        "title_frag": "ESI = 10 excluded",
        "body": (
            "Pre-specified sensitivity analysis: participants with ESI at the upper "
            "boundary of the scale (ESI = 10) are excluded, testing sensitivity of "
            "the primary by-category framework comparison to the ceiling effect. "
            "Estimates are hazard ratios (HR, 95% CI) for mortality outcomes and "
            "incidence-rate ratios (IRR, 95% CI) for exacerbations; reference "
            "category is noCOPD.")},
    cap_note=(
        "Fit families: Cox proportional-hazards models for all-cause and respiratory "
        "mortality, negative-binomial regression for exacerbations. Covariates: age, "
        "sex, race, current smoking status, pack-years, body mass index."))

render_sensitivity_table(
    variant_name="4-criterion alt",
    variant_label="S3b",
    body_prose={
        "title_frag": "4-criterion alternative framework",
        "body": (
            "Pre-specified sensitivity analysis: an alternative four-criterion "
            "framework in which ESI is collapsed to a single ≥ 1.5 cutoff (instead "
            "of the primary 5-criterion two-threshold rule) and the "
            "≥ 3-of-N COPD-minor threshold is preserved by using ≥ 3 of 4 minor "
            "criteria. This is a stress test of the primary framework, not a "
            "competing primary framework.")},
    cap_note=(
        "Same fit families and covariates as S3a."))

# S3c is smaller — only the exacerbation outcome (severe exacerbations)
s3c_rows = [r for r in s3_all if r["sensitivity"] == "severe exac only"]
render_supp_table(doc,
    table_num="S3c",
    title="Sensitivity analysis — severe exacerbations only",
    body_text=(
        "Pre-specified sensitivity analysis: total exacerbation count replaced by "
        "severe-exacerbation count as the negative-binomial outcome; all other model "
        "covariates unchanged from Table 1."),
    headers=["Framework", "Category", "IRR (95% CI)", "p"],
    rows=[[r["framework"], norm_group(r["group"]),
           fmt_ci(r["estimate"], r["LCI"], r["UCI"]), fmt_p(r["p"])] for r in s3c_rows],
    caption_note_text=(
        "Log(years followed) offset. Covariates: age, sex, race, current smoking "
        "status, pack-years, body mass index."),
    vmerge_cols=[0])

# ============================================================================
# S4a / S4b / S4c — three cause-specific Cox models (SPLIT from v10.1 S4)
# ============================================================================
s4_all = read_csv_("Table_CauseSpecific_byClass.csv")

def render_cause_specific_table(cause_key, label, cause_title, cause_slug):
    cause_rows = [r for r in s4_all if r["cause"] == cause_key]
    return render_supp_table(doc,
        table_num=label,
        title=f"Cause-specific mortality by category — {cause_title}",
        body_text=(
            f"Cox proportional-hazards model for {cause_slug}-cause mortality by "
            "diagnostic category, both frameworks head-to-head (reference: noCOPD). "
            "Non-target deaths were censored at the date of death (cause-specific "
            "hazards)."),
        headers=["Category", "CT events", "CT HR (95% CI)", "CT p",
                 "ESI events", "ESI HR (95% CI)", "ESI p"],
        rows=[[norm_group(r["group"]), r["n_events_bhatt"],
               fmt_ci(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]),
               fmt_p(r["bhatt_p"]), r["n_events_esi"],
               fmt_ci(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),
               fmt_p(r["esi_p"])] for r in cause_rows],
        caption_note_text=(
            "Covariates: age, sex, race, current smoking status, pack-years, body "
            "mass index. All-cause and respiratory-cause mortality are reported in "
            "the main manuscript Table 1."))

render_cause_specific_table("CVD",    "S4a", "cardiovascular disease", "cardiovascular")
render_cause_specific_table("Cancer", "S4b", "cancer",                 "cancer")
render_cause_specific_table("Other",  "S4c", "other causes",           "other-cause")

# ============================================================================
# S5 — FEV1 decline by category (KEPT — CT vs ESI is the point)
# ============================================================================
s5 = read_csv_("Table_BhattDecline.csv")
render_supp_table(doc,
    table_num="S5",
    title="Longitudinal FEV₁ decline by diagnostic category",
    body_text=(
        "Linear mixed-effects models of longitudinal FEV₁ (Visits 1–3, "
        "approximately 10 years of follow-up) by diagnostic category, both "
        "frameworks head-to-head. The estimate is the additional mL/year decline "
        "relative to noCOPD (the reference category). The two-framework comparison "
        "is the point: for each category, do CT-based and ESI-based frameworks "
        "yield similar decline coefficients?"),
    headers=["Category", "CT-based estimate (mL/yr)", "SE", "p",
             "ESI-based estimate (mL/yr)", "SE", "p"],
    rows=[[norm_group(r["group"]), fmt_num(r["bhatt_est"], 2), fmt_num(r["bhatt_se"], 2),
           fmt_p(r["bhatt_p"]), fmt_num(r["esi_est"], 2),
           fmt_num(r["esi_se"], 2), fmt_p(r["esi_p"])] for r in s5],
    caption_note_text=(
        "Random subject intercept; adjusted for baseline height, gender, race, age "
        "at visit, current smoking status, and pack-years."))

# ============================================================================
# S6a.1 / S6a.2 — SPLIT continuous-ESI mortality tables
# ============================================================================
s6a = read_csv_("Table_S6a_continuous_mortality.csv")

def render_continuous_mortality_table(outcome_key, label, outcome_title):
    outcome_rows = [r for r in s6a if r["outcome"] == outcome_key]
    return render_supp_table(doc,
        table_num=label,
        title=f"Continuous ESI as a{'n' if outcome_title.startswith('all') else ''} {outcome_title} predictor",
        body_text=(
            f"Cox proportional-hazards models of {outcome_title} with baseline ESI "
            "as a continuous predictor. Nested-model progression: ESI only → "
            "FEV₁/FVC only → ESI + FEV₁/FVC. Likelihood-ratio test compares the "
            "combined model to the FEV₁/FVC-only nested model."),
        headers=["Model", "ESI HR (95% CI)", "ESI p",
                 "FEV₁/FVC HR (95% CI)", "FEV₁/FVC p",
                 "LR vs FEV₁/FVC only"],
        rows=[[r["model"], r["ESI_HR"], r["ESI_p"], r["FEV1FVC_HR"],
               r["FEV1FVC_p"], r["LR_vs_FEV1FVC_only"]] for r in outcome_rows],
        caption_note_text=(
            "HR per 1-unit ESI; FEV₁/FVC HR is per 0.1-unit decrease. Adjusted "
            "for age, sex, race, current smoking status, pack-years, and stratum."))

render_continuous_mortality_table("all-cause",   "S6a.1", "all-cause mortality")
render_continuous_mortality_table("respiratory", "S6a.2", "respiratory-mortality")

# ============================================================================
# S6b — Continuous ESI, exacerbations
# ============================================================================
s6b = read_csv_("Table_S6b_continuous_exacerbations.csv")
render_supp_table(doc,
    table_num="S6b",
    title="Continuous ESI as an exacerbation predictor",
    body_text=(
        "Negative-binomial regression of prospective exacerbation count with "
        "baseline ESI as a continuous predictor. Nested-model progression as in "
        "S6a.1. Effect metric is IRR per 1-unit ESI (or per 0.1-unit FEV₁/FVC "
        "decrease)."),
    headers=["Model", "ESI IRR (95% CI)", "ESI p",
             "FEV₁/FVC IRR (95% CI)", "FEV₁/FVC p",
             "LR vs FEV₁/FVC only"],
    rows=[[r["model"], r["ESI_IRR"], r["ESI_p"], r["FEV1FVC_IRR"],
           r["FEV1FVC_p"], r["LR_vs_FEV1FVC_only"]] for r in s6b],
    caption_note_text=(
        "Log(years followed) offset. Covariates as in S6a.1."))

# ============================================================================
# S6c — Continuous ESI, FEV1 decline (KEPT — stratum comparison is the finding)
# ============================================================================
s6c = read_csv_("Table_S6c_continuous_fev1_decline.csv")
render_supp_table(doc,
    table_num="S6c",
    title="Continuous ESI as a longitudinal FEV₁-decline predictor",
    body_text=(
        "Linear mixed-effects models of longitudinal FEV₁ by baseline stratum. "
        "The point of the table is the stratum contrast: GOLD 0 smokers with "
        "preserved spirometry show an ESI-associated FEV₁ decline slope, whereas "
        "PRISm and the pooled cohort do not. Effect metric is mL per year per "
        "1-unit ESI (interaction of baseline ESI with follow-up time)."),
    headers=["Stratum", "N subjects", "Model",
             "ESI slope (mL/yr)", "ESI p",
             "FEV₁/FVC slope (mL/yr)", "FEV₁/FVC p"],
    rows=[[r["stratum"], r["n_subj"], r["model"],
           r["ESI_slope_mL_yr"], r["ESI_p"],
           r["FEV1FVC_slope_mL_yr"], r["FEV1FVC_p"]] for r in s6c],
    caption_note_text=(
        "FEV₁/FVC slope is the analogous time-interaction of baseline FEV₁/FVC. "
        "Both predictors are Visit-1 baselines."),
    vmerge_cols=[0, 1])

# ============================================================================
# S7 — ESI trajectories
# ============================================================================
s7 = read_csv_("Supp_Table_S7_ESI_trajectory.csv")
render_supp_table(doc,
    table_num="S7",
    title="Longitudinal ESI trajectories, GOLD 0 versus PRISm",
    body_text=(
        "Within-subject change in ESI (post-bronchodilator) from Visit 1 to "
        "subsequent visits, stratified by baseline GOLD 0 versus PRISm status."),
    headers=["Baseline stratum", "Visit", "N", "Mean ΔESI", "Median ΔESI"],
    rows=[[r["stratum_baseline"], r["visitnum"], r["n"],
           fmt_num(r["mean_dESI"], 3), fmt_num(r["median_dESI"], 3)] for r in s7],
    caption_note_text=(
        "ΔESI = ESI at follow-up visit − ESI at Visit 1, computed within subject. "
        "Rows show the number of subjects with an ESI observation at each "
        "follow-up visit and the pooled mean and median ΔESI within stratum."),
    vmerge_cols=[0])

# ============================================================================
# S8 — Per-category paired-bootstrap HR difference (KEPT — 2×2 grid comparison)
# ============================================================================
s8 = read_csv_("Supp_Table_HR_Difference_Bootstrap.csv")
render_supp_table(doc,
    table_num="S8",
    title="Per-category paired-bootstrap HR difference",
    body_text=(
        "Paired subject-resample of the 9,463-subject analytic cohort "
        "(B = 1,000 resamples; seed = 20260717). In each resample, the four "
        "category-level Cox models (CT-based and ESI-based, all-cause and "
        "respiratory mortality) were re-fit and log(HR_CT) − log(HR_ESI) was "
        "recorded. Two-sided empirical p is 2 × min(mean(Δ ≤ 0), mean(Δ ≥ 0)); "
        "B_effective / B = 978 / 1000. The p < 0.002 resolution floor reflects "
        "the B = 1,000 grid. The 2×2 outcome-by-category grid is presented "
        "together so patterns can be read across all four cells (COPD-major is "
        "detectable in both outcomes; COPD-minor is not)."),
    headers=["Outcome", "Category", "HR (CT)", "HR (ESI)",
             "Absolute HR diff", "Mean ΔlogHR", "95% CI (ΔlogHR)",
             "Two-sided p"],
    rows=[[r["outcome"], r["category"], fmt_num(r["HR_CT"], 2),
           fmt_num(r["HR_ESI"], 2), fmt_num(r["abs_HR_diff"], 2),
           fmt_num(r["mean_logHR_diff"], 3),
           f"({fmt_num(r['ci_lo_logHR'], 3)}, {fmt_num(r['ci_hi_logHR'], 3)})",
           r["two_sided_p_reported"]] for r in s8],
    caption_note_text=(
        "Companion to main-manuscript Table 1. The paired resample keeps subject "
        "matching intact so log(HR_CT) − log(HR_ESI) is estimated on the same "
        "subjects at each iteration."),
    vmerge_cols=[0])

# ============================================================================
# S9a / S9b — SPLIT Table 2 pairwise contrasts
# ============================================================================
pw_all = read_csv_("Table_2_pairwise_contrasts.csv")

def render_pairwise_table(outcome_key, label, outcome_title, metric_name, model_family):
    rows_out = [r for r in pw_all if r["outcome"] == outcome_key]
    return render_supp_table(doc,
        table_num=label,
        title=f"Table 2 pairwise contrasts — {outcome_title}",
        body_text=(
            f"Pairwise Wald contrasts among Both-COPD, Bhatt-only-COPD, and "
            f"ESI-only-COPD from the {model_family} cross-classification model on "
            "preserved-spirometry participants (Table 2 in the main manuscript). "
            "Contrasts are estimated from the single fit with the four-level "
            "discord predictor; p-values are single-step-adjusted over the three "
            "reported pairs."),
        headers=["Contrast", f"Estimate ({metric_name})", "SE", "Adjusted p"],
        rows=[[r["contrast"], fmt_num(r["est_logHR"], 3),
               fmt_num(r["se_logHR"], 3), fmt_p(r["p_adj"])] for r in rows_out],
        caption_note_text=(
            f"Estimates on the {metric_name} scale. The corresponding all-cause-"
            "mortality contrasts appear in the Table 2 footnote in the main manuscript."))

render_pairwise_table(
    outcome_key="respiratory mortality", label="S9a",
    outcome_title="respiratory mortality", metric_name="log HR",
    model_family="Cox proportional-hazards")
render_pairwise_table(
    outcome_key="exacerbations", label="S9b",
    outcome_title="exacerbations", metric_name="log IRR",
    model_family="negative-binomial")

# ============================================================================
# Save + report
# ============================================================================
doc.save(OUT)
print(f"Wrote: {OUT}")

d2 = Document(OUT)
n_tables = len(d2.tables)
n_paras  = len(d2.paragraphs)
print(f"Post-save: {n_paras} paragraphs, {n_tables} tables")
assert n_tables == 17, f"Expected 17 tables, got {n_tables}"
print("All 17 tables (S1, S2, S3a, S3b, S3c, S4a, S4b, S4c, S5, S6a.1, S6a.2, "
      "S6b, S6c, S7, S8, S9a, S9b) rendered.")
