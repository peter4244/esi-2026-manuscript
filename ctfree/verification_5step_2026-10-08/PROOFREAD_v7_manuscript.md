# Proofread: CT-free MD-COPD manuscript draft v7

Proofread on 2026-10-31. Sources: `ctfree/manuscript/CT-free MD-COPD manuscript draft v7.docx` (paragraphs, table, document XML), the LibreOffice PDF (18 pages, viewed as images), the v7 supplement (cross-references only), and the CSVs in `ctfree/assets/`. No file was edited. Paragraph numbers are python-docx indices (`[n]`). Page numbers refer to the PDF.

The items the authors already decided are not listed (see the brief).

Counts: 5 must-fix, 16 style/consistency, 14 optional polish.

---

## A. Errors to fix before circulation

**A1. "What This Study Adds" body text is styled Heading 1 and has a page break before it (layout).**
- Location: At a Glance, paragraph [22]. PDF pages 2-3.
- Text: "The Emphysema Severity Index (ESI), derived from the expiratory portion of the spirometric flow-volume curve, recovered part of the information lost…"
- Problem: The paragraph has style Heading 1 (with run-level overrides to 11 pt, not bold, so it looks like body text) and `page_break_before = True`. The subheading "What This Study Adds to the Field" is therefore left alone at the bottom of page 2, and page 3 holds only this paragraph. Word will also list the whole paragraph as a level-1 heading in the navigation pane and outline, and in any tagged PDF.
- Fix: Set the paragraph to Normal and remove its page break. ABSTRACT [23] already has its own page break.

**A2. Missing article.**
- Location: Results, Agreement, [60].
- Text: "For COPD-minor group, sensitivity was 88.7% and 89.4%…"
- Fix: "For the COPD-minor group, …" (this matches "For the noCOPD group" in the previous sentence).

**A3. Crapo's name differs between the byline and the disclosures.**
- Location: byline [1] "James Crapo⁶"; Author disclosures [17] "…Enrico Maiorino, and James D. Crapo report no conflicts of interest." The supplement byline also reads "James Crapo".
- Problem: The name is given in two forms. Every other author has the same form in both places.
- Fix: Use one form everywhere, presumably "James D. Crapo", in the manuscript byline and the supplement byline.

**A4. Grammar: a semicolon followed by "and".**
- Location: Results, Relationship of ESI to the visual CT criteria, [58].
- Text: "…from 1.04 in participants with no emphysema to 6.62 in those with advanced destructive emphysema; and it also increased across categories of visual airway wall thickening, from 0.96…"
- Fix: "…advanced destructive emphysema, and also increased across categories of visual airway wall thickening, from 0.96…" (or keep the semicolon and delete "and").

**A5. AUC is used in the Abstract without being defined.**
- Location: Abstract, Measurements and Main Results, [27].
- Text: "ESI discriminated visual emphysema and airway wall thickening with AUCs of 0.78 and 0.80."
- Problem: Every other Abstract abbreviation (CT, ESI, MD-COPD-CT, MD-NoCT, MD-COPD-ESI, AFL-only) is defined at first use. AUC is defined only in the main text [47].
- Fix: "…with areas under the receiver operating characteristic curve (AUCs) of 0.78 and 0.80." This adds about 7 words, which takes the Abstract from 248 to roughly 255 words. If the limit is 250, cut elsewhere, for example drop "high and" from "Overall agreement with MD-COPD-CT was high and modestly higher…".

---

## B. Style and consistency

**B1. FEV₁, FVC and FEV₁/FVC are never spelled out.**
- Location: first use in the Abstract [26] "FEV₁ decline"; first use in the main text [33] "longitudinal FEV₁ decline"; FEV₁/FVC first appears in [38].
- Problem: The brief asks for these to be defined at first use in the Abstract and again in the main text. They are not defined in either. (Some journals accept FEV₁ and FVC without definition. I have not checked AJRCCM's current list.)
- Fix: Abstract: "forced expiratory volume in 1 second (FEV₁) decline". Main text [33]: the same. Methods [38]: "post-bronchodilator FEV₁/forced vital capacity (FVC) <0.70".

**B2. CI is used before it is defined.**
- Location: Methods [47] "summarized by its mean and 95% CI (paired t-test)". The definition comes later, in [53] "95% confidence intervals (CIs)". The Abstract uses "95% CI" undefined [27].
- Fix: In [47] write "95% confidence interval (CI)". In [53] change to "Estimates are reported with 95% CIs in square brackets." The Abstract usage is conventional and can stay, or can be spelled out once.

**B3. TORCH is not expanded.**
- Location: Methods [45] "adjudicated using modified TORCH criteria (21)… (TORCH group 1)".
- Fix: Expand at first use, "Towards a Revolution in COPD Health (TORCH)", or leave as a trial name if the journal allows it. This was one of the abbreviations on the brief's checklist.

**B4. Spacing after ≥ and < is inconsistent.**
- Table 1, MD-COPD-ESI row: "ESI ≥ 1.50". Results [57] and Table S2 legend: "ESI ≥1.50".
- Table 1 legend [108]: "FEV₁/FVC < 0.70". Methods [38] and the Table 1 body: "FEV₁/FVC <0.70".
- Everywhere else the text has no space after the symbol ("≥2", "≥10 pack-years", "≥25"). P values do have a space ("P < 0.005"), which is consistent among themselves.
- Fix: Table 1 "ESI ≥1.50". Table 1 legend "FEV₁/FVC <0.70".

**B5. "AUC =" and "AUC" appear in the same sentence.**
- Location: Results [58]: "(AUC = 0.75 for both criteria) than among those without airflow limitation (AUC 0.56 and 0.61, respectively)". The Discussion [71] uses "AUC 0.75".
- Fix: "(AUC 0.75 for both criteria)".

**B6. Table 1 row labels do not match each other.**
- Rows read "MD-COPD-CT", "MD-NoCT classification" and "MD-COPD-ESI classification".
- Fix: "MD-NoCT" and "MD-COPD-ESI", matching "MD-COPD-CT" and the rest of the paper.

**B7. Table 1: "(≥3)" and "(≥2)" in the Diagnostic criteria column are not explained.**
- Problem: The legend does not say that the number is the minimum count of minor criteria for COPD-minor in participants without airflow limitation.
- Fix: Add to the legend: "Numbers in parentheses are the minimum number of minor criteria required for COPD-minor in participants without airflow limitation; with airflow limitation, ≥1 minor criterion defines COPD-major."

**B8. Figure 3 legend lists the classifications in a different order from the figure.**
- Legend [116]: "…under MD-COPD-CT, MD-NoCT, and MD-COPD-ESI." The figure rows run MD-COPD-CT, MD-COPD-ESI, MD-NoCT in every panel.
- Fix: Change the legend order to "MD-COPD-CT, MD-COPD-ESI, and MD-NoCT", or reorder the figure.

**B9. Figure 2B/C and Table S3 orient the same counts in opposite directions.**
- Figure 2 legend [114]: "Rows indicate MD-COPD-CT categories and columns the categories assigned by the modified classification". The figure does this (noCOPD row: 3,892 / 0 / 465 / 0).
- Table S3 legend: "Rows indicate the category assigned by each modified classification and columns the corresponding MD-COPD-CT category" (MD-NoCT noCOPD row: 3,892 / 0 / 90 / 0).
- Each legend correctly describes its own display. A reader comparing the two will find the off-diagonal cells transposed (465 against 90).
- Fix: Optional. Transpose Table S3 to match Figure 2, or add a note.

**B10. P values for differences in PPV are given only for AFL-only.**
- Location: Results [60]. Only AFL-only has a P value: "24.8% and 35.5%, respectively (P < 0.005)". Table S3 reports significant paired-bootstrap differences in PPV for all four categories (noCOPD P = 0.022; COPD-minor P < 0.005; COPD-major P < 0.005).
- Problem: Readers may take the noCOPD, COPD-minor and COPD-major PPV differences as non-significant, because the text gives a P value only for AFL-only.
- Fix: Add P values, for example "positive predictive value 97.7% and 97.8%, respectively (P = 0.022)", or add after the AFL-only sentence: "PPV differed between the modified classifications in all four categories (Table S3)."

**B11. Follow-up median for lung function decline: the denominator is not stated.**
- Location: Results [62] "9.7 years for lung function decline".
- Check: `followup_medians.csv` gives 9.68 years for the 5,414 participants with a follow-up visit, and 5.08 years for all 9,240 in the decline data. The other three medians are for the full analytic samples (8,769, 8,769 and 8,177).
- Fix: "9.7 years among the 5,414 participants with follow-up spirometry". Also use "FEV₁ decline" rather than "lung function decline", which is the term used everywhere else.

**B12. "Respiratory deaths were too few" applies to only two of the three AFL-only groups.**
- Location: Results [63]: "Respiratory deaths were too few for statistical comparison; rates were 0.39 per 100 person-years for MD-NoCT AFL-only and 0.09 for both MD-COPD-CT and MD-COPD-ESI AFL-only."
- Check: The event counts are 34 (MD-NoCT), 2 (MD-COPD-CT) and 4 (MD-COPD-ESI). The rates in the text match `consensus_ref_crude.csv`. Figure 3 shows a CI for MD-NoCT AFL-only respiratory mortality (8.07 [4.22-16.28]).
- Fix: "Respiratory deaths in MD-COPD-CT and MD-COPD-ESI AFL-only (2 and 4) were too few for statistical comparison; …"

**B13. Affiliation 7 spells out the state name.**
- Location: [9] "Birmingham, Alabama, USA". Affiliations 1-6 use postal abbreviations ("Boston, MA", "Denver, CO").
- Fix: "Birmingham, AL, USA".

**B14. Straight and curly quotation marks are mixed.**
- Most apostrophes are straight (Women's, George's, Cohen's, McNemar's, Fisher's). The Table 1 legend has a curly one, "St. George’s Respiratory Questionnaire".
- The Discussion [70] has curly double quotes ("low-risk", "higher-risk"). Reference 23 has straight ones ("kink").
- Fix: Pick one style and apply it everywhere. Word's AutoFormat "straight quotes with smart quotes" will make everything curly.

**B15. Reference 25 has an unabbreviated journal name and a zero-padded page range.**
- Text: "EC Pulmonology and Respiratory Medicine. 2025;14(3):01-09."
- Fix: "EC Pulmonol Respir Med. 2025;14(3):1-9." All other references use abbreviated journal names.

**B16. Title page and layout items for journal submission (check against AJRCCM instructions).**
- The docx has no footer, so it has no page numbers, and line numbering is off. Line numbers would also help co-authors comment.
- The title page has no corresponding author block (address, email), running head, author contributions statement, or subject category. The main-text word count is at the end of the Discussion ("(Word count 3354)"), not on the title page.
- I believe AJRCCM asks for these, but I have not checked the current instructions. Some may be planned for a later stage.

---

## C. Optional polish

**C1. At a Glance subheadings are plain body text.**
"Scientific Knowledge on the Subject" [19] and "What This Study Adds to the Field" [21] are Normal and not bold, so they are hard to tell from the body text (PDF page 2). Consider bold or italic.

**C2. Two parentheticals in a row.**
- [58] "(AUC 0.56 and 0.61, respectively) (Figure 1)" → "(AUC 0.56 and 0.61, respectively; Figure 1)".
- [63] "(1.14 [0.92-1.50] and 0.96 [0.79-1.22], respectively; both P > 0.2) (Table S4)" → "…both P > 0.2; Table S4)".

**C3. [58] The second sentence repeats the first.**
"ESI increased across increasing severity categories of both visual emphysema and airway wall thickening, although the magnitude of the increase was greater across emphysema severity categories (Figure 1)." The previous sentence already says ESI increased across both. Suggest: "The increase was larger across emphysema severity categories (Figure 1)."

**C4. [58] "subjects".**
"…better in subjects with airflow limitation…" → "participants", the term used elsewhere.

**C5. [60] Awkward sentence opening.**
"Both of these results reflect that, in the absence of available CT criteria, the MD-NoCT classification could not identify…" Suggest: "Both results arise because, without CT criteria, MD-NoCT could not identify participants whose only minor criteria were CT findings; it therefore reassigned 833…"

**C6. [74] "which" has an unclear antecedent.**
"…it is fairly insensitive to bronchodilation (25), which, in the context of COPD diagnostic tools, is a source of undesirable measurement variability (26)." As written, "which" can be read as referring to the insensitivity. Suggest: "…insensitive to bronchodilation (25), whereas bronchodilator responsiveness is a source of undesirable measurement variability in COPD diagnosis (26)."

**C7. [36] The exclusion list is not parallel.**
"Participants with diagnosed interstitial lung disease or bronchiectasis, never-smokers, or without acceptable post-bronchodilator spirometry or CT passing quality control were excluded." Suggest: "Never-smokers and participants with diagnosed interstitial lung disease or bronchiectasis, without acceptable post-bronchodilator spirometry, or without a CT scan passing quality control were excluded."

**C8. [56] "GOLD 0" right after "formerly referred to as GOLD grade 0".**
The cohort sentence calls this group "preserved spirometry (formerly … GOLD grade 0)", and the next sentence says "from 0.90 in GOLD 0". Consider "from 0.90 in participants with preserved spirometry", or leave as is because Table S1 uses "GOLD 0".

**C9. Figure 1 legend defines AUC twice.**
It is defined inline ("area under the receiver operating characteristic curve (AUC)") and again in the abbreviation list at the end. Drop the second.

**C10. Figure 4 legend: informal phrasing.**
"for the three groups either classification calls COPD" → "for the three groups classified as COPD by either classification".

**C11. Figure 3 legend does not state how the CIs were computed.**
The Figure 4 legend and the Table S4 legend both do ("exact Poisson intervals for deaths and participant-level bootstrap intervals for exacerbations"). Consider adding the same sentence to Figure 3.

**C12. [73] Informal wording.**
"Even the MD-COPD-ESI AFL-only group, which otherwise performed quite well, …" Consider "The MD-COPD-ESI AFL-only group, which otherwise closely matched MD-COPD-CT, nonetheless had faster FEV₁ decline…"

**C13. Disclosure spellings (author-supplied text, so confirm with each author rather than edit).**
"MedScape" (the brand is "Medscape"), "HIKMA" (the brand is "Hikma"). "GlaxoSmithKline" (Lavorini, funding statement) and "GSK" (Silverman, Bhatt) both appear.

**C14. Document metadata.**
`docProps/core.xml` gives the creator as "python-docx" and the description as "generated by python-docx", and the title is empty. Co-authors will see this under File > Properties. Consider setting the author and title before sending.

---

## What I checked and found correct

- **Dashes:** No em dashes (U+2014) or en dashes (U+2013) anywhere in the document XML: body, tables, legends or references. Ranges use a hyphen. Negatives use the true minus sign (−0.09, −950). The bronchodilator CI "[95% CI −0.11 to −0.08]" uses "to", which avoids a hyphen next to minus signs. That is reasonable, and Table S6/S7 do the same.
- **Other characters:** No doubled words, double spaces, replacement characters or zero-width characters. FEV₁ uses the Unicode subscript character in all 10 occurrences, and it renders as a subscript in the PDF.
- **Classification and category names:** MD-COPD-CT, MD-NoCT and MD-COPD-ESI are used consistently in the text, legends and figures. So are noCOPD, AFL-only, COPD-minor and COPD-major, and CT-only, ESI-only and Both-COPD.
- **Unadjusted vs crude:** "crude" does not appear; "unadjusted" is used throughout. CIs are in square brackets throughout. "P < 0.005", "P > 0.2", "P = 0.006" and "P = 0.074" are spaced consistently.
- **Abbreviations defined at first use:** ESI, CT, AFL-only, MD-COPD-CT and the other classification names are defined in the Abstract and the main text. AUC is defined in the main text [47]. PRISm and GOLD are defined in [56], mMRC and SGRQ in [38], %LAA-950HU in [39], PEF in [41], and HR and IRR in [50].
- **Cohort numbers:**
  - 9,240 total; 8,769 + 469 + 2 = 9,240.
  - GOLD and PRISm counts sum to 9,240. PRISm + GOLD 0 = 5,156 and GOLD 1-4 = 4,084, which match the fixed-ratio row of Table 1.
  - All Table 1 rows sum to 9,240.
  - Common reference 3,856 / 3,625 / 3,411 matches `discord_rates.csv`. It equals the MD-COPD-ESI × MD-COPD-CT noCOPD concordant cell, which is consistent with "noCOPD by all three".
- **Agreement:** 8,222/9,240 = 89.0% and 7,852/9,240 = 85.0% (`crossclass.csv`). All sensitivities and PPVs in [60] match `agreement_by_group.csv`. 833/3,809 = 21.9% and 350/3,809 = 9.2%. 1,108 / 275 ≈ 4.0, which supports "four times the size". 483/833 = 58% of CT-dependent COPD-major were retained, which supports "more than half".
- **AUCs:** 0.78 / 0.80 overall, 0.75 / 0.75 with airflow limitation and 0.56 / 0.61 without, all match `esi_ct_auc.csv`. These figures agree in the Abstract, Results, Discussion and the Figure 1 insets.
- **Mean ESI by visual category:** 1.04, 6.62, 0.96 and 3.32 match `esi_ct_levels.csv`. Emphysema-category n values sum to 9,236, which matches the Figure 1 legend.
- **Other ESI numbers:** ESI by GOLD (0.90 in GOLD 0, 8.30 in GOLD 4) matches `supp_baseline.csv`. The bronchodilator change of −0.09 [−0.11 to −0.08] matches the value recomputed from `bronchodilator_delta_esi.csv` (mean −0.0918, SD 0.818, n = 9,234).
- **Rate ratios versus MD-COPD-CT** (Abstract and Results) all match `group_vs_mdcopd.csv`, including the P values:
  - unadjusted 1.38 [1.11-1.80], 1.42 [1.16-1.82], 1.14 [0.92-1.50], 0.96 [0.79-1.22];
  - adjusted 1.33 [1.09-1.71] P = 0.006, 1.22 [0.98-1.58] P = 0.074, 1.03 [0.82-1.35], 0.92 [0.75-1.18].
- **Respiratory mortality rates:** 0.39 / 0.09 / 0.09 match `consensus_ref_crude.csv`.
- **Follow-up medians:** 11.2, 8.6 and 10.4 years match `followup_medians.csv`. For 9.7 years, see B11.
- **FEV₁ decline statements** in [64] and [73] match the pattern in `fev1_decline.csv` and `fev1_decline_random_slope.csv`. COPD-major is significant under all three classifications. COPD-minor is significant only under MD-COPD-CT. AFL-only is significant under MD-NoCT and MD-COPD-ESI only. Random slopes give the same pattern, with larger COPD-major estimates.
- **Discordant groups:** the n values in the Figure S2 legend (714/85/501; 3,459/350/82) match `crossclass.csv`. The direction of the Figure 4 results matches the text in [66].
- **References:** Citations are numbered in order of first appearance, 1-26. Every listed reference is cited and every cited number exists. Author lists are truncated after six with "et al."; references with six or fewer authors list all of them. Year;volume(issue):pages format is used with hyphen ranges. The bibliographic details of the classic references (Burrows 1966, Snider 1989, Celli 2004, Macklem 1967, Saltzman 1976, Albert 2012, Lynch 2015/2018, Regan 2010) match the details as I know them.
- **Callouts:**
  - Table 1 and Figures 1-4 are called out in order.
  - Supplement callouts appear in order: S1, S2, S3, S4, S5, Figure S1, S6, S7, S8, Figure S2.
  - Each points to the right content: S1 baseline by spirometric category; S2 thresholds; S3 cross-classification; S4 unadjusted; S5 adjusted; S6 FEV₁ decline; S7 random slopes; S8 discordant outcomes; Figure S1 unadjusted and adjusted; Figure S2 discordant characteristics.
- **Figures:**
  - Figure 1 has dashed thresholds at mild/trace and definite/borderline. The insets match the CSV and n labels are present.
  - Figure 2 has the Sankey diagram with CT in the center. The panel B/C counts match `crossclass.csv`, and the colors match the legend.
  - In Figure 3, the respiratory mortality estimates for MD-COPD-CT and MD-COPD-ESI AFL-only and for all COPD-minor groups are shown without CIs, which matches the <10-event flags. The log axes differ by column, as the legend states.
  - In Figure 4, the top row is without airflow limitation and the bottom row with it, as the legend states.
  - All four figures are legible at page width, and none is cut off.
- **Layout:** Abstract and Introduction each start a new page. Table 1 fits on one page with its legend. Each figure sits with its legend on its own page. Supported by, Data availability and Author disclosures are all present on the title page. Apart from A1, there are no orphaned headings.
- **Word counts:** The Abstract is 248 words including section labels (240 without). The main text from Introduction through Discussion, including headings, is 3,354 words. Both match the stated counts. At a Glance is 187 words.
