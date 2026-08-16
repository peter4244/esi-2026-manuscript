"""Build the ESI manuscript OUTLINE — 2026-06-25 v4: restructured around the
ESI-as-CT-substitute and Bhatt-comparison framework, with subgroup-specific
outcome analyses as the core Results.
"""
import csv, os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ASSETS = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
OUT    = "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/ESI_manuscript_outline_2026.6.25_v4.docx"

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
title = doc.add_paragraph()
r = title.add_run("MANUSCRIPT OUTLINE — Emphysema Severity Index as a spirometric substitute for CT in the Bhatt 2025 multidimensional COPD diagnostic schema")
r.font.size = Pt(16); r.bold = True; r.font.name = "Arial"

note("Castaldi, Paoletti, Occhipinti, Sorano, Lavorini, Maiorino, Hersh, Silverman, Pistolesi  •  25 June 2026 (v4) — restructured around CT-substitute framework with subgroup-specific outcome comparisons")
note("Target journal: AJRCCM or ERJ.  Section headers and paragraph topics only; tables and figures embedded for review.")

H2("Working title — three candidates")
topic("'A spirometric approximation of the multidimensional COPD diagnostic schema: the Emphysema Severity Index as a substitute for chest CT'")
topic("'The Emphysema Severity Index reproduces the prognostic discrimination of CT-based multidimensional COPD diagnosis: a substitution analysis in COPDGene'")
topic("'Spirometry alone for multidimensional COPD diagnosis: the Emphysema Severity Index as a CT-free implementation of the Bhatt 2025 schema'")

# ====================================================================
# ABSTRACT
# ====================================================================
H1("Abstract  (250 w / AJRCCM, 200 w / ERJ)")
H3("Background")
topic("The Bhatt 2025 multidimensional COPD diagnostic schema combines spirometry, chest CT findings (visual emphysema and bronchial wall thickening), and symptoms.  CT is not universally available; spirometric proxies for the structural dimension are needed.  The Emphysema Severity Index (ESI), a continuous spirometric index of expiratory-curve concavity, may serve as such a proxy.")
H3("Methods")
topic("We tested in COPDGene (n = 9,463 V1 subjects with all required variables) whether ESI can substitute for the two CT-imaging criteria in the Bhatt schema, and compared the resulting CT-free classification against the full Bhatt schema across four outcomes: all-cause mortality, cause-specific mortality (CVD, Cancer, Other), prospective exacerbation rate, and FEV1 decline.  Subgroups: (a) the four classification categories themselves (noCOPD, AFL-only-NoCOPD, COPD-minor, COPD-major); (b) the cross-tabulation cells (Both-COPD, Bhatt-only-COPD, ESI-only-COPD).")
H3("Results")
topic("ESI correlates with CT-emphysema markers across the spectrum (r(ESI, PRM emphysema) = 0.80 overall, with stratum-specific variation).")
topic("The ESI-substituted Bhatt classification agrees with the full schema on COPD vs noCOPD in 91% of cases (κ = 0.82, sensitivity 88%, specificity 94%).")
topic("Within each classification category (noCOPD, COPD-minor, COPD-major), the Bhatt and ESI-substituted schemas produce essentially identical hazard ratios for all-cause and cause-specific mortality (e.g., COPD-major CVD HR 2.34 vs 2.24, Cancer 2.05 vs 1.88, Other 1.92 vs 1.80), and similar exacerbation rate ratios (COPD-major IRR 5.07 vs 4.47).")
topic("Across the cross-tabulation cells, Both-COPD subjects carry the highest risk on every outcome; Bhatt-only-COPD subjects are also significantly elevated (CVD HR 1.50, Cancer 1.64, Other 1.49); ESI-only-COPD subjects (n = 95) have significantly elevated CVD mortality despite small N (HR 2.74, p = 0.006).")
H3("Conclusions")
topic("Substituting ESI for the two CT-imaging criteria in the Bhatt 2025 schema produces a clinically meaningful CT-free approximation of multidimensional COPD diagnosis with prognostic discrimination equivalent to the full schema.  The two schemas identify partially overlapping but complementary at-risk subpopulations.")

# ====================================================================
# 1 INTRODUCTION
# ====================================================================
H1("1.  Introduction")
topic("¶1 — COPD heterogeneity and the long-standing recognition that spirometry alone misses important structural and symptomatic disease.")
topic("¶2 — The Bhatt 2025 JAMA multidimensional COPD diagnostic schema integrates spirometry, CT visual emphysema and bronchial wall thickening, and three symptom criteria; reclassifies 15.4% of preserved-spirometry COPDGene subjects as COPD with elevated mortality and faster FEV1 decline.  Imaging is not routinely available; CT-free implementations are needed for global applicability.")
topic("¶3 — ESI as a candidate spirometric proxy for the structural (emphysema) dimension: continuous, derived from the shape of the expiratory flow–volume curve, correlates with emphysema in prior work (Occhipinti 2019, 2020); insensitive to bronchodilator; prognostic value across multiple cohorts (Luoto 2022 Sweden; Pistolesi 2026 ERJ Italy; our own GOLD 2–4 subtyping work).")
topic("¶4 — Aim: test whether ESI can substitute for the two CT-imaging criteria in the Bhatt schema, and compare the resulting CT-free classification against the full Bhatt schema across multiple outcomes using both classification-category subgroups and discordance (cross-tab) subgroups.")

# ====================================================================
# 2 METHODS
# ====================================================================
H1("2.  Methods")
H2("2.1  Study population")
topic("COPDGene Visit-1 subjects with usable post-BD spirometry, valid ESI, and complete Bhatt-criteria variables (n = 9,463).  V2 (~5 y) and V3 (~10 y) follow-up for longitudinal FEV1.")
H2("2.2  Bhatt 2025 schema and ESI substitution")
topic("Bhatt schema: major criterion (FEV1/FVC < 0.70) plus 5 minor criteria (2 CT: visual emphysema, bronchial wall thickening; 3 symptom: mMRC ≥ 2, SGRQ ≥ 25, chronic bronchitis).  Categories: major = major + ≥1 minor; minor = ≥3 of 5 minor without obstruction.")
topic("ESI-substituted schema: the two CT-imaging criteria are replaced by a single ESI-based scoring rule.  A subject's ESI value contributes 0 minor criteria if ESI < 1.0, 1 if 1.0 ≤ ESI < 2.5, and 2 if ESI ≥ 2.5.  Original ≥3-of-5 threshold preserved.")
topic("Threshold selection: ten variants evaluated (Supp Table — Threshold sensitivity); the selected variant (T_low = 1.0, T_high = 2.5) achieves κ = 0.82 with high specificity (94%) and clinically meaningful cut-offs.")
topic("Methodological caveat: ESI tracks emphysema-related mechanics; correlation with bronchial-wall thickening is weaker.  A 4-criterion sensitivity variant (ESI replaces emphysema only; wall thickening dropped) is reported and discussed.")
H2("2.3  Outcomes")
topic("All-cause mortality (Cox PH; n = 10,105 with vital-status data, 2,857 deaths over median 10.7 y).")
topic("Cause-specific mortality (CVD, Cancer, Other; cause-specific Cox with non-target deaths censored at death date).")
topic("Prospective exacerbation rate (LFU file; negative-binomial regression with log(Years_Followed) offset; n = 8,898 subjects, 24,454 total exacerbations).")
topic("Longitudinal FEV1 in mL (linear mixed-effects model with random subject intercept).")
H2("2.4  Subgroup definitions")
topic("Primary subgroups (by classification): four diagnostic categories (noCOPD, AFL-only-NoCOPD, COPD-minor, COPD-major) — head-to-head Bhatt vs ESI-substituted.")
topic("Secondary subgroups (by cross-tabulation): Both-COPD, Bhatt-only-COPD (ESI missed), ESI-only-COPD (Bhatt missed), Both-noCOPD reference (analysed in preserved-spirometry subjects, where the schemas can disagree).")
topic("Tertiary subgroups: GOLD spectrum strata (Never / GOLD 0 / PRISm / GOLD 1–4), used to test continuous ESI vs continuous FEV1/FVC and to explore the PRISm trajectory observation.")
H2("2.5  Statistical analysis")
topic("All multivariable models adjusted for age, sex, race, current smoking, pack-years, BMI (mortality and exacerbation models) and baseline height (FEV1-decline models).")
topic("FEV1/FVC is reported on a per-0.1-unit scale for clinical interpretability.")
topic("Pre-specified sensitivity analyses: drop subjects pegged at the ESI ceiling of 10; 4-criterion ESI substitution variant; severe-exacerbations sensitivity.")

# ====================================================================
# 3 RESULTS
# ====================================================================
H1("3.  Results")

# --- 3.1 ---
H2("3.1  ESI as a spirometric proxy for CT emphysema metrics")
topic("¶ — Across the COPDGene spectrum, ESI correlates with CT-based emphysema markers: r(ESI, %LAA-950HU) = 0.77 overall, r(ESI, PRM emphysema) = 0.80, with weaker correlation in the preserved-spirometry strata (r ≤ 0.10 in GOLD 0 and PRISm) and strong correlation in the obstructive strata (r 0.45–0.58 in GOLD 2–4).  This is the empirical basis for treating ESI as a spirometric proxy for the emphysema imaging criterion.")
topic("¶ — The two CT emphysema markers (%LAA-950HU and PRM emphysema) are nearly perfectly correlated in our cohort (r = 0.985, confirming Occhipinti Radiology 2018).  Substituting PRM emphysema for %LAA-950HU in Table 2 changes the qualitative findings negligibly (see Supp Table — CT correlations).")
topic("¶ — ESI is essentially insensitive to bronchodilator (mean ΔESI ≈ −0.09 across the cohort at V1).  This distinguishes ESI from FEV1/FVC, which depends on bronchodilator status.  Implication: ESI provides a clinically usable signal that does not depend on BD-response classification.")
topic("¶ — The Bhatt 2025 schema requires CT for emphysema and bronchial wall thickening; CT is not universally available.  We tested whether ESI can substitute for these two imaging criteria.  (Refer to Methods §2.2 for the substitution rule.)")

caption("Table 1.  Per-stratum Pearson correlations between ESI and (a) FEV1/FVC, (b) %LAA-950HU.  Note the contrast: ESI–FEV1/FVC is weak in preserved spirometry but strong in obstructive strata; ESI–LAA-950HU is the opposite (weak in preserved, strong in obstructive), confirming that ESI tracks emphysema specifically.")
t2 = read_csv_("Table_2.csv")
add_table(headers=["Stratum","n (FEV1/FVC)","r (ESI, FEV1/FVC)","n (%LAA-950)","r (ESI, %LAA-950)"],
          rows=[[r["stratum"], r["n_FF"], f"{float(r['r_FF']):+.2f}",
                 r["n_LAA"], f"{float(r['r_LAA']):+.2f}"] for r in t2])
caption_note("Replication note: substituting PRM emphysema for %LAA-950HU gives essentially identical per-stratum correlations (Supp Table — Threshold sensitivity).")
doc.add_paragraph("")

# --- 3.2 ---
H2("3.2  Substituting ESI for CT produces a fairly close approximation of the Bhatt schema")
topic("¶ — Classification agreement (Table 2): the two schemas agree on COPD vs no COPD in 91% of cases (sensitivity 88%, specificity 94%; Cohen's κ = 0.82).  Refer to Figure 1 for stacked-bar visualisation and to Table 3 for the four-way cross-tabulation.")
topic("¶ — Per-stratum agreement (Table 4): In the preserved-spirometry strata where the schemas can disagree (GOLD 0 and PRISm), the ESI-substituted classifier is highly specific (96–98%) but catches only about half of Bhatt's COPD cases; the missed cases are predominantly those Bhatt diagnoses on the basis of visible CT emphysema.")
topic("¶ — Threshold sensitivity (Supp Table): of ten variants tested, the selected 5-criterion variant (T_low = 1.0, T_high = 2.5) achieves κ = 0.82 with balanced sensitivity (88%) and specificity (94%) and clinically meaningful cut-offs.  A 4-criterion sensitivity variant (ESI replaces emphysema only; wall thickening dropped) achieves κ = 0.79, retained as a methodological alternative when ESI's weaker relationship with wall thickening is the concern.")
topic("¶ — Discordance characterisation (Table 5; preserved-spirometry only): Bhatt-only-COPD subjects (Bhatt-COPD missed by ESI; n = 546) have low mean ESI (0.80) yet 91% have visible CT emphysema and only 16% have chronic bronchitis — anchored to the imaging criterion.  ESI-only-COPD subjects (n = 95) have high mean ESI (1.48), zero visible CT findings, but heavy symptom burden (85% mMRC ≥ 2, 95% SGRQ ≥ 25) — symptom-laden subjects with mechanical changes invisible to visual CT.  Both-COPD subjects (n = 553) sit between, with moderate ESI, moderate imaging, highest symptom burden (72% chronic bronchitis).")

caption("Figure 1.  Stacked-bar visualisation of the Bhatt 2025 classification (left) and the ESI-substituted classification (right), with counts and percentages per category.")
add_figure(os.path.join(ASSETS, "Figure_Bhatt_StackedBars.png"), width_in=6.5)
doc.add_paragraph("")

caption("Table 2.  Per-stratum agreement of the ESI-substituted classification with the full Bhatt schema among preserved-spirometry subjects (FEV1/FVC ≥ 0.70).")
t7 = read_csv_("Table_7.csv")
rows7 = []
for r in t7:
    sens = "—" if r["sens"] in ("NA","") else f"{float(r['sens']):.2f}"
    spec = "—" if r["spec"] in ("NA","") else f"{float(r['spec']):.2f}"
    rows7.append([r["stratum"], r["n"], r["bhatt_copd_n"], r["esi_copd_n"], r["both"], r["bhatt_only"], r["esi_only"], sens, spec])
add_table(headers=["Stratum","N","Bhatt-COPD","ESI-variant COPD","Both","Bhatt only","ESI only","Sens","Spec"], rows=rows7)
doc.add_paragraph("")

caption("Table 3.  Four-way cross-tabulation of the Bhatt 2025 classification (rows) and the ESI-substituted classification (columns) in n = 9,463 V1 subjects with all required variables non-missing.")
t6 = read_csv_("Table_6.csv")
add_table(headers=["Bhatt ↓ / ESI-variant →","noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"],
          rows=[[r["Bhatt"], r["noCOPD"], r["AFL_only_NoCOPD"], r["COPD_minor"], r["COPD_major"]] for r in t6])
caption_note("Concordant cells on the diagonal; off-diagonal cells define the discordance subgroups analysed in §3.3.")
doc.add_paragraph("")

caption("Table 4.  Per-stratum agreement of the ESI-substituted classification with the full Bhatt schema (preserved-spirometry subjects only).")
add_table(headers=["Stratum","N","Bhatt-COPD","ESI-variant COPD","Both","Bhatt only","ESI only","Sens","Spec"], rows=rows7)
doc.add_paragraph("")

caption("Table 5.  Characteristics of the discordant subjects in preserved spirometry: Bhatt-only-COPD (n = 546), Both-COPD (n = 553), ESI-only-COPD (n = 95).")
t9 = read_csv_("Table_Discordance.csv")
rows9 = [[r["grp_5"], r["n"], r["age"], r["pct_F"], r["BMI"], r["pack_yr"], r["ESI"],
          r["FEV1_pp"], r["FEV1_FVC"], r["LAA950"], r["pct_emph"], r["pct_wall"],
          r["pct_mMRC2p"], r["pct_SGRQ25p"], r["pct_CB"]] for r in t9]
add_table(
    headers=["Group","N","Age","%F","BMI","Pack-yr","ESI","FEV1 %pred","FEV1/FVC",
             "%LAA-950HU","%emph (visual)","%wall thick.","%mMRC ≥ 2","%SGRQ ≥ 25","%CB"],
    rows=rows9)
caption_note("Bhatt-only cases are imaging-anchored (91% visible emphysema, low ESI).  ESI-only cases are symptom-anchored with mechanical changes invisible on visual CT (high ESI, 0% visible findings, 85% mMRC ≥ 2, 95% SGRQ ≥ 25).")
doc.add_paragraph("")

# --- 3.3 ---
H2("3.3  Subgroup-specific outcomes: ESI-Bhatt vs OG-Bhatt across mortality (all-cause and cause-specific), FEV1 decline, and exacerbations")

H3("3.3a  By classification category — head-to-head equivalence")
topic("¶ — All-cause mortality (Table 6): for each diagnostic category, the Bhatt and ESI-substituted schemas produce essentially overlapping hazard ratios vs noCOPD (COPD-major: HR 2.59 Bhatt vs 2.39 ESI-variant; COPD-minor: 1.91 vs 1.94; AFL-only-NoCOPD: 0.90 vs 0.91).  C-index: Bhatt 0.703 vs ESI-variant 0.700.  Refer to Figure 2 (forest plot, all-cause).")
topic("¶ — Respiratory-cause mortality (Table 6): similarly close.  COPD-major Bhatt HR 13.93 vs ESI-variant 11.85; COPD-minor 3.09 vs 2.91; both schemas correctly identify AFL-only-NoCOPD as not significantly elevated.  C-index 0.822 vs 0.819.")
topic("¶ — Cause-specific mortality by classification (Table 7 and Figure 3): for each broad cause (CVD, Cancer, Other), the Bhatt and ESI-substituted schemas produce essentially identical hazard ratios for COPD-major and COPD-minor.  Example: CVD COPD-major HR 2.34 Bhatt vs 2.24 ESI-variant; Cancer 2.05 vs 1.88; Other 1.92 vs 1.80.  AFL-only-NoCOPD groups are too small for cause-specific HR estimation in either schema (events 3–7 per cause).")
topic("¶ — Exacerbation rate (Table 8): also closely overlapping.  COPD-major IRR 5.07 (Bhatt) vs 4.47 (ESI-variant); COPD-minor 2.73 vs 2.78; AFL-only-NoCOPD IRRs cross 1 in both schemas.")
topic("¶ — FEV1 decline (Table 9): neither schema produces large or significant interaction coefficients for COPD-minor or COPD-major after adjustment; both schemas correctly identify AFL-only-NoCOPD as not characterised by accelerated decline (positive coefficient ≈ less negative slope than noCOPD reference).")

# Table 6 — Mortality by classification (all-cause + respiratory)
t8a = read_csv_("Table_8_allcause.csv"); t8r = read_csv_("Table_8_resp.csv")
stats8 = read_kv("Table_8_stats.txt")
caption(f"Table 6.  Adjusted all-cause and respiratory-cause mortality hazard ratios from the Bhatt and ESI-substituted classifications (n = {int(stats8['n_cohort']):,}).  Reference: noCOPD.  Covariates: age, sex, race, current smoking, pack-years, BMI.")
rows6 = []
t8r_by = {r["group"]: r for r in t8r}
for r in t8a:
    rr = t8r_by.get(r["group"], {})
    rows6.append([r["group"],
                  fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_HR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"]),
                  fmt_hr(rr.get("bhatt_HR"), rr.get("bhatt_LCI"), rr.get("bhatt_UCI")), fmt_p(rr.get("bhatt_p")),
                  fmt_hr(rr.get("esi_HR"),   rr.get("esi_LCI"),   rr.get("esi_UCI")),   fmt_p(rr.get("esi_p"))])
add_table(headers=["Group","Bhatt (all-cause)","p","ESI-var (all-cause)","p","Bhatt (resp)","p","ESI-var (resp)","p"], rows=rows6)
caption_note(f"All-cause C-index — Bhatt {float(stats8['bhatt_cindex_all']):.3f}, ESI-variant {float(stats8['esi_cindex_all']):.3f}.  Respiratory C-index — Bhatt {float(stats8['bhatt_cindex_resp']):.3f}, ESI-variant {float(stats8['esi_cindex_resp']):.3f}.")
doc.add_paragraph("")

caption("Figure 2.  Forest plot of all-cause and respiratory-cause mortality hazard ratios (95% CI, log scale) from the Bhatt and ESI-substituted classifications.")
add_figure(os.path.join(ASSETS, "Figure_5.png"), width_in=6.8)
doc.add_paragraph("")

# Table 7 — Cause-specific by classification (Bhatt + ESI side by side)
t_cs = read_csv_("Table_CauseSpecific_byClass.csv")
caption("Table 7.  Cause-specific mortality hazard ratios by diagnostic category (vs noCOPD), for CVD, Cancer, and Other deaths.  Bhatt and ESI-substituted classifications side by side.")
rows7c = []
for r in t_cs:
    rows7c.append([
        r["cause"], r["group"], r["n_events_bhatt"],
        fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
        r["n_events_esi"],
        fmt_hr(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),       fmt_p(r["esi_p"])
    ])
add_table(headers=["Cause","Group","Bhatt n_events","Bhatt HR (95% CI)","Bhatt p",
                   "ESI-var n_events","ESI-var HR (95% CI)","ESI-var p"], rows=rows7c)
caption_note("AFL-only-NoCOPD has insufficient cause-specific events (3–7) in either schema for reliable HR estimation; both schemas show non-significant point estimates near the null, consistent with Bhatt's exclusion of this group from COPD.  COPD-minor and COPD-major HRs are head-to-head equivalent.")
doc.add_paragraph("")

caption("Figure 3.  Cause-specific mortality hazard ratios (95% CI, log scale) by Bhatt category (vs noCOPD reference), with Bhatt full schema and ESI-substituted schema side by side, faceted by cause (CVD, Cancer, Other).  AFL-only-NoCOPD has very few cause-specific events (3–7 per cause in both schemas), so its confidence intervals are wide and capped at 12 for display.  COPD-minor and COPD-major hazard ratios are nearly identical between the two schemas across all three causes — head-to-head prognostic equivalence at the classification level.")
add_figure(os.path.join(ASSETS, "Figure_CauseSpecific_byClass.png"), width_in=7.0)
doc.add_paragraph("")

# Table 8 — Exacerbations by classification
t12 = read_csv_("Table_Exacerbations_Bhatt.csv")
t12_stats = read_kv("Table_Exacerbations_Bhatt_stats.txt")
caption(f"Table 8.  Prospective exacerbation incidence-rate ratios by diagnostic category (negative-binomial, n = {int(t12_stats['n_cohort']):,}; {int(t12_stats['n_total_exac']):,} exacerbations).  Reference: noCOPD.")
rows8 = []
for r in t12:
    rows8.append([r["group"],
                  fmt_hr(r["bhatt_IRR"], r["bhatt_LCI"], r["bhatt_UCI"]), fmt_p(r["bhatt_p"]),
                  fmt_hr(r["esi_IRR"],   r["esi_LCI"],   r["esi_UCI"]),   fmt_p(r["esi_p"])])
add_table(headers=["Group","Bhatt IRR (95% CI)","Bhatt p","ESI-variant IRR (95% CI)","ESI-variant p"], rows=rows8)
doc.add_paragraph("")

# Table 9 — FEV1 decline by classification
t11 = read_csv_("Table_BhattDecline.csv")
caption("Table 9.  FEV1-decline coefficients by diagnostic category (years_from_baseline × category interaction).  Each coefficient = additional mL/yr change vs noCOPD reference.")
def fmt_int_se(est, se, p):
    if est in ("NA","") or est is None: return "—", "—"
    e = float(est); s = float(se)
    return f"{e:+.2f} ({e-1.96*s:+.2f}, {e+1.96*s:+.2f})", fmt_p(p)
rows9c = []
for r in t11:
    bc, bp = fmt_int_se(r["bhatt_est"], r["bhatt_se"], r["bhatt_p"])
    ec, ep = fmt_int_se(r["esi_est"],   r["esi_se"],   r["esi_p"])
    rows9c.append([r["group"], bc, bp, ec, ep])
add_table(headers=["Group","Bhatt (mL/yr, 95% CI)","Bhatt p","ESI-variant (mL/yr, 95% CI)","ESI-variant p"], rows=rows9c)
caption_note("Both schemas correctly identify AFL-only-NoCOPD as not characterised by accelerated decline.  No large or significant differences for COPD-minor or COPD-major in either schema after adjustment.")
doc.add_paragraph("")

H3("3.3b  By cross-tabulation subgroup — discordance outcomes")
topic("¶ — All-cause and respiratory mortality (Table 10): Both-COPD carries the highest risk (all-cause HR 2.02, resp HR 3.05); Bhatt-only-COPD remains significantly elevated (1.53, 2.48); ESI-only-COPD has positive but underpowered point estimates for all-cause (1.26).")
topic("¶ — Cause-specific mortality by discordance group (Table 11): for CVD specifically, ESI-only-COPD shows significantly elevated risk despite the small N (HR 2.74, 95% CI 1.33–5.64, p = 0.006), suggesting ESI is identifying a subgroup of preserved-spirometry subjects with cardiovascular vulnerability that visual CT misses.  For Cancer and Other deaths, ESI-only-COPD has positive point estimates but is underpowered.  Both-COPD and Bhatt-only-COPD subjects have elevated mortality across all three cause categories.")
topic("¶ — Exacerbation rate by discordance group (Table 12): same pattern as mortality — Both-COPD highest (IRR 3.17), Bhatt-only-COPD significantly elevated (2.01), ESI-only-COPD positive but borderline (1.59, p = 0.07).")
topic("¶ — FEV1 decline by discordance group (Table 13): point estimates are positive (Both-COPD −1.4 mL/yr; ESI-only-COPD −3.7 mL/yr; Bhatt-only-COPD +0.2 mL/yr) but none reach significance.  This is consistent with FEV1-decline differences being modest within the preserved-spirometry stratum where these subgroups live.")

# Table 10 — All-cause + resp mortality by discordance
t10 = read_csv_("Table_BhattOnly_vs_Both.csv")
caption("Table 10.  Mortality hazard ratios by cross-tabulation subgroup (vs Both-noCOPD reference; preserved-spirometry only).")
rows10 = []
for r in t10:
    rows10.append([r["group"], r["n"], r["n_deaths_all"],
                   fmt_hr(r["all_HR"], r["all_LCI"], r["all_UCI"]), fmt_p(r["all_p"]),
                   fmt_hr(r["resp_HR"], r["resp_LCI"], r["resp_UCI"]), fmt_p(r["resp_p"])])
add_table(headers=["Group","N","All-cause deaths","All-cause HR (95% CI)","All-cause p",
                   "Respiratory HR (95% CI)","Respiratory p"], rows=rows10)
doc.add_paragraph("")

# Table 11 — Cause-specific by discordance
t_cs_disc = read_csv_("Table_CauseSpecific_byDiscord.csv")
caption("Table 11.  Cause-specific mortality hazard ratios by cross-tabulation subgroup (vs Both-noCOPD reference; preserved-spirometry only).")
rows_cd = []
for r in t_cs_disc:
    rows_cd.append([r["cause"], r["group"], r["n_events"],
                    fmt_hr(r["HR"], r["LCI"], r["UCI"]), fmt_p(r["p"])])
add_table(headers=["Cause","Group","Events","HR (95% CI)","p"], rows=rows_cd)
caption_note("Striking finding: ESI-only-COPD (n = 95, 8 CVD events) shows significantly elevated CVD mortality (HR 2.74, p = 0.006), suggesting ESI flags a CT-invisible subgroup of preserved-spirometry subjects with cardiovascular vulnerability.  Other-cause cells with very small events (e.g., ESI-only Cancer with 3 events) yield non-significant but positive point estimates — interpretation should acknowledge the wide CIs.")
doc.add_paragraph("")

# Table 12 — Exacerbations by discordance
t10ex = read_csv_("Table_Exacerbations_Discordance.csv")
caption("Table 12.  Exacerbation incidence-rate ratios by cross-tabulation subgroup (vs Both-noCOPD reference; preserved-spirometry only).")
rows10ex = []
for r in t10ex:
    rows10ex.append([r["group"], r["n"], fmt_hr(r["IRR"], r["LCI"], r["UCI"]), fmt_p(r["p"])])
add_table(headers=["Group","N","Exacerbation IRR (95% CI)","p"], rows=rows10ex)
doc.add_paragraph("")

# Table 13 — FEV1 decline by discordance
t_dec = read_csv_("Table_FEV1Decline_byDiscord.csv")
caption("Table 13.  FEV1-decline interaction coefficients by cross-tabulation subgroup (vs Both-noCOPD reference; preserved-spirometry only).  Estimate = additional mL/yr decline vs reference.")
rows_dec = []
for r in t_dec:
    bc, bp = fmt_int_se(r["est"], r["se"], r["p"])
    rows_dec.append([r["group"], r["n_subj"], bc, bp])
add_table(headers=["Group","N subjects","Coefficient (mL/yr, 95% CI)","p"], rows=rows_dec)
caption_note("Point estimates indicate slower or non-significant decline differences within preserved spirometry — the most clinically actionable subgroup-specific finding here is the elevated cause-specific mortality (Table 11) rather than the decline trajectory.")
doc.add_paragraph("")

# --- 3.4 ---
H2("3.4  Secondary GOLD-stratified analyses")
H3("3.4a  Continuous ESI vs continuous FEV1/FVC for mortality and FEV1 decline (GOLD-stratified)")
topic("¶ — When ESI is treated as a continuous predictor (rather than as a substitute in the Bhatt classification), three patterns emerge.  All-cause mortality: ESI HR 1.08 per unit after FEV1/FVC adjustment (p < 0.001); concentrated in GOLD 1–3 (per-stratum HRs 1.09–1.32).  Respiratory mortality: ESI alone HR 1.10 (p < 0.001), but null after FEV1/FVC adjustment (HR 1.01, p = 0.85) — FEV1/FVC dominates.  Exacerbations: same pattern as respiratory mortality — ESI alone significant, null after FEV1/FVC adjustment.")
topic("¶ — FEV1 decline (continuous): ESI is the stronger pooled predictor (LR χ² 25.9 vs 11.7); per-stratum, ESI is independently significant only in GOLD 0 (β = −4.7 mL/yr per unit, p = 0.001).  This is the novel preserved-spirometry-smoker finding.")
topic("¶ — Cause-specific exploration of the all-cause continuous-ESI signal showed no localisation to any single non-respiratory cause when broken down by CVD / Cancer / Other or by specific subcauses.  Two equally consistent interpretations: distributed contribution to multiple pathways (frailty-like) or reduced statistical power per cause (100–700 events each vs 2,839 for all-cause).")
H3("3.4b  PRISm trajectory observation")
topic("¶ — PRISm subjects and smokers without obstruction (GOLD 0) start with identical baseline ESI distributions (mean ≈ 0.90) but over 10 years PRISm subjects show a faster rise (mean ESI change +0.26 vs +0.03; medians +0.12 vs +0.01 — direction preserved in both).  This is hypothesis-generating: PRISm may contain a subgroup with progressive emphysema-related physiology that emerges over time, possibly the same subgroup that LLN-based criteria (ATS/ERS 2022) would re-label as mild COPD.")
caption("Figure 4.  Within-subject ΔESI over 10-year follow-up: PRISm vs GOLD 0 (mean and median panels).")
add_figure(os.path.join(ASSETS, "Figure_6.png"), width_in=6.5)
doc.add_paragraph("")

# ====================================================================
# 4 DISCUSSION
# ====================================================================
H1("4.  Discussion")
topic("¶1 — Top-line summary: substituting ESI for the two CT-imaging criteria in the Bhatt 2025 multidimensional COPD schema produces a CT-free classification that retains the prognostic discrimination of the full schema across all-cause mortality, cause-specific mortality (CVD, Cancer, Other), prospective exacerbation rate, and (to a lesser extent) FEV1 decline.")
topic("¶2 — Why ESI substitutes well for CT in this context: ESI tracks emphysema-related expiratory mechanics; the two CT emphysema markers are nearly perfectly correlated with each other (r = 0.985); the bronchial-wall-thickening criterion is less faithfully captured by ESI (acknowledged sensitivity analysis with 4-criterion variant).")
topic("¶3 — Discordance subgroups carry independent clinical signal: Bhatt-only-COPD are imaging-anchored at-risk subjects ESI misses; ESI-only-COPD are symptom-anchored at-risk subjects Bhatt misses, with significantly elevated CVD mortality despite small N — suggesting ESI flags a CT-invisible cardiovascular-vulnerable subgroup that may benefit from non-respiratory risk-factor screening.")
topic("¶4 — BD insensitivity (ESI's near-zero change after bronchodilator) is a clinically valuable property distinguishing ESI from FEV1/FVC, particularly for subjects with partial reversibility.")
topic("¶5 — Continuous-ESI analyses (§3.4) sharpen the interpretation: ESI's added prognostic value lies in (a) all-cause mortality across the spectrum (driven by GOLD 1–3 contribution), (b) FEV1 decline specifically in GOLD 0 — the preserved-spirometry-smoker stratum.  In subjects with established airflow obstruction, FEV1/FVC alone is sufficient.  For respiratory mortality and exacerbations, FEV1/FVC fully captures the signal and ESI does not add — consistent with airway obstruction itself being the proximate cause.")
topic("¶6 — Comparison with prior cohorts: in the Swedish geriatric general population (Luoto 2022), ESI predicted respiratory mortality specifically; in our COPD-enriched cohort the pattern is opposite, consistent with cohort composition affecting which prognostic axis ESI dominates.")
topic("¶7 — PRISm trajectory observation (§3.4b) is hypothesis-generating: PRISm may contain a progressive subgroup that emerges over time, possibly the same subset that would be reclassified under LLN-based criteria.")
topic("¶8 — Limitations: ESI ceiling at 10; DLco only at V2; single-cohort discovery; CT-vs-ESI substitution is conceptually defensible for emphysema but less so for wall thickening (acknowledged); cause-specific analyses are underpowered for sub-categories with < 100 events; observational design.")

# ====================================================================
# 5 CONCLUSION
# ====================================================================
H1("5.  Conclusion")
topic("¶ — The ESI-substituted Bhatt classification is a clinically meaningful CT-free implementation of multidimensional COPD diagnosis.  Prognostic discrimination is equivalent to the full schema across multiple outcomes including all-cause and cause-specific mortality.  Discordance subgroups identify complementary at-risk populations — particularly an ESI-flagged, CT-invisible, cardiovascular-vulnerable subgroup that may merit further investigation.")

H1("6.  References")
note("Placeholder.  Key citations: Bhatt 2025 JAMA (multidimensional schema); Occhipinti 2019, 2020 (ESI development and validation); Occhipinti 2018 Radiology (CT marker correlations); Luoto 2022 Respir Med (Swedish respiratory-mortality finding); Pistolesi 2026 ERJ (Italian general-population finding); Stanojevic 2022 ERJ (ATS/ERS spirometry standards for PRISm discussion).")

H1("Supplementary material")
topic("Supp Fig 1 — Spectrum-stratum flow chart.")
topic("Supp Fig 2 — Cause-specific cumulative-incidence curves by Bhatt category.")
topic("Supp Table — Threshold sensitivity: ten ESI-substitution variants compared on agreement with full Bhatt schema (including 4-criterion variant where ESI replaces emphysema only).")
topic("Supp Table — CT marker correlations: Thirona %LAA-950HU vs PRM emphysema vs %LAA-856HU (r ≈ 0.985).")
topic("Supp Table — BD response of ESI by stratum (supports BD-insensitivity claim).")
topic("Supp Table — Cause-specific Cox HRs for ESI as a continuous predictor (per 1-unit) by cause of death, with FEV1/FVC adjustment.")
topic("Supp Table — Per-stratum continuous-ESI analyses for mortality, FEV1 decline, exacerbations.")

caption("Supp Table — Threshold sensitivity (Bhatt-substitution variants).  Comparison of ten ESI-substitution variants: 4-criterion (ESI replaces emphysema only; wall thickening dropped) and 5-criterion (ESI as two minors).  Selected = 5-crit T_low=1.0 / T_high=2.5.")
ts = read_csv_("Supp_Table_Thresholds.csv")
rowsts = []
for r in ts:
    rowsts.append([r["variant"], r["n_COPD"],
                   f"{float(r['sens']):.3f}", f"{float(r['spec']):.3f}", f"{float(r['kappa']):.3f}"])
add_table(headers=["Variant","n COPD","Sensitivity","Specificity","Cohen's κ"], rows=rowsts)

doc.save(OUT)
print(f"Wrote: {OUT}")
