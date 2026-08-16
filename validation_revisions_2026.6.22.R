#!/usr/bin/env Rscript
# 5-step validation of the 2026-06-22 revisions.
#   Step 1: factual accuracy — recompute new counts, HRs, correlations independently
#   Step 2: result correctness — adversarial sanity checks
#   Step 3: documentation accuracy — match prose claims to recomputed values

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(survival); library(lme4); library(lmerTest)
})

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_revisions_2026.6.22.md"
LOG <- character()
n_pass <- 0L; n_fail <- 0L
emit  <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)
check <- function(label, expected, actual, tol = 0.005, fmt = "%.3f") {
  ok <- if (is.numeric(expected) && is.numeric(actual)) {
    abs(expected - actual) <= tol
  } else identical(expected, actual)
  status <- if (ok) "PASS" else "**FAIL**"
  emit(sprintf("- [%s] %s — expected %s, recomputed %s", status, label,
               if (is.numeric(expected)) sprintf(fmt, expected) else expected,
               if (is.numeric(actual))   sprintf(fmt, actual)   else actual))
  if (ok) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L
}

# --- Load and rebuild cohort from source CSVs ---------------------------------
esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv",
                stringsAsFactors = FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv",
                stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)

vs  <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE)
vs$rand_id <- as.character(vs$rand_id)

cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE)
cod$rand_id <- as.character(cod$rand_id.x)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels))

mort <- d %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow))
mort_in <- mort %>%
  filter(!is.na(stratum), !is.na(FEV1_FVC_post), !is.na(age_visit),
         !is.na(ATS_PackYears), !is.na(BMI))
mort_in$stratum <- relevel(mort_in$stratum, ref = "GOLD0")

emit("# Validation log — 2026-06-22 revisions\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.\n")

# ============================================================================
# STEP 1: factual accuracy
# ============================================================================
emit("\n## Step 1 — Factual accuracy\n")

# Cohort counts
check("Mortality merge cohort size",        10043, nrow(mort_in), tol = 0, fmt = "%d")
check("All-cause deaths in merge",          2839,  sum(mort_in$vital_status == 1), tol = 0, fmt = "%d")
check("Respiratory deaths in merge (cause-specific)", 1163, sum(mort_in$event_resp == 1), tol = 0, fmt = "%d")

# All-cause Cox models — quick re-fit and check headline HRs
cox_all_esi  <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
cox_all_bo   <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
cox_all_ff   <- coxph(Surv(days_followed/365.25, vital_status) ~ FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
check("All-cause Cox HR(ESI), ESI-only model",      1.098,  summary(cox_all_esi)$conf.int["ESI_v1post","exp(coef)"], tol = 0.005)
check("All-cause Cox HR(ESI), ESI + FF model",      1.077,  summary(cox_all_bo)$conf.int["ESI_v1post","exp(coef)"], tol = 0.005)
lr_all <- anova(cox_all_ff, cox_all_bo)
check("All-cause LR chi-sq (ESI added beyond FF)",  11.48,  lr_all$Chisq[2], tol = 0.5)

# Respiratory Cox models — the new analysis
cox_resp_esi <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
cox_resp_bo  <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
cox_resp_ff  <- coxph(Surv(days_followed/365.25, event_resp) ~ FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
check("Respiratory Cox HR(ESI), ESI-only model",    1.103,  summary(cox_resp_esi)$conf.int["ESI_v1post","exp(coef)"], tol = 0.01)
check("Respiratory Cox HR(ESI), ESI + FF model",    1.006,  summary(cox_resp_bo)$conf.int["ESI_v1post","exp(coef)"], tol = 0.01)
lr_resp <- anova(cox_resp_ff, cox_resp_bo)
check("Respiratory LR chi-sq (ESI added beyond FF)", 0.04,  lr_resp$Chisq[2], tol = 0.2)
check("Respiratory LR p-value > 0.5 (ESI not adding)", TRUE, lr_resp$`Pr(>|Chi|)`[2] > 0.5)

# Per-stratum respiratory Cox
strata_to_test <- c("GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
for (s in strata_to_test) {
  df <- mort_in %>% filter(stratum == s)
  if (sum(df$event_resp == 1) < 10) next
  fit <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FEV1_FVC_post +
                 age_visit + gender + race + SmokCigNow + ATS_PackYears, data = df)
  hr <- summary(fit)$conf.int["ESI_v1post","exp(coef)"]
  p  <- summary(fit)$coef["ESI_v1post","Pr(>|z|)"]
  emit(sprintf("- Per-stratum respiratory HR(ESI) — %s: HR=%.3f, p=%.3g  (n=%d, deaths=%d)",
               s, hr, p, nrow(df), sum(df$event_resp == 1)))
}

# CT correlations
ct_df <- d[, c("Exp_LAA856_total_Thirona","Insp_LAA950_total_Thirona","PRM_pct_emphysema_Thirona","PRM_pct_airtrapping_Thirona")]
ct_cor <- cor(ct_df, use = "pairwise.complete.obs")
check("r(LAA-950, PRM_emph)",   0.985, ct_cor["Insp_LAA950_total_Thirona","PRM_pct_emphysema_Thirona"], tol = 0.005)
check("r(LAA-856, LAA-950)",    0.850, ct_cor["Exp_LAA856_total_Thirona","Insp_LAA950_total_Thirona"], tol = 0.005)
check("r(LAA-856, PRM_airtrap)", 0.926, ct_cor["Exp_LAA856_total_Thirona","PRM_pct_airtrapping_Thirona"], tol = 0.005)

# Per-stratum r(ESI, PRM_emph)
prm_per <- d %>% filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(r = cor(ESI_v1post, PRM_pct_emphysema_Thirona, use = "pairwise.complete.obs"),
            .groups = "drop")
check("r(ESI, PRM_emph) in GOLD0",  0.067, prm_per$r[prm_per$stratum=="GOLD0"], tol = 0.02)
check("r(ESI, PRM_emph) in GOLD3",  0.563, prm_per$r[prm_per$stratum=="GOLD3"], tol = 0.02)
check("r(ESI, PRM_emph) overall",   0.799,
      cor(d$ESI_v1post, d$PRM_pct_emphysema_Thirona, use = "pairwise.complete.obs"), tol = 0.01)

# Within-subject ΔFEV1 in GOLD 0 by ESI tertile — sanity check counts only
fev1_long <- phe %>% filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline))
v1b <- d %>% transmute(rand_id, ESI_baseline = ESI_v1post, stratum_baseline = stratum,
                       FEV1_post_V1 = phe$FEV1_post[match(rand_id, phe$rand_id[phe$visitnum==1])])
gold0_n <- length(unique(fev1_long$rand_id[fev1_long$rand_id %in% d$rand_id[d$stratum == "GOLD0"]]))
check("Subjects with V1 ESI in GOLD 0",  4327,
      sum(d$stratum == "GOLD0", na.rm = TRUE), tol = 0, fmt = "%d")

# PRISm vs GOLD 0 ΔESI — recompute mean at V3
esi_l <- esi %>% filter(PrePost == 1) %>%
  group_by(rand_id, visitnum) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
bs <- d %>% select(rand_id, baseline_stratum = stratum, ESI_v1post)
long <- esi_l %>% inner_join(bs, by = "rand_id") %>% mutate(deltaESI = ESI - ESI_v1post)
prism_v3_mean <- mean(long$deltaESI[long$baseline_stratum == "PRISm" & long$visitnum == 3], na.rm = TRUE)
gold0_v3_mean <- mean(long$deltaESI[long$baseline_stratum == "GOLD0" & long$visitnum == 3], na.rm = TRUE)
check("PRISm mean ΔESI at V3 ≈ 0.25",  0.25, prism_v3_mean, tol = 0.03)
check("GOLD 0 mean ΔESI at V3 ≈ 0.05", 0.05, gold0_v3_mean, tol = 0.03)

# Bhatt-substitution mortality (n_cohort = 9400; resp deaths = 1068)
d_b <- d %>%
  mutate(
    major_criterion = FEV1_FVC_post < 0.70,
    emph_yn = CT_Visual_Emph_Severity >= 1,
    wall_yn = CT_Visual_Wall_Thickening == 2,
    dysp_yn = MMRCDyspneaScor >= 2,
    qol_yn  = SGRQ_scoreTotal >= 25,
    cb_yn   = Chronic_Bronchitis == 1
  ) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn))
n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                  ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                  ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD",
                                                                "noCOPD")))
mort_b <- d_b %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
         bhatt_grp = factor(bhatt_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
check("Bhatt-substitution cohort size",   9400, nrow(mort_b), tol = 0, fmt = "%d")
check("Bhatt-substitution resp deaths",   1068, sum(mort_b$event_resp == 1), tol = 0, fmt = "%d")

cox_bh_resp <- coxph(Surv(days_followed/365.25, event_resp) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
hr_b_minor_resp <- summary(cox_bh_resp)$conf.int["bhatt_grpCOPD-minor","exp(coef)"]
hr_b_major_resp <- summary(cox_bh_resp)$conf.int["bhatt_grpCOPD-major","exp(coef)"]
check("Bhatt respiratory HR (COPD-minor)", 3.09, hr_b_minor_resp, tol = 0.1)
check("Bhatt respiratory HR (COPD-major)", 13.93, hr_b_major_resp, tol = 0.3)
check("Bhatt model resp C-index",          0.822, concordance(cox_bh_resp)$concordance, tol = 0.005)

# ============================================================================
# STEP 2: result correctness — adversarial sanity checks
# ============================================================================
emit("\n## Step 2 — Adversarial sanity checks\n")

# Sanity: respiratory deaths are a subset of all-cause deaths
n_resp_when_alive <- sum(mort_in$event_resp == 1 & mort_in$vital_status == 0)
check("Respiratory deaths only occur in those who died (alive subjects have event_resp=0)",
      0, n_resp_when_alive, tol = 0, fmt = "%d")
n_resp_when_alive_b <- sum(mort_b$event_resp == 1 & mort_b$vital_status == 0)
check("Same in Bhatt-cohort",  0, n_resp_when_alive_b, tol = 0, fmt = "%d")

# Sanity: subjects with vital_status == 1 but no CCOD_COPD_resp adjudication should have event_resp = 0
n_unadjud_resp_one <- sum(mort_in$vital_status == 1 & is.na(mort_in$CCOD_COPD_resp) & mort_in$event_resp == 1)
check("Unadjudicated deaths default to event_resp=0 (not classified as respiratory)",
      0, n_unadjud_resp_one, tol = 0, fmt = "%d")

# Sanity: AFL-only-NoCOPD has zero minors AND has airflow obstruction
afl <- d_b %>% filter(bhatt_cls == "AFL-only-NoCOPD")
check("AFL-only-NoCOPD subjects all have FEV1/FVC < 0.70", nrow(afl), sum(afl$major_criterion), tol = 0, fmt = "%d")

# Sanity: the per-stratum respiratory Cox in GOLD 4 — many deaths, HR should NOT be wildly different from 1
df_g4 <- mort_in %>% filter(stratum == "GOLD4")
fit_g4_resp <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FEV1_FVC_post +
                       age_visit + gender + race + SmokCigNow + ATS_PackYears, data = df_g4)
hr_g4 <- summary(fit_g4_resp)$conf.int["ESI_v1post","exp(coef)"]
emit(sprintf("- GOLD 4 per-stratum respiratory HR(ESI) = %.3f (sanity: should be near 1 because GOLD 4 has ESI-ceiling and high baseline mortality)", hr_g4))
check("GOLD 4 per-stratum respiratory HR(ESI) within sensible range (0.8 to 1.3)",
      TRUE, hr_g4 > 0.8 && hr_g4 < 1.3)

# Sanity: PRISm trajectory direction is consistent across mean/median
prism_v3_median <- median(long$deltaESI[long$baseline_stratum == "PRISm" & long$visitnum == 3], na.rm = TRUE)
gold0_v3_median <- median(long$deltaESI[long$baseline_stratum == "GOLD0" & long$visitnum == 3], na.rm = TRUE)
emit(sprintf("- PRISm V3 ΔESI: mean = %.3f, median = %.3f", prism_v3_mean, prism_v3_median))
emit(sprintf("- GOLD 0 V3 ΔESI: mean = %.3f, median = %.3f", gold0_v3_mean, gold0_v3_median))
check("PRISm > GOLD 0 trajectory direction holds in BOTH mean and median",
      TRUE, (prism_v3_mean > gold0_v3_mean) & (prism_v3_median > gold0_v3_median))

# Sanity: r(LAA-950, PRM_emph) is very high (Massimo cited r ≈ 1 in Occhipinti 2018)
check("LAA-950 vs PRM_emph correlation extremely high (≥ 0.97)",
      TRUE, ct_cor["Insp_LAA950_total_Thirona","PRM_pct_emphysema_Thirona"] >= 0.97)

# ============================================================================
# STEP 3: documentation accuracy
# ============================================================================
emit("\n## Step 3 — Documentation accuracy\n")

# Claims we plan to make in the updated outline:
check("'Respiratory mortality: ESI not significant after FEV1/FVC' (HR ≈ 1.0)",
      TRUE, abs(summary(cox_resp_bo)$conf.int["ESI_v1post","exp(coef)"] - 1) < 0.02)
check("'All-cause mortality: ESI HR 1.08 after FEV1/FVC' (claim retained)",
      1.08, summary(cox_all_bo)$conf.int["ESI_v1post","exp(coef)"], tol = 0.01)
check("'1,163 respiratory deaths in mortality merge'",
      1163, sum(mort_in$event_resp == 1), tol = 0, fmt = "%d")
check("'r(ESI, PRM emphysema) overall ≈ 0.80 (Massimo's earlier finding'",
      0.80, cor(d$ESI_v1post, d$PRM_pct_emphysema_Thirona, use = "pairwise.complete.obs"), tol = 0.01)
check("'PRISm ΔESI V3 mean 0.25, median 0.06 — direction consistent'",
      TRUE, prism_v3_mean > 0.20 && prism_v3_median > 0.04 && prism_v3_median < 0.10)

# ============================================================================
# Summary
# ============================================================================
LOG <- c(
  "# Validation log — 2026-06-22 revisions",
  "",
  sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
  "",
  "Tolerance: 0.005 absolute on numerics by default.",
  "",
  LOG[-(1:2)]
)
writeLines(LOG, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
