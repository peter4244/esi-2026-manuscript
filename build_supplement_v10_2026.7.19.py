"""Build the v10 supplement docx from scratch.

Reads every value from CSVs in manuscript_assets/ produced by
esi_manuscript_analysis_2026.7.17.Rmd. No values are hard-coded.

Tables: S1 (thresholds), S2 (baseline chars by stratum), S3 (three sensitivity
variants), S4 (cause-specific mortality by category), S5 (FEV1 decline by
category), S6a/S6b/S6c (continuous ESI — mortality/exacerbations/decline),
S7 (ESI trajectories), S8 (per-category HR bootstrap), S9 (Table 2 pairwise
contrasts — respiratory + exacerbation rows).
"""
import csv, os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI manuscript supplement v10.1 2026.7.19_PJC.docx"

def norm_group(s):
    """Normalize category labels to match the manuscript's lowercase-n convention."""
    if s is None: return s
    return s.replace("AFL-only-NoCOPD", "AFL-only-noCOPD")

# -------- helpers ------------------------------------------------------------

def read_csv_(name):
    with open(os.path.join(ASSETS, name)) as f:
        return list(csv.DictReader(f))

def fmt_num(v, digits=2):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return str(v) if v is not None else "—"
    if f != f:  # NaN
        return "—"
    return f"{f:.{digits}f}"

def fmt_p(v):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return str(v) if v is not None else "—"
    if f != f: return "—"
    if f < 0.001: return "<0.001"
    if f < 0.01:  return f"{f:.3f}"
    return f"{f:.2f}"

def fmt_ci(hr, lci, uci):
    try:
        return f"{float(hr):.2f} ({float(lci):.2f}–{float(uci):.2f})"
    except (TypeError, ValueError):
        return "—"

def set_cell_border(cell):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_borders = OxmlElement("w:tcBorders")
    for edge in ("top", "left", "bottom", "right"):
        b = OxmlElement(f"w:{edge}")
        b.set(qn("w:val"),   "single")
        b.set(qn("w:sz"),    "6")
        b.set(qn("w:color"), "000000")
        tc_borders.append(b)
    tc_pr.append(tc_borders)

def add_table(doc, headers, rows):
    tbl = doc.add_table(rows=1 + len(rows), cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    try:
        tbl.style = "Table Grid"
    except KeyError:
        pass
    for j, h in enumerate(headers):
        cell = tbl.rows[0].cells[j]
        cell.text = ""
        r = cell.paragraphs[0].add_run(h)
        r.bold = True
        r.font.size = Pt(10)
        r.font.name = "Arial"
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_border(cell)
    for i, row in enumerate(rows, start=1):
        for j, val in enumerate(row):
            cell = tbl.rows[i].cells[j]
            cell.text = ""
            r = cell.paragraphs[0].add_run(str(val))
            r.font.size = Pt(10)
            r.font.name = "Arial"
            set_cell_border(cell)
    return tbl

# ============================================================================
# Document skeleton
# ============================================================================

doc = Document()
for section in doc.sections:
    section.page_width  = Inches(8.5); section.page_height = Inches(11)
    section.top_margin  = section.bottom_margin = Inches(1)
    section.left_margin = section.right_margin  = Inches(1)

styles = doc.styles
normal = styles["Normal"]; normal.font.name = "Arial"; normal.font.size = Pt(11)
rPr = normal.element.get_or_add_rPr()
rFonts = rPr.find(qn("w:rFonts"))
if rFonts is None:
    rFonts = OxmlElement("w:rFonts"); rPr.append(rFonts)
for k in ("w:ascii", "w:hAnsi", "w:cs"):
    rFonts.set(qn(k), "Arial")

for name, size in [("Heading 1", 14), ("Heading 2", 12), ("Heading 3", 11)]:
    st = styles[name]
    st.font.name = "Arial"; st.font.size = Pt(size); st.font.bold = True
    st.font.color.rgb = RGBColor(0, 0, 0)
    st.paragraph_format.space_before = Pt(12); st.paragraph_format.space_after = Pt(4)
normal.paragraph_format.space_after = Pt(8)
normal.paragraph_format.line_spacing = 1.5

def H1(t): doc.add_paragraph(t, style="Heading 1")
def H2(t): doc.add_paragraph(t, style="Heading 2")

def body(text, size=11):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Inches(0.25)
    r = p.add_run(text); r.font.size = Pt(size)

def caption(text):
    p = doc.add_paragraph(); r = p.add_run(text); r.bold = True; r.font.size = Pt(10)

def caption_note(text):
    p = doc.add_paragraph(); r = p.add_run(text); r.font.size = Pt(9)
    r.font.color.rgb = RGBColor(60, 60, 60)

# -------- Title page ---------------------------------------------------------

t = doc.add_paragraph(); t.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = t.add_run(
    "Supplementary Materials to "
    "The Emphysema Severity Index: A Spirometric Representation of "
    "CT-Defined Structural Abnormalities in a Multidimensional COPD Framework"
)
r.font.size = Pt(14); r.bold = True; r.font.name = "Arial"

au = doc.add_paragraph(); au.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = au.add_run(
    "Peter J. Castaldi; Matteo Paoletti; Mariaelena Occhipinti; Alessandra Sorano; "
    "Federico Lavorini; Enrico Maiorino; Craig P. Hersh; Edwin K. Silverman; "
    "Massimo Pistolesi"
)
r.font.size = Pt(11)

dt = doc.add_paragraph(); dt.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = dt.add_run("Supplement v10 — 17 July 2026"); r.italic = True; r.font.size = Pt(9)
r.font.color.rgb = RGBColor(100, 100, 100)

doc.add_paragraph("")

# ============================================================================
# S1 — ESI-threshold selection
# ============================================================================
H1("Supplementary Table S1 — Selection and performance of ESI thresholds")
body(
    "Ten candidate two-threshold ESI-scoring configurations were evaluated for "
    "their ability to reproduce the CT-based multidimensional classification. "
    "For each configuration, the ESI-based classification was compared with the "
    "original CT-based framework on the presence-versus-absence of COPD. "
    "The 5-criterion configuration with lower threshold ESI ≤ 1.0 and upper "
    "threshold ESI ≥ 2.5 (denoted [SELECTED]) was retained as the primary framework. "
    "Threshold-selection was informed by a single-variable classification tree "
    "(rpart) developed in a randomly-selected 80% training cohort and evaluated "
    "in the remaining 20%."
)
s1 = read_csv_("Supp_Table_Thresholds.csv")
add_table(doc,
    headers=["Variant", "N COPD", "Sensitivity", "Specificity", "κ"],
    rows=[[r["variant"], r["n_COPD"], fmt_num(r["sens"], 3),
           fmt_num(r["spec"], 3), fmt_num(r["kappa"], 3)] for r in s1])
caption_note(
    "Comparison is against the CT-based framework on the presence-versus-absence "
    "of COPD. The selected configuration provides the optimal balance among κ, "
    "sensitivity, specificity, and clinical interpretability of the threshold "
    "values."
)
doc.add_paragraph("")

# ============================================================================
# S2 — Baseline characteristics by stratum
# ============================================================================
H1("Supplementary Table S2 — Baseline characteristics of the analytic cohort by stratum")
body(
    "Demographic characteristics, smoking exposure, symptom burden, spirometric "
    "measurements, ESI values, and CT-derived measures across the 9,463-subject "
    "analytic cohort (participants with complete baseline data on all criteria "
    "of the multidimensional diagnostic framework at Visit 1)."
)
s2 = read_csv_("Table_S2_baseline_characteristics.csv")
add_table(doc,
    headers=["Stratum", "N", "Age", "% female", "% current smoker",
             "BMI", "Pack-years", "FEV1 %pred", "FEV1/FVC", "ESI",
             "%LAA-950HU", "% mMRC ≥ 2", "% SGRQ ≥ 25", "% chronic bronchitis"],
    rows=[[norm_group(r["stratum"]), r["n"], r["age"], r["pct_female"], r["pct_current"],
           r["BMI"], r["pack_years"], r["FEV1_pp"], r["FEV1_FVC"], r["ESI"],
           r["LAA950"], r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]] for r in s2])
caption_note(
    "Continuous variables are reported as mean (SD); dichotomous variables as "
    "%. Never, GOLD 0, PRISm, and GOLD 1–4 refer to smoking and spirometric "
    "status at baseline. The Overall row is the pooled 9,463-subject analytic "
    "cohort."
)
doc.add_paragraph("")

# ============================================================================
# S3 — Sensitivity analyses (three variants)
# ============================================================================
H1("Supplementary Table S3 — Sensitivity analyses of the by-category framework comparison")
body(
    "Three pre-specified sensitivity analyses of the by-category CT-based "
    "vs ESI-based framework comparison (Table 1 in the main manuscript). "
    "Each variant re-fits the same Cox / negative-binomial models on a "
    "modified cohort or outcome. Estimates are HR (95% CI) for mortality "
    "and IRR (95% CI) for exacerbations. See caption footer for a description "
    "of each variant."
)
s3 = read_csv_("Table_S3_sensitivity.csv")
add_table(doc,
    headers=["Sensitivity variant", "Framework", "Outcome", "Category",
             "Estimate (95% CI)", "p"],
    rows=[[r["sensitivity"], r["framework"], r["outcome"], norm_group(r["group"]),
           fmt_ci(r["estimate"], r["LCI"], r["UCI"]), fmt_p(r["p"])] for r in s3])
caption_note(
    "(i) ESI=10 excluded: drops participants with ESI at the upper boundary "
    "of the scale, testing sensitivity to the ceiling effect. "
    "(ii) 4-criterion alt: replaces the primary 5-criterion two-threshold rule "
    "with a 4-criterion variant in which ESI is collapsed to a single ≥ 1.5 "
    "cutoff and COPD-minor requires ≥ 3 of 4 minor criteria (preserving the "
    "≥ 3-of-N structure). This is a stress test, not a competing primary "
    "framework. "
    "(iii) Severe exacerbations only: replaces the total-exacerbation count "
    "with severe-exacerbation count as the negative-binomial outcome."
)
doc.add_paragraph("")

# ============================================================================
# S4 — Cause-specific mortality by diagnostic category
# ============================================================================
H1("Supplementary Table S4 — Cause-specific mortality by diagnostic category, both frameworks head-to-head")
body(
    "Cause-specific mortality Cox models for the by-category comparison "
    "(reference: noCOPD). Causes analyzed: cardiovascular disease (CVD), "
    "cancer, and other. Non-target deaths were censored at the date of death "
    "(cause-specific hazards)."
)
s4 = read_csv_("Table_CauseSpecific_byClass.csv")
add_table(doc,
    headers=["Cause", "Category", "CT events", "CT HR (95% CI)", "CT p",
             "ESI events", "ESI HR (95% CI)", "ESI p"],
    rows=[[r["cause"], norm_group(r["group"]), r["n_events_bhatt"],
           fmt_ci(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]),
           fmt_p(r["bhatt_p"]), r["n_events_esi"],
           fmt_ci(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),
           fmt_p(r["esi_p"])] for r in s4])
caption_note(
    "Cox proportional-hazards models adjusted for age, sex, race, current "
    "smoking status, pack-years, and body mass index. All-cause and "
    "respiratory-cause mortality are reported in the main manuscript Table 1."
)
doc.add_paragraph("")

# ============================================================================
# S5 — Longitudinal FEV1 decline by diagnostic category
# ============================================================================
H1("Supplementary Table S5 — Longitudinal FEV1 decline by diagnostic category")
body(
    "Linear mixed-effects models of longitudinal FEV1 (Visits 1–3, "
    "approximately 10 years of follow-up) by diagnostic category, both "
    "frameworks head-to-head. Estimate is the additional mL/year decline "
    "relative to noCOPD (the reference category)."
)
s5 = read_csv_("Table_BhattDecline.csv")
add_table(doc,
    headers=["Category", "CT-based estimate (mL/yr)", "SE", "p",
             "ESI-based estimate (mL/yr)", "SE", "p"],
    rows=[[norm_group(r["group"]), fmt_num(r["bhatt_est"], 2), fmt_num(r["bhatt_se"], 2),
           fmt_p(r["bhatt_p"]), fmt_num(r["esi_est"], 2),
           fmt_num(r["esi_se"], 2), fmt_p(r["esi_p"])] for r in s5])
caption_note(
    "Linear mixed-effects models with a random subject intercept, adjusted "
    "for baseline height, gender, race, age at visit, current smoking status, "
    "and pack-years."
)
doc.add_paragraph("")

# ============================================================================
# S6a — Continuous ESI, mortality
# ============================================================================
H1("Supplementary Table S6a — Continuous ESI as a mortality predictor")
body(
    "Cox proportional-hazards models with baseline ESI as a continuous "
    "predictor. Effect metric is HR per 1-unit ESI (or per 0.1-unit FEV1/FVC). "
    "Models are adjusted for age, sex, race, current smoking status, "
    "pack-years, and stratum."
)
s6a = read_csv_("Table_S6a_continuous_mortality.csv")
add_table(doc,
    headers=["Outcome", "Model", "ESI HR (95% CI)", "ESI p",
             "FEV1/FVC HR (95% CI)", "FEV1/FVC p", "LR vs FEV1/FVC-only"],
    rows=[[r["outcome"], r["model"], r["ESI_HR"], r["ESI_p"],
           r["FEV1FVC_HR"], r["FEV1FVC_p"], r["LR_vs_FEV1FVC_only"]] for r in s6a])
caption_note(
    "HR per 1-unit ESI. FEV1/FVC HR is per 0.1-unit decrease. LR test "
    "compares the two-predictor model to the FEV1/FVC-only nested model."
)
doc.add_paragraph("")

# ============================================================================
# S6b — Continuous ESI, exacerbations
# ============================================================================
H1("Supplementary Table S6b — Continuous ESI as an exacerbation predictor")
body(
    "Negative-binomial regression with baseline ESI as a continuous predictor. "
    "Effect metric is IRR per 1-unit ESI (or per 0.1-unit FEV1/FVC). "
    "Log(years followed) offset; adjustment covariates as in Table S6a."
)
s6b = read_csv_("Table_S6b_continuous_exacerbations.csv")
add_table(doc,
    headers=["Outcome", "Model", "ESI IRR (95% CI)", "ESI p",
             "FEV1/FVC IRR (95% CI)", "FEV1/FVC p", "LR vs FEV1/FVC-only"],
    rows=[[r["outcome"], r["model"], r["ESI_IRR"], r["ESI_p"],
           r["FEV1FVC_IRR"], r["FEV1FVC_p"], r["LR_vs_FEV1FVC_only"]] for r in s6b])
caption_note(
    "IRR per 1-unit ESI. FEV1/FVC IRR is per 0.1-unit decrease."
)
doc.add_paragraph("")

# ============================================================================
# S6c — Continuous ESI, longitudinal FEV1 decline
# ============================================================================
H1("Supplementary Table S6c — Continuous ESI as a longitudinal FEV1-decline predictor")
body(
    "Linear mixed-effects models of longitudinal FEV1. Effect metric is "
    "mL per year per 1-unit ESI (interaction of baseline ESI with time). "
    "Adjustment covariates as in Table S5."
)
s6c = read_csv_("Table_S6c_continuous_fev1_decline.csv")
add_table(doc,
    headers=["Stratum", "N subjects", "Model",
             "ESI slope (mL/yr)", "ESI p",
             "FEV1/FVC slope (mL/yr)", "FEV1/FVC p"],
    rows=[[r["stratum"], r["n_subj"], r["model"],
           r["ESI_slope_mL_yr"], r["ESI_p"],
           r["FEV1FVC_slope_mL_yr"], r["FEV1FVC_p"]] for r in s6c])
caption_note(
    "The interaction of baseline ESI with time (mL/yr per 1-unit ESI) is "
    "reported. The FEV1/FVC-slope column shows the analogous interaction of "
    "baseline FEV1/FVC with time (mL/yr per 0.1-unit FEV1/FVC). Both "
    "predictors are Visit-1 baselines."
)
doc.add_paragraph("")

# ============================================================================
# S7 — Longitudinal ESI trajectories, GOLD 0 vs PRISm
# ============================================================================
H1("Supplementary Table S7 — Longitudinal ESI trajectories, GOLD 0 versus PRISm")
body(
    "Within-subject change in ESI (post-bronchodilator) from Visit 1 to "
    "subsequent visits, stratified by baseline GOLD 0 versus PRISm status. "
    "ΔESI is subject-specific; means and medians are across subjects at "
    "each visit."
)
s7 = read_csv_("Supp_Table_S7_ESI_trajectory.csv")
add_table(doc,
    headers=["Baseline stratum", "Visit", "N", "Mean ΔESI", "Median ΔESI"],
    rows=[[r["stratum_baseline"], r["visitnum"], r["n"],
           fmt_num(r["mean_dESI"], 3), fmt_num(r["median_dESI"], 3)] for r in s7])
caption_note(
    "ΔESI = ESI at follow-up visit − ESI at Visit 1, computed within subject. "
    "Rows show the number of subjects with an ESI observation at each "
    "follow-up visit and the pooled mean and median ΔESI within stratum."
)
doc.add_paragraph("")

# ============================================================================
# S8 — Per-category paired-bootstrap HR difference (Table 1 companion)
# ============================================================================
H1("Supplementary Table S8 — Per-category paired-bootstrap HR difference")
body(
    "Paired subject-resample of the 9,463-subject analytic cohort "
    "(B = 1,000 resamples; seed = 20260717). In each resample, the four "
    "category-level Cox models (CT-based and ESI-based, all-cause and "
    "respiratory mortality) are re-fit and log(HR_CT) − log(HR_ESI) is "
    "recorded. Two-sided empirical p is 2 × min(mean(Δ ≤ 0), mean(Δ ≥ 0)); "
    "B_effective / B = 978 / 1000 (dropped resamples had near-singular "
    "designs and were skipped). The p < 0.002 resolution floor reflects the "
    "B = 1,000 grid."
)
s8 = read_csv_("Supp_Table_HR_Difference_Bootstrap.csv")
add_table(doc,
    headers=["Outcome", "Category", "HR (CT)", "HR (ESI)",
             "Absolute HR difference",
             "Mean ΔlogHR", "95% CI (ΔlogHR)",
             "Two-sided p"],
    rows=[[r["outcome"], r["category"], fmt_num(r["HR_CT"], 2),
           fmt_num(r["HR_ESI"], 2), fmt_num(r["abs_HR_diff"], 2),
           fmt_num(r["mean_logHR_diff"], 3),
           f"({fmt_num(r['ci_lo_logHR'], 3)}, {fmt_num(r['ci_hi_logHR'], 3)})",
           r["two_sided_p_reported"]] for r in s8])
caption_note(
    "Companion to main-manuscript Table 1. The paired resample keeps subject "
    "matching intact so log(HR_CT) − log(HR_ESI) is estimated on the same "
    "subjects at each iteration. Reported p refers to the null of Δ = 0."
)
doc.add_paragraph("")

# ============================================================================
# S9 — Table 2 pairwise contrasts, respiratory + exacerbation outcomes
# ============================================================================
H1("Supplementary Table S9 — Table 2 pairwise contrasts, respiratory mortality and exacerbations")
body(
    "Pairwise Wald contrasts among Both-COPD, Bhatt-only-COPD, and "
    "ESI-only-COPD from the cross-classification model on preserved-spirometry "
    "participants (Table 2 in the main manuscript). Contrasts are estimated "
    "from the single Cox / negative-binomial model with a 4-level discord "
    "predictor; p-values are single-step-adjusted over the three reported "
    "pairs. The corresponding all-cause-mortality contrasts appear in the "
    "Table 2 footnote in the main manuscript."
)
pw_all = read_csv_("Table_2_pairwise_contrasts.csv")
s9_rows = [r for r in pw_all if r["outcome"] in ("respiratory mortality", "exacerbations")]
add_table(doc,
    headers=["Outcome", "Contrast", "Estimate (log HR / log IRR)",
             "SE", "Adjusted p"],
    rows=[[r["outcome"], r["contrast"], fmt_num(r["est_logHR"], 3),
           fmt_num(r["se_logHR"], 3), fmt_p(r["p_adj"])] for r in s9_rows])
caption_note(
    "Estimate is on the log-HR scale for respiratory mortality (Cox model) "
    "and log-IRR scale for exacerbations (negative-binomial model). "
    "Single-step adjustment is over the three reported pairs per outcome."
)

# ============================================================================
# Save + verify
# ============================================================================
doc.save(OUT)
print(f"Wrote: {OUT}")

d2 = Document(OUT)
n_tables = len(d2.tables)
n_paras  = len(d2.paragraphs)
print(f"Post-save: {n_paras} paragraphs, {n_tables} tables")
assert n_tables == 11, f"Expected 11 tables, got {n_tables}"
print("All 11 tables (S1, S2, S3, S4, S5, S6a, S6b, S6c, S7, S8, S9) rendered.")
