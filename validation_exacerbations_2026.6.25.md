# Validation log — Exacerbation analyses (2026-06-25)

**Result: 27 checks PASS, 0 checks FAIL.**


## Step 1 — Factual accuracy

- [PASS] Exacerbation merge cohort size — expected 8898, recomputed 8898
- [PASS] Total exacerbations in cohort — expected 24454, recomputed 24454
- [PASS] Median follow-up years — expected 10.300, recomputed 10.300
- [PASS] ESI-only IRR(ESI) — expected 1.114, recomputed 1.114
- [PASS] ESI+FF IRR(ESI) — expected 1.010, recomputed 1.010
- [PASS] ESI+FF IRR(FF per 0.1) — expected 0.797, recomputed 0.797
- [PASS] FF-only IRR(FF per 0.1) — expected 0.787, recomputed 0.787
- [PASS] LR chi-sq (ESI added beyond FF) — expected 0.140, recomputed 0.141
- [PASS] LR p-value > 0.5 (ESI not adding) — expected TRUE, recomputed TRUE
- [PASS] Severe ESI+FF IRR(ESI) ≈ 0.99 (null) — expected 0.988, recomputed 0.988
- [PASS] Severe ESI p > 0.5 — expected TRUE, recomputed TRUE
- [PASS] Bhatt COPD-minor IRR — expected 2.728, recomputed 2.728
- [PASS] Bhatt COPD-major IRR — expected 5.068, recomputed 5.068
- [PASS] ESI-variant COPD-minor IRR — expected 2.781, recomputed 2.781
- [PASS] ESI-variant COPD-major IRR — expected 4.473, recomputed 4.473
- [PASS] Both-COPD discord IRR — expected 3.170, recomputed 3.167
- [PASS] Bhatt-only-COPD discord IRR — expected 2.010, recomputed 2.011

## Step 2 — Adversarial sanity checks

- [PASS] Severe exacerbations never exceed total — expected 0, recomputed 0
- [PASS] All subjects have Years_Followed > 0 — expected TRUE, recomputed TRUE
- Simpler model (no stratum, no smoking, no PY): ESI IRR = 0.975, p = 0.199
- [PASS] Direction: lower FEV1/FVC → more exacerbations (IRR per 0.1-unit < 1) — expected TRUE, recomputed TRUE
- [PASS] Both-COPD > reference (positive coefficient) — expected TRUE, recomputed TRUE
- Pattern: ESI signal disappears after FEV1/FVC adjustment (same as respiratory mortality, opposite of all-cause mortality).

## Step 3 — Documentation accuracy

- [PASS] Prose: '8,898 subjects in exacerbation cohort' — expected 8898, recomputed 8898
- [PASS] Prose: '24,454 total exacerbations' — expected 24454, recomputed 24454
- [PASS] Prose: 'median 10.3 yr follow-up' — expected 10.300, recomputed 10.300
- [PASS] Prose: 'ESI IRR ≈ 1.11 alone (p < 0.001)' — expected TRUE, recomputed TRUE
- [PASS] Prose: 'ESI IRR ≈ 1.01 after FF (null)' — expected TRUE, recomputed TRUE
- [PASS] Prose: 'Bhatt COPD-major IRR ~5; ESI-var COPD-major IRR ~4.5; similar' — expected TRUE, recomputed TRUE
