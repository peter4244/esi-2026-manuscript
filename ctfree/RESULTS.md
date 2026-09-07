# Results — CT-free MD-COPD paper

Draft. **[v15 ¶n]** marks text reused from `manuscript/ESI manuscript draft v15
2026.8.31_PJC.docx`. Every number is registered in [CLAIMS.md](CLAIMS.md) and
checked by `ctfree/verify.R`; claim ids are shown in braces and would be
stripped before submission.

---

## Study population

**[v15 ¶67, rewritten for the corrected cohort]**

The analytic cohort comprised 9,240 COPDGene participants
(Supplemental Table S1) {COH-01}. It follows the exclusion chain of the source MD-COPD report, which
removes never-smokers, so the cohort is entirely ever-smokers. It comprised
4,037 smokers without airflow obstruction (GOLD 0), 1,119 participants with
PRISm, and 4,084 participants with GOLD 1 to 4 airflow obstruction {COH-02,
COH-03}. Mean baseline ESI increased monotonically with severity, from 0.90 in
GOLD 0 to 8.30 in GOLD 4 participants.

**[v15 ¶68, verbatim]**

Across the entire cohort, ESI showed significant associations with quantitative
CT measures of emphysema, including the percentage of low attenuation area below
−950 Hounsfield units (%LAA−950HU; r = 0.78) {CORR-01} and PRM-defined
emphysema (r = 0.81) {CORR-02}. The strength of these relationships varied
according to disease severity, with weak correlations observed in groups with
minimal structural abnormalities (GOLD 0, r = 0.08) {CORR-03} and stronger
relationships among participants with established airflow obstruction
(GOLD 3, r = 0.58) {CORR-04, CORR-05} (Supplemental Table S2).

## Optimization of the ESI-MD-COPD and NoCT-MD-COPD classifications

*(new)*

Both modified classifications require a threshold for the number of minor
criteria sufficient for the COPD-minor pathway, and ESI-MD-COPD additionally
requires a threshold for ESI itself. Thresholds were determined against the
MD-COPD labels alone. Mortality and exacerbation data were excluded from the
fitting, so the outcome comparisons reported below are an independent check
rather than a restatement of the fit.

The objective scores a four-category classification, and it macro-averages, so
that each category contributes equally regardless of how many participants it
contains. This matters because noCOPD and COPD-major together account for 88%
of the cohort; a score that is not category-weighted is determined almost
entirely by them and is nearly indifferent to AFL-only, which contains 275
participants. Within each category, F1 combines precision and recall, so that
assigning too many participants to a category is penalized as well as assigning
too few. Cohen's κ and mean per-category sensitivity, also known as balanced
accuracy, were examined and rejected: κ is a single overall agreement statistic
that is not category-weighted, and balanced accuracy averages recall alone.
Neither penalizes over-assignment, and their optima lie where AFL-only is
respectively almost empty and more than triple the size of the reference
(Supplemental Table S4).

The fitted rules assign COPD-minor at two or more of three symptom criteria for
NoCT-MD-COPD, and at two or more of four criteria with the ESI criterion met at
ESI ≥ 1.50 for ESI-MD-COPD. ESI-MD-COPD achieved a held-out macro-averaged F1
of 0.752 against 0.721 for NoCT-MD-COPD, a difference of 0.031 (95% across
folds: 0.014 to 0.044) {FIT-04a, FIT-04b, FIT-05a} (Supplemental Table S11). The cross-classifications
locate that difference (Table 2). Removing the CT criteria without replacement
moves 833 participants out of COPD-major, and replacing them with ESI reduces
that to 350 {RECL-01, RECL-02}. Per-category F1 against MD-COPD improves for
AFL-only, from 0.40 to 0.47, and for COPD-major, from 0.88 to 0.94, and is
fractionally lower for noCOPD and COPD-minor {F1CAT-01, F1CAT-02, F1CAT-03}.
The advantage of an ESI criterion is therefore confined to the two categories
defined by airflow limitation.

## Cross-classification and outcome risks

*(new)*

All classifications share the same major criterion, so no participant moves
between the airflow-limitation categories and the preserved-spirometry ones,
and reclassification occurs only within each pair. NoCT-MD-COPD moves 833
participants from COPD-major to AFL-only, 579 from noCOPD to COPD-minor and 75
from COPD-minor to noCOPD, and retains all 275 of the participants MD-COPD
assigns to AFL-only. ESI-MD-COPD moves 350, 612 and 70 respectively, and
retains 193, moving the remaining 82 into COPD-major {RECL-07, RECL-08}.
Removing a criterion can only lower a participant's count, so NoCT-MD-COPD
cannot move anyone out of AFL-only; restoring a criterion in the form of ESI
can. The 833 participants lost from COPD-major are those whose only minor
criterion was a CT finding, 21.9% of that category {RECL-03}. Overall, 7,753
participants (83.9%) retain their MD-COPD category under NoCT-MD-COPD and 8,126
(87.9%) under ESI-MD-COPD (Figure 1, Supplemental Table S10).

The AFL-only category withholds a COPD diagnosis from participants the fixed
ratio would diagnose, so it is defensible only while the participants within it
are at genuinely low risk. Under MD-COPD they are, with crude rate ratios of
1.05 (95% CI: 0.79 to 1.37) for all-cause mortality, 1.76 (0 to 5.75) for
respiratory mortality and 1.00 (0.77 to 1.25) for exacerbations {CRUDE-06,
CRUDE-08, CRUDE-09}. Under NoCT-MD-COPD they are not: 1.54 (1.34 to 1.76), 9.38
(5.00 to 21.95) and 1.72 (1.43 to 1.98) {CRUDE-01, CRUDE-03}. The excess is
attributable to the 833 participants moved into that category, who have
structural disease identified only by chest CT and who are placed by a CT-free
classification into a category named for the absence of COPD. Under
ESI-MD-COPD, which recovers most of them, the estimates return close to those
of MD-COPD: 1.29 (1.05 to 1.55), 2.37 (0.44 to 6.99) and 1.17 (0.94 to 1.41)
{CRUDE-04}. Adjusted estimates follow the same ordering (Figures 2 to 4,
Supplemental Tables S3a to S3c).

At the COPD-minor boundary the three multidimensional classifications are
close to indistinguishable. Crude all-cause rate ratios are 1.77, 1.72 and 1.75
for MD-COPD, NoCT-MD-COPD and ESI-MD-COPD; respiratory 3.27, 3.42 and 3.89; and
exacerbations 3.01, 3.31 and 3.28 {CRUDE-10, CRUDE-11, CRUDE-12}. The symptom
criteria alone reproduce this category about as well as ESI does, which is
consistent with the per-category F1 reported above, where ESI-MD-COPD is
fractionally lower than NoCT-MD-COPD. Resampling participants and refitting
both classifications within every resample confirms that the two assign
statistically indistinguishable effect sizes to this category on all three
outcomes, while differing for COPD-major (Supplemental Table S9). The reason is
taken up below.

## Outcome risks by MD-COPD and ESI-MD-COPD cross-classification

*(new)*

To examine the disagreements at the level of individual participants, binary
COPD status under MD-COPD and under ESI-MD-COPD was cross-classified within the
preserved-spirometry subgroup, where the two classifications can disagree about
a diagnosis rather than about which COPD category applies. Of these
participants, 3,745 are classified as not having COPD by both, 612 by
ESI-MD-COPD only, 70 by MD-COPD only and 729 by both {DISC2-01, DISC2-02,
DISC2-03}. ESI-MD-COPD therefore agrees with 729 of the 799 participants
MD-COPD assigns to COPD-minor, or 91.2% {DISC2-04}. Observed all-cause
mortality rises across the four groups, at 1.46, 2.30, 2.13 and 2.84 per 100
person-years, as do exacerbations, at 11.2, 31.0, 21.7 and 42.9 (Table 3).

Against participants both classifications call noCOPD, the group both call COPD
carries an adjusted all-cause hazard ratio of 1.94 (95% CI: 1.62 to 2.32),
respiratory 5.10 (1.92 to 13.5) and an exacerbation incidence rate ratio of
2.10 (1.72 to 2.57) {DISC2-10, DISC2-11, DISC2-12}. The 612 participants added
by ESI-MD-COPD approach these values on every outcome, at 1.59 (1.30 to 1.95),
3.63 (1.20 to 11.0) and 1.82 (1.48 to 2.25) {DISC2-05, DISC2-13, DISC2-07}. The
70 participants ESI-MD-COPD does not identify carry 1.25 (0.70 to 2.22) for
all-cause mortality and 1.88 (1.05 to 3.35) for exacerbations, and had no
respiratory deaths during follow-up, so no respiratory estimate is available for
them {DISC2-08}. The errors are therefore asymmetric in the direction that
matters for a diagnostic label: the participants ESI-MD-COPD adds carry risk
approaching that of established COPD-minor, and the participants it misses are
few. Prior exacerbation burden rises across the groups from 0.09 to 0.44 and
0.50 exacerbations per participant in the year before enrollment {DISC2-09}, so
part of the gradient in subsequent exacerbations reflects history already
present at baseline.

## ESI and the visual CT criteria

*(new)*

Mean ESI rises monotonically across the visual emphysema scale, from 1.04 in
participants with no emphysema through 1.22, 1.59, 2.91 and 5.21 to 6.62 in
those with advanced destructive emphysema, and across airway wall thickening,
from 0.96 when absent through 1.29 when borderline to 3.32 when definite
{CTLEV-01, CTLEV-02}.

Pooled across the cohort, ESI discriminates visual emphysema of at least mild
severity with an area under the curve of 0.78 and definite wall thickening with
0.80, and FEV₁/FVC discriminates both better, at 0.82 and 0.82 {CTAUC-01}. Stratifying by airflow limitation shows that this is
largely a reflection of severity rather than of detection. Among participants
with airflow limitation, ESI achieves 0.75 and 0.75 and FEV₁/FVC 0.78 and 0.75;
these are the only comparisons in which ESI is not clearly lower, and for wall
thickening the two are equal to two decimal places {CTAUC-02, CTAUC-02b}.
Among participants with preserved spirometry, where the ESI criterion actually
operates in the COPD-minor pathway, ESI achieves only 0.56 and 0.61, and
FEV₁/FVC 0.67 and 0.64 {CTAUC-03, CTAUC-04} (Table 4). Both CT criteria are
poorly predicted from spirometry of any kind in that stratum. The same pattern
holds for quantitative CT, where the correlation between ESI and low attenuation
area is 0.78 across the cohort but 0.08 within GOLD 0 {CORR-01, CORR-03}.
Used as a continuous measure rather than as a threshold, ESI carried all-cause
mortality beyond FEV₁/FVC (hazard ratio 1.07 per unit, 95% CI: 1.03 to 1.12;
likelihood ratio P = 0.002) though it added nothing for respiratory mortality
{CONT-01, CONT-02, CONT-03}, and among GOLD 0 participants each unit predicted
4.6 mL/yr of additional FEV₁ decline (P = 0.002) {CONT-04} (Supplemental Tables
S7 and S8).

This accounts for the results above. ESI substitutes for the CT criteria among
participants with airflow limitation, which is precisely where COPD-major is
lost when CT is removed, and is why ESI-MD-COPD holds that category at 3,541
participants rather than the 2,976 of NoCT-MD-COPD {LAB-02, LAB-03}. It does
not detect CT abnormality among participants with preserved spirometry, which is
why the three multidimensional classifications are indistinguishable at the
COPD-minor boundary. FEV₁/FVC cannot serve as the replacement criterion despite
discriminating the CT findings at least as well, because it is already the major
criterion: a minor criterion defined by a threshold above 0.70 is met by every
participant with airflow limitation, which would empty the AFL-only category
entirely and remove the correction the framework exists to make.

## Longitudinal FEV₁ decline

*(new)*

Annualized change in FEV₁ was estimated for every category under all four
classifications, against each classification's own noCOPD group. Fixed-ratio
COPD declined 1.66 mL/yr faster than the reference (P = 0.07). Under MD-COPD no
category differed from the reference: AFL-only −0.84 mL/yr (P = 0.71),
COPD-minor −3.05 (P = 0.08) and COPD-major 1.39 (P = 0.16) {DEC-01}. Under
NoCT-MD-COPD the estimates were −0.95 (P = 0.48), 1.65 (P = 0.23) and 2.78
(P = 0.014), and under ESI-MD-COPD −1.63 (P = 0.36), 1.70 (P = 0.21) and 2.59
(P = 0.013) {DEC-02} (Supplemental Table S6). Two of the ten estimates reach
significance, both for COPD-major under a CT-free classification, and both in
the direction of slower decline than the noCOPD reference rather than faster.
Baseline FEV₁ is already low in those categories, and removing the CT criteria
moves into them participants with more room to decline, so the comparison
reflects a change in composition rather than a difference in disease behavior.
This outcome does not distinguish between the classifications and no claim is
drawn from it.

---

## Open

- Abstract and References remain to be written.
- Whether the continuous-ESI material now compressed into one sentence of the
  ESI-and-CT section deserves more room, or belongs only in the Supplement.
