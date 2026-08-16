# Validation log — Round-2 §3.5 revisions (2026-06-25)

**Result: 28 checks PASS, 0 checks FAIL.**


## Step 1 — Factual accuracy

- [PASS] κ for 4-crit ESI≥1.5 ≥2-of-4 — expected 0.793, recomputed 0.793
- [PASS] κ for 4-crit ESI≥1.0 ≥2-of-4 — expected 0.827, recomputed 0.827
- [PASS] κ for selected 5-crit T_low=1.0 T_high=2.5 — expected 0.820, recomputed 0.820
- [PASS] κ for best 5-crit T_low=0.5 T_high=2.0 — expected 0.863, recomputed 0.863
- [PASS] Preserved Both-COPD count — expected 553, recomputed 553
- [PASS] Preserved Bhatt-only-COPD count — expected 546, recomputed 546
- [PASS] Preserved ESI-only-COPD count — expected 95, recomputed 95
- [PASS] Both-COPD mean ESI — expected 1.060, recomputed 1.057
- [PASS] Bhatt-only mean ESI — expected 0.800, recomputed 0.801
- [PASS] ESI-only mean ESI — expected 1.480, recomputed 1.480
- [PASS] Both-COPD %emph_yn — expected 0.650, recomputed 0.651
- [PASS] Bhatt-only %emph_yn — expected 0.910, recomputed 0.910
- [PASS] ESI-only %emph_yn — expected 0.000, recomputed 0.000
- [PASS] Both-COPD %CB — expected 0.720, recomputed 0.716
- [PASS] Bhatt-only %CB — expected 0.160, recomputed 0.161
- [PASS] ESI-only %CB — expected 0.160, recomputed 0.158
- [PASS] Both-COPD all-cause HR — expected 2.020, recomputed 2.024
- [PASS] Bhatt-only all-cause HR — expected 1.530, recomputed 1.530
- [PASS] Both-COPD resp HR — expected 3.050, recomputed 3.053
- [PASS] Bhatt-only resp HR — expected 2.480, recomputed 2.476

## Step 2 — Adversarial sanity checks

- [PASS] Both + Bhatt-only + ESI-only = Either-COPD — expected 1194, recomputed 1194
- ESI-only subjects: emph_yn = 0/95 (0%), wall_yn = 0/95 (0%)
- [PASS] ESI-only subjects with both imaging criteria (impossible for Bhatt-noCOPD with 3 symptoms) — expected TRUE, recomputed TRUE
- [PASS] Bhatt-only ESI mean < Both ESI mean (lower ESI = ESI missed) — expected TRUE, recomputed TRUE
- [PASS] Both-COPD HR > Bhatt-only HR > 1 (both classifications agreeing = highest risk) — expected TRUE, recomputed TRUE

## Step 3 — Documentation accuracy

- [PASS] 'Bhatt-only-COPD subjects have low ESI (0.80) but high CT emphysema (91%)' — expected TRUE, recomputed TRUE
- [PASS] 'ESI-only-COPD subjects have high ESI (1.48) but ZERO CT findings' — expected TRUE, recomputed TRUE
- [PASS] 'Bhatt-only-COPD has elevated mortality (HR 1.53, p<0.001)' — expected TRUE, recomputed TRUE
- [PASS] 'Both-COPD has highest mortality (HR 2.02)' — expected TRUE, recomputed TRUE
