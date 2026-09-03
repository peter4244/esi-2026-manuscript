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

## What the multidimensional framework adds to the fixed ratio

*(new)*

The four classifications are named as in the Methods: the **fixed ratio**;
**MD-COPD**, the published CT-based framework; **NoCT-MD-COPD**, with the CT
criteria removed; and **ESI-MD-COPD**, with ESI in their place.

Because fixed-ratio COPD comprises exactly the AFL-only-noCOPD and COPD-major
categories, the fixed-ratio model is nested within the four-category model and
the two can be compared directly. The four-category classification added
information beyond the fixed ratio for all-cause mortality (likelihood ratio
χ² = 122.1 on 2 df) {GATE-01}, respiratory mortality (χ² = 76.1) {GATE-02} and
exacerbations (χ² = 158.9) {GATE-03}, all P < 0.001.

The gain in discrimination was small. The C-index for all-cause mortality rose
from 0.693 to 0.703 {GATE-04, GATE-05}. MD-COPD does not predict better across
the cohort. It corrects the fixed ratio in two groups.

The first group is 275 participants with airflow limitation and no other
abnormality. The fixed ratio calls them COPD. They have no excess mortality
(AFL-only-noCOPD, adjusted all-cause HR 0.87, 95% CI 0.65 to 1.16; crude rate
ratio 1.05, 0.79 to 1.37) {RISK-01, CRUDE-06}. MD-COPD withholds the diagnosis.

The second group is 799 participants with preserved spirometry and at least
three minor criteria. The fixed ratio calls them healthy. Their mortality is
nearly double the reference (COPD-minor, HR 1.83, 1.55 to 2.16) {LAB-01a,
LAB-01b}. MD-COPD gives them the diagnosis. A CT-free classification has to
keep both corrections.

## What is lost when the CT criteria are removed

*(new)*

Removing the CT criteria without replacing them costs the COPD-major category
833 of its 3,809 participants, who are reclassified as AFL-only-noCOPD
{RECL-01, LAB-02}. Those 833 are the participants whose only minor criterion
was a CT finding {RECL-05}. They account for 21.9% of the COPD-major category
{RECL-03, RECL-04}. None of them has a symptom criterion. Remove CT without
replacing it and nothing is left to identify them.

ESI-MD-COPD reduces that loss from 833 to 350 {RECL-02}
and holds the COPD-major category at 3,541 against the reference's 3,809
{LAB-03}. Overall, 8,126 of 9,240 participants (87.9%) retain their MD-COPD
category under ESI-MD-COPD against 7,753 (83.9%) under NoCT-MD-COPD (Figure 1, Supplemental Table S3).

NoCT-MD-COPD and ESI-MD-COPD were both fitted to approximate the CT-based classification by
the same objective and over the same parameter space. ESI-MD-COPD achieved a held-out macro-averaged F1 of 0.752 against 0.721 for NoCT-MD-COPD, a difference of 0.031 (95% across folds 0.014 to 0.044)
{FIT-04a, FIT-04b, FIT-05a, FIT-05b}. The fitted rule uses a single ESI
threshold of 1.50 and a count of two of four minor criteria {FIT-01, FIT-02a,
FIT-02b, FIT-03} (Supplemental Table S4).

## Discrimination favors the classification that should not be used

*(new)*

Discrimination did not track the quality of the classification. NoCT-MD-COPD had the highest C-index of the four for all-cause
mortality (0.721 against 0.703 for MD-COPD) and the highest for
respiratory mortality, and the lowest exacerbation AIC {DISC-01, DISC-01b}
(Supplemental Table S5). ESI-MD-COPD also discriminated marginally better than MD-COPD {DISC-02, DISC-03}.

A C-index does not test what the categories are called. It tests how well they
rank risk. NoCT-MD-COPD ranks risk well because its COPD-major category is smaller and more severe: 2,976 participants rather than 3,809, with
an adjusted hazard ratio of 3.34 against 2.54 {RISK-07, RISK-08}. It gets there by moving 833
participants into a category named as not having COPD.

## Whether the category labels remain true

*(new)*

The AFL-only-noCOPD category exists to identify participants whom the fixed
ratio would call COPD but who do not have it, so a classification is usable only if
that category is genuinely low risk. Under MD-COPD it is. Adjusted all-cause
HR 0.87 (0.65 to 1.16), respiratory HR 1.39 (0.32 to 6.04) and exacerbation
IRR 1.21 (0.95 to 1.54) all cross the null {RISK-01, RISK-01b, RISK-01c}, as
does the crude exacerbation rate ratio (1.00, 0.77 to 1.25) {CRUDE-07}.

Under NoCT-MD-COPD it is not. That category carries 6.4 times the
respiratory mortality of its own noCOPD reference (adjusted HR 6.37, 3.29 to
12.34) and 1.8 times the exacerbation rate (IRR 1.78, 1.56 to 2.03) {RISK-02,
RISK-02b, RISK-03}. The crude estimates are worse than the adjusted ones rather
than better: unadjusted, participants in that category died at 1.54 times the
rate of the reference (95% CI 1.34 to 1.76) {CRUDE-01, CRUDE-02} and had 9.4
times the respiratory mortality {CRUDE-03}. Adjustment masked an excess that
participants actually experienced.

Under ESI-MD-COPD the label largely holds. Adjusted all-cause HR 0.96 (0.78 to
1.18) and respiratory HR 1.77 (0.56 to 5.58) both cross the null {RISK-04,
RISK-04b}. The exacerbation estimate does not (IRR 1.23, 1.03 to 1.48), and
neither does the crude all-cause rate ratio (1.29, 1.05 to 1.55) {CRUDE-04,
CRUDE-05}. The exacerbation estimate is the same size as MD-COPD's own for this
category, 1.23 against 1.21; its interval excludes 1 because ESI-MD-COPD
assigns 543 participants to AFL-only-noCOPD against MD-COPD's 275, not because
the rate is higher. The remaining categories track the reference: COPD-minor HR
1.96 against 1.83, COPD-major 2.93 against 2.54 {RISK-05, RISK-06} (Table 3,
Figures 2 to 4).

---

## Open

- The COPD-minor figure shows the three multidimensional classifications essentially
  superimposed. ESI adds nothing at that boundary, and the text should say so
  rather than leave the figure to say it.
- Whether the v15 secondary analyses of continuous ESI (v15 ¶80) are retained.
- The bronchodilator ΔESI quoted in the Discussion (−0.09) is computed on
  10,160 paired measurements from the full COPDGene, not on this cohort.
