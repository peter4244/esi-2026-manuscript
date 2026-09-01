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

The reference classification runs across the columns; the CT-free schema being
evaluated runs down the rows. Diagonal cells are participants both schemas
place in the same category.


**Schema 3. MD-COPD without CT**

| MD-COPD without CT &darr;&nbsp;&nbsp;/&nbsp;&nbsp;MD-COPD with CT &rarr; | noCOPD | AFL-only | COPD-minor | COPD-major | **total** |
|---|---|---|---|---|---|
| **noCOPD** | **3,864** | 0 | 117 | 0 | **3,981** |
| **AFL-only** | 0 | **170** | 0 | 949 | **1,119** |
| **COPD-minor** | 339 | 0 | **969** | 0 | **1,308** |
| **COPD-major** | 0 | 0 | 0 | **2,994** | **2,994** |
| **total** | 4,203 | 170 | 1,086 | 3,943 | **9,402** |

Concordant with MD-COPD in 7,997 of 9,402 participants (85.1%).


**Schema 4. MD-COPD with ESI**

| MD-COPD with ESI &darr;&nbsp;&nbsp;/&nbsp;&nbsp;MD-COPD with CT &rarr; | noCOPD | AFL-only | COPD-minor | COPD-major | **total** |
|---|---|---|---|---|---|
| **noCOPD** | **3,805** | 0 | 98 | 0 | **3,903** |
| **AFL-only** | 0 | **77** | 0 | 233 | **310** |
| **COPD-minor** | 398 | 0 | **988** | 0 | **1,386** |
| **COPD-major** | 0 | 93 | 0 | **3,710** | **3,803** |
| **total** | 4,203 | 170 | 1,086 | 3,943 | **9,402** |

Concordant with MD-COPD in 8,580 of 9,402 participants (91.3%).


## Table 3. Crude and adjusted risk within each schema's own categories

Each estimate is against that schema's own noCOPD reference. Crude ratios are
the observed event rate in the category divided by the observed rate in the
reference, with 95% percentile intervals from a subject resample bootstrap;
adjusted estimates are hazard ratios (mortality) and incidence-rate ratios
(exacerbations) from models carrying age, sex, race, current smoking status,
pack-years and body mass index, with prior exacerbation frequency added for
exacerbations. Reading each pair together shows how much of an association the
covariates account for.

| Schema | Category | n | All-cause crude RR | All-cause adjusted HR | Respiratory crude RR | Respiratory adjusted HR | Exacerbation crude RR | Exacerbation adjusted IRR |
|---|---|---|---|---|---|---|---|---|
| 1 Fixed ratio | noCOPD | 5,289 | reference | reference | reference | reference | reference | reference |
|  | COPD | 4,111 | 2.84 (2.63–3.08) | 2.17 (1.99–2.37) | 35.08 (24.44–57.33) | 21.98 (14.54–33.23) | 3.16 (2.91–3.46) | 3.03 (2.77–3.32) |
| 2 MD-COPD with CT | noCOPD | 4,203 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 170 | 1.08 (0.73–1.49) | 0.90 (0.62–1.30) | 1.70 (0.00–7.17) | 1.42 (0.19–10.84) | 1.15 (0.81–1.55) | 1.35 (1.00–1.81) |
|  | COPD-minor | 1,086 | 1.85 (1.60–2.13) | 1.91 (1.64–2.22) | 3.90 (1.56–9.03) | 4.80 (2.14–10.76) | 3.09 (2.65–3.63) | 2.16 (1.88–2.49) |
|  | COPD-major | 3,941 | 3.39 (3.11–3.71) | 2.59 (2.35–2.86) | 56.05 (35.90–109.15) | 36.27 (20.85–63.07) | 4.46 (4.06–4.92) | 3.82 (3.48–4.21) |
| 3 without CT | noCOPD | 3,981 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 1,119 | 1.56 (1.35–1.79) | 1.13 (0.97–1.31) | 9.64 (5.46–20.20) | 6.61 (3.41–12.79) | 1.74 (1.48–2.03) | 1.80 (1.58–2.05) |
|  | COPD-minor | 1,308 | 1.73 (1.51–1.98) | 1.97 (1.71–2.28) | 3.53 (1.37–7.89) | 5.05 (2.26–11.29) | 3.36 (2.87–3.88) | 2.40 (2.11–2.73) |
|  | COPD-major | 2,992 | 4.13 (3.77–4.51) | 3.34 (3.02–3.69) | 76.14 (47.00–155.65) | 51.62 (29.03–91.78) | 6.24 (5.64–6.88) | 4.87 (4.40–5.40) |
| 4 with ESI | noCOPD | 3,903 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 310 | 1.30 (0.98–1.65) | 0.94 (0.72–1.22) | 4.23 (0.71–11.83) | 3.02 (0.96–9.51) | 1.09 (0.84–1.36) | 1.12 (0.89–1.40) |
|  | COPD-minor | 1,386 | 1.76 (1.53–2.01) | 1.94 (1.68–2.24) | 3.88 (1.63–9.18) | 5.31 (2.37–11.90) | 3.28 (2.82–3.79) | 2.29 (2.01–2.61) |
|  | COPD-major | 3,801 | 3.55 (3.24–3.88) | 2.76 (2.50–3.05) | 64.23 (39.37–137.90) | 42.72 (23.45–77.82) | 5.18 (4.67–5.71) | 4.19 (3.80–4.62) |

## Results sentence, replacing the former Table 5

> MD-COPD improved on the fixed ratio for every outcome. Because fixed-ratio
> COPD comprises exactly the AFL-only-noCOPD and COPD-major categories, the
> two models are nested, and the four-category classification added
> information beyond the fixed ratio for all-cause mortality
> (likelihood ratio chi-square 110.2 on 2 df), respiratory mortality (53.9)
> and exacerbations (162.4), all p < 0.001. The gain in discrimination was
> small, with the C-index rising from 0.694 to 0.703 for all-cause mortality,
> so the framework's advantage lies in reclassifying an identifiable
> minority correctly rather than in improved prediction overall.


---

# Supplement

Discrimination and the threshold fitting are supporting detail rather than
the argument, so they sit here rather than in the main tables.


## Table S1. Discrimination under each schema

Every model carries the same covariates. The symptoms-only schema has the
best discrimination on all three outcomes; Table 3 shows what it costs to
get it.

| Schema | All-cause C-index | Respiratory C-index | Exacerbation AIC |
|---|---|---|---|
| 1 Fixed ratio | 0.6945 | 0.8454 | 30326 |
| 2 MD-COPD with CT | 0.7034 | 0.8527 | 30168 |
| 3 without CT | 0.7219 | 0.8755 | 29970 |
| 4 with ESI | 0.7079 | 0.8581 | 30066 |

## Table S2. Fitting the CT-free schemas to approximate MD-COPD

| Schema | Count threshold | ESI threshold | In-sample macro-F1 | Held-out macro-F1 |
|---|---|---|---|---|
| 3 without CT | ≥ 2 | — | 0.7202 | 0.7203 |
| 4 with ESI | ≥ 2 | 1.25 | 0.7542 | 0.7532 |

Schema 4 exceeds schema 3 by 0.0329 (0.0159 to 0.0498) across 25 held-out folds.

