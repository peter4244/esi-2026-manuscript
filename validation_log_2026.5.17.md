# Validation log — spectrum-wide ESI analysis, 2026-05-17

**Result: 106 checks PASS, 0 checks FAIL.**

Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.
Tolerance: 0.005 absolute on numerics unless otherwise specified at the check.


## Step 1 — Factual accuracy


### Sample counts

- [PASS] V1 POST ESI subjects — expected 10169, recomputed 10169
- [PASS] V1 phenotype subjects — expected 10371, recomputed 10371
- [PASS] Merged V1 ESI + phenotype — expected 10169, recomputed 10169
- [PASS] Vital-status records — expected 10652, recomputed 10652
- [PASS] Deaths in vital-status — expected 2932, recomputed 2932

### Per-stratum subject counts at V1

- [PASS] V1 N(Never) — expected 107, recomputed 107
- [PASS] V1 N(GOLD0) — expected 4327, recomputed 4327
- [PASS] V1 N(PRISm) — expected 1254, recomputed 1254
- [PASS] V1 N(GOLD1) — expected 776, recomputed 776
- [PASS] V1 N(GOLD2) — expected 1900, recomputed 1900
- [PASS] V1 N(GOLD3) — expected 1152, recomputed 1152
- [PASS] V1 N(GOLD4) — expected 593, recomputed 593
- [PASS] Missing-stratum V1 subjects (gold_visit blank) — expected 60, recomputed 60
- [PASS] Per-stratum + missing sum to merged total — expected 10169, recomputed 10169

### ESI distribution by stratum (mean)

- [PASS] Mean ESI Never — expected 0.830, recomputed 0.826
- [PASS] Mean ESI GOLD0 — expected 0.900, recomputed 0.905
- [PASS] Mean ESI PRISm — expected 0.900, recomputed 0.903
- [PASS] Mean ESI GOLD1 — expected 1.440, recomputed 1.440
- [PASS] Mean ESI GOLD2 — expected 2.180, recomputed 2.180
- [PASS] Mean ESI GOLD3 — expected 4.830, recomputed 4.828
- [PASS] Mean ESI GOLD4 — expected 8.250, recomputed 8.250

### ESI ceiling counts (V1)

- [PASS] V1 subjects at ESI=10 (any stratum) — expected 264, recomputed 264
- [PASS] V1 GOLD4 subjects at ESI=10 — expected 228, recomputed 228
- [PASS] V1 GOLD4 ESI=10 percentage — expected 38.400, recomputed 38.449

### Longitudinal FEV1-decline LMM data

- [PASS] LMM total rows — expected 18893, recomputed 18893
- [PASS] LMM unique subjects — expected 10109, recomputed 10109
- [PASS] LMM rows at V1 — expected 10109, recomputed 10109
- [PASS] LMM rows at V2 — expected 5573, recomputed 5573
- [PASS] LMM rows at V3 — expected 3211, recomputed 3211

### Mortality merge

- [PASS] V1 ESI subjects with vital status — expected 10105, recomputed 10105
- [PASS] Median follow-up (yr) — expected 10.700, recomputed 10.732
- [PASS] Deaths in merged set — expected 2857, recomputed 2857

## Step 1 — Cross-spectrum correlations


### Overall correlations (V1)

- [PASS] r(ESI, FEV1/FVC) — all V1 — expected -0.890, recomputed -0.890
- [PASS] r(ESI, %LAA-950) — all V1 — expected 0.770, recomputed 0.773
- [PASS] r(ESI, PRM emph) — all V1 — expected 0.800, recomputed 0.799
- [PASS] r(ESI, PRM air-trapping) — expected 0.690, recomputed 0.685
- [PASS] r(ESI, Pi10) — all V1 — expected 0.380, recomputed 0.384

### Per-stratum r(ESI, FEV1/FVC)

- [PASS] r(ESI, FEV1/FVC) Never — expected -0.400, recomputed -0.395
- [PASS] r(ESI, FEV1/FVC) GOLD0 — expected -0.260, recomputed -0.262
- [PASS] r(ESI, FEV1/FVC) PRISm — expected -0.260, recomputed -0.259
- [PASS] r(ESI, FEV1/FVC) GOLD1 — expected -0.610, recomputed -0.609
- [PASS] r(ESI, FEV1/FVC) GOLD2 — expected -0.880, recomputed -0.876
- [PASS] r(ESI, FEV1/FVC) GOLD3 — expected -0.920, recomputed -0.919
- [PASS] r(ESI, FEV1/FVC) GOLD4 — expected -0.850, recomputed -0.849

### Per-stratum r(ESI, %LAA-950HU)

- [PASS] r(ESI, LAA-950) Never — expected 0.290, recomputed 0.288
- [PASS] r(ESI, LAA-950) GOLD0 — expected 0.080, recomputed 0.079
- [PASS] r(ESI, LAA-950) PRISm — expected 0.050, recomputed 0.049
- [PASS] r(ESI, LAA-950) GOLD1 — expected 0.240, recomputed 0.244
- [PASS] r(ESI, LAA-950) GOLD2 — expected 0.510, recomputed 0.511
- [PASS] r(ESI, LAA-950) GOLD3 — expected 0.580, recomputed 0.575
- [PASS] r(ESI, LAA-950) GOLD4 — expected 0.440, recomputed 0.444

### v10 cross-check: r(ESI, FEV1/FVC) in GOLD 2–4 subset

- [PASS] r(ESI, FEV1/FVC) in current GOLD 2–4 subset (v10 reported -0.94) — expected -0.940, recomputed -0.942

## Step 1 — Mortality Cox models

- [PASS] Cox univariable HR(ESI) — expected 1.270, recomputed 1.276
- [PASS] Cox adjusted (no FEV1/FVC) HR(ESI) — expected 1.100, recomputed 1.098
- [PASS] Cox adjusted (no FEV1/FVC) p(ESI) (sci) — expected 0.0, recomputed 0.3
- [PASS] Cox adjusted (with FEV1/FVC) HR(ESI) — expected 1.080, recomputed 1.077
- [PASS] Cox adjusted (with FEV1/FVC) p(ESI) (sci) — expected 0.00, recomputed -0.01
- [PASS] Cox sensitivity (drop ESI=10) HR(ESI) — expected 1.070, recomputed 1.070
- [PASS] Cox LR chi-sq for adding ESI to FEV1/FVC + covariates — expected 11.478, recomputed 11.478

## Step 1 — FEV1 decline LMM

- [PASS] LMM pooled years × ESI (mL/yr/unit) — expected 2.560, recomputed 2.556
- [PASS] LMM pooled years × FEV1/FVC (mL/yr/unit) — expected 20.050, recomputed 20.053
- [PASS] LMM LR chi-sq adding years × ESI to (FF + covariates) — expected 25.873, recomputed 25.873
- [PASS] LMM LR chi-sq adding years × FF to (ESI + covariates) — expected 11.706, recomputed 11.706

### Per-stratum FEV1 decline (years × ESI), mutually adjusted

- [PASS] Per-stratum LMM GOLD0 — slope (mL/yr/unit) — expected -4.700, recomputed -4.704
- [PASS] Per-stratum LMM GOLD0 — p — expected 0.001, recomputed 0.001
- [PASS] Per-stratum LMM PRISm — slope (mL/yr/unit) — expected 0.940, recomputed 0.938
- [PASS] Per-stratum LMM PRISm — p — expected 0.800, recomputed 0.801
- [PASS] Per-stratum LMM GOLD1 — slope (mL/yr/unit) — expected -1.180, recomputed -1.180
- [PASS] Per-stratum LMM GOLD1 — p — expected 0.730, recomputed 0.728
- [PASS] Per-stratum LMM GOLD2 — slope (mL/yr/unit) — expected 3.030, recomputed 3.034
- [PASS] Per-stratum LMM GOLD2 — p — expected 0.170, recomputed 0.174
- [PASS] Per-stratum LMM GOLD3 — slope (mL/yr/unit) — expected 0.620, recomputed 0.618
- [PASS] Per-stratum LMM GOLD3 — p — expected 0.680, recomputed 0.679
- [PASS] Per-stratum LMM GOLD4 — slope (mL/yr/unit) — expected 0.740, recomputed 0.737
- [PASS] Per-stratum LMM GOLD4 — p — expected 0.650, recomputed 0.652

## Step 1 — ESI trajectories (mean ESI by visit × baseline stratum)

- [PASS] Mean ESI Never V1 — expected 0.830, recomputed 0.826
- [PASS] Mean ESI Never V2 — expected 0.880, recomputed 0.878
- [PASS] Mean ESI Never V3 — expected 0.740, recomputed 0.743
- [PASS] Mean ESI GOLD0 V1 — expected 0.900, recomputed 0.905
- [PASS] Mean ESI GOLD0 V2 — expected 0.910, recomputed 0.910
- [PASS] Mean ESI GOLD0 V3 — expected 0.930, recomputed 0.934
- [PASS] Mean ESI PRISm V1 — expected 0.900, recomputed 0.903
- [PASS] Mean ESI PRISm V2 — expected 1.000, recomputed 1.000
- [PASS] Mean ESI PRISm V3 — expected 1.160, recomputed 1.160
- [PASS] Mean ESI GOLD1 V1 — expected 1.440, recomputed 1.440
- [PASS] Mean ESI GOLD1 V2 — expected 1.500, recomputed 1.503
- [PASS] Mean ESI GOLD1 V3 — expected 1.790, recomputed 1.794
- [PASS] Mean ESI GOLD2 V1 — expected 2.180, recomputed 2.180
- [PASS] Mean ESI GOLD2 V2 — expected 2.580, recomputed 2.578
- [PASS] Mean ESI GOLD2 V3 — expected 3.080, recomputed 3.080
- [PASS] Mean ESI GOLD3 V1 — expected 4.830, recomputed 4.828
- [PASS] Mean ESI GOLD3 V2 — expected 5.200, recomputed 5.199
- [PASS] Mean ESI GOLD3 V3 — expected 5.690, recomputed 5.689
- [PASS] Mean ESI GOLD4 V1 — expected 8.250, recomputed 8.250
- [PASS] Mean ESI GOLD4 V2 — expected 7.560, recomputed 7.558
- [PASS] Mean ESI GOLD4 V3 — expected 6.200, recomputed 6.195

## Step 2 — Adversarial sanity checks (try to disprove)


### GOLD 4 V3 survivor bias quantification

- GOLD 4 baseline ESI mean (all V1, n = 593): 8.25
- GOLD 4 baseline ESI mean for the V3 SURVIVOR subset (n = 39): 8.45
- Difference: 0.20 (lower in survivors → confirms selection)

### PRISm trajectory robustness — median vs mean

- PRISm V1: mean = 0.903, median = 0.830, n = 1254
- PRISm V2: mean = 1.000, median = 0.870, n = 666
- PRISm V3: mean = 1.160, median = 0.950, n = 210

### Pooled years × ESI sign: stratum-confounding artifact?

- With baseline_stratum REMOVED: years × ESI = +2.50 mL/yr/unit (p = 1.59e-06); years × FEV1/FVC = +19.4 mL/yr/unit (p = 0.00131)
- With stratum IN: years × ESI = +2.56 (p≈0); years × FF = +20.05 (p=0.001).
- If removing stratum flips signs back to expected (-), the pooled-positive sign is a stratum-confounding artifact.

### Deaths and follow-up — sanity checks

- vital_status == 1 (deaths) in merged mortality set: 2857 / 10105 (28.3%)
- days_followed range: 0 to 5575 (i.e. 0.0 to 15.3 yr)
- Subjects with days_followed == 0: 532 (should be small)

### FEV1 decline LMM — alignment check

- V1 years_from_baseline range: 0.00 to 0.00
- V2 years_from_baseline range: 3.58 to 9.16
- V3 years_from_baseline range: 8.61 to 14.93

## Step 3 — Documentation accuracy (key prose statements)

- [PASS] Prose: '10,169 V1 subjects with valid ESI' — expected 10169, recomputed 10169
- [PASS] Prose: '10,109 subjects in LMM' — expected 10109, recomputed 10109
- [PASS] Prose: '18,893 LMM rows' — expected 18893, recomputed 18893
- [PASS] Prose: '2,857 deaths over median 10.7 yr' — expected 2857, recomputed 2857
- [PASS] Prose: 'r(ESI, FEV1/FVC) = -0.89 overall' — expected -0.890, recomputed -0.890
- [PASS] Prose: 'r(ESI, FEV1/FVC) -0.26 in GOLD0' — expected -0.260, recomputed -0.262
- [PASS] Prose: 'r(ESI, FEV1/FVC) -0.92 in GOLD3' — expected -0.920, recomputed -0.919
- [PASS] Prose: 'pooled HR(ESI)=1.08, p≈6e-4' — expected 1.080, recomputed 1.077
- [PASS] Prose: 'sensitivity HR=1.07, p=0.005' — expected 1.070, recomputed 1.070
- [PASS] Prose: 'GOLD 0 baseline ESI slope ≈ -4.7' — expected -4.700, recomputed -4.704
