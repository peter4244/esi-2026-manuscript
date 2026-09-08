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

## Reclassification of MD-COPD categories by the CT-free classifications

*(Pete's text)*

We compared the two CT-free classifications to MD-COPD (Table 2), and
ESI-MD-COPD reproduced the MD-COPD categories more closely, with a held-out
macro-averaged F1 of 0.752 against 0.721 (p<0.001, Supplemental Table S11)
{FIT-04a, FIT-04b, FIT-07a, FIT-07b}. Because all four classifications share
the same major criterion, reclassification occurred due only to differences in
minor criteria and was limited to shifts between the airflow-limitation groups (COPD-major and
AFL-only) and the preserved-spirometry groups (COPD-minor and noCOPD).
Per-category agreement shows that ESI-MD-COPD outperformed the NoCT-MD-COPD
classification in the airflow-limitation groups (F1 score for AFL-only 0.47 vs
0.40 and COPD-major 0.94 vs 0.88) while maintaining comparable performance in
the preserved-spirometry groups {F1CAT-01, F1CAT-02, F1CAT-03}. NoCT-MD-COPD
misclassified 833 of 3,809 COPD-major participants (21.9%) as AFL-only, whereas
ESI-MD-COPD only misclassified 350 {RECL-01, RECL-02} (Figure 1). For NoCT-MD-COPD, no choice of threshold could recover the participants with airflow limitation whose only minor criterion was a CT finding; once the CT criteria are removed these participants meet no minor criteria at all {RECL-03}.

## Clinical outcomes within each classification's groups

*(Pete's text, extended)*

To systematically compare the risk of the AFL-only, COPD-minor and COPD-major
groups across the three multidimensional classifications, we defined a noCOPD
group consisting of subjects assigned as noCOPD by all three methods in order to
have a consistent reference group, and all estimates below are made against it
{CONSREF-00} (Table 3). This reference is smaller and at lower risk than any
single classification's own noCOPD group, since it excludes the participants the
three disagree about, so estimates against it are larger than the corresponding
per-classification estimates.

For the AFL-only group, which withholds a COPD diagnosis from participants who
would otherwise receive one on the fixed ratio, risk was at reference level in
both the MD-COPD and ESI-MD-COPD classifications for all-cause mortality (crude
rate ratio 1.13 and 1.29, adjusted hazard ratio 0.94 and 0.96) and for
respiratory mortality (crude 2.23 and 2.34, adjusted 1.84 and 1.75, all on 2 and
4 respiratory deaths and reported without intervals), with a modest excess in
exacerbations that was present under both (adjusted incidence rate ratio 1.36,
95% CI: 1.08 to 1.73, and 1.25, 1.05 to 1.50) {CONSREF-01, CONSREF-02,
CONSREF-05, CONSREF-06, CONSREF-07, CONSREF-09} (Figure 2, Supplemental Tables S3a to S3c). Under the
NoCT-MD-COPD classification, this group carried substantially elevated risk on
every outcome, most markedly for respiratory mortality (crude 10.00, 95% CI:
4.95 to 21.87; adjusted 6.80, 3.44 to 13.46), and also for all-cause mortality
(crude 1.57, 1.35 to 1.82) and exacerbations (crude 1.75, 1.46 to 2.03; adjusted
1.81, 1.58 to 2.06) {CONSREF-03, CONSREF-04, CONSREF-08, CONSREF-16,
CONSREF-20, CONSREF-21}. The raw counts make the same point without a model: the
AFL-only group contained 2 respiratory deaths under MD-COPD and 4 under
ESI-MD-COPD, against 34 under NoCT-MD-COPD. In the original report, the AFL-only
MD-COPD group showed no excess risk in all-cause mortality, exacerbations or
FEV₁ decline after adjustment. This demonstrates that removing the CT criteria
results in an AFL-only group that is contaminated by individuals at elevated
risk of COPD-related outcomes.

For the COPD-minor group, where a replacement criterion must be met by
participants with preserved spirometry, the three multidimensional
classifications were indistinguishable on all three outcomes, with adjusted
all-cause hazard ratios of 2.02, 1.97 and 2.01 under MD-COPD, ESI-MD-COPD and
NoCT-MD-COPD, and overlapping intervals throughout {CONSREF-10, CONSREF-11,
CONSREF-12} (Figure 3, Table 3, Supplemental Tables S3a to S3c). Resampling participants while refitting both
classifications within each resample likewise gave no detectable difference
between MD-COPD and ESI-MD-COPD for this group, although the two differed for
COPD-major (Supplemental Table S9). An ESI criterion adds little where the
symptom criteria already identify the group.

For the COPD-major group, risk was the highest of any group under every
classification, and the estimates were largest under NoCT-MD-COPD on all three
outcomes, with adjusted all-cause hazard ratios of 2.75, 2.94 and 3.38 under
MD-COPD, ESI-MD-COPD and NoCT-MD-COPD {CONSREF-13, CONSREF-14, CONSREF-15}
(Figure 4, Table 3). This does not mean that NoCT-MD-COPD defines a better
COPD-major group. It follows from the same reclassification: having moved 833 of
its members into AFL-only, what remains is a smaller and more severe group, and
the risk it sheds reappears in the AFL-only group.

## Outcomes of concordant and discordant classification by MD-COPD and ESI-MD-COPD

*(new)*

To characterize the participants the two classifications disagree about, we
cross-classified binary COPD status under MD-COPD and ESI-MD-COPD within the
preserved-spirometry subgroup, where the two can disagree about a diagnosis
rather than about which COPD group applies. ESI-MD-COPD agreed with 729 of 799
participants (91.2%) MD-COPD assigned to COPD-minor, identified a further 612 as
having COPD, and did not identify 70 {DISC2-01, DISC2-02, DISC2-03, DISC2-04}.
Observed mortality and exacerbation rates rose across the four resulting groups
(Table 4).

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

Among participants with airflow limitation, ESI discriminated both visual
emphysema and definite wall thickening with an area under the curve of 0.75,
whereas among those with preserved spirometry the values fell to 0.56 and 0.61
{CTAUC-03, CTAUC-04} (Table 5). This distribution corresponds to where an ESI
criterion changed the classification: it retained COPD-major participants who
would otherwise have been reclassified, and left the COPD-minor group
unaffected.

## Longitudinal FEV₁ decline

*(new)*

We estimated annualized change in FEV₁ for every group under all four
classifications, this being the fourth outcome against which the MD-COPD
framework was validated, adjusting for baseline post-bronchodilator FEV₁ as the
source report did. Every point estimate was negative and seven of the ten
reached significance {FEV1-05, FEV1-06}. COPD-major declined faster than its
reference under all three multidimensional classifications, by 5.6, 5.1 and 4.9
mL/yr under MD-COPD, NoCT-MD-COPD and ESI-MD-COPD {FEV1-01, FEV1-02, FEV1-03},
and fixed-ratio COPD by 4.3 mL/yr {FEV1-04} (Supplemental Table S6). The three
multidimensional classifications did not separate from each other on this
outcome, which is the comparison this study is making, so FEV₁ decline does not
bear on whether the CT criteria can be replaced.

## Open
