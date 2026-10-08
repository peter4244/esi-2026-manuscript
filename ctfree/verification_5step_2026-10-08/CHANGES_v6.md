# CHANGES v6: numbers updated to cluster job 6118470 (2026-10-08)

Branch `resp-mortality-cod-window`, not committed. Source of every new value: `ctfree/assets/*.csv` as now on disk; old values from `git show HEAD:ctfree/assets/<file>`. Only numbers were changed. Any wording change is listed under the proposals and has not been applied.

`Rscript ctfree/verify.R` result: **VERIFICATION PASSED: 249 claims, 0 failed** (54 failed before the edits).

## Numbers changed (applied)

### Manuscript sources

| file | location | old text | new text | source asset / field |
|---|---|---|---|---|
| ABSTRACT.md | Measurements and Main Results, last sentence | 1.38 [95% CI 1.10–1.77] | 1.38 [95% CI 1.11–1.80] | group_vs_mdcopd.csv S3 AFL-only crude all: lo 1.107, hi 1.797 |
| ABSTRACT.md | same | 1.42 [1.15–1.79] | 1.42 [1.16–1.82] | group_vs_mdcopd.csv S3 AFL-only crude exac: lo 1.159, hi 1.817 |
| ABSTRACT.md | same | 1.14 [0.91–1.44] | 1.14 [0.92–1.50] | group_vs_mdcopd.csv S4 AFL-only crude all: lo 0.915, hi 1.498 |
| ABSTRACT.md | same | 0.96 [0.78–1.21] | 0.96 [0.79–1.22] | group_vs_mdcopd.csv S4 AFL-only crude exac: lo 0.787, hi 1.222 |
| RESULTS.md | Clinical outcomes, para 1, sentence 1 | 10.8 years for mortality | 11.2 years for mortality | followup_medians.csv "all-cause mortality" median_yr 11.17 |
| RESULTS.md | Clinical outcomes, para 2, sentence 2 | 1.38 [1.10–1.77] | 1.38 [1.11–1.80] | as Abstract row 1 |
| RESULTS.md | same | 1.42 [1.15–1.79] | 1.42 [1.16–1.82] | as Abstract row 2 |
| RESULTS.md | same | 1.14 [0.91–1.44] | 1.14 [0.92–1.50] | as Abstract row 3 (P = 0.24, still "P > 0.2") |
| RESULTS.md | same | 0.96 [0.78–1.21] | 0.96 [0.79–1.22] | as Abstract row 4 (P = 0.776, still "P > 0.2") |
| RESULTS.md | Clinical outcomes, para 2, sentence 3 | ratio of IRRs 1.33 [1.07–1.70] | ratio of IRRs 1.33 [1.09–1.71] | group_vs_mdcopd.csv S3 AFL-only adjusted exac: lo 1.091, hi 1.706 |
| RESULTS.md | same | P = 0.008 | P = 0.006 | same row, p_boot 0.006 |
| RESULTS.md | same | ratio of HRs 1.22 [0.97–1.55] | ratio of HRs 1.22 [0.98–1.58] | group_vs_mdcopd.csv S3 AFL-only adjusted all: lo 0.981, hi 1.577 |
| RESULTS.md | same | P = 0.098 | P = 0.074 | same row, p_boot 0.074 (still not significant) |
| RESULTS.md | Clinical outcomes, para 2, sentence 4 | ratio of HRs 1.03 [0.82–1.31] | ratio of HRs 1.03 [0.82–1.35] | group_vs_mdcopd.csv S4 AFL-only adjusted all: hi 1.347 (P = 0.79) |
| RESULTS.md | same | ratio of IRRs 0.92 [0.73–1.17] | ratio of IRRs 0.92 [0.75–1.18] | group_vs_mdcopd.csv S4 AFL-only adjusted exac: lo 0.747, hi 1.185 (P = 0.498, still "P > 0.2") |
| RESULTS.md | Clinical outcomes, para 2, last sentence | 0.30 per 100 person-years for MD-NoCT AFL-only | 0.39 per 100 person-years for MD-NoCT AFL-only | consensus_ref_crude.csv S3 AFL-only resp rate_100py 0.387 |
| RESULTS.md | same | 0.07 for both MD-COPD-CT and MD-COPD-ESI | 0.09 for both MD-COPD-CT and MD-COPD-ESI | consensus_ref_crude.csv resp rate_100py S2 AFL-only 0.088, S4 AFL-only 0.092 (both round to 0.09, so "both" still holds) |
| METHODS.md | Study population, last sentence | Mortality analyses included 9,238 participants | Mortality analyses included 8,769 participants | followup_medians.csv / continuous_esi_mortality.csv n 8,769 |

Counts: ABSTRACT.md 8 numbers (4 intervals), RESULTS.md 20 numbers (1 follow-up median, 15 interval bounds across 8 intervals, 2 P values, 2 rates), METHODS.md 1. No number changed in AT_A_GLANCE.md, INTRODUCTION.md, DISCUSSION.md, the six figure legends, build_manuscript.py or build_supplement.py.

Checked and unchanged: every other number in the six text files and six legends (cohort 9,240, agreement 89.0%/85.0%, sensitivities and PPVs, 833/350, AUCs, 10.4 and 9.7 years, 8,177, 1,108/275, Figure 2 and S2 legend counts). The builders hard-code no result numbers; every table and table-legend number is read from assets, so these move on the next build without edits:
- Table S2 legend held-out agreement: 88.9% → 88.8% (schema_fit.csv S4 agreement_heldout 0.8883); MD-NoCT 85.0% unchanged.
- Table S3 legend PPV bootstrap P: noCOPD 0.012 → 0.022 (agreement_by_group.csv p_boot); the other three remain < 0.005.
- Tables 3, S4, S5, S7 cells: respiratory columns, all bootstrap intervals and P values.

### verify.R expected values (claim wording updated to match)

| claim id | old claim / expected | new claim / expected | computed |
|---|---|---|---|
| FU-01 | median follow-up 10.8 years for mortality; 10.8 | 11.2; 11.2 | 11.173 |
| AFL-09 | its lower bound 0.89; 0.89 | 0.88; 0.88 | 0.879 |
| AFL-10 | its upper bound 1.33; 1.33 | 1.36; 1.36 | 1.360 |
| AFL-12 | its lower bound 0.89; 0.89 | 0.88; 0.88 | 0.885 |
| AFL-13 | its upper bound 1.46; 1.46 | 1.44; 1.44 | 1.444 |
| AFL-21 | its upper bound 16.27; 16.27 | 16.28; 16.28 | 16.285 |
| AFL-23 | its lower bound 1.38; 1.38 | 1.36; 1.36 | 1.357 |
| AFL-26 | MD-COPD AFL-only crude respiratory rate ratio 1.80 | 1.84 | 1.841 |
| GRP-02 | its lower bound 1.10 | 1.11 | 1.107 |
| GRP-03 | its upper bound 1.77 | 1.80 | 1.797 |
| GRP-06 | its lower bound 1.15 | 1.16 | 1.159 |
| GRP-07 | its upper bound 1.79 | 1.82 | 1.817 |
| GRP-09 | ESI vs MD-COPD crude all-cause p = 0.25 | p = 0.24 | 0.240 |
| GRP-10 | ESI vs MD-COPD crude exacerbations p = 0.73 | p = 0.78 | 0.776 |
| GRP-12 | to 1.28 | to 1.25 | 1.254 |
| GRP-14 | to 1.09 | to 1.08 | 1.081 |
| MINOR-08 | its p = 0.036 | its p = 0.034 | 0.034 |
| MINOR-03 | its upper bound 0.98 | 0.97 | 0.975 |
| MINOR-04 | its p = 0.016 | its p = 0.012 | 0.012 |
| FILL-22 | AFL-only decline NoCT minus ESI p=0.68 | p=0.65 | 0.652 |
| CONSREF-05 | MD-COPD AFL-only crude respiratory RR 1.80 | 1.84 | 1.841 |
| CONSREF-06 | ESI AFL-only crude respiratory RR 1.88 | 1.92 | 1.921 |
| CONSREF-16 | NoCT AFL-only adjusted respiratory HR 5.46 | 5.43 | 5.428 |
| CONSREF-21 | NoCT AFL-only crude respiratory upper bound 16.27 | 16.28 | 16.285 |
| CONSREF-31 | MD-COPD AFL-only adjusted respiratory HR 1.47 | 1.46 | 1.456 |
| MAJ-01 | NoCT COPD-major 18% to 28% higher | 18% to 25% (expression max == 25) | 1.179 to 1.254 |
| MAJ-02 | ESI COPD-major 5% to 9% higher | 5% to 8% (max == 8) | 1.054 to 1.081 |
| CV-01 | held-out agreement 88.9%; 0.889 | 88.8%; 0.888 | 0.8883 |
| ADJ-02 | its interval 1.07 to 1.70 | 1.09 to 1.71 | 1.091, 1.706 |
| ADJ-03 | P=0.008 | P=0.006 | 0.006 |
| ADJ-04 | 1.22 (0.97 to 1.55), P=0.098 (expression tested p against 0.10) | 1.22 (0.98 to 1.58), P=0.074 (p tested against 0.074, tolerance 0.0005) | 1.218, 0.981, 1.577, 0.074 |
| ADJ-05 | 1.03 (0.82 to 1.31), P=0.79 | 1.03 (0.82 to 1.35), P=0.79 | hi 1.347 |
| ADJ-06 | 0.92 (0.73 to 1.17), P=0.49 | 0.92 (0.75 to 1.18), P=0.50 | 0.920, 0.747, 1.185, 0.498 |
| MIN-01 | NoCT crude all-cause 0.87 (0.79 to 0.95), P = 0.006 | 0.87 (0.78 to 0.97), P = 0.010 | 0.869, 0.783, 0.968, 0.010 |
| MIN-02 | NoCT crude exac 0.90 (0.83 to 0.99), P = 0.036 | P = 0.034 | 0.902, 0.827, 0.991, 0.034 |
| MIN-03 | ESI crude all-cause 0.88 (0.80 to 0.97), P = 0.008 | 0.88 (0.80 to 0.98), P = 0.014 | 0.883, 0.797, 0.981, 0.014 |
| MIN-04 | ESI crude exac 0.89 (0.81 to 0.98), P = 0.016 | 0.89 (0.81 to 0.97), P = 0.012 | 0.888, 0.814, 0.975, 0.012 |
| MIN-05 | adjusted ratios 0.92 to 0.95, P = 0.096 to 0.27 | P = 0.084 to 0.32 | p 0.084 to 0.322 |
| MAJ-06 | ESI 5% to 9% higher, crude and adjusted | 5% to 8% (max == 8) | 1.054 to 1.081 |
| ADJ-ESI-AFL | P = 0.79 and 0.49 | P = 0.79 and 0.50 | 0.79, 0.498 |
| FEV1-NE | P = 0.68 to 0.91 | P = 0.65 to 0.96 | 0.652 to 0.956 |
| DISC-MINOR-ESI | 11% to 12% lower (P = 0.008 and 0.016) | 11% to 12% lower (P = 0.012 and 0.014) | 0.012, 0.014 |
| CI-01 | S4 AFL-only crude all 1.14 [0.91-1.44] | 1.14 [0.92-1.50] | |
| CI-02 | S4 AFL-only crude exac 0.96 [0.78-1.21] | 0.96 [0.79-1.22] | |
| CI-03 | S3 AFL-only adjusted all 1.22 [0.97-1.55], P 0.098 | 1.22 [0.98-1.58], P 0.074 | |
| CI-04 | S4 AFL-only adjusted all 1.03 [0.82-1.31] | 1.03 [0.82-1.35] | |
| CI-05 | S4 AFL-only adjusted exac 0.92 [0.73-1.17] | 0.92 [0.75-1.18] | |
| CI-06 | S3 COPD-minor adjusted all 0.95 [0.85-1.04], P 0.27 | 0.95 [0.85-1.05], P 0.32 | |
| CI-07 | S3 COPD-minor adjusted exac 0.95 [0.87-1.04], P 0.27 | 0.95 [0.87-1.04], P 0.24 | |
| CI-08 | S4 COPD-minor adjusted all 0.94 [0.84-1.03], P 0.20 | 0.94 [0.84-1.05], P 0.24 | |
| CI-09 | S4 COPD-minor adjusted exac 0.92 [0.84-1.02], P 0.096 | 0.92 [0.84-1.01], P 0.084 | |
| CI-10 | S3 COPD-major adjusted all 1.23 [1.19-1.27] | 1.23 [1.20-1.26] | |
| CI-11 | S3 COPD-major adjusted exac 1.17 [1.13-1.21] | 1.17 [1.14-1.21] | |
| CI-14 | S3 COPD-major adjusted resp 1.29 [1.25-1.34] | 1.29 [1.25-1.33] | |

Most of these registered claims (AFL-09 to AFL-26, GRP-09 to GRP-14, MINOR-*, FILL-22, CONSREF-*, MAJ-*, MIN-*, FEV1-NE, DISC-MINOR-ESI, CI-06 to CI-14) are not printed anywhere in the current v5 prose. They come from earlier drafts or appear only in the generated tables, so only verify.R changed for them. CLAIMS.md holds none of these values and was not edited.

## Proposed text changes (not applied)

1. **RESULTS.md, Clinical outcomes, para 1, sentence 1.**
   Current: "Median follow-up was 11.2 years for mortality, 10.4 years for exacerbations, and 9.7 years for lung function decline."
   Proposed: "Median follow-up was 11.2 years for all-cause mortality, 8.6 years for respiratory mortality, 10.4 years for exacerbations, and 9.7 years for lung function decline."
   Reason: respiratory mortality is now followed only to the end of cause-of-death coverage (followup_medians.csv "respiratory mortality (cause-of-death window)", median 8.62 years, IQR 6.19–9.52). The 11.2 years does not apply to respiratory mortality.

2. **METHODS.md, Study population, last sentence (number already changed to 8,769).**
   Current: "Mortality analyses included 8,769 participants with complete follow-up and covariates and exacerbation analyses included 8,177 with longitudinal exacerbation data and complete covariates."
   Proposed: "Mortality analyses included 8,769 participants with follow-up after the baseline visit and complete covariates, and exacerbation analyses included 8,177 with longitudinal exacerbation data and complete covariates."
   Reason: the 469 newly excluded participants have zero follow-up time. "Complete follow-up" could be read as "followed to the end of the study", which is not the criterion.

3. **METHODS.md, Clinical outcomes (a): respiratory mortality window.** After "respiratory mortality was adjudicated using modified TORCH criteria (21)." add:
   "Respiratory deaths were deaths recorded in both the vital-status and the cause-of-death files and adjudicated as respiratory (TORCH group 1). Because cause of death was adjudicated through December 31, 2018, follow-up for respiratory mortality ended at the earlier of the end of cause-of-death coverage and the end of vital-status follow-up."
   Reason: this is the approved analysis change (commits b568ec2, 0319892, 9ef5266). The Methods do not describe it, and the respiratory rates and HRs in the text depend on it. I took the rule from the commit messages, not from the code. The detail about participants dead only in the cause-of-death file (counted as alive) could go in the Online Supplement.

4. **METHODS.md, Study population (b): exclusion of zero follow-up.** Either the wording in proposal 2, or a separate sentence: "Participants without follow-up time after the baseline visit (n = 469) were excluded from mortality analyses."
   Reason: this is the approved change and is not described anywhere. 9,238 − 8,769 = 469.

5. **figures/figure3_group_risk_legend.md and figures/figureS1_group_risk_legend.md: "3,856".**
   Current (Fig 3): "The common reference was the 3,856 participants classified as noCOPD by all three classifications." Fig S1: "...a common reference comprising the 3,856 participants classified as noCOPD by all three classifications."
   Proposed: keep 3,856 as the definition of the group and add "(3,625 in mortality analyses and 3,411 in exacerbation analyses)".
   Reason: the reference group is still the 3,856 noCOPD-by-all-three (consensus_ref_group.csv n_cohort). The mortality columns of these figures are estimated on 3,625 (n_mort) and the exacerbation column on 3,411 (n_exac), so the bare 3,856 overstates the mortality denominator. I did not edit the number because 3,856 is still correct as the group definition.

6. **Generated table legends (build_manuscript.py Table 3; build_supplement.py rate-ratio table S4): same "3,856" issue.** Both print `ref['n_cohort']`. The same parenthetical could be added from `ref['n_mort']` and `ref['n_exac']` (both already columns of consensus_ref_group.csv). This is a change to the legend text, not to table-generation logic, so it is proposed only.

7. **build_supplement.py, "COPDGene files used" list.** Current: "**COPDGene_Mort_COD_Adj**: adjudicated underlying cause of death, used for respiratory mortality." Proposed: append ", with coverage through December 31, 2018, which bounds respiratory-mortality follow-up". Optional. It ties the data-file list to proposal 3.

8. **Discordance analyses (Methods para 7 / Figure 4 / Table S7), no change needed, noted for completeness.** The noCOPD-by-both reference for mortality is also 3,625 (discord_rates.csv n_mort), and the other groups shrank similarly (e.g., ESI-only 501 → 463). Table S7's "n" column prints the full group sizes (n, not n_mort), which is unchanged. Whether the n column should show n_mort is a presentation question for Pete.

No significance call changed. Checked: the NoCT AFL-only crude comparisons stay P < 0.005; every ESI AFL-only comparison stays P > 0.2; the NoCT adjusted all-cause comparison stays non-significant (P = 0.074); the NoCT adjusted exacerbation comparison stays significant (P = 0.006); and the Figure 4 airflow-limitation discordant-group intervals still include 1.
