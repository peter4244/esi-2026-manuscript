# Results — CT-free MD-COPD paper

Draft. **[v15 ¶n]** marks text reused from `manuscript/ESI manuscript draft v15
2026.8.31_PJC.docx`. Every number is registered in [CLAIMS.md](CLAIMS.md) and
checked by `ctfree/verify.R`; claim ids are shown in braces and would be
stripped before submission.

---

## Study population

**[v15 ¶67, verbatim]**

The analytic cohort comprised 9,402 COPDGene participants with complete
baseline data on all diagnostic criteria of the multidimensional framework
(Supplemental Table 4) {COH-01}. The cohort spanned the full COPDGene spectrum,
including 106 never-smokers, 4,054 smokers without airflow obstruction (GOLD 0),
1,129 participants with PRISm, and 4,113 participants with GOLD 1 to 4 airflow
obstruction. Mean baseline ESI increased monotonically with severity across the
spectrum, from 0.83 in never-smokers to 8.30 in GOLD 4 participants.

**[v15 ¶68, verbatim]**

Across the entire cohort, ESI showed significant associations with quantitative
CT measures of emphysema, including the percentage of low attenuation area below
−950 Hounsfield units (%LAA−950HU; r = 0.78) and PRM-defined emphysema
(r = 0.81). The strength of these relationships varied according to disease
severity, with weak correlations observed in groups with minimal structural
abnormalities (GOLD 0, r = 0.08) and stronger relationships among participants
with established airflow obstruction (GOLD 3, r = 0.58; Supplemental Table 5).

## What the multidimensional framework adds to the fixed ratio

*(new)*

Because fixed-ratio COPD comprises exactly the AFL-only-noCOPD and COPD-major
categories, the fixed-ratio model is nested within the four-category model and
the two can be compared directly. The four-category classification added
information beyond the fixed ratio for all-cause mortality (likelihood ratio
χ² = 110.2 on 2 df) {GATE-01}, respiratory mortality (χ² = 53.9) {GATE-02} and
exacerbations (χ² = 162.4) {GATE-03}, all P < 0.001.

The gain in discrimination was small: the C-index for all-cause mortality rose
from 0.694 to 0.703 {GATE-04, GATE-05}. The framework's advantage lies not in
predicting better overall but in reclassifying a specific minority correctly,
and the two reclassifications move in opposite directions. The fixed ratio
labels 170 participants as having COPD who show no excess mortality
(AFL-only-noCOPD, adjusted all-cause HR 0.90, 95% CI 0.62 to 1.30; crude rate
ratio 1.08, 0.73 to 1.49) {RISK-01, CRUDE-06}, and labels 1,086 participants as
not having COPD who carry nearly double the risk (COPD-minor, HR 1.91, 1.64 to
2.22) {LAB-01a, LAB-01b}. A CT-free classification is useful only insofar as it
preserves both corrections.

## What is lost when the CT criteria are removed

*(new)*

Removing the CT criteria without replacing them costs the COPD-major category
949 of its 3,943 participants, who are reclassified as AFL-only-noCOPD
{RECL-01, LAB-02}. Those 949 are precisely the participants whose only minor
criteria were CT findings: 24.1% of the COPD-major category meets the framework
through structural imaging alone, with no symptom criterion at all {RECL-03,
RECL-04, RECL-05}. Without either CT or a structural surrogate there is nothing
left to detect them.

Replacing the CT criteria with ESI reduces that loss from 949 to 233 {RECL-02}
and holds the COPD-major category at 3,803 against the reference's 3,943
{LAB-03}. Overall, 8,580 of 9,402 participants (91.3%) retain their MD-COPD
category under the ESI-based schema against 7,997 (85.1%) without any
structural criterion (Figure 1, Table 2).

Both CT-free schemas were fitted to approximate the CT-based classification by
the same objective and over the same parameter space. The ESI-based schema
achieved a held-out macro-averaged F1 of 0.753 against 0.720 for the
symptoms-only schema, a difference of 0.033 (95% across folds 0.016 to 0.050)
{FIT-04a, FIT-04b, FIT-05a, FIT-05b}. The fitted rule uses a single ESI
threshold of 1.25 and a count of two of four minor criteria {FIT-01, FIT-02a,
FIT-02b, FIT-03} (Supplemental Table S2).

## Discrimination favors the schema that should not be used

*(new)*

Discrimination did not track the quality of the classification. The
symptoms-only schema had the highest C-index of the four for all-cause
mortality (0.722 against 0.703 for the CT-based framework) and the highest for
respiratory mortality, and the lowest exacerbation AIC {DISC-01, DISC-01b}
(Supplemental Table S1). The ESI-based schema also discriminated marginally
better than the CT-based reference {DISC-02, DISC-03}.

The explanation is that a summary measure of discrimination is indifferent to
what the categories are called. The symptoms-only schema separates risk more
sharply because it concentrates the COPD-major category into a smaller, more
selected group, and it does so by moving 949 participants into a category
labeled as not having COPD.

## Whether the category labels remain true

*(new)*

The AFL-only-noCOPD category exists to identify participants whom the fixed
ratio would call COPD but who do not have it, so a schema is usable only if
that category is genuinely low risk. Under the CT-based framework it is:
adjusted all-cause HR 0.90 (0.62 to 1.30), with intervals crossing 1 for
respiratory mortality and exacerbations as well {RISK-01, RISK-01b}.

Under the symptoms-only schema it is not. That category carries 6.6 times the
respiratory mortality of its own noCOPD reference (adjusted HR 6.61, 3.41 to
12.79) and 1.8 times the exacerbation rate (IRR 1.80, 1.58 to 2.05) {RISK-02,
RISK-02b, RISK-03}. The crude estimates are worse than the adjusted ones rather
than better: unadjusted, participants in that category died at 1.56 times the
rate of the reference (95% CI 1.35 to 1.79) {CRUDE-01, CRUDE-02} and had 9.6
times the respiratory mortality {CRUDE-03}. Adjustment masked an excess that
participants actually experienced.

Under the ESI-based schema the label holds. Adjusted all-cause HR 0.94 (0.72 to
1.22), with no significant excess on any outcome {RISK-04, RISK-04b}, and a
crude all-cause rate ratio of 1.30 whose interval includes 1 {CRUDE-04,
CRUDE-05}. The remaining categories track the reference closely: COPD-minor HR
1.94 against 1.91, COPD-major 2.76 against 2.59 {RISK-05, RISK-06} (Table 3,
Figures 2 to 4).

---

## Open

- The COPD-minor figure shows the three multidimensional schemas essentially
  superimposed. ESI adds nothing at that boundary, and the text should say so
  rather than leave the figure to say it.
- Whether the v15 secondary analyses of continuous ESI (v15 ¶80) are retained.
- The crude all-cause interval for the ESI schema's AFL-only category has a
  lower bound of 0.98, close enough to 1 that "no excess" should not be stated
  more strongly than the data support.
