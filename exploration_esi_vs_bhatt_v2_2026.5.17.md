# ESI as a substitute for imaging in the Bhatt 2025 schema — v2

Setting: CT is unavailable; we have **spirometry (FEV1/FVC, ESI) + the 3 Bhatt symptom criteria** (mMRC ≥ 2; SGRQ ≥ 25; chronic bronchitis).  Does the resulting classification match Bhatt's full schema (which uses CT visual emphysema + wall thickening), and does it predict outcomes similarly?

Cohort: n = 9463 V1 subjects with valid ESI and all Bhatt criteria.

Bhatt distribution: COPD-major %d, COPD-minor %d, AFL-only-NoCOPD %d, noCOPD %d.396910991704225

## Agreement of ESI-substituted variants vs Bhatt — binary COPD vs noCOPD

| Variant | n COPD | Sens | Spec | κ |
|---|---:|---:|---:|---:|
| 4-crit, ESI≥1.5, ≥2-of-4 | 4952 | 0.892 | 0.902 | 0.793 |
| 4-crit, ESI≥2.0, ≥2-of-4 | 4663 | 0.848 | 0.916 | 0.760 |
| 4-crit, ESI≥2.5, ≥2-of-4 | 4559 | 0.830 | 0.919 | 0.743 |
| 4-crit, ESI≥1.5, ≥3-of-4 | 3983 | 0.773 | 0.985 | 0.746 |
| 4-crit, ESI≥2.0, ≥3-of-4 | 3697 | 0.725 | 0.995 | 0.706 |
| 5-crit double, T_low=1.0/T_high=2.5 | 4703 | 0.880 | 0.944 | 0.820 |
| 5-crit double, T_low=1.5/T_high=3.0 | 3986 | 0.773 | 0.985 | 0.745 |
| 5-crit double, T_low=2.0/T_high=3.5 | 3699 | 0.725 | 0.995 | 0.706 |

Best κ variant: **5-crit double, T_low=1.0/T_high=2.5**

## Per-stratum agreement among preserved-spirometry subjects

Within preserved spirometry (FEV1/FVC ≥ 0.70), the Bhatt minor-category COPD subset is the question that matters.  How well does the symptoms + ESI classification recover it?

| Stratum | n | Bhatt-COPD | ESI-variant COPD | Both | Bhatt-only | ESI-only | Sens | Spec |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Never | 107 | 0 | 0 | 0 | 0 | 0 | NA | 1.00 |
| GOLD0 | 4073 | 682 | 409 | 342 | 340 | 67 | 0.50 | 0.98 |
| PRISm | 1144 | 417 | 239 | 211 | 206 | 28 | 0.51 | 0.96 |

## Full 4-way classification cross-tab (best variant)

```
                 ESI_variant
Bhatt             AFL-only-NoCOPD COPD-major COPD-minor noCOPD
  AFL-only-NoCOPD              21        149          0      0
  COPD-major                   63       3906          0      0
  COPD-minor                    0          0        553    546
  noCOPD                        0          0         95   4130
```

## Outcome prediction: does the ESI-substituted classification predict outcomes as well as Bhatt?

Compare three classifications head-to-head for predicting (a) all-cause mortality and (b) FEV1 decline.  All models adjusted for age, sex, race, current smoking, pack-years, BMI.  Reference category: Bhatt noCOPD (or ESI noCOPD for the ESI-variant model).

### Mortality HRs (vs noCOPD reference) — adjusted Cox models

| Group | Bhatt HR (95% CI) | ESI-variant HR (95% CI) |
|---|---|---|
| AFL-only-NoCOPD | 0.90 (0.62–1.30), p=0.564 | 0.91 (0.57–1.46), p=0.705 |
| COPD-minor | 1.91 (1.64–2.22), p=4.79e-17 | 1.94 (1.63–2.32), p=3.26e-13 |
| COPD-major | 2.59 (2.35–2.86), p=2.91e-82 | 2.39 (2.18–2.63), p=8.8e-77 |

C-index — Bhatt model: 0.703; ESI-variant model: 0.700.

### FEV1 decline slope (vs noCOPD reference) — interaction term, mL/yr per group

| Group | Bhatt slope (mL/yr, p) | ESI-variant slope (mL/yr, p) |
|---|---|---|
| AFL-only-NoCOPD | +3.67, p=0.186 | +10.18, p=0.0154 |
| COPD-minor | -0.43, p=0.771 | -1.58, p=0.382 |
| COPD-major | +1.38, p=0.151 | +1.18, p=0.206 |

LMM AIC — Bhatt: 263805.1; ESI-variant: 264025.3.
