# Step 1a: factual accuracy, numbers vs aggregate tables (laptop half)

Date: 2026-10-08. Documents: `manuscript/CT-free MD-COPD manuscript draft v5.docx` and
`manuscript/CT-free MD-COPD supplement draft v5.docx`, read with python-docx (paragraphs and
tables). Sources: `assets/*.csv`, `cohort.txt`, `PROVENANCE.txt`, the figure PNGs and
`figures/*_legend.md`. No participant-level file was opened. No builder, Rmd or render script was run.

Method. Tables S2, S4, S5 and S6 were regenerated cell by cell from the CSVs with independent
Python using the paper's P format (< 0.005; 3 dp below 0.1; 2 dp above) and compared as
strings. Every printed cell matched. Tables 1, S1, S3 and S7, and all prose numbers, were checked
by hand against the CSVs. Derived numbers were recomputed from counts and rates: percentages,
sensitivity, PPV, F1, macro-F1, balanced accuracy, Cohen's κ (from `crossclass.csv`), rate ratios
(rate / reference rate, with the reference rate rebuilt from `consensus_ref_group.csv`
events and person-years), ratios versus MD-COPD-CT for both crude rates and adjusted HR/IRR,
CI-versus-P agreement for every bootstrap comparison, the bronchodilator CI from mean, SD and n,
row and column sums, and event partitions across the discordance groups. The main-text sections
of the docx were compared number by number with the `*.md` sources and were identical.

## Scope (approximate count of numbers checked)

| Section | Numbers checked |
|---|---|
| Abstract | 22 |
| At a Glance | 0 (contains no numbers) |
| Methods (main) | 12 |
| Results | 78 |
| Discussion | 11 |
| Table 1 + legend | 19 |
| Figure legends 1–4 (docx = legend .md) | 9 |
| Figure images 1, 2, 3, 4 (labels, cells, AUC insets, point positions) | 47 labels + visual check of 54 estimates |
| Supplemental Methods | 3 |
| Table S1 | 42 |
| Table S2 + legend | 96 |
| Table S3 + legend | 76 |
| Table S4 | 128 |
| Table S5 | 101 |
| Table S6 | 35 |
| Table S7 | 32 |
| Figure S1 / S2 legends and images (n's, significance stars) | 10 + 14 star brackets |
| Word counts | 2 |

About 760 printed numbers checked in total.

## Findings, ranked by severity

**No high- or medium-severity errors were found.** Every printed statistic matches its
producing CSV value at the stated precision, and every derived number recomputes. The items
below are low severity or informational.

### Low

**L1. Stated word counts do not reproduce.** Main docx, Abstract footer: "(word count 250)".
Main docx, end of Discussion: "(Word count 3182)". Both are typed into `ABSTRACT.md` and
`DISCUSSION.md`; the builder does not compute them. Whitespace-token count of the built text:
Abstract 246 including the five bold labels (238 without them). Introduction through Discussion
3,161 including section and subsection headings. Both counts are under the AJRCCM limits, but
the printed figures should be recounted in Word before submission.

**L2. The FEV₁ follow-up median has an unstated denominator.** Results, Clinical outcomes:
"Median follow-up was 10.8 years for mortality, 10.4 years for exacerbations, and 9.7 years for
lung function decline." The 9.7 comes from `followup_medians.csv` row "FEV1 decline,
participants with a follow-up visit" (n = 5,414, median 9.68). Across everyone in the decline
data (n = 9,240, which is also the denominator of the Table S6 n's) the median is 5.08. The
other two medians are over the full analysis sets (9,238 and 8,177). The number is correct, but
a reader will assume it applies to all 9,240. Suggested fix: "9.7 years among the 5,414
participants with a follow-up spirometry visit".

### Informational (no change required; note for step 2/3 agents)

**I1. The Figure 1 AUC denominator is 9,240, not 9,236.** The Figure 1 legend says "9,236
participants had a visual score for each criterion". That is correct for the category counts
(`esi_ct_levels.csv`: 3,086+1,686+1,829+1,435+894+306 = 9,236 and 1,006+4,553+3,677 = 9,236). The
inset AUCs in `esi_ct_auc.csv` use n = 9,240, with the 4 missing scores counted as not meeting the
criterion, as the Supplemental Methods state. The legend and the data agree. The AUCs are not
computed on the 9,236.

**I2. The Table S1 Overall "Female 47%" sits at the edge of rounding.** Weighting the rounded
stratum percentages by n gives 46.35%. Since each stratum value is rounded, the true value lies
between 45.85% and 46.85%, and 47% needs a true value of at least 46.5%. That is possible, so
this is not an error, but it cannot be confirmed on the laptop. A one-line check on the cluster
(count of females / 9,240) would settle it. Current smoker (52.6% weighted, printed 53%), age,
pack-years, FEV₁ %pred and ESI all reconcile with the weighted strata.

**I3. Subtracting printed values does not always give the printed difference** (all
correct from unrounded values):
- Table S6, AFL-only, MD-NoCT minus MD-COPD-ESI is printed "−0.5". The printed rows give
  −4.9 − (−4.3) = −0.6. The unrounded difference is −0.542 (`fev1_noct_vs_esi.csv`).
- Table S4, AFL-only respiratory mortality: MD-NoCT versus MD-COPD-CT is printed "4.49†", while
  the printed rates give 0.30/0.07 = 4.3. The unrounded rates are 0.2977/0.0664 = 4.487.
- Table S4, COPD-major respiratory: printed 1.28, while the rates give 2.33/1.83 = 1.27. The
  unrounded value is 1.276.
- Table S5, COPD-minor respiratory ESI ratio: printed 0.81, while the HRs give 3.29/4.09 = 0.80.
  The unrounded value is 0.805.

**I4. Prose and style details, for step 3:**
- Results, ESI–CT paragraph: "than among those without airflow (AUC 0.56 and 0.61,
  respectively)". The word "limitation" is missing.
- The Abstract writes "P<0.005" while the rest of the paper writes "P < 0.005".

**I5. The McNemar P value is heavily understated.** The text gives "P < 0.005"; the actual value
is 4.7 × 10⁻⁵¹ (χ² = 225.9; 488 participants correct only under ESI versus 118 correct only under
NoCT, from `accuracy_test.csv`). This follows the paper's P-format convention and is not an
error.

**I6. Overall agreement and airflow limitation.** The claim "This difference was concentrated
among participants with airflow limitation" (Abstract) is understated. From `crossclass.csv`:
without airflow limitation, NoCT agrees for 4,601 participants and ESI for 4,570 (NoCT ahead by
31). With airflow limitation, NoCT agrees for 3,251 and ESI for 3,652 (ESI ahead by 401). The
whole difference, and more, comes from participants with airflow limitation. "Concentrated" is
accurate.

Known and decided items were not re-raised: Monte Carlo movement of bootstrap CIs and P values,
and the chronic bronchitis direction in the "symptom criteria more frequent in ESI-only"
sentence. The Figure S2 data show chronic bronchitis 28.2% in CT-only versus 15.0% in ESI-only
(P = 0.0044).

## Numbers verified correct (grouped)

**Cohort and flow (12).** 9,240 (`cohort.txt`, `cohort_flow.csv`). GOLD strata 1,119 / 4,037 /
734 / 1,772 / 1,050 / 528, which sum to 9,240; the four GOLD 1–4 strata sum to 4,084 = fixed-ratio
COPD. Mortality n 9,238 = Σ n_mort in `schema_risk.csv` S2. Exacerbation n 8,177 = Σ n_exac. Common
reference 3,856. This number is logically forced: an MD-COPD-ESI noCOPD participant has fewer
than 2 symptom criteria and is therefore also MD-NoCT noCOPD, so S2∩S3∩S4 = S2∩S4 = 3,856. Missing
visual scores: 4 (9,240 − 9,236). The CV design of 5 folds × 5 repeats and B = 1,000 match
`PROVENANCE.txt` and the `B_eff` fields. R 4.5.2 matches.

**Table 1 (16 counts + rules).** All counts match `schema_labels.csv`, and every row sums to
9,240. The rules ≥3 / ≥2 / ESI ≥ 1.50 match `PROVENANCE.txt` (fitted k = 2, t_low = 1.500).

**ESI and CT (Results paragraphs 1–2, Figure 1, Discussion; 25).** Mean ESI 0.90 (GOLD 0) and
8.30 (GOLD 4), monotone across GOLD 0–4. Bronchodilator change −0.09 [−0.11 to −0.08]: the
interval recomputed from mean −0.0918, SD 0.818, n 9,234 is −0.1085 to −0.0751. Visual levels
1.04, 6.62, 0.96 and 3.32, monotone. AUCs 0.78 / 0.80 overall, 0.75 / 0.75 with airflow
limitation, 0.56 / 0.61 without. All nine Figure 1 n-labels and six inset AUCs match the CSVs.

**Thresholds (Table S2 and legend; 96).** All 13 rows × 7 cells match `metric_sweep.csv`, and
every row sums to 9,240. κ recomputed from `crossclass.csv`: 0.769 (NoCT) and 0.825 (ESI). The
selected rules have the highest macro-F1 in their family. Held-out agreement 88.9% / 85.0% and
full-cohort agreement 89.0% / 85.0% match `schema_fit.csv`.

**Agreement (Results paragraph 3, Abstract, Figure 2, Table S3; ~110).** All 32 cross-class
cells match in both Figure 2 and Table S3; row and column sums reproduce the category sizes.
Overall agreement 8,222 (89.0%) and 7,852 (85.0%). Sensitivity, PPV and F1 recomputed for all 8
rows, and macro-F1 and balanced accuracy reproduce Table S2. PPV bootstrap P values: 0.012 and
three of < 0.005. 833 (21.9% of 3,809) and 350 (9.2%). "Four times the size": 1,108 / 275 = 4.03.
"More than half": the 350 are necessarily a subset of the 833, so 483 / 833 = 58% kept.

**Outcomes against the common reference (Table S4, Table S5, Figures 3 and S1; ~230).** All 27
rows of both tables match `consensus_ref_crude.csv`, `consensus_ref_risk.csv` and
`group_vs_mdcopd.csv` as printed, including † placement. Every crude rate ratio recomputes as
rate / reference rate (reference rates 1.511, 0.0369 and 11.91 per 100 person-years from
573 / 14 / 3,733 events). Every ratio versus MD-COPD-CT recomputes from the rates (crude) or the
HR/IRR (adjusted). For every bootstrap comparison the CI excludes 1 exactly when P < 0.05. Events
agree between the crude and adjusted files. Point positions in Figures 3 and S1 agree with the
tables.

**Prose on outcomes (Abstract and Results paragraphs 5–7, Discussion; ~45).** 1.38 [1.10–1.77]
and 1.42 [1.15–1.79], both < 0.005. 1.14 [0.91–1.44] and 0.96 [0.78–1.21], P 0.25 and 0.73, so
"> 0.2" holds. 1.33 [1.07–1.70], P = 0.008. 1.22 [0.97–1.55], P = 0.098. 1.03 [0.82–1.31] and
0.92 [0.73–1.17], P 0.79 and 0.49. Respiratory rates 0.30 / 0.07 / 0.07. Medians 10.8 / 10.4 /
9.7 (see L2). The qualitative statements check out: COPD-minor and COPD-major exceed the
reference under all three classifications; COPD-major is highest; the ESI COPD-minor rates are
below the CT rates.

**FEV₁ (Table S6 and prose; 35).** All 9 rows match `fev1_decline.csv` and
`fev1_noct_vs_esi.csv`. The significance pattern in Results and Discussion matches: CT COPD-minor
P = 0.007; NoCT and ESI COPD-minor P = 0.96; AFL-only P values 0.22 / < 0.005 / 0.012.

**Discordance (Table S7, Figure 4, Figure S2 and legends, Results paragraphs 8–9; ~70).** All n,
deaths, rate ratios and CIs match `discord_*` CSVs, and the rate ratios recompute from the group
rates. The n's partition the crossclass cells (85, 501, 714, 3,856; 350, 82, 193, 3,459). The
deaths partition the Table S4 events: 34 + 16 = 50; 34 + 75 = 109; 75 + 1,609 = 1,684;
16 + 1,609 = 1,625; 22 + 158 = 180; 94 + 158 = 252. Figure S2 stars match
`discord_profile_tests.csv`: ESI ns P = 0.13 and %LAA ** P = 0.0012 without airflow limitation;
ESI *** and %LAA ns P = 0.53 with airflow limitation; emphysema and wall thickening ***; mMRC and
SGRQ ***; chronic bronchitis ** P = 0.0044. The Figure S2 legend group n's match. The Results
statements on direction and significance in both strata match.

**Table S1 (42).** All cells match `supp_baseline.csv`. Weighted reconciliation of the Overall
row is in I2.
