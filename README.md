# ESI multidimensional-COPD reformulation — analysis code

Code accompanying *The Emphysema Severity Index: A Spirometric Representation of
CT-Defined Structural Abnormalities in a Multidimensional COPD Framework*.

## Contents

| Path | Purpose |
|---|---|
| `esi_manuscript_analysis_2026.7.17_noILD.Rmd` | The analysis. Produces every result CSV consumed by the manuscript and supplement. |
| `check_config.R` | Validates a site configuration before a run. |
| `config_paths.R.example` | Template for site-local input locations. |
| `build_supplement.py` | Renders the supplement .docx from `tables/`. |
| `tables/`, `prose_py/`, `prose/` | Supplement table modules and legends. |
| `figures/` | Figure 1 and Figure 2 source. |
| `manuscript_assets/` | Result CSVs written by the analysis. |

## Data

Five COPDGene analysis files are required, obtained through your own
institutional data agreement. No participant data is included here, and no
dataset path or filename appears anywhere in this repository.

## Running it

```r
cp config_paths.R.example config_paths.R      # then edit
Rscript check_config.R config_paths.R         # validate before running
Rscript -e 'knitr::knit("esi_manuscript_analysis_2026.7.17_noILD.Rmd")'
python3 build_supplement.py                   # optional: rebuild the supplement
```

`knitr::knit` runs every chunk and writes all outputs without requiring pandoc.
Use `rmarkdown::render` instead if you also want the HTML report.

Set `ESI_CONFIG` to use a config under another name:

```sh
ESI_CONFIG=config_paths_mysite.R Rscript check_config.R
```

## Requirements

R with `survival`, `lme4`, `lmerTest`, `MASS`, `dplyr`, `tidyr`, `ggplot2`,
`scales`, `patchwork`, `multcomp`, `rpart`, `knitr`. Python 3 with
`python-docx` for the supplement build. Developed on R 4.5.2; verified to
reproduce on R 4.3.2.

Runtime is roughly ten minutes, dominated by two 1,000-iteration bootstraps.
These cache to `manuscript_assets/_cache/`; the cache records a fingerprint of
the data it came from and recomputes automatically if that changes.

## Verifying a run

The analysis ends with a self-check comparing 29 canonical values against the
published numbers and printing a PASS/FAIL summary, so drift is visible on any
re-run.
