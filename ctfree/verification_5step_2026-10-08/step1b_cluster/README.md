# Step 1b: independent recomputation on Channing

Part of the five-step pre-submission verification (step 1, factual accuracy) of the CT-free MD-COPD
manuscript. `recompute_ctfree.R` re-derives the key numbers from the six COPDGene input files without
sourcing or copying the analysis code (`ctfree/ESI_ctfree_analysis_2026.9.3.Rmd`). It was written from
`ctfree/METHODS.md` and the rules stated in the Rmd. The goal is to catch errors in the analysis's data
handling. A shared misreading of a definition would not be caught; the ambiguities below list where that
could happen.

COPDGene participant data are used only on Channing. On the laptop this folder has been run only on
synthetic data.

## Files

| file | role |
|---|---|
| `recompute_ctfree.R` | the cluster script |
| `make_synthetic.R` | writes fake inputs shaped like the real files, plus a `config_paths.R` for them |
| `synthetic_inputs/` | output of `make_synthetic.R` (random values, no real data) |
| `synthetic_output/` | `recompute_ctfree.R` run on the synthetic inputs (24 `rc_*.csv`) |
| `synthetic_recompute_log.txt`, `synthetic_compare_log.txt` | logs of the synthetic test |
| `compare_recompute.R` | laptop side: compares a returned `rc_*` folder against the analysis tables |

## Running

On Channing, from the root of the reproduction clone (where `config_paths.R` is):

```
LC_ALL=en_US.UTF-8 /app/R-4.5.1@i86-rhel9.0/bin/Rscript <path>/recompute_ctfree.R <outdir>
```

The script creates `<outdir>`, refuses to start if it already holds any `rc_*.csv`, writes only aggregate
CSVs, and logs to stdout. It needs base R plus `survival` and `MASS`, which are recommended packages that
ship with R. If `pROC` is installed it is used for a second AUC value; otherwise that column is NA. There is
no bootstrap. On the synthetic data (3,000 people) it runs in about 1.5 s. On the real data, reading the
1,032-column phenotype file should take the most time (only 24 of its columns are kept), and the 12 Cox
and 12 negative-binomial fits should take seconds. An optional second argument names a different config
file.

On the laptop, after the folder comes back:

```
Rscript compare_recompute.R <returned_outdir> [--write comparison.csv]
```

By default it compares against `ctfree/assets/` and also against the cluster run's copy,
`notes/from_cluster/esi_ctfree/cluster_assets_6116301/`. The cluster's phenotype file has no
ILD/bronchiectasis rows, so the first cohort-flow step should be 10,305 against the cluster copy and will
differ from the laptop's 10,371. That difference is expected.

Tolerances: counts must match exactly; deterministic real numbers (rates, means, AUC, medians) to a
relative 1e-6; Cox and negative-binomial estimates to a relative 1e-4; Table S1 strings to half a unit of
the last printed digit. Rows where both sides are NA (exacerbation bootstrap CIs, which are not
recomputed) are counted as agreeing.

## What is recomputed, and which field it should equal

| output `rc_*.csv` | quantity | compare to (asset: field) |
|---|---|---|
| `cohort_flow` | n after each exclusion step | `cohort_flow.csv`: n (9,240 final) |
| `mdcopd_validation` | MD-COPD-CT category counts on the 9,416, before the ESI requirement | `mdcopd_validation.csv`: ours (4,439 / 282 / 811 / 3,884) |
| `schema_labels` | category counts, S1 to S4 | `schema_labels.csv`: n |
| `crossclass` | S3 x S2 and S4 x S2 4x4 tables (rows = modified, cols = MD-COPD-CT) | `crossclass.csv`: n |
| `agreement` | per category: n in reference, n assigned, n agreeing, sensitivity %, PPV %, F1; plus an `overall` row (agreement %) | `agreement_by_group.csv`: recall_*, pct_*, n_*, agree_*; `f1_by_category.csv`: f1_*; Results 89.0% / 85.0% |
| `accuracy_test` | correct counts, discordant pairs, McNemar chi-square (no continuity correction) | `accuracy_test.csv` |
| `reclassification` | COPD-major to AFL-only (833 / 350) and the other moves | `reclassification.csv` |
| `fit_selected`, `fit_grid` | in-sample macro-F1 re-fit of k (S3) and k, ESI threshold (S4) over the Rmd's grid | `schema_fit.csv`: k, t_low, macroF1_insample; PROVENANCE k3=2, k4=2, t=1.50 |
| `bronchodilator_delta_esi` | paired post minus pre ESI at visit 1: n, mean, SD, t-test CI | `bronchodilator_delta_esi.csv` |
| `supp_baseline` | Table S1 by stratum (PRISm, GOLD 0 to 4, overall): n, age, % female, % current smoker, pack-years, BMI, FEV1 %pred, FEV1/FVC, ESI, % mMRC>=2, % SGRQ>=25, % CB, unformatted | `supp_baseline.csv` (formatted strings, parsed) |
| `esi_ct_levels` | n and mean ESI at each visual emphysema level (0 to 5) and wall-thickening level (0 to 2), plus a "missing" row | `esi_ct_levels.csv` |
| `esi_ct_auc` | AUC of ESI (and of -FEV1/FVC) for emphysema >= mild and definite wall thickening; overall, airflow limitation, preserved spirometry; two missing-data handlings | `esi_ct_auc.csv` (the `missing_as_negative` rows) |
| `consensus_ref_group` | the common reference (noCOPD under S2, S3 and S4): n, deaths, respiratory deaths, exacerbations, person-years, years followed | `consensus_ref_group.csv` (n 3,856) |
| `consensus_ref_crude` | per classification x category x outcome (all, resp, exac): events, time, rate per 100 py (exac: per 100 years followed), rate ratio vs reference, exact Poisson CI for all/resp | `consensus_ref_crude.csv`: events, rate_100py, rr, lo, hi (exac CIs were bootstrapped and are not recomputed) |
| `consensus_ref_risk` | adjusted all-cause and respiratory HR (Cox) and exacerbation IRR (negative binomial, log follow-up offset), each with a 95% Wald CI; one model per classification: reference plus the three categories | `consensus_ref_risk.csv` |
| `consensus_ref_risk_pairwise` | the same, with one model per category (reference plus that category alone) | none; a sensitivity check of the model specification |
| `followup_medians` | median and IQR follow-up: mortality, exacerbations, FEV1 decline (everyone; those with a follow-up visit) | `followup_medians.csv` |
| `diagnostics` | key/value data checks: duplicate ids per file, missing counts per criterion, ESI means by PrePost code, deaths without a TORCH code, analysis-set sizes (mort_n, exac_n) | METHODS.md counts 9,238 and 8,177 (checked by `compare_recompute.R`) |
| `mdcopd_score_by_afl`, `mdcopd_subtype_by_score` | Bhatt's score (and subtype label, if present) against FEV1/FVC < 0.70 | none; consistency check |
| `mdcopd_rebuilt_vs_file` | MD-COPD-CT rebuilt from the five minor criteria (>= 3, cardiac rule) against Bhatt's file | none; tests the criterion coding (emphysema >= 2, wall == 2) |
| `torch_codes_among_deaths`, `vital_status_vs_cod_file` | TORCH group counts among deaths; vital status in the VS file against the COD file | none; checks the respiratory-death coding |

## Definitions taken from the Rmd, and where I am unsure

These are the places where the recomputation follows the Rmd because METHODS.md does not settle the
question. If one of them is wrong, the recomputation shares the error and will not catch it.

1. **Missing criteria count as "not met".** The Rmd sets a missing visual CT score, mMRC, SGRQ or
   chronic bronchitis to FALSE, and the recomputation does the same. METHODS.md does not say. This affects
   S3 and S4 directly. It also means the AUC denominators include participants with no visual CT read,
   counted as negatives: `esi_ct_auc.csv` has n = 9,240 for every row, the whole cohort. The recomputation
   reports a complete-case AUC next to it, and `rc_diagnostics` gives the number missing per criterion. If
   any are missing, the published AUCs and prevalences include them as negatives, which I think is not
   what a reader would assume.
2. **Visual scale coding.** Emphysema "at least mild" is taken as `CT_Visual_Emph_Severity >= 2` (0 none,
   1 trace, 2 mild, per the Rmd's comment), and definite wall thickening as `CT_Visual_Wall_Thickening == 2`
   (0 absent, 1 borderline, 2 definite). I have not seen the data dictionary. `rc_mdcopd_rebuilt_vs_file`
   tests this coding: if it is right, rebuilding MD-COPD-CT from the criteria should agree closely with
   Bhatt's file.
3. **Bhatt's score coding.** Score 1 is taken as COPD-major, 2 as COPD-minor, and 0 is split into AFL-only
   or noCOPD by FEV1/FVC < 0.70. `rc_mdcopd_score_by_afl` shows whether every score-1 participant has
   airflow limitation and every score-2 participant does not.
4. **Post-bronchodilator ESI is `PrePost == 1`.** When a participant has more than one visit-1 post row,
   their values are averaged. `rc_diagnostics` gives mean ESI by PrePost code (post should be lower), the
   number of participants with several post rows, and the largest difference between the mean and the
   first value.
5. **Respiratory death is `Torch_Group_Basic == 1` among those with `vital_status == 1`.** I am inferring
   this from the code; I have not checked it against the COD data dictionary. `rc_torch_codes_among_deaths`
   gives the counts so it can be checked.
6. **The mortality set has no follow-up filter.** It is the cohort inner-joined to the vital-status file
   with complete covariates (age, sex, race, current smoking, pack-years, BMI). METHODS.md says "complete
   follow-up and covariates", but no filter removes missing or zero `days_followed`. `rc_diagnostics`
   counts such rows. If there are none, the wording is harmless.
7. **The exacerbation set** requires non-missing `Total_Exacerbations`, `Years_Followed > 0`, non-missing
   visit-1 `Exacerbation_Frequency` (entered as a linear term) and complete covariates. Race, sex and
   current smoking enter as factors, using the file's codes unchanged.
8. **Common-reference models.** The Rmd fits one model per classification containing the reference and all
   three categories, so the covariate coefficients are estimated on the whole set. METHODS.md ("compared
   with a common reference group") could also be read as separate models per category.
   `rc_consensus_ref_risk` follows the Rmd; `rc_consensus_ref_risk_pairwise` shows how much the
   alternative reading would change the estimates.
9. **Cardiac rule.** It applies only to the COPD-minor pathway. Under MD-COPD-ESI, a cardiac participant
   needs the ESI criterion plus at least one symptom criterion (count >= 2 with ESI met). Under MD-NoCT
   the pathway is closed. This matches METHODS.md. In all three classifications, airflow limitation plus
   any one criterion (ESI included for S4) gives COPD-major, whatever the cardiac status.
10. **Never-smoker exclusion uses the `cohort` text "Never smoked".** In the Rmd, a participant whose
   `cohort` is missing would produce an all-NA row. The recomputation keeps them and
   `rc_diagnostics: v1_cohort_NA` counts them. A non-zero count would point to a defect in the Rmd.
11. **Follow-up for FEV1 decline** is the last `years_from_baseline` among visits 1 to 3 with
   post-bronchodilator FEV1. Rows also need visit-level age and smoking status, baseline height, and a
   visit-1 FEV1. This is reconstructed from the decline model's data filter. METHODS.md does not define it.
12. **Exacerbation "per 100 person-years"** is per 100 years followed in the LFU program
   (`Years_Followed`), not per 100 person-years of vital-status follow-up.

## The synthetic test

`make_synthetic.R` writes 3,000 fake participants. Each file mimics the real format: the ESI file is
comma-separated with a UTF-8 BOM and two trailing empty columns; the phenotype, COD and LFU files are
tab-separated; the VS and MD-COPD files are comma-separated. The fake data also include ILD rows,
never-smokers, missing spirometry, missing visual CT, duplicate ESI rows, and ids absent from some files.
`recompute_ctfree.R` ran end to end on it and wrote 24 files; it also ran under `LC_ALL=C`, where the BOM
is still stripped; and a second run into the same folder was refused. `compare_recompute.R` then ran
against both asset folders. Every key lined up, and the values differ, as they must on random data.

This tests my code, not the science. Whether the numbers agree is known only once the script has been
run on Channing and the result compared here.
