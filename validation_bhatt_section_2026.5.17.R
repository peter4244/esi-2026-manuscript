#!/usr/bin/env Rscript
# 5-step validation for the new Bhatt-substitution section.
#   Step 1: factual accuracy — recompute counts and HRs independently
#   Step 2: result correctness — actively try to disprove
#   Step 3: documentation accuracy — match prose claims to recomputed values

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(survival)
})

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_bhatt_section_2026.5.17.md"
LOG <- character()
n_pass <- 0L; n_fail <- 0L
emit  <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)
check <- function(label, expected, actual, tol = 0.01, fmt = "%.3f") {
  ok <- if (is.numeric(expected) && is.numeric(actual)) {
    abs(expected - actual) <= tol
  } else identical(expected, actual)
  status <- if (ok) "PASS" else "**FAIL**"
  emit(sprintf("- [%s] %s — expected %s, recomputed %s", status, label,
               if (is.numeric(expected)) sprintf(fmt, expected) else expected,
               if (is.numeric(actual))   sprintf(fmt, actual)   else actual))
  if (ok) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L
}

esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
vs_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"

esi <- read.csv(esi_path, stringsAsFactors = FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1) %>%
  select(rand_id, finalgold_visit, FEV1_FVC_post,
         CT_Visual_Emph_Severity, CT_Visual_Wall_Thickening,
         MMRCDyspneaScor, SGRQ_scoreTotal, Chronic_Bronchitis,
         age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI)

vs <- read.csv(vs_path, stringsAsFactors = FALSE); vs$rand_id <- as.character(vs$rand_id)

d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(
    major_criterion = FEV1_FVC_post < 0.70,
    emph_yn = CT_Visual_Emph_Severity >= 1,
    wall_yn = CT_Visual_Wall_Thickening == 2,
    dysp_yn = MMRCDyspneaScor >= 2,
    qol_yn  = SGRQ_scoreTotal >= 25,
    cb_yn   = Chronic_Bronchitis == 1,
    stratum = factor(case_when(
      finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
      finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
      finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
      finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
      levels = c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4"))
  ) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn))

n_minor <- d$emph_yn + d$wall_yn + d$dysp_yn + d$qol_yn + d$cb_yn
d$bhatt_cls <- ifelse(d$major_criterion & n_minor >= 1, "COPD-major",
               ifelse(!d$major_criterion & n_minor >= 3, "COPD-minor",
               ifelse(d$major_criterion & n_minor == 0, "AFL-only-NoCOPD",
                                                        "noCOPD")))
d$bhatt_copd <- d$bhatt_cls %in% c("COPD-major","COPD-minor")

esi_score   <- ifelse(d$ESI_v1post >= 2.5, 2, ifelse(d$ESI_v1post >= 1.0, 1, 0))
n_minor_esi <- esi_score + d$dysp_yn + d$qol_yn + d$cb_yn
d$esi_cls   <- ifelse(d$major_criterion & n_minor_esi >= 1, "COPD-major",
                ifelse(!d$major_criterion & n_minor_esi >= 3, "COPD-minor",
                ifelse(d$major_criterion & n_minor_esi == 0, "AFL-only-NoCOPD",
                                                              "noCOPD")))
d$esi_copd <- d$esi_cls %in% c("COPD-major","COPD-minor")

emit("# Validation log — Bhatt-substitution section, 2026-05-17\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.\n")

# ============================================================================
# STEP 1: factual accuracy
# ============================================================================
emit("\n## Step 1 — Factual accuracy\n")

check("Cohort size (n with all Bhatt criteria)",   9463, nrow(d), tol = 0, fmt = "%d")
check("Bhatt COPD-major count",                    3969, sum(d$bhatt_cls == "COPD-major"),       tol = 0, fmt = "%d")
check("Bhatt COPD-minor count",                    1099, sum(d$bhatt_cls == "COPD-minor"),       tol = 0, fmt = "%d")
check("Bhatt AFL-only-NoCOPD count",                170, sum(d$bhatt_cls == "AFL-only-NoCOPD"),  tol = 0, fmt = "%d")
check("Bhatt noCOPD count",                        4225, sum(d$bhatt_cls == "noCOPD"),           tol = 0, fmt = "%d")

# Per-stratum preserved-spirometry agreement
preserved <- d %>% filter(!major_criterion, stratum %in% c("GOLD0","PRISm"))
g0  <- preserved %>% filter(stratum == "GOLD0")
prm <- preserved %>% filter(stratum == "PRISm")

check("Preserved GOLD0 — n",                    4073, nrow(g0), tol = 0, fmt = "%d")
check("Preserved GOLD0 — Bhatt-COPD",            682, sum(g0$bhatt_copd), tol = 0, fmt = "%d")
check("Preserved GOLD0 — ESI-variant COPD",      409, sum(g0$esi_copd), tol = 0, fmt = "%d")
check("Preserved GOLD0 — both",                  342, sum(g0$bhatt_copd & g0$esi_copd), tol = 0, fmt = "%d")
check("Preserved GOLD0 — Bhatt-only (missed)",   340, sum(g0$bhatt_copd & !g0$esi_copd), tol = 0, fmt = "%d")
check("Preserved GOLD0 — ESI-only (false +)",     67, sum(!g0$bhatt_copd & g0$esi_copd), tol = 0, fmt = "%d")
check("Preserved GOLD0 — sensitivity",           0.50, mean(g0$esi_copd[g0$bhatt_copd]), tol = 0.01)
check("Preserved GOLD0 — specificity",           0.98, mean(!g0$esi_copd[!g0$bhatt_copd]), tol = 0.01)

check("Preserved PRISm — n",                    1144, nrow(prm), tol = 0, fmt = "%d")
check("Preserved PRISm — Bhatt-COPD",            417, sum(prm$bhatt_copd), tol = 0, fmt = "%d")
check("Preserved PRISm — ESI-variant COPD",      239, sum(prm$esi_copd), tol = 0, fmt = "%d")
check("Preserved PRISm — both",                  211, sum(prm$bhatt_copd & prm$esi_copd), tol = 0, fmt = "%d")
check("Preserved PRISm — Bhatt-only (missed)",   206, sum(prm$bhatt_copd & !prm$esi_copd), tol = 0, fmt = "%d")
check("Preserved PRISm — ESI-only (false +)",     28, sum(!prm$bhatt_copd & prm$esi_copd), tol = 0, fmt = "%d")
check("Preserved PRISm — sensitivity",           0.51, mean(prm$esi_copd[prm$bhatt_copd]), tol = 0.01)
check("Preserved PRISm — specificity",           0.96, mean(!prm$esi_copd[!prm$bhatt_copd]), tol = 0.01)

# Cox models
mort_b <- d %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  mutate(bhatt_grp = factor(bhatt_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
         esi_grp   = factor(esi_cls,   levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

cox_b <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_e <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)

hr_b_minor <- summary(cox_b)$conf.int["bhatt_grpCOPD-minor","exp(coef)"]
hr_e_minor <- summary(cox_e)$conf.int["esi_grpCOPD-minor",  "exp(coef)"]
hr_b_major <- summary(cox_b)$conf.int["bhatt_grpCOPD-major","exp(coef)"]
hr_e_major <- summary(cox_e)$conf.int["esi_grpCOPD-major",  "exp(coef)"]

check("Bhatt mortality HR (COPD-minor)",    1.91, hr_b_minor, tol = 0.05)
check("ESI-variant mortality HR (COPD-minor)", 1.94, hr_e_minor, tol = 0.05)
check("Bhatt mortality HR (COPD-major)",    2.59, hr_b_major, tol = 0.05)
check("ESI-variant mortality HR (COPD-major)", 2.39, hr_e_major, tol = 0.05)
check("Bhatt model C-index",                0.703, concordance(cox_b)$concordance, tol = 0.005)
check("ESI-variant model C-index",          0.700, concordance(cox_e)$concordance, tol = 0.005)

# ============================================================================
# STEP 2: result correctness — adversarial checks
# ============================================================================
emit("\n## Step 2 — Adversarial sanity checks\n")

# Sanity: cells of 4-way cross-tab sum to total
ctab <- table(d$bhatt_cls, d$esi_cls)
check("4-way cross-tab cells sum to n",    nrow(d), sum(ctab), tol = 0, fmt = "%d")

# AFL-only-NoCOPD must not have bhatt_copd flag
afl_only <- d %>% filter(bhatt_cls == "AFL-only-NoCOPD")
check("AFL-only-NoCOPD have major_criterion = TRUE",
      170, sum(afl_only$major_criterion), tol = 0, fmt = "%d")
check("AFL-only-NoCOPD have zero minor criteria",
      170, sum((afl_only$emph_yn + afl_only$wall_yn + afl_only$dysp_yn + afl_only$qol_yn + afl_only$cb_yn) == 0),
      tol = 0, fmt = "%d")
check("AFL-only-NoCOPD bhatt_copd = FALSE",  0, sum(afl_only$bhatt_copd), tol = 0, fmt = "%d")

# Sanity: mortality among AFL-only-NoCOPD should be near 1 — that's Bhatt's whole point
hr_b_afl <- summary(cox_b)$conf.int["bhatt_grpAFL-only-NoCOPD","exp(coef)"]
p_b_afl  <- summary(cox_b)$coef["bhatt_grpAFL-only-NoCOPD","Pr(>|z|)"]
emit(sprintf("- AFL-only-NoCOPD mortality HR (Bhatt): %.2f, p = %.3g (should be ~1, not significant)", hr_b_afl, p_b_afl))

# Sanity: no preserved-spirometry subjects in COPD-major (must have major_criterion = TRUE)
n_pres_major <- sum(!d$major_criterion & d$bhatt_cls == "COPD-major")
check("No preserved-spirometry subjects in COPD-major",  0, n_pres_major, tol = 0, fmt = "%d")
n_obs_minor <- sum(d$major_criterion & d$bhatt_cls == "COPD-minor")
check("No obstructed subjects in COPD-minor",  0, n_obs_minor, tol = 0, fmt = "%d")

# Sanity: alternative κ calculation matches
kappa_manual <- function(a, b) {
  tab <- table(a, b); po <- sum(diag(tab))/sum(tab)
  pe <- sum(rowSums(tab) * colSums(tab))/sum(tab)^2
  (po - pe)/(1 - pe)
}
k_bin <- kappa_manual(d$bhatt_copd, d$esi_copd)
check("Cohen's κ (binary COPD vs noCOPD)",  0.82, k_bin, tol = 0.01)

# Sanity: at very low ESI threshold (0.5), almost everyone in GOLD 0+ would be classified as COPD by ESI
# At very high threshold (10), no one would be — these are sanity checks the rule behaves as expected
esi_low  <- ifelse(d$ESI_v1post >= 2.5, 2, ifelse(d$ESI_v1post >= 0.5, 1, 0))
esi_high <- ifelse(d$ESI_v1post >= 10,  2, ifelse(d$ESI_v1post >= 8,   1, 0))
n_copd_low  <- sum((d$major_criterion & (esi_low + d$dysp_yn + d$qol_yn + d$cb_yn) >= 1) |
                  (!d$major_criterion & (esi_low + d$dysp_yn + d$qol_yn + d$cb_yn) >= 3))
n_copd_high <- sum((d$major_criterion & (esi_high + d$dysp_yn + d$qol_yn + d$cb_yn) >= 1) |
                  (!d$major_criterion & (esi_high + d$dysp_yn + d$qol_yn + d$cb_yn) >= 3))
emit(sprintf("- Sanity rule behavior: at very low ESI threshold (0.5/2.5), n_COPD = %d; at very high (8/10), n_COPD = %d.  Expect: low threshold gives more, high gives fewer.", n_copd_low, n_copd_high))
ok_low_high <- n_copd_low > n_copd_high
emit(sprintf("- %s: rule behaves monotonically with thresholds.", if (ok_low_high) "PASS" else "**FAIL**"))
if (ok_low_high) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L

# ============================================================================
# STEP 3: documentation accuracy
# ============================================================================
emit("\n## Step 3 — Documentation accuracy\n")

# Prose claims in the new Section 5:
check("Prose: 'about half of Bhatt's minor-COPD' (GOLD 0 sens ≈ 50%)",
      0.50, mean(g0$esi_copd[g0$bhatt_copd]), tol = 0.02)
check("Prose: 'about half of Bhatt's minor-COPD' (PRISm sens ≈ 51%)",
      0.51, mean(prm$esi_copd[prm$bhatt_copd]), tol = 0.02)
check("Prose: 'highly specific (96–98%)' — GOLD 0 spec ≥ 0.96",
      TRUE, mean(!g0$esi_copd[!g0$bhatt_copd]) >= 0.96)
check("Prose: 'highly specific (96–98%)' — PRISm spec ≥ 0.96",
      TRUE, mean(!prm$esi_copd[!prm$bhatt_copd]) >= 0.96)
check("Prose: 'HR ≈ 1.94 vs 1.91 for COPD-minor'",
      TRUE, abs(hr_e_minor - hr_b_minor) < 0.10)
check("Prose: 'C-index 0.700 vs 0.703'",
      TRUE, abs(concordance(cox_e)$concordance - concordance(cox_b)$concordance) < 0.005)
check("Prose: 'AFL-only-NoCOPD HR not different from noCOPD'",
      TRUE, p_b_afl > 0.10)

# ============================================================================
# Summary
# ============================================================================
LOG <- c(
  "# Validation log — Bhatt-substitution section, 2026-05-17",
  "",
  sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
  "",
  "Tolerance: 0.01 absolute on numerics by default.",
  "",
  LOG[-(1:2)]
)
writeLines(LOG, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
