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

## A cluster run is IN FLIGHT — check it first

Started 2026-08-25 on Channing, ~20 min, from local commit `a2c143d`
(snapshot `09dca2d`). Ask Pete for the output; he runs the commands, we do not
have cluster access.

    cd /proj/regeps/regep00/studies/COPDGene/analyses/repjc/COPDGene/ESI_MDCOPD_2026/esi-2026 && echo "--- R still running? ---" && (pgrep -f "[k]nitr::knit" >/dev/null && echo YES || echo NO) && echo "--- tail ---" && tail -5 render.log && echo "--- figures ---" && ls -la manuscript_assets/Figure_3_Discordance.png manuscript_assets/Figure_Bhatt_StackedBars.png && echo "--- selfcheck ---" && awk -F, '{print $NF}' manuscript_assets/SELFCHECK.csv | sort | uniq -c && echo "--- diffs ---" && git status --porcelain manuscript_assets

Expected: 68/68, 29 PASS / 0 FAIL, both PNGs fresh and non-zero, R exited.

Three things this run is testing, each a bug fixed today:

1. **Figures actually written.** The figure chunks call `png()` directly, which
   uses `bitmapType`; knitr's `dev` only covers plots embedded in the report.
   Setting only one leaves the other broken. A probe in the setup chunk now
   opens base `png()` and stops if it cannot write, so a dead device fails in
   5 seconds instead of after a 20-minute run with no figures.
2. **Clean exit.** R was hanging at exit clearing its temp dir on NFS. Run now
   sets `TMPDIR=/tmp/repjc_R`, and `graphics.off()` closes lingering devices.
3. **Reproduction**, via the `git status` diff against this machine's outputs.

**Known nit, not yet fixed:** the setup chunk is `include = FALSE`, so knitr
captures its output and the `Raster device OK (...)` line never reaches
`render.log`. Change that `cat()` to `message()` so it goes to stderr. Absence
of the line is NOT a failure signal; a failed probe calls `stop()`.

## State

Analysis renders 68/68, self-check 29 PASS / 0 FAIL on both machines.
Supplement builds 35 OK / 0 FAIL. A code review was acted on in full.

**The verification report is written** (2026-08-26): `verification_report.Rmd`
plus the `verify.R` runner, which renders it and then exits non-zero on any
failure. The gate lives in the runner, not the Rmd, so a failing run still
leaves a readable HTML document. 120 registry entries, 116 PASS, 4 ERROR — all
four pending the next analysis render, none of them a drifted number.

It was reviewed by hand and then adversarially by an independent reviewer, whose
findings were verified before being acted on. The review found no transcription
errors and no wrong-cell field expressions; everything it found was in the
evaluation and gating layer. What changed as a result:

- **The gate now enforces provenance, not mtime.** The analysis writes
  `PROVENANCE.txt` carrying the md5 of the source that produced the artifact set
  and the R that ran it; `PRV-01` fails if that does not match the source being
  verified. mtime cannot do this job on the cluster, where a `git clone` stamps
  every file with checkout time in arbitrary order.
- **The manuscript is pinned by hash** (`MANUSCRIPT_MD5`, `PRV-02`). `expected`
  is a hand transcription made once; if the document changes, the transcription
  must be re-read against it. Degrades to NOT-AVAILABLE where `manuscript/` is
  absent rather than pretending to check.
- **`local_only` waives the numeric comparison only.** It used to absorb ERROR
  too, so a broken field on a local-only entry read as a benign cross-site
  difference.
- **A logical claim requires a logical answer.** `MET-01`/`MET-02` expect TRUE;
  a field that lost its comparison and returned `0.0033` used to PASS on
  truthiness alone.
- **Table 1's `CT vs ESI (p)` is compared as a number,** so `TOL_BOOT` actually
  applies. It was comparing `two_sided_p_reported` as a string, which verified
  the formatter rather than the quantity and would have rejected a legitimate
  cluster re-run landing on 0.71. The two `<0.002` cells assert that no resample
  crossed zero, so they now check that directly against the percentile interval.
- **Fields evaluate in an environment parented to `baseenv()`,** so a field
  cannot reach `T1`/`T2` — the transcription itself — and check the answer key
  against itself.
- **Coverage is asserted.** `REGISTRY_N` in `verify.R` fails if entries are lost.
- **The MD-COPD criterion constants are registered** (`MET-08`..`MET-14`):
  FEV1/FVC < 0.70, Fleischner emphysema >= 1, wall thickening == 2, mMRC >= 2,
  SGRQ >= 25, >= 1 and >= 3 of 5 minor criteria. These define the framework the
  paper is about; if one moved, every artifact would move with it and nothing
  else in the registry would notice.
- **Four significance claims are registered** (`SIG-01`..`SIG-04`): the ones
  asserting AFL-only-noCOPD is not significant, and that the FEV1 increase is
  significant under ESI but not CT.

The gate was then probe-validated by injecting four deliberate defects (a
boolean field degraded to a number, a broken field on a local-only entry, a
bootstrap p drifted past the tolerance, a mis-transcribed CI bound). All four
were caught. A verification harness that cannot fail is worthless, so do this
again after any change to the evaluation layer.

Two findings from the first run:

1. The Discussion cited `p=0.647` for continuous ESI adjusted for FEV1/FVC.
   Commit `7b34c39` moved the S6b model onto the analytic cohort and the value
   became `0.727`; the supplement was rebuilt, the main text was not. Corrected
   in the v12 docx (one run edit, text diff confirmed to be that string alone).
   The IRR of 1.01 did not change and both values are non-significant.
2. The Table 2 legend Ns had no artifact. A writer now emits
   `Table_2_model_Ns.txt` from `cox_disc_all$n` and `model.frame(nb_disc)`.
   **The two entries reading it are ERROR until the analysis is next rendered.**
   The mortality N (5,289) is separately cross-checked against `Table_6.csv`
   and passes today; only 4,635 actually needs the run.

Notes for whoever picks this up:

- **The Changit repo is the source of record for the manuscript.**
- Both `esi_manuscript_analysis_*.html` renders on disk are pre-`7b34c39`
  vintage and still print the superseded S6b values.
- **Open question for Pete — `PRO-11`.** The limitations sentence pairs
  "ESI-only-COPD (n=94)" with "AFL-only-noCOPD (n=170)", but 94 is a
  cross-classification count while 170 is a single-framework category count
  (the CT-based AFL-only row of `Table_6.csv`, 21 + 149). The ESI-based
  AFL-only column totals 84. The registry checks 170 as the CT-based figure,
  which is defensible, but confirm that is what the sentence means.
- **`SELFCHECK.csv` and this report now disagree by design.** SELFCHECK's
  `expected` column has drifted from the manuscript and its `tol = 0.02` is
  loose enough not to notice: it expects 0.770 for the all-strata correlation
  the paper prints as 0.78, 5.070 for an IRR printed as 5.05, and 3.170 for one
  printed as 3.15. All three pass there and are checked correctly here. Worth
  deciding whether SELFCHECK should be retired rather than leaving two
  mechanisms with different answers.
- **Known and left alone:** `grab_const` takes the first assignment of a
  constant (each is currently assigned exactly once); the exacerbation model N
  of 4,635 has no independent cross-check the way the mortality N does, because
  no second artifact carries it.

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
