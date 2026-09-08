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

## Selection of diagnostic thresholds for the CT-free classifications

*(Pete's text)*

Both CT-free classifications required a threshold for the number of minor
criteria sufficient for the COPD-minor pathway, and ESI-MD-COPD additionally
required an ESI threshold. We explored multiple measures for identifying optimal
threshold values, evaluating their performance using five-fold cross validation.
Our final thresholds were based on the macro-F1 measure, which had the desirable
effect of giving equal importance to correct assignment for each of the four
groups despite the large difference in sample size between groups (Supplemental
Table S4). The selected rules assigned COPD-minor at ≥ 2 minor criteria for both
ESI-MD-COPD and NoCT-MD-COPD, and the optimal ESI threshold for recovery of
MD-COPD subgroups was ≥ 1.50.

ESI-MD-COPD reproduced the MD-COPD categories more closely than NoCT-MD-COPD,
with a held-out macro-averaged F1 of 0.752 against 0.721 (difference 0.031; 95%
across folds: 0.014 to 0.044) {FIT-04a, FIT-04b, FIT-05a} (Supplemental Table
S11). For NoCT-MD-COPD, the major limitation was that no choice of threshold
could recover the participants with airflow limitation whose only minor
criterion was a CT finding, and who were therefore classified as COPD-major by
MD-COPD; once the CT criteria are removed these participants meet no minor
criteria at all {RECL-03}.

## Reclassification of MD-COPD categories by the CT-free classifications

*(Pete's text)*

We compared the categories each CT-free classification assigned against those
assigned by MD-COPD, and we measured the per-group F1 score (Table 2). Because
all four classifications share the same major criterion, reclassification due to
differences in minor criteria occurred only between the airflow-limitation
groups (COPD-major and AFL-only) and the preserved-spirometry groups
(COPD-minor and noCOPD). Per-category agreement shows that the improved
classification of ESI-MD-COPD resulted primarily from its improved
reconstruction performance in the airflow-limitation groups (F1 score for
AFL-only 0.47 vs 0.40 and COPD-major 0.94 vs 0.88) while maintaining comparable
performance in the preserved-spirometry groups {F1CAT-01, F1CAT-02, F1CAT-03}.
NoCT-MD-COPD reclassified 833 of 3,809 COPD-major participants (21.9%) as
AFL-only, whereas ESI-MD-COPD reclassified 350 {RECL-01, RECL-02}, and overall
concordance with MD-COPD was 83.9% and 87.9% respectively (Figure 1,
Supplemental Table S10).

## Clinical outcomes within each classification's groups

*(new)*

The AFL-only group withholds a COPD diagnosis from participants the fixed ratio
would diagnose, so whether its members are at low risk determines whether a
CT-free classification is usable. Under MD-COPD this group showed no excess on
any outcome, crude or adjusted. Under NoCT-MD-COPD it carried substantially
elevated risk, most markedly for respiratory mortality, where the crude rate
ratio against its own noCOPD group was 9.38 (95% CI: 5.00 to 21.95) compared
with 1.76 (0 to 5.75) under MD-COPD {CRUDE-03, CRUDE-08}; all-cause mortality
and exacerbations were elevated in the same direction (Figures 2 to 4,
Supplemental Tables S3a to S3c). Under ESI-MD-COPD, which retained most of the
participants NoCT-MD-COPD had reclassified, the corresponding estimate was 2.37
(0.44 to 6.99) {CRUDE-04}. Removing the CT criteria without replacement
therefore produces a group whose members do not support its label, and an ESI
criterion largely prevents this.

We next examined the COPD-minor group, where a replacement criterion must be met
by participants with preserved spirometry. The three multidimensional
classifications gave closely similar crude and adjusted estimates on all three
outcomes {CRUDE-10, CRUDE-11, CRUDE-12} (Supplemental Tables S3a to S3c), and
resampling participants while refitting both classifications within each
resample gave no detectable difference between MD-COPD and ESI-MD-COPD for this
group, although the two differed for COPD-major (Supplemental Table S9). An ESI
criterion adds little where the symptom criteria already identify the group.

## Outcomes of concordant and discordant classification by MD-COPD and ESI-MD-COPD

*(new)*

To characterize the participants the two classifications disagree about, we
cross-classified binary COPD status under MD-COPD and ESI-MD-COPD within the
preserved-spirometry subgroup, where the two can disagree about a diagnosis
rather than about which COPD group applies. ESI-MD-COPD agreed with 729 of 799
participants (91.2%) MD-COPD assigned to COPD-minor, identified a further 612 as
having COPD, and did not identify 70 {DISC2-01, DISC2-02, DISC2-03, DISC2-04}.
Observed mortality and exacerbation rates rose across the four resulting groups
(Table 3).

Adjusted against participants both classifications called noCOPD, the 612
identified by ESI-MD-COPD alone carried an all-cause hazard ratio of 1.59 (95%
CI: 1.30 to 1.95), approaching the 1.94 (1.62 to 2.32) of participants both
classifications called COPD, with exacerbations showing the same pattern
{DISC2-05, DISC2-07, DISC2-10, DISC2-12}. The 70 identified by MD-COPD alone
showed no excess all-cause mortality and recorded no respiratory deaths
{DISC2-08}. The disagreements between the two classifications are therefore
asymmetric: participants ESI-MD-COPD adds carry risk approaching that of
established COPD-minor, and those it misses are few and at low risk.

## Relationship of ESI to the visual CT criteria

*(new)*

Because an ESI criterion stands in for the two visual CT criteria, we examined
how closely ESI tracks them. Mean ESI increased monotonically across both
scales, from 1.04 in participants with no visual emphysema to 6.62 in those with
advanced destructive emphysema {CTLEV-01, CTLEV-02} (Supplemental Table S12).

The discrimination of these criteria by ESI depended on airflow limitation.
Among participants with airflow limitation ESI discriminated both visual
emphysema and definite wall thickening with an area under the curve of 0.75,
whereas among those with preserved spirometry the values fell to 0.56 and 0.61
{CTAUC-03, CTAUC-04} (Table 4). Pooled values across the whole cohort were
higher {CTAUC-01} but reflect the mixture of the two strata rather than
detection within either, as does the correlation between ESI and low attenuation
area, which was 0.78 across the cohort but 0.08 within GOLD 0 {CORR-01,
CORR-03}. FEV₁/FVC discriminated both criteria at least as well as ESI
{CTAUC-02, CTAUC-02b} but is already the major criterion and cannot serve as a
minor one (Supplemental Table S13). This distribution corresponds to where an
ESI criterion changed the classification: it retained COPD-major participants
who would otherwise have been reclassified, and left the COPD-minor group
unaffected.

Analyzed as a continuous measure, ESI was associated with all-cause mortality in
a model also containing FEV₁/FVC (hazard ratio 1.07 per unit, 95% CI: 1.03 to
1.12; likelihood ratio P = 0.002) but not with respiratory mortality {CONT-01,
CONT-02, CONT-03}. Among GOLD 0 participants each unit of baseline ESI predicted
an additional 4.6 mL/yr of FEV₁ decline (P = 0.002) {CONT-04} (Supplemental
Tables S7 and S8).

## Longitudinal FEV₁ decline

*(new)*

We estimated annualized change in FEV₁ for every group under all four
classifications, this being the fourth outcome against which the MD-COPD
framework was validated. No group differed from its own noCOPD reference under
MD-COPD, and only two of the ten estimates reached significance, both for
COPD-major under a CT-free classification and both indicating slower decline
than the reference rather than faster {DEC-01, DEC-02} (Supplemental Table S6).
FEV₁ decline did not distinguish between the classifications.

---

## Open

- Whether the continuous-ESI paragraph deserves more room, or belongs only in
  the Supplement.
