# Step 2: Result correctness (CT-free MD-COPD, v5)

Date: 2026-10-08. Scope: the producing code (`ESI_ctfree_analysis_2026.9.3.Rmd`, `figures/*.R`), the aggregate assets (`assets/*.csv`), the cluster rerun (`notes/from_cluster/esi_ctfree/cluster_assets_6116301/`), and the v5 manuscript and supplement (text pulled with python-docx). I did not open any participant-level data. Checks that need participant data are written up as cluster scripts in `step2_cluster_checks/`.

Severity scale: **Major** means a published statement is wrong or unsupported by the paper's own data. **Moderate** means an inference is weaker than stated, or a model choice could change a reported significance call. **Minor** means a code or artifact problem that does not reach the documents, or a cosmetic issue.

---

## Findings, by severity

### MAJOR

**M1. Figure S2 tests differences that the classification definitions force, and the Results report them as findings. The legend says the opposite.**

- Location: `figures/figureS2_profile.R` (bracket logic), Figure S2 legend, Results paragraph "Clinical, physiological, and CT characteristics…".
- The script only drops a bracket when *both* groups are at 0% (`both_zero`). The legend says "Comparisons fixed by the classification definitions are shown without statistical testing." That is false for five of the brackets drawn:
  - **Airflow limitation, ESI (\*\*\*).** Every CT-only participant has ESI < 1.50 and every ESI-only participant has ESI ≥ 1.50. This follows from the definitions:
    - CT-only = MD-COPD-CT major and MD-COPD-ESI AFL-only, which requires ESI < 1.50 and no symptom criterion.
    - ESI-only = MD-COPD-CT AFL-only and MD-COPD-ESI major. With no symptoms, ESI ≥ 1.50 is the only way to qualify.
    - `discord_profile_strata.csv` confirms it: `pct_meets_esi` is 0 and 100.
  - **Airflow limitation, visual emphysema (\*\*\*) and wall thickening (\*\*\*).** ESI-only is MD-COPD-CT AFL-only, so it has 0% of both by definition. CT-only must have at least one.
  - **Without airflow limitation, visual emphysema (\*\*\*) and wall thickening (\*\*\*).** CT-only is 100% for both by definition:
    - It has ESI < 1.50, and the only way to reach ≥3 of 5 MD-COPD-CT criteria while staying below 2 of 4 MD-COPD-ESI criteria is with both CT criteria.
    - Cardiac participants also need both CT criteria under MD-COPD-CT.
    - The asset shows 100.0 and 100.0.
- Two Results sentences restate these definitions as observations:
  - "visual emphysema and definite airway wall thickening were more frequent in the MD-COPD-CT-only group" (without airflow limitation)
  - "ESI was higher and visual emphysema less frequent in the MD-COPD-ESI-only group" (with airflow limitation)
- Separate error in the same paragraph: "symptom criteria were more frequent in the MD-COPD-ESI-only group" is false for chronic bronchitis. CT-only is 28.2% and ESI-only is 15.0% (Fisher P = 0.004, the opposite direction). The statement holds only for mMRC and SGRQ.
- Consequence: the reader is shown tests of tautologies. Fix:
  - Suppress the five brackets.
  - Rewrite the two sentences as descriptions of the definitions.
  - Restrict the symptom statement to mMRC and SGRQ. In the airflow-limitation stratum, %LAA-950HU (ns) is the only non-definitional CT-only vs ESI-only comparison left.

**M2. "Information beyond conventional spirometric indices" is contradicted by the paper's own data.**

- Location: At a Glance ("…clinically relevant physiological information… beyond conventional spirometric indices"), Conclusion paragraph (same sentence), Abstract ("ESI discriminated visual emphysema and airway wall thickening with AUCs of 0.78 and 0.80"), Figure 1.
- Evidence from `esi_ct_auc.csv`, which the Rmd computes but the paper never reports. FEV1/FVC discriminates both CT criteria at least as well as ESI in every stratum:

  | stratum | criterion | AUC ESI | AUC FEV1/FVC |
  |---|---|---|---|
  | All | emphysema | 0.780 | 0.824 |
  | All | wall | 0.804 | 0.817 |
  | AFL | emphysema | 0.754 | 0.780 |
  | AFL | wall | 0.746 | 0.745 |
  | Preserved | emphysema | 0.557 | 0.673 |
  | Preserved | wall | 0.605 | 0.643 |

- `continuous_esi_mortality.csv`: in a model that already contains FEV1/FVC and GOLD stratum, ESI does not add to respiratory mortality (HR 0.97 [0.89–1.05], LR P = 0.44). For all-cause mortality it adds a little (HR 1.07, P = 0.002).
- The design has no comparator that replaces CT with a *conventional* spirometric criterion fitted the same way. MD-NoCT (CT dropped, nothing put in) is the only control. Within airflow limitation, ESI ≥ 1.50 behaves largely as a severity marker: mean ESI is 1.44 in GOLD 1 and 2.18 in GOLD 2. An FEV1/FVC or FEV1 %pred threshold may therefore rescue the same CT-only COPD-major participants.
- Consequence: the data support "ESI recovers part of what MD-NoCT loses". They do not support "ESI carries information beyond conventional spirometry", and the AUC comparison points against it. Two options:
  - Run cluster check **C2**: refit the classification with FEV1/FVC or FEV1 %pred in place of ESI, then compare agreement and AFL-only risk.
  - Or remove the "beyond conventional spirometric indices" claims and report the FEV1/FVC AUCs next to the ESI AUCs.

**M3 (unverified, needs cluster check C1). Respiratory deaths are probably under-ascertained, because deaths without an adjudicated cause are counted as non-respiratory.**

- Location: Rmd `ingest-and-cohort` (`UCD_Resp`) and `outcome-data` (`ev_resp`). Affects every respiratory-mortality number: Tables S4 and S5, Figure 3, Figure S1, and the Results respiratory rates (0.30 and 0.07 per 100 person-years).
- Evidence:
  - The earlier analysis log (`esi_manuscript_analysis_2026.7.17_noILD.md`, lines 150–177) documents Torch_Group_Basic code 1 as Respiratory, so the event definition itself is right. The same log records **2,101 adjudicated deaths in the whole COD file**.
  - This cohort has **2,581 deaths** in the vital-status file (`schema_binary.csv`: 1,734 + 847). So at least about 480 deaths (≥19%) have no adjudicated cause. Code 5 ("unknown", 124 in that file) adds more.
  - The vital-status file (Sep 2023) is probably newer than the adjudication. If so, the missing causes sit in later follow-up.
  - Respiratory causes are 2.4% of deaths in the MD-COPD-CT noCOPD group (16/667) and 23% overall.
  - The common reference has 14 respiratory deaths, which is why the COPD-major HRs (33–42) and crude ratios (50–63) are so large and so wide.
- Consequence: absolute respiratory rates are biased low. HRs are biased in an unknown direction if adjudication coverage differs by group. Mortality is the most comorbidity-heavy outcome, so coverage could well differ by group. Run C1 before submission. If coverage is incomplete, either censor follow-up at the adjudication cutoff or state the limitation.

### MODERATE

**D1. In preserved spirometry, ESI barely drives the "ESI-only-COPD" group; the lower criterion count does.**

- Location: Table S7, Figure 4, Figure S2, Results "Discordant…" and the Discussion's reading of the COPD-minor pathway.
- Evidence (`discord_profile_strata.csv`):
  - Only 9.8% of the 501 ESI-only-COPD participants (about 49) meet ESI ≥ 1.50, against 84% mMRC ≥ 2 and 94% SGRQ ≥ 25.
  - Among Both-COPD, 6.6% meet ESI.
  - By construction MD-NoCT COPD-minor is a subset of MD-COPD-ESI COPD-minor (`s3` vs `s4`: ≥2 of 3 symptoms implies ≥2 of 4). MD-COPD-ESI adds only 41 COPD-minor participants (1,215 vs 1,174).
  - So without airflow limitation, about 92% of MD-COPD-ESI COPD-minor diagnoses come from two symptom criteria. The discordance is mostly "≥2 of 4" against "≥3 of 5".
- Consequence: the label "ESI-only" and the excess risk of this group (all-cause 1.39, exacerbations 2.44) credit ESI with what the lowered count threshold does. The Discussion already says ESI is "less effective" here. It should say *why*: in this stratum ESI almost never reaches 1.50. Consider renaming the group (for example "MD-COPD-ESI-only") and adding the ESI-met share to Figure S2. The share is already in the asset (`pct_meets_esi`).

**D2. FEV1-decline inference rests on a random-intercept-only model and on contrasts of significance.**

- Location: `fev1-decline` chunk, Table S6, Results ("…in AFL-only it was observed with MD-NoCT and MD-COPD-ESI but not with MD-COPD-CT"), Discussion ("Even the MD-COPD-ESI AFL-only group… had faster FEV₁ decline… whereas MD-COPD-CT AFL-only did not").
- Problem 1: without a random slope, the group-by-time SEs assume no between-person variation in slope. That usually makes them too narrow. The model is documented (Methods, Table S6), but it supports the significance calls the text relies on.
- Problem 2: MD-COPD-CT AFL-only at −2.7 [−7.0, 1.6] and MD-COPD-ESI AFL-only at −4.3 [−7.7, −0.9] overlap almost completely. No test compares them; the paired bootstrap covers only NoCT vs ESI. "Significant vs not significant" is not a demonstrated difference. The same applies to COPD-minor: CT −4.5 vs ESI −0.1.
- Arithmetic check: 714 of the 1,215 ESI COPD-minor participants are CT COPD-minor, yet the two groups' slopes are −4.5 and −0.1. That requires either very fast decline in the 85 CT-only participants or slower-than-reference decline in the 501 ESI-only participants. The text should name which. Cluster check **C3** fits a random-slope sensitivity model and splits the COPD-minor groups.
- Smaller point for Step 3: "9.7 years for lung function decline" is the median among the 5,414 participants with a follow-up visit. Over all 9,240 in the model it is 5.1 years (`followup_medians.csv`).

**D3. "Neither discordant group had significantly increased…" (airflow limitation) is a non-significant result in a small comparison.**

- The reference is 193 participants with 34 deaths. CT-only 1.30 [0.86–2.01] and ESI-only 1.14 [0.59–2.12] (16 deaths) cannot exclude a doubling.
- Recommend wording that does not read as equivalence. The same caution applies to "MD-COPD-ESI AFL-only did not differ significantly from MD-COPD-CT" (1.14 [0.91–1.44]).

**D4. Methods overstate the cross-validation.**

- Methods say candidate thresholds "were evaluated by five-fold cross-validation repeated five times using Cohen's κ, mean per-category sensitivity, and macro-F1."
- In the code (`objective-selection`), κ and mean sensitivity are scored only in-sample on the full cohort. The CV loop (`cv-fit`) refits and scores macro-F1 only.
- This is a Step 3/4 item, flagged here because it misstates how the selection was validated.

### MINOR (code or artifacts; not in the v5 documents unless noted)

- **m1. `schema_diff_bootstrap.csv` (§10) has three problems.** None of `build_*.py`, `draft_tables.R` or `supp_registry.py` reads it, so none reaches the documents. Fix or delete it so it cannot be cited.
  - The point estimate is `exp(mean(bootstrap log-differences))`, not the full-data ratio. For example, AFL-only respiratory is 0.937 here against 1.336/1.386 = 0.963 from `schema_risk.csv`.
  - Any warning from either fit drops the whole resample, which is not missing at random (respiratory B_eff = 862).
  - It applies no fewer-than-10-events rule. CIs and P values are reported for AFL-only respiratory (2 vs 4 events) and COPD-minor respiratory (8 vs 9).
- **m2. `discord_adjusted_strata.csv` carries degenerate and under-floor estimates.**
  - The airflow-limitation ESI-only respiratory HR is 1.8e-06 [0, Inf]; the preserved chunk sets this case to NA, the airflow chunk does not.
  - Preserved-spirometry respiratory CIs are given for cells with 1, 2 and 7 events, and no few-events flag is carried.
  - Figure 4 and Table S7 use crude all-cause and exacerbation values only, and `figure4_discord_risk.R` asserts ≥10 events, so nothing wrong is published.
- **m3. Small issues in `agreement_by_group.csv` (Table S3 P values).**
  - `p_boot` lacks the `min(1, ·)` cap used everywhere else. The current values are fine.
  - The COPD-major PPV comparison has one arm fixed at 100% by construction: every MD-NoCT COPD-major participant is MD-COPD-CT COPD-major, because afl plus ≥1 symptom implies MD-COPD-CT major. P therefore tests only the ESI PPV against 100%. Worth one clause in the Table S3 footnote.
- **m4. Bootstrap P = 0/1000 is reported as "P < 0.005".** That is a valid bound. The finest the bootstrap can resolve is about 0.002, so "P < 0.002" would also be defensible. The overall-agreement P is reported as "P < 0.005", but it comes from McNemar's test and is about 5e-51 (exact binomial about 2e-54), so "P < 0.001" is more informative.
- **m5. Stale prose in Rmd §8a.** It says the classifications' own noCOPD groups are "4,357, 3,853 and 3,815". The assets give 4,357, 3,982 and 3,941. This appears in the HTML analysis report, not the manuscript.
- **m6. The cluster rerun is not identical in its deterministic CV quantities.**
  - Held-out CV agreement differs in the fourth decimal (`schema_fit.csv`: S4 held-out 0.88892 local vs 0.88831 cluster). Fold assignment depends on row order after `merge`. Table S2's "88.9%" would read "88.8%" from the cluster run. Pin the order (`d_b <- d_b[order(d_b$pid), ]` before `cv-fit`) or call it Monte Carlo.
  - `fev1_decline.csv` differs at about 3e-5 relative (lmer tolerance).
  - `cohort_flow.csv` row 1 differs (10,371 vs 10,305) because of a different phenotype-file version. Downstream counts are identical.
  - No significance call at 0.05 changes between the local and cluster bootstraps (checked for Tables S3, S4, S5 and S6).
- **m7.** `schema_crude.csv` `B_eff` is meaningless for exact-Poisson rows. The Rmd computes it anyway.
- **m8.** The continuous-ESI Cox models (`continuous-esi-prognosis`) omit BMI, unlike the Methods covariate set. They are not in the manuscript.

---

## Proposed cluster checks (`step2_cluster_checks/`)

All scripts source `00_load_objects.R`. It purls the Rmd, sends `OUT_DIR` to a temporary directory so nothing in `ctfree/assets/` is overwritten, and cuts the bootstrap chunks. Run them from `ctfree/` through the copilot-relay, not from this laptop.

| script | question | confirms if | refutes if |
|---|---|---|---|
| `C1_cause_of_death_coverage.R` | Share of deaths with no adjudicated cause or code 5, by MD-COPD-CT group and by time; respiratory HRs with follow-up censored at the last adjudicated death | Unadjudicated share is small or the same across groups, and censored HRs are within about 15% of Table S5 | Share differs by group, or HRs move materially (M3) |
| `C2_conventional_spirometry_comparator.R` | Replace the ESI criterion with FEV1/FVC ≤ t or FEV1 %pred ≤ t, fitted with the same macro-F1 grid; compare macro-F1, agreement, CT-only COPD-major moved to AFL-only, and the AFL-only crude mortality and exacerbation ratio versus MD-COPD-CT (paired bootstrap) | ESI beats both comparators | A comparator matches or beats ESI (M2) |
| `C3_fev1_model_checks.R` | (a) Table S6 refitted with `(1 + years \| pid)`; (b) slopes for Both-COPD, CT-only and ESI-only in preserved spirometry against the common reference | Same significance pattern with SEs no more than about 25% wider; (b) shows which group drives the COPD-minor gap | MD-COPD-ESI AFL-only or MD-COPD-CT COPD-minor loses significance (D2) |
| `C4_join_integrity.R` | One row per participant in `mort`, `exa`, `vs`, `ex_raw`, `cod`; one row per (pid, visit) in `decline`; no `py <= 0` | All FALSE or 0 | Any duplicate, which would mean the bootstraps resample rows rather than participants |

---

## What I tried to disprove and could not

- **Common reference.** The reference is noCOPD under all three classifications (asserted in code). Its n = 3,856 equals the MD-COPD-CT ∩ MD-COPD-ESI noCOPD cell in `crossclass.csv`. MD-COPD-ESI noCOPD is a subset of MD-NoCT noCOPD by construction, so the triple intersection equals that cell. Each model excludes the reference from the comparison groups (asserted).
- **Table S3 orientation and definitions.** Rows are the modified classification and columns are MD-COPD-CT. I recomputed every sensitivity, PPV and F1 from `crossclass.csv`; all match. The nesting identities hold: NoCT minor ⊆ ESI minor (709 ≤ 714), ESI AFL-only ⊆ NoCT AFL-only, and 833 − 350 = 483 rescued (58%, "more than half").
- **McNemar test.** The matrix uses the discordant pairs 488 (ESI-only correct) and 118 (NoCT-only correct); 8,222 − 7,852 = 370 = 488 − 118. Test without continuity correction; exact binomial also given.
- **Rate-ratio arithmetic.**
  - Table S4 rates and ratios match `consensus_ref_crude.csv`.
  - The ratio versus MD-COPD-CT is a ratio of group rates, since the reference cancels: 2.294/1.659 = 1.383.
  - Additivity holds: MD-NoCT AFL-only deaths 262 = 50 (MD-COPD-CT AFL-only) + 212 (reclassified group); respiratory 34 = 2 + 32.
  - `poisson.test(c(e1, e0), c(t1, t0))` puts the group in the numerator, which is the right orientation.
- **Paired bootstraps.**
  - All classifications are refitted on the same participant resample.
  - Mortality and exacerbation data are resampled separately. That is harmless, because no estimand combines them.
  - Percentile CIs are taken on the log scale. P is 2 × min tail, capped at 1, in all published paths.
  - The fewer-than-10-events rule is applied to both groups in `group_vs_mdcopd`. The reference has 14 respiratory deaths, which clears the floor.
- **Models.**
  - Cox and negative binomial models use the Methods covariates.
  - The negative binomial has offset log(Years_Followed) and adjusts for prior-year exacerbation frequency.
  - Respiratory death is cause-specific (other deaths censored).
- **Threshold selection.**
  - The fit uses only the MD-COPD-CT labels; no outcome enters.
  - Folds are stratified and thresholds are refitted inside each training fold, so there is no leakage.
  - The selected optimum is not a tie: macro-F1 0.7629 vs 0.7612 at 1.75. `which.max` would break ties toward lower k and lower t.
  - The Nadeau–Bengio factor (1/25 + 1/4) is applied correctly.
  - κ and mean sensitivity err in opposite directions as stated (3 and 954 AFL-only vs 275).
- **Event definition.** TORCH code 1 is Respiratory (documented in the July analysis). The data pattern fits respiratory, not cardiovascular, deaths: 596 of 620 respiratory deaths fall in fixed-ratio COPD.
- **ESI against visual CT.** Mean ESI rises monotonically across both scales. The AUC is Mann–Whitney with ESI oriented positive and FEV1/FVC negated. Prevalences recompute: 4,464/9,240 = 48.3% and 3,677/9,240 = 39.8%. Missing visual scores (n = 4) are disclosed.
- **Bronchodilator CI.** −0.092 ± 1.96 × 0.818/√9,234 gives [−0.109, −0.075], so "−0.11 to −0.08" is correct. The negative sign fits PrePost = 1 being post-bronchodilator.
- **Figures.**
  - Figure 1 (means, n's, AUCs), Figure 3 (27 crude points, interval suppression below 10 events, log axes, MD-COPD-CT on top) and Figure 4 (12 points, both references ≥ 10 deaths) match their assets.
  - Figure S2 bar heights match `discord_profile_strata.csv`; its bracket problem is M1.
- **Plausibility.**
  - MD-NoCT AFL-only having higher risk is expected: it absorbs the 833 CT-positive asymptomatic COPD-major participants (crude all-cause 1.67, respiratory 10.3 against the reference).
  - Exacerbation rates of 0.57 per year in COPD-major and 0.12–0.14 per year in noCOPD are typical of the COPDGene follow-up program.
  - All-cause HRs of 1.8–3.3 are in the expected range.
- **Monte Carlo stability.** Comparing local and cluster bootstraps, no published P crosses 0.05: 0.098 vs 0.090, 0.012 vs 0.022, and 0.008 vs 0.004.
