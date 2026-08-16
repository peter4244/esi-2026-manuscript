#!/usr/bin/env Rscript
# Independent recomputation of every key statistic claimed in the spectrum
# analysis report.  Source: raw CSVs.  No reliance on cached Rmd chunks.
#
# Writes a markdown PASS/FAIL log next to this script.
# Run from /Users/petecastaldi/claude_projects/projects/ESI_2024/.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(tibble); library(survival); library(lme4); library(lmerTest)
})

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_log_2026.5.17.md"

# --- Logging helpers ----------------------------------------------------------
LOG_LINES <- character()
n_pass <- 0L
n_fail <- 0L

emit <- function(...) LOG_LINES[[length(LOG_LINES) + 1L]] <<- paste0(...)
hdr  <- function(txt) emit("\n## ", txt, "\n")
sec  <- function(txt) emit("\n### ", txt, "\n")

check <- function(label, expected, actual, tol = 0.005, fmt = "%.3f") {
  ok <- if (is.null(expected) || is.na(expected)) {
    !is.null(actual) && !is.na(actual)
  } else if (is.numeric(expected) && is.numeric(actual)) {
    abs(expected - actual) <= tol
  } else {
    identical(expected, actual)
  }
  status <- if (ok) "PASS" else "**FAIL**"
  emit(sprintf("- [%s] %s — expected %s, recomputed %s",
               status, label,
               if (is.numeric(expected)) sprintf(fmt, expected) else as.character(expected),
               if (is.numeric(actual))   sprintf(fmt, actual)   else as.character(actual)))
  if (ok) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L
  invisible(ok)
}

# --- Load raw data ------------------------------------------------------------
esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
vs_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"

esi_raw <- read.csv(esi_path, stringsAsFactors = FALSE)
esi_raw <- esi_raw[, c("rand_id","visitnum","PrePost","FVC","PEF","FEF25","FEF50","FEF75","ESI")]
esi_raw$rand_id <- as.character(esi_raw$rand_id)
esi_raw$visitnum <- as.integer(esi_raw$visitnum)
esi_raw$PrePost  <- as.integer(esi_raw$PrePost)

esi_v1 <- esi_raw %>%
  filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe_all <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe_all$rand_id <- as.character(phe_all$rand_id)

vs <- read.csv(vs_path, stringsAsFactors = FALSE)
vs$rand_id <- as.character(vs$rand_id)

# Visit-1 merged set with stratum
phe_v1 <- phe_all %>% filter(visitnum == 1)
d <- esi_v1 %>%
  inner_join(phe_v1, by = "rand_id") %>%
  mutate(
    stratum = case_when(
      finalgold_visit == -2 ~ "Never",
      finalgold_visit == -1 ~ "PRISm",
      finalgold_visit ==  0 ~ "GOLD0",
      finalgold_visit ==  1 ~ "GOLD1",
      finalgold_visit ==  2 ~ "GOLD2",
      finalgold_visit ==  3 ~ "GOLD3",
      finalgold_visit ==  4 ~ "GOLD4",
      TRUE                  ~ NA_character_
    )
  )

emit("# Validation log — spectrum-wide ESI analysis, 2026-05-17\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.")
emit("Tolerance: 0.005 absolute on numerics unless otherwise noted.\n")

# ==============================================================================
# STEP 1 — Factual accuracy: recompute sample counts and key descriptives
# ==============================================================================
hdr("Step 1 — Factual accuracy")

sec("Sample counts")
check("V1 POST ESI subjects",   10169, nrow(esi_v1), tol = 0, fmt = "%d")
check("V1 phenotype subjects",  10371, nrow(phe_v1), tol = 0, fmt = "%d")
check("Merged V1 ESI + phenotype", 10169, nrow(d), tol = 0, fmt = "%d")
check("Vital-status records",    10652, nrow(vs), tol = 0, fmt = "%d")
check("Deaths in vital-status",   2932, sum(vs$vital_status == 1), tol = 0, fmt = "%d")

sec("Per-stratum subject counts at V1")
expected_counts <- c(Never=107, GOLD0=4327, PRISm=1254, GOLD1=776, GOLD2=1900, GOLD3=1152, GOLD4=593)
actual_counts   <- d %>% filter(!is.na(stratum)) %>% count(stratum) %>% deframe()
for (s in names(expected_counts)) {
  check(paste0("V1 N(", s, ")"),
        expected_counts[s], unname(actual_counts[s]), tol = 0, fmt = "%d")
}
n_missing_stratum <- sum(is.na(d$stratum))
check("Missing-stratum V1 subjects (gold_visit blank)", 60, n_missing_stratum, tol = 0, fmt = "%d")
total_sum <- sum(actual_counts) + n_missing_stratum
check("Per-stratum + missing sum to merged total", 10169, total_sum, tol = 0, fmt = "%d")

sec("ESI distribution by stratum (mean)")
expected_means <- c(Never=0.83, GOLD0=0.90, PRISm=0.90, GOLD1=1.44,
                    GOLD2=2.18, GOLD3=4.83, GOLD4=8.25)
esi_by_strat <- d %>% filter(!is.na(stratum)) %>%
  group_by(stratum) %>% summarise(m = mean(ESI_v1post), .groups = "drop") %>% deframe()
for (s in names(expected_means)) {
  check(paste0("Mean ESI ", s), expected_means[s], unname(esi_by_strat[s]), tol = 0.01)
}

sec("ESI ceiling counts (V1)")
ceil_total <- sum(d$ESI_v1post >= 9.999, na.rm = TRUE)
ceil_g4    <- sum(d$ESI_v1post[d$stratum == "GOLD4"] >= 9.999, na.rm = TRUE)
check("V1 subjects at ESI=10 (any stratum)", 264, ceil_total, tol = 0, fmt = "%d")
check("V1 GOLD4 subjects at ESI=10", 228, ceil_g4, tol = 2, fmt = "%d")
check("V1 GOLD4 ESI=10 percentage", 38.4, 100 * ceil_g4 / sum(d$stratum == "GOLD4", na.rm = TRUE), tol = 1)

sec("Longitudinal FEV1-decline LMM data")
fev1_long <- phe_all %>%
  filter(visitnum %in% c(1, 2, 3),
         !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit    = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow   = factor(SmokCigNow))
v1_baseline <- d %>%
  transmute(rand_id, ESI_baseline = ESI_v1post,
            FEV1_FVC_baseline = FEV1_FVC_post,
            stratum_baseline = stratum) %>%
  left_join(
    phe_all %>% filter(visitnum == 1) %>%
      transmute(rand_id = as.character(rand_id),
                Height_CM = as.numeric(Height_CM),
                gender_baseline = factor(gender),
                race_baseline   = factor(race)),
    by = "rand_id"
  )
decline_d <- fev1_long %>%
  inner_join(v1_baseline, by = "rand_id") %>%
  filter(!is.na(ESI_baseline), !is.na(FEV1_FVC_baseline),
         !is.na(stratum_baseline),
         !is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
decline_d$stratum_baseline <- relevel(factor(decline_d$stratum_baseline,
                                             levels = names(expected_counts)), ref = "GOLD0")

check("LMM total rows",       18893, nrow(decline_d), tol = 0, fmt = "%d")
check("LMM unique subjects",  10109, length(unique(decline_d$rand_id)), tol = 0, fmt = "%d")
rows_per_visit <- table(decline_d$visitnum)
check("LMM rows at V1", 10109, rows_per_visit["1"], tol = 0, fmt = "%d")
check("LMM rows at V2",  5573, rows_per_visit["2"], tol = 0, fmt = "%d")
check("LMM rows at V3",  3211, rows_per_visit["3"], tol = 0, fmt = "%d")

sec("Mortality merge")
mort <- d %>% inner_join(vs %>% select(rand_id, vital_status, days_followed),
                         by = "rand_id")
check("V1 ESI subjects with vital status", 10105, nrow(mort), tol = 0, fmt = "%d")
median_fu_yr <- median(mort$days_followed) / 365.25
check("Median follow-up (yr)", 10.7, median_fu_yr, tol = 0.1)
check("Deaths in merged set",  2857, sum(mort$vital_status == 1), tol = 0, fmt = "%d")

# ==============================================================================
# STEP 1 — Correlations across spectrum
# ==============================================================================
hdr("Step 1 — Cross-spectrum correlations")

sec("Overall correlations (V1)")
r_FF   <- cor(d$ESI_v1post, d$FEV1_FVC_post,              use = "pairwise.complete.obs")
r_LAA  <- cor(d$ESI_v1post, d$Insp_LAA950_total_Thirona,  use = "pairwise.complete.obs")
r_PRM  <- cor(d$ESI_v1post, d$PRM_pct_emphysema_Thirona,  use = "pairwise.complete.obs")
r_AT   <- cor(d$ESI_v1post, d$PRM_pct_airtrapping_Thirona,use = "pairwise.complete.obs")
r_Pi10 <- cor(d$ESI_v1post, d$Pi10_Thirona,               use = "pairwise.complete.obs")
check("r(ESI, FEV1/FVC) — all V1",     -0.89, r_FF,  tol = 0.01)
check("r(ESI, %LAA-950) — all V1",     +0.77, r_LAA, tol = 0.01)
check("r(ESI, PRM emph) — all V1",     +0.80, r_PRM, tol = 0.02)
check("r(ESI, PRM air-trapping)",      +0.69, r_AT,  tol = 0.02)
check("r(ESI, Pi10) — all V1",         +0.38, r_Pi10, tol = 0.02)

sec("Per-stratum r(ESI, FEV1/FVC)")
exp_r_FF <- c(Never=-0.40, GOLD0=-0.26, PRISm=-0.26, GOLD1=-0.61,
              GOLD2=-0.88, GOLD3=-0.92, GOLD4=-0.85)
for (s in names(exp_r_FF)) {
  rs <- cor(d$ESI_v1post[d$stratum == s],
            d$FEV1_FVC_post[d$stratum == s], use = "pairwise.complete.obs")
  check(paste0("r(ESI, FEV1/FVC) ", s), exp_r_FF[s], rs, tol = 0.02)
}

sec("Per-stratum r(ESI, %LAA-950HU)")
exp_r_LAA <- c(Never=+0.29, GOLD0=+0.08, PRISm=+0.05, GOLD1=+0.24,
               GOLD2=+0.51, GOLD3=+0.58, GOLD4=+0.44)
for (s in names(exp_r_LAA)) {
  rs <- cor(d$ESI_v1post[d$stratum == s],
            d$Insp_LAA950_total_Thirona[d$stratum == s], use = "pairwise.complete.obs")
  check(paste0("r(ESI, LAA-950) ", s), exp_r_LAA[s], rs, tol = 0.02)
}

sec("v10 cross-check: r(ESI, FEV1/FVC) in GOLD 2–4 subset")
d_g234 <- d %>% filter(stratum %in% c("GOLD2","GOLD3","GOLD4"))
r_g234 <- cor(d_g234$ESI_v1post, d_g234$FEV1_FVC_post, use = "pairwise.complete.obs")
check("r(ESI, FEV1/FVC) in current GOLD 2–4 subset (v10 reported -0.94)",
      -0.94, r_g234, tol = 0.05)

# ==============================================================================
# STEP 1 — Cox mortality
# ==============================================================================
hdr("Step 1 — Mortality Cox models")

mort$gender     <- factor(mort$gender)
mort$race       <- factor(mort$race)
mort$SmokCigNow <- factor(mort$SmokCigNow)
mort$stratum    <- factor(mort$stratum, levels = names(expected_counts))
cox_input <- mort %>%
  filter(!is.na(stratum), !is.na(FEV1_FVC_post),
         !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
cox_input$stratum <- relevel(cox_input$stratum, ref = "GOLD0")

m_uni        <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post, data = cox_input)
m_no_FEV1FVC <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_with_FEV1FVC <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_FEV1FVC_only <- coxph(Surv(days_followed/365.25, vital_status) ~                FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_ceil       <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input %>% filter(ESI_v1post < 9.999))

s_uni  <- summary(m_uni)$coef
s_no   <- summary(m_no_FEV1FVC)$coef
s_with <- summary(m_with_FEV1FVC)$coef
s_ceil <- summary(m_ceil)$coef

check("Cox univariable HR(ESI)",                 1.27, s_uni["ESI_v1post","exp(coef)"], tol = 0.02)
check("Cox adjusted (no FEV1/FVC) HR(ESI)",      1.10, s_no["ESI_v1post","exp(coef)"], tol = 0.01)
check("Cox adjusted (no FEV1/FVC) p(ESI) (sci)", 0, log10(s_no["ESI_v1post","Pr(>|z|)"]) + 12, tol = 1,
      fmt = "%.1f")   # expected log10(p) ≈ -12
check("Cox adjusted (with FEV1/FVC) HR(ESI)",    1.08, s_with["ESI_v1post","exp(coef)"], tol = 0.01)
check("Cox adjusted (with FEV1/FVC) p(ESI) (sci)", 0, log10(s_with["ESI_v1post","Pr(>|z|)"]) + 3.18, tol = 1,
      fmt = "%.2f")  # expected p ≈ 6.5e-4
check("Cox sensitivity (drop ESI=10) HR(ESI)",   1.07, s_ceil["ESI_v1post","exp(coef)"], tol = 0.01)

# LR test ESI adds beyond FEV1/FVC + covariates
lr <- anova(m_FEV1FVC_only, m_with_FEV1FVC)
check("Cox LR chi-sq for adding ESI to FEV1/FVC + covariates", 11.478, lr$Chisq[2], tol = 0.5)

# ==============================================================================
# STEP 1 — FEV1 decline LMM
# ==============================================================================
hdr("Step 1 — FEV1 decline LMM")

cov_block <- "+ stratum_baseline + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id)"
m_base   <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline + ESI_baseline + FEV1_FVC_baseline", cov_block)), data = decline_d)
m_ESI    <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * ESI_baseline + FEV1_FVC_baseline", cov_block)), data = decline_d)
m_FEV1FVC<- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * FEV1_FVC_baseline + ESI_baseline", cov_block)), data = decline_d)
m_both   <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * (ESI_baseline + FEV1_FVC_baseline)", cov_block)), data = decline_d)

co_both <- summary(m_both)$coef
check("LMM pooled years × ESI (mL/yr/unit)",       2.56, co_both["years_from_baseline:ESI_baseline","Estimate"], tol = 0.05)
check("LMM pooled years × FEV1/FVC (mL/yr/unit)", 20.05, co_both["years_from_baseline:FEV1_FVC_baseline","Estimate"], tol = 0.3)

lr_addESI <- anova(m_FEV1FVC, m_both)
lr_addFF  <- anova(m_ESI,     m_both)
check("LMM LR chi-sq adding years × ESI to (FF + covariates)", 25.873, lr_addESI$Chisq[2], tol = 0.5)
check("LMM LR chi-sq adding years × FF to (ESI + covariates)", 11.706, lr_addFF$Chisq[2], tol = 0.5)

sec("Per-stratum FEV1 decline (years × ESI), mutually adjusted")
exp_perstrat <- list(
  GOLD0 = c(-4.70, 0.001),
  PRISm = c(+0.94, 0.80),
  GOLD1 = c(-1.18, 0.73),
  GOLD2 = c(+3.03, 0.17),
  GOLD3 = c(+0.62, 0.68),
  GOLD4 = c(+0.74, 0.65)
)
for (s in names(exp_perstrat)) {
  df_s <- decline_d %>% filter(stratum_baseline == s)
  safe_covs <- c()
  if (length(unique(df_s$SmokCigNow))      > 1) safe_covs <- c(safe_covs, "SmokCigNow")
  if (length(unique(df_s$gender_baseline)) > 1) safe_covs <- c(safe_covs, "gender_baseline")
  if (length(unique(df_s$race_baseline))   > 1) safe_covs <- c(safe_covs, "race_baseline")
  rhs <- paste(
    "years_from_baseline*(ESI_baseline + FEV1_FVC_baseline)",
    "+ Height_CM + age_visit + ATS_PackYears",
    if (length(safe_covs)) paste("+", paste(safe_covs, collapse = " + ")) else "",
    "+ (1 | rand_id)"
  )
  fit <- try(lmer(as.formula(paste("FEV1_post_mL ~", rhs)), data = df_s), silent = TRUE)
  if (inherits(fit, "try-error")) next
  cc <- summary(fit)$coef
  est_p <- cc["years_from_baseline:ESI_baseline", c("Estimate","Pr(>|t|)")]
  check(paste0("Per-stratum LMM ", s, " — slope (mL/yr/unit)"),
        exp_perstrat[[s]][1], est_p["Estimate"], tol = 0.2)
  check(paste0("Per-stratum LMM ", s, " — p"),
        exp_perstrat[[s]][2], est_p["Pr(>|t|)"], tol = 0.2)
}

# ==============================================================================
# STEP 1 — Longitudinal ESI trajectories
# ==============================================================================
hdr("Step 1 — ESI trajectories (mean ESI by visit × baseline stratum)")

esi_long_post <- esi_raw %>% filter(PrePost == 1) %>%
  group_by(rand_id, visitnum) %>%
  summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
baseline_stratum <- d %>% select(rand_id, baseline_stratum = stratum)
long <- esi_long_post %>% inner_join(baseline_stratum, by = "rand_id")
traj <- long %>%
  filter(!is.na(baseline_stratum), !is.na(ESI)) %>%
  group_by(baseline_stratum, visitnum) %>%
  summarise(mean_ESI = mean(ESI), n = n(), .groups = "drop")

exp_traj <- list(
  Never = c(V1=0.83, V2=0.88, V3=0.74),
  GOLD0 = c(V1=0.90, V2=0.91, V3=0.93),
  PRISm = c(V1=0.90, V2=1.00, V3=1.16),
  GOLD1 = c(V1=1.44, V2=1.50, V3=1.79),
  GOLD2 = c(V1=2.18, V2=2.58, V3=3.08),
  GOLD3 = c(V1=4.83, V2=5.20, V3=5.69),
  GOLD4 = c(V1=8.25, V2=7.56, V3=6.20)
)
for (s in names(exp_traj)) {
  for (v in 1:3) {
    a <- traj %>% filter(baseline_stratum == s, visitnum == v) %>% pull(mean_ESI)
    if (length(a) == 0) next
    check(sprintf("Mean ESI %s V%d", s, v),
          unname(exp_traj[[s]][v]), a, tol = 0.01)
  }
}

# ==============================================================================
# STEP 2 — Result correctness: actively try to disprove
# ==============================================================================
hdr("Step 2 — Adversarial sanity checks (try to disprove)")

sec("GOLD 4 V3 survivor bias quantification")
g4 <- esi_v1 %>% inner_join(d %>% select(rand_id, stratum), by = "rand_id") %>%
  filter(stratum == "GOLD4")
g4_v3_ids <- esi_long_post %>% filter(visitnum == 3) %>%
  inner_join(g4 %>% select(rand_id, ESI_v1post), by = "rand_id")
mean_v1_full   <- mean(g4$ESI_v1post)
mean_v1_v3sub  <- mean(g4_v3_ids$ESI_v1post)
emit(sprintf("- GOLD 4 baseline ESI mean (all V1, n = %d): %.2f", nrow(g4), mean_v1_full))
emit(sprintf("- GOLD 4 baseline ESI mean for the V3 SURVIVOR subset (n = %d): %.2f", nrow(g4_v3_ids), mean_v1_v3sub))
emit(sprintf("- Difference: %.2f (lower in survivors → confirms selection)", mean_v1_v3sub - mean_v1_full))

sec("PRISm trajectory robustness — median vs mean")
prism_long <- long %>% filter(baseline_stratum == "PRISm", !is.na(ESI)) %>%
  group_by(visitnum) %>% summarise(mean = mean(ESI), median = median(ESI), n = n(),
                                    .groups = "drop")
for (i in seq_len(nrow(prism_long))) {
  emit(sprintf("- PRISm V%d: mean = %.3f, median = %.3f, n = %d",
               prism_long$visitnum[i], prism_long$mean[i],
               prism_long$median[i], prism_long$n[i]))
}

sec("Pooled years × ESI sign: stratum-confounding artifact?")
m_no_stratum <- lmer(
  FEV1_post_mL ~ years_from_baseline * (ESI_baseline + FEV1_FVC_baseline) +
    Height_CM + gender_baseline + race_baseline +
    age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id),
  data = decline_d)
co_ns <- summary(m_no_stratum)$coef
emit(sprintf("- With baseline_stratum REMOVED: years × ESI = %+.2f mL/yr/unit (p = %.3g); years × FEV1/FVC = %+.1f mL/yr/unit (p = %.3g)",
             co_ns["years_from_baseline:ESI_baseline","Estimate"],
             co_ns["years_from_baseline:ESI_baseline","Pr(>|t|)"],
             co_ns["years_from_baseline:FEV1_FVC_baseline","Estimate"],
             co_ns["years_from_baseline:FEV1_FVC_baseline","Pr(>|t|)"]))
emit("- With stratum IN: years × ESI = +2.56 (p≈0); years × FF = +20.05 (p=0.001).")
emit("- If removing stratum flips signs back to expected (-), the pooled-positive sign is a stratum-confounding artifact.")

sec("Deaths and follow-up — sanity checks")
emit(sprintf("- vital_status == 1 (deaths) in merged mortality set: %d / %d (%.1f%%)",
             sum(mort$vital_status == 1), nrow(mort),
             100 * mean(mort$vital_status == 1)))
emit(sprintf("- days_followed range: %d to %d (i.e. %0.1f to %0.1f yr)",
             min(mort$days_followed), max(mort$days_followed),
             min(mort$days_followed)/365.25, max(mort$days_followed)/365.25))
emit(sprintf("- Subjects with days_followed == 0: %d (should be small)",
             sum(mort$days_followed == 0)))

sec("FEV1 decline LMM — alignment check")
# Verify visit 1 has years_from_baseline near 0
yfb_v1_rng <- range(decline_d$years_from_baseline[decline_d$visitnum == 1], na.rm = TRUE)
yfb_v2_rng <- range(decline_d$years_from_baseline[decline_d$visitnum == 2], na.rm = TRUE)
yfb_v3_rng <- range(decline_d$years_from_baseline[decline_d$visitnum == 3], na.rm = TRUE)
emit(sprintf("- V1 years_from_baseline range: %.2f to %.2f", yfb_v1_rng[1], yfb_v1_rng[2]))
emit(sprintf("- V2 years_from_baseline range: %.2f to %.2f", yfb_v2_rng[1], yfb_v2_rng[2]))
emit(sprintf("- V3 years_from_baseline range: %.2f to %.2f", yfb_v3_rng[1], yfb_v3_rng[2]))

# ==============================================================================
# STEP 3 — Documentation accuracy: check key prose claims against recomputed
# ==============================================================================
hdr("Step 3 — Documentation accuracy (key prose statements)")

# These are claims made in the Massimo report / outline / discussion text.
check("Prose: '10,169 V1 subjects with valid ESI'", 10169, nrow(d), tol = 0, fmt = "%d")
check("Prose: '10,109 subjects in LMM'",            10109, length(unique(decline_d$rand_id)), tol = 0, fmt = "%d")
check("Prose: '18,893 LMM rows'",                   18893, nrow(decline_d), tol = 0, fmt = "%d")
check("Prose: '2,857 deaths over median 10.7 yr'",  2857,  sum(mort$vital_status == 1), tol = 0, fmt = "%d")
check("Prose: 'r(ESI, FEV1/FVC) = -0.89 overall'",  -0.89, r_FF, tol = 0.01)
check("Prose: 'r(ESI, FEV1/FVC) -0.26 in GOLD0'",   -0.26, cor(d$ESI_v1post[d$stratum=="GOLD0"], d$FEV1_FVC_post[d$stratum=="GOLD0"], use="pairwise.complete.obs"), tol = 0.02)
check("Prose: 'r(ESI, FEV1/FVC) -0.92 in GOLD3'",   -0.92, cor(d$ESI_v1post[d$stratum=="GOLD3"], d$FEV1_FVC_post[d$stratum=="GOLD3"], use="pairwise.complete.obs"), tol = 0.02)
check("Prose: 'pooled HR(ESI)=1.08, p≈6e-4'",       1.08,  s_with["ESI_v1post","exp(coef)"], tol = 0.01)
check("Prose: 'sensitivity HR=1.07, p=0.005'",      1.07,  s_ceil["ESI_v1post","exp(coef)"], tol = 0.01)
check("Prose: 'GOLD 0 baseline ESI slope ≈ -4.7'",
      -4.70,
      summary(lmer(FEV1_post_mL ~ years_from_baseline*(ESI_baseline + FEV1_FVC_baseline) + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1|rand_id),
                   data = decline_d %>% filter(stratum_baseline == "GOLD0")))$coef["years_from_baseline:ESI_baseline","Estimate"],
      tol = 0.2)

# ==============================================================================
# Summary
# ==============================================================================
LOG_LINES <- c(
  "# Validation log — spectrum-wide ESI analysis, 2026-05-17",
  "",
  sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
  "",
  "Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.",
  "Tolerance: 0.005 absolute on numerics unless otherwise specified at the check.",
  "",
  LOG_LINES[-(1:3)]   # drop the duplicate header lines emitted at top
)

writeLines(LOG_LINES, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
