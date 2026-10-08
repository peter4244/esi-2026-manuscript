# Step 5: Methods against code (CT-free MD-COPD, v5)

Date: 2026-10-08. Scope: `ctfree/METHODS.md` (= main Methods of manuscript v5), Supplemental Methods and the table and figure legends in `CT-free MD-COPD supplement draft v5.docx`, and `ctfree/figures/*_legend.md`. These were checked against `ctfree/ESI_ctfree_analysis_2026.9.3.Rmd` (cited as `Rmd:line`), `figures/*.R`, `build_manuscript.py`, `build_supplement.py` and `verify.R`. The only data read were aggregate CSVs in `ctfree/assets/`. Nothing was knit or run.

Every line number below refers to the Rmd unless another file is named.

## 1. Statement-by-statement table

| # | Methods statement (source) | Code location | Verdict | Note |
|---|---|---|---|---|
| 1 | ILD or bronchiectasis excluded (main) | Rmd:195-196 (`is.na(ExclusionaryDisease)`) | match | 10,305, which equals Bhatt's count (`cohort_flow.csv`) |
| 2 | Never-smokers excluded (main) | Rmd:197-198 | match | 10,198 |
| 3 | "without acceptable post-bronchodilator spirometry" excluded (main) | Rmd:199-200 | match, worded loosely | The code only requires non-missing `FEV1_FVC_post`. The count matches Bhatt's (10,132). |
| 4 | "or CT passing quality control" excluded (main) | Rmd:205-210 | partly matches | This step is cohort membership in Bhatt's `Multidimensional_COPD_plus` file. It removes 716 participants for CT QC **and** for incomplete minor-criteria data (Rmd:152-163). The Methods name CT QC only. |
| 5 | 9,240 with MD-COPD-CT classification and baseline post-BD ESI (main) | Rmd:255-262; `cohort_flow.csv` | match | 9,416 → 9,240 |
| 6 | Baseline post-BD ESI used (main) | Rmd:255-257 | match, one omission | Uses visit 1 with `PrePost == 1`. **Several post-BD records per participant are averaged** (`aggregate(..., mean)`), which the Methods do not say. |
| 7 | Mortality n = 9,238 with complete follow-up and covariates (main) | Rmd:776-781; `followup_medians.csv` | match | inner join to vital status, plus complete age/sex/race/smoking/pack-years/BMI |
| 8 | Exacerbation n = 8,177 with LFU data and complete covariates (main) | Rmd:789-793 | match, one omission | The filter also requires `Years_Followed > 0` and non-missing baseline `Exacerbation_Frequency` |
| 9 | MD-COPD-CT classification per the published framework (main) | Rmd:205-207, 236-240 | match (source file, not reimplemented) | Categories come from Bhatt's per-subject file (score 1/2/0, with 0 split by FEV1/FVC). The ≥3-of-5 rule and the minor-criterion logic are **not computed in the code**. The Supplement's "COPDGene files used" section discloses the source. |
| 10 | Major criterion: post-BD FEV1/FVC < 0.70 (main) | Rmd:220 | match | |
| 11 | mMRC ≥ 2 (main) | Rmd:225 | match | |
| 12 | SGRQ total ≥ 25 (main) | Rmd:226 | match | SGRQ only, with no CAT alternative, consistent with the text |
| 13 | Chronic bronchitis (main) | Rmd:227 | match | `Chronic_Bronchitis == 1` |
| 14 | Missing symptom data | Rmd:229-230 | not stated | Missing mMRC/SGRQ/CB is set to "not met". Likely affects few or none, since Bhatt's file required complete minor criteria, but the rule is in the code. |
| 15 | Visual emphysema ≥ mild = score ≥ 2 (supp) | Rmd:223 | match | |
| 16 | Definite wall thickening = score 2 (supp) | Rmd:224 | match | |
| 17 | Missing visual CT (n = 4) treated as not met (supp) | Rmd:229-230; `esi_ct_levels.csv` (n sums to 9,236) | matches the code, but describes the wrong analysis | See Mismatch M5. MD-COPD-CT labels come from Bhatt's file, so this rule does **not** enter the MD-COPD-CT classification. It enters only the AUCs (Fig 1), the discordance profiles (Fig S2) and an internal assertion. |
| 18 | %LAA-950HU by Thirona (main) | Rmd:1886, 2071 (`Insp_LAA950_total_Thirona`) | match | |
| 19 | MD-NoCT: CT criteria removed, 3 symptom criteria kept (main) | Rmd:364, 391 | match | |
| 20 | MD-COPD-ESI: ESI replaces both CT criteria as one criterion (main) | Rmd:399-402 | match | `ESI >= t_low` counts as one criterion |
| 21 | ESI criterion threshold 1.50 (supp Table S2 legend only) | Rmd:448-449, 456-461; PROVENANCE `fitted_S4_t_low=1.500` | match in value, **missing from main Methods** | See M2 |
| 22 | Number of minor criteria derived from concordance, outcome-blind (main) | Rmd:452-466 | match | Only `S2` labels enter `fit3`/`fit4` |
| 23 | Candidate thresholds evaluated by 5×5 CV **using κ, mean per-category sensitivity and macro-F1** (main) | Rmd:574-606 (CV); Rmd:479-506, 515-544 (κ and mean sensitivity) | **mismatch** | See M1. The CV loop fits and scores **macro-F1 only** (plus held-out overall agreement). κ and mean sensitivity are computed on the full cohort only. |
| 24 | Final thresholds selected by macro-F1 (main) | Rmd:452-466 | match | |
| 25 | Thresholds refitted in each training fold; final thresholds fitted on the full cohort (main) | Rmd:587, 463-464 | match | Folds are stratified on the MD-COPD-CT category (Rmd:578-582) and the seed is 20260901 (Rmd:108, 575). Neither is stated. |
| 26 | 5 folds × 5 repeats (main; Table S2 legend) | Rmd:106-107 | match | |
| 27 | Held-out agreement 88.9% / 85.0% vs 89.0% / 85.0% full cohort (Table S2 legend) | Rmd:596-597, 628-631; `schema_fit.csv` | match | 0.8889 / 0.8498 held out, 0.8898 / 0.8498 full cohort |
| 28 | Table S2: "metrics shown for **each candidate rule**" | Rmd:526-531 (sweep) vs Rmd:447-450 (search grid) | **mismatch** | See M2. The search covered k ∈ {2,3,4} × ESI ∈ {0.50, 0.75, …, 4.00} (45 rules) for MD-COPD-ESI and k ∈ {1,2,3} for MD-NoCT. Table S2 shows k = 2 only, at 9 hand-picked ESI values. |
| 29 | Balanced accuracy = mean per-category sensitivity; macro-F1 = mean of the 4 per-category F1 values (Table S2 legend) | Rmd:433-438, 516 | match | |
| 30 | AFL-positive: COPD-major if ≥ 1 minor criterion, else AFL-only (main) | Rmd:378-381, 391, 401 | match | `aflo = (count == 0)` |
| 31 | Cardiac rule: COPD-minor needs both CT criteria (CT) / unavailable (NoCT) / needs the ESI criterion (ESI) (main) | Rmd:369-373, 391, 401 | match | For MD-COPD-CT the code only asserts that the source file obeys the rule |
| 32 | Mortality from follow-up and SSDI; respiratory death by modified TORCH (main) | Rmd:181-182, 779 | match (data source) | `Torch_Group_Basic == 1`. SSDI ascertainment is upstream of the code. Follow-up time is `days_followed / 365.25`. |
| 33 | Exacerbations from LFU (main) | Rmd:790 | match | `Total_Exacerbations`, offset `log(Years_Followed)` |
| 34 | FEV1 decline from spirometry at visits 1-3 (main; Table S6) | Rmd:1497-1503 | match | Participants with visit 1 only are kept: 9,240 in the model, 5,414 with any follow-up (`followup_medians.csv`). Not stated. |
| 35 | BD change in ESI: mean and 95% CI, paired t-test (main) | Rmd:1822-1836 (mean, SD, n only); verify.R:703-704 (t-based CI) | partly matches | The analysis Rmd computes no CI or test. The CI exists only as a check in `verify.R` (mean ± t·SD/√n, which is equivalent to the paired-t CI). This is a reproducibility gap, not a numeric error. |
| 36 | ROC/AUC for visual emphysema and wall thickening, overall and by AFL (main) | Rmd:1710-1761 | match, one omission | AUC is the rank (Mann-Whitney) estimate with no CI. **n = 9,240 in every overall AUC, with the 4 unscored participants counted as criterion-negative** (`esi_ct_auc.csv`). See M5. |
| 37 | McNemar test for overall agreement (main) | Rmd:747-750 | match | Run **without continuity correction** (`correct = FALSE`), which is not stated |
| 38 | Sensitivity and PPV per category (main; Table S3) | Rmd:2128, 2137-2143 | match | |
| 39 | PPV compared by 1,000 paired participant-level bootstrap resamples (main; Table S3) | Rmd:2129-2140 | match | Two-sided P = 2·min(share ≤ 0, share ≥ 0) of the ESI − NoCT PPV difference. The formula is not stated. |
| 40 | Cox for mortality; NB with follow-up offset for exacerbations (main) | Rmd:1221-1224 | match | |
| 41 | Adjusted for age, sex, race, current smoking, pack-years, BMI; NB also for baseline exacerbation frequency (main; Table S5; Fig S1) | Rmd:774, 784-787, 1223-1224 | match | Prior exacerbation frequency enters as a linear numeric term |
| 42 | Common reference = noCOPD under all three classifications, n = 3,856 (main; S4, S5, Fig 3, Fig S1) | Rmd:1192; `consensus_ref_group.csv` | match | |
| 43 | Model sample for the common-reference comparisons | Rmd:1213-1217 | not stated | See M4. Each classification's models contain only the common reference plus that classification's AFL-only/COPD-minor/COPD-major. Participants that classification calls noCOPD who are outside the common reference are dropped (501 under MD-COPD-CT, since 4,357 − 3,856 = 501). |
| 44 | Unadjusted RR = rate per 100 PY in group / rate in reference (main; supp) | Rmd:1251-1258 | match | |
| 45 | Mortality CIs: exact conditional interval for the ratio of two Poisson rates (supp) | Rmd:950-954, 1283-1285 | match | `poisson.test(c(e1, e0), c(t1, t0))`. No interval when the group has 0 events. |
| 46 | Exacerbation CIs: 1,000 participant-level bootstrap resamples, reference rate recomputed each time (supp) | Rmd:1266-1281 | match | Percentile intervals |
| 47 | Comparison with MD-COPD-CT: crude rate ratio and ratio of HRs/IRRs, CIs and P from 1,000 paired bootstrap resamples (main; supp; S4, S5) | Rmd:1402-1481 | match | Percentile CI on the log difference. P = min(1, 2·min(share ≤ 0, share ≥ 0)). Mortality and exacerbation data are resampled separately in each draw. Failed fits become NA (tryCatch) and warnings are suppressed. `B_eff` is asserted ≥ 950 and was 1,000 for every row. |
| 48 | Fewer than 10 events: no CI or P (supp; S4, S5; Fig 3, Fig S1) | Rmd:115, 1235-1236, 1293, 1466; build_supplement.py:352-363; build_manuscript.py:315-320 | match | For comparisons with MD-COPD-CT the rule checks the CT-free group and the corresponding MD-COPD-CT group, as the S4/S5 footnotes say. The common reference has 14 respiratory deaths, so the reference never triggers it. |
| 49 | FEV1 LMM with random intercept; group effect = time × group interaction relative to the common reference (main; Table S6) | Rmd:1544-1565 | match | |
| 50 | FEV1 covariates: height, sex, race, age, smoking status, pack-years, baseline post-BD FEV1 × time (main; Table S6) | Rmd:1497-1503, 1550-1553 | **mismatch in description** | See M3. Age, current smoking and pack-years are **per-visit (time-varying) values** from the long file, not baseline values. Height, sex and race are baseline. Baseline FEV1 enters only as an interaction with time; Table S6 says this, the main Methods do not. |
| 51 | FEV1 P vs common reference (Table S6) | Rmd:1527-1531, 1560-1561 | not stated | P values are lmerTest (Satterthwaite) and CIs are Wald ±1.96·SE |
| 52 | NoCT − ESI FEV1 difference by 1,000 paired bootstrap resamples (main; Table S6) | Rmd:1607-1657 | match | A participant-cluster bootstrap that refits both models per draw, with B_eff = 1,000 for all 3 groups |
| 53 | Discordance by AFL stratum; reference Both-noCOPD (no AFL) or Both-AFL-only (AFL) (main; supp; Fig 4; S7) | Rmd:1852-1857, 1906-1911, 2056-2060 | match | |
| 54 | Fig 4 / S7: exact Poisson CIs for deaths, bootstrap CIs for exacerbations | Rmd:2083-2103 | match | |
| 55 | Wilcoxon for ESI and %LAA-950; Fisher for criterion prevalence (main; Fig S2) | Rmd:2161-2178 | match | Unadjusted, `exact = FALSE` |
| 56 | Fig S2: "Comparisons fixed by the classification definitions are shown without statistical testing" | figures/figureS2_profile.R:56-60 | **mismatch** | See M6. A bracket is suppressed only when both groups are at 0%. Comparisons that the definitions determine are still tested and starred. |
| 57 | Fig S2: bars are means ± SE | Rmd:2055, 2070-2072 | match | |
| 58 | Fig 1: "9,236 participants had a visual score for each criterion" | figure1_esi_ct.R:43-46; `esi_ct_levels.csv` | match for the points; the AUC insets differ | The insets use n = 9,240 (see M5) |
| 59 | Bootstrap B = 1,000 everywhere | Rmd:109 `CRUDE_B`, 1403 `B_GRP`, 1608 `B_FEV`, 2202 `B_DIFF` | match | |
| 60 | Event minimum 10 | Rmd:115 | match | |
| 61 | R version 4.5.2 | PROVENANCE.txt | match | |

## 2. Mismatches ranked by severity

### M1 (moderate). The CV is described as evaluating three metrics; the code evaluates one

**Methods:** "Candidate thresholds were evaluated by five-fold cross-validation repeated five times using Cohen's κ, mean per-category sensitivity, and macro-F1. Final thresholds were selected by macro-F1."

**Code:** inside each training fold, `fit3`/`fit4` (Rmd:452-461) maximize **macro-F1 only**. Each held-out fold is scored by macro-F1, per-category F1 and overall agreement (Rmd:588-604). κ and mean sensitivity are never computed in the CV. They are computed on the **full cohort** only:
- in `objective-selection` (Rmd:479-506), which shows what each objective would pick;
- in `metric-sweep` (Rmd:515-544).

A reader would infer that the three objectives were compared out of sample.

**Suggested wording:** "Candidate thresholds were compared on Cohen's κ, mean per-category sensitivity (balanced accuracy) and macro-F1 in the full cohort, and selected by macro-F1. To assess overfitting, the macro-F1 selection was repeated within each training fold of five-fold cross-validation, stratified on MD-COPD-CT category and repeated five times, and agreement was evaluated in the held-out folds."

### M2 (moderate). The ESI threshold is a fitted parameter, but the main Methods never mention it, and neither the grid nor Table S2 shows the full search

**Main Methods:** "the number of minor criteria required for COPD diagnosis was derived from concordance…" The ESI cutoff (1.50) is never named in the main Methods, although it is fitted by the same procedure (Rmd:448-459).

**Search space in the code:**
- MD-NoCT: k ∈ {1,2,3}.
- MD-COPD-ESI: k ∈ {2,3,4} × ESI threshold ∈ {0.50, 0.75, …, 4.00}, which is 45 candidates. k = 1 is not searched.

**Table S2** (build_supplement.py:170-200, from `metric_sweep`, Rmd:526-531) lists MD-COPD-ESI only at k = 2 and 9 ESI values (0.75-4.00, uneven spacing). Its legend nevertheless says "performance metrics are shown for each candidate rule." The κ-optimal rule (k = 3, ESI ≥ 0.75; `objective_selection.csv`) is not among the rows shown.

**Suggested wording:**
- Main Methods: "…the number of minor criteria required for COPD diagnosis and, for MD-COPD-ESI, the ESI value defining the ESI criterion were derived from concordance with MD-COPD-CT categories without using outcome data. Candidates were 1-3 of 3 criteria for MD-NoCT and 2-4 of 4 criteria with ESI thresholds from 0.50 to 4.00 in steps of 0.25 for MD-COPD-ESI."
- Table S2 legend: "…shown for each MD-NoCT rule and for MD-COPD-ESI rules requiring ≥2 of 4 criteria at selected ESI thresholds; the full search grid is described in the Methods."

### M3 (moderate). The FEV1 model's age, smoking and pack-years are time-varying

**Code:** `fev1_long` (Rmd:1497-1503) carries `age_visit`, `SmokCigNow` and `ATS_PackYears` from each visit's row, and these enter the LMM (Rmd:1550-1553) as per-visit covariates. Height, sex and race are baseline values (Rmd:1505-1509). Per-visit age is nearly collinear with `years_from_baseline` within participant. The group × time terms are still identified, but a reader cannot reproduce the model from "adjusted for … age, smoking status, pack-years."

Further omissions:
- P values are lmerTest/Satterthwaite and CIs are Wald.
- Participants with only visit 1 are included (9,240 in the model, of whom 5,414 have a follow-up visit).
- The main Methods do not say that baseline FEV1 enters only through its interaction with time. Table S6 does say this.

**Suggested wording:** "…adjusted for baseline height, sex and race, for age, current smoking status and pack-years at each visit, and for baseline post-bronchodilator FEV₁ entered as an interaction with follow-up time. All participants with baseline spirometry were included, including those without a follow-up visit." If baseline values were intended, the code is what needs changing, not the text.

### M4 (low-moderate). Who is in the common-reference models is not stated

**Code:** each classification's Cox, NB and LMM models are fitted on the common reference plus **that classification's** AFL-only, COPD-minor and COPD-major (Rmd:1213-1217, 1546). Participants that classification calls noCOPD who are not in the common reference are excluded from its models: 501 under MD-COPD-CT (4,357 − 3,856), and similar numbers under the other two. The Methods imply this but never say it.

**Suggested addition:** "Participants classified as noCOPD by a given classification but not by all three were excluded from that classification's models."

### M5 (low-moderate). The visual-CT missing-data rule is described as part of the MD-COPD-CT classification, but the code does not apply it there; Fig 1 is internally inconsistent

**Supplement:** "For MD-COPD-CT classification, visual emphysema was considered present at … score ≥2 … Participants with missing visual CT scores (n = 4) were considered not to meet the corresponding imaging criterion."

**Code:** MD-COPD-CT categories come from Bhatt's file (Rmd:236-240). How that file treated the 4 unscored participants is not determined by this code. The ≥2 / ==2 / missing-as-not-met rules (Rmd:223-230) feed only three places: the ESI-vs-CT AUCs, the discordance profiles, and the cardiac-rule assertion.

**Inside Fig 1:**
- The legend's "9,236 participants had a visual score" matches the points (`esi_ct_levels.csv`).
- The AUC insets are computed on 9,240, with the 4 unscored participants as criterion-negative (`esi_ct_auc.csv`, Rmd:1717-1758).

**Suggested wording (supplement):** "MD-COPD-CT categories were taken from the source classification (S3). For analyses of the individual imaging criteria (Figure 1 and Supplemental Figure S2), visual emphysema was considered present at mild severity or greater (score ≥2) and airway wall thickening when definite (score 2); the 4 participants without visual scores were counted as not meeting either criterion."

There are two ways to make Fig 1 consistent:
- add "AUCs include the 4 unscored participants as criterion-negative"; or
- exclude them from the AUC, which is a code change.

### M6 (low). Fig S2's legend claims that definitionally fixed comparisons are not tested; the code tests them

**Code:** figureS2_profile.R:56-60 drops a bracket only when both CT-only and ESI-only are at 0%. In the airflow-limitation stratum:
- ESI-only is 0% visual emphysema and 0% wall thickening, which the definitions force: MD-COPD-CT AFL-only means no minor criterion.
- ESI-only is 100% ESI ≥ 1.50 and CT-only is 0%, also forced by the definitions.

These comparisons are still tested and starred (`discord_profile_tests.csv`: ESI P = 4e-45, emphysema P = 1e-43, wall P = 2e-20). In the stratum without airflow limitation, CT-only is 100% for both CT criteria.

**Suggested fix:** either change the figure to omit tests where the definitions force a group's value (0% or 100%, or complete ESI separation), or reword the legend: "Brackets are omitted where neither group meets the criterion; some remaining contrasts, such as ESI and the visual CT criteria in the airflow-limitation stratum, are determined by the classification definitions."

### M7 (low). Omissions a reader would need, with no change in numbers

- **Bootstrap P formula:** two-sided P = 2 × min(proportion of resampled differences ≤ 0, proportion ≥ 0), capped at 1. The resolution is 0.002 at B = 1,000, so "P < 0.005" is the reporting floor. Could go in the supplement's bootstrap paragraph.
- **Failed fits:** resamples where a model fails to fit are dropped, and warnings are suppressed (Rmd:1453-1454). The effective number of resamples was 1,000 in every reported comparison, so a single clause would do.
- **McNemar:** run without continuity correction (Rmd:749-750).
- **Seed and stratification:** CV folds are stratified on MD-COPD-CT category, and the seed for CV and every bootstrap is 20260901.
- **Averaging of replicate ESI:** replicate post-BD ESI values at visit 1 are averaged (Rmd:256-257), and the same applies to the pre-BD values used for the BD change (Rmd:1825).
- **Exacerbation sample:** also requires baseline exacerbation frequency and `Years_Followed > 0` (Rmd:792).
- **Exclusion via the source file:** the step labelled "CT passing quality control" also removed participants with incomplete minor-criteria data in the source classification (Rmd:152-163).
- **BD-change CI:** computed only in `verify.R:703-704`, not in the analysis Rmd. A reproducibility gap, not an error.
- **Missing symptom criteria:** coded as not met (Rmd:229-230).

## 3. What was checked and found consistent

All stated parameters equal the code's current values:
- B = 1,000 for every bootstrap;
- 5 × 5 CV;
- event floor 10;
- FEV1/FVC < 0.70, mMRC ≥ 2, SGRQ ≥ 25, emphysema score ≥ 2, wall score 2, ESI ≥ 1.50;
- k = 2 for both CT-free rules;
- common reference n = 3,856;
- R 4.5.2.

The following match their Methods descriptions:
- the Cox and NB covariate sets;
- the exact conditional Poisson CIs for mortality;
- the bootstrap CIs for exacerbations, with the reference rate recomputed in each resample;
- the paired-bootstrap ratios against MD-COPD-CT;
- the PPV bootstrap;
- the discordance references;
- Wilcoxon and Fisher in the profiles;
- the cardiac-comorbidity rule.

The step-1 to step-4 cohort counts reproduce Bhatt's published counts by assertion (Rmd:269).
