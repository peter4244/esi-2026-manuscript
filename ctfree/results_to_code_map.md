# Results to code map — CT-free MD-COPD paper

Every table, figure and quoted number, traced to the script that produces it,
the artifact it lands in, the claim that pins it and the METHODS.md section
that describes the method. Required by the `figures` skill: a figure is not
finished until it appears here, in the same commit that creates it.

Run order, from any working directory:

```
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/render_ctfree_2026.9.3.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/draft_tables.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure1_esi_ct.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure2_flow.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure3_group_risk.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figure4_discord_risk.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/figureS2_profile.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/verify.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/figures/check_edges.R
python3 /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/build_manuscript.py
python3 /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/build_supplement.py
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/render_massimo_report.R
```

## Tables

| | Produced by | Artifact | Claims | Methods |
|---|---|---|---|---|
| Table 1, schemas and counts | `draft_tables.R` | `schema_labels.csv` | LAB-01a/b, LAB-02, LAB-03, LAB-04 | The four classification schemas |
| Table 2, reclassification | `draft_tables.R` | `schema_labels.rds` | LAB-* | Agreement between classifications |
| Table 3, crude and adjusted risk | `draft_tables.R` | `schema_risk.csv`, `schema_crude.csv` | RISK-01 to RISK-06 | Statistical analysis |
| Results sentence, fixed ratio | `draft_tables.R` | `gate_fixedratio.csv` | GATE-01 to GATE-05 | Comparison with the fixed ratio |
| Table S1, baseline characteristics | `build_supplement.py` | `manuscript_assets/Table_S2_baseline_characteristics.csv` *(earlier analysis)* | — | Study population |
| Table S2, ESI and quantitative CT | `build_supplement.py` | `manuscript_assets/Supp_Table_CT_correlations.csv` *(earlier analysis)* | — | Study population |
| Table S3, reclassification | `build_supplement.py` | `crossclass.csv` | RECL-01, RECL-02, LAB-* | Agreement between classifications |
| Table S4, threshold fitting | `build_supplement.py` | `schema_fit.csv`, `schema_fit_cv_diff.csv` | FIT-01 to FIT-06 | Fitting the CT-free schemas |
| Table S5, discrimination | `build_supplement.py` | `schema_discrimination.csv` | DISC-01, DISC-01b, DISC-02, DISC-03 | Comparison with the fixed ratio |

## Figures

Numbering follows Massimo's 2026-09-20 draft, which is the baseline for the text
(Pete, 2026-09-20): Figure 1 ESI against the visual CT criteria, Figure 2 the
reclassification flow, Figure 3 crude group risk, Figure 4 the discordant groups,
Supplemental Figure S1 crude with adjusted risk, Supplemental Figure S2 the profile.

| Figure | Produced by | Legend | Artifact | Claims |
|---|---|---|---|---|
| ESI across the visual CT criteria | `figures/figure1_esi_ct.R` | `figures/figure1_esi_ct_legend.md` | `esi_ct_levels.csv`, `esi_ct_auc.csv` | CTLEV-01, CTLEV-02, CTAUC-01 to CTAUC-04 |
| Reclassification flow and cross-classification | `figures/figure2_flow.R` | `figures/figure2_flow_legend.md` | `schema_labels.rds`, `crossclass.csv`, `accuracy_test.csv` | RECL-11, RECL-12, ACC-01 |
| Crude group risk, and crude with adjusted in the supplement | `figures/figure3_group_risk.R` | `figures/figure3_group_risk_legend.md`, `figures/figureS1_group_risk_legend.md` | `consensus_ref_crude.csv`, `consensus_ref_risk.csv`, `consensus_ref_group.csv` | AFL-02 to AFL-26, CONSREF-04 to CONSREF-29 |
| Risk in the concordant and discordant groups | `figures/figure4_discord_risk.R` | `figures/figure4_discord_risk_legend.md` | `discord_crude_strata.csv`, `discord_rates.csv`, `discord_rates_afl.csv` | FILL-25 to FILL-29, NEW-12, NEW-13, NEW-14 |
| Profile of the concordant and discordant groups | `figures/figureS2_profile.R` | `figures/figureS2_profile_legend.md` | `discord_profile_strata.csv`, `discord_profile_tests.csv` | FILL-02 to FILL-18, NEW-07 to NEW-10 |

Every figure is gated on `validate_layout` before `ggsave` and on
`check_edges.R` after, the second because `validate_layout` cannot detect text
clipping and says so in its own header.

## Scripts

| Script | Produces | Notes |
|---|---|---|
| `ESI_ctfree_analysis_2026.9.3.Rmd` | `cohort.txt`, `cohort_flow.csv`, `mdcopd_validation.csv`, `schema_*.csv`, `schema_labels.rds`, `cv_schema_fits.csv`, `objective_selection.csv`, `reclassification.csv`, `crossclass.csv`, `gate_*.csv`, `PROVENANCE.txt` | The full analysis report. Cohort construction (validated exactly against Bhatt et al. Table 1 via `MDCOPD_PATH`), schema fitting, 5x5 stratified cross-validation, fixed-ratio nested LR gate, adjusted and crude risk. |
| `render_ctfree_2026.9.3.R` | (render wrapper) | Sets a headless-safe raster device before knitting the report. Runs from any working directory including the Channing cluster. |
| `draft_tables.R` | `DRAFT_TABLES.md` | Reads artifacts only; no number is typed. |
| `figures/figure1_esi_ct.R` | `figure1_esi_ct.png`, its legend and size file | Mean ESI by visual CT level, with the AUC inset. |
| `figures/figure2_flow.R` | `figure2_flow.png`, its legend and size file | |
| `figures/figure3_group_risk.R` | `figure3_group_risk.png`, `figureS1_group_risk.png`, their legends and size files | Crude in the main text; crude with adjusted in the supplement. |
| `figures/figure4_discord_risk.R` | `figure4_discord_risk.png`, its legend and size file | |
| `figures/figureS2_profile.R` | `figureS2_profile.png`, its legend and size file | |
| `build_manuscript.py`, `build_supplement.py` | `CT-free MD-COPD manuscript draft v2.docx`, `CT-free MD-COPD supplement draft v2.docx` | Text sources, results tables and figures; `paginate.py` supplies the supplement's contents page numbers. |
| `verify.R` | `VERIFICATION.csv` | 199 claims. Fails the run on drift. Falsification-tested. |
| `figures/check_edges.R` | console | Fails if ink touches the canvas edge. |
| `INTRODUCTION.md`, `METHODS.md`, `RESULTS.md`, `DISCUSSION.md` | prose sources | Annotated with claim ids and v15 provenance; both stripped at build. |
| `build_supplement.py` | `manuscript/CT-free MD-COPD supplement draft v1.docx` | Five supplemental tables plus the COPDGene file list. Checks that every `Supplemental Table Sn` cited in the main text is produced here and vice versa; falsification-tested. |
| `build_manuscript.py` | `manuscript/CT-free MD-COPD manuscript draft v1.docx` | Builds the document from METHODS.md, RESULTS.md, the artifacts and the figure PNGs. Nothing is hand-edited into the .docx, so a rebuild never destroys work; that is what retired the parent directory's builder. Strips claim ids and provenance markers from the prose. |
| `massimo_report.Rmd` | `massimo_report.html` | Condensed co-author report: per-category agreement of the original rule, why the overall figure was high, and the refit. Self-contained HTML for emailing. Rendered by `render_massimo_report.R`. |

## Not yet mapped

- Legends for Figures 2 to 4.
- Any figure showing ESI against quantitative CT, if that v15 material is kept.
