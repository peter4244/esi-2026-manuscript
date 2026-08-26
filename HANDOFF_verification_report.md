# Handoff — build the verification report for the ESI 2026 manuscript

## The job

Write `verification_report.Rmd`, living beside the analysis in this repo, that
reconciles every number printed in the manuscript to the artifact that produces
it. It must regenerate on each run so a drifted number fails loudly rather than
silently. Pete asked for an `.Rmd` in the repo specifically so it can never go
stale the way a written-once Markdown file would.

**Read the paper yourself before writing it.** Do not build the claim list from
this file. This list is a starting point and is not guaranteed complete.

- Manuscript: `manuscript/ESI manuscript draft v12 2026.8.22_PJC.docx`
- Supplement: `manuscript/ESI manuscript supplement v12 2026.8.16_PJC.docx`
- Analysis:   `esi_manuscript_analysis_2026.7.17_noILD.Rmd`

Both `.docx` are now tracked in git (negation rules in `.gitignore`), so you
have history if something goes wrong.

## Hard design constraint

The Changit snapshot ships **no `manuscript/` directory**, so on the cluster the
report cannot read the `.docx`. It must carry each claimed value as a declared
registry entry and compare it against the freshly computed artifact. That is the
right shape anyway: a code-to-claim map that fails when a number moves.

Suggested row shape: `id | manuscript location | claim text | expected |
source artifact | field | tolerance | computed | PASS/FAIL`, written to
`VERIFICATION.csv` in `OUT_DIR` plus a rendered table.

## Tolerances — do not demand exact equality

A two-machine comparison was run on 2026-08-25 (this workstation and the
Channing cluster, same commit, both computing their own bootstraps). Result:

- **Every headline table agreed to between 1e-8 and 1e-15.** Tables 2 and 8,
  cause-specific, pairwise contrasts, exacerbations, C-index. These are
  effectively exact.
- **Bootstrap p-values reproduce to about +/- 0.01, not exactly.** Effective
  resamples were 416 on one machine and 412 on the other, because which Cox
  fits emit warnings differs with BLAS/LAPACK, and warned resamples are
  dropped. This affects Table 1's respiratory `CT vs ESI (p)` values (0.702,
  0.293) and Supplemental Table 2's intervals.
- **`Supp_Table_Thresholds.csv` differed by 2.8e-2**, likely the `sample()`
  80/20 split. Not chased; Pete ruled it not worth pursuing.
- **`n_paired` in `Supp_Bronchodilator_deltaESI.txt` is 10,160 locally and
  10,397 on the cluster.** The two ESI source extracts differ in rows outside
  the analytic cohort. `d_b` is 9,402 on both and all 29 self-checks pass.
  Mark this claim as local-extract-specific, not as reproducible.

A report demanding bit-equality would fail on a correct run. Set per-claim
tolerances and say why in the report.

## Claim registry starting point (verify against the paper)

Cohort: 9,402 analytic; 106 never-smokers / 4,054 GOLD 0 / 1,129 PRISm /
4,113 GOLD 1-4  -> `Table_Agreement_stats.txt`, `Table_S2_stratum_counts.csv`

Baseline ESI 0.83 (never-smokers) to 8.30 (GOLD 4) -> `Table_S2_stratum_counts.csv`
  (`ESI_mean`)

Agreement 91%, kappa 0.82, sensitivity 88%, specificity 94%
  -> `Table_Agreement_stats.txt`

Correlations r=0.78 (LAA-950), 0.08 (GOLD 0), 0.58 (GOLD 3) -> `Table_2.csv`
  (`r_LAA`); r=0.81 (PRM) -> `Table_2_PRMversion.csv` (`r_PRM`)

Table 1 HRs/IRRs -> `Table_8_allcause.csv`, `Table_8_resp.csv`,
  `Table_Exacerbations_Bhatt.csv`; its `CT vs ESI (p)` column ->
  `Supp_Table_HR_Difference_Bootstrap.csv`, `Supp_Table_IRR_Difference_Bootstrap.csv`

Table 2 HRs/IRRs -> `Table_BhattOnly_vs_Both.csv`,
  `Table_Exacerbations_Discordance.csv`; pairwise p=0.005 / p=0.037 ->
  `Table_2_pairwise_contrasts.csv` (`p_adj`)

Table 2 legend Ns: mortality 5,289, exacerbations 4,635. NOT currently written
  to any artifact -- I computed them ad hoc. Either add a stats writer to the
  analysis Rmd or compute them in the report.

AFL-only ESI FEV1 +10.1 mL/yr, p=0.02 -> `Table_BhattDecline.csv`
  (`esi_est`, `esi_p`, row `AFL-only-NoCOPD`)

GOLD 0 continuous ESI 4.73 mL/yr, P=0.001 ->
  `Supp_Table_Continuous_FEV1Decline_GOLD0.txt`

Continuous ESI exacerbations IRR=1.01, p=0.647 ->
  `Table_S6b_continuous_exacerbations.csv`

Mean dESI -0.09 across n=10,160 -> `Supp_Bronchodilator_deltaESI.txt`

Subgroup sizes n=94 (ESI-only), n=170 (AFL-only) -> `Table_6.csv`,
  `Table_BhattOnly_vs_Both.csv`

C-index equivalence, margin +/-0.02 -> `Table_1_Cindex_Equivalence.csv`

Thresholds ESI<1 / 1<=ESI<2.5 / >=2.5, and B=1,000 -> constants in the
  `paths` chunk (`ESI_T_LOW`, `ESI_T_HIGH`, `B_BOOTSTRAP`)

ST9 category totals 170 / 1,086 / 3,943 -> derived from `Table_6.csv` by
  `tables/supp/_bhatt_category_ns.py`

## State as of this handoff

- Analysis renders clean, 68/68 chunks, **self-check 29 PASS / 0 FAIL** on both
  machines.
- Supplement builds 35 OK / 0 FAIL.
- A code review (mine plus an independent reviewer) was acted on: bootstrap
  scale mismatch, TOST underflow, swapped Figure 3 labels, `d_cont` cohort,
  five vacuous guards, self-check returning NA, cache fingerprints, and the
  IRR warning-drop. All committed.
- 18 stale artifacts from the retired ILD-inclusive/CCOD-era analysis were
  deleted, and `build_outline_docx.py` (their only consumer) retired.
- All historical/internal/off-cluster commentary was stripped from the Rmd.

## Known and deliberately NOT fixed

- **Cause-of-death adjudication gap.** 33.6% of deaths in the analytic cohort
  have no assigned cause, and it is differential: 40.3% unadjudicated in
  noCOPD vs 26.0% in COPD-major. Unadjudicated deaths are censored, so the
  respiratory HR of 36.27 is biased upward. A MAR-within-group sensitivity
  gives 32.27, an 11% attenuation with no change in conclusion. Pete decided
  to leave it and address it only if reviewers raise it. **Do not reopen this.**
- Supplemental Table 14's covariate-sensitivity labels (`S6a`..`S6d` in the
  `covariate-sensitivity` chunk) are off by one relative to the CSV names.
  HTML-only, backs no manuscript claim.

## Gotchas that cost time this session

- **zsh does not word-split unquoted `$VAR`.** `for f in $FILES` iterates once
  over the whole string. Use an array. This produced two false "no consumers
  found" results and nearly caused a wrong deletion.
- **`pgrep -f "pattern"` matches the shell running it.** Use `[p]attern`.
- **Verify comment-only edits** by purling both versions and diffing the
  executable lines. The Rmd is 1,713 executable lines / 472 expressions.
- **Never write to a `.docx` without asking** -- Pete often has it open in
  Word, and a python-docx save is a whole-file rewrite that Word will clobber
  on its next save.
- **Probe scripts must redirect `OUT_DIR`** (via `ESI_CONFIG`) or they
  overwrite `manuscript_assets/`.
