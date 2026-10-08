# Step 4: reproducibility and completeness (2026-10-08)

Scope: the v5 manuscript and supplement (`ctfree/manuscript/CT-free MD-COPD ... draft v5.docx`, text extracted with python-docx), against the changit snapshot `bf72167` (local branch `changit-snapshot`) and the working tree at `c9a6802`. The snapshot and `main` differ only in five planning notes (DRAFT_TABLES.md, EMAIL_massimo_draft.md, OUTLINE.md, RESULTS_OUTLINE.md, REVIEW_PJC_2026.9.8.md), so every code file and asset cited below is identical in both.

Nothing was knitted, rendered or built. No participant-level file was opened. The only inputs read were code, prose, aggregate CSVs in `ctfree/assets/`, the cluster notes, and the `sessionInfo()` block of the locally rendered HTML.

Name crosswalk used throughout: the artifacts and code use S1 = fixed ratio, S2 = MD-COPD-CT (code calls it "MD-COPD"), S3 = MD-NoCT (code: "NoCT-MD-COPD"), S4 = MD-COPD-ESI (code: "ESI-MD-COPD"). "Rmd" means `ctfree/ESI_ctfree_analysis_2026.9.3.Rmd`.

---

## 1. Trace table

Columns: what the paper shows, the asset, the producing Rmd chunk or script, the builder or figure script that puts it on the page, and the Methods text that describes it (M = main Methods / METHODS.md, SM = Supplemental Methods in the supplement docx, which is hardcoded in `build_supplement.py::supp_methods`). "Reg." says whether `verify.R` pins the number.

### Tables and figures

| Item | Asset(s) | Rmd chunk (line) / script | Placed by | Methods | Status |
|---|---|---|---|---|---|
| Table 1, category counts | `schema_labels.csv`, `schema_fit.csv` (ESI cut) | `labels-and-flow` (698), `fitting` (428) | `build_manuscript.py::t_classifications` | M "MD-COPD-CT classification", "ESI and modified classifications" | OK |
| Figure 1, ESI by visual CT level, AUC insets | `esi_ct_levels.csv`, `esi_ct_auc.csv` | `esi-visual-ct` (1709) | `figures/figure1_esi_ct.R` | M Stats para 1 (ROC/AUC) | OK. "9,236 had a visual score" is computed by the script from `esi_ct_levels.csv`. |
| Figure 2, flow + cross-classification | `schema_labels.rds`, `reclassification.csv`, `accuracy_test.csv` | `labels-and-flow` (698) | `figures/figure2_flow.R` | M Stats para 2 (McNemar) | **Gap:** `schema_labels.rds` is participant-level, git-ignored and absent from the snapshot. Figure 2 is the only display item that cannot be regenerated from the published assets; this is not stated anywhere. |
| Figure 3, unadjusted group risk | `consensus_ref_crude.csv`, `consensus_ref_risk.csv`, `consensus_ref_group.csv` | `consensus-reference` (1191) | `figures/figure3_group_risk.R` | M Stats para 4; SM "Unadjusted outcome comparisons" | OK |
| Table S1, baseline by stratum | `supp_baseline.csv` | `baseline-by-stratum` (284) | `build_supplement.py::s1_baseline` | **None.** PRISm/GOLD stratum definitions and FEV1 % predicted reference equations (`FEV1pp_utah`) are not described. | Gap (Methods) |
| Table S2, threshold selection | `metric_sweep.csv`, `schema_fit.csv` | `metric-sweep` (515), `fitting` (428), `cv-fit` (574) | `build_supplement.py::s4_sweep` | M "ESI and modified classifications" para 3 | Partial: search grid not described; CV/Methods mismatch (finding M2) |
| Table S3, cross-classification, Sens/PPV/F1, PPV P | `crossclass.csv`, `f1_by_category.csv`, `agreement_by_group.csv` | `labels-and-flow` (698), `f1-decomposition` (546), **`strata-combined` (2053)** | `build_supplement.py::s_crossclass_agreement` | M Stats para 2 | OK, but the PPV bootstrap sits inside the discordance chunk headed "Section 9b -- for Figures 5 and 6". A reader looking for Table S3's P values will not find them there. |
| Table S4, unadjusted risk + ratio vs MD-COPD-CT | `consensus_ref_crude.csv`, `group_vs_mdcopd.csv` (type crude), `consensus_ref_group.csv` | `consensus-reference` (1191), `group-paired-bootstrap` (1402) | `build_supplement.py::s_groups_crude` | M Stats para 4; SM both paras | Partial: bootstrap P definition and dropped-resample rule not described (M4) |
| Table S5, adjusted risk + ratio of HRs/IRRs | `consensus_ref_risk.csv`, `group_vs_mdcopd.csv` (type adjusted) | same two chunks | `build_manuscript.py::t_risk_common_ref` via `s_risk_common_ref` | M Stats paras 3-4 | Same as S4 |
| Table S6, FEV1 decline | `fev1_decline.csv`, `fev1_noct_vs_esi.csv` | `fev1-decline` (1494), `fev1-paired-bootstrap` (1607) | `build_supplement.py::s6_fev1_decline` | M Stats para 5 | Partial: column-4 P is a lmerTest Satterthwaite test and age/smoking are time-varying; neither is stated. Baseline-FEV1-by-time is in the table legend only. |
| Table S7, discordance outcomes | `discord_crude_strata.csv`, `discord_rates.csv`, `discord_rates_afl.csv` | `discordance-groups` (1851), `discordance-rates` (1974), `strata-combined` (2053) | `build_manuscript.py::t_discord_risk` | M Stats para 6; SM "Discordant classification analyses" | OK |
| Figure 4, discordance risk | `discord_crude_strata.csv`, `discord_rates*.csv` | as Table S7 | `figures/figure4_discord_risk.R` | as Table S7 | OK |
| Figure S1, unadjusted + adjusted | as Figure 3 | `consensus-reference` (1191) | `figures/figure3_group_risk.R` (writes both; there is no `figureS1_*.R`) | M Stats paras 3-4 | OK; the script header calls it "Figure 2" |
| Figure S2, profile and tests | `discord_profile_strata.csv`, `discord_profile_tests.csv` | `strata-combined` (2053), `strata-profile-tests` (2156) | `figures/figureS2_profile.R` | M Stats para 6 (Wilcoxon, Fisher) | OK; SE bars only in the legend |
| SM "COPDGene files used" | none (hardcoded) | — | `build_supplement.py::data_files` | — | Partial: the ESI input file is not listed (finding H3) |

### Quoted numbers in the text

| Text | Value | Asset / field | Producing chunk | Reg. | Methods |
|---|---|---|---|---|---|
| Methods, mortality n | 9,238 | `followup_medians.csv` n (also sum of `schema_risk.csv` n_mort) | `outcome-data` (773) | **No** | M Study population |
| Methods, exacerbation n | 8,177 | `followup_medians.csv` n | `outcome-data` | **No** | M Study population |
| Methods, R version | 4.5.2 | `PROVENANCE.txt` | `provenance` (2343) | **No** | M Stats last para |
| Results, GOLD stratum counts | 1,119 / 4,037 / 734 / 1,772 / 1,050 / 528 | `supp_baseline.csv` n | `baseline-by-stratum` | **No** (only the overall n) | **None** (no stratum definitions) |
| Results, mean ESI 0.90 to 8.30 | | `supp_baseline.csv` ESI | `baseline-by-stratum` | **No** | — |
| Results, bronchodilator change −0.09 [−0.11 to −0.08], "statistically significant" | | `bronchodilator_delta_esi.csv` (mean, sd, n only) | `bronchodilator-delta` (1821) | Yes (BD-CI) | M Stats para 1 says "paired t-test" | **Broken link (H2):** no code in the analysis computes the CI, a t statistic or a P value. The CI is reconstructed only inside `verify.R` (BD-CI); the significance claim has no producing code and no asset. n = 9,234 paired, not 9,240, and this is unstated. |
| Results, thresholds ≥2 of 3 and ESI ≥1.50 | | `schema_fit.csv`, `PROVENANCE.txt` | `fitting` | Yes (FIT-01, ...) | M |
| Results, ESI by CT level 1.04 / 6.62 / 0.96 / 3.32 | | `esi_ct_levels.csv` | `esi-visual-ct` | Yes (CTLEV-01/02) | M Stats para 1 |
| Results/Abstract, AUC 0.78, 0.80; 0.75, 0.75; 0.56, 0.61 | | `esi_ct_auc.csv` | `esi-visual-ct` | Partial: 0.78 and 0.56 pinned; 0.80, 0.75 (x2), 0.61 only through an ordering test (CTAUC-04) | M Stats para 1 |
| Agreement 89.0% (8,222) vs 85.0% (7,852), McNemar P < 0.005 | | `accuracy_test.csv` | `labels-and-flow` | Yes | M Stats para 2 (does not say uncorrected McNemar) |
| Sensitivity/PPV, noCOPD and COPD-minor (89.3/88.5, 97.7/97.8; 88.7/89.4, 60.4/58.8) | | `agreement_by_group.csv` | `strata-combined` | **No** at 1 dp (COPD-minor PPV pinned only as rounded integers) | M Stats para 2 |
| AFL-only and COPD-major sensitivity/PPV (100/70.2, 24.8/35.5; 78.1/90.8, 100/97.7) | | `agreement_by_group.csv` | `strata-combined` | Sensitivities yes; **PPVs no** | M Stats para 2 |
| 833 (21.9%) vs 350 (9.2%) | | `reclassification.csv` | `labels-and-flow` | 833/350 yes; **21.9% and 9.2% no**; 9.2% (350/3,809) is not in any asset field | — |
| Median follow-up 10.8 / 10.4 / 9.7 y | | `followup_medians.csv` | `followup-medians` (1582) | Yes (FU-01..03) | **None.** 9.7 y is the median among the 5,414 with a follow-up visit, which the text does not say; mortality follow-up is the plain median of observed time, not reverse Kaplan-Meier. |
| AFL-only rate ratios vs MD-COPD-CT, ratios of HRs/IRRs, P values | | `group_vs_mdcopd.csv` | `group-paired-bootstrap` | Yes | M Stats para 4, SM |
| Respiratory rates 0.30 and 0.07 per 100 PY | | `consensus_ref_crude.csv` rate_100py | `consensus-reference` | **No** | — |
| FEV1 decline statements | | `fev1_decline.csv` | `fev1-decline` | Yes | M Stats para 5 |
| Discussion "four times the size (1,108 versus 275)" | | `schema_labels.csv` (derived ratio) | `labels-and-flow` | Counts yes; the ratio no | — |
| Discussion "more than half" (483 of 833) | | derived from `reclassification.csv` | `labels-and-flow` | **No** | — |
| Figure 3/S1/Table S4/S5 legends, common reference 3,856 | | `consensus_ref_group.csv` | `consensus-reference` | Yes | M Stats para 4 |
| SM "missing visual CT scores (n = 4)" | | 9,240 − 9,236, from `esi_ct_levels.csv` | `ingest-and-cohort` (sets NA to FALSE) | **No**; the prose value is hardcoded in `build_supplement.py` | SM |

All 249 registered claims PASS in `assets/VERIFICATION.csv` (written 2026-10-07). The gaps above are text values that have no registry entry, not failed entries.

### Assets or figures produced by code not in the snapshot

- None. Every asset in `ctfree/assets/` is written by the Rmd, and every figure PNG by a script under `ctfree/figures/`. The figure scripts also source `figures/style.R` and `figures/validate_layout.R` from the repository root, and both are in the snapshot.
- The verification and reproduction helpers used on 2026-10-07 (`ctfree_preflight.R`, `ctfree_compare_assets.R`, `ctfree_install_missing.R`, `run_ctfree_repro.sh`) are not in the snapshot. That is fine for a deposit. But the snapshot's own `check_config.R` is weaker than the preflight that was used (finding H4).
- Assets that are produced but used by nothing in v5: `supp_esi_ct.csv`, `gate_*.csv`, `schema_risk.csv`, `schema_crude.csv`, `schema_discrimination.csv`, `schema_binary.csv`, `binary_vs_mdcopd.csv`, `raw_discrimination.csv`, `objective_selection.csv`, `cv_*`, `schema_fit_cv_*`, `continuous_esi_*`, `esi_trajectory.csv`, `consensus_ref_lost.csv`, `discord_adjusted*.csv`, `discord_profile*.csv` (non-strata), `schema_diff_bootstrap.csv`, `mdcopd_validation.csv`, `cohort_flow.csv`. These are not errors, but a reader of the deposit cannot tell which assets belong to the paper; finding M6 covers this.

---

## 2. Findings ranked by severity

### High

**H1. The snapshot's top-level run instructions fail.** The root `README.md` in `bf72167` tells the reader to run `ctfree/figures/figure1_flow.R` "likewise figure2_group_risk.R, figure3_discord_risk.R, figure4_profile.R". None of these files exist. The scripts are `figure1_esi_ct.R`, `figure2_flow.R`, `figure3_group_risk.R` (which writes Figures 3 and S1), `figure4_discord_risk.R` and `figureS2_profile.R`, and `figure1_esi_ct.R` is missing from the list altogether. The same README says `ctfree/manuscript/` holds the current .docx files, but the snapshot contains no `ctfree/manuscript/` files.

**H2. The bronchodilator result has no producing code for its CI or its significance claim.** The Results quote "mean change −0.09 [95% CI −0.11 to −0.08]" and call the change statistically significant. Methods says a paired t-test. The `bronchodilator-delta` chunk writes only n, mean and SD. The CI exists only as an arithmetic check inside `verify.R` (BD-CI), and no code anywhere computes a t statistic or a P value. The analysed n is 9,234 paired measurements, not the 9,240 cohort, and the text does not say so. Fix: add `t.test(ESI_1, ESI_0, paired = TRUE)` to the chunk and write its estimate, CI and P to the asset.

**H3. No data or code availability statement, and the ESI input cannot be traced.** The manuscript has no data availability statement, no code availability statement (changit repository and commit), no COPDGene funding acknowledgment, and no IRB or consent statement. The supplement's "COPDGene files used" lists five files but not the sixth input, the ESI values. It says only that ESI "values were computed from the COPDGene spirometric flow-volume curves as described in the main text", and the main text gives the algorithm's inputs but not its formula, so no reader could recompute ESI. The deposit should say who computed the ESI values, with which software or version, and how a qualified investigator can get them. The listed file names also omit version stamps that the cluster run used: `COPDGene_Mort_COD_Adj_SMNS_Y2018`, `LFU_SidLevel_Comorbid_SM_30SEP21`.

**H4. The snapshot's config validator does not validate this paper's inputs.** `check_config.R` (snapshot root) is still the v15 checker:
- It does not require or check `MDCOPD_PATH`, because the `need` vector omits it.
- Its column lists miss columns the ctfree Rmd reads:
  - ESI file: `visitnum`, `PrePost`
  - phenotype file: `ExclusionaryDisease`, `CoronaryArtery`, `CongestHeartFail`, `Exacerbation_Frequency`, `FEV1pp_utah`, `FEV1_post`, `Insp_LAA950_total_Thirona`, `PRM_pct_emphysema_Thirona`, `CT_Visual_Emph_Severity`
  - MD-COPD file: `MultiDim_COPD_score`
- It requires `Total_Severe_Exacer`, which ctfree does not use.

`config_paths.R.example` does define `MDCOPD_PATH`, but its header says "All five inputs". It does not say that the ESI file needs `visitnum` and `PrePost` (0 = pre, 1 = post) columns. Its `OUT_DIR` comment ("Must match ASSETS in manifest.py") applies only to v15; the ctfree Rmd ignores `OUT_DIR`. The Rmd also points readers to "the header comment on MDCOPD_PATH in config_paths.R.example for the full story", and that comment is three lines.

### Medium

**M1. Package versions are not recorded in the deposit.**
- The root README lists package names without versions, and there is no `renv.lock`.
- `sessionInfo()` is printed only into the rendered HTML, which is git-ignored and was kept off the cluster transfer. The HTML records: R 4.5.2; dplyr 1.2.1, survival 3.8-3, MASS 7.3-65, lme4 2.0-1, lmerTest 3.2-1, Matrix 1.7-4, digest 0.6.39, knitr 1.51, rmarkdown 2.30, tidyr 1.3.1, ggplot2 4.0.1.
- Versions of the figure packages (ggalluvial, patchwork, scales, png) and of the Python build tools (python-docx, PyMuPDF, LibreOffice) are recorded nowhere.
- `PROVENANCE.txt` holds R version, seed and fitted parameters, but no commit hash, Rmd checksum or package versions. The v15 PROVENANCE recorded a source md5; this one does not.
- The 2026-10-07 cluster reproduction ran R 4.5.1, while the paper states 4.5.2. That is consistent, because the published assets are the laptop run, but it should be noted in the README.

Fix: write `sessionInfo()` to `assets/SESSION_INFO.txt` and add `git rev-parse HEAD` to PROVENANCE.

**M2. CV procedure in Methods does not match the code.** Methods says candidate thresholds "were evaluated by five-fold cross-validation repeated five times using Cohen's κ, mean per-category sensitivity, and macro-F1". In `cv-fit`, only macro-F1 is optimised and evaluated inside the folds, along with held-out overall agreement. κ and balanced accuracy are computed only on the full cohort (`metric-sweep`, `objective-selection`). Methods also does not state:
- the search grid (S3: k = 1-3; S4: k = 2-4 by ESI cut-point 0.50-4.00 in 0.25 steps);
- that folds were stratified on MD-COPD-CT category;
- the seed.

Table S2 shows only the k = 2 rows for ESI and a subset of cut-points, without saying so. This overlaps step 5 and is listed here because it blocks reproducing Table S2 from the text.

**M3. Several analyses reported in Results have no Methods description.** These are:
- PRISm/GOLD strata and FEV1 % predicted equations (Table S1)
- median follow-up definitions (Results para 4)
- the fact that MD-COPD-CT categories were taken from the source report's per-participant file rather than re-derived (stated only in the supplement file list)
- the 9,416 → 9,240 step (176 without baseline ESI)
- CAD/CHF definitions for the cardiac rule
- handling of missing symptom criteria (set to "not met", as for visual CT)
- the exacerbation outcome variable (total, not severe-only) and the source of baseline exacerbation frequency
- Cox time scale
- the McNemar variant (uncorrected)
- the FEV1 model's time-varying covariates and Satterthwaite P values

Draft text is in section 4.

**M4. Bootstrap details are missing.** The paper reports bootstrap P values to "< 0.005" without defining them. The code uses percentile intervals and P = 2 × min(share of resampled log-differences ≤ 0, share ≥ 0). Resamples in which a model fails are dropped, and the run aborts if fewer than 95% of 1,000 succeed (`B_eff`). Mortality and exacerbation analysis sets are resampled independently. All resampling uses seed 20260901. None of this is in M or SM, and `B_eff` appears nowhere in the manuscript.

**M5. Bootstrap results reproduce only to Monte Carlo error, and this is undocumented.** Per the 2026-10-07 cluster run, deterministic outputs matched exactly but bootstrap and CV outputs did not, because the identified and de-identified files have different row order. A reader with their own COPDGene copy will hit the same thing. The README should say so explicitly, so that a mismatch at the third decimal of an interval is not read as a failed reproduction.

**M6. No chunk or figure script says which manuscript item it produces or which Methods section it implements.** Only two Rmd headings name a supplement table, and one of those is wrong (below). No chunk cites METHODS.md. The full list is in section 3.

**M7. The companion documents are out of date with v5.**
- `results_to_code_map.md`:
  - describes Tables 2 and 3, which v5 does not have;
  - maps Tables S1-S5 to their pre-v5 contents (S1 from `manuscript_assets/` "earlier analysis", S2 = ESI vs quantitative CT, S4 = threshold fitting, S5 = discrimination);
  - has no rows for Tables S6 and S7 and no figure numbers in its figure table;
  - cites Methods sections that no longer exist ("The four classification schemas", "Fitting the CT-free schemas", "Comparison with the fixed ratio", "Agreement between classifications");
  - says the builders write "draft v1/v2" .docx, gives "199 claims" (the actual count is 249), and gives run commands with absolute `/Users/petecastaldi/...` paths.
- `CLAIMS.md`:
  - uses the old names (MD-COPD, NoCT-MD-COPD, ESI-MD-COPD);
  - its values are superseded and, if `verify.R` still used them, would fail: ESI threshold 1.25 (now 1.50), t_high 7.0 (dropped), held-out F1 0.753/0.720 (now 0.762/0.732), COH-02 4,113 (now 4,084), LAB-03 3,803 (now 3,541), LAB-04 "1,119 vs 170" (now 1,108 vs 275), RISK-01..06 HRs against own-classification references;
  - lists about 25 claims while `verify.R` registers 249;
  - `verify.R`'s header says "Every claim in ctfree/CLAIMS.md is evaluated", which is no longer true, because verify.R is now the live registry.
- `ctfree/README.md`:
  - says "One R Markdown report produces every result, table, and figure" (figures come from five separate scripts);
  - says it "writes every artifact to OUT_DIR (defined in config_paths.R)" (it always writes `ctfree/assets/`);
  - says verify.R checks claims "against the manuscript prose" (it checks hardcoded expected values against assets and does not read prose);
  - has a "Three traps" section quoting superseded numbers (1,119 AFL-only vs 170, 6.6x);
  - uses absolute laptop paths;
  - its file table omits the figure scripts and builders.
- Root `README.md` (snapshot): uses "NoCT classification", "ESI classification", "MD-COPD", plus H1.

**M8. Stale labels inside the code.**
- Figure-script headers: `figure2_flow.R` says "Figure 1", `figure3_group_risk.R` "Figure 2", `figure4_discord_risk.R` "Figure 3", `figureS2_profile.R` "Figure 4".
- Rmd Section 1.2 is headed "(Supplemental Table S2)" but produces `supp_esi_ct.csv`, which is no longer in the supplement; S2 is now threshold selection.
- Rmd Section 9b says "for Figures 5 and 6", and `strata-profile-tests` says "Figure 5 brackets"; these are now Table S7, Figure 4 and Figure S2.
- Rmd line 415 says ESI-MD-COPD "needs the two ESI thresholds"; there is one.
- Rmd line 1174 quotes own-reference sizes "4,357, 3,853 and 3,815"; the current values are 4,357, 3,982 and 3,941.
- The Rmd Overview says "a closing self-check block echoes every canonical value cited in the manuscript prose", but Section 11 only checks that files exist. It also says figures are written to `OUT_DIR`, but no figure is written by the Rmd.
- Group names in code and assets are the old ones throughout. A one-line crosswalk (S1-S4 to the v5 names) belongs in the Rmd header and the README.

### Low

**L1. Number tokens in v5 prose with no registry entry** (they trace to assets, but drift would not be caught):
- 9,238 and 8,177
- GOLD stratum counts, and ESI means 0.90 and 8.30
- noCOPD and COPD-minor sensitivity and PPV at 1 dp; AFL-only and COPD-major PPV
- 21.9% and 9.2%
- AUCs 0.80, 0.75 and 0.61 as values
- respiratory rates 0.30 and 0.07
- "four times" and "more than half"
- R 4.5.2
- the hardcoded "n = 4" in SM

**L2. Discordance-group names vary.** Fig 4/S2 use "CT-only" and "ESI-only"; Table S7 uses "CT-only-COPD" and "ESI-only-COPD"; Results uses "MD-COPD-CT-only group" and "MD-COPD-ESI-only group". The main Methods defines only the two reference groups. "Both-COPD" is defined only in legends.

**L3. Macro-F1 is used in main Methods without a definition.** It is defined only in the Table S2 legend.

**L4. `build_supplement.py` has the guard imports above its shebang and docstring.** As a result the docstring is not the module docstring. This is cosmetic.

**L5. `massimo_report.Rmd` and `render_massimo_report.R` are in the snapshot but read `manuscript_assets/` (v15).** They are not needed for the paper and should be marked as such.

---

## 3. Chunks and scripts: what they produce and whether they say so

None of the chunks or scripts below cites a Methods section. The "States paper output?" column records whether the code itself names the table or figure it feeds.

| Chunk / script | Feeds | States paper output? |
|---|---|---|
| `paths`, `setup` | — | n/a |
| `ingest-and-cohort` | Methods Ns, cohort; `cohort_flow.csv`, `mdcopd_validation.csv` | No |
| `baseline-by-stratum` | Table S1, Results para 1 | Yes (heading) |
| `esi-ct-correlations` | nothing in v5 | Wrong (says Table S2) |
| `classifications` | Table 1 definitions | No |
| `fitting` | Table 1, Table S2, Results para 1 | No |
| `objective-selection` | nothing in v5 | No |
| `metric-sweep` | Table S2 | No |
| `f1-decomposition` | Table S3 F1 column | No |
| `cv-fit` | Table S2 legend (held-out agreement) | No |
| `labels-and-flow` | Table 1, Table S3, Figure 2, agreement and McNemar results, 833/350 | No |
| `outcome-data` | Methods Ns 9,238 / 8,177 | No |
| `gate-fixedratio`, `adjusted-risk`, `crude-rr`, `binary-discrimination`, `raw-discrimination`, `binary-vs-mdcopd` | nothing in v5 | No (should be marked "not used in v5") |
| `consensus-reference` | Figure 3, Figure S1, Tables S4/S5, respiratory rates | No |
| `group-paired-bootstrap` | Tables S4/S5 ratio columns, Abstract and Results AFL-only ratios | No |
| `fev1-decline`, `fev1-paired-bootstrap` | Table S6 | No |
| `followup-medians` | Results median follow-up | No |
| `continuous-esi-prognosis`, `continuous-esi-gold0`, `esi-trajectory` | nothing in v5 | No |
| `esi-visual-ct` | Figure 1, Results para 2, Abstract AUCs | No |
| `bronchodilator-delta` | Results para 1 | No |
| `discordance-groups`, `discordance-rates`, `discordance-adjusted` | Table S7 n and deaths (rates); adjusted not used | No |
| `strata-combined` | Table S7, Figure 4, Figure S2, **and Table S3 PPV P values** | Wrong ("Figures 5 and 6") |
| `strata-profile-tests` | Figure S2 brackets | Wrong ("Figure 5") |
| `paired-bootstrap` | nothing in v5 (`schema_diff_bootstrap.csv`) | No |
| `completeness`, `provenance`, `session` | `PROVENANCE.txt` | n/a |
| `figures/figure1_esi_ct.R` | Figure 1 | Yes |
| `figures/figure2_flow.R` | Figure 2 | Wrong number (says Figure 1) |
| `figures/figure3_group_risk.R` | Figure 3, Figure S1 | Wrong number (says Figure 2) |
| `figures/figure4_discord_risk.R` | Figure 4 | Wrong number (says Figure 3) |
| `figures/figureS2_profile.R` | Figure S2 | Wrong number (says Figure 4) |

Suggested fix: one comment line per chunk in the form `# Paper: Table S4 cols 4-6; Methods: Statistical analysis para 4, SM "Unadjusted outcome comparisons"`, plus a "not used in v5" tag on the unused chunks.

---

## 4. Suggested missing Methods text (for review; no file was edited)

**Main Methods, "Study population"** (append):
> Of the 9,416 participants classified by MD-COPD-CT in the source report, 176 without a baseline post-bronchodilator ESI were excluded. MD-COPD-CT categories were taken from the source report's per-participant classification file rather than re-derived; the category counts matched the published counts exactly.

**Main Methods, "MD-COPD-CT classification"** (append):
> Coronary artery disease and congestive heart failure were defined from self-reported physician diagnosis at enrolment. Participants with a missing value for a minor criterion were considered not to meet it.

(Confirm the CAD/CHF source variables `CoronaryArtery` and `CongestHeartFail` are self-report before using this wording.)

**Main Methods, "ESI and modified classifications"** (replace the CV sentences):
> For MD-NoCT the minimum number of symptom criteria for COPD-minor was searched over 1 to 3. For MD-COPD-ESI the ESI criterion was defined by a cut-point searched from 0.50 to 4.00 in steps of 0.25, jointly with a minimum of 2 to 4 of the four criteria. Each candidate rule was scored against MD-COPD-CT categories by macro-averaged F1 (the mean, across the four categories, of the harmonic mean of sensitivity and positive predictive value). Rules were also scored by Cohen's κ and mean per-category sensitivity in the full cohort for comparison (Table S2). Selection used no outcome data. Stability was assessed by five-fold cross-validation, stratified on MD-COPD-CT category and repeated five times (seed 20260901), with the rule refitted within each training fold and agreement measured in the held-out fold. Final rules were selected in the full cohort.

**Main Methods, "Clinical outcomes"** (append):
> Respiratory exacerbations were the total number reported in the Longitudinal Follow-up program, and baseline exacerbation frequency was the number reported for the year before enrolment. Survival time was measured from enrolment. Median follow-up was the median observed follow-up time for mortality and exacerbations, and the median time from enrolment to the last spirometry visit among participants with at least one follow-up visit for FEV₁ decline.

**Main Methods, "Statistical analysis"** (edits):
> - Para 1: "...summarized by its mean and 95% CI (paired t-test, n = 9,234 participants with both measurements)". This needs the code fix in H2 first.
> - Para 2: "McNemar's test without continuity correction".
> - Para 5: "...adjusted for height, sex, race, and baseline post-bronchodilator FEV₁ (entered as an interaction with time) and for age, current smoking and pack-years at each visit. P values used Satterthwaite degrees of freedom."
> - Para 6, after the reference groups: "Participants classified as COPD by MD-COPD-CT only (CT-only), by MD-COPD-ESI only (ESI-only), or by both (Both-COPD) were compared with the reference group of their stratum."

**Supplemental Methods, "Unadjusted outcome comparisons and bootstrap procedures"** (append):
> Bootstrap confidence intervals are percentile intervals. Two-sided bootstrap P values are twice the smaller of the proportions of resampled differences (on the log scale for ratios) at or below and at or above zero, and are reported as P < 0.005 when no more than two of 1,000 resamples fall on the far side of zero. Participants were resampled with replacement separately within the mortality and exacerbation analysis sets. Resamples in which a model failed to converge were discarded; at least 950 of 1,000 resamples were retained for every reported comparison. All resampling used a fixed seed (20260901). Because resampling draws participants by row position, intervals and P values reproduce exactly only on identically ordered input data and otherwise agree to Monte Carlo error.

**Supplemental Methods, new paragraph "Spirometric categories"**:
> PRISm was defined as post-bronchodilator FEV₁/FVC ≥ 0.70 with FEV₁ < 80% predicted, and GOLD 0 (preserved spirometry) as FEV₁/FVC ≥ 0.70 with FEV₁ ≥ 80% predicted. GOLD 1–4 followed the standard FEV₁ % predicted cut-points among participants with FEV₁/FVC < 0.70. Percent predicted values used the [Hankinson NHANES III] reference equations.

(Confirm the equations behind `FEV1pp_utah` and the `finalgold_visit` coding.)

**Supplemental "COPDGene files used"** (add):
> ESI values: [file name, version], computed by [group/software, version] from the stored flow-volume curves of each baseline pre- and post-bronchodilator manoeuvre.

**Manuscript end matter** (new):
> - *Data availability.* COPDGene data are available to qualified investigators through the COPDGene Study (www.copdgene.org) and dbGaP (phs000179).
> - *Code availability.* The analysis code, aggregate results tables and the claim registry are available at [changit URL], commit bf72167.
> - *Funding/acknowledgment.* Standard COPDGene acknowledgment (NHLBI U01 HL089897 and U01 HL089856; COPD Foundation).
> - *Ethics.* Approval and consent statement.

---

## 5. Snapshot sufficiency checklist

| Requirement | Status |
|---|---|
| Config template covers every input incl. `MDCOPD_PATH` | Yes in `config_paths.R.example`, but the header says "five"; required ESI-file columns are undocumented; the `OUT_DIR` comment is v15-only (H4) |
| Config validator covers this paper | **No** (H4) |
| Package list | Names only; no versions; figure and Python versions unrecorded (M1) |
| R version | 4.5.2 in `PROVENANCE.txt` and Methods; cluster repro on 4.5.1 |
| Seeds | `CV_SEED = 20260901` set before every resampling block and recorded in PROVENANCE; results depend on input row order (M5) |
| Caches | `assets/_cache/` is fingerprinted on formulas, n, B and label vectors, so a fresh run recomputes. OK |
| README render instructions | ctfree README: absolute laptop paths. Root README: wrong figure script names (H1). Neither says Figure 2 needs the participant-level `schema_labels.rds` from the same run |
| Build of .docx | Needs python-docx, PyMuPDF, LibreOffice (stated in root README); builders not run here |
| Data / code availability statement in manuscript | **Absent** (H3) |
