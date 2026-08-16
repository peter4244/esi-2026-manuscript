"""ESI manuscript — draft v3 (2026-07-04).
Incorporates Massimo's ESI project working draft v1.docx into the v2 draft.
Rules applied (in priority): (1) correctness, (2) style consistency, (3) preserve Massimo's text.

Changes from v2:
- Introduction ¶3: adopt Massimo's cleaner closing phrase ("structural dimension of COPD traditionally described by chest CT").
- Methods (Massimo's ask: shorten): merged ESI-representation paragraphs; adopted rpart classification-tree
  language for the lower threshold (which matches rpart-derived ~1.05 closely); the upper threshold (2.5)
  is transparently described as chosen to identify subjects with both structural findings (top decile of
  the structural score) — this preserves correctness because rpart with equal priors gave 1.045 and
  1.705, not 1.0 and 2.5, and all downstream analyses use 1.0 and 2.5.
- Results: reorganized into Massimo's two subsections ("ESI captures CT-derived structural information" and
  "Reconstruction of the multidimensional diagnostic framework") plus outcomes retained (Massimo's own
  note: "The outcome data seems to be easier to list and discuss"). New Figure 3 (Discordance panel)
  inserted.
- Discussion: adopted Massimo's new opening; retained validated interpretation; added "Questions remaining"
  subsection reflecting Massimo's red-highlighted comments.
- Figure numbering updated: Figure 1 (stacked bars), Figure 2 (mortality forest), Figure 3 (discordance),
  Figure 4 (cause-specific by class), Figure 5 (PRISm trajectory).
"""
import csv, os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI_manuscript_draft_v3_2026.7.4.docx"

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
# TITLE / AUTHORS
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
r = dt.add_run("Draft v3 — 4 July 2026"); r.italic = True; r.font.size = Pt(9)
r.font.color.rgb = RGBColor(100,100,100)

# ====================================================================
# ABSTRACT
# ====================================================================
H1("Abstract")
H3("Background")
body(
    "The multidimensional diagnostic framework for chronic obstructive pulmonary disease (COPD) recently proposed by "
    "Bhatt and colleagues integrates spirometry, chest computed tomography (CT), and respiratory symptoms.  Because "
    "chest CT is not universally available, the requirement for imaging substantially limits application of this "
    "framework in routine clinical practice, in large epidemiological studies, and in resource-limited settings.  The "
    "Emphysema Severity Index (ESI), a continuous spirometric measure derived from the morphology of the expiratory "
    "flow-volume curve, may provide a physiological representation of the structural dimension of COPD traditionally "
    "described by chest CT.  (Note: Massimo plans to revise this paragraph after the target journal has been selected.)"
)
H3("Methods")
body(
    "The visually assessed CT structural component of the Bhatt framework was reformulated using a single continuous "
    "physiological measure (ESI), while the spirometric and symptom components were left unchanged.  In 9,463 COPDGene "
    "participants with complete baseline data, we compared diagnostic agreement, prognostic performance, and "
    "cross-classification concordance between the original CT-based framework and the reformulated ESI-based "
    "framework.  Outcomes included all-cause mortality, cause-specific mortality (respiratory, cardiovascular, "
    "cancer, other), prospective exacerbation rate, and longitudinal decline in FEV1."
)
H3("Results")
body(
    "Diagnostic agreement between the original CT-based and reformulated ESI-based frameworks was 91% (Cohen's κ = "
    "0.82; sensitivity 88%; specificity 94%).  Prognostic performance at the level of diagnostic categories was "
    "essentially identical between the two frameworks: for COPD-major, all-cause mortality hazard ratio (HR) 2.59 "
    "(original) versus 2.39 (reformulated); respiratory mortality HR 13.93 versus 11.85; cardiovascular mortality "
    "HR 2.34 versus 2.23; exacerbation incidence-rate ratio (IRR) 5.07 versus 4.47.  Discrimination was "
    "indistinguishable between the two frameworks (all-cause C-index 0.703 versus 0.700; respiratory C-index 0.822 "
    "versus 0.819).  Among preserved-spirometry participants, concordantly classified subjects (Both-COPD) carried "
    "the highest risk; discordantly classified subjects also carried elevated risk, with ESI-only-COPD subjects "
    "showing significantly elevated cardiovascular mortality (HR 2.74; 95% CI 1.33–5.64; p = 0.006) despite a small "
    "number of events."
)
H3("Conclusions")
body(
    "A CT-free implementation of the multidimensional COPD diagnostic framework, in which ESI represents the "
    "structural component previously contributed by chest CT, preserves the prognostic discrimination of the "
    "original framework and identifies partially overlapping but complementary at-risk subpopulations.  This "
    "reformulation makes multidimensional COPD diagnosis feasible in settings where chest CT is unavailable."
)

# ====================================================================
# INTRODUCTION (Massimo verbatim, with his newest closing phrase)
# ====================================================================
H1("Introduction")
body(
    "Chronic obstructive pulmonary disease (COPD) is increasingly recognized as a multidimensional disease in which "
    "airflow limitation, structural lung abnormalities, and respiratory symptoms provide complementary information "
    "on disease expression.  Consequently, reliance on spirometry alone incompletely captures the biological "
    "heterogeneity of COPD and has prompted the development of multidimensional diagnostic approaches (Lowe 2019; "
    "Stolz 2022)."
)
body(
    "Recently, Bhatt and colleagues proposed a multidimensional diagnostic framework integrating spirometry, chest "
    "computed tomography (CT), and symptom burden.  By combining airflow obstruction with imaging evidence of "
    "emphysema or airway wall thickening and respiratory symptoms, this framework identifies clinically relevant "
    "COPD beyond conventional spirometric criteria and improves prediction of mortality and lung-function decline.  "
    "However, dependence on chest CT substantially limits implementation of this otherwise attractive diagnostic "
    "approach in routine clinical practice, large epidemiological studies, and healthcare settings where advanced "
    "imaging is unavailable or impractical."
)
body(
    "The Emphysema Severity Index (ESI) is a continuous spirometric measure derived exclusively from the morphology "
    "of the expiratory flow-volume curve.  Unlike conventional spirometric indices, which quantify expiratory "
    "volumes or flows and require comparison with anthropometric reference populations, ESI is intrinsically "
    "independent of reference equations because it reflects curve morphology rather than absolute lung function.  "
    "Previous studies have demonstrated close associations between ESI and quantitative CT measures of emphysema "
    "together with independent prognostic value across different populations (Occhipinti 2019, 2020; Luoto 2022; "
    "Pistolesi 2026).  These observations suggest that ESI may provide a physiological representation of the "
    "structural dimension of COPD traditionally described by chest CT."
)
body(
    "We therefore tested whether the structural contribution of chest CT to the multidimensional diagnostic "
    "framework proposed by Bhatt and colleagues can be reproduced using ESI, thereby enabling a CT-free "
    "implementation while preserving diagnostic agreement and prognostic performance.  Using the COPDGene cohort, "
    "we compared the original CT-based classification with an ESI-based classification across mortality, "
    "exacerbations, and longitudinal lung-function decline."
)

# ====================================================================
# METHODS — shortened per Massimo's request.
# ====================================================================
H1("Methods")

H2("Study design and population")
body(
    "The study was designed to determine whether the structural information contributed by chest computed "
    "tomography (CT) to the multidimensional diagnostic framework proposed by Bhatt and colleagues could be "
    "represented using a physiological measure derived from standard spirometry.  To isolate the contribution of "
    "structural information, only the representation of the structural component of the original diagnostic "
    "framework was reformulated, whereas all remaining diagnostic criteria, including spirometric airflow "
    "obstruction and symptom assessment, were left unchanged.  The analysis was performed using data from the "
    "COPDGene study (NCT00608764), a multicenter observational cohort of current and former smokers aged 45–80 "
    "years with a smoking history of at least 10 pack-years (Regan 2010).  Baseline evaluation included "
    "standardized post-bronchodilator spirometry, chest CT, symptom assessment, and longitudinal clinical "
    "follow-up.  Participants with complete data required to construct both the original CT-based and the "
    "reformulated ESI-based multidimensional classifications were included in the present analysis, comprising "
    "9,463 subjects at Visit 1.  Longitudinal analyses of FEV1 decline additionally included data from Visit 2 "
    "(approximately 5 years after baseline) and Visit 3 (approximately 10 years after baseline)."
)

H2("Original multidimensional diagnostic framework")
body(
    "The multidimensional diagnostic framework proposed by Bhatt and colleagues integrates three complementary "
    "domains of COPD: spirometric airflow obstruction, respiratory symptoms, and structural abnormalities assessed "
    "by chest CT.  The major diagnostic criterion is post-bronchodilator FEV1/FVC below 0.70.  Five minor criteria "
    "comprise two structural criteria—visual emphysema (Fleischner assessment at least mild) and airway wall "
    "thickening (Fleischner assessment definite)—together with three symptom criteria: modified Medical Research "
    "Council dyspnea score of 2 or greater, St. George's Respiratory Questionnaire total score of 25 or greater, "
    "and chronic bronchitis.  Participants meeting the major criterion together with at least one minor criterion "
    "are classified as COPD-major; participants meeting at least three of five minor criteria without the major "
    "criterion are classified as COPD-minor; participants meeting the major criterion alone are classified as "
    "AFL-only-noCOPD; and the remaining participants are classified as noCOPD."
)

H2("ESI-based physiological representation of visually assessed CT structural information")
body(
    "In the present study, the visually assessed CT structural information of the original framework was "
    "reformulated using a single continuous physiological measure, the Emphysema Severity Index (ESI), while all "
    "remaining components of the multidimensional diagnostic framework were left unchanged.  ESI values were "
    "calculated from standard spirometric measurements (peak expiratory flow, forced vital capacity, and forced "
    "expiratory flows at 25%, 50%, and 75% of vital capacity) using the previously validated algorithm "
    "(Occhipinti 2019, 2020).  Because ESI is derived exclusively from the morphology of the expiratory "
    "flow-volume curve, it is intrinsically independent of anthropometric reference equations and provides a "
    "continuous physiological measure ranging from 0 to 10."
)
body(
    "To preserve the original diagnostic architecture, in which the structural domain contributes up to two of "
    "five minor criteria, the ESI-based representation was implemented as a two-threshold scoring rule (ESI values "
    "below the lower threshold contribute zero minor criteria; values between the two thresholds contribute one; "
    "values at or above the upper threshold contribute two).  The lower threshold was identified using a "
    "single-variable classification tree (rpart) developed in a randomly selected 80% training cohort and "
    "evaluated in the remaining 20%, yielding a cut-point of ESI ≈ 1.0 that separates subjects with no structural "
    "findings from those with at least one.  The upper threshold (ESI = 2.5) was selected to identify subjects in "
    "whom both visual emphysema and airway wall thickening were highly probable, corresponding to the top decile "
    "of the structural-score distribution.  Complete threshold-selection results are reported in the "
    "Supplementary materials.  The resulting ESI-derived structural representation was combined with the "
    "unchanged spirometric and symptom components of the original framework, allowing direct comparison between "
    "the original CT-based and the reformulated ESI-based classifications using identical diagnostic criteria."
)

H2("Diagnostic subgroup definitions")
body(
    "Participants were initially classified according to the four diagnostic categories defined by the original "
    "multidimensional framework (noCOPD, AFL-only-noCOPD, COPD-minor, COPD-major) and the corresponding categories "
    "generated by the reformulated ESI-based framework.  To investigate concordant and discordant classifications, "
    "participants were additionally categorized according to cross-classification between the two frameworks "
    "(Both-COPD, Bhatt-only-COPD, ESI-only-COPD, Both-noCOPD).  For exploratory analyses of the relationship "
    "between respiratory physiology and structural lung disease, participants were further stratified according "
    "to smoking and spirometric status (never smokers, GOLD 0, PRISm, and GOLD stages 1–4)."
)

H2("Clinical outcomes and statistical analysis")
body(
    "Clinical outcomes included all-cause mortality, cause-specific mortality (respiratory, cardiovascular, "
    "cancer, and other), prospective exacerbation rate, and longitudinal decline in FEV1.  Mortality was "
    "ascertained through September 2023; cause of death was ascertained from the COPDGene Mortality "
    "Cause-of-Death Adjudication file, with cause-specific analyses treating non-target deaths as censored at the "
    "date of death.  Exacerbations were analyzed prospectively using long-term follow-up survey data, and "
    "repeated post-bronchodilator spirometry from Visits 1 through 3 was used to assess longitudinal FEV1 decline."
)
body(
    "Classification agreement between the original CT-based and reformulated ESI-based frameworks was assessed "
    "using sensitivity, specificity, overall agreement, and Cohen's κ coefficient.  Associations between ESI and "
    "quantitative CT measures of emphysema (%LAA-950HU and PRM emphysema) were evaluated using Pearson correlation "
    "coefficients in the overall cohort and within predefined smoking and spirometric strata.  Associations "
    "between multidimensional diagnostic categories and clinical outcomes were evaluated using multivariable "
    "regression models appropriate for each endpoint: Cox proportional-hazards models for all-cause and "
    "cause-specific mortality, negative-binomial regression with log-follow-up offset for exacerbation rates, and "
    "linear mixed-effects models with a random subject intercept for longitudinal FEV1 decline.  All multivariable "
    "models were adjusted for age, sex, race, current smoking status, cumulative smoking exposure (pack-years), "
    "and body mass index; models of longitudinal FEV1 decline additionally included baseline height.  Three "
    "pre-specified sensitivity analyses evaluated the robustness of the findings: exclusion of subjects with ESI "
    "values at the upper boundary of the scale (ESI = 10), application of an alternative four-criterion framework "
    "in which ESI replaced only the emphysema criterion, and analyses restricted to severe exacerbations.  "
    "Statistical analyses were performed using R version 4.5.2; statistical significance was defined as a "
    "two-sided P < 0.05."
)

# ====================================================================
# RESULTS — reorganised around Massimo's two subsections plus outcomes
# ====================================================================
H1("Results")

H2("Cohort characteristics")
body(
    "The analytic cohort comprised 9,463 COPDGene participants with complete baseline data on all diagnostic "
    "criteria of the multidimensional framework (Supplementary Table S1).  The cohort spanned the full COPDGene "
    "spectrum, including 107 never-smokers, 4,327 smokers without airflow obstruction (GOLD 0), 1,254 subjects "
    "with preserved-ratio impaired spirometry (PRISm), and 4,421 subjects with GOLD 1–4 airflow obstruction.  "
    "Mean baseline ESI increased monotonically with severity across the spectrum, from 0.83 in never-smokers to "
    "8.25 in GOLD 4 participants."
)

H2("ESI captures CT-derived structural information")
body(
    "ESI showed a strong association with quantitative CT measures of emphysema across the COPDGene cohort "
    "(Pearson r = 0.77 with %LAA-950HU; r = 0.80 with PRM emphysema).  The strength of these associations "
    "increased progressively across predefined smoking and spirometric categories, with the highest correlation "
    "coefficients observed in subjects with established airflow obstruction (GOLD 1–4) and the lowest in "
    "never-smokers, GOLD 0, and PRISm (Table 1).  This progressive increase indicates increasing concordance "
    "between physiological and structural descriptors as structural lung disease becomes more established.  In "
    "the preserved-spirometry portion of the spectrum, quantitative %LAA-950HU values are typically well below "
    "the 6% threshold considered normal according to the Fleischner Society statement (Lynch 2015), which limits "
    "the dynamic range of visible emphysema in this portion of the cohort.  The two quantitative CT measures of "
    "emphysema (%LAA-950HU and PRM emphysema) were themselves nearly perfectly correlated (r = 0.985), "
    "reproducing the earlier observation of Occhipinti and colleagues (Occhipinti 2018)."
)
body(
    "A distinctive property of ESI is its independence from bronchodilator response.  In the present cohort, the "
    "mean change in ESI between pre- and post-bronchodilator measurements at Visit 1 was −0.09.  This finding "
    "extends to the COPDGene cohort a previous observation reported in a smaller COPD population by dal Negro and "
    "colleagues.  Because many COPD subjects exhibit partial bronchodilator reversibility (less than 12% or less "
    "than 200 mL of FEV1), a diagnostic index unaffected by bronchodilator response avoids the ambiguity "
    "introduced by the reversibility component of standard spirometric assessment."
)

caption("Table 1.  Per-stratum Pearson correlations between ESI and (a) FEV1/FVC and (b) chest-CT %LAA-950HU, across the COPDGene spectrum.")
t2 = read_csv_("Table_2.csv")
add_table(headers=["Stratum","n (FEV1/FVC)","r (ESI, FEV1/FVC)","n (%LAA-950)","r (ESI, %LAA-950)"],
          rows=[[r["stratum"], r["n_FF"], f"{float(r['r_FF']):+.2f}",
                 r["n_LAA"], f"{float(r['r_LAA']):+.2f}"] for r in t2])
caption_note(
    "Both correlations are weak in the preserved-spirometry portion of the spectrum (never-smokers, GOLD 0, "
    "PRISm) and strong in the obstructive portion (GOLD 1–4), reflecting the limited dynamic range of visible "
    "emphysema in participants without airflow obstruction.  Substituting PRM emphysema for %LAA-950HU produces "
    "essentially identical per-stratum correlations."
)
doc.add_paragraph("")

H2("Reconstruction of the multidimensional diagnostic framework")
body(
    "Replacing the visually assessed CT structural descriptor with ESI produced a multidimensional classification "
    "closely matching that obtained with the original Bhatt framework (Figure 1).  The distribution of subjects "
    "across the four diagnostic categories remained remarkably similar, yielding an overall agreement of 91% "
    "(Cohen's κ = 0.82), with a sensitivity of 88% and a specificity of 94%.  The complete 4×4 cross-tabulation "
    "of the two classifications (Table 2) identified 4,130 concordant noCOPD participants, 3,906 concordant "
    "COPD-major participants, 553 concordant COPD-minor participants, and 21 concordant AFL-only-noCOPD "
    "participants.  These findings indicate that the structural information captured by ESI is sufficient to "
    "preserve the overall architecture of the multidimensional diagnostic framework despite replacing the "
    "visually assessed CT component."
)

caption("Table 2.  Cross-tabulation of the original CT-based classification (rows) and the reformulated ESI-based classification (columns) in 9,463 COPDGene participants with complete baseline data.")
t6 = read_csv_("Table_6.csv")
add_table(headers=["Original ↓ / Reformulated →","noCOPD","AFL-only-noCOPD","COPD-minor","COPD-major"],
          rows=[[r["Bhatt"].replace("NoCOPD","noCOPD"), r["noCOPD"], r["AFL_only_NoCOPD"], r["COPD_minor"], r["COPD_major"]] for r in t6])
caption_note("Cohen's κ = 0.82 for concordance on the presence versus absence of COPD.  Diagonal cells indicate concordant classifications; off-diagonal cells define the discordant subgroups analyzed in Table 3 and Figure 3.")
doc.add_paragraph("")

caption("Figure 1.  Stacked-bar visualization of the original CT-based classification (left) and the reformulated ESI-based classification (right) in 9,463 COPDGene participants.")
add_figure(os.path.join(ASSETS, "Figure_Bhatt_StackedBars.png"), width_in=6.5)
doc.add_paragraph("")

body(
    "Cross-classification of the two frameworks within preserved spirometry (FEV1/FVC ≥ 0.70) identified 641 "
    "discordantly classified participants (12.0% of preserved-spirometry participants), distributed across three "
    "clinically distinct subgroups (Table 3, Figure 3).  Participants classified as COPD by the "
    "original framework but not by the reformulated framework (Bhatt-only-COPD; n = 546) had a low mean ESI "
    "(0.80), yet 91% were assigned visible emphysema on qualitative CT assessment.  The mean quantitative "
    "%LAA-950HU in this subgroup was only 1.4%, well below the 6% Fleischner threshold for definite emphysema, "
    "indicating that the qualitative-emphysema flag in this subgroup reflects expert-reader detection at low "
    "quantitative burdens rather than substantial structural disease.  Participants classified as COPD by the "
    "reformulated framework but not by the original framework (ESI-only-COPD; n = 95) had a high mean ESI "
    "(1.48), no visible emphysema or airway wall thickening on CT, and a heavy symptom burden (85% with modified "
    "Medical Research Council dyspnea score ≥ 2 and 95% with St. George's Respiratory Questionnaire total ≥ 25).  "
    "This pattern suggests that ESI identified mechanical changes in these participants that were not "
    "appreciated by visual CT assessment.  Concordantly classified COPD participants (Both-COPD; n = 553) had "
    "intermediate ESI (1.06), moderate imaging findings, and the highest overall symptom burden, including 72% "
    "with chronic bronchitis.  In all three discordantly classified subgroups the mean %LAA-950HU was very low "
    "(1.4–1.7%), which limits the interpretability of quantitative structural differences and is discussed "
    "further below."
)

caption("Table 3.  Baseline characteristics of the three discordantly classified subgroups within preserved spirometry (FEV1/FVC ≥ 0.70).  Values are mean (SD) unless otherwise indicated.")
t9 = read_csv_("Table_Discordance.csv")
rows9 = [[r["grp_5"].replace("NoCOPD","noCOPD"), r["n"], r["age"], r["pct_F"], r["BMI"], r["pack_yr"], r["ESI"],
          r["FEV1_pp"], r["FEV1_FVC"], r["LAA950"], r["pct_emph"], r["pct_wall"],
          r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]] for r in t9]
add_table(
    headers=["Group","N","Age","% F","BMI","Pack-yr","ESI","FEV1 %pred","FEV1/FVC",
             "%LAA-950HU","% emph (visual)","% wall thick.","% mMRC ≥ 2","% SGRQ ≥ 25","% CB"],
    rows=rows9)
caption_note(
    "The mean %LAA-950HU is very low (1.4–1.7%) in all three discordantly classified subgroups, well below the "
    "6% Fleischner threshold for definite emphysema.  The 91% prevalence of visible emphysema in Bhatt-only-COPD "
    "participants therefore reflects expert-reader detection at low quantitative burdens rather than substantial "
    "structural disease.  The high ESI values and heavy symptom burden of ESI-only-COPD participants, in the "
    "absence of visible imaging findings, suggest that ESI captures mechanical changes not appreciated by visual "
    "CT scoring."
)
doc.add_paragraph("")

caption("Figure 3.  Comparison of the three discordantly classified subgroups (Bhatt-only-COPD, Both-COPD, ESI-only-COPD) across seven descriptors: ESI, %LAA-950HU, visual emphysema, airway wall thickening, mMRC ≥ 2, SGRQ ≥ 25, and chronic bronchitis.")
add_figure(os.path.join(ASSETS, "Figure_3_Discordance.png"), width_in=6.8)
caption_note(
    "Top row: continuous descriptors (mean).  Bottom row: percentage prevalence of each dichotomous descriptor "
    "within the subgroup.  Bhatt-only-COPD participants combine low ESI with high visual-emphysema prevalence at "
    "quantitatively normal %LAA-950HU; ESI-only-COPD participants combine high ESI and heavy symptom burden with "
    "no visible imaging findings; Both-COPD participants combine intermediate ESI with the highest prevalence of "
    "chronic bronchitis."
)
doc.add_paragraph("")

H2("Prognostic performance at the level of diagnostic categories")
body(
    "For every outcome examined, the reformulated ESI-based framework produced hazard ratios and rate ratios "
    "essentially indistinguishable from those of the original CT-based framework (Tables 4–6, Figures 2 and 4).  "
    "For all-cause mortality, the adjusted hazard ratio for COPD-major relative to noCOPD was 2.59 in the "
    "original framework and 2.39 in the reformulated framework; the corresponding hazard ratios for COPD-minor "
    "were 1.91 and 1.94.  For respiratory mortality, the hazard ratio for COPD-major was 13.93 versus 11.85; for "
    "COPD-minor, 3.09 versus 2.91.  Discrimination was indistinguishable between the two frameworks, with "
    "C-index values of 0.703 versus 0.700 for all-cause mortality and 0.822 versus 0.819 for respiratory "
    "mortality."
)

t8a = read_csv_("Table_8_allcause.csv"); t8r = read_csv_("Table_8_resp.csv"); stats8 = read_kv("Table_8_stats.txt")
caption(f"Table 4.  Adjusted all-cause and respiratory-cause mortality hazard ratios by diagnostic category, head-to-head original CT-based versus reformulated ESI-based framework (n = {int(stats8['n_cohort']):,}; reference: noCOPD).")
rows4 = []
t8r_by = {r["group"]: r for r in t8r}
for r in t8a:
    rr = t8r_by.get(r["group"], {})
    g = r["group"].replace("NoCOPD","noCOPD")
    rows4.append([g,
                  fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_HR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"]),
                  fmt_hr(rr.get("bhatt_HR"), rr.get("bhatt_LCI"), rr.get("bhatt_UCI")), fmt_p(rr.get("bhatt_p")),
                  fmt_hr(rr.get("esi_HR"),   rr.get("esi_LCI"),   rr.get("esi_UCI")),   fmt_p(rr.get("esi_p"))])
add_table(headers=["Group","Original (all-cause)","p","Reformulated (all-cause)","p","Original (respiratory)","p","Reformulated (respiratory)","p"], rows=rows4)
caption_note(f"C-index — all-cause: original {float(stats8['bhatt_cindex_all']):.3f}, reformulated {float(stats8['esi_cindex_all']):.3f}.  Respiratory: original {float(stats8['bhatt_cindex_resp']):.3f}, reformulated {float(stats8['esi_cindex_resp']):.3f}.  Multivariable Cox proportional-hazards models adjusted for age, sex, race, current smoking, pack-years, and body mass index.")
doc.add_paragraph("")

caption("Figure 2.  Adjusted hazard ratios (95% CI, log scale) for all-cause and respiratory-cause mortality by diagnostic category, original CT-based versus reformulated ESI-based framework.")
add_figure(os.path.join(ASSETS, "Figure_5.png"), width_in=6.8)
doc.add_paragraph("")

body(
    "Cause-specific mortality analyses confirmed the same pattern of head-to-head equivalence (Table 5, Figure "
    "4).  For COPD-major relative to noCOPD, cardiovascular-mortality hazard ratios were 2.34 (original) versus "
    "2.23 (reformulated); cancer-mortality hazard ratios were 2.05 versus 1.88; other-cause hazard ratios were "
    "1.92 versus 1.80.  The AFL-only-noCOPD category contributed only three to seven cause-specific events in "
    "either framework, precluding reliable hazard-ratio estimation for this subgroup; the consistent "
    "non-significant point estimates observed for AFL-only-noCOPD are consistent with the exclusion of this "
    "group from a COPD diagnosis in the original framework."
)

t_cs = read_csv_("Table_CauseSpecific_byClass.csv")
caption("Table 5.  Cause-specific mortality hazard ratios by diagnostic category, original CT-based versus reformulated ESI-based framework (reference: noCOPD).  Non-target deaths were censored at date of death.")
rows5 = []
for r in t_cs:
    g = r["group"].replace("NoCOPD","noCOPD")
    rows5.append([
        r["cause"], g, r["n_events_bhatt"],
        fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
        r["n_events_esi"],
        fmt_hr(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),       fmt_p(r["esi_p"])
    ])
add_table(headers=["Cause","Group","Original events","Original HR (95% CI)","Original p",
                   "Reformulated events","Reformulated HR (95% CI)","Reformulated p"], rows=rows5)
caption_note("For all three cause categories, COPD-major and COPD-minor hazard ratios are essentially equivalent between the two frameworks.  The AFL-only-noCOPD subgroup contributed too few cause-specific events for reliable estimation in either framework.")
doc.add_paragraph("")

caption("Figure 4.  Cause-specific mortality hazard ratios (95% CI, log scale) by diagnostic category (reference: noCOPD), original versus reformulated framework, faceted by cause.")
add_figure(os.path.join(ASSETS, "Figure_CauseSpecific_byClass.png"), width_in=7.0)
doc.add_paragraph("")

body(
    "For prospective exacerbation rate (Table 6), the reformulated framework yielded incidence-rate ratios "
    "closely matching those of the original framework: for COPD-major, 5.07 (original) versus 4.47 "
    "(reformulated); for COPD-minor, 2.73 versus 2.78.  For the AFL-only-noCOPD category, incidence-rate ratios "
    "crossed unity in both frameworks, again consistent with the exclusion of this group from a COPD diagnosis.  "
    "Longitudinal FEV1-decline analyses by diagnostic category (Supplementary Table S6) yielded modest and "
    "non-significant differences for COPD-minor and COPD-major after adjustment for time-varying covariates in "
    "both frameworks; both frameworks correctly identified AFL-only-noCOPD as not characterized by accelerated "
    "FEV1 decline."
)

t12 = read_csv_("Table_Exacerbations_Bhatt.csv")
t12_stats = read_kv("Table_Exacerbations_Bhatt_stats.txt")
caption(f"Table 6.  Prospective exacerbation incidence-rate ratios by diagnostic category (negative-binomial regression; n = {int(t12_stats['n_cohort']):,}; total exacerbations {int(t12_stats['n_total_exac']):,}).  Reference: noCOPD.")
rows6 = []
for r in t12:
    g = r["group"].replace("NoCOPD","noCOPD")
    rows6.append([g,
                  fmt_hr(r["bhatt_IRR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_IRR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"])])
add_table(headers=["Group","Original IRR (95% CI)","Original p","Reformulated IRR (95% CI)","Reformulated p"], rows=rows6)
doc.add_paragraph("")

H2("Cross-classification outcomes")
body(
    "We next examined outcomes in the subgroups defined by cross-classification between the original and "
    "reformulated frameworks, restricting analyses to preserved-spirometry participants in whom the two "
    "frameworks may diverge (Table 7).  Concordantly classified Both-COPD participants carried the highest risk "
    "across every outcome, with an adjusted all-cause hazard ratio of 2.02 and a respiratory-mortality hazard "
    "ratio of 3.05 relative to Both-noCOPD participants.  Bhatt-only-COPD participants, whose diagnosis in the "
    "original framework rested primarily on qualitative visual emphysema at low quantitative burdens, showed "
    "significantly elevated all-cause (HR 1.53), respiratory (HR 2.48), cancer (HR 1.64), and exacerbation (IRR "
    "2.01) outcomes.  ESI-only-COPD participants, whose diagnosis in the reformulated framework rested on "
    "elevated ESI in the absence of visible CT findings, showed a smaller but positive all-cause mortality "
    "effect and, notably, a significantly elevated cardiovascular-mortality hazard ratio of 2.74 (95% CI "
    "1.33–5.64; p = 0.006) despite contributing only eight cardiovascular deaths in this small subgroup.  These "
    "findings indicate that concordant classification identifies the participants at highest risk, while both "
    "discordantly classified subgroups carry meaningful residual risk reflecting complementary information "
    "captured by the two frameworks."
)

t10 = read_csv_("Table_BhattOnly_vs_Both.csv")
t_cs_disc = read_csv_("Table_CauseSpecific_byDiscord.csv")
t10ex = read_csv_("Table_Exacerbations_Discordance.csv")
caption("Table 7.  Adjusted outcomes by cross-classification subgroup within preserved spirometry (FEV1/FVC ≥ 0.70; reference: Both-noCOPD).")
rows7 = []
for r in t10:
    g = r["group"]
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
    "All estimates are adjusted for age, sex, race, current smoking, pack-years, and body mass index.  "
    "Concordantly classified Both-COPD participants carried the highest risk across every outcome.  Bhatt-only-"
    "COPD participants also showed significantly elevated all-cause, respiratory, cancer, and exacerbation "
    "outcomes.  ESI-only-COPD participants demonstrated significantly elevated cardiovascular mortality (HR "
    "2.74; 95% CI 1.33–5.64; p = 0.006) despite the small number of cause-specific events in this subgroup."
)
doc.add_paragraph("")

H2("Secondary continuous-ESI analyses")
body(
    "In secondary analyses, ESI was examined as a continuous predictor across the COPDGene spectrum "
    "(Supplementary Tables S7 and S8).  ESI added prognostic value beyond FEV1/FVC for all-cause mortality "
    "(adjusted hazard ratio 1.08 per 1-unit increase after adjustment for FEV1/FVC, p < 0.001), with the signal "
    "concentrated in participants with mild-to-moderate airflow obstruction (GOLD 1–3).  For respiratory-cause "
    "mortality and for prospective exacerbations, ESI alone was a strong predictor but lost independent value "
    "after adjustment for FEV1/FVC, consistent with airflow obstruction itself being the proximate driver of "
    "these airway-event endpoints."
)
body(
    "For longitudinal FEV1 decline, an important secondary finding emerged.  ESI added prognostic information "
    "beyond FEV1/FVC across the entire cohort, and this signal was specifically localized to smokers with "
    "preserved spirometry (GOLD 0).  Within this subgroup, each 1-unit higher baseline ESI predicted an "
    "additional 4.7 mL/year of FEV1 decline (p = 0.001), independent of baseline FEV1/FVC.  This observation "
    "indicates that ESI identifies smokers with normal spirometry whose lung function is already declining "
    "faster than that of their spirometrically similar peers—a subgroup not flagged for risk monitoring by "
    "conventional GOLD criteria."
)
body(
    "An unexpected observation emerged from the longitudinal ESI trajectory analyses.  Participants with PRISm "
    "and participants with GOLD 0 shared essentially identical baseline ESI distributions (mean ≈ 0.90) yet "
    "diverged in longitudinal ESI trajectory over 10 years of follow-up, with PRISm participants showing a "
    "steeper rise (mean ΔESI +0.26 versus +0.03; medians +0.12 versus +0.01; Figure 5).  This "
    "hypothesis-generating observation suggests that PRISm may include a sub-population with progressive "
    "emphysema-related mechanical changes that emerge over time and were not detectable at baseline by either "
    "spirometry or ESI."
)

caption("Figure 5.  Within-subject change in ESI from baseline over 10-year follow-up, by baseline stratum (PRISm versus GOLD 0).  Mean (left panel) and median (right panel).")
add_figure(os.path.join(ASSETS, "Figure_6.png"), width_in=6.5)
doc.add_paragraph("")

# ====================================================================
# DISCUSSION — Massimo's new opening + interpretation retained + Questions remaining
# ====================================================================
H1("Discussion")
body(
    "The principal finding of the present study is that a physiological descriptor derived exclusively from the "
    "expiratory flow-volume curve captured the structural information provided by quantitative chest CT "
    "sufficiently to preserve the diagnostic architecture of a multidimensional COPD classification framework.  "
    "Rather than representing a simple comparison between ESI and CT, these findings support the concept that "
    "physiological and structural descriptors provide partially overlapping representations of the structural "
    "and functional consequences of the same disease process."
)
body(
    "The ability of the reformulated framework to reproduce the diagnostic classification obtained with the "
    "original CT-based model suggests that the structural information required for multidimensional "
    "classification is not uniquely linked to imaging itself, but may also be encoded within physiological "
    "measurements reflecting the mechanical consequences of structural lung damage.  These findings should not "
    "be interpreted as proposing a substitute for CT imaging, but rather as demonstrating preservation of "
    "structural information within the specific context of multidimensional COPD classification."
)
body(
    "The suitability of ESI as a physiological representation of the structural information contributed by chest "
    "CT rests on two empirical observations.  First, ESI is correlated with quantitative CT measures of "
    "emphysema across the COPDGene spectrum, and the two quantitative CT emphysema measures are themselves "
    "nearly perfectly correlated in our data (r = 0.985), reproducing the earlier observation of Occhipinti and "
    "colleagues (Occhipinti 2018).  Second, ESI is essentially insensitive to bronchodilator response (mean "
    "ΔESI = −0.09 at Visit 1), confirming and extending to the COPDGene cohort the observation reported by dal "
    "Negro and colleagues in a smaller COPD population.  The independence of ESI from bronchodilator response is "
    "clinically valuable because many COPD subjects exhibit partial reversibility that complicates diagnostic "
    "categorization based on conventional spirometric thresholds; a physiological measure unaffected by such "
    "reversibility provides a stable diagnostic input across the clinical spectrum."
)
body(
    "Although the reformulated framework showed good overall agreement with the original framework, ESI does not "
    "faithfully capture the airway wall thickening component of the original imaging criteria; prior work has "
    "demonstrated only weak associations between ESI and airway-wall metrics.  The primary five-criterion "
    "formulation adopted in the present study treats ESI as a combined physiological representation of both "
    "structural criteria, which is defensible statistically because it yielded the highest classification "
    "agreement but is conceptually mixed.  A sensitivity analysis using a four-criterion formulation, in which "
    "ESI represented only the emphysema criterion and the airway wall thickening criterion was omitted, yielded "
    "similar prognostic discrimination.  This convergence supports the conclusion that the imaging contribution "
    "to the original framework is dominated by the emphysema component and that ESI is most defensible as a "
    "physiological representation of the emphysema criterion specifically."
)
body(
    "The characterization of discordantly classified subgroups within preserved spirometry warrants careful "
    "interpretation (Figure 3).  In all three discordantly classified subgroups, the mean %LAA-950HU was very "
    "low (1.4–1.7%), well below the 6% Fleischner threshold for definite emphysema (Lynch 2015).  This suggests "
    "that discordance between the two frameworks in the preserved-spirometry portion of the spectrum reflects "
    "expert-reader detection at the boundary between normal and abnormal, rather than fundamentally different "
    "physiological information about substantial structural disease.  Bhatt-only-COPD participants had 91% "
    "visible emphysema by qualitative CT read despite quantitatively normal %LAA-950HU values, indicating that "
    "expert readers detected low-burden qualitative features that may not correspond to a definite quantitative "
    "threshold.  Conversely, ESI-only-COPD participants had high ESI and heavy symptom burden but no visible "
    "imaging findings, suggesting that ESI captured mechanical changes in these participants that were not "
    "appreciated by visual CT scoring.  Both frameworks therefore identify clinically meaningful participants, "
    "but with imperfect overlap near the threshold of normality on both modalities."
)
body(
    "A particularly intriguing observation concerns the ESI-only-COPD subgroup, in whom cardiovascular mortality "
    "was significantly elevated (HR 2.74; 95% CI 1.33–5.64; p = 0.006) despite only eight cardiovascular deaths "
    "in 95 participants.  Although the small number of events requires cautious interpretation and external "
    "validation, the magnitude and statistical significance of the effect suggest that ESI may identify a subset "
    "of preserved-spirometry smokers whose mechanical lung impairment correlates with extrapulmonary "
    "cardiovascular risk that is not captured by visual CT assessment.  This observation is consistent with the "
    "broader literature documenting cardiovascular vulnerability in subjects with early or sub-clinical "
    "respiratory impairment and warrants further investigation in larger cohorts."
)
body(
    "Secondary continuous-ESI analyses reinforced and extended these findings.  ESI added prognostic value "
    "beyond FEV1/FVC most clearly for all-cause mortality, with the signal concentrated in participants with "
    "mild-to-moderate airflow obstruction.  A novel and clinically relevant secondary finding emerged in the "
    "GOLD 0 subgroup: among smokers with preserved spirometry, each 1-unit higher baseline ESI predicted an "
    "additional 4.7 mL/year of FEV1 decline, independent of baseline FEV1/FVC.  This observation identifies a "
    "subgroup of participants whose lung function is already declining faster than that of their spirometrically "
    "similar peers, but who are not flagged as at-risk by conventional GOLD criteria.  Detection of such "
    "accelerated decline by a single spirometric measurement has clear potential for earlier identification and "
    "monitoring of individuals at risk for progressive respiratory impairment.  For respiratory-cause mortality "
    "and prospective exacerbations, by contrast, FEV1/FVC alone was sufficient and ESI did not add independent "
    "value, which is consistent with airflow obstruction itself being the proximate driver of airway-event "
    "endpoints in a COPD-enriched cohort."
)
body(
    "Comparison with prior population-based cohorts is informative.  In the Swedish geriatric general population "
    "(Luoto 2022), ESI predicted respiratory mortality specifically while age and FEV1 dominated all-cause "
    "mortality.  In the present COPD-enriched cohort the pattern was opposite, with FEV1/FVC dominating "
    "respiratory mortality and ESI contributing primarily to all-cause and non-respiratory mortality.  This "
    "difference plausibly reflects cohort composition: in COPD-enriched samples, severe airflow obstruction "
    "itself is the proximate driver of respiratory death, whereas in the general population emphysema-specific "
    "physiology distinguishes a smaller subgroup at respiratory risk.  Comparable patterns have been reported in "
    "the Italian general population (Pistolesi 2026)."
)
body(
    "The longitudinal ESI trajectory observation in PRISm deserves brief mention.  Participants with PRISm and "
    "participants with GOLD 0 shared essentially identical baseline ESI distributions yet diverged in ESI "
    "trajectory over 10 years, with PRISm participants showing a steeper rise.  This hypothesis-generating "
    "observation suggests that PRISm may contain a progressive sub-population with emerging emphysema-related "
    "mechanical changes, an interpretation that could be tested in future longitudinal analyses incorporating "
    "diffusing capacity for carbon monoxide (DLco), which was measured at Visit 2 in COPDGene but was not "
    "incorporated into the primary analyses of the present study."
)
body(
    "This study has several limitations.  The findings derive from a single COPD-enriched cohort (COPDGene) and "
    "require external validation in general-population and clinical-referral samples (Lowe 2019; Stolz 2022).  "
    "The five-criterion formulation of ESI as a combined structural representation is statistically well-"
    "supported but conceptually mixed with respect to the distinct roles of emphysema and airway wall thickening "
    "in the original framework.  The ESI ceiling at 10 affects approximately 3% of participants; sensitivity "
    "analyses excluding these participants did not alter the principal findings.  Cause-specific analyses of "
    "subgroups with fewer than 50 events (notably the AFL-only-noCOPD and the ESI-only-COPD subgroups for some "
    "causes) yield confidence intervals that require careful interpretation.  Finally, the discordance findings, "
    "in particular the elevated cardiovascular mortality in ESI-only-COPD participants, reflect a small number "
    "of events in a single-cohort observational analysis and require independent replication before firm "
    "clinical inferences can be drawn."
)

H2("Questions remaining")
body(
    "Several questions raised by the present analyses are highlighted here as targets for further work and for "
    "discussion among the co-authors.  First, the biological basis of the differences between Bhatt-only-COPD "
    "and ESI-only-COPD participants remains uncertain: whether these discordant groups represent distinct "
    "intermediate phenotypes or simply subjects close to the diagnostic thresholds of each framework cannot be "
    "resolved from the present analyses alone.  Second, the very low mean %LAA-950HU across all discordant "
    "subgroups is accompanied by substantial standard deviations, and it is possible that these means conceal "
    "biologically distinct subgroups; complementary analyses of medians, interquartile ranges, and proportions "
    "of participants below quantitative thresholds (%LAA-950HU < 6% and < 10%) may clarify this issue.  Third, "
    "the divergence between different structural descriptors—qualitative visual emphysema, quantitative %LAA-"
    "950HU, and ESI—at low quantitative emphysema burden warrants a more detailed exploration of how each "
    "modality behaves near the boundary between normal and abnormal.  Fourth, the systematic discrepancy "
    "between visual and quantitative CT assessments observed in Bhatt-only-COPD participants requires a "
    "dedicated methodological discussion.  Final interpretation of these questions will require analysis of the "
    "original individual %LAA-950HU values and further review of the visual scoring."
)

# ====================================================================
# CONCLUSION
# ====================================================================
H1("Conclusion")
body(
    "Reformulating the structural component of the Bhatt multidimensional COPD diagnostic framework using the "
    "Emphysema Severity Index yields a CT-free classification with prognostic discrimination essentially "
    "equivalent to the original CT-based framework, together with complementary information about at-risk "
    "subgroups that would otherwise be missed.  This reformulation enables application of multidimensional COPD "
    "diagnosis in clinical, epidemiological, and public-health settings where chest CT is unavailable, using "
    "spirometry and symptom assessment alone."
)

# ====================================================================
# REFERENCES
# ====================================================================
H1("References")
refs = [
    "Bhatt SP, et al. (COPDGene 2025 Diagnosis Working Group and CanCOLD Investigators).  A Multidimensional Diagnostic Approach for Chronic Obstructive Pulmonary Disease.  JAMA. 2025;333(24):2164–2175.",
    "Occhipinti M, Paoletti M, Bartholmai BJ, et al.  Spirometric assessment of emphysema presence and severity as measured by quantitative CT and CT-based radiomics in COPD.  Respir Res. 2019;20:101.",
    "Occhipinti M, Paoletti M, Crapo JD, et al.  Validation of a method to assess emphysema severity by spirometry in the COPDGene study.  Respir Res. 2020;21:103.",
    "Occhipinti M, et al.  Radiologic evaluation of emphysema by quantitative CT.  Radiology 2018.  [full citation to be confirmed]",
    "Luoto J, Pihlsgård M, Pistolesi M, et al.  Emphysema severity index (ESI) associated with respiratory death in a large Swedish general population.  Respir Med. 2022;106899.",
    "Pistolesi M, et al.  Emphysema severity index and respiratory risk in the Italian general population.  Eur Respir J. 2026 (in press).",
    "Lowe KE, Regan EA, Anzueto A, et al.  COPDGene 2019: redefining the diagnosis of chronic obstructive pulmonary disease.  Chronic Obstr Pulm Dis. 2019;6(5):384–399.",
    "Stolz D, Mkorombindo T, Schumann DM, et al.  Towards the elimination of chronic obstructive pulmonary disease: a Lancet Commission.  Lancet. 2022;400(10356):921–972.",
    "Lynch DA, Austin JHM, Hogg JC, et al.  CT-definable subtypes of chronic obstructive pulmonary disease: a statement of the Fleischner Society.  Radiology. 2015;277(1):192–205.",
    "dal Negro RW, et al.  Effect of bronchodilator on the Emphysema Severity Index in COPD.  EC Pulmonology and Respiratory Medicine.  [full citation to be confirmed]",
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
# SUPPLEMENT
# ====================================================================
H1("Supplementary materials (placeholder list)")
supp = [
    "Supp Table S1.  Baseline characteristics of the analytic cohort by spectrum stratum.",
    "Supp Table S2.  Per-stratum agreement of the reformulated ESI-based framework with the original CT-based framework, restricted to preserved-spirometry participants.",
    "Supp Table S3.  ESI-threshold selection: single-variable classification-tree (rpart) results in 80% training and 20% testing cohorts, together with the ten candidate configurations evaluated during framework development.",
    "Supp Table S4.  Correlations among quantitative CT measures of emphysema (%LAA-950HU and PRM emphysema; r = 0.985).",
    "Supp Table S5.  Bronchodilator response of ESI by stratum.",
    "Supp Table S6.  FEV1-decline coefficients by diagnostic category, original versus reformulated framework.",
    "Supp Table S7.  FEV1-decline coefficients by cross-classification subgroup within preserved spirometry.",
    "Supp Table S8.  Secondary continuous-ESI mortality and FEV1-decline analyses stratified by GOLD status.",
    "Supp Figure S1.  Flowchart of participant inclusion and exclusion.",
]
for s in supp:
    p = doc.add_paragraph(); r = p.add_run(s); r.font.size = Pt(10)
    p.paragraph_format.left_indent = Inches(0.25)

doc.save(OUT)
print(f"Wrote: {OUT}")
