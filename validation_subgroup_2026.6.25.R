#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(dplyr); library(survival); library(lme4); library(lmerTest)
})
select <- dplyr::select

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_subgroup_2026.6.25.md"
LOG <- character(); n_pass <- 0L; n_fail <- 0L
emit  <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)
check <- function(label, expected, actual, tol = 0.02, fmt = "%.3f") {
  if (is.logical(expected) || is.logical(actual)) {
    expected <- unname(as.logical(expected)); actual <- unname(as.logical(actual))
  }
  ok <- if (is.numeric(expected) && is.numeric(actual)) {
    isTRUE(abs(expected - actual) <= tol)
  } else identical(expected, actual)
  if (is.na(ok)) ok <- FALSE
  status <- if (ok) "PASS" else "**FAIL**"
  emit(sprintf("- [%s] %s — expected %s, recomputed %s", status, label,
               if (is.numeric(expected)) sprintf(fmt, expected) else expected,
               if (is.numeric(actual))   sprintf(fmt, actual)   else actual))
  if (ok) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L
}

esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv", stringsAsFactors=FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv", stringsAsFactors=FALSE, na.strings=c("","NA")); phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)
vs <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE); vs$rand_id <- as.character(vs$rand_id)
cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE); cod$rand_id <- as.character(cod$rand_id.x)

d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_CVD, CCOD_Cancer, CCOD_Other), by = "rand_id") %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1, wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2, qol_yn = SGRQ_scoreTotal >= 25, cb_yn = Chronic_Bronchitis == 1,
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn),
         !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))

n_minor_b <- d$emph_yn + d$wall_yn + d$dysp_yn + d$qol_yn + d$cb_yn
d$bhatt <- ifelse(d$major_criterion & n_minor_b >= 1, "COPD-major",
            ifelse(!d$major_criterion & n_minor_b >= 3, "COPD-minor",
            ifelse(d$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD", "noCOPD")))
esi_s <- ifelse(d$ESI_v1post >= 2.5, 2, ifelse(d$ESI_v1post >= 1.0, 1, 0))
n_minor_e <- esi_s + d$dysp_yn + d$qol_yn + d$cb_yn
d$esi_cls <- ifelse(d$major_criterion & n_minor_e >= 1, "COPD-major",
              ifelse(!d$major_criterion & n_minor_e >= 3, "COPD-minor",
              ifelse(d$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD", "noCOPD")))
d$bhatt_grp <- factor(d$bhatt,   levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"))
d$esi_grp   <- factor(d$esi_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"))
d$bhatt_copd <- d$bhatt %in% c("COPD-major","COPD-minor")
d$esi_copd   <- d$esi_cls %in% c("COPD-major","COPD-minor")
d$discord <- factor(with(d, case_when(
  bhatt_copd & esi_copd ~ "Both-COPD",
  bhatt_copd & !esi_copd ~ "Bhatt-only-COPD",
  !bhatt_copd & esi_copd ~ "ESI-only-COPD", TRUE ~ "Both-noCOPD")),
  levels = c("Both-noCOPD","Both-COPD","Bhatt-only-COPD","ESI-only-COPD"))

emit("# Validation log — Subgroup analyses (2026-06-25)\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.\n")
emit("\n## Step 1 — Factual accuracy\n")

covs <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"
mk <- function(c) ifelse(d$vital_status == 1 & !is.na(d[[c]]) & d[[c]] == 1, 1, 0)

# Cause-specific by Bhatt category
get_hr <- function(fit, term) unname(exp(coef(fit)[term]))
ev_cvd <- mk("CCOD_CVD"); ev_canc <- mk("CCOD_Cancer"); ev_oth <- mk("CCOD_Other")

fit_b_cvd <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_cvd) ~ bhatt_grp +", covs)), data = d)
fit_e_cvd <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_cvd) ~ esi_grp +", covs)), data = d)
check("CVD COPD-major (Bhatt) HR ≈ 2.34", 2.336, get_hr(fit_b_cvd, "bhatt_grpCOPD-major"))
check("CVD COPD-major (ESI)   HR ≈ 2.24", 2.235, get_hr(fit_e_cvd, "esi_grpCOPD-major"))
check("CVD COPD-minor (Bhatt) HR ≈ 1.67", 1.667, get_hr(fit_b_cvd, "bhatt_grpCOPD-minor"))
check("CVD COPD-minor (ESI)   HR ≈ 1.87", 1.872, get_hr(fit_e_cvd, "esi_grpCOPD-minor"))

fit_b_canc <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_canc) ~ bhatt_grp +", covs)), data = d)
fit_e_canc <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_canc) ~ esi_grp +", covs)), data = d)
check("Cancer COPD-major (Bhatt) HR ≈ 2.05", 2.054, get_hr(fit_b_canc, "bhatt_grpCOPD-major"))
check("Cancer COPD-minor (Bhatt) HR ≈ 2.32", 2.319, get_hr(fit_b_canc, "bhatt_grpCOPD-minor"))

fit_b_oth <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_oth) ~ bhatt_grp +", covs)), data = d)
check("Other COPD-major (Bhatt) HR ≈ 1.92", 1.922, get_hr(fit_b_oth, "bhatt_grpCOPD-major"))

# Cause-specific by discordance (preserved spirometry)
d_p <- d %>% filter(!major_criterion)
ev_cvd_p <- ifelse(d_p$vital_status == 1 & !is.na(d_p$CCOD_CVD) & d_p$CCOD_CVD == 1, 1, 0)
ev_canc_p <- ifelse(d_p$vital_status == 1 & !is.na(d_p$CCOD_Cancer) & d_p$CCOD_Cancer == 1, 1, 0)

fit_disc_cvd  <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_cvd_p) ~ discord +", covs)), data = d_p)
fit_disc_canc <- coxph(as.formula(paste("Surv(days_followed/365.25, ev_canc_p) ~ discord +", covs)), data = d_p)
check("Discord CVD Both-COPD HR ≈ 1.70",       1.699, get_hr(fit_disc_cvd, "discordBoth-COPD"))
check("Discord CVD Bhatt-only HR ≈ 1.50",      1.502, get_hr(fit_disc_cvd, "discordBhatt-only-COPD"))
check("Discord CVD ESI-only HR ≈ 2.74",        2.742, get_hr(fit_disc_cvd, "discordESI-only-COPD"))
check("Discord Cancer Both-COPD HR ≈ 2.87",    2.870, get_hr(fit_disc_canc, "discordBoth-COPD"))

# Event counts
n_esi_only_cvd <- sum(ev_cvd_p[d_p$discord == "ESI-only-COPD"])
check("ESI-only-COPD CVD events", 8, n_esi_only_cvd, tol = 0, fmt = "%d")

# FEV1 decline
fev1_long <- phe %>% filter(visitnum %in% c(1,2,3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow = factor(SmokCigNow))
base_pres <- d_p %>% transmute(rand_id, discord,
                               Height_CM = as.numeric(Height_CM),
                               gender_baseline = factor(gender),
                               race_baseline = factor(race))
dec_d <- fev1_long %>% inner_join(base_pres, by = "rand_id") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
lmm <- lmer(FEV1_post_mL ~ years_from_baseline * discord + Height_CM + gender_baseline + race_baseline +
              age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id), data = dec_d)
co <- summary(lmm)$coef
check("FEV1 decline interaction Both-COPD est ≈ -1.40",
      -1.395, unname(co["years_from_baseline:discordBoth-COPD","Estimate"]), tol = 0.05)
check("FEV1 decline interaction ESI-only-COPD est ≈ -3.70",
      -3.700, unname(co["years_from_baseline:discordESI-only-COPD","Estimate"]), tol = 0.1)

emit("\n## Step 2 — Adversarial sanity\n")

# Sanity: head-to-head Bhatt and ESI-Bhatt HRs for COPD-major should be similar (within 20%)
diff_major_cvd <- abs(get_hr(fit_b_cvd, "bhatt_grpCOPD-major") - get_hr(fit_e_cvd, "esi_grpCOPD-major"))
check("Bhatt vs ESI-Bhatt COPD-major CVD HRs differ by < 0.20",
      TRUE, diff_major_cvd < 0.20)

# Sanity: ESI-only group has smallest CVD events (n=8) — HR should have wide CI
ci_width <- summary(fit_disc_cvd)$conf.int["discordESI-only-COPD","upper .95"] -
            summary(fit_disc_cvd)$conf.int["discordESI-only-COPD","lower .95"]
emit(sprintf("- ESI-only-COPD CVD HR 95%% CI width = %.2f (wide due to n_events=8)", ci_width))
check("ESI-only-COPD CVD CI width > 3 (small N → wide CI)", TRUE, ci_width > 3)

# Sanity: discord groups in preserved spirometry sum correctly
ng <- table(d_p$discord)
total_n <- sum(ng)
check("Discord groups sum to preserved-spirometry n", nrow(d_p), total_n, tol = 0, fmt = "%d")

emit("\n## Step 3 — Documentation accuracy\n")
# Headline claim: ESI-only-COPD shows elevated CVD mortality despite small N
hr_esi_cvd <- get_hr(fit_disc_cvd, "discordESI-only-COPD")
p_esi_cvd  <- summary(fit_disc_cvd)$coef["discordESI-only-COPD","Pr(>|z|)"]
check("Prose: 'ESI-only-COPD CVD HR ~2.7 (p < 0.01) despite small N'",
      TRUE, hr_esi_cvd > 2.5 && p_esi_cvd < 0.01)

# Both schemas show similar HRs for COPD-major across all causes
diff_major_all <- abs(get_hr(fit_b_cvd, "bhatt_grpCOPD-major") - get_hr(fit_e_cvd, "esi_grpCOPD-major")) +
                  abs(get_hr(fit_b_canc, "bhatt_grpCOPD-major") - get_hr(fit_e_canc, "esi_grpCOPD-major"))
check("Prose: 'Bhatt and ESI-Bhatt produce similar COPD-major HRs across causes'",
      TRUE, diff_major_all < 0.50)

# Summary
LOG <- c("# Validation log — Subgroup analyses (2026-06-25)",
         "",
         sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
         "", LOG[-(1:2)])
writeLines(LOG, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
