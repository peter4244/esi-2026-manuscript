# v4 outline comprehensive validation log — 2026-06-25

**Result: 73 checks PASS, 0 checks FAIL.**

Each line: `[PASS|FAIL] label — expected <prose claim>, recomputed <from raw CSV>`.
Tolerance: 0.02 absolute on HRs/IRRs/coefs; 0 on counts; 0.005 on κ/sens/spec.

## Step 1 — Factual accuracy: every numerical claim in v4 prose re-derived


### §3.1 — ESI-CT correlations
- [PASS] Prose: r(ESI, %LAA-950HU) = 0.77 overall — expected 0.770, recomputed 0.773
- [PASS] Prose: r(ESI, PRM emphysema) = 0.80 overall — expected 0.800, recomputed 0.799
- r(ESI, FEV1/FVC) Never = -0.40
- r(ESI, FEV1/FVC) GOLD0 = -0.26
- r(ESI, FEV1/FVC) PRISm = -0.26
- r(ESI, FEV1/FVC) GOLD1 = -0.61
- r(ESI, FEV1/FVC) GOLD2 = -0.88
- r(ESI, FEV1/FVC) GOLD3 = -0.92
- r(ESI, FEV1/FVC) GOLD4 = -0.85
- [PASS] Prose: r(LAA-950, PRM emph) = 0.985 — expected 0.985, recomputed 0.985
- [PASS] Prose: 'mean ΔESI ≈ -0.09' (BD insensitivity) — expected -0.090, recomputed -0.089

### §3.2 — Bhatt substitution and classification agreement
- [PASS] Prose: cohort n = 9,463 (subjects with all Bhatt criteria) — expected 9463, recomputed 9463
- [PASS] Prose: agree on COPD vs noCOPD in 91% of cases — expected 0.910, recomputed 0.910
- [PASS] Prose: κ = 0.82 — expected 0.820, recomputed 0.820
- [PASS] Prose: sensitivity 88% — expected 0.880, recomputed 0.880
- [PASS] Prose: specificity 94% — expected 0.940, recomputed 0.944
- [PASS] Prose: Both-COPD n = 553 — expected 553, recomputed 553
- [PASS] Prose: Bhatt-only-COPD n = 546 — expected 546, recomputed 546
- [PASS] Prose: ESI-only-COPD n = 95 — expected 95, recomputed 95
- [PASS] Prose: Both-COPD mean ESI 1.06 — expected 1.060, recomputed 1.057
- [PASS] Prose: Bhatt-only mean ESI 0.80 — expected 0.800, recomputed 0.801
- [PASS] Prose: ESI-only mean ESI 1.48 — expected 1.480, recomputed 1.480
- [PASS] Prose: Bhatt-only 91% visible emphysema — expected 0.910, recomputed 0.910
- [PASS] Prose: ESI-only 0% visible emphysema — expected 0.000, recomputed 0.000

### §3.3a — By-classification outcomes
- [PASS] Prose: COPD-major Bhatt all-cause HR 2.59 — expected 2.590, recomputed 2.591
- [PASS] Prose: COPD-major ESI all-cause HR 2.39 — expected 2.390, recomputed 2.395
- [PASS] Prose: COPD-minor Bhatt all-cause HR 1.91 — expected 1.910, recomputed 1.907
- [PASS] Prose: COPD-minor ESI all-cause HR 1.94 — expected 1.940, recomputed 1.943
- [PASS] Prose: AFL-only Bhatt all-cause HR 0.90 — expected 0.900, recomputed 0.897
- [PASS] Prose: AFL-only ESI all-cause HR 0.91 — expected 0.910, recomputed 0.913
- [PASS] Prose: Bhatt all-cause C-index 0.703 — expected 0.703, recomputed 0.703
- [PASS] Prose: ESI-variant all-cause C-index 0.700 — expected 0.700, recomputed 0.700
- [PASS] Prose: COPD-major Bhatt resp HR 13.93 — expected 13.930, recomputed 13.930
- [PASS] Prose: COPD-major ESI resp HR 11.85 — expected 11.850, recomputed 11.853
- [PASS] Prose: COPD-minor Bhatt resp HR 3.09 — expected 3.090, recomputed 3.092
- [PASS] Prose: COPD-minor ESI resp HR 2.91 — expected 2.910, recomputed 2.912
- [PASS] Prose: Bhatt resp C-index 0.822 — expected 0.822, recomputed 0.822
- [PASS] Prose: ESI-variant resp C-index 0.819 — expected 0.819, recomputed 0.819
- [PASS] Prose: CVD COPD-major Bhatt HR 2.34 — expected 2.340, recomputed 2.336
- [PASS] Prose: CVD COPD-major ESI HR 2.24 — expected 2.240, recomputed 2.235
- [PASS] Prose: Cancer COPD-major Bhatt HR 2.05 — expected 2.050, recomputed 2.054
- [PASS] Prose: Cancer COPD-major ESI HR 1.88 — expected 1.880, recomputed 1.880
- [PASS] Prose: Other COPD-major Bhatt HR 1.92 — expected 1.920, recomputed 1.922
- [PASS] Prose: Other COPD-major ESI HR 1.80 — expected 1.800, recomputed 1.799
- [PASS] Prose: COPD-major Bhatt IRR 5.07 — expected 5.070, recomputed 5.068
- [PASS] Prose: COPD-major ESI IRR 4.47 — expected 4.470, recomputed 4.473
- [PASS] Prose: COPD-minor Bhatt IRR 2.73 — expected 2.730, recomputed 2.728
- [PASS] Prose: COPD-minor ESI IRR 2.78 — expected 2.780, recomputed 2.781

### §3.3b — Discordance subgroups
- [PASS] Prose: Both-COPD all-cause HR 2.02 — expected 2.020, recomputed 2.024
- [PASS] Prose: Bhatt-only all-cause HR 1.53 — expected 1.530, recomputed 1.530
- [PASS] Prose: ESI-only all-cause HR 1.26 — expected 1.260, recomputed 1.257
- [PASS] Prose: Both-COPD resp HR 3.05 — expected 3.050, recomputed 3.053
- [PASS] Prose: Bhatt-only resp HR 2.48 — expected 2.480, recomputed 2.476
- [PASS] Prose: ESI-only-COPD CVD HR 2.74 — expected 2.740, recomputed 2.742
- [PASS] Prose: ESI-only CVD p ≈ 0.006 — expected TRUE, recomputed TRUE
- [PASS] Prose: ESI-only CVD 95%CI lower 1.33 — expected 1.330, recomputed 1.334
- [PASS] Prose: ESI-only CVD 95%CI upper 5.64 — expected 5.640, recomputed 5.638
- [PASS] Prose: ESI-only CVD events n = 8 — expected 8, recomputed 8
- [PASS] Prose: Both-COPD discord exac IRR 3.17 — expected 3.170, recomputed 3.167
- [PASS] Prose: Bhatt-only discord exac IRR 2.01 — expected 2.010, recomputed 2.011
- [PASS] Prose: ESI-only discord exac IRR 1.59 — expected 1.590, recomputed 1.587

### §3.4 — Continuous-ESI secondary analyses
- [PASS] Prose: continuous-ESI all-cause HR 1.08 after FF — expected 1.080, recomputed 1.077
- [PASS] Prose: continuous-ESI resp HR ~1.01 after FF (null) — expected 1.010, recomputed 1.006
- [PASS] Prose: GOLD 0 FEV1-decline ESI coef -4.7 mL/yr/unit — expected -4.700, recomputed -4.704

## Step 2 — Adversarial: cohort-filter and definition consistency checks

- §3.2 Bhatt-cohort n = 9463 (Table 6 cross-tab); §3.3a mortality-cohort n = 9400 after vital-status merge and covariate filtering
- [PASS] Mortality merge loses no more than ~5% of the Bhatt cohort — expected TRUE, recomputed TRUE
- §3.2 discordance subgroups in preserved spirometry: 1194 (Both + Bhatt-only + ESI-only)
- §3.3b same subgroups after mortality merge: 1180
- [PASS] Discordance group sizes are consistent between §3.2 and §3.3b (after merge attrition) — expected TRUE, recomputed TRUE
- [PASS] Prose: 'AFL-only cause-specific events 3-7 per cause' (CVD Bhatt = 7) — expected 7, recomputed 7
- [PASS] Prose: 'AFL-only cause-specific events 3-7 per cause' (CVD ESI = 3) — expected 3, recomputed 3
- [PASS] ESI-only CVD CI width > 3 (small N → wide CI, as expected) — expected TRUE, recomputed TRUE
- [PASS] Both-COPD all-cause HR > Bhatt-only HR > 1 — expected TRUE, recomputed TRUE
- [PASS] Higher ESI thresholds produce fewer ESI-COPD (monotonic) — expected TRUE, recomputed TRUE

## Step 3 — Documentation accuracy: prose ↔ rendered table ↔ source CSV

- [PASS] CSV ↔ recomputed: Table_CauseSpecific_byClass CVD COPD-major Bhatt HR — expected 2.336, recomputed 2.336
- [PASS] CSV ↔ recomputed: Table_CauseSpecific_byDiscord ESI-only CVD HR — expected 2.742, recomputed 2.742
- [PASS] CSV ↔ recomputed: Table_Exacerbations_Bhatt COPD-major IRR — expected 5.068, recomputed 5.068
- [PASS] CSV ↔ recomputed: Table_8_resp Bhatt COPD-minor HR — expected 3.092, recomputed 3.092

## Step 4 — Methods description vs code

- Cohort: §2.1 says 'n = 9,463 V1 subjects with usable post-BD spirometry, valid ESI, and complete Bhatt-criteria variables'.  This matches the Bhatt cohort definition (d_b) which filters on all 6 criteria being non-missing.
- [PASS] Methods §2.1 cohort definition reproduces n = 9,463 — expected 9463, recomputed 9463
- ESI substitution rule: §2.2 says 'ESI < 1.0 → 0 minors; 1.0 ≤ ESI < 2.5 → 1 minor; ESI ≥ 2.5 → 2 minors'.
- [PASS] Methods §2.2 ESI scoring rule reproduces the analysis — expected TRUE, recomputed TRUE
- FEV1/FVC scaling: §2.5 says 'FEV1/FVC is reported on a per-0.1-unit scale'.
- [PASS] Methods §2.5 FEV1/FVC scaling = /0.1 (used in all neg-bin / Cox-cs models) — expected TRUE, recomputed TRUE
- Outcomes: §2.3 lists all-cause mortality (n_deaths = 2,839 expected after merge).
- [PASS] §2.3 mortality cohort with covariate filtering — expected TRUE, recomputed TRUE

## Step 5 — METHODS.md

- METHODS.md written to /Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript/METHODS.md
- [PASS] METHODS.md exists and is non-empty — expected TRUE, recomputed TRUE
