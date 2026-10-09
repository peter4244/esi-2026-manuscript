# Five-step verification of the CT-free MD-COPD manuscript: summary

Dates: 2026-10-07 to 2026-10-08. Documents verified: manuscript and supplement v5; findings carried through v6 and v7
(the current drafts, `ctfree/manuscript/CT-free MD-COPD {manuscript,supplement} draft v7.docx`).
Branch `resp-mortality-cod-window`, last commit before this summary `34870dc`.

Each step ran as a separate pass by a separate agent, so no pass inherited another's assumptions. Its full report is
in this folder. Findings marked **[checked]** were re-checked by Claude against the code or tables after the agent
reported them; the rest are the agent's reading. From 2026-10-08 COPDGene participant data were used only on
Channing (Pete), so every recomputation from participant data ran there through the Copilot window
(`notes/to_cluster/esi_ctfree/`); the laptop worked from code, prose and aggregate tables only.

## Headline

- **The paper's numbers reproduce.** An independent recomputation, written separately from the analysis code and run
  on the original `sid`-keyed data, matched the paper on all 1,141 values compared (cohort flow, classifications,
  cross-classification, Table S1, AUCs, event counts, rates, rate ratios, adjusted HRs and IRRs, follow-up, the
  counts in Methods). The one difference, the first cohort step (10,305 vs 10,371), is the ILD/bronchiectasis rows
  absent from the cluster phenotype file. **[checked]**
- **Every printed number matched its table** (step 1a, about 760 numbers; step 3). **[checked for the bootstrap and
  respiratory numbers]**
- **Two analysis corrections were made**, both approved by Pete and now in v6/v7:
  respiratory mortality censored at the end of cause-of-death coverage, and participants without follow-up excluded
  from mortality analyses. No significance call changed.
- **One sensitivity analysis was added** (Pete): a random-slope FEV₁ model, Table S7 in v7.
- **The paper's numbers now come from a single source**, the Channing run (job 6118470, plus job 6120833 for Table S7).
  verify.R: 257 claims pass.

## Step by step

| step | report | outcome |
|---|---|---|
| 1a Factual accuracy (numbers vs tables) | `step1a_numbers_vs_tables.md` | ~760 numbers, no errors; low items below |
| 1b Independent recomputation (cluster) | `step1b_cluster/`, results in `notes/from_cluster/esi_ctfree/verify_6117724/` | 1,141 values match **[checked]** |
| 2 Result correctness | `step2_result_correctness.md`, cluster checks C1–C5, C3b | 3 major findings; resolved or decided below |
| 3 Documentation accuracy | `step3_documentation_accuracy.md` | 2 high, 9 moderate, 13 low; decided or open below |
| 4 Reproducibility | `step4_reproducibility.md` | deposit and Methods-completeness gaps; mostly open |
| 5 Methods vs code | `step5_methods_vs_code.md` | 6 mismatches, none changing a number; open |

## Findings and their resolution

### Resolved by changes to the analysis or text (in v6/v7)

| # | finding | step | resolution |
|---|---|---|---|
| R1 | Respiratory mortality counted post-2018 person-time: causes come from the 2018 adjudication file, vital status runs to 2023; 762 deaths fall after the window. **[checked]** | 2 (C1) | Respiratory death = death in both files with TORCH group 1, at the vital-status time; otherwise followed for the shorter of the two files' times; the 10 (8 after exclusion) dead only in the 2018 file count as alive (Pete). Respiratory rates rose ~20–25%; HRs moved ≤1.3%; respiratory death counts and all-cause results unchanged. Methods text added (Pete approved). |
| R2 | 469 participants in the mortality analysis had zero follow-up. **[checked]** | 2 (C4, C5 diagnostic) | Excluded (Pete); mortality n 9,238 → 8,769; Methods text names the 469. |
| R3 | Bootstrap and cross-validation results depend on row order and differ at Monte Carlo level between the de-identified and identified data. **[checked]** | cluster reproduction | B = 1,000 kept (Pete); the Channing run is the single source; intervals in Abstract/Results updated (no significance change). |
| R4 | FEV₁ follow-up median (9.7 y) had an unstated denominator; mortality follow-up now differs by outcome. | 1a, 3, 4 | Results gives 11.2 y all-cause, 8.6 y respiratory (Pete). The 9.7 y denominator (5,414 with a follow-up visit) is still not named in the text: see O-text-1. |
| R5 | Legends gave the 3,856 common reference for all outcomes; mortality uses 3,625 and exacerbations 3,411. | 3 | Figure 3, Figure S1, Table S4, Table S5 legends give all three (Pete). Table S8's n column left as is (Pete). |
| R6 | FEV₁ model has a random intercept only; standard errors possibly too small. | 2 (C3b) | Random-slope sensitivity added as Table S7 (Pete): same significance pattern, standard errors ~10% wider, COPD-major excess decline about −12 to −13 vs −5 mL/yr. |

### Decided by Pete: no change

| # | finding | step |
|---|---|---|
| D1 | Figure S2 and two Results sentences present comparisons forced by the classification rules as findings, and the legend says such comparisons are not tested. **[checked]** | 2, 3, 5 |
| D2 | "Beyond conventional spirometric indices" (At a Glance, Discussion) is not supported: FEV₁/FVC discriminates the CT criteria at least as well as ESI in 5 of 6 comparisons (the sixth a tie), and in C2 a fitted FEV₁/FVC ≤ 0.62 criterion matched ESI (macro-F1 0.771 vs 0.763; AFL-only ratios similar). **[checked]** Pete: important; leave the language for now. | 2, 3, C2 |
| D3 | Without airflow limitation only 9.8% of the 501 ESI-only participants meet ESI ≥ 1.50. **[checked]** Pete: described well as is. | 2 |
| D4 | "Symptom criteria were more frequent in the ESI-only group" although chronic bronchitis goes the other way (28.2% vs 15.0%). Pete: true of symptoms overall. | 3 (v5 review) |

### Text items (decided by Pete, 2026-10-08)

Fixed in v8 (commit `62bd7f1`): O-text-2, O-text-3, O-text-4 (Abstract 248, main text 3,272, counted from the
built document with labels and headings), O-text-9 (discordant groups named CT-only/ESI-only throughout; Figure S1
axis "Rate ratio, HR or IRR"; Figure S2 "Wall thickening (visual)"; Figure 2 colour key and minor/major in the
legend). No change, per Pete: O-text-1, O-text-5, O-text-6, O-text-7, O-text-8.

The items as originally listed:

| # | item | step |
|---|---|---|
| O-text-1 | Name the denominator of the 9.7-year FEV₁ follow-up ("among the 5,414 participants with at least one follow-up spirometry"). Suggested to Pete on 2026-10-08; not applied. | 1a, 3 |
| O-text-2 | Results: "than among those without airflow (AUC 0.56 …" is missing "limitation". | 1a, 3 |
| O-text-3 | Abstract writes "P<0.005"; elsewhere "P < 0.005". | 1a |
| O-text-4 | Word counts are typed into the sources ("(word count 250)", "(Word count 3182)"), not computed, and v6/v7 added sentences. Recount in Word before submission. | 1a |
| O-text-5 | "Concentrated among participants with airflow limitation" (Abstract, Discussion): without airflow limitation MD-COPD-ESI agrees slightly less well than MD-NoCT (difference of 31 participants), so "confined" is the stronger reading. Agents disagree; wording call. | 1a, 3 |
| O-text-6 | Discussion: "eliminated the primary diagnostic benefit" overstates (MD-NoCT AFL-only adjusted HR vs reference 1.11 [0.95–1.29]). | 3 |
| O-text-7 | Discussion's COPD-minor claim has no counterpart in Results. C3b(b) gives a decomposition for the FEV₁ part: preserved-spirometry CT-only −12.7 mL/yr (n = 85), ESI-only +3.7 (n = 501) vs the common reference. | 2, 3 |
| O-text-8 | Abstract omits that the adjusted MD-NoCT all-cause difference was not significant (P = 0.074 in v6/v7). | 3 |
| O-text-9 | Figure 2 panel A has no colour key; "Wall thick." in Figure S2 undefined; Figure S1 x-axis label omits IRR; discordance-group names vary across sections. | 3 |

### Methods vs code and deposit items (decided by Pete, 2026-10-08)

Repository fixes applied (commit `2db946e`): O-r-2, O-r-3, O-r-5, O-r-6 (documented), O-r-7 (34 more verify.R
claims; 291 pass), O-r-4 (`ctfree/SOFTWARE_VERSIONS.md`, from Channing). Manuscript text: **no change** to the
Methods-vs-code items (O-m-1 to O-m-6), the R version sentence, or the statements (O-r-1), per Pete ("I don't feel
like those changes are really needed"). Proposed wording kept in `TEXT_PROPOSALS_methods_deposit.md` for reference.

The items as originally listed:

### Methods vs code (step 5; none changes a number)

| # | mismatch |
|---|---|
| O-m-1 | Methods say candidate thresholds were cross-validated with κ, mean sensitivity and macro-F1; the code cross-validates macro-F1 (and held-out agreement) only; κ and mean sensitivity are full-cohort. Stratification and seed not stated. (Steps 4 and 5 independently.) |
| O-m-2 | The ESI cut-point (1.50) is a fitted parameter (45-rule grid, k 2–4 × ESI 0.50–4.00); the main Methods mention only the fitted count. Table S2's legend says "each candidate rule" but shows 9. |
| O-m-3 | FEV₁ model: age, smoking status and pack-years are per-visit, not baseline; participants with only visit 1 are included; P values are Satterthwaite. |
| O-m-4 | Who is in each common-reference model is not stated (participants noCOPD under one classification but outside the common reference are dropped). |
| O-m-5 | The Supplement presents the visual-CT rules as part of the MD-COPD-CT classification; MD-COPD-CT comes from Bhatt's file and the rules are used only for the AUCs and discordance profiles. Figure 1 AUCs use 9,240 (4 unscored counted as negative) while the legend says 9,236. |
| O-m-6 | Omissions: bootstrap P formula; failed-fit handling; McNemar without continuity correction; averaging of replicate ESI; missing criteria counted as not met; the bronchodilator CI and its paired test exist only in verify.R (n = 9,234). |

### Open: deposit and reproducibility (step 4)

| # | item |
|---|---|
| O-r-1 | No data availability, code availability, funding/COPDGene acknowledgment, or ethics/consent statement. The supplement's file list omits the ESI values file. |
| O-r-2 | The changit snapshot's root README names four figure scripts that no longer exist and says `ctfree/manuscript/` holds drafts (the snapshot has none). |
| O-r-3 | `check_config.R` is the older paper's checker (no `MDCOPD_PATH`, misses columns the analysis reads); `config_paths.R.example` says "five inputs". |
| O-r-4 | Package versions are recorded only in the git-ignored HTML; no lock file. The cluster runs used R 4.5.1 (laptop 4.5.2). |
| O-r-5 | `CLAIMS.md`, `results_to_code_map.md` and both READMEs describe an earlier version of the paper (old names, old table numbering). |
| O-r-6 | Figure 2 can only be rebuilt from the participant-level `schema_labels.rds`; nothing says so. Several code headers carry stale figure/table labels. |
| O-r-7 | Some printed values have no verify.R entry (e.g. GOLD stratum counts, 21.9%/9.2%, several AUCs and PPVs, the 469). |

## Where things are

- Reports: this folder (`step1a`, `step1b_cluster/`, `step2`, `step3`, `step4`, `step5`, `CHANGES_v6.md`).
- Cluster notes and reports: `notes/to_cluster/esi_ctfree/` (entry point `CURRENT.md`; all threads closed) and
  `notes/from_cluster/esi_ctfree/` (aggregate output only).
- Commits for the corrections: `b568ec2`, `0319892`, `9ef5266` (respiratory window, exclusion), `a96bf87` (v6 numbers),
  `facdb62` (v6 wording), `fe60157`, `ebf2245`, `1618e89` (random-slope sensitivity, v7).
