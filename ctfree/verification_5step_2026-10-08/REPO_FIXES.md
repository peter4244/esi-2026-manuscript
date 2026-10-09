# Repository-level reproducibility fixes (2026-10-08)

Covers SUMMARY.md items O-r-2, O-r-3, O-r-5, O-r-6 and O-r-7, and the matching step-4 findings
(H1, H4, M7, M8, L1). No manuscript source, legend, builder or .docx was edited; nothing was
rendered, built or committed. No participant-level file was opened. `check_config.R` was run only
against the synthetic inputs in `step1b_cluster/synthetic_inputs/`.

`verify.R` after the changes: **VERIFICATION PASSED: 291 claims, 0 failed** (257 before, 34 added).

## 1. READMEs (O-r-2, O-r-5; H1, M7)

- **`README.md` (repository root).** On `main` this file was still the original v15 README with no
  CT-free section; the CT-free section existed only in the changit snapshot's README (commit
  `6925016`). I brought that README onto `main` and corrected its CT-free section:
  - figure script names and what each produces (Figure 3 and S1 from `figure3_group_risk.R`);
  - group names MD-COPD-CT / MD-NoCT / MD-COPD-ESI, with the S1-S4 and working-name crosswalk;
  - table numbering S1-S8 and the main-text Table 1 and Figures 1-4;
  - how outputs are produced: render → `ctfree/assets/`, figure scripts read only aggregate assets
    except `figure2_flow.R`, which needs the participant-level `schema_labels.rds`; builders read
    assets and .md sources, `build_supplement.py <out.docx>`;
  - `verify.R` as the claim registry (291 claims, printed precision, does not read prose);
  - removed the statement that `ctfree/manuscript/` holds the current .docx (it is not shipped);
  - added the Monte Carlo reproducibility note (step 4, M5) and R 4.5.1 for the numbers;
  - `check_config.R` usage.
  
  The nested v15 section is the changit text with one added note: `check_config.R` now checks the
  CT-free inputs. **For Pete:** this replaces `main`'s old v15-only README with the changit one,
  so `main` and changit now share a README. The changit intro ("a current snapshot ... not a
  development history") reads oddly on `main`; I left it as is.
- **`ctfree/README.md`.** Rewrote "What the analysis does", "Running it" and "Files"; kept "The
  question", "Why this is not the v15 paper" and the traps. Relative paths; outputs go to
  `ctfree/assets/` (not `OUT_DIR`); figures come from five scripts; Figure 2 needs
  `schema_labels.rds`; verify.R checks assets, not prose; the Channing job ids; the table list. The
  first trap quoted superseded numbers (1,119 vs 170, 6.6x, and "kappa, mean recall and C-index
  all select" the same rule). It now uses `objective_selection.csv`: kappa leaves 3 in AFL-only,
  mean sensitivity puts 954 there against 275, and MD-NoCT's 1,108 AFL-only have crude
  respiratory rate ratio 8.07 (CONSREF-04).

## 2. `check_config.R` and `config_paths.R.example` (O-r-3; H4)

- **`check_config.R`** now serves the CT-free analysis:
  - requires all six paths including `MDCOPD_PATH`, plus `ID_COL`; `OUT_DIR` is no longer required;
  - checks the columns the Rmd reads from each file, taken from the purled code:
    - ESI: `visitnum`, `PrePost`, `ESI`;
    - phenotype: 25 columns (exclusion chain, the five criteria, `CoronaryArtery`,
      `CongestHeartFail`, covariates, `finalgold_visit`, `FEV1pp_utah`, `Exacerbation_Frequency`,
      `FEV1_post`, `years_from_baseline`, `Insp_LAA950_total_Thirona`, `PRM_pct_emphysema_Thirona`);
    - vital status: `vital_status`, `days_followed`;
    - cause of death: `Torch_Group_Basic`, `mortality_survival_vital_status`, `days_followed`;
    - exacerbations: `Total_Exacerbations`, `Years_Followed`;
    - MD-COPD: `MultiDim_COPD_score`;
  - reads only the first line of each file. The two old blocks that read the whole phenotype and
    exacerbation files (cohort-level table, exacerbation coverage by cohort) are removed. What they
    reported is now a comment, and the Rmd's own `stopifnot` on the Bhatt counts covers it.
  - Synthetic test: reports missing `Insp_LAA950_total_Thirona` and `PRM_pct_emphysema_Thirona`
    (phenotype) and `days_followed` (cause-of-death), finds `sid` in all six, ends "CONFIG HAS
    PROBLEMS". This tests my code, not the real files.
  - `MultiDim_COPD_Subtype` is **not** checked. The task brief listed it, but the Rmd never reads
    it (only `MultiDim_COPD_score`). The template now says so.
- **`config_paths.R.example`**: "All six inputs"; each input's comment names the columns needed
  (ESI: `PrePost` 0 = pre, 1 = post; replicate manoeuvres averaged); the `MDCOPD_PATH` comment
  gives the score coding and points to the Rmd header for the reconstruction history; the
  `OUT_DIR` comment says it is for v15 only and that the CT-free analysis ignores it.
- Side effect: v15 users of `check_config.R` now get a check of CT-free columns. The root README's
  v15 section says so. If a v15 check is still needed, it would be a separate script or a mode
  switch; not done.

## 3. Companion documents (O-r-5; M7)

- **`ctfree/CLAIMS.md`**: rewritten as a reading guide to the `verify.R` registry. It covers the v8
  names with the crosswalk, current standing decisions (single ESI cut-point, the common reference
  3,856 / 3,625 / 3,411), and the claim groups by paper section with their v8 values. It now says
  verify.R is the registry and has 291 claims. The superseded values (ESI 1.25, t_high 7.0,
  held-out F1 0.753/0.720, 4,113, 3,803, 1,119 vs 170, own-reference HRs, discrimination and gate
  claims) are gone. A "Not registered" list names what has no entry and why.
- **`ctfree/results_to_code_map.md`**: rewritten for v8:
  - Table 1, Tables S1-S8, Figures 1-4 and S1-S2, each with its Rmd chunk, asset, placing
    builder function, claim ids and Methods section (M sections by their current METHODS.md
    headings and paragraph numbers; SM paragraphs by their `supp_methods` headings);
  - a quoted-numbers table;
  - relative run commands, 291 claims, and builder outputs (v<N> set in `OUT`;
    supplement to the path given);
  - Figure 2's dependency on `schema_labels.rds`;
  - `draft_tables.R` and `massimo_report.Rmd` marked as not part of v8.
  
  Every claim id cited in the map exists in VERIFICATION.csv (checked by script).
- **`ctfree/verify.R` header**: it said "Every claim in ctfree/CLAIMS.md is evaluated". It now says
  verify.R is the registry, does not read the manuscript text, and CLAIMS.md is a guide to it.
  The run line uses a relative path.

## 4. Code headers and comments (O-r-6; M8)

- **Figure scripts** (comments only; `git diff` shows no non-comment line changed):
  - `figure2_flow.R`: "Figure 1" → "Figure 2"; panel names → MD-NoCT / MD-COPD-CT /
    MD-COPD-ESI; added a note that it reads the participant-level `schema_labels.rds` and is the
    only figure script that does;
  - `figure3_group_risk.R`: "Figure 2" → "Figure 3";
  - `figure4_discord_risk.R`: "Figure 3" → "Figure 4" (and group names);
  - `figureS2_profile.R`: "Figure 4" → "Supplemental Figure S2" (and group names).
  - `figure1_esi_ct.R` was already correct.
- **`ESI_ctfree_analysis_2026.9.3.Rmd`** (prose outside chunks and comments only):
  - header comment: produces result tables, not figures; adds the S1-S4 / v8 name crosswalk;
  - Overview: no figures written here; output goes to `ctfree/assets/` and `OUT_DIR` from the
    config is ignored; Section 11 only checks that files exist, and `verify.R` checks the numbers;
  - Section 1 points to the Rmd's own header comment for the MD-COPD reconstruction story, not
    the three-line config comment;
  - Section 1.2 heading "(Supplemental Table S2)" → "(not in the v8 supplement)";
  - Section 3 "the two ESI thresholds" → "the ESI threshold";
  - Section 8a own-reference sizes 3,853 and 3,815 → 3,982 and 3,941 (`schema_labels.csv`);
  - random-slope paragraph names Table S7;
  - Section 9b "for Figures 5 and 6" → "for Table S8, Figure 4, Figure S2 and the Table S3 P
    values";
  - `strata-profile-tests` comment "Figure 5 brackets" → "Figure S2 brackets".
  
  Checks: `git diff` shows only prose/comment lines changed. `knitr::purl` + `parse()` gives 524
  expressions before and after, and the deparsed code is identical.

## 5. New verify.R entries (O-r-7; L1)

34 entries, each against its asset field at printed precision; `REGISTRY_N` 257 → 291.

| ids | value(s) | artifact |
|---|---|---|
| GOLD-01 to GOLD-06 | stratum counts 1,119 / 4,037 / 734 / 1,772 / 1,050 / 528 | supp_baseline.csv |
| GOLD-07, GOLD-08 | mean ESI 0.90 (GOLD 0), 8.30 (GOLD 4) | supp_baseline.csv |
| FU-07 | exacerbation n 8,177 | followup_medians.csv |
| RECL-13, RECL-14 | 21.9%, 9.2% (of 3,809) | reclassification.csv |
| CTAUC-05 to CTAUC-08 | AUC 0.80 overall wall; 0.75, 0.75 with AFL; 0.61 without AFL, wall | esi_ct_auc.csv |
| AGR-01 to AGR-08 | noCOPD and COPD-minor sensitivity and PPV at 1 dp | agreement_by_group.csv |
| AGR-09, AGR-10, AGR-11 | AFL-only PPV 24.8%, 35.5%; its P < 0.005 | agreement_by_group.csv |
| AGR-12, AGR-13 | COPD-major PPV 100%, 97.7% | agreement_by_group.csv |
| RATE-08 to RATE-10 | respiratory rates 0.39 (MD-NoCT), 0.09 (MD-COPD-CT), 0.09 (MD-COPD-ESI) | consensus_ref_crude.csv |
| DISC-FOUR | "four times the size" (1,108 / 275 rounds to 4) | schema_labels.csv |
| DISC-HALF | "more than half" (483 / 833 > 0.5) | crossclass.csv |
| SM-CTMISS | "missing visual CT scores (n = 4)", both criteria | esi_ct_levels.csv |

## Left undone, with reasons

- **The 469 participants without follow-up** (Methods): no asset carries the count (the old 9,238
  is not written anywhere now), so it cannot be registered without changing the analysis code.
  It would need the `outcome-data` chunk to write the pre-exclusion n, which is a logic change
  outside this task.
- **R version.** METHODS.md says "R version 4.5.2"; `assets/PROVENANCE.txt` from the Channing
  run that produced the v8 numbers records R 4.5.1. Not registered, because the entry would fail;
  the Methods sentence is Pete's to change. The READMEs now state 4.5.1 for the numbers.
- **Per-chunk "Paper: … ; Methods: …" lines and "not used in v8" tags** (step 4, M6): not added.
  The task asked only for stale labels to be fixed. The Rmd's remaining working names in code
  comments (MD-COPD, NoCT-MD-COPD, ESI-MD-COPD) are covered by the new crosswalk rather than
  renamed.
- **O-r-1 (availability/ethics statements), O-r-4 (package versions, lock file), H2 (bronchodilator
  CI/P has no producing code), Methods-completeness items**: out of scope (manuscript prose or
  analysis logic).
- **Concurrent changes not mine:** while I worked, `notes/to_cluster/esi_ctfree/CURRENT.md` changed,
  and `notes/to_cluster/esi_ctfree/2026-10-08_2135_esi-pkg.md`,
  `notes/to_cluster/esi_ctfree/ctfree_package_versions.R` and
  `ctfree/verification_5step_2026-10-08/TEXT_PROPOSALS_methods_deposit.md` appeared. I did not
  touch them.
- `ctfree/assets/VERIFICATION.csv` is rewritten by every `verify.R` run, so it shows as modified.

## Files changed

`README.md`, `check_config.R`, `config_paths.R.example`, `ctfree/README.md`, `ctfree/CLAIMS.md`,
`ctfree/results_to_code_map.md`, `ctfree/verify.R`, `ctfree/assets/VERIFICATION.csv`,
`ctfree/ESI_ctfree_analysis_2026.9.3.Rmd`, `ctfree/figures/figure2_flow.R`,
`ctfree/figures/figure3_group_risk.R`, `ctfree/figures/figure4_discord_risk.R`,
`ctfree/figures/figureS2_profile.R`; new: this file.
