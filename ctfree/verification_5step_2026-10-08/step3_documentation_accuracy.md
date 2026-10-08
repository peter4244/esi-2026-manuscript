# Step 3: Documentation accuracy (CT-free MD-COPD v5)

Date: 2026-10-08. Sources read: `ctfree/manuscript/CT-free MD-COPD manuscript draft v5.docx` and `... supplement draft v5.docx` (all paragraphs and tables, via python-docx), all six figure PNGs, `ctfree/figures/*_legend.md`, and aggregate CSVs in `ctfree/assets/` (`esi_ct_auc`, `esi_ct_levels`, `discord_profile*`, `discord_rates*`, `followup_medians`, `bronchodilator_delta_esi`, `cohort_flow`). I opened no participant-level data and edited no file other than this one. Wording below is suggested only.

Known and decided, noted only: bootstrap CIs vary at Monte Carlo level. Pete keeps "symptom criteria were more frequent in the MD-COPD-ESI-only group" even though chronic bronchitis goes the other way. H1 below raises a separate point about the same sentence.

---

## HIGH

### H1. Figure S2 and Results: differences fixed by the classification rules are tested and reported as findings, and the legend says this is not done

**Text (Results, last paragraph):** "Among participants with airflow limitation, ESI was higher and visual emphysema less frequent in the MD-COPD-ESI-only group, whereas %LAA-950HU did not differ significantly between the discordant groups (Figure S2)."
**Legend (Figure S2):** "Comparisons fixed by the classification definitions are shown without statistical testing."

**What the rules force (from the Methods definitions).** In the airflow-limitation stratum:
- ESI-only = MD-COPD-CT AFL-only (none of the 5 minor criteria) and MD-COPD-ESI COPD-major (at least 1 of 4). They have no symptom criteria, so they must have ESI ≥ 1.50, and visual emphysema and definite wall thickening must both be 0%.
- CT-only = MD-COPD-CT COPD-major and MD-COPD-ESI AFL-only. They have no symptom criteria and ESI < 1.50, so they must have at least one CT criterion.

So in this stratum the ESI difference, the visual-emphysema difference and the wall-thickening difference are all fixed by definition. `discord_profile_afl.csv` agrees: ESI-only has pct_meets_esi = 100 and visual emphysema and wall thickening = 0; CT-only has pct_meets_esi = 0. Figure S2 still marks all three CT-only vs ESI-only brackets with ***. Their p-values in `discord_profile_tests.csv` are 3.7e-45, 1.2e-43 and 2.0e-20. Only the three symptom panels were left untested.

Without airflow limitation, CT-only means CT COPD-minor (≥3 of 5) with ESI noCOPD (<2 of 4). Outside the CAD/CHF rule, that forces both CT criteria, at most one symptom criterion, and ESI < 1.50. `discord_profile.csv` matches: visual emphysema 100%, wall thickening 100%, ESI SD 0.20. The *** on the emphysema and wall-thickening panels in this stratum therefore compare a by-construction 100% with an observed value. The symptom comparison here is also largely driven by the rules.

Within the two discordant groups, the only CT comparisons not set by the rules are %LAA-950HU in both strata. Without airflow limitation it differed (P = 0.001, `**`); see M8. With airflow limitation it did not (P = 0.53).

**Suggested:** Remove the significance brackets from the comparisons fixed by definition: in the airflow-limitation row, ESI, visual emphysema and wall thickening; in the row without airflow limitation, visual emphysema and wall thickening. Keep the legend sentence, which then becomes true. Rewrite the Results sentence along these lines: "By definition, the MD-COPD-ESI-only group with airflow limitation met the ESI criterion and no CT criterion. %LAA-950HU did not differ significantly between the two discordant groups (4.8% vs 4.1%; Figure S2)."

### H2. "beyond conventional spirometric indices" is not tested, and the unreported comparison does not favour ESI

**Text:**
- At a Glance: "These findings suggest that the expiratory flow-volume curve contains clinically relevant physiological information related to the structural dimension of COPD beyond conventional spirometric indices."
- Discussion, conclusion paragraph: "...contains clinically relevant physiological information about the structural dimension of COPD beyond conventional spirometric indices."

No analysis in the paper compares ESI with a conventional spirometric index. `esi_ct_auc.csv` already holds FEV₁/FVC AUCs for the same visual CT criteria. FEV₁/FVC is equal to or better than ESI in every cell:

| stratum | criterion | AUC ESI | AUC FEV₁/FVC |
|---|---|---|---|
| All participants | emphysema | 0.78 | 0.82 |
| All participants | wall thickening | 0.80 | 0.82 |
| Airflow limitation | emphysema | 0.75 | 0.78 |
| Airflow limitation | wall thickening | 0.75 | 0.75 |
| No airflow limitation | emphysema | 0.56 | 0.67 |
| No airflow limitation | wall thickening | 0.61 | 0.64 |

The classification results do not test this question either. MD-NoCT is not a "conventional index replacing CT" comparator; it simply drops the CT criteria. A reviewer with access to these numbers could rebut the claim directly.

**Suggested:** Delete "beyond conventional spirometric indices" in both places, or replace it with "that can partly stand in for the CT criteria within this framework". Separately, decide whether the FEV₁/FVC AUCs should be reported.

---

## MODERATE

### M1. The agreement gain is confined to participants with airflow limitation, not "concentrated" there

**Text:**
- Abstract: "This difference was concentrated among participants with airflow limitation."
- At a Glance: "This effect was most evident in participants with airflow limitation."
- Abstract Conclusions: "ESI recovers part of the information ... particularly among participants with airflow limitation ..."

From Table S3 and Figure 2, within each stratum:

| stratum | MD-NoCT agreement | MD-COPD-ESI agreement |
|---|---|---|
| Without airflow limitation (n = 5,156) | 4,601 (89.2%) | 4,570 (88.6%) |
| With airflow limitation (n = 4,084) | 3,251 (79.6%) | 3,652 (89.4%) |

The whole overall gain comes from the airflow-limitation stratum. Without airflow limitation, MD-COPD-ESI agrees slightly less well than MD-NoCT. For COPD-minor outcomes, MD-COPD-ESI and MD-NoCT also perform the same (Table S4: 0.88 vs 0.87 for mortality and 0.89 vs 0.90 for exacerbations versus MD-COPD-CT). The Discussion phrase "less effective in reproducing the CT-based classification among individuals without airflow limitation" is accurate, but it does not say that ESI was no better than no replacement there.

**Suggested:**
- Abstract: "This difference arose entirely among participants with airflow limitation."
- At a Glance: "This effect was confined to participants with airflow limitation."
- Discussion: add "...where it did not improve on MD-NoCT."

### M2. Discussion: "eliminated the primary diagnostic benefit of the AFL-only pathway" goes beyond the data

**Text:** "This transfer raised event rates in AFL-only and eliminated the primary diagnostic benefit of the AFL-only pathway, which is to remove the COPD diagnosis from individuals ... at relatively low risk."

MD-NoCT AFL-only remains low-risk relative to the COPD groups:
- Unadjusted all-cause mortality rate ratio versus the common reference is 1.52, against 4.05 for MD-NoCT COPD-major (Table S4).
- The adjusted HR versus the common reference is 1.11 [0.95–1.29], which is not elevated (Table S5).
- The adjusted MD-NoCT versus MD-COPD-CT contrast for mortality is not significant (1.22, P = 0.098).

"Diluted" or "weakened" is supported. "Eliminated" is not.

**Suggested:** "...raised unadjusted event rates in AFL-only and weakened the main diagnostic benefit of the AFL-only pathway..."

### M3. The Discussion states COPD-minor results that are not in Results, and omits the adjusted and MD-NoCT context

**Text (Discussion):** "For the COPD-minor pathway, while MD-COPD-ESI did identify participants with higher risks of mortality and exacerbations relative to the noCOPD group, these unadjusted rates were lower than in MD-COPD-CT COPD-minor."

The Results never report the COPD-minor or COPD-major contrasts versus MD-COPD-CT from Tables S4 and S5. Table S4 does show the unadjusted COPD-minor ratios for MD-COPD-ESI: 0.88, P = 0.008, and 0.89, P = 0.016. However:
- (a) The adjusted ratios are not significant: 0.94, P = 0.20, and 0.92, P = 0.096 (Table S5).
- (b) MD-NoCT COPD-minor is lowered by the same amount (0.87 and 0.90), so ESI is no better than removing CT for this pathway.
- (c) MD-COPD-ESI COPD-major differs significantly from MD-COPD-CT for every outcome (unadjusted 1.05–1.09 and adjusted 1.07–1.08, all P < 0.005). The Results report significance only for AFL-only.

The Results claim "Differences among classifications were most apparent in AFL-only" is defensible on magnitude, but the significant contrasts in the other groups go unmentioned.

**Suggested:** Add one sentence to Results, for example: "In COPD-minor, unadjusted mortality and exacerbation rates were modestly lower under both modified classifications than under MD-COPD-CT (rate ratios 0.87–0.90), and these differences were not significant after adjustment. In COPD-major, both modified classifications had modestly higher rates than MD-COPD-CT (Tables S4 and S5)." In the Discussion, add "...as were those of MD-NoCT COPD-minor, and the difference was not significant after adjustment."

### M4. The Methods do not describe how the ESI cut-point was selected, and Table S2 does not show the count rules for ESI

**Methods:** "the number of minor criteria required for COPD diagnosis was derived from concordance with MD-COPD-CT..."
**Results:** "...ESI ≥1.50 for the ESI criterion in MD-COPD-ESI (Table S2)."

Table S2 varies the ESI cut-point from 0.75 to 4.00. It does not say that those rows all use ≥2 of 4 criteria, and it shows no alternative count rule (≥1, ≥3 or ≥4 of 4) for MD-COPD-ESI. The ≥2 of 4 rule appears only in the footnote, as the selected rule. The Methods never say the ESI cut-point was a tuned parameter. It is also unclear whether the metrics in Table S2 are full-cohort or cross-validated values.

**Suggested:**
- Methods: "For MD-COPD-ESI, the ESI cut-point defining the ESI criterion and the number of minor criteria were selected in the same way."
- Table S2: label the ESI rows "≥2 of 4 criteria; ESI ≥x". State whether other counts were evaluated, and state that the metrics are from the full cohort.

### M5. The median follow-up for FEV₁ decline is for a subset that is not named

**Text:** "Median follow-up was 10.8 years for mortality, 10.4 years for exacerbations, and 9.7 years for lung function decline."

`followup_medians.csv`: the 9.68-year figure is for the 5,414 participants with a follow-up visit. Across all 9,240 in the decline data, the median is 5.1 years (IQR 0–9.9). Table S6 lists full classification group sizes (275, 799, ...) as n, so a reader would assume the 9.7 years applies to all of them.

**Suggested:** "...and 9.7 years for lung function decline among the 5,414 participants with at least one follow-up spirometry." Either label the Table S6 n column "n (all participants in model)" or add the number with follow-up.

### M6. "Common reference of 3,856 participants" is stated for exacerbations too, but the exacerbation reference is smaller

The Figure 3, Figure S1, Table S4 and Table S5 legends all give the reference as "the 3,856 participants classified as noCOPD by all three classifications". In `discord_rates.csv` the same group has n_exac = 3,411, consistent with the 8,177-participant exacerbation population given in the Methods. For mortality the reference is 3,856. The n column in Table S7 also gives classification counts, not exacerbation-analysis counts. For example, Both-AFL-only is 193 for mortality and 181 for exacerbations.

**Suggested:** "...the 3,856 participants (3,411 in exacerbation analyses) classified as noCOPD by all three classifications." Add a matching footnote to Table S7.

### M7. Results omit the one CT difference without airflow limitation that the rules do not fix

Figure S2 shows %LAA-950HU higher in CT-only than in ESI-only without airflow limitation (1.91% vs 1.24%, P = 0.001, `**`). The Results sentence for this stratum covers ESI, the visual criteria and symptoms, but not %LAA-950HU. It is the only quantitative-CT difference in that stratum, and it runs against ESI (ESI-only had less emphysema).

**Suggested:** Add "...and %LAA-950HU was higher in the MD-COPD-CT-only group".

### M8. Discussion attributes the stratum difference to ESI discrimination, but the rule structure also differs between strata (this is my inference)

**Text:** "Because ESI better discriminated the CT criteria in individuals with airflow limitation, its advantages over the MD-NoCT classification derive primarily from the characteristics of the AFL-only diagnostic pathway..."

This is causal language. The pathways differ structurally: with airflow limitation any single criterion suffices, whereas without it the count threshold changes from ≥3 of 5 to ≥2 of 4.

Without airflow limitation, the ESI-only group had mean ESI 0.97 (SD 0.64), below the 1.50 cut-point. In Figure S2 the group shows mMRC ≥2 in 84% and SGRQ ≥25 in 94%. I think this means most of these participants reached COPD-minor through two symptom criteria under the lower count threshold, not through ESI. This is inference from means and percentages; I have no per-participant count.

**Suggested:** "Consistent with its better discrimination of the CT criteria in individuals with airflow limitation, its advantages..." Consider also stating that, without airflow limitation, discordance mostly reflects the change in the required number of criteria.

### M9. The Abstract gives only unadjusted AFL-only contrasts

The Abstract results labels them "unadjusted" correctly. It does not mention that after adjustment the MD-NoCT versus MD-COPD-CT mortality difference was not significant (1.22 [0.97–1.55], P = 0.098). Only the exacerbation difference stayed significant (1.33, P = 0.008). The Abstract Conclusions rest partly on this contrast.

**Suggested (if words allow):** "...after adjustment, the exacerbation difference persisted (ratio of IRRs 1.33 [1.07–1.70])."

---

## LOW

- **L1. Results, Figure 1 paragraph:** "than among those without airflow (AUC 0.56 and 0.61, respectively)". The word "limitation" is missing.
- **L2. Figure 2:** Panel A has no colour key or category labels, so a reader can map colours only from the diagonals in B and C. Panels B and C label categories "minor" and "major", which the legend does not define. Suggested: add a category key to A, or add to the legend "grey, noCOPD; purple, AFL-only; orange, COPD-minor; red, COPD-major; minor/major = COPD-minor/COPD-major".
- **L3. Figure S1 x-axis:** "Rate ratio or hazard ratio versus the common noCOPD reference" leaves out the IRR shown for exacerbations. Suggested: "Rate ratio, HR or IRR versus...".
- **L4. Figure S2 panels:**
  - The "Wall thick." abbreviation is undefined.
  - The shared y-label "Mean" covers ESI (unitless) and %LAA-950HU (%).
  - "Emphysema (visual)" does not say "mild or greater".
  - Suggested legend addition: "Wall thick. = definite airway wall thickening; visual emphysema = mild or greater".
- **L5. Discordant-group names vary:**
  - Table S7: "CT-only-COPD / ESI-only-COPD / Both-AFL-only"
  - Figure 4 and Figure S2: "CT-only / ESI-only"
  - Results: "MD-COPD-CT-only group" and "MD-COPD-ESI-only group"

  Each version is defined where it appears, but one form throughout would be cleaner.
- **L6. AFL-only gloss varies:**
  - Legends: "airflow limitation without other criteria"
  - Abstract: "without additional diagnostic criteria"
  - Introduction: "no other diagnostic criteria"
  - Abstract Conclusions: "lacking other diagnostic criteria"

  "MD-NoCT classification" and "MD-NoCT" are also used interchangeably. This is minor; consider one form.
- **L7. Table S6:**
  - The header "Difference in decline versus the common reference" uses a sign convention where a negative value means faster decline. "Difference in annual FEV₁ change" would match the footnote.
  - The footnote says "corresponding MD-NoCT and ESI groups". Suggested: "MD-COPD-ESI groups".
  - The Methods say baseline FEV₁ was a covariate, but omit the interaction with time that the footnote states.
- **L8. FEV₁ comparisons:**
  - The Results say "Longitudinal FEV₁ decline differed across diagnostic pathways", but no test across pathways was done.
  - The one pre-specified contrast (MD-NoCT minus MD-COPD-ESI, all P = 0.68–0.91) is not reported in the Results.
  - The Discussion contrasts MD-COPD-ESI AFL-only (−4.3, P = 0.012) with MD-COPD-CT AFL-only (−2.7, P = 0.22, "did not"). Those two groups were never compared directly, and their CIs overlap.

  Suggested: report the null MD-NoCT–MD-COPD-ESI contrasts, and soften to "was significant versus the reference only for...".
- **L9. Bronchodilator ESI change:** the Results give mean −0.09 [−0.11 to −0.08], but no table or figure is cited and no n is given. `bronchodilator_delta_esi.csv` gives n = 9,234 paired and SD 0.82. Add "(n = 9,234)" or "(data not shown)".
- **L10. Table 1:**
  - Fixed-ratio COPD (4,084) sits in the "COPD-major" column, which reads as though fixed-ratio COPD were COPD-major. A spanning note or a separate "COPD" label would help.
  - The "(≥3)" and "(≥2)" in the Diagnostic criteria column apply only to the COPD-minor pathway, and nothing explains them.
  - The criteria column for the MD-COPD-* rows leaves out the FEV₁/FVC major criterion.
  - The column uses "dyspnea" without giving mMRC ≥2.

  Suggested footnote: "Numbers in parentheses are the minor criteria required for COPD-minor; COPD-major requires FEV₁/FVC <0.70 and ≥1 minor criterion."
- **L11. Abstract AUCs:** The Abstract says "airway wall thickening", where "definite" would match the criterion. It gives only the overall AUCs (0.78 and 0.80), not the 0.56 and 0.61 in participants without airflow limitation, which is where the CT criteria drive COPD-minor. Consider adding them if space allows.
- **L12. Figure 3 legend:** it does not give the CI method (exact Poisson for deaths, bootstrap for exacerbations), which the Figure 4 legend and Table S4 do. Add one clause.
- **L13. Table S7:** it has a "Deaths" column but no exacerbation-event or person-year column, so the exacerbation ratios cannot be traced from the table. This is minor.

---

## Checked and found accurate

- **Table 1:** all rows sum to 9,240. AFL-only + COPD-major = 4,084 under all three classifications, matching the fixed-ratio count and GOLD 1–4 in Table S1. The footnote's CAD/CHF rule matches the Methods.
- **Table S1:** strata sum to 9,240. The Results text "0.90 in GOLD 0 to 8.30 in GOLD 4" matches, and ESI is monotone across GOLD 0–4.
- **Table S2:** the selected rules have the highest macro-F1 (0.732 and 0.763). The footnote's metric definitions match the Methods. The cross-validated agreement (88.9% and 85.0%) is consistent with the Methods.
- **Table S3 and the Agreement paragraph:**
  - Every sensitivity and PPV quoted in the Results matches Table S3.
  - 833/3,809 = 21.9% and 350/3,809 = 9.2%.
  - Overall agreement of 8,222 and 7,852 matches the diagonals.
  - The Figure 2 B/C counts match Table S3, which is the transpose; both legends describe their row and column orientation correctly.
  - The AFL-only PPV P < 0.005 matches the footnote.
- **Figure 1:**
  - The points match `esi_ct_levels.csv` (none 1.04, advanced destructive 6.62, absent 0.96, definite 3.32).
  - The n labels sum to 9,236 in each panel, consistent with the legend and the supplement's n = 4 missing.
  - The inset AUCs match `esi_ct_auc.csv` and the Results text.
  - The dashed thresholds sit at mild and at definite.
- **Figure 3:** the row and column layout, the log axis that differs by column, the omitted CIs for <10 events (COPD-minor respiratory, AFL-only CT and ESI respiratory) and the point estimates all match Table S4.
- **Figure S1:** open circles are unadjusted and filled circles adjusted, as the legend says. Points match Tables S4 and S5. The covariate list matches the Methods and Table S5.
- **Clinical outcomes paragraph:** the AFL-only contrasts (1.38, 1.42, 1.14, 0.96; 1.22 with P = 0.098; 1.33 with P = 0.008; 1.03 and 0.92), the "both P < 0.005" and "both P > 0.2" statements, and the respiratory rates (0.30, 0.07, 0.07) all match Tables S4 and S5. "COPD-minor and COPD-major were associated with increased all-cause mortality and exacerbation risk ... higher in COPD-major" holds both unadjusted and adjusted.
- **FEV₁ paragraph:** the significance pattern by group matches Table S6.
- **Discordance paragraph and Figure 4:**
  - Without airflow limitation, both discordant groups are elevated.
  - With airflow limitation, neither discordant group differs significantly and Both-COPD is elevated.
  - Figure 4 points match Table S7, and the legend's reference groups, CI methods and row orientation are correct.
  - The Figure S2 group sizes in the legend match Table S7 and Table S3.
  - "ESI did not differ significantly" without airflow limitation matches the CSV (P = 0.13).
  - "%LAA-950HU did not differ" with airflow limitation matches the CSV (P = 0.53).
- **Discussion arithmetic:** 1,108 vs 275 is "four times". "More than half" kept from reassignment is correct: 483/833 = 58%, and the 350 are a subset of the 833 by construction. The AUCs quoted (0.75, 0.56, 0.61) are correct.
- **Methods and Supplement:** the reference-group definitions, the <10-events rule (Supplemental Methods, Table S4/S5 † footnote, figure legends), the bootstrap descriptions, the Wilcoxon and Fisher tests, and the cohort numbers (9,238 mortality, 8,177 exacerbation) are consistent with each other.
- **Wording:** "unadjusted" is used throughout; "crude" does not appear in either document. Every main-text Table S1–S7 and Figure S1–S2 pointer lands on content that supports its sentence. Each figure and table legend defines its abbreviations, apart from the items in L2 and L4.
