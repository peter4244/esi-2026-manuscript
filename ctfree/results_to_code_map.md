# Results to code map — CT-free MD-COPD paper

Every table, figure and quoted number in the v8 manuscript and supplement,
traced to the script that produces it, the artifact it lands in, the claims
that pin it in `verify.R`, and the Methods text that describes the method.
Required by the `figures` skill: a figure is not finished until it appears
here, in the same commit that creates it.

Names: the code and assets use S1-S4; the paper uses fixed ratio (S1),
MD-COPD-CT (S2, "MD-COPD" in code), MD-NoCT (S3, "NoCT-MD-COPD") and
MD-COPD-ESI (S4, "ESI-MD-COPD"). Methods references: M = main Methods
(`METHODS.md`, by section heading and, for Statistical analysis, paragraph);
SM = Supplemental Methods, written by `build_supplement.py::supp_methods`.

The numbers in v8 come from the Channing run on the original sid-keyed
COPDGene files (job 6118470; Table S7 from job 6120833). Bootstrap and
cross-validation results reproduce exactly only on identically ordered input
files, and otherwise to Monte Carlo error.

Run order, from the repository root:

```
Rscript check_config.R                         # header-only check of the six inputs
Rscript ctfree/render_ctfree_2026.9.3.R        # the analysis; writes ctfree/assets/
Rscript ctfree/verify.R                        # 291 claims against ctfree/assets/
Rscript ctfree/figures/figure1_esi_ct.R
Rscript ctfree/figures/figure2_flow.R          # needs ctfree/assets/schema_labels.rds
Rscript ctfree/figures/figure3_group_risk.R    # Figure 3 and Figure S1
Rscript ctfree/figures/figure4_discord_risk.R
Rscript ctfree/figures/figureS2_profile.R
Rscript ctfree/figures/check_edges.R
python3 ctfree/build_manuscript.py
python3 ctfree/build_supplement.py <out.docx>
```

## Tables

| | Produced by (Rmd chunk) | Artifact | Placed by | Claims | Methods |
|---|---|---|---|---|---|
| Table 1, the classifications and their category counts | `labels-and-flow`, `fitting` | `schema_labels.csv`, `schema_fit.csv` | `build_manuscript.py::t_classifications` | LAB-01a/b/c, LAB-02 to LAB-04, AFL-01, FIT-01 to FIT-03 | M "MD-COPD-CT classification", "ESI and modified classifications" |
| Table S1, baseline characteristics by GOLD stratum | `baseline-by-stratum` | `supp_baseline.csv` | `build_supplement.py::s1_baseline` | BASE-01, BASE-02, GOLD-01 to GOLD-08 | M "Study population" (strata not defined; see step 4, M3) |
| Table S2, threshold selection | `fitting`, `metric-sweep`, `cv-fit` | `metric_sweep.csv`, `schema_fit.csv` | `build_supplement.py::s4_sweep` | FIT-01 to FIT-03, CV-01, CV-02 | M "ESI and modified classifications" |
| Table S3, cross-classification, sensitivity, PPV, F1 | `labels-and-flow`, `f1-decomposition`, `strata-combined` (PPV bootstrap P) | `crossclass.csv`, `f1_by_category.csv`, `agreement_by_group.csv` | `build_supplement.py::s_crossclass_agreement` | RECL-01 to RECL-14, F1CAT-01 to F1CAT-03, SENS-01 to SENS-04, PPV-01 to PPV-04, AGR-01 to AGR-13, NEW-01, NEW-02, ACC-01 | M Statistical analysis para 2 |
| Table S4, unadjusted risk and rate ratios against MD-COPD-CT | `consensus-reference`, `group-paired-bootstrap` | `consensus_ref_crude.csv`, `group_vs_mdcopd.csv` (type crude), `consensus_ref_group.csv` | `build_supplement.py::s_groups_crude` | AFL-02 to AFL-26, GRP-01 to GRP-15, MIN-01 to MIN-04, MINOR-01 to MINOR-09, MAJ-01 to MAJ-04, CI-01, CI-02, RATE-01 to RATE-10, FILL-01, REF-M, REF-E, DISC-MINOR, DISC-MINOR-ESI | M Statistical analysis paras 3-4; SM "Unadjusted outcome comparisons and bootstrap procedures" |
| Table S5, adjusted risk and ratios of HRs/IRRs | `consensus-reference`, `group-paired-bootstrap` | `consensus_ref_risk.csv`, `group_vs_mdcopd.csv` (type adjusted) | `build_supplement.py::s_risk_common_ref` (calls `build_manuscript.py::t_risk_common_ref`) | CONSREF-00 to CONSREF-32, ADJ-01 to ADJ-07, ADJ-ESI-AFL, CI-03 to CI-15, MIN-05, MAJ-05 to MAJ-09 | M Statistical analysis paras 3-4; SM as Table S4 |
| Table S6, FEV₁ decline | `fev1-decline`, `fev1-paired-bootstrap` | `fev1_decline.csv`, `fev1_noct_vs_esi.csv` | `build_supplement.py::s6_fev1_decline` | DEC-01, DEC-02, FEV1-01 to FEV1-08, FEV1-NE, FILL-20 to FILL-22 | M Statistical analysis para 5 |
| Table S7, FEV₁ decline with random slopes (sensitivity) | `fev1-decline-random-slope` | `fev1_decline_random_slope.csv` | `build_supplement.py::s_fev1_random_slope` | RS-01 to RS-04 | Table S7 legend (not in M) |
| Table S8, outcomes by concordance and discordance | `discordance-groups`, `discordance-rates`, `strata-combined` | `discord_crude_strata.csv`, `discord_rates.csv`, `discord_rates_afl.csv` | `build_supplement.py::s_discord_risk` (calls `build_manuscript.py::t_discord_risk`) | DISC2-01 to DISC2-03, NEW-03 to NEW-06, NEW-12 to NEW-14, FILL-25 to FILL-29, DISC-BOTH3 | M Statistical analysis para 6; SM "Discordant classification analyses" |

Supplemental table numbers come from position in `supp_registry.py::SUPP_KEYS`.

## Figures

| Figure | Produced by | Legend | Artifact | Claims | Methods |
|---|---|---|---|---|---|
| Figure 1, ESI across the visual CT criteria, with AUC insets | `figures/figure1_esi_ct.R` | `figures/figure1_esi_ct_legend.md` | `esi_ct_levels.csv`, `esi_ct_auc.csv` (chunk `esi-visual-ct`) | CTLEV-01, CTLEV-02, CTAUC-01 to CTAUC-08, SM-CTMISS | M Statistical analysis para 1; SM "Visual CT assessment" |
| Figure 2, reclassification flow and cross-classification | `figures/figure2_flow.R` | `figures/figure2_flow_legend.md` | `schema_labels.rds` (participant-level), `reclassification.csv`, `accuracy_test.csv` (chunk `labels-and-flow`) | RECL-01, RECL-02, RECL-09 to RECL-14, ACC-01, LAB-* | M Statistical analysis para 2 |
| Figure 3, unadjusted risk by diagnostic group | `figures/figure3_group_risk.R` | `figures/figure3_group_risk_legend.md` | `consensus_ref_crude.csv`, `consensus_ref_risk.csv`, `consensus_ref_group.csv` (chunk `consensus-reference`) | AFL-02 to AFL-26, CONSREF-04 to CONSREF-29, REF-M, REF-E | M Statistical analysis paras 3-4 |
| Figure 4, risk in the concordant and discordant groups | `figures/figure4_discord_risk.R` | `figures/figure4_discord_risk_legend.md` | `discord_crude_strata.csv`, `discord_rates.csv`, `discord_rates_afl.csv` | FILL-25 to FILL-29, NEW-12 to NEW-14, DISC-BOTH3 | M Statistical analysis para 6; SM "Discordant classification analyses" |
| Figure S1, unadjusted and adjusted risk | `figures/figure3_group_risk.R` (no separate script) | `figures/figureS1_group_risk_legend.md` | as Figure 3 | as Tables S4 and S5 | M Statistical analysis paras 3-4 |
| Figure S2, profile of the concordant and discordant groups | `figures/figureS2_profile.R` | `figures/figureS2_profile_legend.md` | `discord_profile_strata.csv`, `discord_profile_tests.csv` (chunks `strata-combined`, `strata-profile-tests`) | FILL-02 to FILL-19, FILL-23, FILL-24, NEW-07 to NEW-11, DISC-ESIC, DISC-CTONLY | M Statistical analysis para 6 |

Figure 2 is the only display item that needs participant-level data: it reads
`ctfree/assets/schema_labels.rds`, which the render writes and git ignores.
Every other figure script reads aggregate assets only.

Every figure is gated on `validate_layout` before `ggsave` and on
`check_edges.R` after, the second because `validate_layout` cannot detect text
clipping and says so in its own header.

## Numbers quoted in the text

| Text | Artifact | Claims |
|---|---|---|
| Methods: 9,240 analysed; 8,769 in mortality analyses; 8,177 in exacerbation analyses | `cohort.txt`, `followup_medians.csv` | COH-01, FU-06, FU-07 |
| Results: GOLD stratum counts and mean ESI 0.90 to 8.30 | `supp_baseline.csv` | GOLD-01 to GOLD-08 |
| Results: bronchodilator change −0.09 [−0.11 to −0.08] | `bronchodilator_delta_esi.csv` | CONT-06, CONT-07, BD-CI, FILL-30 to FILL-32 |
| Results/Abstract: AUCs 0.78, 0.80; 0.75, 0.75; 0.56, 0.61 | `esi_ct_auc.csv` | CTAUC-01, CTAUC-03, CTAUC-05 to CTAUC-08 |
| Results/Abstract: agreement 89.0% vs 85.0%, P < 0.005 | `reclassification.csv`, `accuracy_test.csv` | RECL-09 to RECL-12, ACC-01 |
| Results: 833 (21.9%) vs 350 (9.2%) | `reclassification.csv` | RECL-01, RECL-02, RECL-13, RECL-14 |
| Results: median follow-up 11.2 / 8.6 / 10.4 / 9.7 years | `followup_medians.csv` | FU-01 to FU-05 |
| Results: respiratory rates 0.39 and 0.09 per 100 person-years | `consensus_ref_crude.csv` | RATE-08 to RATE-10 |
| Discussion: "four times the size (1,108 versus 275)"; "more than half" | `schema_labels.csv`, `crossclass.csv` | DISC-FOUR, DISC-AFLN, DISC-HALF, DISC-KEPT |
| Supplemental Methods: missing visual CT scores (n = 4) | `esi_ct_levels.csv` | SM-CTMISS |

Not registered: the 469 participants without follow-up (Methods) are not in
any asset; "R version 4.5.2" (Methods) is not checked, and `PROVENANCE.txt`
for the Channing run records R 4.5.1.

## Scripts

| Script | Produces | Notes |
|---|---|---|
| `../check_config.R` | console | Reads only the header line of each input; checks the six paths, the identifier column and every column the analysis reads. |
| `ESI_ctfree_analysis_2026.9.3.Rmd` | every CSV in `assets/`, `schema_labels.rds`, `PROVENANCE.txt`, and an HTML report | The full analysis. Cohort construction (validated exactly against Bhatt et al. Table 1 via `MDCOPD_PATH`), classification fitting, 5x5 stratified cross-validation, common-reference risk, paired bootstraps, FEV₁ decline, discordance. Several chunks (fixed-ratio gate, own-reference risk, discrimination, continuous ESI, ESI trajectory) write assets that v8 does not use. |
| `render_ctfree_2026.9.3.R` | (render wrapper) | Sets a headless-safe raster device before knitting the report. |
| `verify.R` | `assets/VERIFICATION.csv` | The claim registry: 291 claims, each a printed value against its asset field. Fails the run on drift. Does not read the manuscript text. |
| `figures/figure1_esi_ct.R` | `figure1_esi_ct.png`, its legend and size file | |
| `figures/figure2_flow.R` | `figure2_flow.png`, its legend and size file | Needs `assets/schema_labels.rds`. |
| `figures/figure3_group_risk.R` | `figure3_group_risk.png`, `figureS1_group_risk.png`, their legends and size files | Unadjusted in the main text; unadjusted with adjusted in the supplement. |
| `figures/figure4_discord_risk.R` | `figure4_discord_risk.png`, its legend and size file | |
| `figures/figureS2_profile.R` | `figureS2_profile.png`, its legend and size file | |
| `figures/check_edges.R` | console | Fails if ink touches the canvas edge. |
| `build_manuscript.py` | `manuscript/CT-free MD-COPD manuscript draft v<N>.docx` (path set in `OUT`) | Builds the document from the .md sources, the assets and the figure PNGs. Nothing is hand-edited into the .docx, so a rebuild never destroys work. Strips claim ids and provenance markers from the prose. |
| `build_supplement.py <out.docx>` | the supplement .docx at the path given | Supplemental Methods, Tables S1-S8, Figures S1-S2 and the COPDGene file list. Checks that every supplemental table cited in the main text is produced and vice versa. `paginate.py` supplies the contents page numbers. |
| `supp_registry.py` | — | Supplemental table order, read by both builders. |
| `INTRODUCTION.md`, `METHODS.md`, `RESULTS.md`, `DISCUSSION.md`, `ABSTRACT.md`, `AT_A_GLANCE.md`, `TITLEPAGE.md`, `REFERENCES.md` | prose sources | Read by the builders. |
| `draft_tables.R` | `DRAFT_TABLES.md` | Earlier working tables (own-reference risk, discrimination, gate); not part of v8. Also reads `schema_labels.rds`. |
| `massimo_report.Rmd` | `massimo_report.html` | Co-author report on the refit, rendered by `render_massimo_report.R`; reads `manuscript_assets/` as well. Not needed for the paper. |
