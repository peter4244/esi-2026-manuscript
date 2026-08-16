# Validation log — Bhatt-substitution section, 2026-05-17

**Result: 42 checks PASS, 0 checks FAIL.**

Tolerance: 0.01 absolute on numerics by default.


## Step 1 — Factual accuracy

- [PASS] Cohort size (n with all Bhatt criteria) — expected 9463, recomputed 9463
- [PASS] Bhatt COPD-major count — expected 3969, recomputed 3969
- [PASS] Bhatt COPD-minor count — expected 1099, recomputed 1099
- [PASS] Bhatt AFL-only-NoCOPD count — expected 170, recomputed 170
- [PASS] Bhatt noCOPD count — expected 4225, recomputed 4225
- [PASS] Preserved GOLD0 — n — expected 4073, recomputed 4073
- [PASS] Preserved GOLD0 — Bhatt-COPD — expected 682, recomputed 682
- [PASS] Preserved GOLD0 — ESI-variant COPD — expected 409, recomputed 409
- [PASS] Preserved GOLD0 — both — expected 342, recomputed 342
- [PASS] Preserved GOLD0 — Bhatt-only (missed) — expected 340, recomputed 340
- [PASS] Preserved GOLD0 — ESI-only (false +) — expected 67, recomputed 67
- [PASS] Preserved GOLD0 — sensitivity — expected 0.500, recomputed 0.501
- [PASS] Preserved GOLD0 — specificity — expected 0.980, recomputed 0.980
- [PASS] Preserved PRISm — n — expected 1144, recomputed 1144
- [PASS] Preserved PRISm — Bhatt-COPD — expected 417, recomputed 417
- [PASS] Preserved PRISm — ESI-variant COPD — expected 239, recomputed 239
- [PASS] Preserved PRISm — both — expected 211, recomputed 211
- [PASS] Preserved PRISm — Bhatt-only (missed) — expected 206, recomputed 206
- [PASS] Preserved PRISm — ESI-only (false +) — expected 28, recomputed 28
- [PASS] Preserved PRISm — sensitivity — expected 0.510, recomputed 0.506
- [PASS] Preserved PRISm — specificity — expected 0.960, recomputed 0.961
- [PASS] Bhatt mortality HR (COPD-minor) — expected 1.910, recomputed 1.907
- [PASS] ESI-variant mortality HR (COPD-minor) — expected 1.940, recomputed 1.943
- [PASS] Bhatt mortality HR (COPD-major) — expected 2.590, recomputed 2.591
- [PASS] ESI-variant mortality HR (COPD-major) — expected 2.390, recomputed 2.395
- [PASS] Bhatt model C-index — expected 0.703, recomputed 0.703
- [PASS] ESI-variant model C-index — expected 0.700, recomputed 0.700

## Step 2 — Adversarial sanity checks

- [PASS] 4-way cross-tab cells sum to n — expected 9463, recomputed 9463
- [PASS] AFL-only-NoCOPD have major_criterion = TRUE — expected 170, recomputed 170
- [PASS] AFL-only-NoCOPD have zero minor criteria — expected 170, recomputed 170
- [PASS] AFL-only-NoCOPD bhatt_copd = FALSE — expected 0, recomputed 0
- AFL-only-NoCOPD mortality HR (Bhatt): 0.90, p = 0.564 (should be ~1, not significant)
- [PASS] No preserved-spirometry subjects in COPD-major — expected 0, recomputed 0
- [PASS] No obstructed subjects in COPD-minor — expected 0, recomputed 0
- [PASS] Cohen's κ (binary COPD vs noCOPD) — expected 0.820, recomputed 0.820
- Sanity rule behavior: at very low ESI threshold (0.5/2.5), n_COPD = 5440; at very high (8/10), n_COPD = 3381.  Expect: low threshold gives more, high gives fewer.
- PASS: rule behaves monotonically with thresholds.

## Step 3 — Documentation accuracy

- [PASS] Prose: 'about half of Bhatt's minor-COPD' (GOLD 0 sens ≈ 50%) — expected 0.500, recomputed 0.501
- [PASS] Prose: 'about half of Bhatt's minor-COPD' (PRISm sens ≈ 51%) — expected 0.510, recomputed 0.506
- [PASS] Prose: 'highly specific (96–98%)' — GOLD 0 spec ≥ 0.96 — expected TRUE, recomputed TRUE
- [PASS] Prose: 'highly specific (96–98%)' — PRISm spec ≥ 0.96 — expected TRUE, recomputed TRUE
- [PASS] Prose: 'HR ≈ 1.94 vs 1.91 for COPD-minor' — expected TRUE, recomputed TRUE
- [PASS] Prose: 'C-index 0.700 vs 0.703' — expected TRUE, recomputed TRUE
- [PASS] Prose: 'AFL-only-NoCOPD HR not different from noCOPD' — expected TRUE, recomputed TRUE
