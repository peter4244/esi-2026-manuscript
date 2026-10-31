# Proofread: CT-free MD-COPD supplement draft v7

Date: 2026-10-31. Read-only pass; no files edited.

Sources read:
- `manuscript/CT-free MD-COPD supplement draft v7.docx` (paragraphs, all 8 tables, the XML for fonts, sections, page setup and table geometry)
- the LibreOffice PDF render (15 pages, each page viewed), and both embedded figure PNGs at full resolution
- `manuscript/CT-free MD-COPD manuscript draft v7.docx`
- `assets/*.csv` (aggregate tables only)

Counts: **2 must-fix**, **11 style/consistency**, **10 optional**.

Authors' decisions I did not re-flag: the Figure S2 brackets, the n column in Table S8, bootstrap CI values, the NIH disclaimer, and the Supplemental Methods wording on the visual CT rules and the bootstrap formula.

---

## A. Must-fix

### A1. Main text claims something about Figure S2 that the figure contradicts (chronic bronchitis)
- **Location:** main manuscript v7, Results, paragraph "Clinical, physiological, and CT characteristics of concordant and discordant groups…".
- **Text:** "…visual emphysema and definite airway wall thickening were more frequent in the CT-only group and symptom criteria were more frequent in the ESI-only group."
- **Problem:** among participants without airflow limitation, chronic bronchitis was **more** frequent in CT-only than in ESI-only: 28.2% vs 15.0%, Fisher P = 0.0044. Figure S2 marks this "**". Sources: `discord_profile_strata.csv` and `discord_profile_tests.csv`. Only mMRC ≥2 (84.4% vs 36.5%) and SGRQ ≥25 (94.0% vs 58.8%) were more frequent in ESI-only.
- **Suggested fix (wording, so it is Pete's call):** "…dyspnea (mMRC ≥2) and impaired health status (SGRQ ≥25) were more frequent in the ESI-only group, whereas chronic bronchitis was more frequent in the CT-only group."

### A2. Table S3 column headers break in the middle of words
- **Location:** Table S3 header row (PDF page 6).
- **Text as rendered:** "MD-COPD-CT noCOP / D", "Assigne / d, n", "Sensitivi / ty, %".
- **Problem:** the table uses a fixed layout. The four MD-COPD-CT columns are 835 twips wide (about 0.58 in), "Assigned, n" is 864 and "Sensitivity, %" is 893, with 9-pt bold text. Words wider than their cell get split. I expect Word to split them too at these widths, but I have only seen the LibreOffice render.
- **Suggested fix:** use a two-row header, with one "MD-COPD-CT category" cell spanning the four category columns and the subheads "noCOPD | AFL-only | COPD-minor | COPD-major" beneath it. Then widen "Assigned, n" and "Sensitivity, %", for example by narrowing "Classification" (1,512 twips). Shortening to "Sens., %" also works.

---

## B. Style and consistency

### B1. Table S6 legend says "ESI groups" instead of the classification name
- **Location:** Table S6 legend.
- **Text:** "The MD-NoCT minus MD-COPD-ESI column compares corresponding MD-NoCT and ESI groups,"
- **Fix:** "…compares corresponding MD-NoCT and MD-COPD-ESI groups (shown in the MD-COPD-ESI rows),"

### B2. Headings render in Calibri; all other text is Arial
- **Location:** every Heading 2: "Supplemental Methods", all eight table titles, both figure titles, "COPDGene files used" and "References".
- **Problem:** the Heading 2 style has both `w:asciiTheme="majorHAnsi"` and `w:ascii="Arial"`. The theme attribute takes precedence, and the theme's major font is Calibri. Body text, legends, tables and the Methods subheads ("Visual CT assessment" etc.) are Arial. The PDF shows the mismatch, for example on pages 3, 4 and 15. The main manuscript's Heading 2 is also theme-only, so this may be the house look. The supplement builder seems to have meant Arial.
- **Fix:** remove the theme attributes from Heading 2 in the builder (keep `w:ascii`/`w:hAnsi="Arial"`), or accept Calibri on purpose.

### B3. Legend labels and repeated titles are inconsistent
- **Text:** table legends start "Table S1." … "Table S8."; figure legends start "Supplemental Figure S1." / "Supplemental Figure S2."
- **Problem:** the two figure legends and the Table S3 legend ("Table S3. Cross-classification of MD-NoCT and MD-COPD-ESI against MD-COPD-CT. Rows indicate…") repeat the full title from the heading directly above. The other seven table legends do not.
- **Fix:** pick one label form ("Table Sx." / "Figure Sx."). Drop the repeated title sentence from the Table S3 legend and from both figure legends, or add it to all of them.

### B4. Two styles for cross-references inside legends
- **Text:** Table S5 legend: "Corresponding unadjusted rate ratios are shown in Supplemental Table S4." Table S7 legend: "Models were as in Table S6,"
- **Fix:** use one form, for example "Table S4".

### B5. Figure S1 lists the classifications in a different order from the tables and its own legend
- **Location:** Figure S1. Within each panel the y-axis reads MD-COPD-CT, MD-COPD-ESI, MD-NoCT.
- **Problem:** Tables S4-S7 and the Figure S1 legend use the order MD-COPD-CT, MD-NoCT, MD-COPD-ESI.
- **Fix:** reorder the y-axis to match the tables (this means regenerating the figure). If main Figure 3 uses the same order as Figure S1, keep the two figures consistent with each other. I did not view main Figure 3.

### B6. Figure S2 panel titles are spaced differently from the legend
- **Text:** figure strips read "mMRC ≥ 2" and "SGRQ ≥ 25"; the legend and main text read "mMRC ≥2", "SGRQ ≥25".
- **Fix:** remove the space in the figure strip labels (regenerate the figure).

### B7. Serial comma missing in the COPDGene files list
- **Text:** "…the visual CT scores, the symptom criteria and the cohort exclusions."
- **Problem:** the rest of the supplement uses the serial comma (for example "pack-years, and body mass index").
- **Fix:** "…the symptom criteria, and the cohort exclusions."

### B8. Supplemental Methods uses HR and IRR before defining them
- **Text:** "…unadjusted rate ratios and adjusted HRs or IRRs were reported without confidence intervals or P values."
- **Fix:** "…adjusted hazard ratios (HRs) or incidence rate ratios (IRRs)…"

### B9. Table S2 and the main text use different names for the same metric
- **Text:** Table S2 header "Balanced accuracy"; main Methods: "using Cohen's κ, mean per-category sensitivity, and macro-F1."
- **Fix:** use one term in both places. The Table S2 legend already defines balanced accuracy as the mean per-category sensitivity, so "balanced accuracy (mean per-category sensitivity)" in the main text would work.

### B10. Tables S4 and S5 lose the Outcome label when a block breaks across pages
- **Location:** PDF page 8, first body row "MD-COPD-ESI | 1,625 | 5.46 …" (belongs to COPD-major all-cause mortality). PDF page 10, first body row "MD-NoCT | 562 | 41.98 …" (belongs to COPD-major respiratory mortality).
- **Problem:** the repeated header row is present, but these continuation rows have a blank Outcome cell, so the reader cannot tell which outcome they belong to.
- **Fix:** set "keep with next" on rows within each outcome block, or repeat the outcome label on the continuation row.

### B11. Abbreviations are defined unevenly across legends
- ESI is defined in the Table S1, S2, S3 and Figure S1/S2 legends, but not in the S4, S5, S6, S7 or S8 legends. In those tables it appears only inside "MD-COPD-ESI" or "ESI-only".
- FEV₁ is not defined in the S6 or S7 legends. Table S1 defines only "FEV₁ %pred".
- SD is not defined in the Table S1 legend.
- **Fix:** define ESI and FEV₁ in each legend where they appear, or nowhere, consistently. Adding "SD = standard deviation" to Table S1 is optional.

---

## C. Optional

1. **Table S1, GOLD 0.** The main text says "preserved spirometry (formerly referred to as … GOLD grade 0)". The Table S1 legend could add "GOLD 0 = preserved spirometry" to match.
2. **Table S1 format.** Age has no unit (years). "Values are mean (SD) unless otherwise indicated" could read "…mean (SD) or %". The ESI column (1,008 twips) wraps every value onto two lines, for example "0.91 / (0.45)". Widening it slightly, for example by taking width from "Current smoker", would keep each value on one line.
3. **Table S2 legend.** The ESI rows ("ESI ≥0.75" … "ESI ≥4.00") are all for ≥2 of 4 criteria, but the legend says so only for the selected rule. Suggest: "ESI rows vary the ESI threshold with ≥2 of 4 criteria required". "both had the highest macro-averaged F1" could read "each had the highest macro-F1 within its candidate set". "against 89.0% and 85.0%" could read "compared with".
4. **Table S6 legend, sentence structure.** "adjusted for height, … pack-years, and baseline post-bronchodilator FEV₁ entered as an interaction with follow-up time" can be read as applying the interaction to every covariate. Suggest "…pack-years, baseline post-bronchodilator FEV₁, and the interaction of baseline FEV₁ with follow-up time". Note this is my reading of the intended model, not something I confirmed from the code.
5. **"visits 1 to 3"** in the S6 legend versus "visits 1-3" in the main text. Harmonize if wanted.
6. **Reference n for the FEV₁ analyses.** The S6 and S7 legends do not give the size of the noCOPD reference for the FEV₁ models, while S4, S5 and Figure S1 give it for the other outcomes. `fev1_decline.csv` does not contain it.
7. **Figure S2 legend, %LAA-950HU.** It was available for 3,457 of the 3,459 Both-COPD participants with airflow limitation (`discord_profile_tests.csv`, n2 = 3,457). The legend gives only n = 3,459. A note is optional.
8. **Non-parallel stratum labels.** Table S8 and Figure S2 use "Without airflow limitation" / "Airflow limitation". "With airflow limitation" would be parallel. The main text already says "with and without airflow limitation".
9. **FEV₁ glyph.** FEV₁ uses Unicode subscript one (U+2081) in Arial runs. In the PDF the ₁ in body and legend text falls back to another font and sits displaced, for example "FEV  ₁" in the S6 and S7 legends. In the Calibri headings it renders correctly. Worth checking in Word. The main text uses the same encoding, so the two documents are at least consistent.
10. **Minor layout and decimals.** The Table S6 legend runs from page 10 onto page 11. F1 has 2 decimals in Table S3 and 3 in Table S2. Rates have 2 decimals for mortality and 1 for exacerbations in Table S4; this looks deliberate.

---

## D. What was checked and found correct

**Dashes and characters**
- No em dashes (U+2014), en dashes (U+2013), figure dashes, non-breaking hyphens, NBSPs or zero-width spaces anywhere in document.xml or footer1.xml.
- All ranges use a plain hyphen, for example "[0.81-1.47]".
- Negatives use the minus sign U+2212, with "to" separators where a CI has a negative bound. This matches the main text ("−0.11 to −0.08").
- No doubled spaces, doubled words, space-before-punctuation, trailing spaces or curly quotes. Apostrophes are straight throughout.

**Typos and grammar**
- None found in the cover sheet, contents, Supplemental Methods, table titles, legends and footnotes, figure legends, files list or references, apart from the items above.

**Cover sheet**
- Title and author list match the main manuscript title page.

**Contents**
- All 13 entries match the heading text exactly, since they are generated by a TOC field on Heading 2.
- The page numbers (3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 15) match where each heading lands in the PDF.

**Names**
- MD-COPD-CT, MD-NoCT and MD-COPD-ESI are used consistently.
- noCOPD, AFL-only, COPD-minor and COPD-major are used consistently.
- CT-only, ESI-only and Both-COPD match between Table S8, Figure S2, both legends and main Figure 4.
- AFL-only is defined in every legend where it appears, and † is defined in S4 and S5, the only tables that use it.
- P values are formatted as "P = 0.022" or "< 0.005", the same as the main text.
- All CIs are in square brackets.
- Reference sizes 3,856 / 3,625 / 3,411 are stated in the S4, S5 and Figure S1 legends. They match main Figure 3 and `consensus_ref_group.csv` (n_cohort 3,856, n_mort 3,625, n_exac 3,411).

**Table S1 vs `supp_baseline.csv`**
- All 56 cells match.
- Stratum n values sum to 9,240.

**Table S2 vs `metric_sweep.csv`, `schema_fit.csv`, `objective_selection.csv`**
- All counts and metrics match after rounding.
- Every row sums to 9,240.
- The selected rows have the highest macro-F1 in their candidate sets (0.732 and 0.763).
- Legend figures match: held-out agreement 88.8% / 85.0% and in-sample 89.0% / 85.0% (`schema_fit` 0.8883 / 0.8498 and 0.8898 / 0.8498).

**Table S3 vs `crossclass.csv`, `agreement_by_group.csv`**
- All 32 cross-classification cells match.
- Sensitivity, PPV and F1 recomputed from the counts all match.
- PPV bootstrap P values match: noCOPD 0.022, others 0/1000 shown as "< 0.005". I read the Rmd (around line 2205) to confirm that `p_boot` tests the PPV difference, so the legend's "PPV differed" is correct.

**Tables S4 and S5 vs `consensus_ref_crude.csv`, `consensus_ref_risk.csv`, `group_vs_mdcopd.csv`**
- Checked by script: every row (events, rate, RR/HR/IRR with CI, ratio versus MD-COPD-CT with CI, P, and † placement): 0 mismatches.

**Table S6 vs `fev1_decline.csv`, `fev1_noct_vs_esi.csv`**
- All 9 group estimates, CIs, P values and n match.
- All 3 NoCT-minus-ESI differences match (−0.5, 0.0, −0.1, with P 0.65, 0.96, 0.90).

**Table S7 vs `fev1_decline_random_slope.csv`**
- All rows match.
- Legend slope SDs 19.0 / 18.8 / 18.7 match the CSV (18.95 / 18.76 / 18.66).

**Table S8 vs `discord_rates*.csv`, `discord_crude_strata.csv`**
- n, deaths, and all mortality and exacerbation RRs with CIs match in both strata.
- Group sizes match the Table S3 off-diagonal cells (85, 501, 350, 82).

**Figure S1**
- Points match Tables S4 and S5, for example AFL-only respiratory mortality for MD-NoCT: 8.07 unadjusted and 5.43 adjusted.
- Open and filled circles match the legend.
- Estimates from fewer than 10 events are drawn without CIs.
- The log x-axis differs by column, and the axis label and abbreviations match the legend.

**Figure S2**
- Bar heights match `discord_profile_strata.csv`.
- Significance marks match `discord_profile_tests.csv`: without AFL, ESI ns (0.13), LAA ** (0.0012), emphysema, wall thickening, mMRC and SGRQ ***, chronic bronchitis ** (0.0044); with AFL, ESI ***, LAA ns (0.53), emphysema and wall thickening ***.
- Group n values in the legend match Table S8.
- Error bars are shown for the two continuous measures only, as the legend states.

**Figure resolution**
- Both images are 300-dpi PNGs placed at about 346 effective dpi: 2,250 px across 6.5 in, and 3,115 px across 9 in.

**References S1-S3**
- Author lists, titles, journals, years and pages are formatted consistently.
- S1 (Radiology 2015;277:192-205) and S2 (Radiology 2018;288:859-866) match my knowledge of these papers. I did not independently check S3's pages (JAMA 2025;333(24):2164-2175).

**Main-text pointers**
- Every citation of Table S1-S8 and Figure S1-S2 in the main text exists.
- First citation order is Tables S1, S2, S3, S4, S5, then Figure S1, then Tables S6, S7, S8, then Figure S2. Table and figure numbering are each sequential.
- Each cited sentence is supported by the table or figure it cites (numbers checked: 21.9%, 9.2%, 1.38 / 1.42 / 1.14 / 0.96, 1.33 P = 0.006, 1.22 P = 0.074, 1.03 / 0.92, 0.39 / 0.09, the FEV₁ decline pattern, and the Table S8 pattern), except A1.
- The three "Online Supplement" pointers (visual CT details, COPDGene files, CI and fewer-than-10-events handling) each have matching content.

**Layout**
- Page setup is portrait Letter, with a landscape section for Figure S2 only.
- All tables are 9,360 twips wide (6.5 in) and fit the text width.
- Header rows repeat on S4 and S5.
- Every heading has keep-with-next, and no heading is stranded at the bottom of a page in the PDF.
