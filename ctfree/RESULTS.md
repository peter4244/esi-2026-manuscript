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

## Threshold selection

*(new)*

Both CT-free classifications required a threshold for the number of minor
criteria sufficient for the COPD-minor pathway, and ESI-MD-COPD additionally
required a threshold for ESI. Because the three candidate selection criteria
weight the four diagnostic categories differently, they selected substantially
different rules (Supplemental Table S4). For ESI-MD-COPD, Cohen's κ selected a
threshold assigning 3 participants to AFL-only and mean per-category
sensitivity one assigning 954, against 275 in the reference; macro-averaged F1
selected 543, being the only criterion to penalize over-assignment and
under-assignment in every category. We used macro-averaged F1 for both
classifications.

For NoCT-MD-COPD the choice of criterion mattered less, because AFL-only
contained 1,108 participants under every threshold examined, against 275 in the
reference. Participants whose only minor criterion was a CT finding meet no
criteria once the CT criteria are removed, so no threshold recovers them.

The selected rules assigned COPD-minor at two or more of three symptom criteria
for NoCT-MD-COPD, and at two or more of four criteria with the ESI criterion met
at ESI ≥ 1.50 for ESI-MD-COPD. ESI-MD-COPD reproduced the MD-COPD categories
more closely, with a held-out macro-averaged F1 of 0.752 against 0.721
(difference 0.031; 95% across folds: 0.014 to 0.044) {FIT-04a, FIT-04b,
FIT-05a} (Supplemental Table S11). That advantage was confined to the two
categories defined by airflow limitation: per-category F1 was higher for
ESI-MD-COPD in AFL-only, 0.47 against 0.40, and in COPD-major, 0.94 against
0.88, and marginally lower in noCOPD and COPD-minor {F1CAT-01, F1CAT-02,
F1CAT-03} (Table 2).

## Reclassification

*(new)*

All four classifications share the same major criterion, so no participant
moved between the airflow-limitation categories and the preserved-spirometry
categories under any of them; reclassification occurred only within each pair.
NoCT-MD-COPD reclassified 833 of 3,809 COPD-major participants (21.9%) as
AFL-only, together with 579 noCOPD participants as COPD-minor and 75
COPD-minor participants as noCOPD, and retained all 275 participants MD-COPD
assigned to AFL-only {RECL-01, RECL-07, RECL-08}. The 833 were those whose only
minor criterion was a CT finding {RECL-03}. ESI-MD-COPD reclassified 350, 612
and 70 respectively, and retained 193 of the 275, assigning the remaining 82 to
COPD-major {RECL-02}. In total, 7,753 participants (83.9%) retained their
MD-COPD category under NoCT-MD-COPD and 8,126 (87.9%) under ESI-MD-COPD
(Figure 1, Supplemental Table S10).

## Clinical outcomes by diagnostic category

*(new)*

The AFL-only category withholds a COPD diagnosis from participants the fixed
ratio would diagnose, so its clinical profile indicates whether that label
holds. Under MD-COPD, crude rate ratios against the same classification's
noCOPD group were 1.05 (95% CI: 0.79 to 1.37) for all-cause mortality, 1.76 (0
to 5.75) for respiratory mortality and 1.00 (0.77 to 1.25) for exacerbations
{CRUDE-06, CRUDE-08, CRUDE-09}. Under NoCT-MD-COPD the same category carried
1.54 (1.34 to 1.76), 9.38 (5.00 to 21.95) and 1.72 (1.43 to 1.98) {CRUDE-01,
CRUDE-03}, an excess consistent with the 833 participants it received from
COPD-major. Under ESI-MD-COPD, which retained most of those participants in
COPD-major, the estimates were 1.29 (1.05 to 1.55), 2.37 (0.44 to 6.99) and
1.17 (0.94 to 1.41) {CRUDE-04}. Adjusted estimates followed the same ordering
(Figures 2 to 4, Supplemental Tables S3a to S3c).

The three multidimensional classifications gave similar estimates for
COPD-minor. Crude all-cause rate ratios were 1.77, 1.72 and 1.75 for MD-COPD,
NoCT-MD-COPD and ESI-MD-COPD; respiratory 3.27, 3.42 and 3.89; and
exacerbations 3.01, 3.31 and 3.28 {CRUDE-10, CRUDE-11, CRUDE-12}. Resampling
participants and refitting both classifications within each resample gave no
detectable difference between MD-COPD and ESI-MD-COPD for this category on any
outcome, while the two differed for COPD-major (Supplemental Table S9),
indicating that an ESI criterion adds little where the symptom criteria already
identify the category.

## Concordant and discordant classification

*(new)*

To locate the disagreements between MD-COPD and ESI-MD-COPD in individual
participants, we cross-classified binary COPD status within the
preserved-spirometry subgroup, where the two can disagree about a diagnosis
rather than about which COPD category applies. Of these participants, 3,745
were classified as not having COPD by both, 612 by ESI-MD-COPD only, 70 by
MD-COPD only and 729 by both {DISC2-01, DISC2-02, DISC2-03}; ESI-MD-COPD
therefore agreed with 729 of 799 participants (91.2%) MD-COPD assigned to
COPD-minor {DISC2-04}. Observed all-cause mortality across these four groups was
1.46, 2.30, 2.13 and 2.84 per 100 person-years, and exacerbations 11.2, 31.0,
21.7 and 42.9 (Table 3).

Against participants classified as not having COPD by both, those classified as
having COPD by both had an adjusted all-cause hazard ratio of 1.94 (95% CI: 1.62
to 2.32), respiratory 5.10 (1.92 to 13.5) and an exacerbation incidence rate
ratio of 2.10 (1.72 to 2.57) {DISC2-10, DISC2-11, DISC2-12}. The 612
participants identified by ESI-MD-COPD alone carried 1.59 (1.30 to 1.95), 3.63
(1.20 to 11.0) and 1.82 (1.48 to 2.25), approaching those values on every
outcome {DISC2-05, DISC2-13, DISC2-07}. The 70 identified by MD-COPD alone
carried 1.25 (0.70 to 2.22) and 1.88 (1.05 to 3.35), and recorded no respiratory
deaths, so no respiratory estimate was obtained {DISC2-08}. Mean exacerbation
count in the year before enrollment was 0.09, 0.44, 0.16 and 0.50 across the
four groups {DISC2-09}, so part of the gradient in subsequent exacerbations was
present at baseline.

## ESI and the visual CT criteria

*(new)*

Mean ESI increased monotonically across the visual emphysema scale, from 1.04 in
participants with no emphysema through 1.22, 1.59, 2.91 and 5.21 to 6.62 in
those with advanced destructive emphysema, and across airway wall thickening,
from 0.96 when absent through 1.29 when borderline to 3.32 when definite
{CTLEV-01, CTLEV-02} (Supplemental Table S12).

Discrimination of the two criteria by ESI depended on airflow limitation. Among
participants with airflow limitation, ESI discriminated visual emphysema of at
least mild severity with an area under the curve of 0.75 and definite wall
thickening with 0.75; among participants with preserved spirometry the
corresponding values were 0.56 and 0.61 {CTAUC-03, CTAUC-04} (Table 4). Pooled
across the cohort the values were 0.78 and 0.80 {CTAUC-01}, reflecting the
mixture of the two strata rather than detection within either. The same pattern
appeared for quantitative CT, where the correlation between ESI and low
attenuation area was 0.78 across the cohort but 0.08 within GOLD 0 {CORR-01,
CORR-03}. This distribution corresponds to where an ESI criterion altered the
classification: it retained COPD-major participants who would otherwise have
been reclassified, and did not affect the COPD-minor boundary. FEV₁/FVC
discriminated both criteria at least as well as ESI in five of six
stratum-by-criterion comparisons and equally in the sixth {CTAUC-02, CTAUC-02b},
but is already the major criterion and so cannot serve as a minor criterion
(Supplemental Table S13).

Analyzed as a continuous measure, ESI was associated with all-cause mortality in
a model also containing FEV₁/FVC (hazard ratio 1.07 per unit, 95% CI: 1.03 to
1.12; likelihood ratio P = 0.002) but not with respiratory mortality {CONT-01,
CONT-02, CONT-03}. Among GOLD 0 participants, each unit of baseline ESI
predicted an additional 4.6 mL/yr of FEV₁ decline (P = 0.002) {CONT-04}
(Supplemental Tables S7 and S8).

## Longitudinal FEV₁ decline

*(new)*

We estimated annualized change in FEV₁ for every category under all four
classifications, against each classification's own noCOPD group (Supplemental
Table S6). Fixed-ratio COPD declined 1.66 mL/yr faster than the reference
(P = 0.07). Under MD-COPD, estimates were −0.84 mL/yr for AFL-only (P = 0.71),
−3.05 for COPD-minor (P = 0.08) and 1.39 for COPD-major (P = 0.16) {DEC-01}.
Under NoCT-MD-COPD they were −0.95 (P = 0.48), 1.65 (P = 0.23) and 2.78
(P = 0.014), and under ESI-MD-COPD −1.63 (P = 0.36), 1.70 (P = 0.21) and 2.59
(P = 0.013) {DEC-02}. Two of the ten estimates reached significance, both for
COPD-major under a CT-free classification, and both indicated slower decline
than the noCOPD reference rather than faster. FEV₁ decline therefore did not
distinguish between the classifications.

---

## Open

- Whether the continuous-ESI material now compressed into one paragraph
  deserves more room, or belongs only in the Supplement.
