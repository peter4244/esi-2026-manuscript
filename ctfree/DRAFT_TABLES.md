# Draft tables — CT-free MD-COPD paper

Generated from `ctfree/assets/`. Every value is read from an artifact.

## Table 1. Four classification schemas and how they label the cohort

| | Major criterion | Minor criteria | noCOPD | AFL-only-noCOPD | COPD-minor | COPD-major |
|---|---|---|---|---|---|---|
| **1** Fixed ratio | FEV~1~/FVC < 0.70 | none | 5,289 | — | — | 4,113 |
| **2** MD-COPD with CT | FEV~1~/FVC < 0.70 | emphysema, wall thickening, dyspnea, SGRQ, chronic bronchitis (≥3) | 4,203 | 170 | 1,086 | 3,943 |
| **3** MD-COPD without CT | FEV~1~/FVC < 0.70 | dyspnea, SGRQ, chronic bronchitis (≥2) | 3,981 | 1,119 | 1,308 | 2,994 |
| **4** MD-COPD with ESI | FEV~1~/FVC < 0.70 | ESI ≥ 1.25, dyspnea, SGRQ, chronic bronchitis (≥2) | 3,903 | 310 | 1,386 | 3,803 |

MD-COPD reference counts are 4,203, 170, 1,086 and 3,943.

## Table 2. Where participants move when CT is removed

Rows are MD-COPD with CT. Columns are the CT-free schema.


**Schema 3, MD-COPD without CT**

| MD-COPD with CT | noCOPD | AFL-only | COPD-minor | COPD-major | total |
|---|---|---|---|---|---|
| noCOPD | **3,864** | 0 | 339 | 0 | 4,203 |
| AFL-only | 0 | **170** | 0 | 0 | 170 |
| COPD-minor | 117 | 0 | **969** | 0 | 1,086 |
| COPD-major | 0 | 949 | 0 | **2,994** | 3,943 |
| **stays in the same category** | 7,997 of 9,402 (85.1%) | | | | |

**Schema 4, MD-COPD with ESI**

| MD-COPD with CT | noCOPD | AFL-only | COPD-minor | COPD-major | total |
|---|---|---|---|---|---|
| noCOPD | **3,805** | 0 | 398 | 0 | 4,203 |
| AFL-only | 0 | **77** | 0 | 93 | 170 |
| COPD-minor | 98 | 0 | **988** | 0 | 1,086 |
| COPD-major | 0 | 233 | 0 | **3,710** | 3,943 |
| **stays in the same category** | 8,580 of 9,402 (91.3%) | | | | |

## Table 3. Risk within each schema's own categories

| Schema | Category | n | All-cause HR (95% CI) | Respiratory HR (95% CI) | Exacerbation IRR (95% CI) |
|---|---|---|---|---|---|
| 1 Fixed ratio | noCOPD | 5,289 | reference | reference | reference |
|  | COPD | 4,111 | 2.17 (1.99–2.37) | 21.98 (14.54–33.23) | 3.03 (2.77–3.32) |
| | *discrimination* | | *C = 0.6945* | *C = 0.8454* | *AIC = 30326* |
| 2 MD-COPD with CT | noCOPD | 4,203 | reference | reference | reference |
|  | AFL-only | 170 | 0.90 (0.62–1.30) | 1.42 (0.19–10.84) | 1.35 (1.00–1.81) |
|  | COPD-minor | 1,086 | 1.91 (1.64–2.22) | 4.80 (2.14–10.76) | 2.16 (1.88–2.49) |
|  | COPD-major | 3,941 | 2.59 (2.35–2.86) | 36.27 (20.85–63.07) | 3.82 (3.48–4.21) |
| | *discrimination* | | *C = 0.7034* | *C = 0.8527* | *AIC = 30168* |
| 3 without CT | noCOPD | 3,981 | reference | reference | reference |
|  | AFL-only | 1,119 | 1.13 (0.97–1.31) | 6.61 (3.41–12.79) | 1.80 (1.58–2.05) |
|  | COPD-minor | 1,308 | 1.97 (1.71–2.28) | 5.05 (2.26–11.29) | 2.40 (2.11–2.73) |
|  | COPD-major | 2,992 | 3.34 (3.02–3.69) | 51.62 (29.03–91.78) | 4.87 (4.40–5.40) |
| | *discrimination* | | *C = 0.7219* | *C = 0.8755* | *AIC = 29970* |
| 4 with ESI | noCOPD | 3,903 | reference | reference | reference |
|  | AFL-only | 310 | 0.94 (0.72–1.22) | 3.02 (0.96–9.51) | 1.12 (0.89–1.40) |
|  | COPD-minor | 1,386 | 1.94 (1.68–2.24) | 5.31 (2.37–11.90) | 2.29 (2.01–2.61) |
|  | COPD-major | 3,801 | 2.76 (2.50–3.05) | 42.72 (23.45–77.82) | 4.19 (3.80–4.62) |
| | *discrimination* | | *C = 0.7079* | *C = 0.8581* | *AIC = 30066* |

## Table 4. Fitting the CT-free schemas to approximate MD-COPD

| Schema | Count threshold | ESI threshold | In-sample macro-F1 | Held-out macro-F1 |
|---|---|---|---|---|
| 3 without CT | ≥ 2 | — | 0.7202 | 0.7203 |
| 4 with ESI | ≥ 2 | 1.25 | 0.7542 | 0.7532 |
| *v15 draft rule* | ≥ 3 | 1.00 | 0.6754 | 0.6752 |

Schema 4 exceeds schema 3 by 0.0329 (0.0159 to 0.0498) across 25 held-out folds.

## Table 5. MD-COPD versus the fixed ratio (nested likelihood ratio test)

| Outcome | C-index, fixed ratio | C-index, MD-COPD | LR χ² (2 df) | p |
|---|---|---|---|---|
| ALL-CAUSE MORTALITY | 0.6945 | 0.7034 | 110.2 | <1e-16 |
| RESPIRATORY MORTALITY | 0.8454 | 0.8527 | 53.9 | 2e-12 |
| EXACERBATIONS | — | — | 162.4 | <1e-16 |
