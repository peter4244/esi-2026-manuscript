# Validation log — 2026-06-22 revisions

**Result: 36 checks PASS, 0 checks FAIL.**

Tolerance: 0.005 absolute on numerics by default.


## Step 1 — Factual accuracy

- [PASS] Mortality merge cohort size — expected 10043, recomputed 10043
- [PASS] All-cause deaths in merge — expected 2839, recomputed 2839
- [PASS] Respiratory deaths in merge (cause-specific) — expected 1163, recomputed 1163
- [PASS] All-cause Cox HR(ESI), ESI-only model — expected 1.098, recomputed 1.098
- [PASS] All-cause Cox HR(ESI), ESI + FF model — expected 1.077, recomputed 1.077
- [PASS] All-cause LR chi-sq (ESI added beyond FF) — expected 11.480, recomputed 11.478
- [PASS] Respiratory Cox HR(ESI), ESI-only model — expected 1.103, recomputed 1.103
- [PASS] Respiratory Cox HR(ESI), ESI + FF model — expected 1.006, recomputed 1.006
- [PASS] Respiratory LR chi-sq (ESI added beyond FF) — expected 0.040, recomputed 0.036
- [PASS] Respiratory LR p-value > 0.5 (ESI not adding) — expected TRUE, recomputed TRUE
- Per-stratum respiratory HR(ESI) — GOLD0: HR=1.007, p=0.986  (n=4308, deaths=52)
- Per-stratum respiratory HR(ESI) — PRISm: HR=1.200, p=0.585  (n=1238, deaths=44)
- Per-stratum respiratory HR(ESI) — GOLD1: HR=1.173, p=0.756  (n=773, deaths=35)
- Per-stratum respiratory HR(ESI) — GOLD2: HR=1.055, p=0.62  (n=1890, deaths=256)
- Per-stratum respiratory HR(ESI) — GOLD3: HR=1.097, p=0.116  (n=1139, deaths=401)
- Per-stratum respiratory HR(ESI) — GOLD4: HR=0.970, p=0.536  (n=589, deaths=375)
- [PASS] r(LAA-950, PRM_emph) — expected 0.985, recomputed 0.985
- [PASS] r(LAA-856, LAA-950) — expected 0.850, recomputed 0.850
- [PASS] r(LAA-856, PRM_airtrap) — expected 0.926, recomputed 0.926
- [PASS] r(ESI, PRM_emph) in GOLD0 — expected 0.067, recomputed 0.067
- [PASS] r(ESI, PRM_emph) in GOLD3 — expected 0.563, recomputed 0.563
- [PASS] r(ESI, PRM_emph) overall — expected 0.799, recomputed 0.799
- [PASS] Subjects with V1 ESI in GOLD 0 — expected 4327, recomputed 4327
- [PASS] PRISm mean ΔESI at V3 ≈ 0.25 — expected 0.250, recomputed 0.253
- [PASS] GOLD 0 mean ΔESI at V3 ≈ 0.05 — expected 0.050, recomputed 0.052
- [PASS] Bhatt-substitution cohort size — expected 9400, recomputed 9400
- [PASS] Bhatt-substitution resp deaths — expected 1068, recomputed 1068
- [PASS] Bhatt respiratory HR (COPD-minor) — expected 3.090, recomputed 3.092
- [PASS] Bhatt respiratory HR (COPD-major) — expected 13.930, recomputed 13.930
- [PASS] Bhatt model resp C-index — expected 0.822, recomputed 0.822

## Step 2 — Adversarial sanity checks

- [PASS] Respiratory deaths only occur in those who died (alive subjects have event_resp=0) — expected 0, recomputed 0
- [PASS] Same in Bhatt-cohort — expected 0, recomputed 0
- [PASS] Unadjudicated deaths default to event_resp=0 (not classified as respiratory) — expected 0, recomputed 0
- [PASS] AFL-only-NoCOPD subjects all have FEV1/FVC < 0.70 — expected 170, recomputed 170
- GOLD 4 per-stratum respiratory HR(ESI) = 0.970 (sanity: should be near 1 because GOLD 4 has ESI-ceiling and high baseline mortality)
- [PASS] GOLD 4 per-stratum respiratory HR(ESI) within sensible range (0.8 to 1.3) — expected TRUE, recomputed TRUE
- PRISm V3 ΔESI: mean = 0.253, median = 0.060
- GOLD 0 V3 ΔESI: mean = 0.052, median = 0.010
- [PASS] PRISm > GOLD 0 trajectory direction holds in BOTH mean and median — expected TRUE, recomputed TRUE
- [PASS] LAA-950 vs PRM_emph correlation extremely high (≥ 0.97) — expected TRUE, recomputed TRUE

## Step 3 — Documentation accuracy

- [PASS] 'Respiratory mortality: ESI not significant after FEV1/FVC' (HR ≈ 1.0) — expected TRUE, recomputed TRUE
- [PASS] 'All-cause mortality: ESI HR 1.08 after FEV1/FVC' (claim retained) — expected 1.080, recomputed 1.077
- [PASS] '1,163 respiratory deaths in mortality merge' — expected 1163, recomputed 1163
- [PASS] 'r(ESI, PRM emphysema) overall ≈ 0.80 (Massimo's earlier finding' — expected 0.800, recomputed 0.799
- [PASS] 'PRISm ΔESI V3 mean 0.25, median 0.06 — direction consistent' — expected TRUE, recomputed TRUE
