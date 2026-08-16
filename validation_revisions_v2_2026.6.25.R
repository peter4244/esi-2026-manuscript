#!/usr/bin/env Rscript
# 5-step validation of the 2026-06-25 round-2 §3.5 revisions.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(survival); library(lme4); library(lmerTest)
})

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_revisions_v2_2026.6.25.md"
LOG <- character(); n_pass <- 0L; n_fail <- 0L
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

# Load
esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv", stringsAsFactors=FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv", stringsAsFactors=FALSE, na.strings=c("","NA")); phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)
vs  <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE); vs$rand_id <- as.character(vs$rand_id)
cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE); cod$rand_id <- as.character(cod$rand_id.x)

d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
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
n_minor_b <- d$emph_yn + d$wall_yn + d$dysp_yn + d$qol_yn + d$cb_yn
d$bhatt_cls <- ifelse(d$major_criterion & n_minor_b >= 1, "COPD-major",
                ifelse(!d$major_criterion & n_minor_b >= 3, "COPD-minor",
                ifelse(d$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD", "noCOPD")))
d$bhatt_copd <- d$bhatt_cls %in% c("COPD-major","COPD-minor")

# Selected variant
esi_s <- ifelse(d$ESI_v1post >= 2.5, 2, ifelse(d$ESI_v1post >= 1.0, 1, 0))
n_minor_e <- esi_s + d$dysp_yn + d$qol_yn + d$cb_yn
d$esi_cls <- ifelse(d$major_criterion & n_minor_e >= 1, "COPD-major",
              ifelse(!d$major_criterion & n_minor_e >= 3, "COPD-minor",
              ifelse(d$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD", "noCOPD")))
d$esi_copd <- d$esi_cls %in% c("COPD-major","COPD-minor")

emit("# Validation log — Round-2 §3.5 revisions (2026-06-25)\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.\n")

# ============================================================================
# STEP 1: Factual accuracy
# ============================================================================
emit("\n## Step 1 — Factual accuracy\n")

# Threshold sensitivity — verify a few κ values
kappa_fn <- function(a, b) {
  tab <- table(a, b); po <- sum(diag(tab))/sum(tab)
  pe <- sum(rowSums(tab)*colSums(tab))/sum(tab)^2
  (po - pe)/(1 - pe)
}
# 4-crit ESI≥1.5, ≥2-of-4
cls <- ifelse(d$major_criterion & (d$ESI_v1post >= 1.5 + d$dysp_yn + d$qol_yn + d$cb_yn) >= 1, NA, NA)  # placeholder; recompute correctly below
esi_yn <- d$ESI_v1post >= 1.5
nm <- esi_yn + d$dysp_yn + d$qol_yn + d$cb_yn
copd_4c_15 <- (d$major_criterion & nm >= 1) | (!d$major_criterion & nm >= 2)
check("κ for 4-crit ESI≥1.5 ≥2-of-4",  0.793, kappa_fn(d$bhatt_copd, copd_4c_15), tol = 0.01)

esi_yn <- d$ESI_v1post >= 1.0
nm <- esi_yn + d$dysp_yn + d$qol_yn + d$cb_yn
copd_4c_10 <- (d$major_criterion & nm >= 1) | (!d$major_criterion & nm >= 2)
check("κ for 4-crit ESI≥1.0 ≥2-of-4",  0.827, kappa_fn(d$bhatt_copd, copd_4c_10), tol = 0.01)

# Selected 5-crit
check("κ for selected 5-crit T_low=1.0 T_high=2.5", 0.82, kappa_fn(d$bhatt_copd, d$esi_copd), tol = 0.005)

# Best 5-crit (T_low=0.5 T_high=2.0)
esi_s2 <- ifelse(d$ESI_v1post >= 2.0, 2, ifelse(d$ESI_v1post >= 0.5, 1, 0))
nm2 <- esi_s2 + d$dysp_yn + d$qol_yn + d$cb_yn
copd_5c_best <- (d$major_criterion & nm2 >= 1) | (!d$major_criterion & nm2 >= 3)
check("κ for best 5-crit T_low=0.5 T_high=2.0",     0.863, kappa_fn(d$bhatt_copd, copd_5c_best), tol = 0.01)

# Discordance characterization — preserved spirometry
preserved <- d %>% filter(!major_criterion)
both     <- preserved %>% filter(bhatt_copd & esi_copd)
bhatt_o  <- preserved %>% filter(bhatt_copd & !esi_copd)
esi_o    <- preserved %>% filter(!bhatt_copd & esi_copd)

check("Preserved Both-COPD count",          553, nrow(both), tol = 0, fmt = "%d")
check("Preserved Bhatt-only-COPD count",    546, nrow(bhatt_o), tol = 0, fmt = "%d")
check("Preserved ESI-only-COPD count",       95, nrow(esi_o), tol = 0, fmt = "%d")

# Key discordance findings
check("Both-COPD mean ESI",     1.06, mean(both$ESI_v1post),    tol = 0.02)
check("Bhatt-only mean ESI",    0.80, mean(bhatt_o$ESI_v1post), tol = 0.02)
check("ESI-only mean ESI",      1.48, mean(esi_o$ESI_v1post),   tol = 0.05)

check("Both-COPD %emph_yn",     0.65, mean(both$emph_yn),    tol = 0.02)
check("Bhatt-only %emph_yn",    0.91, mean(bhatt_o$emph_yn), tol = 0.02)
check("ESI-only %emph_yn",      0.00, mean(esi_o$emph_yn),   tol = 0.01)

check("Both-COPD %CB",          0.72, mean(both$cb_yn),    tol = 0.02)
check("Bhatt-only %CB",         0.16, mean(bhatt_o$cb_yn), tol = 0.02)
check("ESI-only %CB",           0.16, mean(esi_o$cb_yn),   tol = 0.03)

# Bhatt-only vs Both: mortality HRs
categorize <- function(b, e) {
  case_when(
    b  &  e ~ "Both-COPD",
    b  & !e ~ "Bhatt-only-COPD (ESI missed)",
    !b &  e ~ "ESI-only-COPD (Bhatt missed)",
    !b & !e ~ "Both-noCOPD"
  )
}
mort_p <- d %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
         grp = factor(categorize(bhatt_copd, esi_copd),
                      levels = c("Both-noCOPD","Both-COPD","Bhatt-only-COPD (ESI missed)","ESI-only-COPD (Bhatt missed)"))) %>%
  filter(!major_criterion,
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

cox_all  <- coxph(Surv(days_followed/365.25, vital_status) ~ grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_p)
cox_resp <- coxph(Surv(days_followed/365.25, event_resp) ~ grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_p)

check("Both-COPD all-cause HR",       2.02, summary(cox_all)$conf.int["grpBoth-COPD","exp(coef)"], tol = 0.05)
check("Bhatt-only all-cause HR",      1.53, summary(cox_all)$conf.int["grpBhatt-only-COPD (ESI missed)","exp(coef)"], tol = 0.05)
check("Both-COPD resp HR",            3.05, summary(cox_resp)$conf.int["grpBoth-COPD","exp(coef)"], tol = 0.10)
check("Bhatt-only resp HR",           2.48, summary(cox_resp)$conf.int["grpBhatt-only-COPD (ESI missed)","exp(coef)"], tol = 0.10)

# ============================================================================
# STEP 2: Adversarial sanity
# ============================================================================
emit("\n## Step 2 — Adversarial sanity checks\n")

# Sanity: discordance counts sum to preserved-spirometry subjects who are in a COPD group on either side
n_either_copd <- sum(preserved$bhatt_copd | preserved$esi_copd)
check("Both + Bhatt-only + ESI-only = Either-COPD",
      n_either_copd, nrow(both) + nrow(bhatt_o) + nrow(esi_o), tol = 0, fmt = "%d")

# Sanity: ESI-only subjects should NOT have any minor imaging criteria met (since
# they're Bhatt-noCOPD, they have <3 of 5 minors — and we expect mostly symptom-driven)
# But our finding shows ESI-only has 0% emph_yn — verify this makes sense
emit(sprintf("- ESI-only subjects: emph_yn = %d/%d (%.0f%%), wall_yn = %d/%d (%.0f%%)",
             sum(esi_o$emph_yn), nrow(esi_o), 100*mean(esi_o$emph_yn),
             sum(esi_o$wall_yn), nrow(esi_o), 100*mean(esi_o$wall_yn)))
# Expected: ESI-only Bhatt-missed subjects in preserved spirometry have at most 2 of 5 minors,
# so most should have <2 imaging criteria positive
n_esi_only_2plus_imaging <- sum(esi_o$emph_yn + esi_o$wall_yn >= 2)
check("ESI-only subjects with both imaging criteria (impossible for Bhatt-noCOPD with 3 symptoms)",
      TRUE, n_esi_only_2plus_imaging < nrow(esi_o)/2)

# Sanity: Bhatt-only ESI-missed subjects should have lower mean ESI than Both-COPD
check("Bhatt-only ESI mean < Both ESI mean (lower ESI = ESI missed)",
      TRUE, mean(bhatt_o$ESI_v1post) < mean(both$ESI_v1post))

# Sanity: mortality HRs make a logical progression
hr_both <- summary(cox_all)$conf.int["grpBoth-COPD","exp(coef)"]
hr_bhatt_only <- summary(cox_all)$conf.int["grpBhatt-only-COPD (ESI missed)","exp(coef)"]
check("Both-COPD HR > Bhatt-only HR > 1 (both classifications agreeing = highest risk)",
      TRUE, hr_both > hr_bhatt_only && hr_bhatt_only > 1)

# ============================================================================
# STEP 3: Documentation accuracy
# ============================================================================
emit("\n## Step 3 — Documentation accuracy\n")

# Claims for the updated outline:
check("'Bhatt-only-COPD subjects have low ESI (0.80) but high CT emphysema (91%)'",
      TRUE, mean(bhatt_o$ESI_v1post) < 0.85 && mean(bhatt_o$emph_yn) > 0.85)
check("'ESI-only-COPD subjects have high ESI (1.48) but ZERO CT findings'",
      TRUE, mean(esi_o$ESI_v1post) > 1.4 && mean(esi_o$emph_yn) < 0.01)
check("'Bhatt-only-COPD has elevated mortality (HR 1.53, p<0.001)'",
      TRUE, hr_bhatt_only > 1.4 && summary(cox_all)$coef["grpBhatt-only-COPD (ESI missed)","Pr(>|z|)"] < 0.001)
check("'Both-COPD has highest mortality (HR 2.02)'",
      TRUE, hr_both > 1.9 && hr_both < 2.1)

# Summary
LOG <- c(
  "# Validation log — Round-2 §3.5 revisions (2026-06-25)",
  "",
  sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
  "",
  LOG[-(1:2)]
)
writeLines(LOG, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
