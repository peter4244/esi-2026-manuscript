# Claims — CT-free MD-COPD paper

Claim tracking for this paper starts here. It shares no entries with the v15
manuscript's registry: that registry is pinned to a document whose central
claim ("the ESI-based framework reproduced the CT-based framework") is not the
claim of this paper, and 180 of its 241 entries verify tables that no longer
exist. The v15 registry stays in the repository, frozen, so the two can be
diffed at the end and nothing is dropped by accident rather than on purpose.

Every claim below names the artifact and field that produces it. `ctfree/verify.R`
evaluates each against `ctfree/assets/` as it exists on disk now and fails
loudly on drift. Nothing here may be quoted in prose without an entry.

## Scope of this paper

CT is often unavailable. MD-COPD is defined partly by CT findings. Can the
classification, and the benefit it carries over the fixed ratio, be preserved
using spirometry and symptoms alone?

Four schemas, same 9,240 participants, same covariates:

S1 to S4 are internal identifiers used in the artifacts and in the field
expressions below. The manuscript names them as follows, and those names are
what appear in the prose, tables and figures.

| artifact id | manuscript name | definition |
|---|---|---|
| S1 | **Fixed ratio** | FEV1/FVC < 0.70 alone |
| S2 | **MD-COPD** | the published CT-based framework; the reference |
| S3 | **NoCT-MD-COPD** | CT criteria removed, count threshold refitted |
| S4 | **ESI-MD-COPD** | CT criteria replaced by ESI, both thresholds refitted |

## Standing methodological decisions

- **Objective for fitting S3 and S4: macro-averaged F1** across the four
  categories. Symmetric across categories, but balancing precision against
  recall within each. Cohen's kappa, mean recall and the C-index were all
  tested and all select a schema that labels 1,119 participants
  AFL-only-noCOPD to capture the 170 real ones, because none penalizes
  over-calling a small category. That group carries 6.6x respiratory
  mortality, so the label is false and the metric that prefers it is wrong for
  this problem.
- **Fitting is outcome-blind.** Thresholds are fitted only against S2's
  labels. No mortality or exacerbation data enters selection, so the risk
  profiles are an independent check rather than a restatement of the fit.
- **S3 and S4 are fitted by the same objective over their full parameter
  space**, including the count threshold. S3 was allowed to move from 3 to 2;
  S4 must be allowed the same or the comparison is rigged.
- **The count threshold of 2 departs from Bhatt's rule of 3** and has to be
  argued in the paper, not slipped in. It applies to S3 and S4 equally.

## Claims

### C-COHORT — cohort

| id | claim | artifact | field |
|---|---|---|---|
| COH-01 | analytic cohort n = 9,240 | cohort.txt | n_cohort |
| COH-02 | 4,113 have airflow limitation | cohort.txt | n_afl |
| COH-03 | 5,289 do not | cohort.txt | n_noafl |

### C-GATE — MD-COPD improves on the fixed ratio

The two models are nested: fixed-ratio COPD is exactly AFL-only-noCOPD plus
COPD-major, so this is a likelihood ratio test on 2 df.

| id | claim | artifact | field |
|---|---|---|---|
| GATE-01 | all-cause mortality, LR chi-square 110.2 on 2 df | gate_fixedratio.csv | lrt_chisq |
| GATE-02 | respiratory mortality, LR chi-square 53.9 | gate_fixedratio.csv | lrt_chisq |
| GATE-03 | exacerbations, LR chi-square 162.4 | gate_fixedratio.csv | lrt_chisq |
| GATE-04 | C-index gain is small, +0.009 all-cause | gate_fixedratio.csv | c_mdcopd - c_fixedratio |

**Not claimed:** that MD-COPD substantially improves prediction. The C-index
gains are +0.009 and +0.007. The claim is correct reclassification of an
identifiable minority.

### C-FIT — fitting the CT-free schemas

FIT-06 is provenance for why the thresholds moved, not a manuscript claim. The
v15 draft rule is an unpublished internal comparator and does not appear in
any table.

| id | claim | artifact | field |
|---|---|---|---|
| FIT-01 | S3 fitted rule is >= 2 of 3 symptom criteria | schema_fit.csv | k, schema S3 |
| FIT-02 | S4 fitted rule is >= 2 of 4, ESI threshold 1.25 | schema_fit.csv | k, t_low |
| FIT-03 | S4's second ESI threshold lands at 7.0, i.e. inert | schema_fit.csv | t_high |
| FIT-04 | held-out macro-F1: S4 0.753 vs S3 0.720 | schema_fit.csv | macroF1_heldout |
| FIT-05 | S4 beats S3 by +0.033 (+0.016 to +0.050) | schema_fit_cv_diff.csv | diff_mean, diff_lo, diff_hi |
| FIT-06 | *(internal, not printed)* the v15 draft rule scores 0.675 on the same folds | schema_fit.csv | macroF1_heldout |

### C-LABEL — how each schema labels the cohort

| id | claim | artifact | field |
|---|---|---|---|
| LAB-01 | S2 reference counts 4,357 / 275 / 799 / 3,809 | schema_labels.csv | n |
| LAB-02 | S3 loses 833 COPD-major, calling 2,976 | schema_labels.csv | n |
| LAB-03 | S4 holds COPD-major at 3,803 | schema_labels.csv | n |
| LAB-04 | S3 calls 1,119 AFL-only against the reference's 170 | schema_labels.csv | n |

### C-RISK — do the labels mean what they say

The load-bearing claim of the paper. AFL-only-noCOPD exists to correct the
fixed ratio's over-diagnosis, so that category must be genuinely low risk or
the schema is mislabelling people.

| id | claim | artifact | field |
|---|---|---|---|
| RISK-01 | S2 AFL-only carries no excess risk, all-cause HR 0.90 | schema_risk.csv | all_HR |
| RISK-02 | S3 AFL-only carries 6.6x respiratory mortality | schema_risk.csv | resp_HR |
| RISK-03 | S3 AFL-only carries 1.8x exacerbations | schema_risk.csv | exac_IRR |
| RISK-04 | S4 AFL-only all-cause HR 0.94, interval crosses 1 | schema_risk.csv | all_HR, all_UCI |
| RISK-05 | S4 COPD-minor HR 1.94 matches S2's 1.91 | schema_risk.csv | all_HR |
| RISK-06 | S4 COPD-major HR 2.76 against S2's 2.59 | schema_risk.csv | all_HR |

### C-DISC — discrimination

| id | claim | artifact | field |
|---|---|---|---|
| DISC-01 | S3 has the best all-cause C-index, 0.722 | schema_discrimination.csv | c_allcause |
| DISC-02 | S4 discriminates slightly better than S2, 0.708 vs 0.703 | schema_discrimination.csv | c_allcause |
| DISC-03 | same ordering on respiratory, S4 0.858 vs S2 0.853 | schema_discrimination.csv | c_resp |

**Claimed against ourselves:** S3 wins every discrimination metric. The paper
must state this plainly and answer it with RISK-02 and RISK-03 rather than
omitting it.

## Open, not yet claimable

- S4's AFL-only respiratory HR is 3.02, point estimate above S2's 1.42 though
  the interval crosses 1. Cleaner than S3, not as clean as CT. Needs stating.
- Whether the count threshold of 2 is defensible as a framework modification.
- External validation. Everything here is COPDGene.
