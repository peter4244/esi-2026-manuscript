# Results to code map — CT-free MD-COPD paper

Every table, figure and quoted number, traced to the script that produces it,
the artifact it lands in, the claim that pins it and the METHODS.md section
that describes the method. Required by the `figures` skill: a figure is not
finished until it appears here, in the same commit that creates it.

Run order, from any working directory:

```
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/gate_fixedratio.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/analysis.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/draft_tables.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure1_flow.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure2_risk.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/verify.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/check_edges.R
```

## Tables

| | Produced by | Artifact | Claims | Methods |
|---|---|---|---|---|
| Table 1, schemas and counts | `draft_tables.R` | `schema_labels.csv` | LAB-01a/b, LAB-02, LAB-03, LAB-04 | The four classification schemas |
| Table 2, reclassification | `draft_tables.R` | `schema_labels.rds` | LAB-* | Agreement between classifications |
| Table 3, crude and adjusted risk | `draft_tables.R` | `schema_risk.csv`, `schema_crude.csv` | RISK-01 to RISK-06 | Statistical analysis |
| Results sentence, fixed ratio | `draft_tables.R` | `gate_fixedratio.csv` | GATE-01 to GATE-05 | Comparison with the fixed ratio |
| Table S1, discrimination | `draft_tables.R` | `schema_discrimination.csv` | DISC-01, DISC-01b, DISC-02, DISC-03 | Comparison with the fixed ratio |
| Table S2, threshold fitting | `draft_tables.R` | `schema_fit.csv`, `schema_fit_cv_diff.csv` | FIT-01 to FIT-06 | Fitting the CT-free schemas |

## Figures

| | Produced by | Legend | Artifact | Claims |
|---|---|---|---|---|
| Figure 1, reclassification flow | `figures/figure1_flow.R` | `figures/figure1_flow_legend.md` | `schema_labels.rds` | LAB-02, LAB-03, LAB-04 |
| Figure 2, AFL-only-noCOPD | `figures/figure2_risk.R` | *(to write)* | `schema_risk.csv`, `schema_crude.csv` | RISK-01, RISK-02, RISK-03, RISK-04 |
| Figure 3, COPD-minor | `figures/figure2_risk.R` | *(to write)* | same | RISK-05 |
| Figure 4, COPD-major | `figures/figure2_risk.R` | *(to write)* | same | RISK-06 |

All four figures are gated on `validate_layout` before `ggsave` and on
`check_edges.R` after, the second because `validate_layout` cannot detect text
clipping and says so in its own header.

## Scripts

| Script | Produces | Notes |
|---|---|---|
| `gate_fixedratio.R` | `gate_fixedratio.csv`, `gate_exac_aic.csv` | The nested likelihood ratio test the reframe presupposes. Run first: if MD-COPD does not beat the fixed ratio, nothing downstream stands. |
| `analysis.R` | `schema_*.csv`, `schema_labels.rds`, `cv_schema_fits.csv`, `cohort.txt` | Fits schemas 3 and 4, cross-validates, scores all four. Asserts the reference category's crude ratio is exactly 1. |
| `draft_tables.R` | `DRAFT_TABLES.md` | Reads artifacts only; no number is typed. |
| `figures/figure1_flow.R` | `figure1_flow.png`, `figure1_flow_legend.md` | |
| `figures/figure2_risk.R` | `figure2_aflonly.png`, `figure3_copdminor.png`, `figure4_copdmajor.png` | One figure per category. |
| `verify.R` | `VERIFICATION.csv` | 35 claims. Fails the run on drift. Falsification-tested. |
| `figures/check_edges.R` | console | Fails if ink touches the canvas edge. |
| `_locate.R` | | Resolves the paper directory so nothing depends on the caller's cwd. |

## Not yet mapped

- Legends for Figures 2 to 4.
- The Supplement list of COPDGene data files, carried over from v15.
- Any figure showing ESI against quantitative CT, if that v15 material is kept.
