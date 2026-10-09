# ESI and multidimensional COPD: analysis code snapshot

This repository is a current snapshot of the analysis code for the manuscript
*The Emphysema Severity Index: Representing CT Abnormalities in a
Multidimensional COPD Framework*, which lives in `ctfree/`. It is a snapshot,
not a development history. The earlier v15 manuscript analysis remains at the
repository root, and its original README is reproduced at the end.

No participant data is included. The analysis needs six COPDGene files obtained
through your own institutional data agreement.

## The CT-free MD-COPD analysis (`ctfree/`)

The study compares four classifications of the same 9,240 COPDGene subjects:
the fixed ratio; MD-COPD-CT, the published CT-based multidimensional COPD
framework; MD-NoCT, which is MD-COPD-CT with the two CT criteria removed; and
MD-COPD-ESI, which replaces the CT criteria with the Emphysema Severity Index.
MD-COPD-CT categories are taken from the source report's per-subject
classification file. The code and results tables call the four S1 to S4 and
use earlier working names for S2 to S4 (MD-COPD, NoCT-MD-COPD, ESI-MD-COPD).

### Contents

| Path | Purpose |
|---|---|
| `ctfree/ESI_ctfree_analysis_2026.9.3.Rmd` | The analysis. Writes every results table in `ctfree/assets/`. |
| `ctfree/render_ctfree_2026.9.3.R` | Renders the analysis with a raster device that works on a headless node. |
| `ctfree/verify.R` | The claim registry: checks each of 291 numbers printed in the manuscript and supplement against its results table; exits non-zero if any fails. |
| `ctfree/assets/` | Results tables (summary statistics only), `VERIFICATION.csv` and `PROVENANCE.txt`. |
| `ctfree/figures/` | Figure scripts: `figure1_esi_ct.R` (Figure 1), `figure2_flow.R` (Figure 2), `figure3_group_risk.R` (Figure 3 and Supplemental Figure S1), `figure4_discord_risk.R` (Figure 4), `figureS2_profile.R` (Supplemental Figure S2). Each writes its PNG, legend (`*_legend.md`) and size file (`*.meta`). |
| `ctfree/ABSTRACT.md`, `INTRODUCTION.md`, `METHODS.md`, `RESULTS.md`, `DISCUSSION.md`, `TITLEPAGE.md`, `REFERENCES.md` | Manuscript text sources. |
| `ctfree/build_manuscript.py`, `ctfree/build_supplement.py` | Build the manuscript (Table 1, Figures 1-4) and the supplement (Supplemental Methods, Tables S1-S8, Figures S1-S2) .docx from the text sources, results tables and figures. |
| `ctfree/paginate.py`, `supp_registry.py`, `display_order.py`, `pjc_guard.py`, `prose_guard.py`, `word_guard.py`, `diff_pjc.py` | Build support: supplement contents page numbers, supplemental table numbering, citation order checks, and guards that protect edited text. |
| `ctfree/draft_tables.R` | Writes a Markdown view of earlier working tables; not used for the current manuscript. |
| `ctfree/massimo_report.Rmd`, `ctfree/render_massimo_report.R` | Co-author report on why the MD-COPD-ESI rule was refitted; reads results from `ctfree/assets/` and `manuscript_assets/`. Not needed for the paper. |
| `ctfree/CLAIMS.md`, `ctfree/results_to_code_map.md` | A guide to the claim registry, and which script, results table and Methods section produce each table, figure and quoted number. |

The supplemental tables are S1 baseline characteristics, S2 threshold
selection, S3 cross-classification, S4 unadjusted risk, S5 adjusted risk, S6
FEV1 decline, S7 FEV1 decline with random slopes (sensitivity analysis) and S8
outcomes by concordance and discordance.

### Configuration

Copy `config_paths.R.example` to `config_paths.R` at the repository root. Set
the six input files (`ESI_PATH`, `PHE_PATH`, `VS_PATH`, `COD_PATH`, `EX_PATH`,
`MDCOPD_PATH`) and `ID_COL`, the subject identifier column in your copies of
those files. The template lists the columns the analysis reads from each file.
`Rscript check_config.R` checks that the six files exist and carry the
identifier and every one of those columns; it reads only the header line of
each file. The CT-free analysis always writes to `ctfree/assets/`; `OUT_DIR`
applies only to the v15 analysis.

### Running it

Each script finds its own location, so the commands work from any directory.
From the repository root:

```sh
Rscript check_config.R                    # header-only check of the inputs
Rscript ctfree/render_ctfree_2026.9.3.R   # the analysis; writes ctfree/assets/
Rscript ctfree/verify.R                   # checks the manuscript's numbers
Rscript ctfree/figures/figure1_esi_ct.R   # likewise figure2_flow.R, figure3_group_risk.R,
                                          # figure4_discord_risk.R, figureS2_profile.R
python3 ctfree/build_manuscript.py        # optional: rebuild the .docx files
python3 ctfree/build_supplement.py <out.docx>
```

The analysis writes every results table to `ctfree/assets/` and an HTML report
beside the .Rmd. `verify.R` compares each registered number with its results
table at the precision the text prints it, writes
`ctfree/assets/VERIFICATION.csv`, and exits non-zero if any comparison fails;
it does not read the manuscript text. The figure scripts read the results
tables in `ctfree/assets/` and write into `ctfree/figures/`. One exception:
`figure2_flow.R` also reads `ctfree/assets/schema_labels.rds`, a
participant-level file that the analysis writes and that is never shared, so
Figure 2 can be rebuilt only where the analysis itself has been run. The
builders read the results tables, the figure PNGs and the text sources;
`build_manuscript.py` writes into `ctfree/manuscript/` (created if absent) and
`build_supplement.py` writes to the path given. The supplement build renders
the document through LibreOffice to fill in the page numbers of its contents,
and Word asks to update fields when the file is first opened.

The manuscript's numbers come from a run on the original COPDGene files with
R 4.5.1. Bootstrap and cross-validation results depend on the row order of the
input files: on identically ordered files they reproduce exactly, and
otherwise to Monte Carlo error, so a difference in the third decimal of an
interval is not a failed reproduction.

### Requirements

R (developed on 4.5.2; the manuscript's numbers were produced on 4.5.1) with
`dplyr`, `tidyr`, `ggplot2`, `ggalluvial`, `patchwork`, `scales`, `survival`,
`MASS`, `lme4`, `lmerTest`, `digest`, `png`, `knitr` and `rmarkdown`. For the
document builds, Python 3 with `python-docx` and `PyMuPDF`, and LibreOffice.

## Earlier manuscript: v15 analysis at the repository root

The files outside `ctfree/` belong to the earlier v15 manuscript. Its original
README follows, with its headings nested under this section.

### ESI multidimensional-COPD reformulation: analysis code

Code accompanying *The Emphysema Severity Index: A Spirometric Representation of
CT-Defined Structural Abnormalities in a Multidimensional COPD Framework*.

#### Contents

| Path | Purpose |
|---|---|
| `esi_manuscript_analysis_2026.7.17_noILD.Rmd` | The analysis. Produces every result CSV consumed by the manuscript and supplement. |
| `verification_report.Rmd` | Reconciles every number printed in the manuscript against the artifact that produces it. |
| `verify.R` | Runs the above and exits non-zero if any claim does not reconcile. |
| `check_config.R` | Validates a site configuration before a run. |
| `config_paths.R.example` | Template for site-local input locations. |
| `build_supplement.py` | Renders the supplement .docx from `tables/`. |
| `tables/`, `prose_py/`, `prose/` | Supplement table modules and legends. |
| `figures/` | Figure 1 and Figure 2 source. |
| `manuscript_assets/` | Result CSVs written by the analysis. |
| `manuscript/` | The manuscript and supplement .docx. Present so `verify.R` can check the registry against the document it was transcribed from. |

#### Data

Five COPDGene analysis files are required, obtained through your own
institutional data agreement. No participant data is included here, and no
dataset path or filename appears anywhere in this repository.

#### Running it

```r
cp config_paths.R.example config_paths.R      # then edit
Rscript check_config.R config_paths.R         # validate before running (see note)
Rscript render_analysis.R                     # the analysis
python3 build_supplement.py                   # optional: rebuild the supplement
```

Note: `check_config.R` now checks the CT-free analysis's six inputs and
columns (see above). For v15 it still confirms the files and the identifier
column, but it also requires `MDCOPD_PATH` and some columns v15 does not read,
and no longer checks `Total_Severe_Exacer`.

`render_analysis.R` selects a headless-safe raster device and then calls
`knitr::knit`, which runs every chunk and writes all outputs without requiring
pandoc. The device has to be chosen before `knit()` is called: knitr probes the
png device during startup, before any chunk runs, and on a node with no X11
display that probe warns. Knitting the .Rmd directly still works and produces
identical output; it just carries that one warning.

Use `rmarkdown::render` instead if you also want the HTML report.

Set `ESI_CONFIG` to use a config under another name:

```sh
ESI_CONFIG=config_paths_mysite.R Rscript check_config.R
```

#### Requirements

R with `survival`, `lme4`, `lmerTest`, `MASS`, `dplyr`, `tidyr`, `ggplot2`,
`scales`, `patchwork`, `multcomp`, `rpart`, `knitr`. Python 3 with
`python-docx` for the supplement build. Developed on R 4.5.2; verified to
reproduce on R 4.3.2.

Runtime is roughly ten minutes, dominated by two 1,000-iteration bootstraps.
These cache to `manuscript_assets/_cache/`; the cache records a fingerprint of
the data it came from and recomputes automatically if that changes.

#### Verifying a run

The analysis ends with a self-check comparing 29 canonical values against the
published numbers and printing a PASS/FAIL summary, so drift is visible on any
re-run.

For a full reconciliation, run the verification report after the analysis:

```sh
Rscript verify.R
```

Every number printed in the manuscript is declared there as a registry entry
naming the artifact and the field expression that produces it, and each is
compared against the artifact on disk within a declared tolerance. Results are
written to `manuscript_assets/VERIFICATION.csv` as `id | location | claim |
expected | artifact | field | tolerance | computed | status`. The report always
renders; `verify.R` carries the gate, so a failing run still leaves a readable
HTML document to read.

Two entries describe the environment rather than a number. `PRV-01` compares the
hash recorded in `manuscript_assets/PROVENANCE.txt`, written by the analysis,
against the analysis source being verified, so a reconciliation against a stale
artifact set fails rather than passing quietly. `PRV-02` pins the manuscript the
registry was transcribed from by hash, so editing the document without re-reading
the registry against it fails the check.

One entry is marked local-only. The paired pre/post-bronchodilator count differs
between sites because the ESI extracts differ outside the analytic cohort; the
analytic cohort itself is 9,402 everywhere. `verify.R` names local-only entries
on every run rather than counting them, because a waived comparison is a claim
nobody is checking.
