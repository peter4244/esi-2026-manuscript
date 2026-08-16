#!/usr/bin/env Rscript
# QND BMI-sensitivity — FEV1-decline addendum.
#
# The main QND script (qnd_bmi_sensitivity_2026.7.20.R) covered Cox mortality
# and NB exacerbation models. This script adds the linear mixed-effects
# FEV1-decline models: S5 (by Bhatt category, both frameworks) and the
# GOLD-0-continuous-ESI slope (S6d headline result).
#
# For the "full" model: age + sex + race + smoker + pack-years + Height_CM
# For the "min" model:  age + sex + race
#
# Note: the FEV1-decline "full" set does NOT include BMI in the v9 analysis
# (Height_CM replaces BMI). Dropping Height_CM in the "min" model isolates
# what the FEV1 slope looks like without any anthropometric adjustment at
# all — informative for a lung-volume outcome that depends heavily on body
# size.

suppressPackageStartupMessages({
  library(dplyr); library(lme4); library(lmerTest)
})

# Reuse the data-prep from the mortality-QND script by sourcing it (this
# also loads d_b, phe_raw, ord, groups3, results collector, etc.).
source("/Users/petecastaldi/claude_projects/projects/ESI_2024/qnd_bmi_sensitivity_2026.7.20.R", echo = FALSE)

# ---- Rebuild the longitudinal FEV1 dataset (mirrors Rmd L843-861) --------
fev1_long <- phe_raw %>%
  filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL  = FEV1_post * 1000,
            age_visit     = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow    = factor(SmokCigNow))

base_b <- d_b %>% transmute(
  rand_id,
  bhatt_grp = factor(bhatt_cls, levels = ord),
  esi_grp   = factor(esi_cls,   levels = ord),
  ESI_v1post,
  FEV1_FVC_baseline = FEV1_FVC_post,
  Height_CM       = as.numeric(Height_CM),
  gender_baseline = factor(gender),
  race_baseline   = factor(race),
  stratum_baseline = stratum
)
decline_full <- fev1_long %>% inner_join(base_b, by = "rand_id") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
decline_min  <- fev1_long %>% inner_join(base_b, by = "rand_id") %>%
  filter(!is.na(age_visit))

cat(sprintf("\nFEV1-decline analysis: full-covariate n = %d obs (%d subjects), min-covariate n = %d obs (%d subjects)\n",
            nrow(decline_full), length(unique(decline_full$rand_id)),
            nrow(decline_min),  length(unique(decline_min$rand_id))))

# ---- LMM extractor -------------------------------------------------------
lmm_row_p <- function(fit, term) {
  s <- summary(fit)
  co <- s$coefficients
  est <- co[term, "Estimate"]
  se  <- co[term, "Std. Error"]
  p   <- co[term, "Pr(>|t|)"]
  c(est = unname(est), se = unname(se),
    LCI = unname(est - 1.96*se), UCI = unname(est + 1.96*se),
    p = unname(p))
}

fmt <- function(v) sprintf("%.2f (%.2f–%.2f)", v["est"], v["LCI"], v["UCI"])

# ---- S5: by Bhatt category, both frameworks -----------------------------
lmm_bhatt_F <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + Height_CM +
                      gender_baseline + race_baseline + age_visit + SmokCigNow +
                      ATS_PackYears + (1 | rand_id), data = decline_full,
                    REML = TRUE)
lmm_esi_F   <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp + Height_CM +
                      gender_baseline + race_baseline + age_visit + SmokCigNow +
                      ATS_PackYears + (1 | rand_id), data = decline_full,
                    REML = TRUE)
lmm_bhatt_M <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp +
                      gender_baseline + race_baseline + age_visit +
                      (1 | rand_id), data = decline_min, REML = TRUE)
lmm_esi_M   <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp +
                    gender_baseline + race_baseline + age_visit +
                    (1 | rand_id), data = decline_min, REML = TRUE)

cat("\n=== S5: FEV1 decline (mL/yr) by Bhatt category ===\n")
cat(sprintf("%-18s %-8s | %-30s %-30s | Δ mL/yr\n",
            "category", "fw", "full (age+sex+race+smk+py+ht)", "min (age+sex+race)"))
cat(strrep("-", 130), "\n", sep = "")
for (g in c("AFL-only-NoCOPD", "COPD-minor", "COPD-major")) {
  bhF <- lmm_row_p(lmm_bhatt_F, paste0("years_from_baseline:bhatt_grp", g))
  bhM <- lmm_row_p(lmm_bhatt_M, paste0("years_from_baseline:bhatt_grp", g))
  esF <- lmm_row_p(lmm_esi_F,   paste0("years_from_baseline:esi_grp",   g))
  esM <- lmm_row_p(lmm_esi_M,   paste0("years_from_baseline:esi_grp",   g))
  cat(sprintf("%-18s %-8s | %-30s %-30s | %+.2f\n",
              g, "CT",  fmt(bhF), fmt(bhM), bhM["est"] - bhF["est"]))
  cat(sprintf("%-18s %-8s | %-30s %-30s | %+.2f\n",
              g, "ESI", fmt(esF), fmt(esM), esM["est"] - esF["est"]))
}

# ---- S6d: continuous ESI, GOLD 0 (headline) ------------------------------
g0_full <- decline_full %>%
  filter(stratum_baseline == "GOLD0",
         !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))
g0_min <- decline_min %>%
  filter(stratum_baseline == "GOLD0",
         !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))

# GOLD 0 ESI alone (interaction: years_from_baseline:ESI_v1post)
lmm_g0_esi_only_F <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post +
                            Height_CM + age_visit + ATS_PackYears + SmokCigNow +
                            gender_baseline + race_baseline + (1 | rand_id),
                          data = g0_full, REML = TRUE)
lmm_g0_esi_only_M <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post +
                            age_visit + gender_baseline + race_baseline +
                            (1 | rand_id), data = g0_min, REML = TRUE)

# GOLD 0 ESI + FEV1/FVC joint
lmm_g0_joint_F <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) +
                         Height_CM + age_visit + ATS_PackYears + SmokCigNow +
                         gender_baseline + race_baseline + (1 | rand_id),
                       data = g0_full, REML = TRUE)
lmm_g0_joint_M <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) +
                         age_visit + gender_baseline + race_baseline +
                         (1 | rand_id), data = g0_min, REML = TRUE)

cat("\n=== S6d: continuous ESI, GOLD 0 subgroup, FEV1 decline (mL/yr per unit ESI) ===\n")
cat(sprintf("%-24s | %-30s %-30s | Δ mL/yr\n",
            "model", "full (age+sex+race+smk+py+ht)", "min (age+sex+race)"))
cat(strrep("-", 110), "\n", sep = "")

eF <- lmm_row_p(lmm_g0_esi_only_F, "years_from_baseline:ESI_v1post")
eM <- lmm_row_p(lmm_g0_esi_only_M, "years_from_baseline:ESI_v1post")
cat(sprintf("%-24s | %-30s %-30s | %+.2f\n",
            "ESI only",       fmt(eF), fmt(eM), eM["est"] - eF["est"]))

jF <- lmm_row_p(lmm_g0_joint_F, "years_from_baseline:ESI_v1post")
jM <- lmm_row_p(lmm_g0_joint_M, "years_from_baseline:ESI_v1post")
cat(sprintf("%-24s | %-30s %-30s | %+.2f\n",
            "ESI + FEV1/FVC joint", fmt(jF), fmt(jM), jM["est"] - jF["est"]))

# Also report the FEV1/FVC interaction in the joint model (so we can see
# whether it changes when adjustments drop)
ffF <- lmm_row_p(lmm_g0_joint_F, "years_from_baseline:FEV1_FVC_baseline")
ffM <- lmm_row_p(lmm_g0_joint_M, "years_from_baseline:FEV1_FVC_baseline")
cat(sprintf("%-24s | %-30s %-30s | %+.2f  (FEV1/FVC interaction, per unit)\n",
            "  (paired FEV1/FVC)",  fmt(ffF), fmt(ffM), ffM["est"] - ffF["est"]))

cat("\nInterpretation: negative estimate = accelerated FEV1 decline in that group\n")
cat("(vs noCOPD reference for S5, or vs baseline slope for S6d).\n")
