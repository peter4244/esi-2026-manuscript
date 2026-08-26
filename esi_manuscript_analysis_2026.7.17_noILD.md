---
title: "ESI multidimensional-COPD reformulation: analysis report accompanying the manuscript"
author: "Peter J. Castaldi"
date: "2026-07-17"
output:
  html_document:
    toc: true
    toc_depth: 3
    number_sections: true
    df_print: paged
    code_folding: show
---

<!--
Single reproducible analysis report that produces every result, table, and figure
cited in the manuscript "The Emphysema Severity Index: A Spirometric Representation
of CT-Defined Structural Abnormalities in a Multidimensional COPD Framework"
(Castaldi, Paoletti, Occhipinti, Sorano, Lavorini, Maiorino, Hersh, Silverman,
Pistolesi).

PORTABILITY.  To run on the Channing cluster, edit ONLY the "PATHS" chunk below to
point at the corresponding files in the cluster's COPDGene deidentified area, then
knit the document (or `Rscript -e 'rmarkdown::render(...)'`).  Everything else is
self-contained.
-->

# Overview

This report reproduces the numerical claims of the manuscript from four COPDGene
deidentified source files (ESI, phenotype/CT, vital status, cause of death) plus
one long-term follow-up exacerbations file.  Each section writes its output
(tables as CSV, figures as PNG) into `OUT_DIR`.  A closing self-check block
echoes every canonical value cited in the manuscript prose against the
expected number so drift can be detected on any re-run.

# PATHS — supplied at run time, never committed

Input locations are read from a site-local config file that is deliberately
kept out of version control, so no dataset path or filename appears anywhere in
this repository. Copy `config_paths.R.example` to `config_paths.R`, fill in the
five input locations for the machine you are running on, and knit. Nothing in
this document needs editing to move between machines.


``` r
# ----- Inputs -------------------------------------------------------------
# Set ESI_CONFIG to use a config file elsewhere, e.g.
#   Sys.setenv(ESI_CONFIG = "/path/to/config_paths.R")
CONFIG <- Sys.getenv("ESI_CONFIG", unset = "config_paths.R")
if (!file.exists(CONFIG)) {
  stop("Missing input-path config: '", CONFIG, "'.\n",
       "Copy config_paths.R.example to config_paths.R and fill in the five\n",
       "input locations (ESI_PATH, PHE_PATH, VS_PATH, COD_PATH, EX_PATH) and\n",
       "OUT_DIR. It is git-ignored by design so that no dataset path is\n",
       "committed.")
}
source(CONFIG, local = FALSE)

.required <- c("ESI_PATH", "PHE_PATH", "VS_PATH", "COD_PATH", "EX_PATH",
               "OUT_DIR", "ID_COL")
.missing  <- .required[!vapply(.required, exists, logical(1))]
if (length(.missing)) {
  stop("config '", CONFIG, "' does not define: ", paste(.missing, collapse = ", "))
}
.absent <- Filter(function(v) !file.exists(get(v)),
                  c("ESI_PATH", "PHE_PATH", "VS_PATH", "COD_PATH", "EX_PATH"))
if (length(.absent)) {
  stop("config '", CONFIG, "' points at files that do not exist: ",
       paste(.absent, collapse = ", "))
}
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

# ----- ESI thresholds (fixed by the manuscript's rpart analysis) -----------
ESI_T_LOW  <- 1.0
ESI_T_HIGH <- 2.5

# ----- Fixed seed for the 80/20 threshold-selection split ------------------
RPART_SEED <- 42
```

# Setup



# Data ingest


``` r
# The participant identifier column is named differently at different sites, so
# its name comes from the config (ID_COL) and is normalised here to an internal
# `pid`. Nothing downstream refers to the site-specific column name. A ".x"/".y"
# variant is accepted because some source files carry a merge-suffixed copy.
# Source files are not consistently comma-delimited: some sites supply
# tab-delimited .txt exports of the same tables. Sniff the header rather than
# assuming, so a tab-delimited file is not silently read as one wide column.
`%||%` <- function(a, b) if (is.null(a)) b else a

read_any <- function(path, ...) {
  hdr <- readLines(path, n = 1, warn = FALSE)
  sep <- if (grepl("\t", hdr)) "\t" else ","
  read.delim(path, sep = sep, stringsAsFactors = FALSE, ...)
}

bind_pid <- function(df, file_label) {
  cand <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit  <- cand[cand %in% names(df)]
  if (!length(hit)) {
    stop("No identifier column in ", file_label, ": looked for ",
         paste(cand, collapse = ", "),
         ". Set ID_COL in your config to the identifier used by your files.")
  }
  df$pid <- as.character(df[[hit[1]]])
  df
}

esi_raw <- bind_pid(read_any(ESI_PATH), "ESI_PATH")
phe_raw <- bind_pid(read_any(PHE_PATH, na.strings = c("", "NA")), "PHE_PATH")

# ---- Exclude the ILD/Bronchiectasis recruitment cohort ---------------------
# Added 2026-08-24 (noILD variant of the analysis).
#
# COPDGene's phenotype table carries three recruitment cohorts in `cohort`:
# "Smoker", "Never smoked" and "ILD/Brnch". The ILD/Bronchiectasis cohort is
# removed here, at the single point where the phenotype table is loaded, so the
# exclusion propagates to every downstream dataset: v1 -> d -> d_b -> mort_b and
# ex_b, and fev1_long for the decline models. Filtering anywhere later would
# leave one of those populations out of step.
#
# Two reasons. (1) ESI is computed from the expiratory flow-volume curve, and
# ILD produces restrictive physiology with a different curve morphology, so
# these subjects sit outside the intended target population for an ESI-based
# COPD classification. (2) Retaining them made the longitudinal analyses
# disagree on their population: the vital-status file covers only the SM and NS
# cohorts, so ILD/Brnch subjects were already absent from the mortality models
# (0 of 61 in the analytic cohort) while still present in the exacerbation (55)
# and FEV1-decline (61) models. Excluding them makes all four consistent.
is_ild  <- !is.na(phe_raw$cohort) & trimws(phe_raw$cohort) == "ILD/Brnch"
n_ild   <- length(unique(phe_raw$pid[is_ild]))
n_row0  <- nrow(phe_raw)
phe_raw <- phe_raw[!is_ild, ]
# The old guard here re-tested the filter that had just run and so could
# never fail. The failure that can actually happen is the label changing
# upstream ("ILD/Brnch" -> something else): is_ild would then be all FALSE,
# nothing would be excluded, and every downstream population would silently
# revert to the ILD-inclusive cohort. Assert the filter DID something, and
# that what remains is exactly the two cohorts we expect.
stopifnot(n_ild > 0)
.cohorts_left <- sort(unique(trimws(phe_raw$cohort[!is.na(phe_raw$cohort)])))
stopifnot(identical(.cohorts_left, sort(c("Smoker", "Never smoked"))))
cat(sprintf("Excluded ILD/Bronchiectasis cohort: %d subjects, %d rows removed (%d -> %d). Cohorts retained: %s\n",
            n_ild, n_row0 - nrow(phe_raw), n_row0, nrow(phe_raw),
            paste(sort(unique(trimws(phe_raw$cohort))), collapse = ", ")))
```

```
## Excluded ILD/Bronchiectasis cohort: 66 subjects, 126 rows removed (21920 -> 21794). Cohorts retained: Never smoked, Smoker
```

``` r
vs      <- bind_pid(read_any(VS_PATH),  "VS_PATH")
cod     <- bind_pid(read_any(COD_PATH), "COD_PATH")
ex_raw  <- bind_pid(read_any(EX_PATH),  "EX_PATH")

# ---- Cause of death: TORCH adjudicated UNDERLYING cause --------------------
# Changed 2026-08-18. Previously these analyses used the CCOD_* indicators,
# which flag whether a cause CONTRIBUTED to death and are therefore NOT
# mutually exclusive: 947 of 2,101 adjudicated deaths carried more than one
# CCOD flag (e.g. 358 were flagged both cardiovascular and respiratory). That
# breaks the competing-risks framing these models use, in which a death from
# any other cause is censored — a multi-flagged death was an event in several
# cause-specific models at once, and the cause-specific event counts did not
# partition total mortality.
#
# Torch_Group_Basic is the adjudicated underlying cause and IS mutually
# exclusive (counts sum exactly to the 2,101 adjudicated deaths):
#   1 Respiratory 704 | 2 Cardiovascular 391 | 3 Cancer 497
#   4 Other 385       | 5 Unknown 124
# Unknown (5) is an event for no cause, so those deaths are censored in every
# cause-specific model, exactly as any other competing death is.
ucd <- suppressWarnings(as.integer(cod$Torch_Group_Basic))
cod$UCD_Resp   <- as.integer(!is.na(ucd) & ucd == 1L)
cod$UCD_CVD    <- as.integer(!is.na(ucd) & ucd == 2L)
cod$UCD_Cancer <- as.integer(!is.na(ucd) & ucd == 3L)
cod$UCD_Other  <- as.integer(!is.na(ucd) & ucd == 4L)
# Exclusivity of the four indicators is guaranteed by construction (they are
# ucd == 1..4 off a single integer), so asserting it tests arithmetic, not
# data. What can actually go wrong is the source coding changing: an
# unexpected level would be silently swept into "no cause" by the ==
# comparisons above. Assert the source takes only the documented codes, and
# that the indicators account for every adjudicated row.
.ucd_levels <- sort(unique(ucd[!is.na(ucd)]))
stopifnot(all(.ucd_levels %in% 1:5))
stopifnot(sum(cod$UCD_Resp, cod$UCD_CVD, cod$UCD_Cancer, cod$UCD_Other) ==
          sum(!is.na(ucd) & ucd %in% 1:4))
cat(sprintf("TORCH underlying cause: resp=%d cvd=%d cancer=%d other=%d\n",
            sum(cod$UCD_Resp), sum(cod$UCD_CVD),
            sum(cod$UCD_Cancer), sum(cod$UCD_Other)))
```

```
## TORCH underlying cause: resp=704 cvd=391 cancer=497 other=385
```

``` r
# Baseline (Visit 1) post-bronchodilator ESI, one row per subject
esi_v1 <- esi_raw %>%
  filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

# Baseline (Visit 1) phenotype
v1 <- phe_raw %>% filter(visitnum == 1)
```

# Cohort construction (Bhatt analytic cohort)

The analytic cohort requires complete data on every major-and-minor criterion of
the Bhatt framework: post-bronchodilator FEV~1~/FVC, visual emphysema, visual
airway wall thickening, mMRC, SGRQ total, and chronic bronchitis.  Absolute-ESI
must also be available at Visit 1.


``` r
stratum_levels <- c("Never", "GOLD0", "PRISm", "GOLD1", "GOLD2", "GOLD3", "GOLD4")

d <- esi_v1 %>%
  inner_join(v1, by = "pid") %>%
  mutate(stratum = factor(case_when(
      finalgold_visit == -2 ~ "Never",
      finalgold_visit == -1 ~ "PRISm",
      finalgold_visit ==  0 ~ "GOLD0",
      finalgold_visit ==  1 ~ "GOLD1",
      finalgold_visit ==  2 ~ "GOLD2",
      finalgold_visit ==  3 ~ "GOLD3",
      finalgold_visit ==  4 ~ "GOLD4",
      TRUE                  ~ NA_character_
    ), levels = stratum_levels),
    gender     = factor(gender),
    race       = factor(race),
    SmokCigNow = factor(SmokCigNow),
    FF_per_0_1 = FEV1_FVC_post / 0.1
  )

d_b <- d %>%
  mutate(
    major_criterion = FEV1_FVC_post < 0.70,
    emph_yn = CT_Visual_Emph_Severity >= 1,
    wall_yn = CT_Visual_Wall_Thickening == 2,
    dysp_yn = MMRCDyspneaScor >= 2,
    qol_yn  = SGRQ_scoreTotal >= 25,
    cb_yn   = Chronic_Bronchitis == 1
  ) %>%
  filter(!is.na(major_criterion),
         !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn),
         !is.na(ESI_v1post))

# CT-based (Bhatt) classification
n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                 ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                 ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD", "noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major", "COPD-minor")

# ESI-based (reformulated) classification — 5-criterion, two-threshold rule
esi_score <- ifelse(d_b$ESI_v1post >= ESI_T_HIGH, 2,
             ifelse(d_b$ESI_v1post >= ESI_T_LOW,  1, 0))
n_minor_e <- esi_score + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
                ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
                ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD", "noCOPD")))
d_b$esi_copd <- d_b$esi_cls %in% c("COPD-major", "COPD-minor")

# Cross-classification cell
d_b$discord <- with(d_b, case_when(
  bhatt_copd  &  esi_copd ~ "Both-COPD",
  bhatt_copd  & !esi_copd ~ "CT-only-COPD",
  !bhatt_copd &  esi_copd ~ "ESI-only-COPD",
  TRUE                    ~ "Both-noCOPD"
))
d_b$discord <- factor(d_b$discord,
                      levels = c("Both-noCOPD", "Both-COPD", "CT-only-COPD", "ESI-only-COPD"))

# Ordered factor for the four diagnostic categories
ord <- c("noCOPD", "AFL-only-NoCOPD", "COPD-minor", "COPD-major")
d_b$bhatt_grp <- factor(d_b$bhatt_cls, levels = ord)
d_b$esi_grp   <- factor(d_b$esi_cls,   levels = ord)

cat(sprintf("Analytic cohort (complete Bhatt criteria + baseline ESI): n = %d\n", nrow(d_b)))
```

```
## Analytic cohort (complete Bhatt criteria + baseline ESI): n = 9402
```

# Section 1 — Cohort description


``` r
tab_by_stratum <- d_b %>%
  filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(n = n(),
            ESI_mean = mean(ESI_v1post, na.rm = TRUE),
            ESI_sd   = sd(ESI_v1post, na.rm = TRUE),
            .groups = "drop")
kable(tab_by_stratum, digits = 2,
      caption = "Cohort size and baseline ESI by GOLD/PRISm/never-smoker stratum.")
```



Table: Cohort size and baseline ESI by GOLD/PRISm/never-smoker stratum.

|stratum |    n| ESI_mean| ESI_sd|
|:-------|----:|--------:|------:|
|Never   |  106|     0.83|   0.22|
|GOLD0   | 4054|     0.90|   0.37|
|PRISm   | 1129|     0.91|   0.45|
|GOLD1   |  740|     1.44|   0.51|
|GOLD2   | 1789|     2.18|   1.20|
|GOLD3   | 1053|     4.84|   2.14|
|GOLD4   |  531|     8.30|   1.97|

``` r
write.csv(tab_by_stratum, file.path(OUT_DIR, "Table_S2_stratum_counts.csv"), row.names = FALSE)
```

## Section 1b — Supp Table S2: full baseline characteristics by stratum (A6b.1)

Baseline characteristics of the 9,402-subject Bhatt-analytic cohort, by
GOLD/PRISm/never-smoker stratum. Continuous → `mean (SD)`; dichotomous → `pct%`.
No across-stratum p-values (skipped per finding 9; would be uniformly
significant in a 9,402-subject cohort and would not inform the paper's claim).


``` r
fmt_msd <- function(x)  sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
fmt_msd0 <- function(x) sprintf("%.0f (%.0f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
fmt_pct <- function(x)  sprintf("%.0f%%", 100 * mean(x, na.rm = TRUE))

s2 <- d_b %>%
  filter(!is.na(stratum)) %>%
  mutate(
    female  = (as.numeric(as.character(gender)) == 2),
    curr_sm = (as.numeric(as.character(SmokCigNow)) == 1)
  ) %>%
  group_by(stratum) %>%
  summarise(
    n            = n(),
    age          = fmt_msd(age_visit),
    pct_female   = fmt_pct(female),
    pct_current  = fmt_pct(curr_sm),
    BMI          = fmt_msd(BMI),
    pack_years   = fmt_msd0(ATS_PackYears),
    FEV1_pp      = fmt_msd0(FEV1pp_post),
    FEV1_FVC     = sprintf("%.2f (%.2f)", mean(FEV1_FVC_post, na.rm = TRUE), sd(FEV1_FVC_post, na.rm = TRUE)),
    ESI          = sprintf("%.2f (%.2f)", mean(ESI_v1post, na.rm = TRUE), sd(ESI_v1post, na.rm = TRUE)),
    LAA950       = fmt_msd(Insp_LAA950_total_Thirona),
    pct_mMRC2p   = fmt_pct(dysp_yn),
    pct_SGRQ25p  = fmt_pct(qol_yn),
    pct_CB       = fmt_pct(cb_yn),
    .groups = "drop"
  )

# Add overall row
s2_overall <- d_b %>%
  mutate(
    female  = (as.numeric(as.character(gender)) == 2),
    curr_sm = (as.numeric(as.character(SmokCigNow)) == 1)
  ) %>%
  summarise(
    stratum = "Overall",
    n            = n(),
    age          = fmt_msd(age_visit),
    pct_female   = fmt_pct(female),
    pct_current  = fmt_pct(curr_sm),
    BMI          = fmt_msd(BMI),
    pack_years   = fmt_msd0(ATS_PackYears),
    FEV1_pp      = fmt_msd0(FEV1pp_post),
    FEV1_FVC     = sprintf("%.2f (%.2f)", mean(FEV1_FVC_post, na.rm = TRUE), sd(FEV1_FVC_post, na.rm = TRUE)),
    ESI          = sprintf("%.2f (%.2f)", mean(ESI_v1post, na.rm = TRUE), sd(ESI_v1post, na.rm = TRUE)),
    LAA950       = fmt_msd(Insp_LAA950_total_Thirona),
    pct_mMRC2p   = fmt_pct(dysp_yn),
    pct_SGRQ25p  = fmt_pct(qol_yn),
    pct_CB       = fmt_pct(cb_yn)
  )
s2_out <- bind_rows(s2 %>% mutate(stratum = as.character(stratum)), s2_overall)
write.csv(s2_out, file.path(OUT_DIR, "Table_S2_baseline_characteristics.csv"),
          row.names = FALSE)
kable(s2_out, caption = "Supp Table S2 — Baseline characteristics of the analytic cohort by stratum.")
```



Table: Supp Table S2 — Baseline characteristics of the analytic cohort by stratum.

|stratum |    n|age        |pct_female |pct_current |BMI        |pack_years |FEV1_pp  |FEV1_FVC    |ESI         |LAA950      |pct_mMRC2p |pct_SGRQ25p |pct_CB |
|:-------|----:|:----------|:----------|:-----------|:----------|:----------|:--------|:-----------|:-----------|:-----------|:----------|:-----------|:------|
|Never   |  106|62.0 (9.3) |68%        |0%          |28.3 (5.1) |0 (0)      |103 (14) |0.80 (0.05) |0.83 (0.22) |1.8 (2.6)   |4%         |4%          |0%     |
|GOLD0   | 4054|56.7 (8.3) |47%        |59%         |28.9 (5.8) |37 (20)    |97 (11)  |0.79 (0.05) |0.90 (0.37) |2.0 (2.7)   |23%        |26%         |13%    |
|PRISm   | 1129|57.2 (8.3) |54%        |63%         |31.7 (7.2) |42 (24)    |71 (8)   |0.77 (0.05) |0.91 (0.45) |1.5 (2.6)   |45%        |50%         |17%    |
|GOLD1   |  740|61.9 (9.0) |42%        |55%         |26.9 (4.8) |45 (24)    |91 (9)   |0.65 (0.04) |1.44 (0.51) |5.4 (5.9)   |21%        |28%         |15%    |
|GOLD2   | 1789|62.6 (8.9) |46%        |49%         |28.7 (6.1) |51 (27)    |65 (9)   |0.58 (0.08) |2.18 (1.20) |7.3 (8.0)   |50%        |58%         |27%    |
|GOLD3   | 1053|64.3 (8.3) |42%        |36%         |28.0 (6.3) |55 (27)    |40 (6)   |0.44 (0.09) |4.84 (2.14) |16.5 (12.7) |78%        |85%         |30%    |
|GOLD4   |  531|64.1 (7.6) |41%        |24%         |25.3 (5.6) |57 (29)    |23 (5)   |0.32 (0.07) |8.30 (1.97) |27.1 (14.0) |95%        |97%         |28%    |
|Overall | 9402|59.6 (9.0) |47%        |52%         |28.8 (6.2) |44 (25)    |77 (25)  |0.67 (0.16) |2.05 (2.23) |6.3 (9.8)   |41%        |46%         |19%    |

# Section 2 — ESI ↔ CT and ESI ↔ FEV~1~/FVC correlations (per stratum + overall)

Reproduces `Table_2.csv` (LAA-950 version) that anchors the manuscript's
per-stratum correlation claims (GOLD 0 r ≈ 0.08; GOLD 3 r ≈ 0.58; all-cohort
LAA-950 r = 0.77).


``` r
# Computed on d_b, the analytic cohort, so these share a denominator with every
# other table. Previously computed on `d` (the pre-filter ESI-merged cohort),
# which made the per-stratum Ns exceed their own ST4 stratum totals (GOLD 3:
# 1054 vs 1053) and the pooled row exceed both the cohort and the sum of its
# strata (9404 vs 9348), because the pooled row alone did not drop rows with a
# missing stratum. The pooled row now applies the same stratum filter as the
# per-stratum rows, so "All strata" equals their sum by construction.
t2 <- d_b %>%
  filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(
    n_FF  = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
    r_FF  = cor(ESI_v1post, FEV1_FVC_post, use = "pairwise.complete.obs"),
    n_LAA = sum(complete.cases(ESI_v1post, Insp_LAA950_total_Thirona)),
    r_LAA = cor(ESI_v1post, Insp_LAA950_total_Thirona, use = "pairwise.complete.obs"),
    .groups = "drop"
  )
t2_all <- d_b %>%
  filter(!is.na(stratum)) %>%
  summarise(stratum = "All strata",
            n_FF  = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
            r_FF  = cor(ESI_v1post, FEV1_FVC_post, use = "pairwise.complete.obs"),
            n_LAA = sum(complete.cases(ESI_v1post, Insp_LAA950_total_Thirona)),
            r_LAA = cor(ESI_v1post, Insp_LAA950_total_Thirona, use = "pairwise.complete.obs"))
t2_out <- bind_rows(t2 %>% mutate(stratum = as.character(stratum)), t2_all)
write.csv(t2_out, file.path(OUT_DIR, "Table_2.csv"), row.names = FALSE)

# PRM emphysema version for the supplement
t2_prm <- d_b %>%
  filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(
    n_FF  = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
    r_FF  = cor(ESI_v1post, FEV1_FVC_post, use = "pairwise.complete.obs"),
    n_PRM = sum(complete.cases(ESI_v1post, PRM_pct_emphysema_Thirona)),
    r_PRM = cor(ESI_v1post, PRM_pct_emphysema_Thirona, use = "pairwise.complete.obs"),
    .groups = "drop"
  )
t2_prm_all <- d_b %>%
  filter(!is.na(stratum)) %>%
  summarise(stratum = "All strata",
            n_FF  = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
            r_FF  = cor(ESI_v1post, FEV1_FVC_post, use = "pairwise.complete.obs"),
            n_PRM = sum(complete.cases(ESI_v1post, PRM_pct_emphysema_Thirona)),
            r_PRM = cor(ESI_v1post, PRM_pct_emphysema_Thirona, use = "pairwise.complete.obs"))
t2_prm_out <- bind_rows(t2_prm %>% mutate(stratum = as.character(stratum)), t2_prm_all)
write.csv(t2_prm_out, file.path(OUT_DIR, "Table_2_PRMversion.csv"), row.names = FALSE)

# Correlation among quantitative CT measures (Supp)
ct_cols <- c("Exp_LAA856_total_Thirona", "Insp_LAA950_total_Thirona",
             "PRM_pct_emphysema_Thirona", "PRM_pct_airtrapping_Thirona", "pctEmph_Thirona")
ct_cor <- cor(d_b[, ct_cols], use = "pairwise.complete.obs")  # d_b: shared denominator
write.csv(round(ct_cor, 3), file.path(OUT_DIR, "Supp_Table_CT_correlations.csv"))

kable(t2_out, digits = 3,
      caption = "Per-stratum Pearson correlations between ESI and FEV1/FVC, and between ESI and %LAA-950HU.")
```



Table: Per-stratum Pearson correlations between ESI and FEV1/FVC, and between ESI and %LAA-950HU.

|stratum    | n_FF|   r_FF| n_LAA| r_LAA|
|:----------|----:|------:|-----:|-----:|
|Never      |  106| -0.397|   105| 0.288|
|GOLD0      | 4054| -0.268|  4030| 0.080|
|PRISm      | 1129| -0.265|  1118| 0.049|
|GOLD1      |  740| -0.607|   734| 0.243|
|GOLD2      | 1789| -0.875|  1771| 0.510|
|GOLD3      | 1053| -0.917|  1050| 0.577|
|GOLD4      |  531| -0.847|   527| 0.439|
|All strata | 9402| -0.889|  9335| 0.779|

# Section 3 — ESI threshold selection (rpart 80/20 + candidate grid)

Reproduces `Supp_Table_Thresholds.csv`.  The single-variable classification-tree
step identifies the low threshold ≈ 1.0; the grid then evaluates ten candidate
2-threshold configurations for agreement, sensitivity, specificity, and κ, and
the selected configuration is (`T_low = 1.0`, `T_high = 2.5`).


``` r
set.seed(RPART_SEED)

# The rpart training/testing split — reported in Methods
d_rp <- d_b %>%
  mutate(struct_score = as.integer(emph_yn) + as.integer(wall_yn)) %>%
  mutate(struct_f = factor(struct_score, levels = 0:2))

n <- nrow(d_rp)
train_idx <- sample(seq_len(n), size = round(0.8 * n))
train <- d_rp[train_idx, ]
test  <- d_rp[-train_idx, ]

# Equal-priors keeps the tree from ignoring class 2 (visual emph + wall)
fit <- rpart(struct_f ~ ESI_v1post,
             data    = train,
             method  = "class",
             parms   = list(prior = c(1/3, 1/3, 1/3)),
             control = rpart.control(maxdepth = 3, minbucket = 200, cp = 0.001))
rpart_cutoffs <- sort(unique(round(fit$splits[, "index"], 3)))
cat(sprintf("rpart-derived cut-points (80%% train): %s\n",
            paste(rpart_cutoffs, collapse = ", ")))
```

```
## rpart-derived cut-points (80% train): 1.065, 1.675
```

``` r
cat(sprintf("Manuscript-selected thresholds: T_low = %.1f, T_high = %.1f\n",
            ESI_T_LOW, ESI_T_HIGH))
```

```
## Manuscript-selected thresholds: T_low = 1.0, T_high = 2.5
```

``` r
# Ten-candidate transparency grid (as in build_revisions_v2)
classify_4crit <- function(df, T, min_count) {
  esi <- df$ESI_v1post >= T
  n_min <- esi + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_min >= 1, "COPD-major",
   ifelse(!df$major_criterion & n_min >= min_count, "COPD-minor",
   ifelse(df$major_criterion & n_min == 0, "AFL-only-NoCOPD", "noCOPD")))
}
classify_5crit <- function(df, T_low, T_high) {
  esi_s <- ifelse(df$ESI_v1post >= T_high, 2, ifelse(df$ESI_v1post >= T_low, 1, 0))
  n_min <- esi_s + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_min >= 1, "COPD-major",
   ifelse(!df$major_criterion & n_min >= 3, "COPD-minor",
   ifelse(df$major_criterion & n_min == 0, "AFL-only-NoCOPD", "noCOPD")))
}
candidates <- list(
  list(type = "4-crit, ESI cutoff 1.0, threshold >=2-of-4", fn = function(x) classify_4crit(x, 1.0, 2)),
  list(type = "4-crit, ESI cutoff 1.5, threshold >=2-of-4", fn = function(x) classify_4crit(x, 1.5, 2)),
  list(type = "4-crit, ESI cutoff 2.0, threshold >=2-of-4", fn = function(x) classify_4crit(x, 2.0, 2)),
  list(type = "4-crit, ESI cutoff 2.5, threshold >=2-of-4", fn = function(x) classify_4crit(x, 2.5, 2)),
  list(type = "4-crit, ESI cutoff 1.5, threshold >=3-of-4", fn = function(x) classify_4crit(x, 1.5, 3)),
  list(type = "4-crit, ESI cutoff 2.0, threshold >=3-of-4", fn = function(x) classify_4crit(x, 2.0, 3)),
  list(type = "5-crit, T_low=0.5 / T_high=2.0",             fn = function(x) classify_5crit(x, 0.5, 2.0)),
  list(type = "5-crit, T_low=1.0 / T_high=2.5 [SELECTED]",  fn = function(x) classify_5crit(x, 1.0, 2.5)),
  list(type = "5-crit, T_low=1.5 / T_high=3.0",             fn = function(x) classify_5crit(x, 1.5, 3.0)),
  list(type = "5-crit, T_low=2.0 / T_high=3.5",             fn = function(x) classify_5crit(x, 2.0, 3.5))
)
# Evaluate every candidate on BOTH the full analytic cohort and the held-out
# 20% split. Added 2026-08-24: previously only the full-cohort figures were
# reported, but the cut-points were derived from the 80% training split, so
# those figures are in-sample with respect to threshold selection. The test
# split had been created and then never used. The held-out columns are the
# defensible estimate; reporting both lets a reader see how far the in-sample
# figures are optimistic.
metrics <- function(dat, cls_fn) {
  cls  <- cls_fn(dat); copd <- cls %in% c("COPD-major", "COPD-minor")
  tp <- sum( dat$bhatt_copd &  copd); fp <- sum(!dat$bhatt_copd &  copd)
  fn <- sum( dat$bhatt_copd & !copd); tn <- sum(!dat$bhatt_copd & !copd)
  list(n_COPD = sum(copd),
       sens = tp / (tp + fn), spec = tn / (tn + fp),
       kappa = kappa_fn(dat$bhatt_copd, copd))
}
# train_idx is sampled without replacement, so d_rp[train_idx, ] and
# d_rp[-train_idx, ] are disjoint by construction; assert that rather than
# comparing rownames, which dplyr resets to 1..n on both halves.
# Disjointness and the row count are guaranteed by the indexing itself, so
# asserting them tests base R. Assert the split FRACTION instead, which is a
# property of the sample() call and would move if the 0.8 were edited.
stopifnot(abs(nrow(test) / nrow(d_rp) - 0.2) < 0.01)

sens_rows <- lapply(candidates, function(c) {
  f <- metrics(d_b,  c$fn)
  h <- metrics(test, c$fn)
  data.frame(variant     = c$type,
             n_COPD      = f$n_COPD, sens      = f$sens,
             spec        = f$spec,   kappa     = f$kappa,
             test_n_COPD = h$n_COPD, test_sens = h$sens,
             test_spec   = h$spec,   test_kappa = h$kappa)
})
supp_thresh <- do.call(rbind, sens_rows)
write.csv(supp_thresh, file.path(OUT_DIR, "Supp_Table_Thresholds.csv"), row.names = FALSE)

cat(sprintf("Threshold grid: full analytic cohort n = %d; held-out test split n = %d (%.1f%%)\n",
            nrow(d_b), nrow(test), 100 * nrow(test) / nrow(d_rp)))
```

```
## Threshold grid: full analytic cohort n = 9402; held-out test split n = 1880 (20.0%)
```

``` r
sel <- supp_thresh[grepl("SELECTED", supp_thresh$variant), ]
cat(sprintf("Selected variant  full: sens %.3f spec %.3f kappa %.3f | held-out: sens %.3f spec %.3f kappa %.3f\n",
            sel$sens, sel$spec, sel$kappa, sel$test_sens, sel$test_spec, sel$test_kappa))
```

```
## Selected variant  full: sens 0.880 spec 0.944 kappa 0.821 | held-out: sens 0.883 spec 0.943 kappa 0.821
```

``` r
kable(supp_thresh, digits = 3,
      caption = paste("Threshold-selection grid: 10 candidate ESI-scoring configurations,",
                      "evaluated on the full analytic cohort and on the held-out 20% split."))
```



Table: Threshold-selection grid: 10 candidate ESI-scoring configurations, evaluated on the full analytic cohort and on the held-out 20% split.

|variant                                    | n_COPD|  sens|  spec| kappa| test_n_COPD| test_sens| test_spec| test_kappa|
|:------------------------------------------|------:|-----:|-----:|-----:|-----------:|---------:|---------:|----------:|
|4-crit, ESI cutoff 1.0, threshold >=2-of-4 |   5572| 0.974| 0.846| 0.827|        1119|     0.975|     0.855|      0.837|
|4-crit, ESI cutoff 1.5, threshold >=2-of-4 |   4912| 0.892| 0.902| 0.793|         991|     0.897|     0.912|      0.807|
|4-crit, ESI cutoff 2.0, threshold >=2-of-4 |   4624| 0.847| 0.917| 0.759|         939|     0.851|     0.917|      0.763|
|4-crit, ESI cutoff 2.5, threshold >=2-of-4 |   4521| 0.829| 0.920| 0.743|         908|     0.825|     0.922|      0.739|
|4-crit, ESI cutoff 1.5, threshold >=3-of-4 |   3954| 0.774| 0.985| 0.747|         802|     0.781|     0.994|      0.760|
|4-crit, ESI cutoff 2.0, threshold >=3-of-4 |   3669| 0.726| 0.995| 0.707|         750|     0.733|     0.998|      0.713|
|5-crit, T_low=0.5 / T_high=2.0             |   5408| 0.975| 0.884| 0.863|        1094|     0.979|     0.890|      0.875|
|5-crit, T_low=1.0 / T_high=2.5 [SELECTED]  |   4671| 0.880| 0.944| 0.821|         950|     0.883|     0.943|      0.821|
|5-crit, T_low=1.5 / T_high=3.0             |   3957| 0.774| 0.985| 0.746|         803|     0.781|     0.993|      0.759|
|5-crit, T_low=2.0 / T_high=3.5             |   3671| 0.726| 0.995| 0.706|         751|     0.733|     0.997|      0.712|

# Section 4 — Classifications, cross-tabulation, agreement metrics

Reproduces `Table_6.csv` (4×4 cross-tab), the headline agreement metrics
(91 %, κ = 0.82, sensitivity 88 %, specificity 94 %) and the
Figure 1 stacked-bar visualization.


``` r
# 4x4 cross-tab
t6 <- as.data.frame.matrix(table(d_b$bhatt_grp, d_b$esi_grp))
t6_wide <- data.frame(
  Bhatt = ifelse(rownames(t6) == "noCOPD", "noCOPD", rownames(t6)),
  noCOPD          = t6[, "noCOPD"],
  AFL_only_NoCOPD = t6[, "AFL-only-NoCOPD"],
  COPD_minor      = t6[, "COPD-minor"],
  COPD_major      = t6[, "COPD-major"]
)
write.csv(t6_wide, file.path(OUT_DIR, "Table_6.csv"), row.names = FALSE)
kable(t6_wide, caption = "Cross-tabulation: rows = original CT-based framework; columns = ESI-based framework.")
```



Table: Cross-tabulation: rows = original CT-based framework; columns = ESI-based framework.

|Bhatt           | noCOPD| AFL_only_NoCOPD| COPD_minor| COPD_major|
|:---------------|------:|---------------:|----------:|----------:|
|noCOPD          |   4109|               0|         94|          0|
|AFL-only-NoCOPD |      0|              21|          0|        149|
|COPD-minor      |    538|               0|        548|          0|
|COPD-major      |      0|              63|          0|       3880|

``` r
# Agreement metrics on binary COPD-vs-noCOPD
tp <- sum( d_b$bhatt_copd &  d_b$esi_copd); fp <- sum(!d_b$bhatt_copd &  d_b$esi_copd)
fn <- sum( d_b$bhatt_copd & !d_b$esi_copd); tn <- sum(!d_b$bhatt_copd & !d_b$esi_copd)
overall_agreement <- (tp + tn) / (tp + fp + fn + tn)
sensitivity_v     <- tp / (tp + fn)
specificity_v     <- tn / (tn + fp)
kappa_v           <- kappa_fn(d_b$bhatt_copd, d_b$esi_copd)

agree_kv <- c(sprintf("agreement=%.4f", overall_agreement),
              sprintf("kappa=%.4f",     kappa_v),
              sprintf("sensitivity=%.4f", sensitivity_v),
              sprintf("specificity=%.4f", specificity_v),
              sprintf("n_cohort=%d", nrow(d_b)))
writeLines(agree_kv, file.path(OUT_DIR, "Table_Agreement_stats.txt"))

cat(sprintf("Agreement %.1f%% | kappa %.2f | sens %.0f%% | spec %.0f%%\n",
            100 * overall_agreement, kappa_v, 100 * sensitivity_v, 100 * specificity_v))
```

```
## Agreement 91.0% | kappa 0.82 | sens 88% | spec 94%
```

``` r
# Figure 1 — stacked bars, both frameworks side-by-side (mirrors v3/v8 Figure 1)
flow_long <- bind_rows(
  d_b %>% transmute(schema = "CT-based framework",  cls = bhatt_grp),
  d_b %>% transmute(schema = "ESI-based framework", cls = esi_grp)
) %>% mutate(schema = factor(schema, levels = c("CT-based framework", "ESI-based framework")))

fig_bars <- ggplot(flow_long, aes(x = schema, fill = cls)) +
  geom_bar(position = position_fill(reverse = TRUE), width = 0.55, color = "white") +
  geom_text(stat = "count",
            aes(label = sprintf("%.1f%%", 100 * after_stat(count) / tapply(after_stat(count), after_stat(x), sum)[after_stat(x)])),
            position = position_fill(vjust = 0.5, reverse = TRUE),
            size = 3, color = "white") +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_manual(values = c(
    "noCOPD"          = "#7F7F7F",
    "AFL-only-NoCOPD" = "#9467BD",
    "COPD-minor"      = "#FFB000",
    "COPD-major"      = "#D62728"
  ), name = "Classification") +
  labs(x = NULL, y = "Participants (%)",
       title = "Reconstruction of the multidimensional COPD framework using ESI",
       subtitle = sprintf("Agreement %.0f%%   kappa=%.2f   Sensitivity %.0f%%   Specificity %.0f%%",
                          100 * overall_agreement, kappa_v,
                          100 * sensitivity_v, 100 * specificity_v)) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "bottom")
ggsave(file.path(OUT_DIR, "Figure_Bhatt_StackedBars.png"),
       fig_bars, width = 8, height = 5.5, dpi = 300)
```

# Section 5 — Discordance descriptive (Table 3 + Figure 2)

Preserved-spirometry cross-classification descriptive characteristics driving
Figure 2 (heatmap) and the discordance narrative in the Discussion.


``` r
preserved <- d_b %>% filter(!major_criterion)

disc_summary <- preserved %>%
  filter(discord != "Both-noCOPD") %>%
  mutate(grp_5 = case_when(
    discord == "CT-only-COPD" ~ "CT-only-COPD (ESI missed)",
    discord == "ESI-only-COPD"   ~ "ESI-only-COPD (Bhatt missed)",
    TRUE                         ~ as.character(discord)
  )) %>%
  group_by(grp_5) %>%
  summarise(
    n           = n(),
    age         = sprintf("%.1f (%.1f)", mean(age_visit, na.rm = TRUE), sd(age_visit, na.rm = TRUE)),
    pct_F       = sprintf("%.0f%%", 100 * mean(gender == 2, na.rm = TRUE)),
    BMI         = sprintf("%.1f (%.1f)", mean(BMI, na.rm = TRUE), sd(BMI, na.rm = TRUE)),
    pack_yr     = sprintf("%.0f (%.0f)", mean(ATS_PackYears, na.rm = TRUE), sd(ATS_PackYears, na.rm = TRUE)),
    ESI         = sprintf("%.2f (%.2f)", mean(ESI_v1post, na.rm = TRUE), sd(ESI_v1post, na.rm = TRUE)),
    FEV1_pp     = sprintf("%.0f (%.0f)", mean(FEV1pp_post, na.rm = TRUE), sd(FEV1pp_post, na.rm = TRUE)),
    FEV1_FVC    = sprintf("%.2f (%.2f)", mean(FEV1_FVC_post, na.rm = TRUE), sd(FEV1_FVC_post, na.rm = TRUE)),
    LAA950      = sprintf("%.1f (%.1f)", mean(Insp_LAA950_total_Thirona, na.rm = TRUE),
                                          sd(Insp_LAA950_total_Thirona, na.rm = TRUE)),
    pct_emph    = sprintf("%.0f%%", 100 * mean(emph_yn, na.rm = TRUE)),
    pct_wall    = sprintf("%.0f%%", 100 * mean(wall_yn, na.rm = TRUE)),
    pct_mMRC2p  = sprintf("%.0f%%", 100 * mean(dysp_yn, na.rm = TRUE)),
    pct_SGRQ25p = sprintf("%.0f%%", 100 * mean(qol_yn, na.rm = TRUE)),
    pct_CB      = sprintf("%.0f%%", 100 * mean(cb_yn, na.rm = TRUE)),
    .groups = "drop"
  )
write.csv(disc_summary, file.path(OUT_DIR, "Table_Discordance.csv"), row.names = FALSE)
kable(disc_summary, caption = "Baseline descriptors of the three discordant preserved-spirometry subgroups.")
```



Table: Baseline descriptors of the three discordant preserved-spirometry subgroups.

|grp_5                        |   n|age        |pct_F |BMI        |pack_yr |ESI         |FEV1_pp |FEV1_FVC    |LAA950    |pct_emph |pct_wall |pct_mMRC2p |pct_SGRQ25p |pct_CB |
|:----------------------------|---:|:----------|:-----|:----------|:-------|:-----------|:-------|:-----------|:---------|:--------|:--------|:----------|:-----------|:------|
|Both-COPD                    | 548|54.1 (6.8) |53%   |31.1 (7.1) |46 (26) |1.06 (0.47) |85 (17) |0.77 (0.05) |1.7 (3.0) |65%      |39%      |93%        |99%         |72%    |
|CT-only-COPD (ESI missed)    | 538|56.2 (8.0) |55%   |30.6 (7.1) |44 (22) |0.80 (0.19) |85 (16) |0.78 (0.05) |1.4 (2.2) |91%      |49%      |74%        |88%         |16%    |
|ESI-only-COPD (Bhatt missed) |  94|55.1 (8.1) |60%   |32.3 (7.3) |38 (18) |1.46 (1.16) |89 (17) |0.78 (0.05) |1.7 (2.4) |0%       |0%       |86%        |95%         |15%    |

## Section 5b — Discordance pairwise tests (Figure 2 significance annotations)

All three pairwise contrasts (CT-only vs Both, Both vs ESI-only, CT-only
vs ESI-only) across the seven Figure-2 descriptors. Wilcoxon rank-sum for the
continuous descriptors (ESI, %LAA-950HU); chi-square (2×2) for the binary
descriptors (visual emph %, visual wall %, mMRC≥2 %, SGRQ≥25 %, chronic
bronchitis %). Reported unadjusted — the intent is descriptive annotation of
Figure 2, not a formal multiple-testing framework.


``` r
disc_dat <- preserved %>%
  filter(discord != "Both-noCOPD") %>%
  mutate(group = case_when(
    discord == "CT-only-COPD" ~ "CT-only",
    discord == "Both-COPD"       ~ "Both",
    discord == "ESI-only-COPD"   ~ "ESI-only"),
    ESI    = ESI_v1post,
    LAA950 = Insp_LAA950_total_Thirona,
    emph   = as.integer(emph_yn), wall = as.integer(wall_yn),
    mMRC2p = as.integer(dysp_yn), SGRQ25p = as.integer(qol_yn),
    CB     = as.integer(cb_yn)) %>%
  dplyr::select(group, ESI, LAA950, emph, wall, mMRC2p, SGRQ25p, CB)

pairs <- list(c("CT-only","Both"), c("Both","ESI-only"),
              c("CT-only","ESI-only"))
cont_vars <- c("ESI","LAA950")
bin_vars  <- c("emph","wall","mMRC2p","SGRQ25p","CB")

pw_rows <- list()
sig_stars <- function(p) {
  if (is.na(p))       return("")
  if (p < 0.001)      return("***")
  if (p < 0.01)       return("**")
  if (p < 0.05)       return("*")
  return("ns")
}
for (v in cont_vars) {
  for (pair in pairs) {
    x <- disc_dat[[v]][disc_dat$group == pair[1]]
    y <- disc_dat[[v]][disc_dat$group == pair[2]]
    x <- x[!is.na(x)]; y <- y[!is.na(y)]
    w <- suppressWarnings(wilcox.test(x, y))
    pw_rows[[length(pw_rows)+1]] <- data.frame(
      descriptor = v, group1 = pair[1], group2 = pair[2],
      n1 = length(x), n2 = length(y),
      test = "Wilcoxon rank-sum",
      statistic = unname(w$statistic), p_value = w$p.value,
      sig = sig_stars(w$p.value), stringsAsFactors = FALSE)
  }
}
for (v in bin_vars) {
  for (pair in pairs) {
    a <- disc_dat[[v]][disc_dat$group == pair[1]]
    b <- disc_dat[[v]][disc_dat$group == pair[2]]
    a <- a[!is.na(a)]; b <- b[!is.na(b)]
    tbl <- rbind(table(factor(a, levels = c(0,1))),
                 table(factor(b, levels = c(0,1))))
    ch <- suppressWarnings(chisq.test(tbl, correct = FALSE))
    pw_rows[[length(pw_rows)+1]] <- data.frame(
      descriptor = v, group1 = pair[1], group2 = pair[2],
      n1 = sum(!is.na(a)), n2 = sum(!is.na(b)),
      test = "Chi-square (2x2)",
      statistic = unname(ch$statistic), p_value = ch$p.value,
      sig = sig_stars(ch$p.value), stringsAsFactors = FALSE)
  }
}
disc_pw <- do.call(rbind, pw_rows)
write.csv(disc_pw, file.path(OUT_DIR, "Table_Discordance_pairwise.csv"),
          row.names = FALSE)
kable(disc_pw %>% mutate(across(c(statistic, p_value), ~ signif(.x, 3))),
      caption = "Figure 2 pairwise tests: Wilcoxon (continuous) + chi-square (binary), unadjusted.")
```



Table: Figure 2 pairwise tests: Wilcoxon (continuous) + chi-square (binary), unadjusted.

|descriptor |group1  |group2   |  n1|  n2|test              | statistic|  p_value|sig |
|:----------|:-------|:--------|---:|---:|:-----------------|---------:|--------:|:---|
|ESI        |CT-only |Both     | 538| 548|Wilcoxon rank-sum |  8.05e+04| 0.000000|*** |
|ESI        |Both    |ESI-only | 548|  94|Wilcoxon rank-sum |  1.53e+04| 0.000000|*** |
|ESI        |CT-only |ESI-only | 538|  94|Wilcoxon rank-sum |  2.50e+03| 0.000000|*** |
|LAA950     |CT-only |Both     | 537| 546|Wilcoxon rank-sum |  1.38e+05| 0.104000|ns  |
|LAA950     |Both    |ESI-only | 546|  94|Wilcoxon rank-sum |  2.46e+04| 0.531000|ns  |
|LAA950     |CT-only |ESI-only | 537|  94|Wilcoxon rank-sum |  2.27e+04| 0.125000|ns  |
|emph       |CT-only |Both     | 538| 548|Chi-square (2x2)  |  1.06e+02| 0.000000|*** |
|emph       |Both    |ESI-only | 548|  94|Chi-square (2x2)  |  1.38e+02| 0.000000|*** |
|emph       |CT-only |ESI-only | 538|  94|Chi-square (2x2)  |  3.81e+02| 0.000000|*** |
|wall       |CT-only |Both     | 538| 548|Chi-square (2x2)  |  1.19e+01| 0.000566|*** |
|wall       |Both    |ESI-only | 548|  94|Chi-square (2x2)  |  5.51e+01| 0.000000|*** |
|wall       |CT-only |ESI-only | 538|  94|Chi-square (2x2)  |  8.03e+01| 0.000000|*** |
|mMRC2p     |CT-only |Both     | 538| 548|Chi-square (2x2)  |  7.16e+01| 0.000000|*** |
|mMRC2p     |Both    |ESI-only | 548|  94|Chi-square (2x2)  |  4.86e+00| 0.027500|*   |
|mMRC2p     |CT-only |ESI-only | 538|  94|Chi-square (2x2)  |  6.65e+00| 0.009900|**  |
|SGRQ25p    |CT-only |Both     | 538| 548|Chi-square (2x2)  |  5.39e+01| 0.000000|*** |
|SGRQ25p    |Both    |ESI-only | 548|  94|Chi-square (2x2)  |  1.02e+01| 0.001430|**  |
|SGRQ25p    |CT-only |ESI-only | 538|  94|Chi-square (2x2)  |  3.40e+00| 0.065000|ns  |
|CB         |CT-only |Both     | 538| 548|Chi-square (2x2)  |  3.38e+02| 0.000000|*** |
|CB         |Both    |ESI-only | 548|  94|Chi-square (2x2)  |  1.11e+02| 0.000000|*** |
|CB         |CT-only |ESI-only | 538|  94|Chi-square (2x2)  |  9.72e-02| 0.755000|ns  |

# Section 6 — Prognostic performance by category (Table 1 head-to-head + C-indices)

Head-to-head Cox all-cause mortality, Cox respiratory-cause mortality, and
negative-binomial exacerbations by diagnostic category, both frameworks.
Reproduces `Table_8_allcause.csv`, `Table_8_resp.csv`, `Table_8_stats.txt`,
`Table_Exacerbations_Bhatt.csv`, `Table_Exacerbations_Bhatt_stats.txt`, and
`Table_BhattDecline.csv`.


``` r
mort_b <- d_b %>%
  inner_join(vs %>% select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% select(pid, UCD_Resp), by = "pid") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

cox_bhatt_all  <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_esi_all    <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_bhatt_resp <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_esi_resp   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)

groups3 <- c("AFL-only-NoCOPD", "COPD-minor", "COPD-major")
build_t8 <- function(cox_b, cox_e) {
  do.call(rbind, lapply(groups3, function(g) {
    bh <- cox_row(cox_b, paste0("bhatt_grp", g))
    eh <- cox_row(cox_e, paste0("esi_grp",   g))
    data.frame(group = g,
               bhatt_HR = bh["HR"], bhatt_LCI = bh["LCI"], bhatt_UCI = bh["UCI"], bhatt_p = bh["p"],
               esi_HR   = eh["HR"], esi_LCI   = eh["LCI"], esi_UCI   = eh["UCI"], esi_p   = eh["p"])
  }))
}
t8_all  <- build_t8(cox_bhatt_all,  cox_esi_all);   write.csv(t8_all,  file.path(OUT_DIR, "Table_8_allcause.csv"), row.names = FALSE)
t8_resp <- build_t8(cox_bhatt_resp, cox_esi_resp);  write.csv(t8_resp, file.path(OUT_DIR, "Table_8_resp.csv"),     row.names = FALSE)

writeLines(c(sprintf("bhatt_cindex_all=%.3f",  concordance(cox_bhatt_all)$concordance),
             sprintf("esi_cindex_all=%.3f",    concordance(cox_esi_all)$concordance),
             sprintf("bhatt_cindex_resp=%.3f", concordance(cox_bhatt_resp)$concordance),
             sprintf("esi_cindex_resp=%.3f",   concordance(cox_esi_resp)$concordance),
             sprintf("n_cohort=%d",            nrow(mort_b)),
             sprintf("n_deaths_all=%d",        sum(mort_b$vital_status == 1)),
             sprintf("n_deaths_resp=%d",       sum(mort_b$event_resp == 1))),
           file.path(OUT_DIR, "Table_8_stats.txt"))

kable(bind_rows(
  cbind(outcome = "All-cause",   t8_all),
  cbind(outcome = "Respiratory", t8_resp)
), digits = 2, caption = "Table 1 (source data): head-to-head HRs by diagnostic category.")
```



Table: Table 1 (source data): head-to-head HRs by diagnostic category.

|        |outcome     |group           | bhatt_HR| bhatt_LCI| bhatt_UCI| bhatt_p| esi_HR| esi_LCI| esi_UCI| esi_p|
|:-------|:-----------|:---------------|--------:|---------:|---------:|-------:|------:|-------:|-------:|-----:|
|HR...1  |All-cause   |AFL-only-NoCOPD |     0.90|      0.62|      1.30|    0.56|   0.91|    0.57|    1.46|  0.70|
|HR1...2 |All-cause   |COPD-minor      |     1.91|      1.64|      2.22|    0.00|   1.94|    1.63|    2.32|  0.00|
|HR2...3 |All-cause   |COPD-major      |     2.59|      2.35|      2.86|    0.00|   2.39|    2.18|    2.63|  0.00|
|HR...4  |Respiratory |AFL-only-NoCOPD |     1.42|      0.19|     10.84|    0.74|   2.19|    0.29|   16.54|  0.45|
|HR1...5 |Respiratory |COPD-minor      |     4.80|      2.14|     10.76|    0.00|   5.68|    2.43|   13.32|  0.00|
|HR2...6 |Respiratory |COPD-major      |    36.27|     20.85|     63.07|    0.00|  30.95|   18.76|   51.06|  0.00|

## Section 6b — Table 1 formal test: paired C-index equivalence (item 3)

Primary CT-vs-ESI agreement test — pre-specified paired equivalence at ±0.02 on
the Harrell's C scale, tested via two one-sided tests (TOST) at α = 0.025
per side.  Uses `survival::concordance(fit_bhatt, fit_esi, ...)` when available
(returns joint estimate + paired covariance); falls back to a paired
subject-resample bootstrap of Harrell's C (never Uno's C — statistic must not
switch between primary and fallback).


``` r
CINDEX_MARGIN <- 0.02

# Primary path (requires survival >= 3.0 multi-fit dispatch)
cindex_equiv <- function(fit_ct, fit_esi, outcome_label) {
  cj <- try(concordance(fit_ct, fit_esi), silent = TRUE)
  if (inherits(cj, "try-error") || is.null(cj$var) || nrow(cj$var) < 2) {
    return(NULL)
  }
  c_ct  <- unname(cj$concordance[1])
  c_esi <- unname(cj$concordance[2])
  V     <- cj$var
  delta <- c_ct - c_esi
  se    <- sqrt(V[1, 1] + V[2, 2] - 2 * V[1, 2])
  ci_lo <- delta - 1.96 * se
  ci_hi <- delta + 1.96 * se
  # TOST: two one-sided z-tests
  z_low  <- (delta - (-CINDEX_MARGIN)) / se   # H0: delta <= -margin
  z_high <- ((+CINDEX_MARGIN) - delta) / se   # H0: delta >= +margin
  # 1 - pnorm(z) loses all precision for z >~ 8 and returns a literal 0.
  # Here z is ~10-15, so the upper tail must be asked for directly.
  p_low  <- pnorm(z_low,  lower.tail = FALSE)
  p_high <- pnorm(z_high, lower.tail = FALSE)
  data.frame(
    outcome   = outcome_label,
    c_ct      = c_ct,
    c_esi     = c_esi,
    delta_c   = delta,
    se_delta  = se,
    ci_lo     = ci_lo,
    ci_hi     = ci_hi,
    tost_p_low  = p_low,
    tost_p_high = p_high,
    equivalent_within_margin = (ci_lo > -CINDEX_MARGIN) && (ci_hi < CINDEX_MARGIN),
    method    = "paired_concordance",
    stringsAsFactors = FALSE
  )
}

# Fallback: Harrell's-C paired subject-resample bootstrap (finding 2 — no statistic switch)
cindex_equiv_bootstrap <- function(surv_time, surv_event, lp_ct, lp_esi, outcome_label,
                                   B = 1000, seed = BOOTSTRAP_SEED) {
  set.seed(seed)
  n <- length(surv_time)
  boot_delta <- numeric(B)
  for (b in seq_len(B)) {
    idx <- sample.int(n, size = n, replace = TRUE)
    S_b <- Surv(surv_time[idx], surv_event[idx])
    c_ct_b  <- concordance(S_b ~ lp_ct[idx],  reverse = TRUE)$concordance
    c_esi_b <- concordance(S_b ~ lp_esi[idx], reverse = TRUE)$concordance
    boot_delta[b] <- c_ct_b - c_esi_b
  }
  delta <- mean(boot_delta)
  se    <- sd(boot_delta)
  ci    <- quantile(boot_delta, c(0.025, 0.975), names = FALSE)
  data.frame(
    outcome   = outcome_label,
    c_ct      = concordance(Surv(surv_time, surv_event) ~ lp_ct,  reverse = TRUE)$concordance,
    c_esi     = concordance(Surv(surv_time, surv_event) ~ lp_esi, reverse = TRUE)$concordance,
    delta_c   = delta,
    se_delta  = se,
    ci_lo     = ci[1],
    ci_hi     = ci[2],
    tost_p_low  = mean(boot_delta <= -CINDEX_MARGIN),
    tost_p_high = mean(boot_delta >=  CINDEX_MARGIN),
    equivalent_within_margin = (ci[1] > -CINDEX_MARGIN) && (ci[2] < CINDEX_MARGIN),
    method    = sprintf("paired_bootstrap_B%d", B),
    stringsAsFactors = FALSE
  )
}

# Primary attempt for both outcomes
res_all  <- cindex_equiv(cox_bhatt_all,  cox_esi_all,  "all-cause")
res_resp <- cindex_equiv(cox_bhatt_resp, cox_esi_resp, "respiratory")

# Fall back per outcome. The respiratory fit is the sparse one and can fail on
# its own; keying the fallback off the all-cause result let a NULL respiratory
# result through, yielding a silently one-row table.
if (is.null(res_all)) {
  message("A2 primary path unavailable for all-cause; using Harrell's-C bootstrap fallback.")
  res_all <- cindex_equiv_bootstrap(
    mort_b$days_followed / 365.25, mort_b$vital_status,
    predict(cox_bhatt_all, type = "lp"), predict(cox_esi_all, type = "lp"),
    "all-cause")
}
if (is.null(res_resp)) {
  message("A2 primary path unavailable for respiratory; using Harrell's-C bootstrap fallback.")
  res_resp <- cindex_equiv_bootstrap(
    mort_b$days_followed / 365.25, mort_b$event_resp,
    predict(cox_bhatt_resp, type = "lp"), predict(cox_esi_resp, type = "lp"),
    "respiratory")
}

cindex_tbl <- rbind(res_all, res_resp)
# Both outcomes must be present; a dropped row would otherwise reach Table 1
# as a missing equivalence result rather than an error.
# Row count and labels are fixed by construction above. The failure worth
# catching is a fallback that ran and returned a degenerate concordance.
stopifnot(nrow(cindex_tbl) == 2,
          all(is.finite(c(cindex_tbl$c_ct, cindex_tbl$c_esi))),
          all(cindex_tbl$c_ct  > 0.5 & cindex_tbl$c_ct  < 1),
          all(cindex_tbl$c_esi > 0.5 & cindex_tbl$c_esi < 1),
          all(is.finite(cindex_tbl$se_delta) & cindex_tbl$se_delta > 0))
write.csv(cindex_tbl, file.path(OUT_DIR, "Table_1_Cindex_Equivalence.csv"), row.names = FALSE)

kable(cindex_tbl %>%
        mutate(across(where(is.numeric), ~ round(.x, 4))),
      caption = sprintf("Paired C-index equivalence test (margin = %.2f).",
                        CINDEX_MARGIN))
```



Table: Paired C-index equivalence test (margin = 0.02).

|outcome     |   c_ct|  c_esi| delta_c| se_delta|   ci_lo|  ci_hi| tost_p_low| tost_p_high|equivalent_within_margin |method             |
|:-----------|------:|------:|-------:|--------:|-------:|------:|----------:|-----------:|:------------------------|:------------------|
|all-cause   | 0.7034| 0.7001|  0.0033|   0.0016|  0.0002| 0.0064|          0|           0|TRUE                     |paired_concordance |
|respiratory | 0.8527| 0.8512|  0.0015|   0.0013| -0.0011| 0.0041|          0|           0|TRUE                     |paired_concordance |


``` r
ex_b <- d_b %>%
  inner_join(ex_raw %>% select(pid, Total_Exacerbations, Total_Severe_Exacer, Years_Followed),
             by = "pid") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0,
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

nb_bhatt <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
nb_esi   <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)

t_bhatt_ex <- do.call(rbind, lapply(groups3, function(g) {
  b <- nb_row(nb_bhatt, paste0("bhatt_grp", g))
  e <- nb_row(nb_esi,   paste0("esi_grp",   g))
  data.frame(group = g,
             bhatt_IRR = b["IRR"], bhatt_LCI = b["LCI"], bhatt_UCI = b["UCI"], bhatt_p = b["p"],
             esi_IRR   = e["IRR"], esi_LCI   = e["LCI"], esi_UCI   = e["UCI"], esi_p   = e["p"])
}))
write.csv(t_bhatt_ex, file.path(OUT_DIR, "Table_Exacerbations_Bhatt.csv"), row.names = FALSE)
writeLines(c(sprintf("n_cohort=%d",     nrow(ex_b)),
             sprintf("n_total_exac=%d", sum(ex_b$Total_Exacerbations))),
           file.path(OUT_DIR, "Table_Exacerbations_Bhatt_stats.txt"))
kable(t_bhatt_ex, digits = 2, caption = "Exacerbation incidence-rate ratios by category.")
```



Table: Exacerbation incidence-rate ratios by category.

|     |group           | bhatt_IRR| bhatt_LCI| bhatt_UCI| bhatt_p| esi_IRR| esi_LCI| esi_UCI| esi_p|
|:----|:---------------|---------:|---------:|---------:|-------:|-------:|-------:|-------:|-----:|
|IRR  |AFL-only-NoCOPD |      1.28|      0.94|      1.75|    0.11|    0.98|    0.63|     1.5|  0.91|
|IRR1 |COPD-minor      |      2.72|      2.36|      3.14|    0.00|    2.77|    2.33|     3.3|  0.00|
|IRR2 |COPD-major      |      5.05|      4.59|      5.56|    0.00|    4.47|    4.07|     4.9|  0.00|

## Section 6c — Per-category paired-bootstrap HR difference (Supp Table S8 / A3)

Paired subject-resample of `mort_b` (B = 1,000), refitting all four Cox models
each iteration. Records `logHR_CT − logHR_ESI` for COPD-minor and COPD-major
across all-cause and respiratory mortality. Uses seed 20260717; per-iteration
fits wrapped in `tryCatch` so near-singular designs don't crash the loop.

Cached to `manuscript_assets/_cache/bootstrap_hr_diff.rds`; delete the file to
force a re-run.


``` r
B_BOOTSTRAP <- 1000
CACHE_DIR   <- file.path(OUT_DIR, "_cache")
CACHE_PATH  <- file.path(CACHE_DIR, "bootstrap_hr_diff.rds")
if (!dir.exists(CACHE_DIR)) dir.create(CACHE_DIR, recursive = TRUE)

# `table_version` is part of the fingerprint because the cache stores the
# CONSTRUCTED table, not just the resample matrices. Without it, a change to
# the table's columns (as on 2026-08-25, when the log-scale point estimate was
# added) is silently skipped on any run that hits the cache, and the run
# produces the old schema while the code says otherwise. Bump on any change to
# the columns built below.
.want <- list(n = nrow(mort_b),
              deaths = sum(mort_b$vital_status == 1),
              resp_events = sum(mort_b$event_resp == 1),
              B = B_BOOTSTRAP,
              table_version = 2L)
.cached <- if (file.exists(CACHE_PATH)) readRDS(CACHE_PATH) else NULL
if (!is.null(.cached) && !identical(.cached$fingerprint, .want)) {
  message("Bootstrap cache does not match the current data; recomputing.")
  .cached <- NULL
}
if (!is.null(.cached)) {
  boot_res <- .cached
  cat(sprintf("Loaded cached bootstrap: B_effective = %d / %d (all-cause %s, respiratory %s)\n",
              boot_res$B_effective, boot_res$B_total,
              format(boot_res$B_eff_all), format(boot_res$B_eff_resp)))
} else {
  set.seed(BOOTSTRAP_SEED)
  n <- nrow(mort_b)
  ids_seq <- seq_len(n)

  outcomes <- list(all = "vital_status", resp = "event_resp")
  cats     <- c("COPD-minor", "COPD-major")

  # storage: list of matrices [B x length(cats)] per outcome, one for CT and one for ESI
  store <- list()
  for (o in names(outcomes)) for (m in c("bhatt", "esi")) {
    store[[paste(o, m, sep = "_")]] <- matrix(NA_real_, nrow = B_BOOTSTRAP, ncol = length(cats),
                                              dimnames = list(NULL, cats))
  }
  log_hr <- function(fit, term) {
    co <- summary(fit)$coef
    if (!term %in% rownames(co)) return(NA_real_)
    unname(co[term, "coef"])
  }
  # Fit each OUTCOME in its own tryCatch. Previously all four models shared a
  # single tryCatch that also caught warnings, so one warning from the
  # respiratory fit discarded the (valid) all-cause fits for that resample as
  # well. Under the TORCH underlying-cause definition respiratory has 704
  # events with very few in the noCOPD reference, so the respiratory fit warns
  # often — that silently cut the SHARED effective sample to 416/1000 and moved
  # the all-cause interval even though all-cause data were unchanged. The
  # dropped resamples are not missing at random (they are the ones with sparse
  # respiratory events), so isolating failures per outcome is required for the
  # all-cause interval to be unbiased, and B_effective is now tracked per
  # outcome so the respiratory sample size is reported rather than hidden.
  fit_pair <- function(dat, ev_col) tryCatch({
    rhs <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"
    lhs <- paste0("Surv(days_followed/365.25, ", ev_col, ")")
    list(
      ct  = coxph(as.formula(paste(lhs, "~ bhatt_grp +", rhs)), data = dat),
      esi = coxph(as.formula(paste(lhs, "~ esi_grp   +", rhs)), data = dat)
    )
  }, error = function(e) NULL, warning = function(w) NULL)

  B_effective   <- 0L
  B_eff_outcome <- c(all = 0L, resp = 0L)
  for (b in seq_len(B_BOOTSTRAP)) {
    idx <- sample.int(n, size = n, replace = TRUE)
    dat <- mort_b[idx, ]
    fa <- fit_pair(dat, "vital_status")
    fr <- fit_pair(dat, "event_resp")
    if (is.null(fa) && is.null(fr)) next
    if (!is.null(fa)) {
      for (cat_ in cats) {
        store[["all_bhatt"]][b, cat_] <- log_hr(fa$ct,  paste0("bhatt_grp", cat_))
        store[["all_esi"]][b, cat_]   <- log_hr(fa$esi, paste0("esi_grp",   cat_))
      }
      B_eff_outcome["all"] <- B_eff_outcome["all"] + 1L
    }
    if (!is.null(fr)) {
      for (cat_ in cats) {
        store[["resp_bhatt"]][b, cat_] <- log_hr(fr$ct,  paste0("bhatt_grp", cat_))
        store[["resp_esi"]][b, cat_]   <- log_hr(fr$esi, paste0("esi_grp",   cat_))
      }
      B_eff_outcome["resp"] <- B_eff_outcome["resp"] + 1L
    }
    B_effective <- B_effective + 1L
  }
  cat(sprintf("Bootstrap effective resamples: all-cause = %d, respiratory = %d (of %d)\n",
              B_eff_outcome[["all"]], B_eff_outcome[["resp"]], B_BOOTSTRAP))

  # Assemble per (outcome, category) results
  rows <- list()
  for (o in names(outcomes)) {
    for (cat_ in cats) {
      log_ct  <- store[[paste0(o, "_bhatt")]][, cat_]
      log_esi <- store[[paste0(o, "_esi")]][, cat_]
      diffs   <- log_ct - log_esi
      diffs   <- diffs[!is.na(diffs)]
      ci      <- quantile(diffs, c(0.025, 0.975), names = FALSE)
      p_two   <- 2 * min(mean(diffs <= 0), mean(diffs >= 0))
      # Observed point estimate from the primary (unresampled) fits
      obs_hr_ct  <- if (o == "all")
        t8_all$bhatt_HR[t8_all$group == cat_]
      else
        t8_resp$bhatt_HR[t8_resp$group == cat_]
      obs_hr_esi <- if (o == "all")
        t8_all$esi_HR[t8_all$group == cat_]
      else
        t8_resp$esi_HR[t8_resp$group == cat_]
      rows[[length(rows) + 1]] <- data.frame(
        outcome        = ifelse(o == "all", "all-cause", "respiratory"),
        category       = cat_,
        HR_CT          = obs_hr_ct,
        HR_ESI         = obs_hr_esi,
        # The interval below is on the LOG-HR scale, so the point estimate
        # reported beside it must be too. `obs_logHR_diff` is the observed
        # statistic the CI brackets; `mean_logHR_diff` is the mean of the
        # resamples and carries bootstrap bias, so it is kept only as a
        # diagnostic. The difference of untransformed HRs is a third scale
        # again and is retained purely for readers who want it, explicitly
        # named so it cannot be mistaken for the estimate the CI refers to.
        obs_logHR_diff  = log(obs_hr_ct) - log(obs_hr_esi),
        mean_logHR_diff = mean(diffs),
        ci_lo_logHR    = ci[1],
        ci_hi_logHR    = ci[2],
        HR_diff_unlogged = obs_hr_ct - obs_hr_esi,
        # Resolution of the bootstrap p is 2/length(diffs), not 2/B: resamples
        # that failed to fit were dropped above. Derive the floor from the
        # resamples that actually survived.
        two_sided_p    = if (p_two == 0) NA_real_ else p_two,
        two_sided_p_reported = ifelse(p_two == 0,
                                      sprintf("<%.3f", 2 / length(diffs)),
                                      sprintf("%.3f", p_two)),
        stringsAsFactors = FALSE
      )
    }
  }
  boot_res <- list(
    table = do.call(rbind, rows),
    B_total = B_BOOTSTRAP,
    B_effective = B_effective,
    B_eff_all  = B_eff_outcome[["all"]],
    B_eff_resp = B_eff_outcome[["resp"]],
    # Fingerprint of the data this cache was computed from, so a cache carried
    # over from a different cohort or event definition is detected rather than
    # silently reused. Both have changed here: the cause-of-death switch and
    # the ILD exclusion.
    fingerprint = .want,
    seed = BOOTSTRAP_SEED
  )
  saveRDS(boot_res, CACHE_PATH)
  cat(sprintf("Bootstrap complete: B_effective = %d / %d\n",
              B_effective, B_BOOTSTRAP))
}
```

```
## Bootstrap effective resamples: all-cause = 1000, respiratory = 416 (of 1000)
## Bootstrap complete: B_effective = 1000 / 1000
```

``` r
write.csv(boot_res$table, file.path(OUT_DIR, "Supp_Table_HR_Difference_Bootstrap.csv"),
          row.names = FALSE)
writeLines(c(sprintf("B_total=%d",     boot_res$B_total),
             sprintf("B_effective=%d", boot_res$B_effective),
             sprintf("B_effective_all_cause=%s",   format(boot_res$B_eff_all)),
             sprintf("B_effective_respiratory=%s", format(boot_res$B_eff_resp)),
             sprintf("seed=%d",        boot_res$seed)),
           file.path(OUT_DIR, "Table_S8_bootstrap_diagnostics.txt"))

kable(boot_res$table %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      caption = sprintf(paste("Paired-bootstrap change in logHR (CT minus ESI). B = %d;",
                              "effective resamples %d for all-cause and %d for respiratory.",
                              "The two differ because resamples whose Cox fit warned were",
                              "dropped, and those are the sparse-event ones, so the",
                              "respiratory interval rests on the retained subset."),
                        boot_res$B_total, boot_res$B_eff_all, boot_res$B_eff_resp))
```



Table: Paired-bootstrap change in logHR (CT minus ESI). B = 1000; effective resamples 1000 for all-cause and 416 for respiratory. The two differ because resamples whose Cox fit warned were dropped, and those are the sparse-event ones, so the respiratory interval rests on the retained subset.

|outcome     |category   |  HR_CT| HR_ESI| obs_logHR_diff| mean_logHR_diff| ci_lo_logHR| ci_hi_logHR| HR_diff_unlogged| two_sided_p|two_sided_p_reported |
|:-----------|:----------|------:|------:|--------------:|---------------:|-----------:|-----------:|----------------:|-----------:|:--------------------|
|all-cause   |COPD-minor |  1.907|  1.943|         -0.019|          -0.016|      -0.179|       0.135|           -0.036|       0.848|0.848                |
|all-cause   |COPD-major |  2.591|  2.395|          0.079|           0.079|       0.045|       0.115|            0.197|          NA|<0.002               |
|respiratory |COPD-minor |  4.804|  5.684|         -0.168|          -0.146|      -1.026|       0.764|           -0.880|       0.702|0.702                |
|respiratory |COPD-major | 36.266| 30.952|          0.158|           0.163|      -0.182|       0.510|            5.314|       0.293|0.293                |

## Section 6d — Per-category paired-bootstrap IRR difference (exacerbations)

Analog of Section 6c for the negative-binomial exacerbation model. Paired
subject-resample of `ex_b` (B = 1,000, same seed), refitting `nb_bhatt` and
`nb_esi` each iteration. Records `logIRR_CT − logIRR_ESI` for COPD-minor and
COPD-major and reports the two-sided percentile p-value from the resample
distribution. Cached to `manuscript_assets/_cache/bootstrap_irr_diff.rds`.


``` r
CACHE_PATH_IRR <- file.path(CACHE_DIR, "bootstrap_irr_diff.rds")

# This cache had no validation: it was reused whenever the file existed. That
# is the same failure the HR cache above is fingerprinted against, and it bites
# harder here because the cache also stores IRR_CT/IRR_ESI captured when it was
# written, so a stale cache would print old IRRs beside the current ones in
# Table_Exacerbations_Bhatt.csv with nothing to flag it. Same schema version as
# the HR table, and bumped for the same reason.
# `table_version` covers BOTH the output schema and the resampling logic; the
# cache stores the finished table, so either change must invalidate it. Bumped
# to 3 on 2026-08-25 when warnings stopped being fatal in the fit loop.
.want_irr <- list(n = nrow(ex_b),
                  total_exac = sum(ex_b$Total_Exacerbations),
                  B = B_BOOTSTRAP,
                  table_version = 3L)
.cached_irr <- if (file.exists(CACHE_PATH_IRR)) readRDS(CACHE_PATH_IRR) else NULL
if (!is.null(.cached_irr) && !identical(.cached_irr$fingerprint, .want_irr)) {
  message("IRR bootstrap cache does not match the current data or table schema; recomputing.")
  .cached_irr <- NULL
}
if (!is.null(.cached_irr)) {
  boot_irr <- .cached_irr
  cat(sprintf("Loaded cached IRR bootstrap: B_effective = %d / %d\n",
              boot_irr$B_effective, boot_irr$B_total))
} else {
  set.seed(BOOTSTRAP_SEED)
  n_ex <- nrow(ex_b)
  cats <- c("COPD-minor", "COPD-major")

  store_irr <- list(
    bhatt = matrix(NA_real_, nrow = B_BOOTSTRAP, ncol = length(cats),
                   dimnames = list(NULL, cats)),
    esi   = matrix(NA_real_, nrow = B_BOOTSTRAP, ncol = length(cats),
                   dimnames = list(NULL, cats))
  )
  B_effective_irr <- 0L
  B_warned_irr    <- 0L
  for (b in seq_len(B_BOOTSTRAP)) {
    idx <- sample.int(n_ex, size = n_ex, replace = TRUE)
    dat <- ex_b[idx, ]
    # Both fits stay inside one tryCatch on purpose: the statistic is the
    # PAIRED difference logIRR_CT - logIRR_ESI, so a resample is only usable if
    # both fits succeeded. Splitting them per fit (as was done for the two
    # independent OUTCOMES on the Cox side above) would buy nothing here.
    #
    # What was wrong was `warning = function(w) NULL`: any warning discarded
    # the resample outright. glm.nb warns routinely on things that do not
    # invalidate the coefficients (theta iteration limits, step-halving), and
    # discarded resamples are not missing at random, so this could shrink the
    # interval toward the null exactly as it did on the respiratory Cox arm.
    # Warnings are now recorded and muffled rather than fatal; a resample is
    # dropped only if a fit errors or returns a non-finite coefficient.
    warned <- FALSE
    fits <- tryCatch(
      withCallingHandlers({
        list(
          b = MASS::glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race +
                           SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)),
                           data = dat),
          e = MASS::glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race +
                           SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)),
                           data = dat)
        )
      }, warning = function(w) { warned <<- TRUE; invokeRestart("muffleWarning") }),
      error = function(e) NULL)
    if (is.null(fits)) next
    if (warned) B_warned_irr <- B_warned_irr + 1L
    log_irr <- function(fit, term) {
      co <- summary(fit)$coefficients
      if (!term %in% rownames(co)) return(NA_real_)
      unname(co[term, "Estimate"])
    }
    vals_b <- vapply(cats, function(cat_) log_irr(fits$b, paste0("bhatt_grp", cat_)), numeric(1))
    vals_e <- vapply(cats, function(cat_) log_irr(fits$e, paste0("esi_grp",   cat_)), numeric(1))
    if (!all(is.finite(c(vals_b, vals_e)))) next
    store_irr$bhatt[b, cats] <- vals_b
    store_irr$esi[b,   cats] <- vals_e
    B_effective_irr <- B_effective_irr + 1L
  }

  rows_irr <- list()
  for (cat_ in cats) {
    log_ct  <- store_irr$bhatt[, cat_]
    log_esi <- store_irr$esi[,   cat_]
    diffs   <- (log_ct - log_esi)
    diffs   <- diffs[!is.na(diffs)]
    ci      <- quantile(diffs, c(0.025, 0.975), names = FALSE)
    p_two   <- 2 * min(mean(diffs <= 0), mean(diffs >= 0))
    obs_irr_ct  <- t_bhatt_ex$bhatt_IRR[t_bhatt_ex$group == cat_]
    obs_irr_esi <- t_bhatt_ex$esi_IRR[t_bhatt_ex$group == cat_]
    rows_irr[[length(rows_irr) + 1]] <- data.frame(
      outcome        = "exacerbations",
      category       = cat_,
      IRR_CT         = obs_irr_ct,
      IRR_ESI        = obs_irr_esi,
      # Same scale discipline as the HR table above: the CI is on the log-IRR
      # scale, so the estimate reported beside it is the observed log-scale
      # difference, not the resample mean and not the difference of IRRs.
      obs_logIRR_diff  = log(obs_irr_ct) - log(obs_irr_esi),
      mean_logIRR_diff = mean(diffs),
      ci_lo_logIRR   = ci[1],
      ci_hi_logIRR   = ci[2],
      IRR_diff_unlogged = obs_irr_ct - obs_irr_esi,
      two_sided_p    = if (p_two == 0) NA_real_ else p_two,
      two_sided_p_reported = ifelse(p_two == 0,
                                    sprintf("<%.3f", 2 / length(diffs)),
                                    sprintf("%.3f", p_two)),
      stringsAsFactors = FALSE
    )
  }
  boot_irr <- list(
    table = do.call(rbind, rows_irr),
    B_total = B_BOOTSTRAP,
    B_effective = B_effective_irr,
    B_warned    = B_warned_irr,
    seed = BOOTSTRAP_SEED,
    fingerprint = .want_irr
  )
  saveRDS(boot_irr, CACHE_PATH_IRR)
  cat(sprintf("IRR bootstrap complete: B_effective = %d / %d\n",
              B_effective_irr, B_BOOTSTRAP))
}
```

```
## IRR bootstrap complete: B_effective = 1000 / 1000
```

``` r
write.csv(boot_irr$table, file.path(OUT_DIR, "Supp_Table_IRR_Difference_Bootstrap.csv"),
          row.names = FALSE)
writeLines(c(sprintf("B_total=%d",     boot_irr$B_total),
             sprintf("B_effective=%d", boot_irr$B_effective),
             # Recorded so that "no resamples were dropped" is an observation
             # in the artifact rather than an assumption about glm.nb.
             sprintf("B_warned=%s",    format(boot_irr$B_warned %||% NA)),
             sprintf("seed=%d",        boot_irr$seed)),
           file.path(OUT_DIR, "Table_IRR_Bootstrap_diagnostics.txt"))

kable(boot_irr$table %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      caption = sprintf("Paired-bootstrap ΔlogIRR (CT − ESI) — B = %d, B_effective = %d.",
                        boot_irr$B_total, boot_irr$B_effective))
```



Table: Paired-bootstrap ΔlogIRR (CT − ESI) — B = 1000, B_effective = 1000.

|outcome       |category   | IRR_CT| IRR_ESI| obs_logIRR_diff| mean_logIRR_diff| ci_lo_logIRR| ci_hi_logIRR| IRR_diff_unlogged| two_sided_p|two_sided_p_reported |
|:-------------|:----------|------:|-------:|---------------:|----------------:|------------:|------------:|-----------------:|-----------:|:--------------------|
|exacerbations |COPD-minor |  2.718|   2.774|          -0.020|           -0.020|       -0.167|        0.117|            -0.055|       0.796|0.796                |
|exacerbations |COPD-major |  5.053|   4.468|           0.123|            0.123|        0.080|        0.166|             0.585|          NA|<0.002               |


``` r
fev1_long <- phe_raw %>%
  filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(pid, visitnum, years_from_baseline,
            FEV1_post_mL  = FEV1_post * 1000,
            age_visit     = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow    = factor(SmokCigNow))

base_b <- d_b %>% transmute(
  pid,
  bhatt_grp = factor(bhatt_cls, levels = ord),
  esi_grp   = factor(esi_cls,   levels = ord),
  Height_CM = as.numeric(Height_CM),
  gender_baseline = factor(gender),
  race_baseline   = factor(race)
)
decline_b <- fev1_long %>% inner_join(base_b, by = "pid") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))

lmm_bhatt <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + Height_CM +
                    gender_baseline + race_baseline + age_visit + SmokCigNow +
                    ATS_PackYears + (1 | pid), data = decline_b)
lmm_esi   <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp + Height_CM +
                    gender_baseline + race_baseline + age_visit + SmokCigNow +
                    ATS_PackYears + (1 | pid), data = decline_b)

t_decline <- data.frame(group = groups3,
                        bhatt_est = NA_real_, bhatt_se = NA_real_, bhatt_p = NA_real_,
                        esi_est   = NA_real_, esi_se   = NA_real_, esi_p   = NA_real_)
for (i in seq_along(groups3)) {
  b <- lmm_row(lmm_bhatt, paste0("years_from_baseline:bhatt_grp", groups3[i]))
  e <- lmm_row(lmm_esi,   paste0("years_from_baseline:esi_grp",   groups3[i]))
  t_decline$bhatt_est[i] <- b["est"]; t_decline$bhatt_se[i] <- b["se"]; t_decline$bhatt_p[i] <- b["p"]
  t_decline$esi_est[i]   <- e["est"]; t_decline$esi_se[i]   <- e["se"]; t_decline$esi_p[i]   <- e["p"]
}
write.csv(t_decline, file.path(OUT_DIR, "Table_BhattDecline.csv"), row.names = FALSE)
kable(t_decline, digits = 2, caption = "FEV1 decline (mL/yr) by category, interaction with follow-up time.")
```



Table: FEV1 decline (mL/yr) by category, interaction with follow-up time.

|group           | bhatt_est| bhatt_se| bhatt_p| esi_est| esi_se| esi_p|
|:---------------|---------:|--------:|-------:|-------:|------:|-----:|
|AFL-only-NoCOPD |      3.63|     2.77|    0.19|   10.15|   4.20|  0.02|
|COPD-minor      |     -0.48|     1.48|    0.75|   -1.56|   1.81|  0.39|
|COPD-major      |      1.27|     0.97|    0.19|    1.09|   0.94|  0.25|

## Section 6d — Follow-up duration for the longitudinal analyses

Each analysis has its own analytic dataset, and those datasets do not share a
denominator, so follow-up is computed from the object each model was actually
fit on (`mort_b`, `ex_b`, `decline_b`) rather than from the full analytic
cohort. Placed after the three cohorts are built so it cannot drift from them.
Reproduces `Table_Followup_Duration.csv`.


``` r
stopifnot(exists("mort_b"), exists("ex_b"), exists("decline_b"))

fu_row <- function(analysis, source_file, quantity, x) {
  stopifnot(length(x) > 0, !any(is.na(x)))
  data.frame(
    analysis    = analysis,
    source_file = source_file,
    quantity    = quantity,
    n           = length(x),
    median_yr   = median(x),
    q1_yr       = quantile(x, 0.25, names = FALSE),
    q3_yr       = quantile(x, 0.75, names = FALSE),
    min_yr      = min(x),
    max_yr      = max(x),
    stringsAsFactors = FALSE
  )
}

# FEV1 decline is the only analysis with repeated measures, and its follow-up
# needs care. Every participant in mort_b and ex_b contributes a positive time
# at risk, so a median/IQR of that time is the natural summary. In decline_b,
# by contrast, participants with only the baseline visit have a
# baseline-to-last-visit span of exactly 0 - they have no follow-up at all, and
# inform the model's intercept rather than any slope. Including them drags the
# first quartile to 0 and makes the IQR uninterpretable as a follow-up period,
# so decline follow-up is summarised among participants who contributed at
# least one follow-up visit, with the baseline-only count reported alongside.
decl_span <- aggregate(years_from_baseline ~ pid, decline_b, max)
decl_nvis <- aggregate(visitnum ~ pid, decline_b, length)
decl      <- merge(decl_span, decl_nvis, by = "pid")
# aggregate(... ~ pid) yields one row per pid on both sides, so this equality
# holds by construction. The merge's real risk is dropping pids, so compare
# against the input set rather than against the merge's own arithmetic.
stopifnot(setequal(decl$pid, unique(decline_b$pid)))
n_baseline_only <- sum(decl$visitnum == 1)
decl_fu <- decl$years_from_baseline[decl$visitnum >= 2]
stopifnot(all(decl_fu > 0))   # a follow-up period of zero is not follow-up

followup_tbl <- rbind(
  fu_row("All-cause and respiratory mortality", "vital status",
         "time at risk (days_followed / 365.25)",
         mort_b$days_followed / 365.25),
  fu_row("Exacerbations", "long-term follow-up",
         "exposure time (Years_Followed, model offset)",
         ex_b$Years_Followed),
  fu_row("FEV1 decline (participants with >=1 follow-up visit)", "longitudinal phenotype",
         "baseline to last observed visit",
         decl_fu)
)
write.csv(followup_tbl, file.path(OUT_DIR, "Table_Followup_Duration.csv"),
          row.names = FALSE)

# COPDGene follow-up visits are scheduled near 5 and 10 years, so the pooled
# decline follow-up distribution is bimodal and a single median understates the
# structure. Report the timing of each visit and how many participants reached
# it; this is the more faithful description of the longitudinal design.
visit_tbl <- do.call(rbind, lapply(sort(unique(decline_b$visitnum)), function(v) {
  y <- decline_b$years_from_baseline[decline_b$visitnum == v]
  data.frame(visit = v, n_participants = length(y),
             median_yr = median(y),
             q1_yr = quantile(y, .25, names = FALSE),
             q3_yr = quantile(y, .75, names = FALSE))
}))
write.csv(visit_tbl, file.path(OUT_DIR, "Table_Followup_ByVisit.csv"),
          row.names = FALSE)

cat(sprintf(paste0(
  "FEV1-decline dataset: %d observations, %d participants.\n",
  "  %d contributed >=1 follow-up visit; %d contributed baseline only ",
  "(no follow-up, intercept-only contribution).\n",
  "  visits per participant: 1 visit %d, 2 visits %d, 3 visits %d\n"),
  nrow(decline_b), nrow(decl), sum(decl$visitnum >= 2), n_baseline_only,
  sum(decl$visitnum == 1), sum(decl$visitnum == 2), sum(decl$visitnum == 3)))
```

```
## FEV1-decline dataset: 17725 observations, 9402 participants.
##   5545 contributed >=1 follow-up visit; 3857 contributed baseline only (no follow-up, intercept-only contribution).
##   visits per participant: 1 visit 3857, 2 visits 2767, 3 visits 2778
```

``` r
kable(followup_tbl, digits = 1,
      caption = paste("Follow-up duration by longitudinal analysis, computed from",
                      "each model's own analytic dataset. FEV1-decline follow-up",
                      "excludes baseline-only participants, who have no follow-up."))
```



Table: Follow-up duration by longitudinal analysis, computed from each model's own analytic dataset. FEV1-decline follow-up excludes baseline-only participants, who have no follow-up.

|analysis                                             |source_file            |quantity                                     |    n| median_yr| q1_yr| q3_yr| min_yr| max_yr|
|:----------------------------------------------------|:----------------------|:--------------------------------------------|----:|---------:|-----:|-----:|------:|------:|
|All-cause and respiratory mortality                  |vital status           |time at risk (days_followed / 365.25)        | 9400|      10.9|   5.5|  13.0|    0.0|   15.2|
|Exacerbations                                        |long-term follow-up    |exposure time (Years_Followed, model offset) | 8338|      10.4|   5.1|  11.8|    0.2|   13.8|
|FEV1 decline (participants with >=1 follow-up visit) |longitudinal phenotype |baseline to last observed visit              | 5545|       9.7|   5.4|  10.5|    3.6|   14.8|

``` r
kable(visit_tbl, digits = 1,
      caption = paste("Timing of each COPDGene visit in the FEV1-decline dataset.",
                      "Visits cluster near 5 and 10 years, so the pooled follow-up",
                      "distribution is bimodal."))
```



Table: Timing of each COPDGene visit in the FEV1-decline dataset. Visits cluster near 5 and 10 years, so the pooled follow-up distribution is bimodal.

| visit| n_participants| median_yr| q1_yr| q3_yr|
|-----:|--------------:|---------:|-----:|-----:|
|     1|           9402|       0.0|   0.0|   0.0|
|     2|           5282|       5.3|   5.0|   5.8|
|     3|           3041|      10.3|   9.9|  11.6|

# Section 7 — Cross-classification outcomes (Table 2)

Adjusted outcomes among preserved-spirometry participants, cross-classified by
CT-based × ESI-based frameworks (reference: Both-noCOPD).  Reproduces
`Table_BhattOnly_vs_Both.csv`, `Table_CauseSpecific_byDiscord.csv`,
`Table_Exacerbations_Discordance.csv`, and `Table_FEV1Decline_byDiscord.csv`.


``` r
mort_disc <- mort_b %>% filter(!major_criterion)
mort_disc$discord <- factor(mort_disc$discord,
                            levels = c("Both-noCOPD", "Both-COPD", "CT-only-COPD", "ESI-only-COPD"))

cox_disc_all  <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_disc)
cox_disc_resp <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_disc)

# Retain the "(ESI missed)" / "(Bhatt missed)" naming used by build_revisions_v2
label_map <- c("Both-COPD"        = "Both-COPD",
               "CT-only-COPD" = "CT-only-COPD (ESI missed)",
               "ESI-only-COPD"   = "ESI-only-COPD (Bhatt missed)")

t_grp_mort <- data.frame(
  group = unname(label_map),
  n            = as.integer(NA), n_deaths_all = as.integer(NA),
  all_HR = NA_real_, all_LCI = NA_real_, all_UCI = NA_real_, all_p = NA_real_,
  resp_HR = NA_real_, resp_LCI = NA_real_, resp_UCI = NA_real_, resp_p = NA_real_
)
for (short in names(label_map)) {
  i <- which(t_grp_mort$group == label_map[short])
  t_grp_mort$n[i]            <- sum(mort_disc$discord == short)
  t_grp_mort$n_deaths_all[i] <- sum(mort_disc$discord == short & mort_disc$vital_status == 1)
  hra <- cox_row(cox_disc_all,  paste0("discord", short))
  hrr <- cox_row(cox_disc_resp, paste0("discord", short))
  t_grp_mort$all_HR[i]  <- hra["HR"]; t_grp_mort$all_LCI[i]  <- hra["LCI"]; t_grp_mort$all_UCI[i]  <- hra["UCI"]; t_grp_mort$all_p[i]  <- hra["p"]
  t_grp_mort$resp_HR[i] <- hrr["HR"]; t_grp_mort$resp_LCI[i] <- hrr["LCI"]; t_grp_mort$resp_UCI[i] <- hrr["UCI"]; t_grp_mort$resp_p[i] <- hrr["p"]
}
write.csv(t_grp_mort, file.path(OUT_DIR, "Table_BhattOnly_vs_Both.csv"), row.names = FALSE)
kable(t_grp_mort, digits = 2, caption = "Cross-classification mortality outcomes.")
```



Table: Cross-classification mortality outcomes.

|group                        |   n| n_deaths_all| all_HR| all_LCI| all_UCI| all_p| resp_HR| resp_LCI| resp_UCI| resp_p|
|:----------------------------|---:|------------:|------:|-------:|-------:|-----:|-------:|--------:|--------:|------:|
|Both-COPD                    | 548|          134|   2.02|    1.66|    2.46|  0.00|    6.10|     2.19|    16.96|   0.00|
|CT-only-COPD (ESI missed)    | 538|          114|   1.53|    1.25|    1.88|  0.00|    2.90|     0.91|     9.28|   0.07|
|ESI-only-COPD (Bhatt missed) |  94|           16|   1.26|    0.76|    2.07|  0.37|    4.86|     0.62|    38.02|   0.13|


``` r
covs <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"
d_pres <- d_b %>%
  inner_join(vs %>% select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% select(pid, UCD_CVD, UCD_Cancer, UCD_Other, UCD_Resp), by = "pid") %>%
  filter(!major_criterion,
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

causes       <- c("UCD_CVD", "UCD_Cancer", "UCD_Other")
cause_labels <- c("CVD",       "Cancer",       "Other")

t_cs_disc <- list()
for (i in seq_along(causes)) {
  ev  <- mk_event(d_pres, causes[i])
  fit <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ discord +", covs)), data = d_pres)
  for (g in c("Both-COPD", "CT-only-COPD", "ESI-only-COPD")) {
    hr <- cox_row(fit, paste0("discord", g))
    t_cs_disc[[length(t_cs_disc) + 1]] <- data.frame(
      cause = cause_labels[i], group = g,
      n_events = sum(ev[d_pres$discord == g] == 1),
      HR = hr["HR"], LCI = hr["LCI"], UCI = hr["UCI"], p = hr["p"]
    )
  }
}
t_cs_disc <- do.call(rbind, t_cs_disc)
write.csv(t_cs_disc, file.path(OUT_DIR, "Table_CauseSpecific_byDiscord.csv"), row.names = FALSE)
kable(t_cs_disc, digits = 2, caption = "Cause-specific mortality by cross-classification subgroup.")
```



Table: Cause-specific mortality by cross-classification subgroup.

|    |cause  |group         | n_events|   HR|  LCI|  UCI|    p|
|:---|:------|:-------------|--------:|----:|----:|----:|----:|
|HR  |CVD    |Both-COPD     |       18| 1.47| 0.87| 2.48| 0.15|
|HR1 |CVD    |CT-only-COPD  |       19| 1.37| 0.83| 2.28| 0.22|
|HR2 |CVD    |ESI-only-COPD |        5| 2.29| 0.93| 5.67| 0.07|
|HR3 |Cancer |Both-COPD     |       33| 2.85| 1.88| 4.32| 0.00|
|HR4 |Cancer |CT-only-COPD  |       24| 1.75| 1.11| 2.76| 0.02|
|HR5 |Cancer |ESI-only-COPD |        3| 1.45| 0.46| 4.59| 0.53|
|HR6 |Other  |Both-COPD     |       34| 2.27| 1.52| 3.39| 0.00|
|HR7 |Other  |CT-only-COPD  |       26| 1.78| 1.15| 2.77| 0.01|
|HR8 |Other  |ESI-only-COPD |        3| 1.12| 0.36| 3.55| 0.84|


``` r
ex_disc <- ex_b %>% filter(!major_criterion)
ex_disc$discord <- factor(ex_disc$discord,
                          levels = c("Both-noCOPD", "Both-COPD", "CT-only-COPD", "ESI-only-COPD"))
nb_disc <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_disc)

t_disc_ex <- data.frame(group = unname(label_map),
                        n = NA_integer_, IRR = NA_real_, LCI = NA_real_, UCI = NA_real_, p = NA_real_)
for (short in names(label_map)) {
  i <- which(t_disc_ex$group == label_map[short])
  t_disc_ex$n[i] <- sum(ex_disc$discord == short)
  v <- nb_row(nb_disc, paste0("discord", short))
  t_disc_ex$IRR[i] <- v["IRR"]; t_disc_ex$LCI[i] <- v["LCI"]; t_disc_ex$UCI[i] <- v["UCI"]; t_disc_ex$p[i] <- v["p"]
}
write.csv(t_disc_ex, file.path(OUT_DIR, "Table_Exacerbations_Discordance.csv"), row.names = FALSE)
kable(t_disc_ex, digits = 2, caption = "Exacerbation IRRs by cross-classification subgroup.")
```



Table: Exacerbation IRRs by cross-classification subgroup.

|group                        |   n|  IRR|  LCI|  UCI|    p|
|:----------------------------|---:|----:|----:|----:|----:|
|Both-COPD                    | 464| 3.15| 2.52| 3.93| 0.00|
|CT-only-COPD (ESI missed)    | 454| 2.00| 1.60| 2.51| 0.00|
|ESI-only-COPD (Bhatt missed) |  78| 1.62| 0.97| 2.68| 0.06|

## Section 7b — Table 2 pairwise contrasts (item 4)

Three comparisons among Both-COPD / CT-only-COPD / ESI-only-COPD, using a
**hand-built 3 × k contrast matrix** so `multcomp::glht`'s single-step
adjustment is calibrated over exactly the three reported contrasts (finding 1
from the second plan-agent review — `mcp("Tukey")` would compute the correction
over 6 pairs and leave the reported p-values miscalibrated).

`df = fit$df.residual` passed explicitly for the negative-binomial fit
(finding 2 defensive coding).


``` r
# Three coefficient names — same in cox_disc_all / cox_disc_resp / nb_disc
target_terms <- c("discordBoth-COPD", "discordCT-only-COPD", "discordESI-only-COPD")

make_K <- function(fit) {
  cn <- names(coef(fit))
  i <- match(target_terms, cn)
  stopifnot(!anyNA(i))
  k <- length(cn)
  row <- function(a, b) { r <- numeric(k); r[i[a]] <- 1; r[i[b]] <- -1; names(r) <- cn; r }
  K <- rbind(
    "Both-COPD - CT-only-COPD"       = row(1, 2),
    "Both-COPD - ESI-only-COPD"         = row(1, 3),
    "CT-only-COPD - ESI-only-COPD"   = row(2, 3)
  )
  K
}

pairwise_rows <- function(fit, outcome_label, df_override = NULL) {
  K  <- make_K(fit)
  tk <- if (is.null(df_override)) glht(fit, linfct = K)
        else                       glht(fit, linfct = K, df = df_override)
  # multcomp's single-step adjustment integrates the multivariate normal by
  # Monte Carlo, so the adjusted p-values are not reproducible unless the RNG
  # is fixed. Unseeded, a re-run moved the smallest of them by ~10% relative
  # (0.00554 -> 0.00496) - enough for a reader reproducing this analysis to get
  # different numbers from the ones printed in the paper.
  set.seed(PAIRWISE_SEED)
  s  <- summary(tk)$test  # single-step adjustment over the 3 reported contrasts
  data.frame(
    outcome    = outcome_label,
    contrast   = rownames(K),
    est_logHR  = unname(s$coefficients),
    se_logHR   = unname(s$sigma),
    p_adj      = unname(s$pvalues),
    stringsAsFactors = FALSE
  )
}

tk_all  <- pairwise_rows(cox_disc_all,  "all-cause mortality")
tk_resp <- pairwise_rows(cox_disc_resp, "respiratory mortality")
tk_exac <- pairwise_rows(nb_disc,        "exacerbations",
                         df_override = nb_disc$df.residual)

t_pw <- rbind(tk_all, tk_resp, tk_exac)
write.csv(t_pw, file.path(OUT_DIR, "Table_2_pairwise_contrasts.csv"), row.names = FALSE)

kable(t_pw %>% mutate(est_logHR = round(est_logHR, 3),
                      se_logHR  = round(se_logHR, 3),
                      p_adj     = signif(p_adj, 3)),
      caption = "Table 2 pairwise contrasts (single-step adjusted over the three reported pairs).")
```



Table: Table 2 pairwise contrasts (single-step adjusted over the three reported pairs).

|outcome               |contrast                     | est_logHR| se_logHR|  p_adj|
|:---------------------|:----------------------------|---------:|--------:|------:|
|all-cause mortality   |Both-COPD - CT-only-COPD     |     0.279|    0.128| 0.0690|
|all-cause mortality   |Both-COPD - ESI-only-COPD    |     0.476|    0.265| 0.1610|
|all-cause mortality   |CT-only-COPD - ESI-only-COPD |     0.197|    0.268| 0.7330|
|respiratory mortality |Both-COPD - CT-only-COPD     |     0.743|    0.638| 0.4640|
|respiratory mortality |Both-COPD - ESI-only-COPD    |     0.227|    1.080| 0.9750|
|respiratory mortality |CT-only-COPD - ESI-only-COPD |    -0.516|    1.124| 0.8870|
|exacerbations         |Both-COPD - CT-only-COPD     |     0.453|    0.147| 0.0050|
|exacerbations         |Both-COPD - ESI-only-COPD    |     0.667|    0.274| 0.0366|
|exacerbations         |CT-only-COPD - ESI-only-COPD |     0.214|    0.275| 0.7070|


``` r
base_pres <- d_pres %>% transmute(
  pid,
  discord         = factor(discord, levels = c("Both-noCOPD", "Both-COPD", "CT-only-COPD", "ESI-only-COPD")),
  Height_CM       = as.numeric(Height_CM),
  gender_baseline = factor(gender),
  race_baseline   = factor(race)
)
decline_d <- fev1_long %>% inner_join(base_pres, by = "pid") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
lmm_disc <- lmer(FEV1_post_mL ~ years_from_baseline * discord + Height_CM +
                   gender_baseline + race_baseline + age_visit + SmokCigNow +
                   ATS_PackYears + (1 | pid), data = decline_d)

t_dec_disc <- data.frame(
  group = c("Both-COPD", "CT-only-COPD", "ESI-only-COPD"),
  n_subj = c(sum(decline_d$discord == "Both-COPD"        & !duplicated(decline_d$pid)),
             sum(decline_d$discord == "CT-only-COPD" & !duplicated(decline_d$pid)),
             sum(decline_d$discord == "ESI-only-COPD"   & !duplicated(decline_d$pid)))
)
for (g in t_dec_disc$group) {
  v <- lmm_row(lmm_disc, paste0("years_from_baseline:discord", g))
  i <- match(g, t_dec_disc$group)
  t_dec_disc$est[i] <- v["est"]; t_dec_disc$se[i] <- v["se"]; t_dec_disc$p[i] <- v["p"]
}
write.csv(t_dec_disc, file.path(OUT_DIR, "Table_FEV1Decline_byDiscord.csv"), row.names = FALSE)
kable(t_dec_disc, digits = 2, caption = "FEV1 decline slope contrasts by cross-classification subgroup.")
```



Table: FEV1 decline slope contrasts by cross-classification subgroup.

|group         | n_subj|   est|   se|    p|
|:-------------|------:|-----:|----:|----:|
|Both-COPD     |    548| -1.40| 1.89| 0.46|
|CT-only-COPD  |    538|  0.19| 1.96| 0.92|
|ESI-only-COPD |     94| -3.70| 4.02| 0.36|

# Section 8 — Cause-specific mortality by diagnostic category (Supp Table S4)


``` r
d_all_cat <- d_b %>%
  inner_join(vs %>% select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% select(pid, UCD_CVD, UCD_Cancer, UCD_Other), by = "pid") %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

t_by_bhatt <- list(); t_by_esi <- list()
for (i in seq_along(causes)) {
  ev    <- mk_event(d_all_cat, causes[i]); lab <- cause_labels[i]
  fit_b <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ bhatt_grp +", covs)), data = d_all_cat)
  fit_e <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ esi_grp +", covs)),   data = d_all_cat)
  for (g in groups3) {
    bh <- cox_row(fit_b, paste0("bhatt_grp", g))
    eh <- cox_row(fit_e, paste0("esi_grp",   g))
    t_by_bhatt[[length(t_by_bhatt) + 1]] <- data.frame(
      cause = lab, group = g,
      n_events_bhatt = sum(ev[d_all_cat$bhatt_grp == g] == 1),
      bhatt_HR = bh["HR"], bhatt_LCI = bh["LCI"], bhatt_UCI = bh["UCI"], bhatt_p = bh["p"])
    t_by_esi[[length(t_by_esi) + 1]]     <- data.frame(
      cause = lab, group = g,
      n_events_esi = sum(ev[d_all_cat$esi_grp == g] == 1),
      esi_HR = eh["HR"], esi_LCI = eh["LCI"], esi_UCI = eh["UCI"], esi_p = eh["p"])
  }
}
t_cs_class <- do.call(rbind, t_by_bhatt) %>%
  inner_join(do.call(rbind, t_by_esi), by = c("cause", "group"))
write.csv(t_cs_class, file.path(OUT_DIR, "Table_CauseSpecific_byClass.csv"), row.names = FALSE)
kable(t_cs_class, digits = 2, caption = "Cause-specific mortality HRs by diagnostic category, both frameworks head-to-head.")
```



Table: Cause-specific mortality HRs by diagnostic category, both frameworks head-to-head.

|cause  |group           | n_events_bhatt| bhatt_HR| bhatt_LCI| bhatt_UCI| bhatt_p| n_events_esi| esi_HR| esi_LCI| esi_UCI| esi_p|
|:------|:---------------|--------------:|--------:|---------:|---------:|-------:|------------:|------:|-------:|-------:|-----:|
|CVD    |AFL-only-NoCOPD |              6|     1.22|      0.53|      2.79|    0.64|            2|   0.73|    0.18|    2.98|  0.67|
|CVD    |COPD-minor      |             37|     1.39|      0.95|      2.05|    0.09|           23|   1.51|    0.96|    2.37|  0.08|
|CVD    |COPD-major      |            186|     1.75|      1.35|      2.26|    0.00|          190|   1.71|    1.33|    2.19|  0.00|
|Cancer |AFL-only-NoCOPD |              7|     1.19|      0.55|      2.57|    0.66|            6|   1.61|    0.71|    3.66|  0.26|
|Cancer |COPD-minor      |             57|     2.32|      1.67|      3.23|    0.00|           36|   2.48|    1.70|    3.61|  0.00|
|Cancer |COPD-major      |            275|     1.97|      1.56|      2.50|    0.00|          276|   1.79|    1.43|    2.24|  0.00|
|Other  |AFL-only-NoCOPD |              4|     0.81|      0.30|      2.19|    0.67|            1|   0.36|    0.05|    2.57|  0.31|
|Other  |COPD-minor      |             60|     2.11|      1.53|      2.92|    0.00|           37|   2.02|    1.39|    2.92|  0.00|
|Other  |COPD-major      |            157|     1.43|      1.10|      1.85|    0.01|          160|   1.30|    1.02|    1.67|  0.03|

## Section 8b — Supp Table S3: three sensitivity analyses (A6b.2)

Three pre-specified sensitivity analyses of the primary by-category framework:

1. **ESI = 10 excluded** — drops the ceiling-effect subset.
2. **Alternative 4-criterion framework** — ESI collapsed to a single `≥ 1.5` cutoff (instead of the primary 5-crit two-threshold rule); ≥3-of-N COPD-minor threshold preserved (`classify_4crit(x, 1.5, 3)` — a ≥3-of-4 rule that parallels the primary ≥3-of-5).  Stress test, not a competing framework.
3. **Severe exacerbations only** — `Total_Severe_Exacer` as the NB outcome.


``` r
sens_rows <- list()

# ---- (i) ESI = 10 excluded --------------------------------------------------
mort_no_ceil <- mort_b %>% filter(ESI_v1post < 9.999)
cbA <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_no_ceil)
ceA <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_no_ceil)
cbR <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_no_ceil)
ceR <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_no_ceil)
ex_no_ceil <- ex_b %>% filter(ESI_v1post < 9.999)
nbB <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_no_ceil)
nbE <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_no_ceil)
for (g in groups3) {
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "CT-based",  outcome = "all-cause",    group = g, as.list(cox_row(cbA, paste0("bhatt_grp", g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "ESI-based", outcome = "all-cause",    group = g, as.list(cox_row(ceA, paste0("esi_grp",   g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "CT-based",  outcome = "respiratory",  group = g, as.list(cox_row(cbR, paste0("bhatt_grp", g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "ESI-based", outcome = "respiratory",  group = g, as.list(cox_row(ceR, paste0("esi_grp",   g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "CT-based",  outcome = "exacerbations",group = g, IRR = as.list(nb_row(nbB, paste0("bhatt_grp", g)))$IRR, LCI = as.list(nb_row(nbB, paste0("bhatt_grp", g)))$LCI, UCI = as.list(nb_row(nbB, paste0("bhatt_grp", g)))$UCI, p = as.list(nb_row(nbB, paste0("bhatt_grp", g)))$p)
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "ESI=10 excluded",   framework = "ESI-based", outcome = "exacerbations",group = g, IRR = as.list(nb_row(nbE, paste0("esi_grp",   g)))$IRR, LCI = as.list(nb_row(nbE, paste0("esi_grp",   g)))$LCI, UCI = as.list(nb_row(nbE, paste0("esi_grp",   g)))$UCI, p = as.list(nb_row(nbE, paste0("esi_grp",   g)))$p)
}

# ---- (ii) Alternative 4-criterion framework: ESI >= 1.5, >=3-of-4 -----------
# Uses the classify_4crit() function defined in Section 3 (threshold-selection).
d_b$esi_cls_4crit <- classify_4crit(d_b, 1.5, 3)
mort_b_4c <- mort_b %>%
  mutate(esi_cls_4crit = d_b$esi_cls_4crit[match(pid, d_b$pid)],
         esi_grp_4crit = factor(esi_cls_4crit, levels = ord))
cbA4 <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp        + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b_4c)
ceA4 <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp_4crit    + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b_4c)
cbR4 <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp        + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b_4c)
ceR4 <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp_4crit    + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b_4c)
ex_b_4c <- ex_b %>%
  mutate(esi_cls_4crit = d_b$esi_cls_4crit[match(pid, d_b$pid)],
         esi_grp_4crit = factor(esi_cls_4crit, levels = ord))
nbB4 <- glm.nb(Total_Exacerbations ~ bhatt_grp     + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b_4c)
nbE4 <- glm.nb(Total_Exacerbations ~ esi_grp_4crit + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b_4c)
for (g in groups3) {
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "CT-based",  outcome = "all-cause",    group = g, as.list(cox_row(cbA4, paste0("bhatt_grp",     g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "ESI-based", outcome = "all-cause",    group = g, as.list(cox_row(ceA4, paste0("esi_grp_4crit", g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "CT-based",  outcome = "respiratory",  group = g, as.list(cox_row(cbR4, paste0("bhatt_grp",     g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "ESI-based", outcome = "respiratory",  group = g, as.list(cox_row(ceR4, paste0("esi_grp_4crit", g))))
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "CT-based",  outcome = "exacerbations",group = g, IRR = as.list(nb_row(nbB4, paste0("bhatt_grp",     g)))$IRR, LCI = as.list(nb_row(nbB4, paste0("bhatt_grp",     g)))$LCI, UCI = as.list(nb_row(nbB4, paste0("bhatt_grp",     g)))$UCI, p = as.list(nb_row(nbB4, paste0("bhatt_grp",     g)))$p)
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "4-criterion alt",   framework = "ESI-based", outcome = "exacerbations",group = g, IRR = as.list(nb_row(nbE4, paste0("esi_grp_4crit", g)))$IRR, LCI = as.list(nb_row(nbE4, paste0("esi_grp_4crit", g)))$LCI, UCI = as.list(nb_row(nbE4, paste0("esi_grp_4crit", g)))$UCI, p = as.list(nb_row(nbE4, paste0("esi_grp_4crit", g)))$p)
}

# ---- (iii) Severe exacerbations only -----------------------------------------
nbBs <- glm.nb(Total_Severe_Exacer ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
nbEs <- glm.nb(Total_Severe_Exacer ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
for (g in groups3) {
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "severe exac only",  framework = "CT-based",  outcome = "exacerbations", group = g, IRR = as.list(nb_row(nbBs, paste0("bhatt_grp", g)))$IRR, LCI = as.list(nb_row(nbBs, paste0("bhatt_grp", g)))$LCI, UCI = as.list(nb_row(nbBs, paste0("bhatt_grp", g)))$UCI, p = as.list(nb_row(nbBs, paste0("bhatt_grp", g)))$p)
  sens_rows[[length(sens_rows) + 1]] <- data.frame(sensitivity = "severe exac only",  framework = "ESI-based", outcome = "exacerbations", group = g, IRR = as.list(nb_row(nbEs, paste0("esi_grp",   g)))$IRR, LCI = as.list(nb_row(nbEs, paste0("esi_grp",   g)))$LCI, UCI = as.list(nb_row(nbEs, paste0("esi_grp",   g)))$UCI, p = as.list(nb_row(nbEs, paste0("esi_grp",   g)))$p)
}

# Rows use two different column names (HR vs IRR); normalize to a common "estimate" column.
sens_out <- do.call(rbind, lapply(sens_rows, function(r) {
  est <- if ("HR" %in% names(r)) r$HR else r$IRR
  data.frame(sensitivity = r$sensitivity, framework = r$framework, outcome = r$outcome,
             group = r$group, estimate = est, LCI = r$LCI, UCI = r$UCI, p = r$p,
             stringsAsFactors = FALSE)
}))
write.csv(sens_out, file.path(OUT_DIR, "Table_S3_sensitivity.csv"), row.names = FALSE)
kable(sens_out %>% mutate(across(where(is.numeric), ~ round(.x, 3))),
      caption = "Supp Table S3 — three sensitivity analyses (rows are HR for mortality outcomes, IRR for exacerbations).")
```



Table: Supp Table S3 — three sensitivity analyses (rows are HR for mortality outcomes, IRR for exacerbations).

|sensitivity      |framework |outcome       |group           | estimate|    LCI|    UCI|     p|
|:----------------|:---------|:-------------|:---------------|--------:|------:|------:|-----:|
|ESI=10 excluded  |CT-based  |all-cause     |AFL-only-NoCOPD |    0.898|  0.622|  1.297| 0.568|
|ESI=10 excluded  |ESI-based |all-cause     |AFL-only-NoCOPD |    0.908|  0.568|  1.452| 0.688|
|ESI=10 excluded  |CT-based  |respiratory   |AFL-only-NoCOPD |    1.405|  0.184| 10.746| 0.743|
|ESI=10 excluded  |ESI-based |respiratory   |AFL-only-NoCOPD |    2.152|  0.285| 16.243| 0.457|
|ESI=10 excluded  |CT-based  |exacerbations |AFL-only-NoCOPD |    1.292|  0.948|  1.759| 0.104|
|ESI=10 excluded  |ESI-based |exacerbations |AFL-only-NoCOPD |    0.974|  0.631|  1.504| 0.905|
|ESI=10 excluded  |CT-based  |all-cause     |COPD-minor      |    1.863|  1.602|  2.166| 0.000|
|ESI=10 excluded  |ESI-based |all-cause     |COPD-minor      |    1.898|  1.587|  2.270| 0.000|
|ESI=10 excluded  |CT-based  |respiratory   |COPD-minor      |    4.552|  2.031| 10.201| 0.000|
|ESI=10 excluded  |ESI-based |respiratory   |COPD-minor      |    5.409|  2.306| 12.688| 0.000|
|ESI=10 excluded  |CT-based  |exacerbations |COPD-minor      |    2.692|  2.330|  3.109| 0.000|
|ESI=10 excluded  |ESI-based |exacerbations |COPD-minor      |    2.749|  2.305|  3.277| 0.000|
|ESI=10 excluded  |CT-based  |all-cause     |COPD-major      |    2.398|  2.173|  2.647| 0.000|
|ESI=10 excluded  |ESI-based |all-cause     |COPD-major      |    2.222|  2.023|  2.441| 0.000|
|ESI=10 excluded  |CT-based  |respiratory   |COPD-major      |   30.272| 17.369| 52.760| 0.000|
|ESI=10 excluded  |ESI-based |respiratory   |COPD-major      |   25.954| 15.695| 42.917| 0.000|
|ESI=10 excluded  |CT-based  |exacerbations |COPD-major      |    4.799|  4.355|  5.289| 0.000|
|ESI=10 excluded  |ESI-based |exacerbations |COPD-major      |    4.246|  3.863|  4.666| 0.000|
|4-criterion alt  |CT-based  |all-cause     |AFL-only-NoCOPD |    0.897|  0.622|  1.296| 0.564|
|4-criterion alt  |ESI-based |all-cause     |AFL-only-NoCOPD |    0.858|  0.702|  1.049| 0.136|
|4-criterion alt  |CT-based  |respiratory   |AFL-only-NoCOPD |    1.417|  0.185| 10.839| 0.737|
|4-criterion alt  |ESI-based |respiratory   |AFL-only-NoCOPD |    1.304|  0.440|  3.858| 0.632|
|4-criterion alt  |CT-based  |exacerbations |AFL-only-NoCOPD |    1.285|  0.945|  1.747| 0.110|
|4-criterion alt  |ESI-based |exacerbations |AFL-only-NoCOPD |    0.989|  0.824|  1.188| 0.908|
|4-criterion alt  |CT-based  |all-cause     |COPD-minor      |    1.907|  1.640|  2.218| 0.000|
|4-criterion alt  |ESI-based |all-cause     |COPD-minor      |    1.892|  1.515|  2.363| 0.000|
|4-criterion alt  |CT-based  |respiratory   |COPD-minor      |    4.804|  2.145| 10.760| 0.000|
|4-criterion alt  |ESI-based |respiratory   |COPD-minor      |    7.214|  2.853| 18.240| 0.000|
|4-criterion alt  |CT-based  |exacerbations |COPD-minor      |    2.718|  2.355|  3.137| 0.000|
|4-criterion alt  |ESI-based |exacerbations |COPD-minor      |    2.838|  2.292|  3.515| 0.000|
|4-criterion alt  |CT-based  |all-cause     |COPD-major      |    2.591|  2.351|  2.855| 0.000|
|4-criterion alt  |ESI-based |all-cause     |COPD-major      |    2.577|  2.353|  2.823| 0.000|
|4-criterion alt  |CT-based  |respiratory   |COPD-major      |   36.266| 20.852| 63.072| 0.000|
|4-criterion alt  |ESI-based |respiratory   |COPD-major      |   33.065| 20.594| 53.088| 0.000|
|4-criterion alt  |CT-based  |exacerbations |COPD-major      |    5.053|  4.593|  5.560| 0.000|
|4-criterion alt  |ESI-based |exacerbations |COPD-major      |    4.775|  4.350|  5.242| 0.000|
|severe exac only |CT-based  |exacerbations |AFL-only-NoCOPD |    1.293|  0.852|  1.960| 0.227|
|severe exac only |ESI-based |exacerbations |AFL-only-NoCOPD |    1.271|  0.727|  2.224| 0.400|
|severe exac only |CT-based  |exacerbations |COPD-minor      |    3.486|  2.911|  4.174| 0.000|
|severe exac only |ESI-based |exacerbations |COPD-minor      |    3.187|  2.560|  3.969| 0.000|
|severe exac only |CT-based  |exacerbations |COPD-major      |    6.520|  5.758|  7.383| 0.000|
|severe exac only |ESI-based |exacerbations |COPD-major      |    5.452|  4.835|  6.147| 0.000|

<!-- NOTE (2026-07-19): the PH-assumption diagnostics chunk that lived here has
been moved out of the main analysis / manuscript path.  A comprehensive
PH-robustness analysis (per-variable Schoenfeld tests, stratified sensitivities,
time-split analyses, framework-invariance checks) is maintained separately in
`esi_ph_robustness_analysis_2026.7.17.Rmd` and is held in reserve for
reviewer-response scenarios rather than surfaced in the manuscript body or its
supplement. -->

# Section 9 — Continuous ESI secondary analyses

Pooled and per-stratum continuous-ESI models for mortality, exacerbations, and
longitudinal FEV~1~ decline; identifies the GOLD 0 → 4.7 mL/yr signal cited in
the Results.


``` r
# ---- Section 9 rewrite (A6b.3): split continuous-ESI supplement into three
# per-metric tables so estimates on incompatible scales are never in one column.
# Old CSV Supp_Table_Continuous_AllCause.csv is written with a .OLD suffix and
# retired.

# Source cohort is d_b, the Bhatt-analytic cohort, matching the sibling
# continuous table (the GOLD 0 FEV1-decline models below) and every other
# table in the paper. Until 2026-08-25 this was built from `d`, the
# pre-completeness merge, which made S6a/S6b the only tables in the
# manuscript running on a different population (10,043 vs 9,400) with no n
# column to make that visible.
d_cont <- d_b %>%
  inner_join(vs %>% select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% select(pid, UCD_Resp), by = "pid") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0)) %>%
  filter(!is.na(stratum), !is.na(FEV1_FVC_post), !is.na(age_visit),
         !is.na(ATS_PackYears), !is.na(BMI))
d_cont$stratum <- relevel(d_cont$stratum, ref = "GOLD0")

# ---- S6a — Continuous ESI, mortality (Cox HR) ------------------------------
fit_cox_esi  <- function(ev) coxph(Surv(days_followed/365.25, ev) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = d_cont)
fit_cox_ff   <- function(ev) coxph(Surv(days_followed/365.25, ev) ~ FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = d_cont)
fit_cox_both <- function(ev) coxph(Surv(days_followed/365.25, ev) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = d_cont)

s6a_rows <- list()
for (o in c("all-cause", "respiratory")) {
  ev <- if (o == "all-cause") d_cont$vital_status else d_cont$event_resp
  me <- fit_cox_esi(ev); mf <- fit_cox_ff(ev); mb <- fit_cox_both(ev)
  lr <- anova(mf, mb)
  ee <- cox_row(me, "ESI_v1post");  ff <- cox_row(mf, "FF_per_0_1")
  eb <- cox_row(mb, "ESI_v1post");  fb <- cox_row(mb, "FF_per_0_1")
  s6a_rows[[length(s6a_rows) + 1]] <- data.frame(
    outcome = o, model = "ESI only",
    ESI_HR = fmt_hr(ee["HR"], ee["LCI"], ee["UCI"]), ESI_p = fmt_p(ee["p"]),
    FEV1FVC_HR = "-", FEV1FVC_p = "-",
    LR_vs_FEV1FVC_only = "-", stringsAsFactors = FALSE)
  s6a_rows[[length(s6a_rows) + 1]] <- data.frame(
    outcome = o, model = "FEV1/FVC only",
    ESI_HR = "-", ESI_p = "-",
    FEV1FVC_HR = fmt_hr(ff["HR"], ff["LCI"], ff["UCI"]), FEV1FVC_p = fmt_p(ff["p"]),
    LR_vs_FEV1FVC_only = "-", stringsAsFactors = FALSE)
  s6a_rows[[length(s6a_rows) + 1]] <- data.frame(
    outcome = o, model = "ESI + FEV1/FVC",
    ESI_HR = fmt_hr(eb["HR"], eb["LCI"], eb["UCI"]), ESI_p = fmt_p(eb["p"]),
    FEV1FVC_HR = fmt_hr(fb["HR"], fb["LCI"], fb["UCI"]), FEV1FVC_p = fmt_p(fb["p"]),
    LR_vs_FEV1FVC_only = sprintf("chi2=%.2f, df=1, p=%s",
                                 lr$Chisq[2], fmt_p(lr$`Pr(>|Chi|)`[2])),
    stringsAsFactors = FALSE)
}
s6a <- do.call(rbind, s6a_rows)
s6a$n_subj <- nrow(d_cont)
write.csv(s6a, file.path(OUT_DIR, "Table_S6a_continuous_mortality.csv"), row.names = FALSE)
kable(s6a, caption = "Supp Table S6a — Continuous ESI as a mortality predictor. Effect metric: HR per 1-unit ESI or per 0.1-unit FEV1/FVC.")
```



Table: Supp Table S6a — Continuous ESI as a mortality predictor. Effect metric: HR per 1-unit ESI or per 0.1-unit FEV1/FVC.

|outcome     |model          |ESI_HR           |ESI_p  |FEV1FVC_HR       |FEV1FVC_p |LR_vs_FEV1FVC_only       | n_subj|
|:-----------|:--------------|:----------------|:------|:----------------|:---------|:------------------------|------:|
|all-cause   |ESI only       |1.10 (1.07-1.13) |<0.001 |-                |-         |-                        |   9400|
|all-cause   |FEV1/FVC only  |-                |-      |0.83 (0.79-0.88) |<0.001    |-                        |   9400|
|all-cause   |ESI + FEV1/FVC |1.07 (1.02-1.12) |0.004  |0.93 (0.85-1.02) |0.101     |chi2=8.30, df=1, p=0.004 |   9400|
|respiratory |ESI only       |1.15 (1.10-1.20) |<0.001 |-                |-         |-                        |   9400|
|respiratory |FEV1/FVC only  |-                |-      |0.65 (0.58-0.72) |<0.001    |-                        |   9400|
|respiratory |ESI + FEV1/FVC |0.97 (0.89-1.05) |0.427  |0.60 (0.49-0.74) |<0.001    |chi2=0.63, df=1, p=0.427 |   9400|

``` r
# ---- S6b — Continuous ESI, exacerbations (negative-binomial IRR) -----------
ex_cont <- d_cont %>%
  inner_join(ex_raw %>% select(pid, Total_Exacerbations, Years_Followed), by = "pid") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0)

nb_esi_ex  <- glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont)
nb_ff_ex   <- glm.nb(Total_Exacerbations ~ FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont)
nb_both_ex <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont)
lr_ex <- anova(nb_ff_ex, nb_both_ex, test = "Chisq")

ee_x <- nb_row(nb_esi_ex,  "ESI_v1post"); ff_x <- nb_row(nb_ff_ex,   "FF_per_0_1")
eb_x <- nb_row(nb_both_ex, "ESI_v1post"); fb_x <- nb_row(nb_both_ex, "FF_per_0_1")

s6b <- data.frame(
  outcome = "exacerbations",
  model = c("ESI only", "FEV1/FVC only", "ESI + FEV1/FVC"),
  ESI_IRR     = c(fmt_hr(ee_x["IRR"], ee_x["LCI"], ee_x["UCI"]), "-",
                  fmt_hr(eb_x["IRR"], eb_x["LCI"], eb_x["UCI"])),
  ESI_p       = c(fmt_p(ee_x["p"]), "-", fmt_p(eb_x["p"])),
  FEV1FVC_IRR = c("-",
                  fmt_hr(ff_x["IRR"], ff_x["LCI"], ff_x["UCI"]),
                  fmt_hr(fb_x["IRR"], fb_x["LCI"], fb_x["UCI"])),
  FEV1FVC_p   = c("-", fmt_p(ff_x["p"]), fmt_p(fb_x["p"])),
  LR_vs_FEV1FVC_only = c("-", "-",
    sprintf("chi2=%.2f, df=1, p=%s",
            lr_ex$`LR stat.`[2], fmt_p(lr_ex$`Pr(Chi)`[2]))),
  stringsAsFactors = FALSE
)
s6b$n_subj <- nrow(ex_cont)
write.csv(s6b, file.path(OUT_DIR, "Table_S6b_continuous_exacerbations.csv"), row.names = FALSE)
kable(s6b, caption = "Supp Table S6b — Continuous ESI as an exacerbation predictor. Effect metric: IRR per 1-unit ESI or per 0.1-unit FEV1/FVC.")
```



Table: Supp Table S6b — Continuous ESI as an exacerbation predictor. Effect metric: IRR per 1-unit ESI or per 0.1-unit FEV1/FVC.

|outcome       |model          |ESI_IRR          |ESI_p  |FEV1FVC_IRR      |FEV1FVC_p |LR_vs_FEV1FVC_only       | n_subj|
|:-------------|:--------------|:----------------|:------|:----------------|:---------|:------------------------|------:|
|exacerbations |ESI only       |1.11 (1.07-1.15) |<0.001 |-                |-         |-                        |   8338|
|exacerbations |FEV1/FVC only  |-                |-      |0.79 (0.74-0.84) |<0.001    |-                        |   8338|
|exacerbations |ESI + FEV1/FVC |1.01 (0.96-1.06) |0.727  |0.80 (0.73-0.88) |<0.001    |chi2=0.12, df=1, p=0.730 |   8338|

``` r
# ---- Retire the old combined CSV (finding 3 filename migration) ------------
old <- file.path(OUT_DIR, "Supp_Table_Continuous_AllCause.csv")
if (file.exists(old)) file.rename(old, paste0(old, ".OLD"))
```


``` r
# GOLD 0 subgroup — the 4.7 mL/yr signal
# Fix item 6 (2026-07-17): restrict source cohort to d_b (Bhatt-analytic, n=9,402)
# for denominator consistency with the by-category analyses.
g0 <- fev1_long %>%
  inner_join(d_b %>% transmute(pid, ESI_baseline = ESI_v1post,
                               FEV1_FVC_baseline = FEV1_FVC_post,
                               stratum_baseline = stratum,
                               Height_CM = as.numeric(Height_CM),
                               gender_baseline = factor(gender),
                               race_baseline   = factor(race)),
             by = "pid") %>%
  filter(stratum_baseline == "GOLD0",
         !is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow),
         !is.na(ESI_baseline), !is.na(FEV1_FVC_baseline))

lmm_g0 <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_baseline + FEV1_FVC_baseline) +
                 Height_CM + age_visit + ATS_PackYears + SmokCigNow +
                 gender_baseline + race_baseline + (1 | pid),
               data = g0)
esi_int <- lmm_row(lmm_g0, "years_from_baseline:ESI_baseline")
cat(sprintf("GOLD 0: each 1-unit higher baseline ESI predicts %.1f mL/yr additional FEV1 decline (SE %.2f, p = %s)\n",
            esi_int["est"], esi_int["se"], fmt_p(esi_int["p"])))
```

```
## GOLD 0: each 1-unit higher baseline ESI predicts -4.7 mL/yr additional FEV1 decline (SE 1.47, p = 0.001)
```

``` r
writeLines(c(sprintf("gold0_esi_est=%.2f", esi_int["est"]),
             sprintf("gold0_esi_se=%.3f",  esi_int["se"]),
             sprintf("gold0_esi_p=%.3e",   esi_int["p"]),
             sprintf("gold0_n_subj=%d",    length(unique(g0$pid)))),
           file.path(OUT_DIR, "Supp_Table_Continuous_FEV1Decline_GOLD0.txt"))

# ---- S6c — Continuous ESI, longitudinal FEV1 decline (LME slope, mL/yr) ----
# For each of GOLD 0, PRISm, and the pooled cohort: fit LME with
# years_from_baseline * ESI_baseline (+ years_from_baseline * FEV1_FVC_baseline)
# so the interaction coefficient is the additional mL/yr per 1-unit ESI.
fit_lme_slope <- function(dat, with_ff = TRUE) {
  rhs_ff <- if (with_ff) " + years_from_baseline * FEV1_FVC_baseline" else ""
  f <- as.formula(paste0("FEV1_post_mL ~ years_from_baseline * ESI_baseline",
                         rhs_ff,
                         " + Height_CM + age_visit + ATS_PackYears + SmokCigNow +
                         gender_baseline + race_baseline + (1 | pid)"))
  lmer(f, data = dat)
}
extract_row <- function(fit, term) {
  co <- summary(fit)$coef
  if (!term %in% rownames(co)) return(c(est = NA, se = NA, p = NA))
  c(est = co[term, "Estimate"], se = co[term, "Std. Error"], p = co[term, "Pr(>|t|)"])
}

# Reuse the g0 (GOLD 0, Bhatt-analytic) dataframe built just above.
# For PRISm we need the analog:
prism <- fev1_long %>%
  inner_join(d_b %>% transmute(pid, ESI_baseline = ESI_v1post,
                               FEV1_FVC_baseline = FEV1_FVC_post,
                               stratum_baseline = stratum,
                               Height_CM = as.numeric(Height_CM),
                               gender_baseline = factor(gender),
                               race_baseline   = factor(race)),
             by = "pid") %>%
  filter(stratum_baseline == "PRISm",
         !is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow),
         !is.na(ESI_baseline), !is.na(FEV1_FVC_baseline))
pooled <- fev1_long %>%
  inner_join(d_b %>% transmute(pid, ESI_baseline = ESI_v1post,
                               FEV1_FVC_baseline = FEV1_FVC_post,
                               stratum_baseline = stratum,
                               Height_CM = as.numeric(Height_CM),
                               gender_baseline = factor(gender),
                               race_baseline   = factor(race)),
             by = "pid") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow),
         !is.na(ESI_baseline), !is.na(FEV1_FVC_baseline))

s6c_rows <- list()
for (nm in c("GOLD 0", "PRISm", "pooled")) {
  dat <- switch(nm, "GOLD 0" = g0, "PRISm" = prism, "pooled" = pooled)
  n_subj <- length(unique(dat$pid))
  # Two models: (1) ESI-only slope (no FF adjustment), (2) both slopes
  fit1 <- fit_lme_slope(dat, with_ff = FALSE)
  fit2 <- fit_lme_slope(dat, with_ff = TRUE)
  e1 <- extract_row(fit1, "years_from_baseline:ESI_baseline")
  e2 <- extract_row(fit2, "years_from_baseline:ESI_baseline")
  f2 <- extract_row(fit2, "years_from_baseline:FEV1_FVC_baseline")
  s6c_rows[[length(s6c_rows) + 1]] <- data.frame(
    stratum = nm, n_subj = n_subj, model = "ESI only",
    ESI_slope_mL_yr = sprintf("%.2f (SE %.2f)", e1["est"], e1["se"]),
    ESI_p = fmt_p(e1["p"]),
    FEV1FVC_slope_mL_yr = "-",
    FEV1FVC_p = "-",
    stringsAsFactors = FALSE
  )
  s6c_rows[[length(s6c_rows) + 1]] <- data.frame(
    stratum = nm, n_subj = n_subj, model = "ESI + FEV1/FVC",
    ESI_slope_mL_yr = sprintf("%.2f (SE %.2f)", e2["est"], e2["se"]),
    ESI_p = fmt_p(e2["p"]),
    FEV1FVC_slope_mL_yr = sprintf("%.2f (SE %.2f)", f2["est"], f2["se"]),
    FEV1FVC_p = fmt_p(f2["p"]),
    stringsAsFactors = FALSE
  )
}
s6c <- do.call(rbind, s6c_rows)
write.csv(s6c, file.path(OUT_DIR, "Table_S6c_continuous_fev1_decline.csv"), row.names = FALSE)
kable(s6c, caption = "Supp Table S6c — Continuous ESI as a longitudinal FEV1-decline predictor. Effect metric: mL per year per 1-unit ESI (or per 0.1-unit FEV1/FVC).")
```



Table: Supp Table S6c — Continuous ESI as a longitudinal FEV1-decline predictor. Effect metric: mL per year per 1-unit ESI (or per 0.1-unit FEV1/FVC).

|stratum | n_subj|model          |ESI_slope_mL_yr |ESI_p  |FEV1FVC_slope_mL_yr |FEV1FVC_p |
|:-------|------:|:--------------|:---------------|:------|:-------------------|:---------|
|GOLD 0  |   4054|ESI only       |-5.38 (SE 1.44) |<0.001 |-                   |-         |
|GOLD 0  |   4054|ESI + FEV1/FVC |-4.73 (SE 1.47) |0.001  |29.93 (SE 11.18)    |0.007     |
|PRISm   |   1129|ESI only       |-1.69 (SE 3.61) |0.639  |-                   |-         |
|PRISm   |   1129|ESI + FEV1/FVC |2.01 (SE 3.80)  |0.597  |66.64 (SE 27.18)    |0.014     |
|pooled  |   9402|ESI only       |0.43 (SE 0.29)  |0.139  |-                   |-         |
|pooled  |   9402|ESI + FEV1/FVC |2.49 (SE 0.54)  |<0.001 |20.11 (SE 6.18)     |0.001     |

``` r
# (Removed 2026-08-25: this block renamed the GOLD-0 sidecar to ".OLD", but
# that file is written earlier in this same chunk, so every run retired its own
# current output and the second run overwrote the previous ".OLD".)
```

# Section 10 — Bronchodilator ΔESI

Mean within-subject change in ESI between pre- and post-bronchodilator
measurements at Visit 1 — reproduces the −0.09 value cited in the manuscript.


``` r
esi_pair <- esi_raw %>%
  filter(visitnum == 1, PrePost %in% c(0, 1)) %>%
  group_by(pid, PrePost) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = PrePost, values_from = ESI, names_prefix = "ESI_") %>%
  filter(!is.na(ESI_0), !is.na(ESI_1))

mean_delta <- mean(esi_pair$ESI_1 - esi_pair$ESI_0)
sd_delta   <- sd(  esi_pair$ESI_1 - esi_pair$ESI_0)

cat(sprintf("Bronchodilator ΔESI: mean = %.2f, SD = %.2f (n = %d paired)\n",
            mean_delta, sd_delta, nrow(esi_pair)))
```

```
## Bronchodilator ΔESI: mean = -0.09, SD = 0.86 (n = 10160 paired)
```

``` r
writeLines(c(sprintf("n_paired=%d",     nrow(esi_pair)),
             sprintf("mean_delta=%.4f", mean_delta),
             sprintf("sd_delta=%.4f",   sd_delta)),
           file.path(OUT_DIR, "Supp_Bronchodilator_deltaESI.txt"))
```

# Section 11 — PRISm vs GOLD 0 longitudinal ESI trajectory (Supp Table S7)


``` r
esi_long <- esi_raw %>%
  filter(visitnum %in% c(1, 2, 3), PrePost == 1) %>%
  group_by(pid, visitnum) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")

esi_baseline <- esi_long %>% filter(visitnum == 1) %>% select(pid, ESI_v1 = ESI)
delta_esi <- esi_long %>%
  filter(visitnum > 1) %>%
  inner_join(esi_baseline, by = "pid") %>%
  mutate(dESI = ESI - ESI_v1) %>%
  inner_join(d %>% select(pid, stratum_baseline = stratum), by = "pid") %>%
  filter(stratum_baseline %in% c("GOLD0", "PRISm"))

traj_summary <- delta_esi %>%
  group_by(stratum_baseline, visitnum) %>%
  summarise(n = n(), mean_dESI = mean(dESI, na.rm = TRUE),
            median_dESI = median(dESI, na.rm = TRUE), .groups = "drop")
write.csv(traj_summary, file.path(OUT_DIR, "Supp_Table_S7_ESI_trajectory.csv"), row.names = FALSE)
kable(traj_summary, digits = 3, caption = "Longitudinal ΔESI by baseline stratum (GOLD 0 vs PRISm).")
```



Table: Longitudinal ΔESI by baseline stratum (GOLD 0 vs PRISm).

|stratum_baseline | visitnum|    n| mean_dESI| median_dESI|
|:----------------|--------:|----:|---------:|-----------:|
|GOLD0            |        2| 2525|     0.012|        0.00|
|GOLD0            |        3|  950|     0.051|        0.01|
|PRISm            |        2|  660|     0.105|        0.04|
|PRISm            |        3|  208|     0.232|        0.06|

# Section 12 — Figures produced from the tables above

`Figure_3_Discordance.png` (a.k.a. Figure 2 in the v8 manuscript) is built
directly from `Table_Discordance.csv` written in Section 5.


``` r
disc <- read.csv(file.path(OUT_DIR, "Table_Discordance.csv"), stringsAsFactors = FALSE, check.names = FALSE)

mean_of <- function(x) as.numeric(sub("\\s*\\(.*", "", x))
pct_of  <- function(x) as.numeric(sub("%", "", x))
disc_num <- disc %>% mutate(
  ESI     = mean_of(ESI),      LAA950  = mean_of(LAA950),
  emph    = pct_of(pct_emph),  wall    = pct_of(pct_wall),
  mMRC2p  = pct_of(pct_mMRC2p), SGRQ25p = pct_of(pct_SGRQ25p),
  CB      = pct_of(pct_CB)
)
lvl <- c("CT-only-COPD (ESI missed)", "Both-COPD", "ESI-only-COPD (Bhatt missed)")
disc_num$grp_5 <- factor(disc_num$grp_5, levels = lvl)
# Look the n up BY NAME. disc_num arrives in group_by() alphabetical order
# (Both-COPD, CT-only, ESI-only), not in `lvl` order, so indexing n[1..3]
# positionally paired each label with the wrong group's count.
n_of <- setNames(disc_num$n, as.character(disc_num$grp_5))
stopifnot(setequal(names(n_of), lvl))   # real guard: names come from the data
lab <- c("CT-only-COPD (ESI missed)"     = "CT-only",
         "Both-COPD"                     = "Both",
         "ESI-only-COPD (Bhatt missed)"  = "ESI-only")
short_of <- setNames(sprintf("%s\n(n=%d)", lab[lvl], n_of[lvl]), lvl)
disc_num$grp_short <- unname(short_of[as.character(disc_num$grp_5)])
disc_num$grp_short <- factor(disc_num$grp_short,
  levels = c(sprintf("CT-only\n(n=%d)", disc_num$n[1]),
             sprintf("Both\n(n=%d)",       disc_num$n[2]),
             sprintf("ESI-only\n(n=%d)",   disc_num$n[3])))

cont <- disc_num %>% select(grp_short, ESI, LAA950) %>%
  pivot_longer(-grp_short, names_to = "feature", values_to = "value") %>%
  mutate(feature = recode(feature, ESI = "ESI", LAA950 = "%LAA-950HU"))
cont$feature <- factor(cont$feature, levels = c("ESI", "%LAA-950HU"))

pct <- disc_num %>% select(grp_short, emph, wall, mMRC2p, SGRQ25p, CB) %>%
  pivot_longer(-grp_short, names_to = "feature", values_to = "value") %>%
  mutate(feature = recode(feature,
    emph    = "Visual emphysema (any)",
    wall    = "Visual wall thickening",
    mMRC2p  = "mMRC >= 2",
    SGRQ25p = "SGRQ >= 25",
    CB      = "Chronic bronchitis"))
pct$feature <- factor(pct$feature, levels = c(
  "Visual emphysema (any)", "Visual wall thickening",
  "mMRC >= 2", "SGRQ >= 25", "Chronic bronchitis"))

pal <- setNames(c("#1F77B4", "#7F7F7F", "#D62728"), levels(disc_num$grp_short))

p_cont <- ggplot(cont, aes(x = grp_short, y = value, fill = grp_short)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", value)), vjust = -0.4, size = 3.1) +
  facet_wrap(~ feature, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = NULL, y = "Mean")

p_pct <- ggplot(pct, aes(x = grp_short, y = value, fill = grp_short)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.0f%%", value)), vjust = -0.4, size = 3.1) +
  facet_wrap(~ feature, ncol = 5, scales = "fixed") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_y_continuous(limits = c(0, 105), expand = expansion(mult = c(0, 0))) +
  labs(x = NULL, y = "% of subgroup")

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  fig_disc <- (p_cont / p_pct) + plot_layout(heights = c(1, 1.15))
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance.png"),
         fig_disc, width = 11, height = 7, dpi = 300)
} else {
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance_cont.png"), p_cont, width = 6, height = 3.2, dpi = 300)
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance_pct.png"),  p_pct,  width = 11, height = 3.5, dpi = 300)
}
```

# Section 13 — Self-check (canonical values echoed for drift detection)

Each row prints the freshly-computed value alongside the value cited in the
manuscript (`expected`).  Rerunning this report on the cluster should reproduce
the `expected` column exactly (within rounding).


``` r
selfcheck <- function(name, computed, expected, tol = 0.02) {
  # A missing lookup (e.g. a stratum that no longer exists) yields NA, and
  # `abs(NA - x) < tol` is NA, so the row used to render as status NA and the
  # PASS/FAIL tallies below both printed NA. A check that cannot be evaluated
  # is a FAIL, not a blank.
  ok <- if (is.numeric(computed) && is.numeric(expected)) {
          isTRUE(abs(computed - expected) < tol)
        } else identical(computed, expected)
  data.frame(check = name,
             computed = if (is.numeric(computed)) sprintf("%.3f", computed) else as.character(computed),
             expected = if (is.numeric(expected)) sprintf("%.3f", expected) else as.character(expected),
             status   = ifelse(ok, "PASS", "FAIL"),
             stringsAsFactors = FALSE)
}

# Expectations below are baselined to the ILD/Bronchiectasis-excluded cohort
# and were confirmed identical on two independent machines (this workstation
# and the Channing cluster).  Two cohorts are checked separately: the
# ESI-merged cohort before the Bhatt-criteria completeness filter (d) and the
# analytic cohort after it (d_b).  The manuscript quotes the d_b values; the
# d values are carried as drift detectors only.
n_gold_d   <- d   %>% filter(!is.na(stratum)) %>% count(stratum) %>% tibble::deframe()
n_gold_d_b <- d_b %>% filter(!is.na(stratum)) %>% count(stratum) %>% tibble::deframe()

checks <- list(
  selfcheck("n analytic cohort (d_b, Bhatt-complete)", nrow(d_b), 9402),
  # ---- Manuscript quoted breakdown (matches the pre-filter d cohort) ------
  selfcheck("n never-smokers (d, pre-filter)",   as.integer(n_gold_d["Never"]),   106),
  selfcheck("n GOLD 0 (d, pre-filter)",          as.integer(n_gold_d["GOLD0"]),   4308),
  selfcheck("n PRISm (d, pre-filter)",           as.integer(n_gold_d["PRISm"]),   1238),
  selfcheck("n GOLD 1-4 (d, pre-filter)",        as.integer(sum(n_gold_d[c("GOLD1","GOLD2","GOLD3","GOLD4")])), 4394),
  # ---- Actual breakdown of the 9,402 analytic cohort (for manuscript fix) --
  selfcheck("n never-smokers (analytic, correct)", as.integer(n_gold_d_b["Never"]), 106),
  selfcheck("n GOLD 0 (analytic, correct)",        as.integer(n_gold_d_b["GOLD0"]), 4054),
  selfcheck("n PRISm (analytic, correct)",         as.integer(n_gold_d_b["PRISm"]), 1129),
  selfcheck("n GOLD 1-4 (analytic, correct)",      as.integer(sum(n_gold_d_b[c("GOLD1","GOLD2","GOLD3","GOLD4")])), 4113),
  selfcheck("agreement (%)",           100 * overall_agreement,                  91.0, tol = 0.6),
  selfcheck("kappa",                   kappa_v,                                  0.82, tol = 0.02),
  selfcheck("sensitivity (%)",         100 * sensitivity_v,                      88.0, tol = 1.0),
  selfcheck("specificity (%)",         100 * specificity_v,                      94.0, tol = 1.0),
  selfcheck("r(ESI, LAA-950) all-strata", t2_all$r_LAA,                          0.77, tol = 0.02),
  selfcheck("r(ESI, LAA-950) GOLD 0",     t2$r_LAA[t2$stratum == "GOLD0"],       0.08, tol = 0.02),
  selfcheck("r(ESI, LAA-950) GOLD 3",     t2$r_LAA[t2$stratum == "GOLD3"],       0.58, tol = 0.02),
  selfcheck("ΔESI (post-pre) mean",       mean_delta,                            -0.09, tol = 0.02),
  selfcheck("GOLD 0 ESI-slope (mL/yr)",   esi_int["est"],                         -4.7, tol = 0.5),
  selfcheck("COPD-major all-cause HR (CT)",  t8_all$bhatt_HR[t8_all$group == "COPD-major"], 2.59, tol = 0.02),
  selfcheck("COPD-major all-cause HR (ESI)", t8_all$esi_HR[t8_all$group == "COPD-major"],   2.39, tol = 0.02),
  selfcheck("COPD-major resp HR (CT)",       t8_resp$bhatt_HR[t8_resp$group == "COPD-major"], 36.27, tol = 0.25),
  selfcheck("COPD-major resp HR (ESI)",      t8_resp$esi_HR[t8_resp$group == "COPD-major"],   30.95, tol = 0.25),
  selfcheck("COPD-major exac IRR (CT)",      t_bhatt_ex$bhatt_IRR[t_bhatt_ex$group == "COPD-major"], 5.07, tol = 0.05),
  selfcheck("COPD-major exac IRR (ESI)",     t_bhatt_ex$esi_IRR[t_bhatt_ex$group == "COPD-major"],   4.47, tol = 0.05),
  selfcheck("Both-COPD all-cause HR",  t_grp_mort$all_HR[t_grp_mort$group  == "Both-COPD"],                    2.02, tol = 0.02),
  selfcheck("CT-only all-cause HR", t_grp_mort$all_HR[t_grp_mort$group  == "CT-only-COPD (ESI missed)"], 1.53, tol = 0.02),
  selfcheck("ESI-only all-cause HR",   t_grp_mort$all_HR[t_grp_mort$group  == "ESI-only-COPD (Bhatt missed)"], 1.26, tol = 0.03),
  selfcheck("ESI-only CVD HR",         t_cs_disc$HR[t_cs_disc$cause == "CVD" & t_cs_disc$group == "ESI-only-COPD"], 2.29, tol = 0.05),
  selfcheck("Both-COPD exac IRR",      t_disc_ex$IRR[t_disc_ex$group == "Both-COPD"],                              3.17, tol = 0.05)
)
selfcheck_tbl <- do.call(rbind, checks)
write.csv(selfcheck_tbl, file.path(OUT_DIR, "SELFCHECK.csv"), row.names = FALSE)
kable(selfcheck_tbl, caption = "Self-check — computed vs manuscript-cited values.")
```



Table: Self-check — computed vs manuscript-cited values.

|check                                   |computed |expected |status |
|:---------------------------------------|:--------|:--------|:------|
|n analytic cohort (d_b, Bhatt-complete) |9402.000 |9402.000 |PASS   |
|n never-smokers (d, pre-filter)         |106.000  |106.000  |PASS   |
|n GOLD 0 (d, pre-filter)                |4308.000 |4308.000 |PASS   |
|n PRISm (d, pre-filter)                 |1238.000 |1238.000 |PASS   |
|n GOLD 1-4 (d, pre-filter)              |4394.000 |4394.000 |PASS   |
|n never-smokers (analytic, correct)     |106.000  |106.000  |PASS   |
|n GOLD 0 (analytic, correct)            |4054.000 |4054.000 |PASS   |
|n PRISm (analytic, correct)             |1129.000 |1129.000 |PASS   |
|n GOLD 1-4 (analytic, correct)          |4113.000 |4113.000 |PASS   |
|agreement (%)                           |91.023   |91.000   |PASS   |
|kappa                                   |0.821    |0.820    |PASS   |
|sensitivity (%)                         |88.049   |88.000   |PASS   |
|specificity (%)                         |94.443   |94.000   |PASS   |
|r(ESI, LAA-950) all-strata              |0.779    |0.770    |PASS   |
|r(ESI, LAA-950) GOLD 0                  |0.080    |0.080    |PASS   |
|r(ESI, LAA-950) GOLD 3                  |0.577    |0.580    |PASS   |
|ΔESI (post-pre) mean                    |-0.089   |-0.090   |PASS   |
|GOLD 0 ESI-slope (mL/yr)                |-4.733   |-4.700   |PASS   |
|COPD-major all-cause HR (CT)            |2.591    |2.590    |PASS   |
|COPD-major all-cause HR (ESI)           |2.395    |2.390    |PASS   |
|COPD-major resp HR (CT)                 |36.266   |36.270   |PASS   |
|COPD-major resp HR (ESI)                |30.952   |30.950   |PASS   |
|COPD-major exac IRR (CT)                |5.053    |5.070    |PASS   |
|COPD-major exac IRR (ESI)               |4.468    |4.470    |PASS   |
|Both-COPD all-cause HR                  |2.024    |2.020    |PASS   |
|CT-only all-cause HR                    |1.530    |1.530    |PASS   |
|ESI-only all-cause HR                   |1.257    |1.260    |PASS   |
|ESI-only CVD HR                         |2.290    |2.290    |PASS   |
|Both-COPD exac IRR                      |3.148    |3.170    |PASS   |

``` r
cat(sprintf("\nSelf-check summary: %d PASS, %d FAIL (of %d total)\n",
            sum(selfcheck_tbl$status == "PASS"),
            sum(selfcheck_tbl$status == "FAIL"),
            nrow(selfcheck_tbl)))
```

```
## 
## Self-check summary: 29 PASS, 0 FAIL (of 29 total)
```

# Section 14 — Completeness check for Phase C (A7b)

Enumerates every CSV the v10 supplement build depends on and aborts if any is
missing. Prevents Phase C from starting on a partially-run Rmd.


``` r
required_csvs <- c(
  # Main assets (v9 baseline; still consumed by Phase B)
  "Table_2.csv",
  "Table_6.csv",
  "Table_Agreement_stats.txt",
  "Table_Discordance.csv",
  "Table_8_allcause.csv",
  "Table_8_resp.csv",
  "Table_8_stats.txt",
  "Table_Exacerbations_Bhatt.csv",
  "Table_Exacerbations_Bhatt_stats.txt",
  "Table_BhattOnly_vs_Both.csv",
  "Table_CauseSpecific_byDiscord.csv",
  "Table_Exacerbations_Discordance.csv",
  "Table_FEV1Decline_byDiscord.csv",
  # New Phase A outputs consumed by v10 (both manuscript + supplement)
  "Table_1_Cindex_Equivalence.csv",             # A2 — Table 1 footnote
  "Supp_Table_HR_Difference_Bootstrap.csv",     # A3 — Supp Table S8
  "Table_S8_bootstrap_diagnostics.txt",         # A3 sidecar
  "Table_2_pairwise_contrasts.csv",             # A4 — Table 2 footnote + S9
  "Supp_Table_Thresholds.csv",                  # S1
  "Table_S2_baseline_characteristics.csv",      # S2 (A6b.1)
  "Table_S3_sensitivity.csv",                   # S3 (A6b.2)
  "Table_CauseSpecific_byClass.csv",            # S4
  "Table_BhattDecline.csv",                     # S5
  "Table_S6a_continuous_mortality.csv",         # S6a (A6b.3)
  "Table_S6b_continuous_exacerbations.csv",     # S6b (A6b.3)
  "Table_S6c_continuous_fev1_decline.csv",      # S6c (A6b.3)
  "Supp_Table_S7_ESI_trajectory.csv",           # S7
  # Figures
  "Figure_Bhatt_StackedBars.png",
  "Figure_3_Discordance.png"
)
missing <- required_csvs[!file.exists(file.path(OUT_DIR, required_csvs))]
if (length(missing) > 0) {
  cat("MISSING:\n"); cat(paste0("  - ", missing, "\n"))
  stop(sprintf("Phase C blocked: %d required file(s) missing. See list above.",
               length(missing)))
} else {
  cat(sprintf("Completeness check PASS: all %d required files present.\n",
              length(required_csvs)))
}
```

```
## Completeness check PASS: all 28 required files present.
```

# Section 12 — Covariate-sensitivity robustness check

Every reported association is refit with the minimal covariate set (age + sex
+ race only) and compared to the primary adjustment set to identify any
estimate whose statistical significance flips at p = 0.05 or whose direction
of effect changes. This chunk exists solely to render the comparison in the
HTML report; no CSV or supplement table is written.


``` r
# --- helpers (local; do not disturb the earlier `cox_row` / `nb_row`) ---
cs_cox <- function(fit, term) {
  s  <- summary(fit); r <- s$coefficients[term, ]; ci <- s$conf.int[term, ]
  c(est = unname(ci["exp(coef)"]), LCI = unname(ci["lower .95"]),
    UCI = unname(ci["upper .95"]), p = unname(r["Pr(>|z|)"]))
}
cs_nb <- function(fit, term) {
  s  <- summary(fit); est <- coef(fit)[term]
  se <- s$coefficients[term, "Std. Error"]; p <- s$coefficients[term, "Pr(>|z|)"]
  c(est = unname(exp(est)), LCI = unname(exp(est - 1.96*se)),
    UCI = unname(exp(est + 1.96*se)), p = unname(p))
}
cs_lmm <- function(fit, term) {
  co <- summary(fit)$coefficients
  est <- co[term, "Estimate"]; se <- co[term, "Std. Error"]; p <- co[term, "Pr(>|t|)"]
  c(est = unname(est), LCI = unname(est - 1.96*se), UCI = unname(est + 1.96*se), p = unname(p))
}
cs_add <- function(reg, table, model, term, full, min_, scale = "HR") {
  sig_f <- !is.na(full["p"]) && full["p"] < 0.05
  sig_m <- !is.na(min_["p"]) && min_["p"] < 0.05
  null_val <- if (scale %in% c("HR","IRR")) 1 else 0
  dir_f <- sign(full["est"] - null_val); dir_m <- sign(min_["est"] - null_val)
  crosses <- sig_f != sig_m
  # Direction change requires BOTH estimates to be significant, so near-null
  # estimates that wobble across the null value (e.g., IRR 1.007 vs 0.978,
  # both p > 0.5) are not flagged.
  dchange <- sig_f && sig_m && !is.na(dir_f) && !is.na(dir_m) &&
              dir_f != dir_m && dir_f != 0 && dir_m != 0
  rbind(reg, data.frame(
    table = table, model = model, term = term, scale = scale,
    est_full = unname(full["est"]), LCI_full = unname(full["LCI"]),
    UCI_full = unname(full["UCI"]), p_full = unname(full["p"]),
    est_min  = unname(min_["est"]),  LCI_min = unname(min_["LCI"]),
    UCI_min  = unname(min_["UCI"]),  p_min  = unname(min_["p"]),
    p_crosses_05 = crosses, direction_change = dchange,
    sensitive = crosses || dchange, stringsAsFactors = FALSE))
}
cs_reg <- data.frame()

# --- datasets (reuse mort_b / ex_b / d_cont from earlier sections when in scope) ---
cs_mort <- d_b %>%
  inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp, UCD_CVD, UCD_Cancer, UCD_Other), by = "pid") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0))
cs_mortF <- cs_mort %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
cs_mortM <- cs_mort %>% filter(complete.cases(age_visit, gender, race))
cs_ex <- d_b %>%
  inner_join(ex_raw %>% dplyr::select(pid, Total_Exacerbations, Years_Followed), by = "pid") %>%
  filter(!is.na(Total_Exacerbations), !is.na(Years_Followed), Years_Followed > 0)
cs_exF <- cs_ex %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
cs_exM <- cs_ex %>% filter(complete.cases(age_visit, gender, race))

groups3 <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")
discords <- c("Both-COPD","CT-only-COPD","ESI-only-COPD")

# Table 1
cB_a_F <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cE_a_F <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cB_r_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cE_r_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cB_a_M <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race, data = cs_mortM)
cE_a_M <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race, data = cs_mortM)
cB_r_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race, data = cs_mortM)
cE_r_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race, data = cs_mortM)
for (g in groups3) {
  cs_reg <- cs_add(cs_reg, "Table 1","all-cause CT",  g, cs_cox(cB_a_F, paste0("bhatt_grp",g)), cs_cox(cB_a_M, paste0("bhatt_grp",g)))
  cs_reg <- cs_add(cs_reg, "Table 1","all-cause ESI", g, cs_cox(cE_a_F, paste0("esi_grp",  g)), cs_cox(cE_a_M, paste0("esi_grp",  g)))
  cs_reg <- cs_add(cs_reg, "Table 1","respiratory CT", g, cs_cox(cB_r_F, paste0("bhatt_grp",g)), cs_cox(cB_r_M, paste0("bhatt_grp",g)))
  cs_reg <- cs_add(cs_reg, "Table 1","respiratory ESI",g, cs_cox(cE_r_F, paste0("esi_grp",  g)), cs_cox(cE_r_M, paste0("esi_grp",  g)))
}
nB_e_F <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = cs_exF)
nE_e_F <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = cs_exF)
nB_e_M <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + offset(log(Years_Followed)), data = cs_exM)
nE_e_M <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + offset(log(Years_Followed)), data = cs_exM)
for (g in groups3) {
  cs_reg <- cs_add(cs_reg, "Table 1","exacerbations CT", g, cs_nb(nB_e_F, paste0("bhatt_grp",g)), cs_nb(nB_e_M, paste0("bhatt_grp",g)), scale="IRR")
  cs_reg <- cs_add(cs_reg, "Table 1","exacerbations ESI",g, cs_nb(nE_e_F, paste0("esi_grp",  g)), cs_nb(nE_e_M, paste0("esi_grp",  g)), scale="IRR")
}

# Table 2 (cross-classification)
cD_a_F <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cD_r_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
cD_a_M <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race, data = cs_mortM)
cD_r_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race, data = cs_mortM)
nD_e_F <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = cs_exF)
nD_e_M <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + offset(log(Years_Followed)), data = cs_exM)
for (g in discords) {
  cs_reg <- cs_add(cs_reg, "Table 2","all-cause",  g, cs_cox(cD_a_F, paste0("discord",g)), cs_cox(cD_a_M, paste0("discord",g)))
  cs_reg <- cs_add(cs_reg, "Table 2","respiratory",g, cs_cox(cD_r_F, paste0("discord",g)), cs_cox(cD_r_M, paste0("discord",g)))
  cs_reg <- cs_add(cs_reg, "Table 2","exacerbations",g, cs_nb(nD_e_F, paste0("discord",g)), cs_nb(nD_e_M, paste0("discord",g)), scale="IRR")
}

# S3a: ESI = 10 excluded
m_neF <- cs_mortF %>% filter(ESI_v1post < 10); m_neM <- cs_mortM %>% filter(ESI_v1post < 10)
e_neF <- cs_exF   %>% filter(ESI_v1post < 10); e_neM <- cs_exM   %>% filter(ESI_v1post < 10)
xB_a_F <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = m_neF)
xE_a_F <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = m_neF)
xB_r_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = m_neF)
xE_r_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = m_neF)
xB_a_M <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race, data = m_neM)
xE_a_M <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race, data = m_neM)
xB_r_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race, data = m_neM)
xE_r_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race, data = m_neM)
xnB_F  <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = e_neF)
xnE_F  <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = e_neF)
xnB_M  <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + offset(log(Years_Followed)), data = e_neM)
xnE_M  <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + offset(log(Years_Followed)), data = e_neM)
for (g in groups3) {
  cs_reg <- cs_add(cs_reg, "S3a","all-cause CT",  g, cs_cox(xB_a_F, paste0("bhatt_grp",g)), cs_cox(xB_a_M, paste0("bhatt_grp",g)))
  cs_reg <- cs_add(cs_reg, "S3a","all-cause ESI", g, cs_cox(xE_a_F, paste0("esi_grp",  g)), cs_cox(xE_a_M, paste0("esi_grp",  g)))
  cs_reg <- cs_add(cs_reg, "S3a","respiratory CT", g, cs_cox(xB_r_F, paste0("bhatt_grp",g)), cs_cox(xB_r_M, paste0("bhatt_grp",g)))
  cs_reg <- cs_add(cs_reg, "S3a","respiratory ESI",g, cs_cox(xE_r_F, paste0("esi_grp",  g)), cs_cox(xE_r_M, paste0("esi_grp",  g)))
  cs_reg <- cs_add(cs_reg, "S3a","exacerbations CT", g, cs_nb(xnB_F, paste0("bhatt_grp",g)), cs_nb(xnB_M, paste0("bhatt_grp",g)), scale="IRR")
  cs_reg <- cs_add(cs_reg, "S3a","exacerbations ESI",g, cs_nb(xnE_F, paste0("esi_grp",  g)), cs_nb(xnE_M, paste0("esi_grp",  g)), scale="IRR")
}

# S4a/b/c: cause-specific mortality
cs_mk <- function(df, col) ifelse(df$vital_status == 1 & !is.na(df[[col]]) & df[[col]] == 1, 1, 0)
cause_cols <- c("UCD_CVD","UCD_Cancer","UCD_Other")
cause_labs <- c("S4a CVD","S4b Cancer","S4c Other")
for (i in seq_along(cause_cols)) {
  ev_F <- cs_mk(cs_mortF, cause_cols[i]); ev_M <- cs_mk(cs_mortM, cause_cols[i])
  qB_F <- coxph(Surv(days_followed/365.25, ev_F) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
  qE_F <- coxph(Surv(days_followed/365.25, ev_F) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = cs_mortF)
  qB_M <- coxph(Surv(days_followed/365.25, ev_M) ~ bhatt_grp + age_visit + gender + race, data = cs_mortM)
  qE_M <- coxph(Surv(days_followed/365.25, ev_M) ~ esi_grp   + age_visit + gender + race, data = cs_mortM)
  for (g in groups3) {
    cs_reg <- cs_add(cs_reg, cause_labs[i],"cause-spec CT",  g, cs_cox(qB_F, paste0("bhatt_grp",g)), cs_cox(qB_M, paste0("bhatt_grp",g)))
    cs_reg <- cs_add(cs_reg, cause_labs[i],"cause-spec ESI", g, cs_cox(qE_F, paste0("esi_grp",  g)), cs_cox(qE_M, paste0("esi_grp",  g)))
  }
}

# S6a/b/c: continuous ESI
cs_dcont <- d_b %>% mutate(FF_per_0_1 = FEV1_FVC_post / 0.1)
cs_mortC <- cs_dcont %>%
  inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp), by = "pid") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0))
cs_mortCF <- cs_mortC %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears))
cs_mortCM <- cs_mortC %>% filter(complete.cases(age_visit, gender, race))
cs_exC <- cs_dcont %>%
  inner_join(ex_raw %>% dplyr::select(pid, Total_Exacerbations, Years_Followed), by = "pid") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0)
cs_exCF <- cs_exC %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears))
cs_exCM <- cs_exC %>% filter(complete.cases(age_visit, gender, race))

for (spec in list(
    list(tab="S6a", out="vital_status", model_alone="cont ESI alone",  model_joint="cont ESI + FEV1/FVC", data_F=cs_mortCF, data_M=cs_mortCM, fitter="cox"),
    list(tab="S6b", out="event_resp",   model_alone="cont ESI alone",  model_joint="cont ESI + FEV1/FVC", data_F=cs_mortCF, data_M=cs_mortCM, fitter="cox"),
    list(tab="S6c", out="Total_Exacerbations", model_alone="cont ESI alone", model_joint="cont ESI + FEV1/FVC", data_F=cs_exCF, data_M=cs_exCM, fitter="nb"))) {
  if (spec$fitter == "cox") {
    fA_F <- coxph(as.formula(paste("Surv(days_followed/365.25,", spec$out, ") ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum")), data = spec$data_F)
    fA_M <- coxph(as.formula(paste("Surv(days_followed/365.25,", spec$out, ") ~ ESI_v1post + age_visit + gender + race")), data = spec$data_M)
    fJ_F <- coxph(as.formula(paste("Surv(days_followed/365.25,", spec$out, ") ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum")), data = spec$data_F)
    fJ_M <- coxph(as.formula(paste("Surv(days_followed/365.25,", spec$out, ") ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race")), data = spec$data_M)
    cs_reg <- cs_add(cs_reg, spec$tab, spec$model_alone, "ESI_v1post", cs_cox(fA_F,"ESI_v1post"), cs_cox(fA_M,"ESI_v1post"))
    cs_reg <- cs_add(cs_reg, spec$tab, spec$model_joint, "ESI_v1post", cs_cox(fJ_F,"ESI_v1post"), cs_cox(fJ_M,"ESI_v1post"))
  } else {
    fA_F <- glm.nb(as.formula(paste(spec$out, "~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed))")), data = spec$data_F)
    fA_M <- glm.nb(as.formula(paste(spec$out, "~ ESI_v1post + age_visit + gender + race + offset(log(Years_Followed))")), data = spec$data_M)
    fJ_F <- glm.nb(as.formula(paste(spec$out, "~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed))")), data = spec$data_F)
    fJ_M <- glm.nb(as.formula(paste(spec$out, "~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + offset(log(Years_Followed))")), data = spec$data_M)
    cs_reg <- cs_add(cs_reg, spec$tab, spec$model_alone, "ESI_v1post", cs_nb(fA_F,"ESI_v1post"), cs_nb(fA_M,"ESI_v1post"), scale="IRR")
    cs_reg <- cs_add(cs_reg, spec$tab, spec$model_joint, "ESI_v1post", cs_nb(fJ_F,"ESI_v1post"), cs_nb(fJ_M,"ESI_v1post"), scale="IRR")
  }
}

# S5 + S6d: FEV1-decline LMMs
cs_fev1 <- phe_raw %>%
  filter(visitnum %in% c(1,2,3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(pid, visitnum, years_from_baseline, FEV1_post_mL = FEV1_post * 1000,
            age_visit = as.numeric(age_visit), ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow = factor(SmokCigNow))
cs_base <- d_b %>% transmute(pid, bhatt_grp = factor(bhatt_cls, levels=ord),
                             esi_grp = factor(esi_cls, levels=ord),
                             ESI_v1post, FEV1_FVC_baseline = FEV1_FVC_post,
                             Height_CM = as.numeric(Height_CM),
                             gender_baseline = factor(gender),
                             race_baseline = factor(race),
                             stratum_baseline = stratum)
cs_declF <- cs_fev1 %>% inner_join(cs_base, by = "pid") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
cs_declM <- cs_fev1 %>% inner_join(cs_base, by = "pid") %>%
  filter(!is.na(age_visit))
lB_F <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1|pid), data = cs_declF, REML=TRUE)
lE_F <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp   + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1|pid), data = cs_declF, REML=TRUE)
lB_M <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + gender_baseline + race_baseline + age_visit + (1|pid), data = cs_declM, REML=TRUE)
lE_M <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp   + gender_baseline + race_baseline + age_visit + (1|pid), data = cs_declM, REML=TRUE)
for (g in groups3) {
  cs_reg <- cs_add(cs_reg, "S5","FEV1 decline CT", g, cs_lmm(lB_F, paste0("years_from_baseline:bhatt_grp",g)), cs_lmm(lB_M, paste0("years_from_baseline:bhatt_grp",g)), scale="mL/yr")
  cs_reg <- cs_add(cs_reg, "S5","FEV1 decline ESI",g, cs_lmm(lE_F, paste0("years_from_baseline:esi_grp",  g)), cs_lmm(lE_M, paste0("years_from_baseline:esi_grp",  g)), scale="mL/yr")
}
g0_F <- cs_declF %>% filter(stratum_baseline == "GOLD0", !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))
g0_M <- cs_declM %>% filter(stratum_baseline == "GOLD0", !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))
la_F <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post + Height_CM + age_visit + ATS_PackYears + SmokCigNow + gender_baseline + race_baseline + (1|pid), data = g0_F, REML=TRUE)
la_M <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post + age_visit + gender_baseline + race_baseline + (1|pid), data = g0_M, REML=TRUE)
lj_F <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) + Height_CM + age_visit + ATS_PackYears + SmokCigNow + gender_baseline + race_baseline + (1|pid), data = g0_F, REML=TRUE)
lj_M <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) + age_visit + gender_baseline + race_baseline + (1|pid), data = g0_M, REML=TRUE)
cs_reg <- cs_add(cs_reg, "S6d","cont ESI alone (GOLD 0)","ESI_v1post", cs_lmm(la_F,"years_from_baseline:ESI_v1post"), cs_lmm(la_M,"years_from_baseline:ESI_v1post"), scale="mL/yr")
cs_reg <- cs_add(cs_reg, "S6d","cont ESI + FEV1/FVC (GOLD 0)","ESI_v1post", cs_lmm(lj_F,"years_from_baseline:ESI_v1post"), cs_lmm(lj_M,"years_from_baseline:ESI_v1post"), scale="mL/yr")

# --- Report ---
num_cols <- c("est_full","LCI_full","UCI_full","est_min","LCI_min","UCI_min")
cs_reg[, num_cols] <- round(cs_reg[, num_cols], 3)
cs_reg$p_full <- signif(cs_reg$p_full, 3); cs_reg$p_min <- signif(cs_reg$p_min, 3)

n_tot   <- nrow(cs_reg)
n_sens  <- sum(cs_reg$sensitive)
n_cross <- sum(cs_reg$p_crosses_05)
n_dir   <- sum(cs_reg$direction_change)
cat(sprintf("Covariate-sensitivity summary: %d estimates tested; %d sensitive to covariate choice (%d cross p = 0.05, %d change direction).\n",
            n_tot, n_sens, n_cross, n_dir))
```

```
## Covariate-sensitivity summary: 77 estimates tested; 2 sensitive to covariate choice (2 cross p = 0.05, 0 change direction).
```

``` r
if (n_sens > 0) {
  kable(cs_reg[cs_reg$sensitive, ], caption = "Estimates sensitive to covariate choice (age+sex+race vs. primary set).")
} else {
  cat("All reported associations preserve direction and p = 0.05 significance status under minimal (age + sex + race) adjustment.\n")
}
```



Table: Estimates sensitive to covariate choice (age+sex+race vs. primary set).

|   |table   |model          |term       |scale | est_full| LCI_full| UCI_full| p_full| est_min| LCI_min| UCI_min|   p_min|p_crosses_05 |direction_change |sensitive |
|:--|:-------|:--------------|:----------|:-----|--------:|--------:|--------:|------:|-------:|-------:|-------:|-------:|:------------|:----------------|:---------|
|48 |S4a CVD |cause-spec CT  |COPD-minor |HR    |    1.393|    0.948|    2.047| 0.0912|   1.676|   1.146|   2.452| 0.00774|TRUE         |FALSE            |TRUE      |
|49 |S4a CVD |cause-spec ESI |COPD-minor |HR    |    1.507|    0.957|    2.373| 0.0767|   1.812|   1.155|   2.843| 0.00970|TRUE         |FALSE            |TRUE      |

``` r
kable(cs_reg, caption = "Full comparison: primary-adjustment vs. minimal-adjustment estimates for every reported association.")
```



Table: Full comparison: primary-adjustment vs. minimal-adjustment estimates for every reported association.

|table      |model                        |term            |scale | est_full| LCI_full| UCI_full|   p_full| est_min| LCI_min| UCI_min|    p_min|p_crosses_05 |direction_change |sensitive |
|:----------|:----------------------------|:---------------|:-----|--------:|--------:|--------:|--------:|-------:|-------:|-------:|--------:|:------------|:----------------|:---------|
|Table 1    |all-cause CT                 |AFL-only-NoCOPD |HR    |    0.897|    0.622|    1.296| 5.64e-01|   0.902|   0.625|   1.303| 5.83e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |all-cause ESI                |AFL-only-NoCOPD |HR    |    0.913|    0.571|    1.460| 7.05e-01|   0.974|   0.609|   1.556| 9.11e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory CT               |AFL-only-NoCOPD |HR    |    1.417|    0.185|   10.839| 7.37e-01|   1.441|   0.188|  11.019| 7.25e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory ESI              |AFL-only-NoCOPD |HR    |    2.192|    0.290|   16.545| 4.47e-01|   2.313|   0.306|  17.456| 4.16e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |all-cause CT                 |COPD-minor      |HR    |    1.907|    1.640|    2.218| 0.00e+00|   2.085|   1.797|   2.421| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |all-cause ESI                |COPD-minor      |HR    |    1.943|    1.625|    2.324| 0.00e+00|   2.109|   1.766|   2.518| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory CT               |COPD-minor      |HR    |    4.804|    2.145|   10.760| 1.36e-04|   4.320|   1.932|   9.658| 3.64e-04|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory ESI              |COPD-minor      |HR    |    5.684|    2.425|   13.324| 6.38e-05|   5.022|   2.146|  11.753| 1.99e-04|FALSE        |FALSE            |FALSE     |
|Table 1    |all-cause CT                 |COPD-major      |HR    |    2.591|    2.351|    2.855| 0.00e+00|   2.927|   2.662|   3.217| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |all-cause ESI                |COPD-major      |HR    |    2.395|    2.184|    2.626| 0.00e+00|   2.687|   2.455|   2.940| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory CT               |COPD-major      |HR    |   36.266|   20.852|   63.072| 0.00e+00|  43.376|  24.990|  75.289| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |respiratory ESI              |COPD-major      |HR    |   30.952|   18.762|   51.063| 0.00e+00|  37.392|  22.706|  61.576| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations CT             |AFL-only-NoCOPD |IRR   |    1.285|    0.945|    1.747| 1.10e-01|   1.245|   0.914|   1.697| 1.65e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations ESI            |AFL-only-NoCOPD |IRR   |    0.975|    0.633|    1.503| 9.10e-01|   0.909|   0.587|   1.407| 6.68e-01|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations CT             |COPD-minor      |IRR   |    2.718|    2.355|    3.137| 0.00e+00|   2.841|   2.467|   3.272| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations ESI            |COPD-minor      |IRR   |    2.774|    2.329|    3.304| 0.00e+00|   2.921|   2.455|   3.476| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations CT             |COPD-major      |IRR   |    5.053|    4.593|    5.560| 0.00e+00|   5.167|   4.710|   5.668| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 1    |exacerbations ESI            |COPD-major      |IRR   |    4.468|    4.072|    4.903| 0.00e+00|   4.589|   4.192|   5.023| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |all-cause                    |Both-COPD       |HR    |    2.607|    2.368|    2.869| 0.00e+00|   2.936|   2.674|   3.224| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |respiratory                  |Both-COPD       |HR    |   36.677|   20.648|   65.151| 0.00e+00|  42.560|  24.009|  75.447| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |exacerbations                |Both-COPD       |IRR   |    4.875|    4.446|    5.345| 0.00e+00|   5.020|   4.592|   5.488| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |all-cause                    |CT-only-COPD    |HR    |    1.577|    1.302|    1.909| 3.00e-06|   1.723|   1.424|   2.084| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |respiratory                  |CT-only-COPD    |HR    |    3.531|    1.242|   10.038| 1.79e-02|   3.266|   1.150|   9.275| 2.63e-02|FALSE        |FALSE            |FALSE     |
|Table 2    |exacerbations                |CT-only-COPD    |IRR   |    1.989|    1.660|    2.383| 0.00e+00|   2.022|   1.688|   2.421| 0.00e+00|FALSE        |FALSE            |FALSE     |
|Table 2    |all-cause                    |ESI-only-COPD   |HR    |    1.096|    0.806|    1.489| 5.60e-01|   1.114|   0.820|   1.514| 4.88e-01|FALSE        |FALSE            |FALSE     |
|Table 2    |respiratory                  |ESI-only-COPD   |HR    |    2.640|    0.591|   11.803| 2.04e-01|   2.482|   0.555|  11.094| 2.34e-01|FALSE        |FALSE            |FALSE     |
|Table 2    |exacerbations                |ESI-only-COPD   |IRR   |    1.383|    1.060|    1.805| 1.69e-02|   1.338|   1.023|   1.750| 3.34e-02|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause CT                 |AFL-only-NoCOPD |HR    |    0.898|    0.622|    1.297| 5.68e-01|   0.903|   0.625|   1.303| 5.85e-01|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause ESI                |AFL-only-NoCOPD |HR    |    0.908|    0.568|    1.452| 6.88e-01|   0.973|   0.609|   1.555| 9.08e-01|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory CT               |AFL-only-NoCOPD |HR    |    1.405|    0.184|   10.746| 7.43e-01|   1.415|   0.185|  10.824| 7.38e-01|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory ESI              |AFL-only-NoCOPD |HR    |    2.152|    0.285|   16.243| 4.57e-01|   2.253|   0.298|  17.005| 4.31e-01|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations CT             |AFL-only-NoCOPD |IRR   |    1.292|    0.948|    1.759| 1.04e-01|   1.253|   0.918|   1.710| 1.56e-01|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations ESI            |AFL-only-NoCOPD |IRR   |    0.974|    0.631|    1.504| 9.05e-01|   0.905|   0.583|   1.406| 6.58e-01|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause CT                 |COPD-minor      |HR    |    1.863|    1.602|    2.166| 0.00e+00|   2.083|   1.794|   2.419| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause ESI                |COPD-minor      |HR    |    1.898|    1.587|    2.270| 0.00e+00|   2.110|   1.766|   2.520| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory CT               |COPD-minor      |HR    |    4.552|    2.031|   10.201| 2.33e-04|   4.395|   1.965|   9.830| 3.12e-04|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory ESI              |COPD-minor      |HR    |    5.409|    2.306|   12.688| 1.04e-04|   5.145|   2.197|  12.046| 1.61e-04|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations CT             |COPD-minor      |IRR   |    2.692|    2.330|    3.109| 0.00e+00|   2.832|   2.457|   3.265| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations ESI            |COPD-minor      |IRR   |    2.749|    2.305|    3.277| 0.00e+00|   2.916|   2.448|   3.473| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause CT                 |COPD-major      |HR    |    2.398|    2.173|    2.647| 0.00e+00|   2.702|   2.454|   2.975| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |all-cause ESI                |COPD-major      |HR    |    2.222|    2.023|    2.441| 0.00e+00|   2.481|   2.264|   2.719| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory CT               |COPD-major      |HR    |   30.272|   17.369|   52.760| 0.00e+00|  35.334|  20.318|  61.449| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |respiratory ESI              |COPD-major      |HR    |   25.954|   15.695|   42.917| 0.00e+00|  30.407|  18.425|  50.181| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations CT             |COPD-major      |IRR   |    4.799|    4.355|    5.289| 0.00e+00|   4.884|   4.445|   5.367| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S3a        |exacerbations ESI            |COPD-major      |IRR   |    4.246|    3.863|    4.666| 0.00e+00|   4.336|   3.954|   4.755| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S4a CVD    |cause-spec CT                |AFL-only-NoCOPD |HR    |    1.221|    0.534|    2.792| 6.35e-01|   1.219|   0.533|   2.785| 6.39e-01|FALSE        |FALSE            |FALSE     |
|S4a CVD    |cause-spec ESI               |AFL-only-NoCOPD |HR    |    0.734|    0.181|    2.980| 6.65e-01|   0.766|   0.189|   3.108| 7.09e-01|FALSE        |FALSE            |FALSE     |
|S4a CVD    |cause-spec CT                |COPD-minor      |HR    |    1.393|    0.948|    2.047| 9.12e-02|   1.676|   1.146|   2.452| 7.74e-03|TRUE         |FALSE            |TRUE      |
|S4a CVD    |cause-spec ESI               |COPD-minor      |HR    |    1.507|    0.957|    2.373| 7.67e-02|   1.812|   1.155|   2.843| 9.70e-03|TRUE         |FALSE            |TRUE      |
|S4a CVD    |cause-spec CT                |COPD-major      |HR    |    1.745|    1.350|    2.256| 2.17e-05|   1.840|   1.432|   2.363| 1.80e-06|FALSE        |FALSE            |FALSE     |
|S4a CVD    |cause-spec ESI               |COPD-major      |HR    |    1.707|    1.334|    2.186| 2.17e-05|   1.771|   1.392|   2.253| 3.30e-06|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec CT                |AFL-only-NoCOPD |HR    |    1.191|    0.553|    2.565| 6.55e-01|   1.203|   0.559|   2.590| 6.37e-01|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec ESI               |AFL-only-NoCOPD |HR    |    1.609|    0.707|    3.662| 2.57e-01|   1.724|   0.758|   3.922| 1.94e-01|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec CT                |COPD-minor      |HR    |    2.322|    1.669|    3.230| 6.00e-07|   2.729|   1.969|   3.781| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec ESI               |COPD-minor      |HR    |    2.478|    1.700|    3.614| 2.40e-06|   2.886|   1.985|   4.195| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec CT                |COPD-major      |HR    |    1.971|    1.557|    2.495| 0.00e+00|   2.299|   1.827|   2.893| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S4b Cancer |cause-spec ESI               |COPD-major      |HR    |    1.790|    1.432|    2.236| 3.00e-07|   2.059|   1.657|   2.558| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec CT                |AFL-only-NoCOPD |HR    |    0.806|    0.297|    2.192| 6.73e-01|   0.797|   0.293|   2.164| 6.56e-01|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec ESI               |AFL-only-NoCOPD |HR    |    0.358|    0.050|    2.565| 3.06e-01|   0.385|   0.054|   2.761| 3.42e-01|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec CT                |COPD-minor      |HR    |    2.114|    1.530|    2.920| 5.70e-06|   2.409|   1.753|   3.310| 1.00e-07|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec ESI               |COPD-minor      |HR    |    2.016|    1.391|    2.923| 2.15e-04|   2.300|   1.594|   3.319| 8.60e-06|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec CT                |COPD-major      |HR    |    1.428|    1.102|    1.850| 6.96e-03|   1.610|   1.252|   2.070| 2.04e-04|FALSE        |FALSE            |FALSE     |
|S4c Other  |cause-spec ESI               |COPD-major      |HR    |    1.304|    1.019|    1.667| 3.46e-02|   1.455|   1.146|   1.849| 2.10e-03|FALSE        |FALSE            |FALSE     |
|S6a        |cont ESI alone               |ESI_v1post      |HR    |    1.100|    1.071|    1.131| 0.00e+00|   1.251|   1.235|   1.267| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S6a        |cont ESI + FEV1/FVC          |ESI_v1post      |HR    |    1.068|    1.022|    1.117| 3.77e-03|   1.100|   1.064|   1.137| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S6b        |cont ESI alone               |ESI_v1post      |HR    |    1.152|    1.102|    1.204| 0.00e+00|   1.521|   1.486|   1.556| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S6b        |cont ESI + FEV1/FVC          |ESI_v1post      |HR    |    0.966|    0.886|    1.053| 4.27e-01|   0.968|   0.902|   1.039| 3.71e-01|FALSE        |FALSE            |FALSE     |
|S6c        |cont ESI alone               |ESI_v1post      |IRR   |    1.112|    1.072|    1.153| 0.00e+00|   1.329|   1.305|   1.354| 0.00e+00|FALSE        |FALSE            |FALSE     |
|S6c        |cont ESI + FEV1/FVC          |ESI_v1post      |IRR   |    1.010|    0.957|    1.065| 7.27e-01|   0.981|   0.942|   1.021| 3.41e-01|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline CT              |AFL-only-NoCOPD |mL/yr |    3.628|   -1.809|    9.065| 1.91e-01|   4.106|  -1.343|   9.555| 1.40e-01|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline ESI             |AFL-only-NoCOPD |mL/yr |   10.148|    1.912|   18.384| 1.58e-02|   9.787|   1.527|  18.048| 2.02e-02|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline CT              |COPD-minor      |mL/yr |   -0.475|   -3.382|    2.431| 7.49e-01|  -1.537|  -4.450|   1.376| 3.01e-01|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline ESI             |COPD-minor      |mL/yr |   -1.560|   -5.107|    1.987| 3.89e-01|  -2.637|  -6.195|   0.922| 1.46e-01|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline CT              |COPD-major      |mL/yr |    1.270|   -0.623|    3.163| 1.88e-01|   0.819|  -1.078|   2.717| 3.97e-01|FALSE        |FALSE            |FALSE     |
|S5         |FEV1 decline ESI             |COPD-major      |mL/yr |    1.089|   -0.753|    2.930| 2.47e-01|   0.786|  -1.061|   2.633| 4.04e-01|FALSE        |FALSE            |FALSE     |
|S6d        |cont ESI alone (GOLD 0)      |ESI_v1post      |mL/yr |   -5.376|   -8.190|   -2.561| 1.84e-04|  -5.684|  -8.535|  -2.834| 9.40e-05|FALSE        |FALSE            |FALSE     |
|S6d        |cont ESI + FEV1/FVC (GOLD 0) |ESI_v1post      |mL/yr |   -4.733|   -7.617|   -1.849| 1.31e-03|  -4.975|  -7.896|  -2.053| 8.52e-04|FALSE        |FALSE            |FALSE     |

# Session info


``` r
sessionInfo()
```

```
## R version 4.5.2 (2025-10-31)
## Platform: aarch64-apple-darwin20
## Running under: macOS Tahoe 26.6.2
## 
## Matrix products: default
## BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib 
## LAPACK: /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
## 
## locale:
## [1] en_US/en_US/en_US/C/en_US/en_US
## 
## time zone: America/New_York
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] patchwork_1.3.2 knitr_1.51      multcomp_1.4-31 TH.data_1.1-5  
##  [5] mvtnorm_1.3-5   rpart_4.1.24    lmerTest_3.2-1  lme4_2.0-1     
##  [9] Matrix_1.7-4    MASS_7.3-65     survival_3.8-3  scales_1.4.0   
## [13] ggplot2_4.0.1   tidyr_1.3.1     dplyr_1.2.1    
## 
## loaded via a namespace (and not attached):
##  [1] sandwich_3.1-1      generics_0.1.4      lattice_0.22-7     
##  [4] magrittr_2.0.5      evaluate_1.0.5      grid_4.5.2         
##  [7] RColorBrewer_1.1-3  purrr_1.2.0         textshaping_1.0.4  
## [10] codetools_0.2-20    numDeriv_2016.8-1.1 reformulas_0.4.4   
## [13] Rdpack_2.6.6        cli_3.6.5           rlang_1.1.7        
## [16] rbibutils_2.4.1     splines_4.5.2       withr_3.0.2        
## [19] otel_0.2.0          tools_4.5.2         nloptr_2.2.1       
## [22] minqa_1.2.8         boot_1.3-32         vctrs_0.7.2        
## [25] R6_2.6.1            zoo_1.8-15          lifecycle_1.0.5    
## [28] ragg_1.5.0          pkgconfig_2.0.3     pillar_1.11.1      
## [31] gtable_0.3.6        glue_1.8.0          Rcpp_1.1.1         
## [34] systemfonts_1.3.1   xfun_0.55           tibble_3.3.1       
## [37] tidyselect_1.2.1    dichromat_2.0-0.1   farver_2.1.2       
## [40] nlme_3.1-168        labeling_0.4.3      compiler_4.5.2     
## [43] S7_0.2.1
```
