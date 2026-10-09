# Software versions

The paper's numbers (manuscript and supplement v8) come from runs on the Channing cluster: job 6118470 (all tables
except one) and job 6120833 (`fev1_decline_random_slope.csv`), in October 2026. Versions recorded on an r9 node on
2026-10-08 (`notes/from_cluster/esi_ctfree/2026-10-08_2148_esi-pkg.md`):

| | version |
|---|---|
| R | 4.5.1 (2025-06-13), x86_64-pc-linux-gnu |
| pandoc | 2.14.0.3 |
| MASS | 7.3.65 |
| digest | 0.6.39 |
| dplyr | 1.2.0 |
| ggalluvial | 0.12.6 |
| ggplot2 | 4.0.2 |
| knitr | 1.51 |
| lme4 | 2.0.1 |
| lmerTest | 3.2.1 |
| Matrix | 1.7.4 |
| patchwork | 1.3.2 |
| png | 0.1.8 |
| rmarkdown | 2.30 |
| scales | 1.4.0 |
| survival | 3.8.6 |
| tidyr | 1.3.2 |
| xfun | 0.56 |

The figures and documents were built on a laptop from the aggregate tables with R 4.5.2 and Python 3.12 (python-docx).
Bootstrap and cross-validation results depend on the order of the input rows and reproduce on differently ordered
copies of the data only to Monte Carlo error.
