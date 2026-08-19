# METHODS.md — ESI / Bhatt-substitution manuscript (v4)

Last validated: 2026-06-25 against `validation_v4_outline_2026.6.25.md`.

## 1. Data sources

- ESI per visit + pre/post BD: `copdgene_esi_randid_2026.5.17.csv` (Massimo's data, rand-ID-keyed).
- COPDGene Phase 1-3 long phenotype: `COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv`.
- Vital status (Sep 2023): `COPDGene_VitalStatus_SM_NS_Sep23_randid.csv`.
- Cause-of-death adjudication: `COPDGene_Mort_COD_Adj_randid.csv`.
- Prospective exacerbation rate (LFU): `LFU_SidLevel_Comorbd_randid.csv`.

## 2. Cohort construction

- V1 ESI subjects: 10,169 with post-BD ESI computed.
- Bhatt cohort: 9,463 V1 ESI subjects with all six Bhatt criteria non-missing
  (FEV1/FVC_post, CT_Visual_Emph_Severity, CT_Visual_Wall_Thickening,
  MMRCDyspneaScor, SGRQ_scoreTotal, Chronic_Bronchitis).
- Mortality cohort: 10,105 V1 ESI subjects with vital-status records (or 9,400
  for Bhatt analyses).
- Exacerbation cohort: 8,898 V1 ESI subjects with LFU exacerbation data and
  Years_Followed > 0.
- Spectrum stratum: derived from `finalgold_visit` ∈ {-2, -1, 0, 1, 2, 3, 4} →
  {Never, PRISm, GOLD0, GOLD1, GOLD2, GOLD3, GOLD4}; GOLD0 is the reference
  level in multivariable models.

## 3. Bhatt 2025 schema

Major criterion: post-BD FEV1/FVC < 0.70.
Five minor criteria:
1. Visual emphysema: CT_Visual_Emph_Severity ≥ 1 (≥ mild, Fleischner)
2. Bronchial wall thickening: CT_Visual_Wall_Thickening == 2 (definite, Fleischner)
3. Dyspnea: MMRCDyspneaScor ≥ 2
4. Quality of life: SGRQ_scoreTotal ≥ 25
5. Chronic bronchitis: Chronic_Bronchitis == 1

Categories:
- COPD-major: major + ≥ 1 minor
- COPD-minor: !major + ≥ 3 minors
- AFL-only-NoCOPD: major + 0 minors (excluded from COPD by Bhatt)
- noCOPD: !major + < 3 minors

## 4. ESI substitution rule

Replace the two CT-based minor criteria with one ESI-derived score:
- ESI < 1.0 → 0 minor criteria contributed
- 1.0 ≤ ESI < 2.5 → 1 minor criterion contributed
- ESI ≥ 2.5 → 2 minor criteria contributed

The three symptom criteria (dyspnea, SGRQ, chronic bronchitis) are unchanged.
Final minor-count = ESI score + dysp_yn + qol_yn + cb_yn (out of 5).
Original COPD-minor threshold of ≥ 3 of 5 is preserved.

Threshold-selection rationale: ten variants evaluated (4-criterion and
5-criterion families) for agreement with the full Bhatt schema (κ).
Selected T_low = 1.0 / T_high = 2.5 yields κ = 0.82 with balanced
sensitivity (88%) and specificity (94%) and clinically meaningful cut-offs.

## 5. Outcomes

### 5.1 All-cause mortality
Cox proportional-hazards model with time = days_followed / 365.25 and
event = vital_status (1 = death).  Covariates: age at visit, sex, race,
current smoking (SmokCigNow), pack-years (ATS_PackYears), BMI; categorical
predictor for Bhatt / ESI-substituted / discordance grouping.

### 5.2 Cause-specific mortality
Cause-specific Cox: event = vital_status == 1 & CCOD_<cause> == 1; other
deaths censored at death date.  Causes analysed: CVD, Cancer, Other (broad);
OthCardiac, MI, LungCancer, OthCancer, OthDis, Accidents/suicide, Sepsis,
Renal (specific subcauses with ≥ 100 events).

### 5.3 Exacerbations
Negative-binomial regression on Total_Exacerbations with offset
log(Years_Followed); same covariate set as mortality.  FEV1/FVC enters at
per-0.1-unit scaling for clinical interpretability.  Sensitivity:
Total_Severe_Exacer.

### 5.4 Longitudinal FEV1 decline
Linear mixed-effects model: FEV1_post (mL) = years_from_baseline ×
(ESI_baseline + FEV1_FVC_baseline) + standard covariates +
(1 | rand_id).  Covariates: baseline stratum, height, sex, race,
time-varying age, current smoking, pack-years.  Per-stratum models drop
stratum_baseline (the stratification variable).

## 6. Subgroup definitions

1. By classification (head-to-head Bhatt vs ESI-substituted):
   noCOPD (reference), AFL-only-NoCOPD, COPD-minor, COPD-major.

2. By cross-tabulation (preserved spirometry only, FEV1/FVC ≥ 0.70):
   Both-noCOPD (reference), Both-COPD, Bhatt-only-COPD, ESI-only-COPD.

3. Secondary GOLD-stratified (continuous ESI vs continuous FEV1/FVC):
   Never, GOLD0 (reference), PRISm, GOLD1-4.

## 7. Software and reproducibility

All analyses in R 4.5.2 with packages survival, MASS, lme4, lmerTest, dplyr,
tidyr, ggplot2.

**Single canonical analysis script** (as of 2026-08-18):
`~/claude_projects/projects/ESI_2024/esi_manuscript_analysis_2026.7.17.Rmd`.
It writes every result CSV consumed by the manuscript and supplement into
`manuscript_assets/`. The earlier per-topic `build_*.R` / `validation_*.R`
scripts were superseded by it and were deleted on 2026-08-18 (recoverable from
git history); they still used the retired CCOD cause-of-death definition and
would have produced numbers contradicting the paper if re-run.

The manuscript and supplement .docx are produced separately:
- Supplement — `build_supplement.py` renders each `tables/supp/s<N>_*.py`
  module with its sibling `_legend.md`.
- Manuscript — the .docx is the source of truth and is edited directly;
  `build_manuscript.py` is retired and guarded against being run.

### Cause of death

Cause-specific mortality uses the TORCH adjudicated **underlying** cause
(`Torch_Group_Basic`), which is mutually exclusive:
Respiratory 704, Cardiovascular 391, Cancer 497, Other 385, Unknown 124
(sum = 2,101 adjudicated deaths). Unknown deaths are an event for no cause and
are therefore censored in every cause-specific model, as any competing death is.

This replaced the `CCOD_*` indicators on 2026-08-18. Those flag whether a cause
*contributed* to death and are not mutually exclusive — 947 of 2,101 deaths
carried more than one (358 were flagged both cardiovascular and respiratory) —
which is incompatible with the competing-risks framing these models use.
