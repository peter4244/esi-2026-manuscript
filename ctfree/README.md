# CT-free MD-COPD

A separate paper from the v15 manuscript in the parent directory, sharing its
code and methodology but not its claims. Start with [CLAIMS.md](CLAIMS.md).

## The question

MD-COPD is defined partly by CT findings. CT is often unavailable. Can the
classification, and the benefit it carries over the fixed ratio, be preserved
using spirometry and symptoms alone?

## Why this is not the v15 paper

v15 asks whether an ESI-based framework reproduces the CT-based one, and
answers with 91% agreement and kappa 0.82 at the binary COPD-versus-noCOPD
level. Per category that agreement is much weaker: 50.5% for COPD-minor and
12.4% for AFL-only, because the binary figure is carried by noCOPD and
COPD-major, which are 86.6% of the cohort and already agree at 97.8% and 98.4%.

Reproducing the CT classification is also the wrong target. What matters is
whether a CT-free classification keeps MD-COPD's advantage over the fixed
ratio, and whether its category labels still mean what they say. Those are the
questions here.

## What the analysis does

Four classifications on the same 9,240 participants, defined in CLAIMS.md: the
fixed ratio, MD-COPD-CT (the published CT-based framework), MD-NoCT (CT
criteria removed) and MD-COPD-ESI (CT criteria replaced by ESI). The code and
assets call them S1 to S4, and use the working names MD-COPD, NoCT-MD-COPD and
ESI-MD-COPD for S2 to S4. The two CT-free classifications are fitted to
approximate the CT-based one, by the same objective, over their full parameter
spaces, outcome-blind, and cross-validated 5 by 5 stratified on the reference
categories.

## Running it

One R Markdown report produces every result table; five figure scripts draw
the figures from those tables. All commands run from any working directory,
including the Channing cluster; from the repository root:

```
Rscript check_config.R                        # header-only check of the six inputs
Rscript ctfree/render_ctfree_2026.9.3.R       # the analysis
Rscript ctfree/verify.R                       # the claims check
Rscript ctfree/figures/figure1_esi_ct.R       # likewise figure2_flow.R, figure3_group_risk.R,
                                              # figure4_discord_risk.R, figureS2_profile.R
python3 ctfree/build_manuscript.py
python3 ctfree/build_supplement.py <out.docx>
```

The render wrapper knits the report and writes every artifact to
`ctfree/assets/` (an `OUT_DIR` in `config_paths.R` belongs to the v15
analysis and is ignored here). `config_paths.R` at the repository root
supplies the six COPDGene input paths and `ID_COL`, and is git-ignored; see
`config_paths.R.example` for the template and the columns each file needs.
`check_config.R` reads only the header line of each file.

`verify.R` is the claim registry: 291 numbers printed in the manuscript and
supplement, each compared with the asset field that produces it at printed
precision. It does not read the prose. It writes `assets/VERIFICATION.csv`
and exits non-zero on any failure.

The figure scripts read only the aggregate assets, except `figure2_flow.R`,
which also needs the participant-level `assets/schema_labels.rds` written by
the render (git-ignored, never shared); Figure 2 can only be rebuilt where the
analysis has been run. `figure3_group_risk.R` writes both Figure 3 and
Supplemental Figure S1. The builders read the assets, the figure PNGs and the
.md text sources; `build_supplement.py` takes the output path as its argument.

The v8 numbers come from the Channing run on the original sid-keyed COPDGene
files (job 6118470; Table S7 from job 6120833). Bootstrap and cross-validation
results reproduce exactly only on identically ordered input files, and
otherwise to Monte Carlo error.

## Files

| | |
|---|---|
| `CLAIMS.md` | reading guide to the claim registry in `verify.R` |
| `results_to_code_map.md` | each table, figure and quoted number, with its chunk, asset, claims and Methods section |
| `ESI_ctfree_analysis_2026.9.3.Rmd` | the analysis report: cohort construction, classification fitting, cross-validation, common-reference risk, paired bootstraps, FEV1 decline, discordance, completeness check |
| `render_ctfree_2026.9.3.R` | render wrapper that sets a headless-safe raster device before knitting |
| `verify.R` | claim registry (291 claims) against `assets/`; fails loudly on drift |
| `figures/figure1_esi_ct.R`, `figure2_flow.R`, `figure3_group_risk.R`, `figure4_discord_risk.R`, `figureS2_profile.R` | Figures 1-4 and S1-S2, each with its legend (`*_legend.md`) and size file (`*.meta`) |
| `build_manuscript.py`, `build_supplement.py`, `supp_registry.py`, `paginate.py` | document builders; supplemental table order; supplement contents page numbers |
| `ABSTRACT.md`, `INTRODUCTION.md`, `METHODS.md`, `RESULTS.md`, `DISCUSSION.md`, `TITLEPAGE.md`, `REFERENCES.md` | manuscript text sources |
| `assets/` | aggregate artifacts, `PROVENANCE.txt` and `VERIFICATION.csv` |

Tables: Table 1 (the classifications) in the manuscript; Supplemental Tables
S1 baseline, S2 thresholds, S3 cross-classification, S4 unadjusted risk, S5
adjusted risk, S6 FEV1 decline, S7 FEV1 random-slope sensitivity, S8
discordance.

## Three traps, recorded so they are not walked into again

**Metrics that ignore one kind of error pick a schema that mislabels people.**
Cohen's kappa and mean per-category sensitivity err in opposite directions on
AFL-only: kappa selects the rule that leaves 3 participants there, mean
sensitivity the rule that puts 954 there, against 275 under MD-COPD-CT. An
over-filled AFL-only group is not low risk: MD-NoCT's 1,108 carry a crude
respiratory mortality rate ratio of 8.07 against the common reference, so the
label is false. Macro-averaged F1 is used instead: symmetric across
categories, but balancing precision against recall within each.

**The schema with the best discrimination is the one that must be rejected.**
Dropping the structural criterion entirely beats every other schema on
C-index and AIC, by concentrating risk into a smaller COPD-major group and
calling the remainder healthy. Discrimination is indifferent to whether labels
are true. The paper has to state this and answer it, not omit it.

**Both CT-free schemas must be fitted over their full parameter space.** The
symptoms-only schema needs its count threshold refitted because dropping two
criteria changes the scale. Allowing that for one schema and not the other
rigs the comparison.
