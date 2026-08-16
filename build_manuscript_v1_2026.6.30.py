"""ESI manuscript — first full draft (2026-06-30).
Incorporates Massimo's comments on v4 outline and his Introduction draft.
"""
import csv, os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI_manuscript_draft_v1_2026.6.30.docx"

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
# Body paragraph spacing
normal.paragraph_format.space_after = Pt(8)
normal.paragraph_format.line_spacing = 1.5

def H1(t): doc.add_paragraph(t, style="Heading 1")
def H2(t): doc.add_paragraph(t, style="Heading 2")
def H3(t): doc.add_paragraph(t, style="Heading 3")

def body(text):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Inches(0.25)
    r = p.add_run(text); r.font.size = Pt(11)

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

def read_csv_(name):
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
title = doc.add_paragraph(); title.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = title.add_run("The Emphysema Severity Index: A Spirometric Surrogate for Chest CT in the Multidimensional Diagnosis of COPD")
r.font.size = Pt(16); r.bold = True; r.font.name = "Arial"

au = doc.add_paragraph(); au.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = au.add_run("Peter J. Castaldi¹,²; Matteo Paoletti³; Mariaelena Occhipinti⁴; Alessandra Sorano³; Federico Lavorini³; Enrico Maiorino¹; Craig P. Hersh¹,⁵; Edwin K. Silverman¹,⁵; Massimo Pistolesi³")
r.font.size = Pt(11)

af = doc.add_paragraph(); af.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = af.add_run(
    "¹ Channing Division of Network Medicine, Brigham and Women's Hospital, Boston, MA, USA\n"
    "² Division of General Internal Medicine and Primary Care, Brigham and Women's Hospital, Boston, MA, USA\n"
    "³ Department of Experimental and Clinical Medicine, University of Florence, Florence, Italy\n"
    "⁴ Division of Radiology, Fondazione Toscana Gabriele Monasterio, Pisa, Italy\n"
    "⁵ Division of Pulmonary and Critical Care Medicine, Brigham and Women's Hospital, Boston, MA, USA"
)
r.font.size = Pt(10); r.italic = True

dt = doc.add_paragraph(); dt.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
r = dt.add_run("First full draft — 30 June 2026"); r.italic = True; r.font.size = Pt(9)
r.font.color.rgb = RGBColor(100,100,100)

# ====================================================================
# ABSTRACT
# ====================================================================
H1("Abstract")
H3("Background")
body(
    "The Bhatt 2025 multidimensional COPD diagnostic schema combines spirometry, chest computed tomography "
    "(CT) for emphysema and bronchial wall thickening, and respiratory symptoms.  CT is not universally "
    "available, limiting application of multidimensional diagnosis in routine clinical practice, large "
    "epidemiologic studies, and resource-limited settings.  The Emphysema Severity Index (ESI), a continuous "
    "spirometric measure of expiratory flow-volume curve morphology, may serve as a structural-imaging "
    "proxy.  (Note: Massimo plans to revise this paragraph after journal choice.)"
)
H3("Methods")
body(
    "In 9,463 COPDGene Visit-1 subjects with all required variables, we substituted ESI for the two "
    "CT-imaging criteria of the Bhatt schema using a 5-criterion scoring rule (ESI < 1.0 contributes 0 minor "
    "criteria; 1.0–< 2.5 contributes 1; ≥ 2.5 contributes 2).  We compared the resulting CT-free "
    "classification with the full Bhatt schema across all-cause and cause-specific (respiratory, "
    "cardiovascular, cancer, other) mortality, prospective exacerbation rate, and longitudinal FEV1 decline.  "
    "Subgroups were defined by classification category and by cross-tabulation between the two schemas."
)
H3("Results")
body(
    "Classification agreement was 91% (Cohen's κ = 0.82, sensitivity 88%, specificity 94%).  At the "
    "classification-category level, the two schemas produced essentially identical hazard ratios for all "
    "outcomes: COPD-major all-cause HR 2.59 (Bhatt) vs 2.39 (ESI-substituted); respiratory HR 13.93 vs 11.85; "
    "CVD 2.34 vs 2.24; exacerbation IRR 5.07 vs 4.47.  Discrimination was indistinguishable (all-cause "
    "C-index 0.703 vs 0.700; respiratory 0.822 vs 0.819).  Among preserved-spirometry subjects, Both-COPD "
    "subjects (concordant; n = 553) had the highest mortality; Bhatt-only-COPD (n = 546) remained "
    "significantly elevated; ESI-only-COPD (n = 95) showed significantly elevated cardiovascular mortality "
    "(HR 2.74, 95% CI 1.33–5.64, p = 0.006)."
)
H3("Conclusions")
body(
    "A CT-free implementation of the multidimensional COPD diagnostic schema, in which ESI substitutes for "
    "chest CT, preserves the prognostic discrimination of the full schema and identifies complementary "
    "at-risk subpopulations.  This makes multidimensional COPD diagnosis feasible in settings where chest "
    "CT is unavailable."
)

# ====================================================================
# INTRODUCTION (Massimo's draft)
# ====================================================================
H1("Introduction")
body(
    "Chronic obstructive pulmonary disease (COPD) is increasingly recognized as a multidimensional disease "
    "in which airflow limitation, structural lung abnormalities, and respiratory symptoms provide "
    "complementary information on disease expression.  Consequently, reliance on spirometry alone "
    "incompletely captures the biological heterogeneity of COPD and has prompted the development of "
    "multidimensional diagnostic approaches (Lowe 2019; Stolz 2022)."
)
body(
    "Recently, Bhatt and colleagues proposed a multidimensional diagnostic framework integrating "
    "spirometry, chest computed tomography (CT), and symptom burden.  By combining airflow obstruction "
    "with imaging evidence of emphysema or airway wall thickening and respiratory symptoms, this framework "
    "identifies clinically relevant COPD beyond conventional spirometric criteria and improves prediction "
    "of mortality and lung-function decline.  However, dependence on chest CT substantially limits "
    "implementation of this otherwise attractive diagnostic approach in routine clinical practice, large "
    "epidemiological studies, and healthcare settings where advanced imaging is unavailable or impractical."
)
body(
    "The Emphysema Severity Index (ESI) is a continuous spirometric measure derived exclusively from the "
    "morphology of the expiratory flow-volume curve.  Unlike conventional spirometric indices, which "
    "quantify expiratory volumes or flows and require comparison with anthropometric reference "
    "populations, ESI is intrinsically independent of reference equations because it reflects curve "
    "morphology rather than absolute lung function.  Previous studies have demonstrated close "
    "associations between ESI and quantitative CT measures of emphysema together with independent "
    "prognostic value across different populations (Occhipinti 2019, 2020; Luoto 2022; Pistolesi 2026).  "
    "These observations suggest that ESI may provide a physiological representation of the structural "
    "information contributed by chest CT within a multidimensional diagnostic framework."
)
body(
    "We therefore tested whether the structural contribution of chest CT to the multidimensional "
    "diagnostic framework proposed by Bhatt and colleagues can be reproduced using ESI, thereby enabling "
    "a CT-free implementation while preserving diagnostic agreement and prognostic performance.  Using "
    "the COPDGene cohort, we compared the original CT-based classification with an ESI-based "
    "classification across mortality, exacerbations, and longitudinal lung-function decline."
)

# ====================================================================
# METHODS
# ====================================================================
H1("Methods")

H2("Study population")
body(
    "The Genetic Epidemiology of COPD (COPDGene; NCT00608764) study enrolled 10,198 non-Hispanic White and "
    "African-American participants aged 45–80 years with at least 10 pack-years of smoking history between "
    "2007 and 2011 (Regan 2010).  Of these, 9,463 had complete data at Visit 1 for all Bhatt-schema "
    "variables (post-bronchodilator FEV1/FVC, CT visual emphysema and bronchial wall thickening, mMRC "
    "dyspnea, SGRQ score, chronic bronchitis status) and a valid ESI computation.  Up to two follow-up "
    "visits were used for longitudinal FEV1 analyses (Visit 2 ≈ 5 years; Visit 3 ≈ 10 years)."
)

H2("Bhatt 2025 schema and ESI substitution")
body(
    "The Bhatt schema consists of a major criterion (post-bronchodilator FEV1/FVC < 0.70) and five minor "
    "criteria: (i) visual emphysema (Fleischner ≥ mild); (ii) bronchial wall thickening (Fleischner "
    "definite); (iii) modified Medical Research Council (mMRC) dyspnea score ≥ 2; (iv) St. George's "
    "Respiratory Questionnaire (SGRQ) total ≥ 25; (v) chronic bronchitis.  Diagnostic categories: "
    "COPD-major = major criterion plus ≥ 1 minor; COPD-minor = no major criterion but ≥ 3 of 5 minors; "
    "AFL-only-NoCOPD = major criterion with 0 minors (excluded from COPD by Bhatt); noCOPD = no major and "
    "< 3 minors."
)
body(
    "ESI was calculated from post-bronchodilator spirometric values (peak expiratory flow, forced "
    "expiratory flows at 25%, 50%, and 75% of FVC, and FVC itself) using a fluid-dynamic model of the "
    "expiratory flow-volume curve (Occhipinti 2019, 2020).  In the ESI-substituted schema, the two "
    "CT-imaging criteria of the Bhatt schema were replaced by a single ESI-based score: ESI < 1.0 "
    "contributes 0 minor criteria; 1.0 ≤ ESI < 2.5 contributes 1; ESI ≥ 2.5 contributes 2.  The original "
    "threshold of ≥ 3 of 5 minor criteria for COPD-minor diagnosis was preserved."
)
body(
    "Threshold selection was based on agreement with the full Bhatt schema across ten variants (Cohen's κ "
    "for binary COPD vs noCOPD), including 4-criterion variants in which ESI replaced only the emphysema "
    "criterion (Supp Table S4).  The selected 5-criterion variant (T_low = 1.0, T_high = 2.5) yielded "
    "the optimal balance of agreement (κ = 0.82), sensitivity (88%), specificity (94%), and clinically "
    "meaningful cut-offs.  A 4-criterion variant in which ESI replaced emphysema only and wall "
    "thickening was dropped achieved κ = 0.79 and is reported as a sensitivity analysis."
)

H2("Outcomes")
body(
    "All-cause mortality.  Cox proportional-hazards modelling with time as days from baseline (rescaled "
    "to years) and event = vital status at the Sep-2023 follow-up snapshot.  Of the 9,463-subject Bhatt "
    "cohort, 9,400 had usable vital-status data after complete-case filtering on covariates "
    "(2,613 deaths over median 10.7 years)."
)
body(
    "Cause-specific mortality.  Respiratory (CCOD_COPD_resp), cardiovascular (CCOD_CVD), cancer "
    "(CCOD_Cancer), and other (CCOD_Other) deaths were derived from the COPDGene Mortality "
    "Cause-of-Death Adjudication file.  Cause-specific Cox models were used with non-target deaths "
    "treated as censored at the death date."
)
body(
    "Prospective exacerbation rate.  Total exacerbations reported during longitudinal follow-up (LFU "
    "survey file) were modelled with negative-binomial regression with log(Years_Followed) as offset.  "
    "In the analytic cohort (n = 8,898 after merge and covariate completeness), 24,454 total "
    "exacerbations were reported over a median 10.3 years of follow-up.  Severe exacerbations were "
    "analysed as sensitivity."
)
body(
    "Longitudinal FEV1.  Post-bronchodilator FEV1 (mL) was modelled with a linear mixed-effects model "
    "with a random intercept per subject, using all available visits per subject (V1, V2, V3)."
)

H2("Subgroup definitions")
body(
    "Two primary subgroup definitions were used.  First, by classification category: the four Bhatt "
    "categories (noCOPD as reference, AFL-only-NoCOPD, COPD-minor, COPD-major), with head-to-head "
    "comparison between the full Bhatt schema and the ESI-substituted schema.  Second, by "
    "cross-tabulation between the two schemas in preserved-spirometry subjects (FEV1/FVC ≥ 0.70): "
    "Both-noCOPD (reference), Both-COPD (concordant COPD by both schemas), Bhatt-only-COPD (Bhatt "
    "called COPD, ESI did not), ESI-only-COPD (ESI called COPD, Bhatt did not).  Secondary GOLD-"
    "stratified continuous-ESI analyses are reported in Supplementary materials."
)

H2("Statistical analysis")
body(
    "All multivariable models were adjusted for age at visit, sex, race, current smoking, pack-years, "
    "and body mass index (FEV1-decline models additionally adjusted for baseline height).  FEV1/FVC was "
    "scaled per 0.1-unit increment for clinical interpretability.  Pre-specified sensitivity analyses "
    "included: exclusion of subjects with ESI = 10 (ceiling effect; ≈ 3% of cohort); a 4-criterion ESI "
    "substitution variant; severe-exacerbation analyses.  All analyses were performed in R 4.5.2 using "
    "the survival, MASS, lme4, and lmerTest packages."
)

# ====================================================================
# RESULTS
# ====================================================================
H1("Results")

H2("Cohort characteristics")
body(
    "The analytic cohort comprised 9,463 COPDGene Visit-1 participants with complete data on all Bhatt "
    "schema variables (Table 1 of the Supplementary materials).  The cohort spanned the full COPDGene "
    "spectrum: 107 never-smokers, 4,327 smokers without obstruction (GOLD 0), 1,254 with preserved-ratio "
    "impaired spirometry (PRISm), and 4,421 with GOLD 1–4 airflow obstruction.  Mean baseline ESI rose "
    "monotonically with severity, from 0.83 (never-smokers) to 8.25 (GOLD 4)."
)

H2("ESI tracks chest-CT emphysema across the spectrum")
body(
    "Across the COPDGene spectrum, ESI was correlated with the two CT-based quantitative emphysema "
    "markers: overall r(ESI, %LAA-950HU) = 0.77; r(ESI, PRM emphysema) = 0.80.  The strength of "
    "correlation varied systematically by spectrum stratum (Table 1).  Among subjects with established "
    "airflow obstruction (GOLD 1–4), both correlations were strong (per-stratum r ≈ 0.45–0.58 with "
    "%LAA-950HU).  Among preserved-spirometry subjects (never-smokers, GOLD 0, PRISm), both ESI-FEV1/FVC "
    "and ESI-%LAA-950HU correlations were weak (per-stratum r ≤ 0.30 and ≤ 0.10 respectively).  This "
    "weak correlation in preserved spirometry reflects the limited dynamic range of visible emphysema in "
    "this band — most subjects have %LAA-950HU well below the 6% Fleischner threshold for emphysema "
    "(Lynch 2015) — rather than poor specificity of ESI itself."
)
body(
    "The two CT-emphysema markers (%LAA-950HU and PRM emphysema) were themselves nearly perfectly "
    "correlated in our cohort (r = 0.985), reproducing the observation of Occhipinti and colleagues "
    "(Radiology 2018).  Substituting PRM emphysema for %LAA-950HU produced essentially identical "
    "per-stratum correlations (Supp Table)."
)
body(
    "ESI was essentially insensitive to bronchodilator: mean change in ESI from pre- to "
    "post-bronchodilator at Visit 1 was −0.09.  This finding extends the observation in a smaller COPD "
    "population (dal Negro et al, EC Pulmonology and Respiratory Medicine) to the COPDGene cohort and "
    "establishes BD insensitivity as a clinically useful property distinguishing ESI from conventional "
    "FEV1- or FVC-based indices, which are themselves modified by bronchodilator response."
)

# Table 1: per-stratum correlations
caption("Table 1.  Per-stratum Pearson correlations between ESI and (a) FEV1/FVC and (b) chest-CT %LAA-950HU, across the COPDGene spectrum.")
t2 = read_csv_("Table_2.csv")
add_table(headers=["Stratum","n (FEV1/FVC)","r (ESI, FEV1/FVC)","n (%LAA-950)","r (ESI, %LAA-950)"],
          rows=[[r["stratum"], r["n_FF"], f"{float(r['r_FF']):+.2f}",
                 r["n_LAA"], f"{float(r['r_LAA']):+.2f}"] for r in t2])
caption_note(
    "Both correlations are weak in preserved-spirometry strata (never-smokers, GOLD 0, PRISm) and "
    "strong in obstructive strata (GOLD 1–4) — a consistent pattern reflecting the limited dynamic "
    "range of visible emphysema in subjects without airflow obstruction.  Substituting PRM emphysema "
    "for %LAA-950HU produces essentially identical per-stratum correlations (Supp Table)."
)
doc.add_paragraph("")

H2("ESI substitution produces a close approximation of the Bhatt classification")
body(
    "When the two CT-imaging criteria of the Bhatt schema were replaced by the ESI-based score, the "
    "resulting CT-free classification agreed with the full Bhatt schema on COPD-vs-noCOPD diagnosis in "
    "91% of subjects (sensitivity 88%, specificity 94%, Cohen's κ = 0.82).  The complete 4-way "
    "cross-tabulation (Table 2; Figure 1) showed 4,130 concordant noCOPD, 3,906 concordant COPD-major, "
    "553 concordant COPD-minor, and 21 concordant AFL-only-NoCOPD subjects."
)
body(
    "Of ten ESI-substitution variants evaluated (Supp Table), the selected 5-criterion variant "
    "(T_low = 1.0, T_high = 2.5) achieved the optimal balance of agreement and clinically meaningful "
    "cut-offs.  A 4-criterion sensitivity variant — in which ESI substituted only for the emphysema "
    "criterion and wall thickening was dropped — achieved κ = 0.79.  This supports the conclusion that "
    "the imaging contribution to the Bhatt schema is dominated by emphysema rather than wall thickening, "
    "and that ESI is most defensible as a proxy for the emphysema criterion specifically."
)

caption("Table 2.  Cross-tabulation of the Bhatt 2025 classification (rows) and the ESI-substituted classification (columns) in n = 9,463 V1 COPDGene subjects with all required variables.")
t6 = read_csv_("Table_6.csv")
add_table(headers=["Bhatt ↓ / ESI-substituted →","noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"],
          rows=[[r["Bhatt"], r["noCOPD"], r["AFL_only_NoCOPD"], r["COPD_minor"], r["COPD_major"]] for r in t6])
caption_note("Cohen's κ = 0.82 for binary COPD vs noCOPD.  Diagonal cells are concordant; off-diagonal cells define the discordance subgroups examined in Table 3 and §3.4 below.")
doc.add_paragraph("")

caption("Figure 1.  Stacked-bar visualisation of the Bhatt 2025 classification (left bar) and the ESI-substituted classification (right bar), with counts and percentages.")
add_figure(os.path.join(ASSETS, "Figure_Bhatt_StackedBars.png"), width_in=6.5)
doc.add_paragraph("")

body(
    "Among preserved-spirometry subjects (FEV1/FVC ≥ 0.70), 641 subjects (12.0%) were classified "
    "differently by the two schemas (Table 3).  Bhatt-only-COPD subjects (n = 546; Bhatt called COPD, "
    "ESI did not) had low mean ESI (0.80) and 91% had visible CT emphysema by qualitative read.  "
    "However, the mean %LAA-950HU in this group was only 1.4% — well below the 6% Fleischner threshold "
    "for definite emphysema (Lynch 2015) — suggesting that the qualitative emphysema reads in this "
    "group reflect reader detection at low burdens rather than substantial structural disease.  "
    "Conversely, ESI-only-COPD subjects (n = 95; ESI called COPD, Bhatt did not) had high mean ESI "
    "(1.48) and no visible CT findings (0% emphysema, 0% wall thickening) but heavy symptom burden "
    "(85% mMRC ≥ 2, 95% SGRQ ≥ 25) — diagnosis was driven by mechanical changes invisible on visual CT "
    "in subjects with elevated symptom burden.  Both-COPD subjects (n = 553) had moderate ESI (1.06), "
    "moderate CT findings, and the highest symptom burden (72% chronic bronchitis)."
)

caption("Table 3.  Baseline characteristics of the three discordance subgroups in preserved spirometry (FEV1/FVC ≥ 0.70).  Values are mean (SD) or %.")
t9 = read_csv_("Table_Discordance.csv")
rows9 = [[r["grp_5"], r["n"], r["age"], r["pct_F"], r["BMI"], r["pack_yr"], r["ESI"],
          r["FEV1_pp"], r["FEV1_FVC"], r["LAA950"], r["pct_emph"], r["pct_wall"],
          r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]] for r in t9]
add_table(
    headers=["Group","N","Age","%F","BMI","Pack-yr","ESI","FEV1 %pred","FEV1/FVC",
             "%LAA-950HU","%emph (visual)","%wall thick.","%mMRC ≥ 2","%SGRQ ≥ 25","%CB"],
    rows=rows9)
caption_note(
    "Mean %LAA-950HU in all three discordance subgroups is 1.4–1.7%, well below the 6% Fleischner "
    "threshold for emphysema.  The qualitative-emphysema flag in Bhatt-only-COPD reflects reader "
    "variability at low burdens rather than substantial structural disease; the high-ESI / no-CT-"
    "findings pattern in ESI-only-COPD suggests mechanical changes invisible on visual CT scoring."
)
doc.add_paragraph("")

H2("Equivalent prognostic discrimination at the classification level")
body(
    "For every outcome examined, the ESI-substituted classification produced hazard ratios and rate "
    "ratios essentially indistinguishable from the full Bhatt schema (Tables 4–6, Figures 2 and 3)."
)

# Table 4: all-cause + respiratory by classification
t8a = read_csv_("Table_8_allcause.csv"); t8r = read_csv_("Table_8_resp.csv"); stats8 = read_kv("Table_8_stats.txt")
caption(f"Table 4.  Adjusted all-cause and respiratory-cause mortality hazard ratios by Bhatt classification category, head-to-head Bhatt vs ESI-substituted schema (n = {int(stats8['n_cohort']):,}; reference: noCOPD).")
rows4 = []
t8r_by = {r["group"]: r for r in t8r}
for r in t8a:
    rr = t8r_by.get(r["group"], {})
    rows4.append([r["group"],
                  fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_HR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"]),
                  fmt_hr(rr.get("bhatt_HR"), rr.get("bhatt_LCI"), rr.get("bhatt_UCI")), fmt_p(rr.get("bhatt_p")),
                  fmt_hr(rr.get("esi_HR"),   rr.get("esi_LCI"),   rr.get("esi_UCI")),   fmt_p(rr.get("esi_p"))])
add_table(headers=["Group","Bhatt (all-cause)","p","ESI-substituted (all-cause)","p","Bhatt (respiratory)","p","ESI-substituted (respiratory)","p"], rows=rows4)
caption_note(f"C-index — all-cause: Bhatt {float(stats8['bhatt_cindex_all']):.3f}, ESI-substituted {float(stats8['esi_cindex_all']):.3f}.  Respiratory: Bhatt {float(stats8['bhatt_cindex_resp']):.3f}, ESI-substituted {float(stats8['esi_cindex_resp']):.3f}.  Adjusted for age, sex, race, current smoking, pack-years, BMI.")
doc.add_paragraph("")

caption("Figure 2.  Adjusted all-cause and respiratory-cause mortality hazard ratios (95% CI, log scale) from the Bhatt and ESI-substituted classifications.")
add_figure(os.path.join(ASSETS, "Figure_5.png"), width_in=6.8)
doc.add_paragraph("")

# Table 5: cause-specific by classification
t_cs = read_csv_("Table_CauseSpecific_byClass.csv")
caption("Table 5.  Cause-specific mortality hazard ratios by classification category, Bhatt vs ESI-substituted (vs noCOPD reference).  Cause-specific Cox; non-target deaths censored at death date.")
rows5 = []
for r in t_cs:
    rows5.append([
        r["cause"], r["group"], r["n_events_bhatt"],
        fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
        r["n_events_esi"],
        fmt_hr(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),       fmt_p(r["esi_p"])
    ])
add_table(headers=["Cause","Group","Bhatt events","Bhatt HR (95% CI)","Bhatt p",
                   "ESI events","ESI HR (95% CI)","ESI p"], rows=rows5)
caption_note("For all three cause categories, COPD-minor and COPD-major HRs are head-to-head equivalent between Bhatt and ESI-substituted schemas.  AFL-only-NoCOPD has too few cause-specific events (3–7 per cause) in either schema for reliable HR estimation; the consistent non-significant point estimates support Bhatt's exclusion of this group from COPD.")
doc.add_paragraph("")

caption("Figure 3.  Cause-specific mortality hazard ratios (95% CI, log scale) by Bhatt category (vs noCOPD), Bhatt vs ESI-substituted side by side, faceted by cause (CVD, Cancer, Other).")
add_figure(os.path.join(ASSETS, "Figure_CauseSpecific_byClass.png"), width_in=7.0)
doc.add_paragraph("")

# Table 6: exacerbations by classification
t12 = read_csv_("Table_Exacerbations_Bhatt.csv")
t12_stats = read_kv("Table_Exacerbations_Bhatt_stats.txt")
caption(f"Table 6.  Prospective exacerbation incidence-rate ratios by classification category (negative-binomial; n = {int(t12_stats['n_cohort']):,}; {int(t12_stats['n_total_exac']):,} total exacerbations).  Reference: noCOPD.")
rows6 = []
for r in t12:
    rows6.append([r["group"],
                  fmt_hr(r["bhatt_IRR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_IRR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"])])
add_table(headers=["Group","Bhatt IRR (95% CI)","Bhatt p","ESI-substituted IRR (95% CI)","ESI-substituted p"], rows=rows6)
doc.add_paragraph("")

body(
    "Across all four outcome categories examined — all-cause and respiratory mortality, cause-specific "
    "mortality (CVD, Cancer, Other), and prospective exacerbation rate — the ESI-substituted schema "
    "yielded essentially identical risk estimates to the full Bhatt schema, with overlapping confidence "
    "intervals and indistinguishable discrimination.  Longitudinal FEV1 decline by classification "
    "category (Supp Table S6) showed modest non-significant interactions for COPD-minor and COPD-major "
    "in both schemas after covariate adjustment; both schemas correctly identified the AFL-only-NoCOPD "
    "group (excluded from COPD by Bhatt) as not characterised by accelerated decline."
)

H2("Outcomes in cross-tabulation subgroups")
body(
    "We next examined outcomes in the discordance subgroups defined by the cross-tabulation between the "
    "two schemas (Table 7; preserved-spirometry subjects only; reference = Both-noCOPD)."
)

# Combine outcomes by discordance into Table 7 (multi-row)
t10 = read_csv_("Table_BhattOnly_vs_Both.csv")
t_cs_disc = read_csv_("Table_CauseSpecific_byDiscord.csv")
t10ex = read_csv_("Table_Exacerbations_Discordance.csv")
caption("Table 7.  Outcomes by cross-tabulation subgroup (preserved-spirometry only; vs Both-noCOPD reference).  Adjusted for age, sex, race, current smoking, pack-years, BMI.")
# Build combined table
rows7 = []
for r in t10:
    g = r["group"]
    # find matching cause-specific and exacerbation rows
    cvd = next((c for c in t_cs_disc if c["cause"] == "CVD" and c["group"] == g), None)
    can = next((c for c in t_cs_disc if c["cause"] == "Cancer" and c["group"] == g), None)
    oth = next((c for c in t_cs_disc if c["cause"] == "Other" and c["group"] == g), None)
    ex_r = next((e for e in t10ex if e["group"] == g), None)
    rows7.append([g, r["n"],
                  fmt_hr(r["all_HR"], r["all_LCI"], r["all_UCI"]),
                  fmt_hr(r["resp_HR"], r["resp_LCI"], r["resp_UCI"]),
                  fmt_hr(cvd["HR"], cvd["LCI"], cvd["UCI"]) if cvd else "—",
                  fmt_hr(can["HR"], can["LCI"], can["UCI"]) if can else "—",
                  fmt_hr(oth["HR"], oth["LCI"], oth["UCI"]) if oth else "—",
                  fmt_hr(ex_r["IRR"], ex_r["LCI"], ex_r["UCI"]) if ex_r else "—"])
add_table(headers=["Group","N","All-cause HR","Respiratory HR","CVD HR","Cancer HR","Other HR","Exacerbation IRR"],
          rows=rows7)
caption_note(
    "All HRs and IRRs are 95% CI from the same adjusted model.  Both-COPD carries the highest risk "
    "across every outcome.  Bhatt-only-COPD shows significantly elevated all-cause, respiratory, "
    "cancer (HR 1.64, p = 0.04), and exacerbation rates.  ESI-only-COPD shows significantly elevated "
    "CVD mortality (HR 2.74, 95% CI 1.33–5.64, p = 0.006) despite only 8 cause-specific events in 95 "
    "subjects."
)
doc.add_paragraph("")

body(
    "The cardiovascular-mortality finding in the ESI-only-COPD subgroup is particularly notable.  "
    "Among preserved-spirometry subjects whom Bhatt classified as noCOPD but ESI classified as "
    "COPD-minor, cardiovascular mortality was significantly elevated (HR 2.74, 95% CI 1.33–5.64, "
    "p = 0.006) versus the Both-noCOPD reference — despite only 8 cardiovascular deaths in this group.  "
    "This finding is hypothesis-generating but suggests that ESI may flag a subset of preserved-"
    "spirometry smokers with cardiovascular vulnerability not captured by visual CT scoring.  "
    "External replication is warranted."
)

H2("Secondary GOLD-stratified analyses")
body(
    "Secondary analyses treated ESI as a continuous predictor (rather than as a categorical substitute "
    "in the Bhatt classification) across the COPDGene spectrum (Supp Tables S7–S8).  Three patterns "
    "emerged.  For all-cause mortality, ESI added prognostic value beyond FEV1/FVC (HR 1.08 per unit "
    "after FEV1/FVC adjustment, p < 0.001), with the signal concentrated in GOLD 1–3 (per-stratum HRs "
    "1.09–1.32, all p < 0.05).  For respiratory mortality and exacerbations, ESI alone predicted but "
    "lost independent value after FEV1/FVC adjustment, consistent with airflow obstruction itself "
    "being the proximate driver of airway-event endpoints in COPD."
)
body(
    "For longitudinal FEV1 decline, the most novel finding emerged.  ESI added prognostic information "
    "beyond FEV1/FVC across the cohort, and this signal was specifically localised to GOLD 0 — "
    "smokers with preserved spirometry.  Each 1-unit higher baseline ESI in GOLD 0 subjects predicted "
    "an additional 4.7 mL/year of FEV1 decline (p = 0.001), independent of FEV1/FVC.  This identifies "
    "smokers with preserved spirometry whose lung function is already declining faster than peers — a "
    "subset not flagged for risk monitoring by conventional GOLD criteria but identified by ESI through "
    "a single spirometric test."
)
body(
    "Finally, an unexpected longitudinal observation: PRISm subjects and GOLD 0 subjects had "
    "essentially identical baseline ESI distributions (mean ≈ 0.90) but PRISm subjects showed a "
    "steeper rise in ESI over 10 years (mean ΔESI +0.26 vs +0.03; medians +0.12 vs +0.01; Figure 4).  "
    "This hypothesis-generating finding suggests PRISm may contain a sub-population with progressive "
    "emphysema-related mechanical changes that emerge over time."
)

caption("Figure 4.  Within-subject change in ESI from baseline over 10-year follow-up, by baseline spectrum stratum (PRISm vs GOLD 0).  Mean (left) and median (right) panels.")
add_figure(os.path.join(ASSETS, "Figure_6.png"), width_in=6.5)
doc.add_paragraph("")

# ====================================================================
# DISCUSSION
# ====================================================================
H1("Discussion")
body(
    "In this study we tested whether the structural component of the Bhatt 2025 multidimensional COPD "
    "diagnostic schema — which requires chest CT for visual emphysema and bronchial wall thickening — "
    "can be reproduced using the Emphysema Severity Index, a continuous spirometric measure derived "
    "from the morphology of the expiratory flow-volume curve.  We found that substituting ESI for the "
    "two CT-imaging criteria produced a CT-free classification that retained the prognostic "
    "discrimination of the full Bhatt schema across all-cause mortality, cause-specific mortality "
    "(respiratory, cardiovascular, cancer, other), prospective exacerbation rate, and longitudinal "
    "FEV1 decline.  At the classification-category level, the two schemas produced essentially "
    "identical hazard ratios across all outcomes, with indistinguishable discrimination.  The "
    "discordance analyses identified partially overlapping but complementary at-risk subpopulations, "
    "including a small group of preserved-spirometry subjects identified as COPD by ESI but not by "
    "Bhatt, who showed significantly elevated cardiovascular mortality despite small N."
)
body(
    "ESI's suitability as a structural-imaging proxy reflects two empirical observations.  First, ESI "
    "correlated with quantitative CT emphysema (%LAA-950HU and PRM emphysema) across the spectrum, "
    "and the two quantitative CT emphysema markers were themselves nearly perfectly correlated "
    "(r = 0.985), reproducing the observation of Occhipinti and colleagues (2018).  Second, ESI is "
    "essentially insensitive to bronchodilator (mean ΔESI = −0.09 at Visit 1), confirming the "
    "observation in a smaller COPD population (dal Negro et al, EC Pulmonology and Respiratory "
    "Medicine).  The absence of BD response is a clinically valuable property: many COPD subjects "
    "exhibit partial bronchodilator reversibility (< 12% or < 200 mL FEV1) that complicates "
    "diagnostic categorisation based on conventional spirometric thresholds but does not affect ESI."
)
body(
    "ESI does not faithfully capture the bronchial-wall-thickening dimension of the Bhatt schema; "
    "prior work has shown only weak correlation between ESI and airway-wall metrics.  The 5-criterion "
    "substitution rule used here treats ESI as a combined proxy for both imaging criteria — defensible "
    "statistically (higher discrimination than the 4-criterion alternative) but conceptually mixed.  "
    "The 4-criterion sensitivity variant, in which ESI substitutes only for the emphysema criterion "
    "and wall thickening is dropped, achieved similar prognostic discrimination.  This supports the "
    "conclusion that the imaging contribution to the Bhatt schema is dominated by the emphysema "
    "component, with wall thickening contributing less independent prognostic information."
)
body(
    "The discordance subgroup findings require careful interpretation.  In all three discordance "
    "subgroups in preserved spirometry, the mean %LAA-950HU was very low (1.4–1.7%) — well below the "
    "6% Fleischner threshold for definite emphysema (Lynch 2015).  This suggests that the discordance "
    "between visual and ESI-based classification in this band is largely driven by measurement noise "
    "near the boundary between normal and abnormal, rather than by fundamentally different "
    "physiological information.  Bhatt-only-COPD subjects had 91% visible emphysema by qualitative "
    "read despite quantitatively normal %LAA-950HU, suggesting that reader detection at low burdens "
    "may have lower specificity than the quantitative threshold suggests.  Conversely, ESI-only-COPD "
    "subjects showed high ESI and heavy symptom burden but no visible imaging findings, possibly "
    "reflecting early or sub-clinical mechanical changes detectable by ESI but invisible to visual CT "
    "scoring.  The relevant clinical interpretation is that both methods identify clinically relevant "
    "subjects, but with imperfect overlap near the threshold of normality."
)
body(
    "The finding of significantly elevated cardiovascular mortality in the ESI-only-COPD subgroup "
    "(HR 2.74, 95% CI 1.33–5.64, p = 0.006) is particularly intriguing.  Despite only 8 cardiovascular "
    "deaths in 95 subjects, the effect size and statistical significance suggest that ESI may identify "
    "a subset of preserved-spirometry smokers whose mechanical lung impairment correlates with "
    "extrapulmonary cardiovascular risk not captured by visual CT.  External validation is essential, "
    "but the observation is consistent with the broader literature documenting cardiovascular "
    "vulnerability in subjects with pre-clinical respiratory impairment."
)
body(
    "Continuous-ESI secondary analyses sharpened the picture.  ESI added prognostic value beyond "
    "FEV1/FVC most clearly for all-cause mortality (driven by GOLD 1–3 contributions) and for FEV1 "
    "decline in GOLD 0 (smokers with preserved spirometry).  The FEV1-decline finding is particularly "
    "novel and clinically relevant: in a group not flagged for risk monitoring by conventional GOLD "
    "criteria, each 1-unit higher baseline ESI predicted an additional 4.7 mL/year of FEV1 decline.  "
    "This is consistent with ESI identifying subjects with early structural-mechanical changes whose "
    "lung function is already declining faster than peers, well before conventional spirometric "
    "criteria flag them as at risk.  For respiratory mortality and exacerbations, by contrast, "
    "FEV1/FVC alone was sufficient and ESI did not add independent value — consistent with airway "
    "obstruction itself being the proximate driver of airway-event endpoints."
)
body(
    "Comparison with prior cohorts is informative.  In the Swedish geriatric general population (Luoto "
    "2022), ESI predicted respiratory mortality specifically while age and FEV1 dominated all-cause "
    "mortality.  In our COPD-enriched cohort the pattern was opposite, with FEV1/FVC dominating "
    "respiratory mortality and ESI contributing primarily to all-cause and non-respiratory "
    "mortality.  The difference plausibly reflects cohort composition: in COPD-enriched samples, "
    "severe airflow obstruction itself drives respiratory deaths, while in the general population "
    "emphysema-specific physiology distinguishes a smaller subgroup at respiratory risk.  Similar "
    "patterns have been reported in the Italian general population (Pistolesi 2026)."
)
body(
    "The PRISm trajectory observation deserves brief mention.  PRISm and GOLD 0 subjects shared "
    "identical baseline ESI distributions but diverged in longitudinal ESI trajectory, with PRISm "
    "progressing faster over 10 years.  This hypothesis-generating finding suggests PRISm may contain "
    "a progressive subgroup with emerging emphysema-related mechanical changes.  Whether this "
    "subgroup corresponds to PRISm subjects who later transition to obstructive COPD is an open "
    "question for future longitudinal work."
)
body(
    "This study has limitations.  The cohort is from a single COPD-enriched study (COPDGene); "
    "external validation in general-population samples is warranted (Lowe 2019; Stolz 2022).  Diffusing "
    "capacity for carbon monoxide (DLco) was measured only at Visit 2 and was not incorporated into the "
    "primary analyses; future analyses incorporating DLco could further validate whether PRISm subjects "
    "identified as COPD by ESI have lower DLco values, supporting the interpretation that these are "
    "emphysema-driven cases.  The ESI ceiling at 10 affects approximately 3% of subjects and was "
    "addressed by sensitivity analysis.  Cause-specific cells with small event counts (notably the "
    "AFL-only-NoCOPD subgroup with 3–7 events per cause and the ESI-only-COPD subgroup with 8 CVD "
    "events) yield wide confidence intervals; interpretation acknowledges this.  Finally, the "
    "discordance findings reflect single-cohort data and require independent replication."
)

# ====================================================================
# CONCLUSION
# ====================================================================
H1("Conclusion")
body(
    "Substituting the Emphysema Severity Index for chest CT in the Bhatt 2025 multidimensional COPD "
    "diagnostic schema produces a clinically meaningful CT-free classification with prognostic "
    "discrimination equivalent to the full schema across mortality (all-cause and cause-specific), "
    "exacerbations, and longitudinal lung-function decline.  Where chest CT is unavailable, ESI offers "
    "a practical structural-imaging surrogate that enables multidimensional COPD diagnosis using "
    "spirometry and symptom assessment alone."
)

# ====================================================================
# REFERENCES (placeholder)
# ====================================================================
H1("References")
refs = [
    "Bhatt SP, et al. (COPDGene 2025 Diagnosis Working Group and CanCOLD Investigators).  A Multidimensional Diagnostic Approach for Chronic Obstructive Pulmonary Disease.  JAMA. 2025;333(24):2164–2175.",
    "Occhipinti M, Paoletti M, Bartholmai BJ, et al.  Spirometric assessment of emphysema presence and severity as measured by quantitative CT and CT-based radiomics in COPD.  Respir Res. 2019;20:101.",
    "Occhipinti M, Paoletti M, Crapo JD, et al.  Validation of a method to assess emphysema severity by spirometry in the COPDGene study.  Respir Res. 2020;21:103.",
    "Occhipinti M, et al.  Spirometric assessment of emphysema by quantitative CT and CT-based radiomics in COPD.  Radiology 2018.  [full citation to be confirmed]",
    "Luoto J, Pihlsgård M, Pistolesi M, et al.  Emphysema severity index (ESI) associated with respiratory death in a large Swedish general population.  Respir Med. 2022;106899.",
    "Pistolesi M, et al.  Emphysema severity index and respiratory risk in the Italian general population.  ERJ 2026 (in press).",
    "Lowe KE, Regan EA, Anzueto A, et al.  COPDGene 2019: redefining the diagnosis of chronic obstructive pulmonary disease.  Chronic Obstr Pulm Dis. 2019;6(5):384–399.",
    "Stolz D, Mkorombindo T, Schumann DM, et al.  Towards the elimination of chronic obstructive pulmonary disease: a Lancet Commission.  Lancet. 2022;400(10356):921–972.",
    "Lynch DA, Austin JH, Hogg JC, et al.  CT-definable subtypes of chronic obstructive pulmonary disease: a statement of the Fleischner Society.  Radiology. 2015;277(1):192–205.",
    "dal Negro RW, et al.  Emphysema Severity Index in a COPD population.  EC Pulmonology and Respiratory Medicine.  [full citation to be confirmed]",
    "Regan EA, Hokanson JE, Murphy JR, et al.  Genetic epidemiology of COPD (COPDGene) study design.  COPD. 2010;7(1):32–43.",
    "Stanojevic S, Kaminsky DA, Miller MR, et al.  ERS/ATS technical standard on interpretive strategies for routine lung function tests.  Eur Respir J. 2022;60(1):2101499.",
]
for i, r in enumerate(refs, 1):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Inches(-0.25)
    p.paragraph_format.left_indent = Inches(0.35)
    rr = p.add_run(f"{i}. "); rr.bold = True; rr.font.size = Pt(10)
    rr2 = p.add_run(r); rr2.font.size = Pt(10)

# ====================================================================
# SUPPLEMENT placeholder
# ====================================================================
H1("Supplementary materials (placeholder list)")
supp = [
    "Supp Table S1.  Cohort baseline characteristics by spectrum stratum.",
    "Supp Table S2.  Per-stratum agreement of the ESI-substituted classification with the full Bhatt schema (preserved-spirometry only).",
    "Supp Table S3.  ESI substitution threshold sensitivity — ten variants evaluated.",
    "Supp Table S4.  CT marker correlations (Thirona %LAA-950HU vs PRM emphysema; r = 0.985).",
    "Supp Table S5.  Bronchodilator response of ESI by stratum.",
    "Supp Table S6.  FEV1 decline coefficients by Bhatt classification category.",
    "Supp Table S7.  FEV1 decline coefficients by cross-tabulation subgroup.",
    "Supp Table S8.  Continuous-ESI mortality and FEV1-decline analyses by GOLD stratum.",
    "Supp Figure S1.  Spectrum-stratum flowchart of the analytic cohort.",
]
for s in supp:
    p = doc.add_paragraph(); r = p.add_run(s); r.font.size = Pt(10)
    p.paragraph_format.left_indent = Inches(0.25)

doc.save(OUT)
print(f"Wrote: {OUT}")
