# v9 Main-Manuscript + Supplement Review — Fix Plan (2026-07-20)

## Origin
Two independent Plan-agent reviewers were spawned in parallel — one for scientific-content correctness, one for prose/style — after Pete's supplement fixes shipped and the legend rewrite in NMD style was complete. Their findings, plus a follow-up factual audit of the analysis Rmd triggered by Pete's BMI-adjustment question, are folded into this ordered fix plan.

Current build state: main 12 OK / 0 FAIL, supplement 36 OK / 0 FAIL, foundation 19 PASS, verification 40 PASS. Fixes must not regress those numbers.

---

## Guiding factual finding: adjustment covariates by model class

Sourced from `esi_manuscript_analysis_2026.7.17.Rmd` (the SSOT). Three distinct adjustment sets are used:

| Adjustment set | Tables using it | Covariates |
| --- | --- | --- |
| **A. Mortality/exacerbations, categorical** | Table 1, Table 2, S3a, S3b, S3c, S4a, S4b, S4c, S8, S9a, S9b | age, sex, race, current smoker, pack-years, **BMI** |
| **B. FEV₁ decline (LMM)** | S5, S6d | age, sex, race, current smoker, pack-years, **Height_CM**, random intercept per participant |
| **C. Continuous ESI (mortality + exacerbations)** | S6a, S6b, S6c | age, sex, race, current smoker, pack-years, **GOLD stratum** |

**Methods currently says** "Models were adjusted for age, sex, race, current smoking status, pack-years, and body mass index. Models of FEV₁ decline additionally included baseline height." — this understates the diversity. Height_CM **replaces** BMI in FEV1-decline models, not adds; and GOLD stratum **replaces** BMI in continuous-ESI models, not adds. **Methods L48 must be rewritten** to describe all three adjustment sets explicitly (see M2 below).

---

## Phase N1 — Confirmed content errors (must fix)

Ordered by blast radius (Methods first — everything cross-references it):

1. **`prose/04_methods.md` L48**: rewrite the covariate paragraph to describe **all three** adjustment sets (A/B/C above). Draft:
   > "Cox proportional-hazards (mortality) and negative-binomial (exacerbations) models used the categorical Bhatt-framework categories or cross-classification groups as the exposure and adjusted for age, sex, race, current smoking status, pack-years, and body mass index. Linear mixed-effects models of longitudinal FEV₁ decline adjusted for the same covariates except that body mass index was replaced by baseline height (Height_CM), with a random intercept per participant. Continuous-ESI models replaced body mass index with GOLD-stratum indicators."
2. **`prose/04_methods.md` L28**: threshold rule inconsistency — "values below the lower threshold (≤1)". Change to either strict `<` or reword: "ESI ≤ 1 contributes zero minor criteria; ESI > 1 and < 2.5 contributes one; ESI ≥ 2.5 contributes two." Clarify what the exact rule at ESI = 1.000 is.
3. **`prose/04_methods.md`** (Statistical analysis, currently missing): add a sentence on the **paired-bootstrap** procedure (n = 2000 replicates) used for S8: "Framework equivalence at the category level was tested using a paired-bootstrap procedure (2,000 replicates resampling participants with replacement) to construct 95% percentile intervals for the between-framework log-hazard-ratio difference (ΔlogHR)."
4. **`prose/04_methods.md`** (Statistical analysis): add a sentence on **pairwise-contrast adjustment** used for Table 2 + S9a/b: "Pairwise Wald contrasts among the three COPD-positive cross-classification groups were single-step-adjusted using the `multcomp` package."
5. **`tables/supp/s4a_cvd_legend.md`, `s4b_cancer_legend.md`, `s4c_other_legend.md`**: append ", and body mass index" to the covariate list. Their models DO include BMI (per Rmd L763-766 which uses the standard `covs` string).
6. **`tables/supp/s6a_continuous_mortality_all_legend.md`, `s6b_continuous_mortality_resp_legend.md`, `s6c_continuous_exacerbations_legend.md`**: DO NOT add BMI (the models omit it). Instead, replace the last sentence to accurately name the adjustment set: "Adjusted for age, sex, race, current smoking status, pack-years, and GOLD-stratum indicators."
7. **`tables/supp/s5_fev1_decline_legend.md`**: replace covariate description with the LMM adjustment: "Adjusted for age at baseline, sex, race, current smoking status, pack-years, and baseline height (Height_CM), with a random intercept per participant."
8. **`tables/supp/s6d_continuous_fev1_decline_legend.md`**: change to "Adjusted for age at baseline, sex, race, current smoking status, pack-years, and baseline height (Height_CM)."
9. **`tables/supp/s3a_esi10_excluded_legend.md`**: "n = 84 ceiling-value participants excluded" — verify against `esi_manuscript_analysis_2026.7.17.Rmd`. If unverifiable, drop the exact n and say "participants at the ESI ceiling excluded."

---

## Phase N2 — Content gaps a reader would want (fix)

10. **`figures/figure2_discordance/figure2_discordance_legend.md`**: state the population restriction in the opening sentence — the figure is limited to preserved-spirometry subgroups (COPD-minor pathway), not the whole discordance universe. Also mirror this restriction in **`prose/05_results.md` L24-26** so the prose sentence about "distinct clinical and structural profiles (Figure 2)" makes the subgroup limitation explicit.
11. **`prose/06_discussion.md` L8**: quote the n behind the ΔESI = −0.09 bronchodilator observation ("in n = 10,160 paired pre/post-BD measurements") — or drop the specific number if it can't be sourced.
12. **`prose/04_methods.md`** (or a new supp table): the stratified ESI–CT correlation r values used in Results L10 (r = 0.77 overall for %LAA-950HU; r = 0.08 in GOLD 0; r = 0.58 in GOLD 3) aren't presented in a supp table — either add a compact supp table drawn from `Table_2.csv` / `Table_2_PRMversion.csv` OR add a sentence to Methods saying "per-stratum correlations are provided in the text only."

---

## Phase N3 — Confirmed style errors (must fix before submission)

13. **`prose/02_abstract.md` L17**: "high sensitivity (88%), and specificity (94%)" — rewrite: "sensitivity 88% and specificity 94%" (drops the awkward elision of "high").
14. **`prose/04_methods.md` L46**: define "PRM emphysema" on first use as "parametric response mapping (PRM) emphysema" (currently spelled out only later in Results).
15. **`prose/05_results.md` L36-38**: split the two consecutive "In both frameworks" sentences; move the AFL-only-noCOPD summary sentence out of the FEV1-decline paragraph and into the prognostic-performance paragraph (line 30-32 vicinity).
16. **`prose/06_discussion.md` L20**: orphaned single-sentence paragraph about PRISm vs GOLD 0 ESI trajectories — consolidate with the immediately preceding secondary-analysis paragraph (line 18).

---

## Phase N4 — Style polish (worth addressing)

17. **`prose/05_results.md` L8**: switch nomenclature — "107 never-smokers, 4,073 smokers … 1,144 subjects with PRISm … 4,139 subjects with GOLD 1–4" → replace "subjects" with "participants" throughout for consistency.
18. **`prose/05_results.md`**: verb variation — "showed" appears ~9 times in Results; substitute "demonstrated", "yielded", "were associated with", "displayed" for 3-4 of these, especially in adjacent sentences.
19. **`prose/06_discussion.md` L4**: "framework" 6× in one paragraph — vary with "approach", "classification", pronouns.
20. **`prose/06_discussion.md` L12**: split the long compound sentence "This finding may reflect the ability of visual CT assessment … even mild visually identified emphysema (11)" at "not captured by quantitative emphysema burden."
21. **`prose/06_discussion.md` L18**: "individualized" twice within three sentences — vary the second occurrence.
22. **`prose/05_results.md` L56**: recast "…continuous measure, ESI provided…" → "…continuous measure, it provided…" (drops back-to-back ESI).
23. **`prose/06_discussion.md` L14**: drop the soft-emphasis "Importantly,"; the sentence stands on its own.
24. **`prose/03_introduction.md` L8**: paragraph restates the CT-unavailability point already made at L6 — condense the two to one bridging sentence.
25. **`prose/04_methods.md` L8**: "derived" appears twice in one sentence — recast.

---

## Phase N5 — Content plausibility flags (Discussion additions, non-blocking)

Not "errors" per se, but the manuscript should acknowledge these to be defensible in review:

26. **`prose/06_discussion.md` limitations paragraph**: add a sentence acknowledging (a) ESI-only-COPD n = 95 → wide CIs → some claims are limited by precision, and (b) AFL-only-noCOPD n = 170 → the null HR does not rule out modest true effects.
27. **`prose/06_discussion.md` (secondary-analyses paragraph)**: acknowledge that continuous ESI adjusted for FEV1/FVC has near-null exacerbation IRR (~1.01, p ≈ 0.70), i.e., "continuous ESI adds little beyond FEV1/FVC for the exacerbation outcome, in contrast to the mortality and FEV1-decline outcomes." Currently the discussion only highlights positive continuous-ESI findings.
28. **`prose/06_discussion.md` L12**: refine the visual-vs-quantitative claim — the Both-COPD group's %LAA-950 (~1.7%) is not meaningfully different from the Bhatt-only group's (~1.4%), so the "visual emphysema despite quantitative CT within normal range" phenomenon is not unique to the Bhatt-only discordant subgroup. Reword to make this a general framework observation, not a discordance-specific one.

---

## Phase N6 — Citation misplacement (must fix if kept, or drop the citation)

29. **`prose/06_discussion.md` L10**: ref (18) (Lynch 2015 Fleischner CT subtypes) doesn't support the mechanistic claim about correlation attenuation in minimal-disease groups. Either replace with a more targeted citation OR drop the parenthetical citation from this specific sentence.
30. **`prose/06_discussion.md` L6**: ref (24) (Stanojevic 2022 ERS/ATS interpretation standard) doesn't describe expiratory-curve-shape biology. Replace with a more targeted small-airway-physiology citation OR drop from this sentence.
31. **`tables/supp/s1_thresholds_legend.md`**: reconcile "pre-specified" claim with Methods description of rpart training. Options: (a) rename SELECTED variant description as "cohort-selected" instead of "pre-specified," or (b) add a Methods sentence clarifying that the two-threshold form was pre-specified even though the specific numerical values were data-driven from 80% training.

---

## Phase N7 — Legend-style follow-ups (NMD-parity polish, non-blocking)

32. **`figures/figure2_discordance/figure2_discordance_legend.md`**: if Figure 2 has a labeled grid layout, replace "Top-row panels / Bottom-row panels" narrative with explicit **(A) … (B) … (C) …** inline descriptions matching NMD style. If it's a two-row unlabeled grid, this is optional.
33. **`tables/supp/s4a_cvd_legend.md`, `s4b_cancer_legend.md`, `s4c_other_legend.md`**: the "Category totals (Bhatt-framework, at risk): AFL-only-noCOPD n=170, COPD-minor n=1,099, COPD-major n=3,969" line is repeated verbatim across all three. Optional: move to a shared S4 preamble.

---

## Phase N8 — Verify

34. `python3 build_manuscript.py` + `python3 build_supplement.py` — expect 12 OK / 36 OK / 0 FAIL each.
35. `python3 tests/test_foundation.py` — expect 19 PASS.
36. `python3 tests/test_verification.py` — expect 40 PASS (may need to re-tune the T-VERIF-3 prefix-match tolerance if a consolidation edit lands mid-sentence).
37. Render supplement PDF and eyeball the S4/S5/S6/S6d legends to confirm the covariate wording lands cleanly.
38. Spot-check Methods L48 rewrite against the Rmd model formulas (should be verbatim-consistent with the three adjustment sets).

---

## Execution order

- **N1 first** (content errors, especially the Methods rewrite — every other legend fix cascades from that language)
- **N2 next** (content gaps)
- **N3, N4 in parallel** (style)
- **N5 as a Discussion-only pass** (limitation acknowledgments — non-blocking but strong reviewer-defense material)
- **N6, N7** (polish)
- **N8** (verify)

## Open questions the plan defers to Pete

1. Phase N2 item 12 (per-stratum correlation supp table) — worth adding? Or leave in prose only?
2. Phase N5 items 26-28 (Discussion additions acknowledging limitations) — I recommend all three, but Pete may want to keep some claims stronger.
3. Phase N6 item 31 (S1 "pre-specified" wording) — Pete's call on whether the training-set derivation should be described more prominently.
