# Draft tables — CT-free MD-COPD paper

Generated from `ctfree/assets/`. Every value is read from an artifact.

## Table 1. Four classification schemas and how they label the cohort

| | Major criterion | Minor criteria | noCOPD | AFL-only | COPD-minor | COPD-major |
|---|---|---|---|---|---|---|
| **1** Fixed ratio | FEV~1~/FVC < 0.70 | none | 5,156 | — | — | 4,084 |
| **2** MD-COPD with CT | FEV~1~/FVC < 0.70 | emphysema, wall thickening, dyspnea, SGRQ, chronic bronchitis (≥3) | 4,357 | 275 | 799 | 3,809 |
| **3** MD-COPD without CT | FEV~1~/FVC < 0.70 | dyspnea, SGRQ, chronic bronchitis (≥2) | 3,853 | 1,108 | 1,303 | 2,976 |
| **4** MD-COPD with ESI | FEV~1~/FVC < 0.70 | ESI ≥ 1.50, dyspnea, SGRQ, chronic bronchitis (≥2) | 3,815 | 543 | 1,341 | 3,541 |

MD-COPD reference counts are 4,357, 275, 799 and 3,809.

## Table 2. Where participants move when CT is removed

The reference classification runs across the columns; the CT-free schema being
evaluated runs down the rows. Diagonal cells are participants both schemas
place in the same category.


**Schema 3. MD-COPD without CT**

| MD-COPD without CT &darr;&nbsp;&nbsp;/&nbsp;&nbsp;MD-COPD with CT &rarr; | noCOPD | AFL-only | COPD-minor | COPD-major | **total** |
|---|---|---|---|---|---|
| **noCOPD** | **3,778** | 0 | 75 | 0 | **3,853** |
| **AFL-only** | 0 | **275** | 0 | 833 | **1,108** |
| **COPD-minor** | 579 | 0 | **724** | 0 | **1,303** |
| **COPD-major** | 0 | 0 | 0 | **2,976** | **2,976** |
| **total** | 4,357 | 275 | 799 | 3,809 | **9,240** |

Concordant with MD-COPD in 7,753 of 9,240 participants (83.9%).


**Schema 4. MD-COPD with ESI**

| MD-COPD with ESI &darr;&nbsp;&nbsp;/&nbsp;&nbsp;MD-COPD with CT &rarr; | noCOPD | AFL-only | COPD-minor | COPD-major | **total** |
|---|---|---|---|---|---|
| **noCOPD** | **3,745** | 0 | 70 | 0 | **3,815** |
| **AFL-only** | 0 | **193** | 0 | 350 | **543** |
| **COPD-minor** | 612 | 0 | **729** | 0 | **1,341** |
| **COPD-major** | 0 | 82 | 0 | **3,459** | **3,541** |
| **total** | 4,357 | 275 | 799 | 3,809 | **9,240** |

Concordant with MD-COPD in 8,126 of 9,240 participants (87.9%).


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
| 1 Fixed ratio | noCOPD | 5,156 | reference | reference | reference | reference | reference | reference |
|  | COPD | 4,082 | 2.82 (2.61–3.05) | 2.17 (1.98–2.37) | 34.19 (24.23–56.02) | 21.31 (14.09–32.21) | 3.09 (2.81–3.40) | 3.00 (2.74–3.29) |
| 2 MD-COPD with CT | noCOPD | 4,357 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 275 | 1.05 (0.79–1.37) | 0.87 (0.65–1.16) | 1.76 (0.00–5.75) | 1.39 (0.32–6.04) | 1.00 (0.77–1.25) | 1.21 (0.95–1.54) |
|  | COPD-minor | 799 | 1.77 (1.50–2.06) | 1.83 (1.55–2.16) | 3.27 (1.16–7.10) | 3.86 (1.65–9.04) | 3.01 (2.52–3.61) | 2.09 (1.79–2.44) |
|  | COPD-major | 3,807 | 3.30 (3.02–3.59) | 2.54 (2.31–2.79) | 48.46 (31.97–95.51) | 30.80 (18.66–50.83) | 4.15 (3.76–4.55) | 3.69 (3.36–4.06) |
| 3 without CT | noCOPD | 3,853 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 1,108 | 1.54 (1.34–1.76) | 1.12 (0.97–1.30) | 9.38 (5.00–21.95) | 6.37 (3.29–12.34) | 1.72 (1.43–1.98) | 1.78 (1.56–2.03) |
|  | COPD-minor | 1,303 | 1.72 (1.51–1.98) | 1.97 (1.71–2.29) | 3.42 (1.42–8.24) | 4.88 (2.18–10.89) | 3.31 (2.86–3.81) | 2.38 (2.09–2.71) |
|  | COPD-major | 2,974 | 4.11 (3.76–4.50) | 3.34 (3.01–3.69) | 73.53 (45.61–164.37) | 49.48 (27.83–87.97) | 6.11 (5.54–6.78) | 4.82 (4.35–5.35) |
| 4 with ESI | noCOPD | 3,815 | reference | reference | reference | reference | reference | reference |
|  | AFL-only | 543 | 1.29 (1.05–1.55) | 0.96 (0.78–1.18) | 2.37 (0.44–6.99) | 1.77 (0.56–5.58) | 1.17 (0.94–1.41) | 1.23 (1.03–1.48) |
|  | COPD-minor | 1,341 | 1.75 (1.53–2.00) | 1.96 (1.70–2.27) | 3.89 (1.64–9.81) | 5.37 (2.40–12.03) | 3.28 (2.83–3.80) | 2.31 (2.03–2.64) |
|  | COPD-major | 3,539 | 3.70 (3.40–4.06) | 2.93 (2.64–3.24) | 67.83 (40.97–161.48) | 44.81 (24.60–81.63) | 5.38 (4.90–5.99) | 4.41 (4.00–4.87) |

## Results sentence, replacing the former Table 5

> MD-COPD improved on the fixed ratio for every outcome. Because fixed-ratio
> COPD comprises exactly the AFL-only and COPD-major categories, the
> two models are nested, and the four-category classification added
> information beyond the fixed ratio for all-cause mortality
> (likelihood ratio chi-square 122.1 on 2 df), respiratory mortality (76.1)
> and exacerbations (158.9), all p < 0.001. The gain in discrimination was
> small, with the C-index rising from 0.693 to 0.703 for all-cause mortality,
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
| 1 Fixed ratio | 0.6929 | 0.8439 | 29835 |
| 2 MD-COPD with CT | 0.7032 | 0.8539 | 29680 |
| 3 without CT | 0.7208 | 0.8740 | 29486 |
| 4 with ESI | 0.7124 | 0.8644 | 29519 |

## Table S2. Fitting the CT-free schemas to approximate MD-COPD

| Schema | Count threshold | ESI threshold | In-sample macro-F1 | Held-out macro-F1 |
|---|---|---|---|---|
| 3 without CT | ≥ 2 | — | 0.7210 | 0.7212 |
| 4 with ESI | ≥ 2 | 1.50 | 0.7527 | 0.7519 |

Schema 4 exceeds schema 3 by 0.0307 (0.0144 to 0.0437) across 25 held-out folds.

