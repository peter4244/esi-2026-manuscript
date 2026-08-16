# Validation log — Subgroup analyses (2026-06-25)

**Result: 19 checks PASS, 0 checks FAIL.**


## Step 1 — Factual accuracy

- [PASS] CVD COPD-major (Bhatt) HR ≈ 2.34 — expected 2.336, recomputed 2.336
- [PASS] CVD COPD-major (ESI)   HR ≈ 2.24 — expected 2.235, recomputed 2.235
- [PASS] CVD COPD-minor (Bhatt) HR ≈ 1.67 — expected 1.667, recomputed 1.667
- [PASS] CVD COPD-minor (ESI)   HR ≈ 1.87 — expected 1.872, recomputed 1.872
- [PASS] Cancer COPD-major (Bhatt) HR ≈ 2.05 — expected 2.054, recomputed 2.054
- [PASS] Cancer COPD-minor (Bhatt) HR ≈ 2.32 — expected 2.319, recomputed 2.319
- [PASS] Other COPD-major (Bhatt) HR ≈ 1.92 — expected 1.922, recomputed 1.922
- [PASS] Discord CVD Both-COPD HR ≈ 1.70 — expected 1.699, recomputed 1.699
- [PASS] Discord CVD Bhatt-only HR ≈ 1.50 — expected 1.502, recomputed 1.502
- [PASS] Discord CVD ESI-only HR ≈ 2.74 — expected 2.742, recomputed 2.742
- [PASS] Discord Cancer Both-COPD HR ≈ 2.87 — expected 2.870, recomputed 2.870
- [PASS] ESI-only-COPD CVD events — expected 8, recomputed 8
- [PASS] FEV1 decline interaction Both-COPD est ≈ -1.40 — expected -1.395, recomputed -1.395
- [PASS] FEV1 decline interaction ESI-only-COPD est ≈ -3.70 — expected -3.700, recomputed -3.700

## Step 2 — Adversarial sanity

- [PASS] Bhatt vs ESI-Bhatt COPD-major CVD HRs differ by < 0.20 — expected TRUE, recomputed TRUE
- ESI-only-COPD CVD HR 95% CI width = 4.30 (wide due to n_events=8)
- [PASS] ESI-only-COPD CVD CI width > 3 (small N → wide CI) — expected TRUE, recomputed TRUE
- [PASS] Discord groups sum to preserved-spirometry n — expected 5289, recomputed 5289

## Step 3 — Documentation accuracy

- [PASS] Prose: 'ESI-only-COPD CVD HR ~2.7 (p < 0.01) despite small N' — expected TRUE, recomputed TRUE
- [PASS] Prose: 'Bhatt and ESI-Bhatt produce similar COPD-major HRs across causes' — expected TRUE, recomputed TRUE
