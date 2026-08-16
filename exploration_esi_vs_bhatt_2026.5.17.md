# ESI as a substitute for CT-imaging criteria in the Bhatt 2025 schema

**Cohort**: V1 subjects with valid ESI and all Bhatt criteria variables non-missing: n = 9463.

Bhatt schema (n of 5 minor criteria collapsed):

- **AFL-only-NoCOPD**: 170 (1.8%)
- **COPD-major**: 3969 (41.9%)
- **COPD-minor**: 1099 (11.6%)
- **noCOPD**: 4225 (44.6%)

## Bhatt classification by spectrum stratum

  stratum noCOPD COPD-minor AFL-only-NoCOPD COPD-major
1   Never    107          0               0          0
2   GOLD0   3391        682               0          0
3   PRISm    727        417               0          0
4   GOLD1      0          0              92        651
5   GOLD2      0          0              73       1726
6   GOLD3      0          0               5       1058
7   GOLD4      0          0               0        534

## Agreement of ESI-substituted vs original Bhatt classification, across ESI thresholds

ESI-substituted variant: replace the 2 imaging criteria with 1 ESI criterion (`ESI ≥ T`).  Major category: major + ≥1 of {ESI, dysp, qol, cb}.  Minor category: !major + ≥2 of {ESI, dysp, qol, cb}.

Truth: Bhatt classification (≥3 of 5 minors).  Candidate: 4-criterion ESI-substituted classification.  Outcome of interest: **COPD (major OR minor) vs no COPD**.

| ESI threshold | n COPD (Bhatt) | n COPD (ESI variant) | Sens | Spec | Agreement (κ) | Reclassified to COPD | Reclassified to noCOPD |
|---:|---:|---:|---:|---:|---:|---:|---:|
| ESI ≥ 1.0 | 5068 | 5616 | 0.974 | 0.846 | 0.827 | 678 | 130 |
| ESI ≥ 1.5 | 5068 | 4952 | 0.892 | 0.902 | 0.793 | 430 | 546 |
| ESI ≥ 2.0 | 5068 | 4663 | 0.848 | 0.916 | 0.760 | 367 | 772 |
| ESI ≥ 2.5 | 5068 | 4559 | 0.830 | 0.919 | 0.743 | 355 | 864 |
| ESI ≥ 3.0 | 5068 | 4497 | 0.818 | 0.920 | 0.732 | 351 | 922 |
| ESI ≥ 3.5 | 5068 | 4458 | 0.811 | 0.920 | 0.724 | 350 | 960 |
| ESI ≥ 4.0 | 5068 | 4430 | 0.806 | 0.921 | 0.720 | 346 | 984 |

## ROC: ESI as a continuous predictor of Bhatt minor-category COPD in preserved-spirometry subjects

Restricted to subjects without airflow obstruction (FEV1/FVC ≥ 0.70).  Outcome: classified by Bhatt as COPD-minor (i.e., ≥ 3 of 5 minor criteria, without airflow obstruction) vs not classified as COPD.

Preserved-spirometry subset (FEV1/FVC ≥ 0.70): n = 5324; Bhatt minor-category COPD = 1099 (20.6%).

**ROC AUC for ESI alone**: 0.535 (95% CI 0.516–0.555)
**Best ESI threshold by Youden index**: 0.98 (sens = 0.33, spec = 0.73).

### Per-stratum ROC (preserved-spirometry subset)

| Stratum | n | Bhatt minor-COPD | AUC | 95% CI |
|---|---:|---:|---:|---|
| Never | 107 | 0 | — | (insufficient) |
| GOLD0 | 4073 | 682 | 0.527 | 0.502–0.551 |
| PRISm | 1144 | 417 | 0.555 | 0.521–0.589 |

## Cross-tabulation at ESI ≥ 1.0 (closest to Youden-optimal)

Full-cohort 4-way table:

```
                 ESI_variant
Bhatt             AFL-only-NoCOPD COPD-major COPD-minor noCOPD
  AFL-only-NoCOPD              21        149          0      0
  COPD-major                   63       3906          0      0
  COPD-minor                    0          0       1032     67
  noCOPD                        0          0        529   3696
```


Simplified COPD vs noCOPD agreement:

```
          ESI_COPD
Bhatt_COPD FALSE TRUE
     FALSE  3717  678
     TRUE    130 4938
```


## Discordant subjects (where ESI variant disagrees with Bhatt)

- Discordant TO COPD (Bhatt says noCOPD, ESI variant says COPD): n = 678.  These are typically high-ESI subjects who failed the 2-imaging or 3-of-5 thresholds.
- Discordant TO noCOPD (Bhatt says COPD, ESI variant says noCOPD): n = 130.  These are typically subjects whose Bhatt minor diagnosis was driven by imaging+symptoms but with low ESI.

### Discordance by spectrum stratum

  stratum Bhatt-noCOPD, ESI-COPD Both noCOPD Bhatt-COPD, ESI-noCOPD Both COPD
1   Never                      4         103                      0         0
2   GOLD0                    377        3014                     52       630
3   PRISm                    148         579                     15       402
4   GOLD1                     81          11                     31       620
5   GOLD2                     64           9                     32      1694
6   GOLD3                      4           1                      0      1058
7   GOLD4                      0           0                      0       534
