# Claims — CT-free MD-COPD paper

Claim tracking for this paper starts here. It shares no entries with the v15
manuscript's registry: that registry is pinned to a document whose central
claim ("the ESI-based framework reproduced the CT-based framework") is not the
claim of this paper, and 180 of its 241 entries verify tables that no longer
exist. The v15 registry stays in the repository, frozen, so the two can be
diffed at the end and nothing is dropped by accident rather than on purpose.

The registry itself is `ctfree/verify.R`. Each `reg()` entry there pins one
number printed in the manuscript or supplement to the artifact and field that
produces it, and `verify.R` evaluates every entry against `ctfree/assets/` as
it exists on disk now and fails loudly on drift. It writes the results to
`ctfree/assets/VERIFICATION.csv`. This file is a reading guide to that
registry, current with the v8 manuscript and supplement: 291 claims, all
passing. Nothing may be quoted in prose without an entry in `verify.R`.

The v8 numbers come from the Channing run on the original sid-keyed COPDGene
files (job 6118470; Table S7 from job 6120833).

## Scope of this paper

CT is often unavailable. MD-COPD is defined partly by CT findings. Can the
classification, and the benefit it carries over the fixed ratio, be preserved
using spirometry and symptoms alone?

Four classifications, same 9,240 participants, same covariates:

S1 to S4 are internal identifiers used in the artifacts, the code and the
field expressions in `verify.R`. The manuscript names them as follows, and
those names are what appear in the prose, tables and figures.

| artifact id | name in code | manuscript name | definition |
|---|---|---|---|
| S1 | fixed ratio | **Fixed ratio** | FEV1/FVC < 0.70 alone |
| S2 | MD-COPD | **MD-COPD-CT** | the published CT-based framework; the reference |
| S3 | NoCT-MD-COPD | **MD-NoCT** | CT criteria removed, count threshold refitted |
| S4 | ESI-MD-COPD | **MD-COPD-ESI** | CT criteria replaced by one ESI criterion; count threshold and ESI cut-point refitted |

## Standing methodological decisions

- **Objective for fitting S3 and S4: macro-averaged F1** across the four
  categories. Symmetric across categories, but balancing precision against
  recall within each. Cohen's kappa and mean per-category sensitivity err in
  opposite directions on AFL-only (`objective_selection.csv`): kappa selects a
  rule that leaves 3 participants in AFL-only, mean sensitivity one that puts
  954 there, against 275 under MD-COPD-CT. Macro-F1 selects ≥2 of 4 with
  ESI ≥1.50, which puts 543 there.
- **Fitting is outcome-blind.** Thresholds are fitted only against S2's
  labels. No mortality or exacerbation data enters selection, so the risk
  profiles are an independent check rather than a restatement of the fit.
- **S3 and S4 are fitted by the same objective over their full parameter
  space**, including the count threshold. Both land on 2; allowing one to move
  and not the other would rig the comparison.
- **The count threshold of 2 departs from Bhatt's rule of 3** and has to be
  argued in the paper, not slipped in. It applies to S3 and S4 equally.
- **ESI is one criterion with one cut-point.** An earlier rule scored ESI 0/1/2
  with an upper threshold fitted at 7.00; it was reached by 2 of 5,156
  participants with preserved spirometry and was dropped (FIT-03).
- **Risk is estimated against one common reference**: the 3,856 participants
  all three multidimensional classifications call noCOPD (3,625 in the
  mortality analyses, 3,411 in the exacerbation analyses).

## Claims

Grouped by where the number appears. The id prefixes are those in `verify.R`;
the values are the v8 values from `ctfree/assets/`. See
`results_to_code_map.md` for the producing chunk and the Methods section.

### Study population and cohort (Methods; Results, first section; Table S1)

| ids | what is pinned | artifact |
|---|---|---|
| COH-01 to COH-03 | 9,240 analysed; 4,084 with and 5,156 without airflow limitation | cohort.txt |
| FU-06, FU-07 | 8,769 in mortality analyses, 8,177 in exacerbation analyses | followup_medians.csv |
| BASE-01, BASE-02, GOLD-01 to GOLD-08 | stratum counts 1,119 / 4,037 / 734 / 1,772 / 1,050 / 528; mean ESI 0.90 (GOLD 0) to 8.30 (GOLD 4); no never-smoker stratum | supp_baseline.csv |
| CONT-06, CONT-07, BD-CI, FILL-30 to FILL-32 | bronchodilator change −0.09 [−0.11 to −0.08], SD 0.82, 9,234 paired | bronchodilator_delta_esi.csv |

### Fitting (Results; Table 1; Table S2)

| ids | what is pinned | artifact |
|---|---|---|
| FIT-01 to FIT-03 | MD-NoCT ≥2 of 3; MD-COPD-ESI ≥2 of 4 with ESI ≥1.50; single ESI threshold | schema_fit.csv |
| CV-01, CV-02 | held-out agreement 88.8% (MD-COPD-ESI) and 85.0% (MD-NoCT); 89.0% and 85.0% in the full cohort | schema_fit.csv |
| F1CAT-01 to F1CAT-03 | per-category F1, AFL-only 0.40 → 0.47, COPD-major 0.88 → 0.94 | f1_by_category.csv |

### ESI and the visual CT criteria (Results; Figure 1; Abstract)

| ids | what is pinned | artifact |
|---|---|---|
| CTLEV-01, CTLEV-02 | mean ESI 1.04 → 6.62 across visual emphysema, 0.96 → 3.32 across wall thickening | esi_ct_levels.csv |
| CTAUC-01 to CTAUC-08 | AUC 0.78 and 0.80 overall; 0.75 and 0.75 with airflow limitation; 0.56 and 0.61 without; FEV1/FVC at least as good in 5 of 6 | esi_ct_auc.csv |
| SM-CTMISS | 4 participants without a visual CT score (Supplemental Methods) | esi_ct_levels.csv |

### Agreement and reclassification (Results; Figure 2; Table 1; Table S3)

| ids | what is pinned | artifact |
|---|---|---|
| LAB-01a/b/c, LAB-02 to LAB-04, AFL-01 | MD-COPD-CT 4,357 / 275 / 799 / 3,809; MD-NoCT COPD-major 2,976 and AFL-only 1,108; MD-COPD-ESI COPD-major 3,541 and AFL-only 543 | schema_labels.csv |
| RECL-09 to RECL-12, ACC-01 | agreement 89.0% (8,222) vs 85.0% (7,852); McNemar P < 0.005 | reclassification.csv, crossclass.csv, accuracy_test.csv |
| RECL-01, RECL-02, RECL-04 to RECL-08, RECL-13, RECL-14 | 833 (21.9%) vs 350 (9.2%) COPD-major reassigned to AFL-only; the 833 are exactly the CT-only COPD-major | reclassification.csv |
| SENS-01 to SENS-04, PPV-01 to PPV-04, AGR-01 to AGR-13, NEW-01, NEW-02 | sensitivity and PPV per category at 1 dp (e.g. AFL-only 100% / 70.2% and 24.8% / 35.5%, P < 0.005) | agreement_by_group.csv |

### Clinical outcomes (Results; Figure 3; Tables S4-S7; Figure S1)

| ids | what is pinned | artifact |
|---|---|---|
| FU-01 to FU-05 | median follow-up 11.2 (all-cause), 8.6 (respiratory), 10.4 (exacerbations), 9.7 years (FEV₁, 5,414 with a follow-up visit) | followup_medians.csv |
| CONSREF-00 to CONSREF-32, FILL-01, REF-M, REF-E | the common reference and the HRs, IRRs and crude rate ratios against it | consensus_ref_group.csv, consensus_ref_risk.csv, consensus_ref_crude.csv |
| AFL-02 to AFL-26, RATE-01 to RATE-10 | AFL-only rates and rate ratios, including respiratory rates 0.39 (MD-NoCT) and 0.09 (MD-COPD-CT, MD-COPD-ESI) per 100 person-years | consensus_ref_crude.csv |
| GRP-01 to GRP-15, CI-01 to CI-15, ADJ-01 to ADJ-07, ADJ-ESI-AFL | ratios against MD-COPD-CT, e.g. MD-NoCT AFL-only 1.38 [1.11–1.80] all-cause and 1.42 [1.16–1.82] exacerbations; adjusted 1.33 [1.09–1.71], P = 0.006, and 1.22 [0.98–1.58], P = 0.074 | group_vs_mdcopd.csv |
| MIN-01 to MIN-06, MINOR-01 to MINOR-09, MAJ-01 to MAJ-09, DISC-MINOR, DISC-MINOR-ESI | COPD-minor and COPD-major comparisons with MD-COPD-CT | group_vs_mdcopd.csv, consensus_ref_crude.csv, consensus_ref_lost.csv |
| DEC-01, DEC-02, FEV1-01 to FEV1-08, FEV1-NE, FILL-20 to FILL-22 | FEV₁ decline against the common reference (Table S6) | fev1_decline.csv, fev1_noct_vs_esi.csv |
| RS-01 to RS-04 | random-slope sensitivity: same significance pattern, larger excess decline, COPD-major −12.1 to −13.0 mL/yr (Table S7) | fev1_decline_random_slope.csv |

### Discordant MD-COPD-CT and MD-COPD-ESI classifications (Results; Figure 4; Table S8; Figure S2; Discussion)

| ids | what is pinned | artifact |
|---|---|---|
| DISC2-01 to DISC2-03, NEW-03 to NEW-06 | without airflow limitation: 85 CT-only, 501 ESI-only, 714 Both-COPD | discord_counts.csv |
| NEW-12 to NEW-14, FILL-25 to FILL-29, DISC-BOTH3 | crude rate ratios in each stratum | discord_crude_strata.csv |
| FILL-02 to FILL-19, FILL-23, FILL-24, NEW-07 to NEW-11, DISC-ESIC, DISC-CTONLY | profiles and pairwise tests (Figure S2) | discord_profile_strata.csv, discord_profile_tests.csv |
| DISC-FOUR, DISC-AFLN, DISC-HALF, DISC-KEPT | "four times the size (1,108 versus 275)"; ESI kept more than half (483 of 833) in COPD-major | schema_labels.csv, crossclass.csv |

## Not registered

- The 469 participants without follow-up after the baseline visit (Methods):
  no asset carries the count.
- "R version 4.5.2" (Methods): the Channing run that produced the v8 numbers
  records R 4.5.1 in `PROVENANCE.txt`.
- Rounded restatements of registered values (Abstract "89% versus 85%").

## Open, not yet claimable

- Whether the count threshold of 2 is defensible as a framework modification.
- External validation. Everything here is COPDGene.
