# Handoff — verification report for the ESI 2026 manuscript

## Job

Write `verification_report.Rmd` in this repo: reconcile every number printed in
the manuscript to the artifact that produces it, regenerating on each run so a
drifted number fails loudly.

**Read the paper yourself.** The registry below is a starting point, not a
complete list.

- Manuscript: `manuscript/ESI manuscript draft v12 2026.8.22_PJC.docx`
- Supplement: `manuscript/ESI manuscript supplement v12 2026.8.16_PJC.docx`
- Analysis:   `esi_manuscript_analysis_2026.7.17_noILD.Rmd`

## Constraint

The Changit snapshot ships no `manuscript/` directory, so the report cannot read
the `.docx` on the cluster. Each claimed value must be a declared registry entry
compared against the freshly computed artifact. Row shape: `id | location |
claim | expected | artifact | field | tolerance | computed | PASS/FAIL`, written
to `VERIFICATION.csv` in `OUT_DIR`.

## Tolerances — do not demand exact equality

Two-machine comparison, 2026-08-25, same commit, both computing their own
bootstraps:

- Headline tables agree to 1e-8 .. 1e-15. Effectively exact.
- **Bootstrap p-values reproduce to ~±0.01.** Effective resamples were 416 vs
  412: which Cox fits warn differs with BLAS, and warned resamples are dropped.
  Affects Table 1's respiratory `CT vs ESI (p)` (0.702, 0.293) and ST2.
- `Supp_Table_Thresholds.csv` differs by 2.8e-2 (the `sample()` split). Pete
  ruled it not worth chasing.
- `n_paired` is 10,160 locally, 10,397 on the cluster: the ESI extracts differ
  outside the analytic cohort. `d_b` is 9,402 both places. Mark this claim
  local-only, not reproducible.

## Registry starting point

| Claim | Artifact |
|---|---|
| 9,402 cohort; 106/4,054/1,129/4,113 | `Table_Agreement_stats.txt`, `Table_S2_stratum_counts.csv` |
| ESI 0.83 → 8.30 across strata | `Table_S2_stratum_counts.csv` (`ESI_mean`) |
| 91%, κ 0.82, 88% sens, 94% spec | `Table_Agreement_stats.txt` |
| r 0.78 / 0.08 / 0.58 | `Table_2.csv` (`r_LAA`) |
| r 0.81 (PRM) | `Table_2_PRMversion.csv` (`r_PRM`) |
| Table 1 HR/IRR | `Table_8_allcause.csv`, `Table_8_resp.csv`, `Table_Exacerbations_Bhatt.csv` |
| Table 1 `CT vs ESI (p)` | `Supp_Table_{HR,IRR}_Difference_Bootstrap.csv` |
| Table 2 HR/IRR | `Table_BhattOnly_vs_Both.csv`, `Table_Exacerbations_Discordance.csv` |
| pairwise p 0.005 / 0.037 | `Table_2_pairwise_contrasts.csv` (`p_adj`) |
| AFL-only +10.1 mL/yr, p=0.02 | `Table_BhattDecline.csv` (`esi_est`, `esi_p`) |
| GOLD 0 4.73 mL/yr, P=0.001 | `Supp_Table_Continuous_FEV1Decline_GOLD0.txt` |
| IRR 1.01, p=0.647 | `Table_S6b_continuous_exacerbations.csv` |
| ΔESI −0.09, n=10,160 | `Supp_Bronchodilator_deltaESI.txt` |
| n=94, n=170 | `Table_6.csv`, `Table_BhattOnly_vs_Both.csv` |
| C-index equivalence, ±0.02 | `Table_1_Cindex_Equivalence.csv` |
| thresholds 1 / 2.5, B=1,000 | constants in the `paths` chunk |
| ST9 totals 170/1,086/3,943 | `tables/supp/_bhatt_category_ns.py` from `Table_6.csv` |

**Gap:** Table 2's legend Ns (mortality 5,289, exacerbations 4,635) are written
to no artifact — computed ad hoc. Add a stats writer to the analysis or compute
them in the report.

## State

Analysis renders 68/68, self-check 29 PASS / 0 FAIL on both machines.
Supplement builds 35 OK / 0 FAIL. A code review was acted on in full.

## Do not reopen

**Cause-of-death adjudication gap.** 33.6% of deaths have no assigned cause,
differentially (40.3% noCOPD vs 26.0% COPD-major), biasing the respiratory HR
of 36.27 upward; MAR-within-group sensitivity gives 32.27. Pete decided to
leave it unless reviewers raise it.

Minor, known: the `covariate-sensitivity` chunk's `S6a`..`S6d` labels are off by
one versus the CSV names. HTML-only, backs no claim.

## Gotchas

- **zsh does not word-split unquoted `$VAR`** — `for f in $FILES` iterates once
  over the whole string. Use an array. This caused two false negatives here.
- **`pgrep -f "pat"` matches its own shell.** Use `[p]at`.
- **Verify comment-only edits** by purling both versions and diffing executable
  lines (1,713 lines / 474 expressions).
- **Never write to a `.docx` without asking** — Pete often has it open, and
  python-docx rewrites the whole file.
- **Probe scripts must redirect `OUT_DIR`** via `ESI_CONFIG` or they overwrite
  `manuscript_assets/`.
