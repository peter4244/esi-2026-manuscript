#!/usr/bin/env Rscript
# Exploratory analysis: how well can ESI substitute for the CT-imaging criteria
# in the Bhatt 2025 multidimensional COPD diagnostic schema?
#
# Bhatt schema (JAMA 2025):
#   Major criterion : FEV1/FVC < 0.70 (post-BD)
#   5 minor criteria:
#     - emph (CT visual emphysema ≥ mild)        ← IMAGING
#     - wall (CT visual bronchial wall thickening definite)  ← IMAGING
#     - dysp (mMRC ≥ 2)
#     - qol  (SGRQ ≥ 25)                            -- in COPDGene
#     - cb   (chronic bronchitis)
#   Categories:
#     Major: major + ≥1 minor
#     Minor: !major + ≥3 minor
#
# ESI-substituted variant (4-criterion):
#   replace the 2 imaging criteria with 1 ESI criterion (ESI ≥ T)
#   Major:  major + ≥1 of {esi, dysp, qol, cb}
#   Minor: !major + ≥2 of {esi, dysp, qol, cb}    (≥half of 4, analogous to ≥3 of 5)
#
# Outputs: per-threshold agreement, cross-tabs, ROC, log to .md

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(pROC)
})

OUT  <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/exploration_esi_vs_bhatt_2026.5.17.md"
LOG  <- character()
hdr  <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)
emit <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)

esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"

# --- Load ---------------------------------------------------------------------
esi <- read.csv(esi_path, stringsAsFactors = FALSE)
esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)

bhatt_cols <- c("rand_id","visitnum","finalgold_visit",
                "FEV1_FVC_post","FEV1pp_post",
                "CT_Visual_Emph_Severity","CT_Visual_Wall_Thickening",
                "MMRCDyspneaScor","SGRQ_scoreTotal","Chronic_Bronchitis",
                "age_visit","gender","race","SmokCigNow","ATS_PackYears","BMI")
v1 <- phe %>% filter(visitnum == 1) %>% select(all_of(bhatt_cols))

# Merge with V1 ESI
d <- esi_v1 %>% inner_join(v1, by = "rand_id")

# --- Bhatt criteria -----------------------------------------------------------
d <- d %>%
  mutate(
    major_criterion = ifelse(is.na(FEV1_FVC_post), NA, FEV1_FVC_post < 0.70),
    emph_yn         = ifelse(is.na(CT_Visual_Emph_Severity), NA,
                             CT_Visual_Emph_Severity >= 1),       # ≥ mild Fleischner
    wall_yn         = ifelse(is.na(CT_Visual_Wall_Thickening), NA,
                             CT_Visual_Wall_Thickening == 2),     # definite Fleischner
    dysp_yn         = ifelse(is.na(MMRCDyspneaScor), NA,
                             MMRCDyspneaScor >= 2),
    qol_yn          = ifelse(is.na(SGRQ_scoreTotal), NA,
                             SGRQ_scoreTotal >= 25),
    cb_yn           = ifelse(is.na(Chronic_Bronchitis), NA,
                             Chronic_Bronchitis == 1)
  )

# Complete-case set for Bhatt classification
bhatt_complete <- d %>% filter(
  !is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
  !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn)
)

# Bhatt classification
classify_bhatt <- function(df, ...){
  imaging_or_symptom <- pmin(1, df$emph_yn + df$wall_yn + df$dysp_yn + df$qol_yn + df$cb_yn) > 0
  n_minor <- df$emph_yn + df$wall_yn + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & imaging_or_symptom,             "COPD-major",
  ifelse(!df$major_criterion & n_minor >= 3,                  "COPD-minor",
  ifelse(df$major_criterion & !imaging_or_symptom,            "AFL-only-NoCOPD",
                                                              "noCOPD")))
}
bhatt_complete$bhatt_cls <- classify_bhatt(bhatt_complete)

# --- ESI-substituted classification (4-criterion) -----------------------------
# For multiple ESI thresholds, compute substitution and agreement
classify_esi <- function(df, esi_thresh){
  esi_yn <- df$ESI >= esi_thresh
  imaging_or_symptom <- pmin(1, esi_yn + df$dysp_yn + df$qol_yn + df$cb_yn) > 0
  n_minor <- esi_yn + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & imaging_or_symptom,             "COPD-major",
  ifelse(!df$major_criterion & n_minor >= 2,                  "COPD-minor",
  ifelse(df$major_criterion & !imaging_or_symptom,            "AFL-only-NoCOPD",
                                                              "noCOPD")))
}

# Treat "Bhatt = COPD (major OR minor)" as the truth, and the ESI-substituted
# version as the candidate.  Report agreement and confusion.
hdr("# ESI as a substitute for CT-imaging criteria in the Bhatt 2025 schema")
hdr("")
hdr(sprintf("**Cohort**: V1 subjects with valid ESI and all Bhatt criteria variables non-missing: n = %d.",
            nrow(bhatt_complete)))
hdr("")
hdr("Bhatt schema (n of 5 minor criteria collapsed):")
hdr("")

bhatt_summary <- table(bhatt_complete$bhatt_cls)
for (k in names(bhatt_summary)) {
  hdr(sprintf("- **%s**: %d (%.1f%%)", k, bhatt_summary[k],
              100 * bhatt_summary[k] / nrow(bhatt_complete)))
}
hdr("")

# Per-stratum breakdown of Bhatt classification
hdr("## Bhatt classification by spectrum stratum")
hdr("")
stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
bhatt_complete$stratum <- factor(
  case_when(
    bhatt_complete$finalgold_visit == -2 ~ "Never",
    bhatt_complete$finalgold_visit == -1 ~ "PRISm",
    bhatt_complete$finalgold_visit ==  0 ~ "GOLD0",
    bhatt_complete$finalgold_visit ==  1 ~ "GOLD1",
    bhatt_complete$finalgold_visit ==  2 ~ "GOLD2",
    bhatt_complete$finalgold_visit ==  3 ~ "GOLD3",
    bhatt_complete$finalgold_visit ==  4 ~ "GOLD4",
    TRUE                                  ~ NA_character_
  ),
  levels = stratum_levels
)

per_strat <- bhatt_complete %>%
  filter(!is.na(stratum)) %>%
  group_by(stratum, bhatt_cls) %>%
  tally() %>%
  pivot_wider(names_from = bhatt_cls, values_from = n, values_fill = 0)
emit(paste(capture.output(print(as.data.frame(per_strat))), collapse = "\n"))

# --- Threshold sweep ----------------------------------------------------------
hdr("\n## Agreement of ESI-substituted vs original Bhatt classification, across ESI thresholds")
hdr("")
hdr("ESI-substituted variant: replace the 2 imaging criteria with 1 ESI criterion (`ESI ≥ T`).  Major category: major + ≥1 of {ESI, dysp, qol, cb}.  Minor category: !major + ≥2 of {ESI, dysp, qol, cb}.")
hdr("")
hdr("Truth: Bhatt classification (≥3 of 5 minors).  Candidate: 4-criterion ESI-substituted classification.  Outcome of interest: **COPD (major OR minor) vs no COPD**.")
hdr("")
hdr("| ESI threshold | n COPD (Bhatt) | n COPD (ESI variant) | Sens | Spec | Agreement (κ) | Reclassified to COPD | Reclassified to noCOPD |")
hdr("|---:|---:|---:|---:|---:|---:|---:|---:|")

bhatt_complete$bhatt_copd <- bhatt_complete$bhatt_cls %in% c("COPD-major","COPD-minor")

# Function for Cohen's kappa
kappa_fn <- function(a, b) {
  tab <- table(a, b)
  if (nrow(tab) < 2 || ncol(tab) < 2) return(NA)
  po <- sum(diag(tab))/sum(tab)
  pe <- sum(rowSums(tab)*colSums(tab))/sum(tab)^2
  (po - pe)/(1 - pe)
}

agreement_rows <- list()
for (thresh in c(1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0)) {
  bhatt_complete$esi_cls  <- classify_esi(bhatt_complete, thresh)
  bhatt_complete$esi_copd <- bhatt_complete$esi_cls %in% c("COPD-major","COPD-minor")

  tab <- table(Bhatt=bhatt_complete$bhatt_copd, ESI=bhatt_complete$esi_copd)
  tp <- tab["TRUE","TRUE"]; fp <- tab["FALSE","TRUE"]
  fn <- tab["TRUE","FALSE"]; tn <- tab["FALSE","FALSE"]
  sens <- tp/(tp+fn); spec <- tn/(tn+fp)
  k <- kappa_fn(bhatt_complete$bhatt_copd, bhatt_complete$esi_copd)

  reclass_to_copd  <- sum(!bhatt_complete$bhatt_copd & bhatt_complete$esi_copd)   # FP for ESI
  reclass_to_nocop <- sum(bhatt_complete$bhatt_copd & !bhatt_complete$esi_copd)   # FN for ESI

  hdr(sprintf("| ESI ≥ %.1f | %d | %d | %.3f | %.3f | %.3f | %d | %d |",
              thresh, sum(bhatt_complete$bhatt_copd), sum(bhatt_complete$esi_copd),
              sens, spec, k, reclass_to_copd, reclass_to_nocop))
  agreement_rows[[paste0("t",thresh)]] <- data.frame(
    thresh = thresh, sens = sens, spec = spec, kappa = k,
    reclass_to_copd = reclass_to_copd, reclass_to_nocop = reclass_to_nocop
  )
}

# --- ROC of ESI alone in preserved-spirometry subjects ------------------------
hdr("\n## ROC: ESI as a continuous predictor of Bhatt minor-category COPD in preserved-spirometry subjects")
hdr("")
hdr("Restricted to subjects without airflow obstruction (FEV1/FVC ≥ 0.70).  Outcome: classified by Bhatt as COPD-minor (i.e., ≥ 3 of 5 minor criteria, without airflow obstruction) vs not classified as COPD.")
hdr("")

preserved <- bhatt_complete %>% filter(!major_criterion)
preserved$bhatt_minor_copd <- preserved$bhatt_cls == "COPD-minor"
hdr(sprintf("Preserved-spirometry subset (FEV1/FVC ≥ 0.70): n = %d; Bhatt minor-category COPD = %d (%.1f%%).",
            nrow(preserved), sum(preserved$bhatt_minor_copd),
            100*mean(preserved$bhatt_minor_copd)))

roc1 <- roc(preserved$bhatt_minor_copd, preserved$ESI, quiet = TRUE)
hdr(sprintf("\n**ROC AUC for ESI alone**: %.3f (95%% CI %.3f–%.3f)",
            auc(roc1), ci.auc(roc1)[1], ci.auc(roc1)[3]))

# Best-threshold candidates
ix <- which.max(roc1$sensitivities + roc1$specificities - 1)
best_t   <- roc1$thresholds[ix]
best_sn  <- roc1$sensitivities[ix]
best_sp  <- roc1$specificities[ix]
hdr(sprintf("**Best ESI threshold by Youden index**: %.2f (sens = %.2f, spec = %.2f).",
            best_t, best_sn, best_sp))

# Per-stratum ROC within preserved-spirometry
hdr("\n### Per-stratum ROC (preserved-spirometry subset)")
hdr("")
hdr("| Stratum | n | Bhatt minor-COPD | AUC | 95% CI |")
hdr("|---|---:|---:|---:|---|")
for (s in c("Never","GOLD0","PRISm")) {
  sub <- preserved %>% filter(stratum == s)
  if (sum(sub$bhatt_minor_copd) < 5 || sum(!sub$bhatt_minor_copd) < 5) {
    hdr(sprintf("| %s | %d | %d | — | (insufficient) |",
                s, nrow(sub), sum(sub$bhatt_minor_copd)))
    next
  }
  r <- roc(sub$bhatt_minor_copd, sub$ESI, quiet = TRUE)
  ci <- ci.auc(r)
  hdr(sprintf("| %s | %d | %d | %.3f | %.3f–%.3f |",
              s, nrow(sub), sum(sub$bhatt_minor_copd),
              auc(r), ci[1], ci[3]))
}

# --- Detailed cross-tab at the best threshold ---------------------------------
best_round <- round(best_t * 2) / 2   # snap to 0.5
if (!best_round %in% c(1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0)) best_round <- 2.0
bhatt_complete$esi_cls  <- classify_esi(bhatt_complete, best_round)
bhatt_complete$esi_copd <- bhatt_complete$esi_cls %in% c("COPD-major","COPD-minor")

hdr(sprintf("\n## Cross-tabulation at ESI ≥ %.1f (closest to Youden-optimal)", best_round))
hdr("")
hdr("Full-cohort 4-way table:")
hdr("")
cls_tab <- table(Bhatt=bhatt_complete$bhatt_cls, ESI_variant=bhatt_complete$esi_cls)
emit("```")
emit(paste(capture.output(print(cls_tab)), collapse = "\n"))
emit("```\n")

# 2x2 simplification
hdr("\nSimplified COPD vs noCOPD agreement:")
hdr("")
tab2 <- table(Bhatt_COPD = bhatt_complete$bhatt_copd, ESI_COPD = bhatt_complete$esi_copd)
emit("```")
emit(paste(capture.output(print(tab2)), collapse = "\n"))
emit("```\n")

# --- Characterize the discordant subjects -------------------------------------
hdr("\n## Discordant subjects (where ESI variant disagrees with Bhatt)")
hdr("")
disc_to_copd  <- bhatt_complete %>% filter(!bhatt_copd & esi_copd)
disc_to_nocop <- bhatt_complete %>% filter(bhatt_copd & !esi_copd)

hdr(sprintf("- Discordant TO COPD (Bhatt says noCOPD, ESI variant says COPD): n = %d.  These are typically high-ESI subjects who failed the 2-imaging or 3-of-5 thresholds.",
            nrow(disc_to_copd)))
hdr(sprintf("- Discordant TO noCOPD (Bhatt says COPD, ESI variant says noCOPD): n = %d.  These are typically subjects whose Bhatt minor diagnosis was driven by imaging+symptoms but with low ESI.",
            nrow(disc_to_nocop)))

# Characterize discordance by stratum
hdr("\n### Discordance by spectrum stratum")
hdr("")
strats <- bhatt_complete %>%
  filter(!is.na(stratum)) %>%
  mutate(
    discord = case_when(
      bhatt_copd  & !esi_copd ~ "Bhatt-COPD, ESI-noCOPD",
      !bhatt_copd &  esi_copd ~ "Bhatt-noCOPD, ESI-COPD",
      bhatt_copd  &  esi_copd ~ "Both COPD",
      TRUE                     ~ "Both noCOPD"
    )
  ) %>%
  group_by(stratum, discord) %>% tally() %>%
  pivot_wider(names_from = discord, values_from = n, values_fill = 0)
emit(paste(capture.output(print(as.data.frame(strats))), collapse = "\n"))

# --- Save and report ----------------------------------------------------------
writeLines(unlist(LOG), OUT)
cat(sprintf("\nWrote: %s\n", OUT))
