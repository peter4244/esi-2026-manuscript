"""Build the ESI manuscript OUTLINE Word document — 2026-06-22 revision.
Incorporates Massimo's comments and the new analyses (respiratory mortality,
Figure 3 redesign, Figure 6 PRISm/GOLD0 trajectory, CT-substitution diagnostics,
BD-insensitivity discussion).
"""
# ---- RETIRED 2026-08-25 -----------------------------------------------------
# This built the June outline (ESI_manuscript_outline_2026.6.25_v3.docx), which
# no longer exists and is superseded by the v12 manuscript draft. It is retired
# for the same reason build_manuscript.py is, plus one of its own: its 13 input
# CSVs were stale outputs of the ILD-inclusive, CCOD-era analysis (n = 10,043;
# 1,163 respiratory deaths, more than the entire TORCH respiratory total of
# 704). Those files were deleted on 2026-08-25 because nothing else read them
# and they were a silent-drift hazard, so this script can no longer run anyway.
#
# Recovering it means regenerating its inputs from the current analysis, not
# restoring the deleted CSVs: they held superseded numbers.
raise SystemExit(
    "build_outline_docx.py is retired. It built the superseded June outline "
    "from stale ILD-inclusive, CCOD-era CSVs that were deleted on 2026-08-25. "
    "The v12 manuscript .docx is the source of truth; edit it with python-docx."
)

import csv, os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI_manuscript_outline_2026.6.25_v3.docx"
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = Document()

for section in doc.sections:
    section.page_width = Inches(8.5); section.page_height = Inches(11)
    section.top_margin = section.bottom_margin = Inches(1)
    section.left_margin = section.right_margin = Inches(1)

styles = doc.styles
normal = styles["Normal"]; normal.font.name = "Arial"; normal.font.size = Pt(11)
rPr = normal.element.get_or_add_rPr()
rFonts = rPr.find(qn("w:rFonts"))
if rFonts is None: rFonts = OxmlElement("w:rFonts"); rPr.append(rFonts)
for k in ("w:ascii","w:hAnsi","w:cs"): rFonts.set(qn(k), "Arial")

for name, size in [("Heading 1", 14), ("Heading 2", 12), ("Heading 3", 11)]:
    st = styles[name]; st.font.name = "Arial"; st.font.size = Pt(size); st.font.bold = True
    st.font.color.rgb = RGBColor(0, 0, 0)
    st.paragraph_format.space_before = Pt(12); st.paragraph_format.space_after = Pt(4)

def H1(t): doc.add_paragraph(t, style="Heading 1")
def H2(t): doc.add_paragraph(t, style="Heading 2")
def H3(t): doc.add_paragraph(t, style="Heading 3")
def topic(text):
    p = doc.add_paragraph(style="List Bullet")
    r = p.add_run(text); r.italic = True; r.font.size = Pt(11)
def note(text):
    p = doc.add_paragraph(); r = p.add_run(text); r.italic = True
    r.font.color.rgb = RGBColor(80, 80, 80); r.font.size = Pt(10)
def caption(text):
    p = doc.add_paragraph(); r = p.add_run(text); r.bold = True; r.font.size = Pt(10)
def caption_note(text):
    p = doc.add_paragraph(); r = p.add_run(text); r.font.size = Pt(9)
    r.font.color.rgb = RGBColor(60, 60, 60)
def fmt_p(p):
    if p is None or p == "" or p == "NA": return "—"
    try: x = float(p)
    except: return str(p)
    if x < 0.001: return "<0.001"
    if x < 0.01:  return f"{x:.3f}"
    return f"{x:.2f}"
def fmt_hr(hr, lci, uci):
    try: a, b, c = float(hr), float(lci), float(uci)
    except: return "—"
    if any(v != v for v in (a,b,c)): return "—"
    return f"{a:.2f} ({b:.2f}–{c:.2f})"
def read_csv(name):
    with open(os.path.join(ASSETS, name)) as f: return list(csv.DictReader(f))
def read_kv(name):
    out = {}
    with open(os.path.join(ASSETS, name)) as f:
        for line in f:
            k, v = line.strip().split("=", 1); out[k] = v
    return out
def add_table(headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Light Grid Accent 1"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(headers):
        cell = t.rows[0].cells[j]; cell.text = ""
        r = cell.paragraphs[0].add_run(h); r.bold = True; r.font.size = Pt(10); r.font.name = "Arial"
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
    for i, row in enumerate(rows, start=1):
        for j, val in enumerate(row):
            cell = t.rows[i].cells[j]; cell.text = ""
            r = cell.paragraphs[0].add_run(str(val)); r.font.size = Pt(10); r.font.name = "Arial"
    return t
def add_figure(path, width_in=6.5):
    p = doc.add_paragraph(); p.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
    p.add_run().add_picture(path, width=Inches(width_in))

# ====================================================================
# TITLE
# ====================================================================
title = doc.add_paragraph()
r = title.add_run("MANUSCRIPT OUTLINE — Emphysema Severity Index across the COPDGene spectrum")
r.font.size = Pt(16); r.bold = True; r.font.name = "Arial"

note("Castaldi, Paoletti, Occhipinti, Sorano, Lavorini, Maiorino, Hersh, Silverman, Pistolesi  •  Updated 25 June 2026 (v3) — adds cause-specific mortality analyses to §3.2 (distributed effect across non-respiratory causes)")
note("Target journal: AJRCCM or ERJ.  Section headers and paragraph topics only; tables and figures embedded for review.")

H2("Working title — three candidates")
topic("Option 1 (lead with multidimensional-diagnosis angle, post-Bhatt 2025): 'A spirometric approximation of the multidimensional COPD diagnostic schema: the Emphysema Severity Index across the COPDGene spectrum'")
topic("Option 2 (lead with what ESI adds): 'Beyond FEV1/FVC — a continuous spirometric index of emphysema-related lung function complements multidimensional COPD diagnosis across the COPDGene spectrum'")
topic("Option 3 (CT-unavailable angle): 'The Emphysema Severity Index as a spirometric substitute for chest CT in multidimensional COPD diagnosis: validation across the COPDGene spectrum'")

# ====================================================================
# ABSTRACT
# ====================================================================
H1("Abstract  (250 w / AJRCCM, 200 w / ERJ)")
H3("Background")
topic("COPD heterogeneity; FEV1/FVC captures the *magnitude* of obstruction, not its *mechanism*; CT identifies emphysema but is not routine; ESI is a continuous spirometric index of expiratory-curve concavity that may reflect emphysema-related physiology.")
H3("Methods")
topic("10,169 COPDGene Visit-1 subjects across the full spectrum (never-smoker → GOLD 4); continuous ESI, FEV1/FVC, %LAA-950HU, DLco; up to 10-year follow-up for FEV1 decline and for all-cause and respiratory-cause mortality.")
H3("Results")
topic("Per-stratum correlation r(ESI, FEV1/FVC) ranges from −0.26 in preserved spirometry to −0.92 in severe COPD: ESI carries non-collinear information at the preserved end.")
topic("ESI is an independent predictor of all-cause mortality (HR 1.08 per unit after FEV1/FVC adjustment, p < 0.001) but for respiratory-cause mortality FEV1/FVC alone is sufficient (ESI HR ≈ 1.0 after adjustment).")
topic("In a mutually adjusted FEV1-decline model, ESI is the stronger pooled predictor and is independently significant within GOLD 0 (β = −4.7 mL/yr/unit, p = 0.001).")
topic("PRISm and GOLD 0 share an identical baseline ESI distribution but PRISm rises faster over 10 years (within-subject ΔESI confirmed by both mean and median).")
topic("Replacing the two CT-imaging criteria of the Bhatt 2025 multidimensional COPD schema with an ESI-based criterion produces a CT-free classification with the same mortality discrimination as the full schema (C-index 0.700 vs 0.703 for all-cause; 0.819 vs 0.822 for respiratory).")
H3("Conclusions")
topic("ESI is a continuous, spirometry-derived physiological dimension partially independent of FEV1/FVC across the COPDGene spectrum.  Its added prognostic value is most pronounced for all-cause mortality and FEV1 decline in mild and preserved-spirometry strata, and it supports a clinically meaningful approximation of multidimensional COPD diagnosis in CT-unavailable settings.")

# ====================================================================
# 1 INTRODUCTION
# ====================================================================
H1("1.  Introduction")
topic("¶1 — COPD heterogeneity and emphysema as a key axis; clinical importance of emphysema-vs-airway phenotyping.")
topic("¶2 — Limits of routine spirometry; complementary CT but not routinely available; introduce ESI and cite prior work (Occhipinti 2019; Occhipinti 2020; Luoto 2022 [respiratory mortality in Swedish general population]; Pistolesi 2026 ERJ [Italian general population]).")
topic("¶3 — The Bhatt 2025 JAMA multidimensional COPD diagnostic schema uses CT visual emphysema and bronchial wall thickening plus three symptom criteria to reclassify 15.4% of preserved-spirometry COPDGene subjects as having COPD, with elevated mortality and faster FEV1 decline.  Imaging is not universally available; spirometric proxies for the structural dimension are needed.")
topic("¶4 — Knowledge gap and aim: prior ESI work (including our GOLD 2–4 EPD subtyping paper) operated where ESI and FEV1/FVC are collinear (r ≈ −0.94); what ESI uniquely adds across the broader spectrum, and whether it can stand in for CT imaging in the Bhatt schema, is unknown.  We use the full COPDGene cohort to test both questions.")

# ====================================================================
# 2 METHODS
# ====================================================================
H1("2.  Methods")
H2("2.1  Study population")
topic("COPDGene Visit-1 subjects with usable post-bronchodilator spirometry and a valid ESI (n = 10,169); V2 (≈ 5 y) and V3 (≈ 10 y) follow-up.")
H2("2.2  Spectrum strata (descriptive only)")
topic("Never-smoker / GOLD 0 (smoker without obstruction) / PRISm / GOLD 1–4, derived from finalgold_visit.  All multivariable models use continuous predictors; GOLD 0 (largest stratum) is the reference for stratum contrasts.")
H2("2.3  Emphysema Severity Index")
topic("ESI is computed from PEF, FVC, FEF25/50/75 (Occhipinti 2019, 2020) and is essentially insensitive to bronchodilator (mean ΔESI ≈ −0.07 in our cohort — see §3.x and Discussion).")
H2("2.4  CT and DLco")
topic("Thirona %LAA-950HU (inspiration), %LAA-856HU (expiration), PRM, Pi10; Fleischner visual scoring of emphysema and bronchial wall thickening.  DLco is measured at V2 only.")
H2("2.5  Outcomes")
topic("All-cause mortality (Cox proportional-hazards; merged cohort n = 10,105, 2,857 deaths, median follow-up 10.7 y).")
topic("Respiratory-cause mortality (Cox; cause-specific Cox with non-respiratory deaths treated as censored at the death date; n = 1,163 adjudicated respiratory deaths).")
topic("Longitudinal FEV1 in mL (linear mixed-effects model with a random subject intercept; 18,893 visit-rows on 10,109 subjects).")
H2("2.6  Statistical analysis")
topic("All exposures continuous; no thresholding of ESI or FEV1/FVC.")
topic("Mutual adjustment: every multivariable model contains both ESI and FEV1/FVC, plus baseline spectrum stratum, age, sex, race, current smoking, pack-years (FEV1-decline models add baseline height and time-varying age/smoking/pack-years).")
topic("Pre-specified sensitivity analyses: drop subjects pegged at the ESI ceiling of 10; pooled versus per-stratum models; a flexible non-linear (spline) model of ESI to verify approximate linearity.")
topic("DLco analysis is V2 cross-sectional (DLco not measured at V1).")

# ====================================================================
# 3 RESULTS
# ====================================================================
H1("3.  Results")

# --- 3.1 ---
H2("3.1  ESI and FEV1/FVC are only weakly collinear in the preserved-spirometry portion of the spectrum")
topic("¶ — Describe the cohort and the per-stratum distribution; refer to Table 1.")
topic("¶ — Pearson correlations between ESI, FEV1/FVC, and CT-based emphysema markers; refer to Table 2; highlight that the strong cohort-wide r(ESI, FEV1/FVC) = −0.89 is driven by the obstructive strata, while in Never / GOLD 0 / PRISm the correlation is weak (|r| ≤ 0.40), so ESI carries information FEV1/FVC does not in the preserved-spirometry band.")
topic("¶ — Refer to Figure 1; emphasise the wide spread of ESI at any fixed FEV1/FVC in the preserved-spirometry region.")

caption("Table 1.  Baseline characteristics of the COPDGene V1 cohort with valid post-bronchodilator ESI, by spectrum stratum.  Values are mean (SD).")
t1 = read_csv("Table_1.csv")
add_table(
    headers=["Stratum","N","Age (y)","BMI","Pack-yr","FEV1 %pred","FEV1/FVC","ESI"],
    rows=[[r["stratum"], r["n"], r["age"], r["bmi"], r["pack_yr"], r["fev1pp"], r["ff"], r["esi"]] for r in t1]
)
caption_note("ESI = Emphysema Severity Index (post-BD).  Note (per Massimo): PRISm subjects have mean FEV1 ≈ 70%pred vs ≈ 97%pred in GOLD 0 — PRISm is clinically a sicker group than GOLD 0 despite both being labelled 'no airflow obstruction'.")

doc.add_paragraph("")

caption("Table 2.  Pearson correlations between ESI and (a) FEV1/FVC and (b) the CT emphysema marker %LAA-950HU, by spectrum stratum.")
t2 = read_csv("Table_2.csv")
add_table(
    headers=["Stratum","n (FEV1/FVC)","r (ESI, FEV1/FVC)","n (%LAA-950)","r (ESI, %LAA-950)"],
    rows=[[r["stratum"], r["n_FF"], f"{float(r['r_FF']):+.2f}", r["n_LAA"], f"{float(r['r_LAA']):+.2f}"] for r in t2]
)
caption_note("Note: substituting %LAA-950HU with PRM emphysema (Supp Table CT correlations) gives essentially identical per-stratum correlations — the two CT markers are r ≈ 0.985 in our cohort (consistent with Occhipinti Radiology 2018).")

doc.add_paragraph("")

caption("Figure 1.  (A) ESI distribution by stratum.  (B) Scatter of ESI vs FEV1/FVC, colored by stratum.  (C) Pearson r(ESI, FEV1/FVC) within each stratum.")
add_figure(os.path.join(ASSETS, "Figure_1.png"), width_in=6.5)
doc.add_paragraph("")

# --- 3.2 ---
H2("3.2  ESI independently predicts all-cause mortality across the spectrum; FEV1/FVC alone predicts respiratory-cause mortality")
topic("¶ — Mortality in our cohort follows the expected severity gradient (Figure 2: survival curves separate cleanly across strata for both all-cause and respiratory-cause mortality over a median 10.7-year follow-up).  This establishes baseline spectrum stratum as a meaningful severity adjustor.")
topic("¶ — ESI is a stronger predictor of all-cause mortality than FEV1/FVC (Table 3, three side-by-side Cox models).  In the ESI-only multivariable model, every 1-unit higher baseline ESI corresponds to a 10% increase in all-cause mortality risk (HR 1.10).  Adding FEV1/FVC reduces this to 8% (HR 1.08) — but does not eliminate it — even after accounting for FEV1/FVC, baseline severity, age, sex, race, smoking, and pack-years.  The result is robust to excluding the small subset of subjects pegged at the ESI maximum value of 10 (HR 1.07).  In the same combined model, FEV1/FVC's independent contribution is no longer statistically significant.")
topic("¶ — Respiratory-cause mortality tells a different story (Table 3, lower panel).  ESI alone predicts respiratory death (HR 1.10, p < 0.001) — but when FEV1/FVC is added, ESI's independent contribution disappears (HR 1.01, p = 0.85) and FEV1/FVC carries the entire respiratory-mortality signal.  This contrasts with the Swedish geriatric general-population finding (Luoto 2022) where ESI was the specific respiratory-mortality predictor — but is consistent with the physiology: in our COPD-enriched cohort, severe airflow obstruction itself dominates respiratory mortality, while ESI's contribution lies in the non-respiratory component of all-cause mortality.")
topic("¶ — When each spectrum band is examined separately (Table 4), ESI's independent all-cause-mortality value is concentrated in subjects with mild-to-severe airflow obstruction — GOLD 1, GOLD 2, and GOLD 3 (per-unit HR 1.09–1.32; HR(GOLD 2) = 1.14, p < 0.001).  For respiratory mortality, the per-stratum analysis shows null effects of ESI in every stratum, consistent with the pooled result.")
topic("¶ — Where does the all-cause ESI signal live by cause of death?  We tested cause-specific Cox models for the broad cause categories (cardiovascular n = 615, cancer n = 501, other n = 680) and the major sub-causes with at least 100 events (Table 4-cs and Figure 2b).  No single non-respiratory cause shows ESI as a significant independent predictor after FEV1/FVC adjustment — every hazard ratio crosses 1.0 at conventional significance, with the closest to significance being 'other cancer' (HR 1.15, p = 0.05).  The pooled all-cause finding of HR(ESI) = 1.08 therefore reflects a distributed effect across multiple cause pathways rather than concentration in any single one.  This is consistent with ESI capturing a general marker of lung mechanical impairment that contributes incrementally to mortality from several non-respiratory causes.  An alternative interpretation is reduced statistical power in the individual cause-specific analyses (100–700 events per cause vs 2,839 for all-cause); both interpretations are honest and the data does not distinguish between them.")
topic("¶ — Exacerbations parallel the respiratory-mortality pattern (Table 4-ex: pooled negative-binomial models on prospective LFU exacerbation counts, n = 8,898 subjects with 24,454 exacerbations over median 10.3 yr of follow-up).  ESI alone is a strong predictor of exacerbation rate (IRR = 1.11 per 1-unit higher baseline ESI, p < 0.001), but the signal disappears entirely when FEV1/FVC is added to the model (ESI IRR = 1.01, p = 0.70).  FEV1/FVC alone captures the entire signal: each 0.1-unit lower FEV1/FVC corresponds to a 27% increase in exacerbation rate (IRR per 0.1-unit increase = 0.79).  The LR test confirms ESI does not add prognostic value beyond FEV1/FVC for exacerbations (p = 0.71).  Sensitivity using severe exacerbations only shows the same pattern (ESI IRR = 0.99, p = 0.72 after FF adjustment).  This mirrors the respiratory-mortality result and contrasts with the all-cause mortality finding — ESI's added prognostic value is specifically in the non-respiratory components of all-cause mortality, not in airway-event endpoints where airflow obstruction itself dominates.")

caption("Figure 2.  Kaplan–Meier survival curves by baseline spectrum stratum, all-cause (left) and respiratory-cause (right).  Both outcomes show clean separation by severity; respiratory mortality has lower event rates and wider confidence intervals at later visits.")
add_figure(os.path.join(ASSETS, "Figure_2.png"), width_in=6.8)
doc.add_paragraph("")

# Table 3 — all-cause + respiratory side by side
t3a = read_csv("Table_3_allcause.csv"); t3r = read_csv("Table_3_resp.csv")
stats3 = read_kv("Table_3_stats.txt")
caption(f"Table 3 (all-cause mortality).  Cox proportional-hazards models for all-cause mortality (n = {int(stats3['n_cohort']):,}; {int(stats3['n_deaths_all']):,} deaths).  HR per 1-unit increase in the predictor, all models adjusted for baseline stratum, age, sex, race, current smoking, and pack-years.")
def hr_cell(r, prefix):
    return fmt_hr(r[f"{prefix}_HR"], r[f"{prefix}_LCI"], r[f"{prefix}_UCI"])
rows_all = [[r["model"], hr_cell(r,"esi"), fmt_p(r["esi_p"]), hr_cell(r,"ff"), fmt_p(r["ff_p"])] for r in t3a]
add_table(headers=["Model","ESI HR (95% CI)","ESI p","FEV1/FVC HR (95% CI)","FEV1/FVC p"], rows=rows_all)
caption_note(f"LR test for adding ESI to FEV1/FVC + covariates: χ² = {float(stats3['LR_chisq_all']):.1f}, p = {float(stats3['LR_p_all']):.1e}.")
doc.add_paragraph("")

caption(f"Table 3 (respiratory-cause mortality).  Same models, respiratory-cause endpoint ({int(stats3['n_deaths_resp']):,} adjudicated respiratory deaths).")
rows_resp = [[r["model"], hr_cell(r,"esi"), fmt_p(r["esi_p"]), hr_cell(r,"ff"), fmt_p(r["ff_p"])] for r in t3r]
add_table(headers=["Model","ESI HR (95% CI)","ESI p","FEV1/FVC HR (95% CI)","FEV1/FVC p"], rows=rows_resp)
caption_note(f"LR test for adding ESI to FEV1/FVC + covariates: χ² = {float(stats3['LR_chisq_resp']):.2f}, p = {float(stats3['LR_p_resp']):.2f}.  For respiratory mortality, ESI does NOT add independent prognostic value beyond FEV1/FVC.")
doc.add_paragraph("")

# Table 4 — per-stratum
t4a = read_csv("Table_4_allcause.csv"); t4r = read_csv("Table_4_resp.csv")
caption("Table 4.  Per-stratum Cox hazard ratios for ESI (per 1-unit increase) from a model adjusted for baseline FEV1/FVC, age, sex, race, current smoking, and pack-years.")
rows4 = []
t4r_by = {r["stratum"]: r for r in t4r}
for r in t4a:
    rr = t4r_by.get(r["stratum"], {})
    rows4.append([r["stratum"], r["n"], r["deaths"], fmt_hr(r["HR"], r["LCI"], r["UCI"]), fmt_p(r["p"]),
                  rr.get("deaths","—"), fmt_hr(rr.get("HR"), rr.get("LCI"), rr.get("UCI")), fmt_p(rr.get("p"))])
add_table(headers=["Stratum","N","All-cause deaths","All-cause HR (95% CI)","All-cause p","Resp deaths","Resp HR (95% CI)","Resp p"], rows=rows4)
caption_note("For all-cause: ESI is significant in GOLD 1–3.  For respiratory: ESI is null in every stratum.")
doc.add_paragraph("")

# Table 4-cs — cause-specific Cox HRs for ESI
t_cs = read_csv("Table_CauseSpecific.csv")
cs_stats = read_kv("Table_CauseSpecific_stats.txt")
caption(f"Table 4-cs.  Cause-specific Cox proportional-hazards models for non-respiratory mortality (n = {int(cs_stats['n_cohort']):,}; cause-specific events censored at non-target deaths).  Each row is a different cause-of-death endpoint.  HR per 1-unit higher baseline ESI; all models adjusted for FEV1/FVC (per 0.1-unit), age, sex, race, current smoking, pack-years, and baseline stratum.")
rows_cs = []
for r in t_cs:
    rows_cs.append([
        r["cause"], r["n_events"],
        fmt_hr(r["ESI_alone_HR"], r["ESI_alone_LCI"], r["ESI_alone_UCI"]),
        fmt_p(r["ESI_alone_p"]),
        fmt_hr(r["ESI_FF_HR"], r["ESI_FF_LCI"], r["ESI_FF_UCI"]),
        fmt_p(r["ESI_FF_p"])
    ])
add_table(headers=["Cause","Events","ESI alone HR (95% CI)","ESI alone p",
                   "ESI + FEV1/FVC HR (95% CI)","ESI + FEV1/FVC p"], rows=rows_cs)
caption_note("No single cause shows ESI as an independent predictor after FEV1/FVC adjustment.  The closest to significance is 'other cancer' (HR 1.15, p ≈ 0.05).  Per-cause analyses are likely underpowered (100–700 events per cause vs 2,839 for all-cause); the data are consistent with either a distributed effect across many cause pathways or with reduced power.")
doc.add_paragraph("")

caption("Figure 2b.  Forest plot of cause-specific Cox hazard ratios for ESI (per 1-unit increase, after FEV1/FVC and covariate adjustment), by cause of death.  Vertical dashed line at HR = 1.")
add_figure(os.path.join(ASSETS, "Figure_CauseSpecific.png"), width_in=6.8)
doc.add_paragraph("")

# Table 4-ex — pooled exacerbation models (parallel to Table 3)
t_ex = read_csv("Table_Exacerbations_Pooled.csv")
ex_stats = read_kv("Table_Exacerbations_Pooled_stats.txt")
caption(f"Table 4-ex.  Pooled negative-binomial models for prospective LFU exacerbation rate (n = {int(ex_stats['n_cohort']):,}; {int(ex_stats['n_total_exac']):,} total exacerbations over median {float(ex_stats['med_yr']):.1f} y of follow-up).  IRR per 1-unit higher baseline ESI; FEV1/FVC IRR is per 0.1-unit (clinically interpretable scale).  Covariates: baseline stratum, age, sex, race, current smoking, pack-years; offset log(Years_Followed).")
rows_ex = []
for r in t_ex:
    esi_hr = fmt_hr(r["esi_IRR"], r["esi_LCI"], r["esi_UCI"])
    ff_hr  = fmt_hr(r["ff_IRR"],  r["ff_LCI"],  r["ff_UCI"])
    rows_ex.append([r["model"], esi_hr, fmt_p(r["esi_p"]), ff_hr, fmt_p(r["ff_p"])])
add_table(headers=["Model","ESI IRR (95% CI)","ESI p","FEV1/FVC IRR per 0.1 (95% CI)","FEV1/FVC p"], rows=rows_ex)
caption_note(f"LR test for adding ESI to FEV1/FVC + covariates: χ² = {float(ex_stats['LR_chisq']):.2f}, p = {float(ex_stats['LR_p']):.2f}.  ESI does NOT add independent value beyond FEV1/FVC for exacerbations — same pattern as respiratory mortality.  Sensitivity using severe exacerbations: ESI IRR = {float(ex_stats['sev_ESI_IRR']):.2f}, p = {float(ex_stats['sev_ESI_p']):.2f} (null).")
doc.add_paragraph("")

# --- 3.3 ---
H2("3.3  ESI predicts FEV1 decline beyond FEV1/FVC, with unique signal in GOLD 0")
topic("¶ — ESI predicts the rate of lung function decline more strongly than FEV1/FVC across the cohort (Table 5a, pooled longitudinal model with all three visits over ~10 years).  Adding ESI to a model that already contains FEV1/FVC improves prediction approximately twice as much (χ² = 25.9, the ratio reflecting two-fold improvement) as adding FEV1/FVC to a model already containing ESI (χ² = 11.7).  Methodological note for the reader: the pooled coefficient on ESI × time is positive, which would superficially suggest higher ESI predicts *slower* decline.  This is a measurement artifact driven by the ESI ceiling at 10 in subjects with severe COPD (whose FEV1 is already near floor and has limited room to decline further), not a sign error.  The clinically interpretable estimates therefore come from the per-stratum analysis below.")
topic("¶ — Within each spectrum band (Table 5b), FEV1/FVC remains the dominant FEV1-decline predictor.  ESI is independently significant beyond FEV1/FVC only in smokers with preserved spirometry (GOLD 0): each 1-unit higher baseline ESI predicts an additional 4.7 mL/yr of FEV1 decline (p = 0.001).  This is the novel finding — among individuals who appear normal on spirometry, ESI identifies those whose lung function is already declining faster than their peers.")
topic("¶ — Figure 3 visualises this: the forest plot (Panel A) shows that GOLD 0 is the only stratum where ESI's confidence interval excludes zero; the within-subject decline plot (Panel B, redesigned per Massimo's suggestion) shows that all three ESI tertiles in GOLD 0 start at the same baseline (Δ = 0 by definition), and the High-ESI tertile declines roughly 200 mL more than the Low-ESI tertile over 10 years — directly illustrating the per-stratum coefficient without the visual confound of differing baseline FEV1.")

t5a = read_csv("Table_5a.csv"); stats5a = read_kv("Table_5a_stats.txt")
caption("Table 5a.  Pooled FEV1-decline coefficients (mutually adjusted ESI and FEV1/FVC).  Each interaction coefficient is the additional change in FEV1 (mL) per year per 1-unit higher baseline predictor.")
def fmt_int(est, se, p):
    if est in ("NA","") or est is None: return "—", "—"
    e = float(est); s = float(se)
    return f"{e:+.2f} ({e-1.96*s:+.2f}, {e+1.96*s:+.2f})", fmt_p(p)
rows5a = []
for r in t5a:
    esi_cell, esi_p = fmt_int(r["esi_est"], r["esi_se"], r["esi_p"])
    ff_cell,  ff_p  = fmt_int(r["ff_est"],  r["ff_se"],  r["ff_p"])
    rows5a.append([r["model"], esi_cell, esi_p, ff_cell, ff_p])
add_table(headers=["Model","ESI×time (mL/yr/unit, 95% CI)","ESI p","FEV1/FVC×time (mL/yr/unit, 95% CI)","FEV1/FVC p"], rows=rows5a)
caption_note(f"LR tests: adding `time × ESI` to a model already containing `time × FEV1/FVC`: χ² = {float(stats5a['LR_addESI_chisq']):.1f}; adding `time × FEV1/FVC` to a model already containing `time × ESI`: χ² = {float(stats5a['LR_addFF_chisq']):.1f}.  The ratio (≈ 2:1) is the basis for the 'twice as much prediction' claim in the prose.")
doc.add_paragraph("")

t5b = read_csv("Table_5b.csv")
caption("Table 5b.  Per-stratum FEV1-decline coefficients (mutually adjusted ESI and FEV1/FVC).")
rows5b = []
for r in t5b:
    e_est = r["esi_est"]; f_est = r["ff_est"]
    rows5b.append([r["stratum"], r["n_subj"],
                   ("—" if e_est in ("NA","") else f"{float(e_est):+.2f}"), fmt_p(r["esi_p"]),
                   ("—" if f_est in ("NA","") else f"{float(f_est):+.1f}"),  fmt_p(r["ff_p"])])
add_table(headers=["Stratum","N subjects","ESI×time (mL/yr/unit)","ESI p","FEV1/FVC×time (mL/yr/unit)","FEV1/FVC p"], rows=rows5b)
caption_note("Within each stratum, FEV1/FVC is the more consistent FEV1-decline predictor across GOLD 0–3 + PRISm.  ESI is independently significant beyond FEV1/FVC only in GOLD 0 (smokers with preserved spirometry).  Never-smokers included for completeness; estimates imprecise at this sample size.")
doc.add_paragraph("")

caption("Figure 3.  ESI vs FEV1/FVC head-to-head for FEV1 decline (V1–V3, mutually adjusted longitudinal model).")
caption_note("(A) Forest plot of the per-stratum `time × predictor` interaction coefficients with 95% CI: ESI (left sub-panel) and FEV1/FVC (right sub-panel).  Coefficient is the additional change in FEV1 (mL/yr) per 1-unit higher baseline predictor; vertical dashed line is the null.  GOLD 0 is the only stratum where ESI's interval excludes zero, in the expected (negative) direction.  (B) Within-subject change in FEV1 from baseline in GOLD 0 subjects, by baseline ESI tertile (LOESS smooth with 95% CI ribbon).  All three tertiles start at Δ = 0 by definition (eliminating the previous version's visual confound).  Over 10 years, the High-ESI tertile loses approximately 200 mL more FEV1 than the Low-ESI tertile, consistent with the −4.7 mL/yr/unit ESI coefficient in Table 5b.")
add_figure(os.path.join(ASSETS, "Figure_3.png"), width_in=6.8)
doc.add_paragraph("")

# --- 3.4 ---
H2("3.4  ESI trajectories distinguish PRISm from GOLD 0 despite identical baseline distributions")
topic("¶ — ESI trajectories over 10 years align with baseline disease severity (Figure 4): higher baseline severity leads to higher baseline ESI and steeper subsequent rise.")
topic("¶ — One unexpected finding: PRISm subjects and smokers without obstruction (GOLD 0) start with identical baseline ESI distributions (mean ≈ 0.90 in both groups), but over 10 years PRISm subjects show a faster rise.  Figure 6 shows this directly using within-subject ΔESI from baseline by stratum — the PRISm trajectory diverges from GOLD 0 starting at V2 and the separation is preserved using either mean or median, confirming the finding is not driven by outliers.")
topic("¶ — Important caveat for the GOLD 4 trajectory: the apparent decline in mean ESI from 8.25 at baseline to 6.20 at 10 years is misleading.  Only 39 of 593 GOLD 4 subjects had a 10-year follow-up ESI measurement, and those survivors actually started with slightly higher baseline ESI (8.45) than the full GOLD 4 cohort.  The apparent decline reflects regression-to-the-mean from the ESI maximum value of 10 within the small survivor subset, combined with standard survivor bias.")

caption("Figure 4.  Mean ESI at each visit by baseline spectrum stratum (95% CI).  Higher baseline severity → higher and steeper trajectory; PRISm rises faster than GOLD 0 despite identical baselines; GOLD 4 apparent decline is a combination of survivor selection and regression from the ESI ceiling.")
add_figure(os.path.join(ASSETS, "Figure_4.png"), width_in=5.8)
doc.add_paragraph("")

caption("Figure 6 (NEW).  Within-subject change in ESI from baseline for PRISm and GOLD 0 only, mean (left) and median (right) at each visit.  All subjects start at Δ = 0 at V1 by definition.  PRISm subjects diverge clearly from GOLD 0 starting at V2; the qualitative pattern holds whether measured by mean (95% CI shown) or median.  Directly addresses Massimo's request to demonstrate the PRISm/GOLD 0 trajectory finding graphically.")
add_figure(os.path.join(ASSETS, "Figure_6.png"), width_in=6.5)
doc.add_paragraph("")

# --- 3.5 ---
H2("3.5  ESI as a CT-unavailable substitute in the Bhatt 2025 multidimensional COPD schema")
topic("¶ — Setting up the question: the Bhatt 2025 schema combines the major criterion of airflow obstruction (FEV1/FVC < 0.70) with five minor criteria — two from chest CT (visual emphysema; bronchial wall thickening) and three from symptoms (mMRC ≥ 2; SGRQ ≥ 25; chronic bronchitis).  In settings where CT is unavailable, the two imaging criteria cannot be scored.  We tested whether ESI — derivable from the same spirometry test that scores the major criterion — can take the place of the imaging criteria.  Substitution rule (clarified per Massimo's question): a subject's ESI contributes 0 minor criteria if ESI < 1.0, 1 minor criterion if 1.0 ≤ ESI < 2.5, and 2 minor criteria if ESI ≥ 2.5.  The original threshold of three of five minor criteria for the minor-category diagnosis is preserved.  Cohort: 9,463 COPDGene subjects at Visit 1 with all Bhatt criteria available.")
topic("¶ — Why these two ESI thresholds?  We evaluated ten variants (Supp Table — Threshold sensitivity): both 4-criterion variants (ESI as a single minor criterion replacing emphysema only, with various cut-offs) and 5-criterion variants (ESI as two minors with low/high cut-offs, replacing both imaging criteria).  The selected 5-criterion variant (T_low = 1.0, T_high = 2.5) was not the single highest-κ variant — a lower T_low of 0.5 reached κ ≈ 0.86 — but it offered a more balanced sensitivity/specificity profile (κ = 0.82; sensitivity 88%; specificity 94%) and physiologically meaningful cut-offs (ESI ≈ 1 is near the centre of the never-smoker / GOLD 0 distribution; ESI ≈ 2.5 is near the lower end of the GOLD 2 distribution).")
topic("¶ — Methodological caveat (per Pete's concern): ESI was developed and validated as a marker of emphysema-related expiratory mechanics; it correlates only weakly with airway-wall thickening or Pi10 in prior work.  The substitution rule above therefore treats ESI as a combined surrogate for both imaging criteria — a defensible choice statistically (the 5-criterion variant maximises agreement with the full Bhatt schema) but conceptually mixed.  We report as a sensitivity analysis a strict 4-criterion variant in which ESI replaces emphysema only and the wall-thickening criterion is dropped (because CT is unavailable to score it).  The 4-criterion variant achieves slightly lower agreement (best κ ≈ 0.79 at ESI ≥ 1.5, ≥ 2 of 4 minors) but cleaner physiological interpretation.  The 5-criterion variant is retained as the primary analysis because of its higher discrimination, with the limitation noted.")
topic("¶ — Classification agreement (refer to Figure 5b — stacked bars — and Table 6 — 4-way cross-tabulation): the two schemas agree on COPD vs no COPD in 91% of cases (sensitivity 88%, specificity 94%; Cohen's κ = 0.82).")
topic("¶ — Per-stratum agreement among preserved-spirometry subjects (refer to Table 7): in GOLD 0 and PRISm, the ESI-substituted classifier is highly specific (96–98%) but catches only about half of Bhatt's COPD cases — these are subjects whose Bhatt diagnosis is anchored on visible CT emphysema that ESI does not flag.")
topic("¶ — Characterising the discordant subjects (Table 9; preserved spirometry only): Bhatt-only-COPD subjects (Bhatt-COPD missed by ESI; n = 546) have low mean ESI (0.80) yet a very high prevalence of visible CT emphysema (91%) and a low burden of chronic bronchitis (16%) — Bhatt's diagnosis here is anchored on the imaging criterion, with emphysema present visually but not mechanically significant enough to elevate ESI.  ESI-only-COPD subjects (caught by ESI but not by Bhatt; n = 95) have higher mean ESI (1.48) and effectively no visible CT findings (0% emphysema, 0% wall thickening) but a heavy symptom burden (85% mMRC ≥ 2, 95% SGRQ ≥ 25) — symptom-laden subjects with elevated mechanical changes that visual CT misses, possibly early or sub-clinical emphysema.  Both-COPD subjects (n = 553) sit between, with moderate ESI (1.06), moderate CT findings, and the highest symptom burden including 72% with chronic bronchitis.")
topic("¶ — Outcomes by discordance group (Table 10): all three preserved-spirometry COPD subgroups have elevated all-cause mortality versus the both-noCOPD reference (adjusted HRs 2.02 Both-COPD, 1.53 Bhatt-only-COPD, 1.26 ESI-only-COPD) and elevated respiratory-cause mortality (HRs 3.05, 2.48, 2.89).  Both-COPD (caught by both schemas) carries the highest risk — concordance of the two methods identifies the highest-confidence cases.  Bhatt-only and ESI-only both carry meaningful residual risk, suggesting each method captures complementary signal.")
topic("¶ — Population-level prognostic equivalence (Table 8 and Figure 5): adjusted mortality HRs from the Bhatt full schema and the ESI-substituted schema overlap closely (all-cause: 1.91 vs 1.94 for COPD-minor; respiratory: 3.09 vs 2.91).  Discrimination is indistinguishable (all-cause C-index 0.703 vs 0.700; respiratory 0.822 vs 0.819).  Both schemas correctly identify subjects with airflow obstruction but no symptoms/imaging as not at elevated mortality risk.")
topic("¶ — Exacerbation rate by Bhatt category (Table 12-ex): both schemas identify exacerbation risk similarly.  Bhatt-defined COPD-major IRR = 5.07 vs ESI-substituted COPD-major IRR = 4.47.  Bhatt COPD-minor IRR = 2.73 vs ESI-substituted COPD-minor IRR = 2.78 — essentially identical.  AFL-only-NoCOPD IRRs are 1.28 (Bhatt) and 0.97 (ESI-variant), both crossing 1 — confirming Bhatt's exclusion of this group from COPD diagnosis on the basis of clinical outcomes.  This is a strong head-to-head equivalence for an outcome where ESI alone does not add beyond FEV1/FVC: at the *classification* level, the schemas identify exacerbation-prone patients equivalently.")
topic("¶ — FEV1 decline by Bhatt category (Table 11): in a head-to-head longitudinal model, neither schema produces large or significant differences in FEV1 slope for COPD-minor or COPD-major relative to noCOPD after adjustment for time-varying covariates.  The AFL-only-NoCOPD group — which Bhatt excludes from COPD — does not decline faster than non-COPD subjects (β +3.7 mL/yr Bhatt, +10.2 mL/yr ESI-variant), supporting Bhatt's exclusion of this group from a COPD diagnosis.")
topic("¶ — Clinical interpretation: ESI is not a perfect substitute for CT in well-resourced settings.  But the spirometry + symptoms + ESI classification is a clinically meaningful approximation of multidimensional COPD diagnosis where CT is unavailable.  It under-identifies relative to the full schema (catching about half of Bhatt's preserved-spirometry COPD cases), but the patients it identifies carry the same prognostic weight as those identified by the full Bhatt schema for both all-cause and respiratory mortality.  The discordance analysis suggests the two methods capture overlapping but complementary signal — Bhatt-only-COPD is mostly imaging-driven; ESI-only-COPD is mostly symptom-driven with elevated mechanical changes that visual CT misses.")

# Figure 5b — stacked bars visualisation (per Massimo's request to make Table 6 easier to read)
caption("Figure 5b.  Stacked-bar visualisation of the Bhatt 2025 classification (left bar) and the ESI-substituted classification (right bar), with counts and percentages of subjects in each category.  Easier-to-grasp companion to Table 6 (per Massimo's suggestion).")
add_figure(os.path.join(ASSETS, "Figure_Bhatt_StackedBars.png"), width_in=6.5)
doc.add_paragraph("")

# Table 6
t6 = read_csv("Table_6.csv")
caption("Table 6.  Four-way cross-tabulation of the Bhatt 2025 classification (rows) and the ESI-substituted classification (columns) in n = 9,463 V1 subjects with all required variables non-missing.")
add_table(headers=["Bhatt ↓ / ESI-variant →","noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"],
          rows=[[r["Bhatt"], r["noCOPD"], r["AFL_only_NoCOPD"], r["COPD_minor"], r["COPD_major"]] for r in t6])
caption_note("Overall: Cohen's κ = 0.82 for binary COPD vs noCOPD.")
doc.add_paragraph("")

# Table 7
t7 = read_csv("Table_7.csv")
caption("Table 7.  Per-stratum agreement of the ESI-substituted classification with the full Bhatt schema among preserved-spirometry subjects (FEV1/FVC ≥ 0.70).")
rows7 = []
for r in t7:
    sens = "—" if r["sens"] in ("NA","") else f"{float(r['sens']):.2f}"
    spec = "—" if r["spec"] in ("NA","") else f"{float(r['spec']):.2f}"
    rows7.append([r["stratum"], r["n"], r["bhatt_copd_n"], r["esi_copd_n"], r["both"], r["bhatt_only"], r["esi_only"], sens, spec])
add_table(headers=["Stratum","N","Bhatt-COPD","ESI-variant COPD","Both","Bhatt only","ESI only","Sens","Spec"], rows=rows7)
caption_note("In GOLD 0 and PRISm, the ESI-substituted classifier achieves ≈ 50% sensitivity and ≥ 96% specificity for the Bhatt COPD label.")
doc.add_paragraph("")

# Table 8 — all-cause + respiratory
t8a = read_csv("Table_8_allcause.csv"); t8r = read_csv("Table_8_resp.csv"); stats8 = read_kv("Table_8_stats.txt")
caption(f"Table 8.  Adjusted mortality hazard ratios from the Bhatt and ESI-substituted classifications (n = {int(stats8['n_cohort']):,}).  Reference category: noCOPD.  Covariates: age, sex, race, current smoking, pack-years, BMI.")
rows8 = []
t8r_by = {r["group"]: r for r in t8r}
for r in t8a:
    rr = t8r_by.get(r["group"], {})
    rows8.append([r["group"],
                  fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_HR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"]),
                  fmt_hr(rr.get("bhatt_HR"), rr.get("bhatt_LCI"), rr.get("bhatt_UCI")), fmt_p(rr.get("bhatt_p")),
                  fmt_hr(rr.get("esi_HR"),   rr.get("esi_LCI"),   rr.get("esi_UCI")),   fmt_p(rr.get("esi_p"))])
add_table(headers=["Group","Bhatt (all-cause)","p","ESI-var (all-cause)","p","Bhatt (resp)","p","ESI-var (resp)","p"], rows=rows8)
caption_note(f"All-cause C-index — Bhatt {float(stats8['bhatt_cindex_all']):.3f}, ESI-variant {float(stats8['esi_cindex_all']):.3f}.  Respiratory C-index — Bhatt {float(stats8['bhatt_cindex_resp']):.3f}, ESI-variant {float(stats8['esi_cindex_resp']):.3f}.")
doc.add_paragraph("")

# Figure 5
caption("Figure 5.  Adjusted mortality hazard ratios (95% CI, log scale) from the Bhatt and ESI-substituted classifications, all-cause (left) and respiratory-cause (right).  The two schemas produce overlapping HR estimates in both panels.")
add_figure(os.path.join(ASSETS, "Figure_5.png"), width_in=6.8)
doc.add_paragraph("")

# Table 9 — discordance characterization
t9 = read_csv("Table_Discordance.csv")
caption("Table 9.  Characterising the discordant subjects in preserved-spirometry (FEV1/FVC ≥ 0.70): Bhatt-only-COPD (missed by ESI), Both-COPD (caught by both schemas), and ESI-only-COPD (Bhatt missed).  Values are mean (SD) or %.")
rows9 = []
for r in t9:
    rows9.append([r["grp_5"], r["n"], r["age"], r["pct_F"], r["BMI"], r["pack_yr"], r["ESI"],
                  r["FEV1_pp"], r["FEV1_FVC"], r["LAA950"], r["pct_emph"], r["pct_wall"],
                  r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]])
add_table(
    headers=["Group","N","Age","%F","BMI","Pack-yr","ESI","FEV1 %pred","FEV1/FVC",
             "%LAA-950HU","%emph (visual)","%wall thick.","%mMRC ≥ 2","%SGRQ ≥ 25","%CB"],
    rows=rows9
)
caption_note("Pattern: Bhatt-only cases have visible CT emphysema with low ESI (imaging-driven diagnosis ESI cannot reproduce); ESI-only cases are symptom-laden with elevated ESI but no visible CT findings (possibly early/sub-clinical mechanical changes); Both-COPD subjects have moderate ESI, moderate imaging findings, and the highest symptom burden.")
doc.add_paragraph("")

# Table 10 — Bhatt-only vs Both vs ESI-only mortality
t10 = read_csv("Table_BhattOnly_vs_Both.csv")
caption("Table 10.  Adjusted mortality hazard ratios for the three discordant preserved-spirometry COPD subgroups vs the Both-noCOPD reference (concordant non-COPD).")
rows10 = []
for r in t10:
    rows10.append([r["group"], r["n"], r["n_deaths_all"],
                   fmt_hr(r["all_HR"], r["all_LCI"], r["all_UCI"]), fmt_p(r["all_p"]),
                   fmt_hr(r["resp_HR"], r["resp_LCI"], r["resp_UCI"]), fmt_p(r["resp_p"])])
add_table(
    headers=["Group","N","All-cause deaths","All-cause HR (95% CI)","All-cause p",
             "Respiratory HR (95% CI)","Respiratory p"],
    rows=rows10
)
caption_note("Both-COPD (both schemas agree on COPD diagnosis) carries the highest mortality risk.  Bhatt-only-COPD (caught by Bhatt, missed by ESI) is also significantly elevated; ESI-only-COPD (caught by ESI, missed by Bhatt) has point estimates of similar magnitude but is underpowered for statistical significance for all-cause mortality.  All three subgroups have elevated respiratory-cause mortality vs reference, with Bhatt-only and ESI-only point estimates similar to each other despite the small ESI-only sample.")
doc.add_paragraph("")

# Table 10-ex — discordance subgroups for exacerbations
t10ex = read_csv("Table_Exacerbations_Discordance.csv")
caption("Table 10-ex.  Adjusted exacerbation rate ratios for the three discordant preserved-spirometry COPD subgroups vs the Both-noCOPD reference (negative-binomial, offset log(Years_Followed)).")
rows10ex = []
for r in t10ex:
    rows10ex.append([r["group"], r["n"], fmt_hr(r["IRR"], r["LCI"], r["UCI"]), fmt_p(r["p"])])
add_table(headers=["Group","N","Exacerbation IRR (95% CI)","p"], rows=rows10ex)
caption_note("Same pattern as mortality: Both-COPD carries the highest exacerbation risk (IRR 3.17); Bhatt-only-COPD remains significantly elevated (IRR 2.01); ESI-only-COPD has a positive but underpowered point estimate (IRR 1.59, p = 0.07).")
doc.add_paragraph("")

# Table 11 — FEV1 decline by Bhatt category
t11 = read_csv("Table_BhattDecline.csv")
caption("Table 11.  FEV1-decline coefficients by Bhatt and ESI-substituted diagnostic categories (years_from_baseline × diagnostic-category interaction term).  Each coefficient is the additional change in FEV1 (mL) per year vs the noCOPD reference.")
def fmt_int_se(est, se, p):
    if est in ("NA","") or est is None: return "—", "—"
    e = float(est); s = float(se)
    return f"{e:+.2f} ({e-1.96*s:+.2f}, {e+1.96*s:+.2f})", fmt_p(p)
rows11 = []
for r in t11:
    bhatt_cell, bhatt_p = fmt_int_se(r["bhatt_est"], r["bhatt_se"], r["bhatt_p"])
    esi_cell,   esi_p   = fmt_int_se(r["esi_est"],   r["esi_se"],   r["esi_p"])
    rows11.append([r["group"], bhatt_cell, bhatt_p, esi_cell, esi_p])
add_table(
    headers=["Group","Bhatt (mL/yr, 95% CI)","Bhatt p","ESI-variant (mL/yr, 95% CI)","ESI-variant p"],
    rows=rows11
)
caption_note("Neither schema produces large or significant differences in FEV1 slope for COPD-minor or COPD-major relative to noCOPD after adjustment for time-varying covariates.  Both schemas correctly identify the AFL-only-NoCOPD group (excluded from COPD by Bhatt) as not characterised by accelerated decline (positive coefficient = less negative slope than noCOPD reference).")
doc.add_paragraph("")

# Table 12-ex — Bhatt vs ESI-substituted exacerbations
t12 = read_csv("Table_Exacerbations_Bhatt.csv")
t12_stats = read_kv("Table_Exacerbations_Bhatt_stats.txt")
caption(f"Table 12-ex.  Prospective exacerbation rate ratios by Bhatt and ESI-substituted diagnostic categories (negative-binomial, n = {int(t12_stats['n_cohort']):,}, {int(t12_stats['n_total_exac']):,} total exacerbations; offset log(Years_Followed); reference = noCOPD).")
rows12 = []
for r in t12:
    bhatt_cell = fmt_hr(r["bhatt_IRR"], r["bhatt_LCI"], r["bhatt_UCI"])
    esi_cell   = fmt_hr(r["esi_IRR"],   r["esi_LCI"],   r["esi_UCI"])
    rows12.append([r["group"], bhatt_cell, fmt_p(r["bhatt_p"]), esi_cell, fmt_p(r["esi_p"])])
add_table(headers=["Group","Bhatt IRR (95% CI)","Bhatt p","ESI-variant IRR (95% CI)","ESI-variant p"], rows=rows12)
caption_note("Head-to-head equivalence: COPD-minor IRR 2.73 (Bhatt) vs 2.78 (ESI-variant); COPD-major 5.07 vs 4.47.  AFL-only-NoCOPD IRRs both cross 1, confirming both schemas correctly identify this group as not exacerbation-prone.")
doc.add_paragraph("")

# Supplementary threshold sensitivity table
caption("Supp Table — Threshold sensitivity.  Agreement of ten ESI-substitution variants with the full Bhatt schema for binary COPD vs noCOPD.  The 5-criterion variant with T_low = 1.0 / T_high = 2.5 was selected as primary; the 4-criterion variants drop the wall-thickening criterion entirely and treat ESI as a single emphysema-substitute (sensitivity analysis per Pete's concern).")
ts = read_csv("Supp_Table_Thresholds.csv")
rowsts = []
for r in ts:
    rowsts.append([r["variant"], r["n_COPD"],
                   f"{float(r['sens']):.3f}", f"{float(r['spec']):.3f}", f"{float(r['kappa']):.3f}"])
add_table(headers=["Variant","n classified as COPD","Sensitivity","Specificity","Cohen's κ"], rows=rowsts)
caption_note("Headline: the lowest-threshold 5-criterion variant (T_low = 0.5, T_high = 2.0) has the highest κ (0.86) but at the cost of specificity (88%); the selected variant (T_low = 1.0, T_high = 2.5) has κ = 0.82 with better specificity (94%) and clinically meaningful cut-offs.  The best 4-criterion variant (ESI replaces emphysema only, ESI ≥ 1.5 + ≥ 2 of 4 minors) achieves κ = 0.79 — slightly lower agreement but cleaner physiological interpretation since ESI is not asked to substitute for bronchial-wall thickening.")
doc.add_paragraph("")

# ====================================================================
# 4 DISCUSSION
# ====================================================================
H1("4.  Discussion")
topic("¶1 — Top-line summary: ESI is a continuous, spirometry-derived index partially independent of FEV1/FVC across the COPDGene spectrum.  It carries outcome-relevant information that FEV1/FVC alone misses — particularly for all-cause mortality (concentrated in GOLD 1–3) and FEV1 decline (concentrated in GOLD 0).  For respiratory-cause mortality, FEV1/FVC is the dominant predictor and ESI does not add independent value.")
topic("¶2 — Physiologic interpretation: FEV1/FVC reflects the *magnitude* of airflow obstruction (which can arise from several mechanisms); ESI reflects the *shape* of the expiratory flow–volume curve, which depends on loss of elastic recoil, thoracic gas compression, and early small-airway collapse — the mechanical hallmarks of emphysema.  At the severe end of the spectrum both markers saturate and become collinear; at the preserved end ESI's emphysema-specific signal becomes visible.")
topic("¶3a — ESI is essentially insensitive to bronchodilator (mean ΔESI ≈ −0.07 in our cohort, V1 pre vs post-BD).  This is a clinically important property: many COPD patients exhibit partial bronchodilator reversibility (< 12% or < 200 mL change in FEV1) that complicates diagnostic categorisation, but the ESI signal — being derived from the *shape* of the flow–volume curve rather than its absolute magnitude — is unaffected.  ESI's prognostic and diagnostic value therefore does not depend on the patient's BD-response status.")
topic("¶3b — Mortality result extends our GOLD 2–4 EPD subtyping finding into GOLD 1 and survives FEV1/FVC + ceiling sensitivity.  Comparison with prior cohorts is informative: in the Swedish geriatric general population (Luoto 2022), ESI was the *specific* respiratory-mortality predictor while age and FEV1 dominated all-cause mortality.  In our COPD-enriched cohort the pattern is opposite — FEV1/FVC dominates respiratory mortality and ESI adds value for all-cause mortality.  The difference plausibly reflects cohort composition: in COPD, severe airflow obstruction itself is the proximate cause of most respiratory deaths, while in the general population emphysema-specific physiology distinguishes a smaller subgroup at respiratory risk.")
topic("¶3b-2 — Cause-specific exploration of the all-cause ESI signal showed no localisation to any single non-respiratory cause (CVD, Cancer, Other, or the major specific subcauses with ≥ 100 events).  Two interpretations are equally consistent with the data: (a) ESI captures a generalised marker of lung mechanical impairment that contributes incrementally to multiple mortality pathways — a 'frailty-like' contribution to all-cause risk; or (b) the individual cause-specific analyses are underpowered (100–700 events per cause vs 2,839 for all-cause) to detect HRs of the 1.05–1.10 magnitude seen in aggregate.  Larger general-population cohorts could distinguish these.")
topic("¶3c — Engagement with the Bhatt 2025 multidimensional COPD diagnostic schema: when the two CT-imaging criteria of the Bhatt schema are replaced with an ESI-based criterion (spirometry + symptoms + ESI, no CT), the resulting classification carries the same prognostic weight as Bhatt's full schema — same mortality hazard ratios and same discriminative ability for both all-cause and respiratory mortality.  The classifier under-identifies in preserved spirometry (catches about half of the imaging-driven cases without symptoms), but those it does identify are equally at risk.  This supports use of ESI as a clinically meaningful approximation of multidimensional COPD diagnosis where CT is not available — a substantial population globally.")
topic("¶4 — The FEV1-decline finding is the novel mechanistic result: higher baseline ESI predicts accelerated FEV1 decline specifically in smokers with preserved spirometry (GOLD 0) — a sub-population that current GOLD criteria do not flag for risk monitoring but that the new Bhatt schema does identify on the basis of CT and symptoms.  Our finding suggests ESI provides a spirometric route to flagging the same at-risk individuals.")
topic("¶5 — PRISm story: clinical and methodological asymmetry.  In our cohort PRISm subjects have substantially lower FEV1 %predicted than GOLD 0 (≈ 70% vs ≈ 97%, Table 1) and higher mortality (Figure 2), despite both groups being labelled 'no airflow obstruction' under the fixed-ratio criterion.  Per Massimo's interpretation, this may partly reflect the use of forced (FVC) rather than slow vital capacity in the FEV1/FVC ratio: patients with mild obstruction may produce a reduced FVC under forced expiration, making the ratio appear preserved.  Under the LLN-based ATS/ERS 2022 spirometric criteria many PRISm subjects would likely be reclassified as GOLD 1–2.  ESI, computed from the absolute shape of the expiratory flow–volume curve rather than from predicted values, is invariant to this categorisation issue.  The PRISm-vs-GOLD-0 trajectory finding (Figure 6: PRISm rises faster than GOLD 0 from identical baseline ESI) is consistent with PRISm containing a subgroup with progressive emphysema-related physiology — possibly the same subgroup that LLN-based criteria would re-label as mild COPD.")
topic("¶6 — Honest framing of where ESI does not add unique value: within GOLD 4, the ESI ceiling limits within-stratum variance and the per-stratum HR is null.  Within PRISm, ESI does not independently predict mortality after adjustment.  For respiratory-cause mortality specifically, ESI does not add value beyond FEV1/FVC in any stratum.  The spectrum-wide ESI signal lives primarily in GOLD 0 (FEV1 decline) and GOLD 1–3 (all-cause mortality).")
topic("¶7 — Limitations: ESI ceiling at 10; DLco only at Visit 2; prospective exacerbation analysis pending Channing-cluster data; single-cohort discovery (external validation in general-population samples warranted); observational design.")

# ====================================================================
# 5 CONCLUSION + REFS + SUPPLEMENT
# ====================================================================
H1("5.  Conclusion")
topic("¶ — One short paragraph reframing ESI as a continuous spirometric dimension complementary to FEV1/FVC, not a CT substitute, with prognostic value for all-cause mortality and FEV1 decline concentrated where standard spirometry under-discriminates; with potential as a CT-free approximation of multidimensional COPD diagnosis (Bhatt 2025) in settings where CT is unavailable.")

H1("6.  References")
note("Placeholder.  Bhatt 2025 JAMA (multidimensional COPD); Luoto 2022 Respir Med (Swedish ESI mortality); Pistolesi 2026 ERJ (Italian general population); Occhipinti 2019 Respir Res; Occhipinti 2020 Respir Res; Occhipinti 2018 Radiology (CT marker correlations); Stanojevic 2022 ERJ (ATS/ERS spirometry standards); plus carry-forward from v10 reference list.")

H1("Supplementary material")
topic("Supp Fig 1 — Spectrum-stratum flow chart.")
topic("Supp Fig 2 — ESI vs FEV1/FVC dispersion at each FEV1/FVC percentile.")
topic("Supp Table 1 — DLco at V2 by stratum.")
topic("Supp Table 2 — Spline-ESI Cox sensitivity (showing approximate linearity).")
topic("Supp Table 3 — V2-baseline → V3 FEV1 5-year sensitivity (uses V2 ESI).")
topic("Supp Table 4 — Bronchodilator response of ESI by stratum (supports BD-insensitivity claim in Discussion).")
topic("Supp Table 5 — Per-stratum correlations of ESI with PRM emphysema (alongside %LAA-950 in Table 2).")

caption("Supp Table CT correlations.  Pearson correlations between Thirona-derived CT markers (full V1 cohort, pairwise complete cases).  Confirms Occhipinti Radiology 2018 finding of near-perfect linearity between %LAA-950HU and PRM emphysema (r ≈ 0.985).")
ct = read_csv("Supp_Table_CT_correlations.csv")
add_table(headers=["", *list(ct[0].keys())[1:]],
          rows=[[row[''], row['Exp_LAA856_total_Thirona'], row['Insp_LAA950_total_Thirona'],
                 row['PRM_pct_emphysema_Thirona'], row['PRM_pct_airtrapping_Thirona'], row['pctEmph_Thirona']] for row in ct])
caption_note("Headline: %LAA-950HU (inspiratory low-attenuation) and PRM emphysema are essentially indistinguishable (r = 0.985) in our cohort, mirroring the r ≈ 1 reported in 200 COPD patients in Occhipinti Radiology 2018.  This justifies treating either as the structural emphysema marker without changing the qualitative findings.")

doc.save(OUT)
print(f"Wrote: {OUT}")
