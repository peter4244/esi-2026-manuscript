# Results outline — agreed 2026-09-07

Organizing principle: each section ends on a mechanism rather than a
measurement, and §5 closes the loop back to §1. The goal throughout is to
explain why the final results are what they are, not to recite them.

Numbering below is the FINAL scheme: the old Table 3 (risk by classification
and category) is split by outcome and moved to the Supplement, and the main
text shows it as figures instead.

---

## 1. Optimization of the ESI-MD-COPD and NoCT-MD-COPD classifications
Cites: Table 2; Supplemental Table S4

- **¶1** What had to be determined: a minor-criteria count for both, plus an
  ESI threshold for ESI-MD-COPD. Fitted on MD-COPD labels only, mortality and
  exacerbation data excluded, so what follows is an independent check.
- **¶2** The objective and the weighting. Macro-averaging gives each category
  equal weight regardless of size, necessary because noCOPD and COPD-major are
  88% of the cohort. Within each category F1 combines precision and recall, so
  over- and under-assignment are both penalized. Cohen's kappa and balanced
  accuracy were examined and rejected: kappa is not category-weighted,
  balanced accuracy averages recall alone.
- **¶3** The fitted rules, and why ESI outperforms NoCT. Both k=2; ESI at
  >= 1.50. Held-out macro-F1 0.752 vs 0.721, +0.031 (0.014 to 0.044). The
  cross-tables locate the difference: 833 vs 350 leaving COPD-major.
  Per-category F1 improves for AFL-only (0.40 to 0.47) and COPD-major (0.88 to
  0.94), fractionally lower for noCOPD and COPD-minor. The advantage is
  confined to the airflow-limitation categories.

## 2. Cross-classification and outcome risks
Cites: Figure 1; Figures 2-4; Supplemental Tables S3a-c

- **¶1** What moves and why those people. Movement confined within the
  airflow-limitation pair and within the preserved-spirometry pair. NoCT: 833
  / 579 / 75, retains all 275 AFL-only. ESI: 350 / 612 / 70, retains 193.
  Removing a criterion can only lower a count, so NoCT cannot move anyone out
  of AFL-only; restoring one as ESI can. The 833 are the CT-only group, 21.9%
  of COPD-major. Concordance 83.9% and 87.9%.
- **¶2** Why NoCT's AFL-only label becomes false. MD-COPD crude 1.05 / 1.76 /
  1.00. NoCT 1.54 / 9.38 / 1.72. The excess IS the 833: structural disease
  identified only by CT, placed in a category named for absence of COPD. ESI
  recovers most of them: 1.29 / 2.37 / 1.17. Adjusted estimates agree.
- **¶3** Why the three agree on COPD-minor. Crude all-cause 1.77 / 1.72 /
  1.75, respiratory 3.27 / 3.42 / 3.89, exacerbations 3.01 / 3.31 / 3.28.
  Symptom criteria alone reproduce the category; ESI's per-category F1 here is
  fractionally lower than NoCT's. Reason deferred to section 5.

## 3. Outcome risks by MD-COPD and ESI-MD-COPD cross-classification
Cites: Table 3

- **¶1** The four concordance groups, preserved spirometry only. Both-noCOPD
  3,745, ESI-only 612, CT-only 70, Both-COPD 729. Agreement on 729 of 799
  (91.2%). Observed rates rise across the groups.
- **¶2** Why the disagreements favor ESI. Both-COPD as anchor (1.94 / 5.10 /
  2.10). The 612 ESI adds approach it (1.59 / 3.63 / 1.82). The 70 it misses
  are few and not significantly elevated for mortality. Errors are asymmetric
  in the direction that matters for a diagnostic label. Prior exacerbation
  burden 0.09 vs 0.44 explains part of the exacerbation gradient.

## 4. ESI and the visual CT criteria
Cites: Table 4; Supplemental Table S2

- **¶1** ESI tracks both criteria across their range. Mean ESI 1.04 none to
  6.62 advanced destructive; 0.96 absent to 3.32 definite wall thickening.
- **¶2** The pooled association is severity, not detection. Pooled AUC 0.78
  and 0.80, with FEV1/FVC as good or better (0.82, 0.82). Airflow limitation
  0.75 / 0.75. Preserved spirometry 0.56 / 0.61. Both criteria are poorly
  predicted from spirometry of any kind there. Same pattern in quantitative
  CT: r = 0.78 overall, 0.08 within GOLD 0.
- **¶3** Why the earlier results came out as they did. ESI substitutes for CT
  where the CT criteria are load-bearing, which is why COPD-major holds at
  3,541 rather than 2,976; it does not detect CT abnormality in preserved
  spirometry, which is why the three classifications are indistinguishable at
  the COPD-minor boundary. Also: FEV1/FVC cannot serve as the replacement,
  because it is already the major criterion and a threshold above 0.70 fires
  for everyone with airflow limitation, collapsing AFL-only to zero.

## 5. Longitudinal FEV1 decline
Cites: Supplemental Table S6
Placed last: it contributes nothing to the argument and would interrupt the
chain if placed earlier. Its function is completeness, so it sits where
completeness lives.

- **¶1** Fitted for all four classifications. Fixed ratio 1.66 (P=0.07);
  MD-COPD -0.84 / -3.05 / 1.39, none significant; NoCT -0.95 / 1.65 / 2.78
  (P=0.014); ESI -1.63 / 1.70 / 2.59 (P=0.013). Two of ten significant, both
  COPD-major under a CT-free classification, both in the direction of slower
  decline. Baseline FEV1 is already low there and removing CT moves in
  participants with more room to decline, so this reflects composition. No
  claim drawn.

---

## Display items

| Item | Content |
|---|---|
| Table 1 | The four classifications and their category counts |
| Table 2 | Cross-classification of each CT-free classification against MD-COPD, with per-category F1 |
| Table 3 | MD-COPD x ESI-MD-COPD concordance groups: rates and adjusted estimates, all three outcomes |
| Table 4 | ESI and FEV1/FVC against the two visual CT criteria, pooled and by airflow limitation |
| Figure 1 | Alluvial flow between classifications, MD-COPD centred |
| Figures 2-4 | Crude and adjusted risk by category under each classification, one figure per outcome |
| S1 | Baseline characteristics by GOLD stratum |
| S2 | ESI against quantitative CT |
| S3a-c | Risk by classification and category, one table per outcome |
| S4 | Parameter sweep with all three candidate metrics |
| S5 | Discrimination under each classification |
| S6 | FEV1 decline |
| S7 | Continuous ESI and FEV1/FVC |
| S8 | ESI trajectory |
| S9 | Paired bootstrap, crude and adjusted |

Legends carry units, the reference group and an abbreviation line, nothing
further.
