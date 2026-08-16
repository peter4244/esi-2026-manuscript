#!/usr/bin/env Rscript
# Comprehensive covariate-sensitivity analysis (2026-07-20).
#
# For every primary and sensitivity analysis reported in the manuscript,
# refit with the minimal adjustment set (age + sex + race) and flag any
# estimate whose (a) statistical significance flips at p = 0.05 or
# (b) direction of effect changes.
#
# Outputs:
#   covariate_sensitivity_summary.csv   — one row per estimand
#
# Scope covered:
#   Table 1  — mortality + exac by Bhatt category, both frameworks
#   Table 2  — mortality + exac by cross-classification group
#   S3a      — ESI=10 excluded sensitivity (same shape as Table 1)
#   S4a/b/c  — cause-specific mortality (CVD, cancer, other)
#   S5       — FEV1 decline by Bhatt category, both frameworks
#   S6a/b/c  — continuous ESI mortality + exac (alone + joint with FEV1/FVC)
#   S6d      — continuous ESI FEV1 decline, GOLD 0 subgroup

suppressPackageStartupMessages({
  library(dplyr); library(survival); library(MASS); library(lme4); library(lmerTest)
})

ROOT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024"
OUT  <- file.path(ROOT, "covariate_sensitivity_summary.csv")

ESI_PATH <- file.path(ROOT, "copdgene_esi_randid_2026.5.17.csv")
PHE_PATH <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
VS_PATH  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"
COD_PATH <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv"
EX_PATH  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/LFU_SidLevel_Comorbd_randid.csv"

ESI_T_LOW  <- 1.0
ESI_T_HIGH <- 2.5

# ---- Data ingest (mirrors Rmd L137-228) -----------------------------------
esi_raw <- read.csv(ESI_PATH, stringsAsFactors = FALSE); esi_raw$rand_id <- as.character(esi_raw$rand_id)
phe_raw <- read.csv(PHE_PATH, stringsAsFactors = FALSE, na.strings = c("", "NA")); phe_raw$rand_id <- as.character(phe_raw$rand_id)
vs      <- read.csv(VS_PATH, stringsAsFactors = FALSE); vs$rand_id <- as.character(vs$rand_id)
cod     <- read.csv(COD_PATH, stringsAsFactors = FALSE); cod$rand_id <- as.character(cod$rand_id.x)
ex_raw  <- read.csv(EX_PATH, stringsAsFactors = FALSE); ex_raw$rand_id <- as.character(ex_raw$rand_id)

esi_v1 <- esi_raw %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
v1 <- phe_raw %>% filter(visitnum == 1)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE ~ NA_character_), levels = stratum_levels),
    gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow))

d_b <- d %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2, qol_yn = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn), !is.na(ESI_v1post))

n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                 ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                 ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD","noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major","COPD-minor")
esi_score <- ifelse(d_b$ESI_v1post >= ESI_T_HIGH, 2,
             ifelse(d_b$ESI_v1post >= ESI_T_LOW, 1, 0))
n_minor_e <- esi_score + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
               ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
               ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD","noCOPD")))
d_b$esi_copd <- d_b$esi_cls %in% c("COPD-major","COPD-minor")
d_b$discord <- with(d_b, case_when(
  bhatt_copd  &  esi_copd ~ "Both-COPD",
  bhatt_copd  & !esi_copd ~ "Bhatt-only-COPD",
  !bhatt_copd &  esi_copd ~ "ESI-only-COPD",
  TRUE ~ "Both-noCOPD"))
d_b$discord <- factor(d_b$discord, levels = c("Both-noCOPD","Both-COPD","Bhatt-only-COPD","ESI-only-COPD"))
ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
d_b$bhatt_grp <- factor(d_b$bhatt_cls, levels = ord)
d_b$esi_grp   <- factor(d_b$esi_cls,   levels = ord)

cat(sprintf("Analytic cohort: n = %d\n", nrow(d_b)))

# ---- Helpers -------------------------------------------------------------
cox_row <- function(fit, term) {
  s <- summary(fit); r <- s$coefficients[term, ]; ci <- s$conf.int[term, ]
  c(est = unname(ci["exp(coef)"]), LCI = unname(ci["lower .95"]),
    UCI = unname(ci["upper .95"]), p = unname(r["Pr(>|z|)"]))
}
nb_row <- function(fit, term) {
  s <- summary(fit); est <- coef(fit)[term]; se <- s$coefficients[term,"Std. Error"]
  p <- s$coefficients[term,"Pr(>|z|)"]
  c(est = unname(exp(est)), LCI = unname(exp(est - 1.96*se)),
    UCI = unname(exp(est + 1.96*se)), p = unname(p))
}
lmm_row <- function(fit, term) {
  co <- summary(fit)$coefficients
  est <- co[term,"Estimate"]; se <- co[term,"Std. Error"]; p <- co[term,"Pr(>|t|)"]
  c(est = unname(est), LCI = unname(est - 1.96*se), UCI = unname(est + 1.96*se), p = unname(p))
}
mk_event <- function(df, col) ifelse(df$vital_status == 1 & !is.na(df[[col]]) & df[[col]] == 1, 1, 0)

results <- list()
add <- function(table, model, term, full, min_, scale = "HR") {
  # Sensitivity flag: (a) crosses p=0.05, or (b) direction changes.
  # Direction is on the effect-vs-null scale: HR/IRR>1 vs <1; LMM est>0 vs <0.
  sig_full <- !is.na(full["p"]) && full["p"] < 0.05
  sig_min  <- !is.na(min_["p"]) && min_["p"] < 0.05
  crosses_p <- sig_full != sig_min
  null_val <- if (scale == "HR") 1 else 0
  dir_full <- sign(full["est"] - null_val)
  dir_min  <- sign(min_["est"] - null_val)
  dir_change <- !is.na(dir_full) && !is.na(dir_min) && dir_full != dir_min &&
                 dir_full != 0 && dir_min != 0
  results[[length(results)+1]] <<- data.frame(
    table = table, model = model, term = term, scale = scale,
    est_full = unname(full["est"]), LCI_full = unname(full["LCI"]),
    UCI_full = unname(full["UCI"]), p_full = unname(full["p"]),
    est_min  = unname(min_["est"]),  LCI_min = unname(min_["LCI"]),
    UCI_min  = unname(min_["UCI"]),  p_min  = unname(min_["p"]),
    p_crosses_05 = crosses_p, direction_change = dir_change,
    sensitive = crosses_p || dir_change,
    stringsAsFactors = FALSE)
}

# ---- Prepare datasets ----------------------------------------------------
mort <- d_b %>%
  inner_join(vs %>% dplyr::select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% dplyr::select(rand_id, CCOD_COPD_resp, CCOD_CVD, CCOD_Cancer, CCOD_Other), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0))
mort_full <- mort %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
mort_min  <- mort %>% filter(complete.cases(age_visit, gender, race))

ex <- d_b %>%
  inner_join(ex_raw %>% dplyr::select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), !is.na(Years_Followed), Years_Followed > 0)
ex_full <- ex %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
ex_min  <- ex %>% filter(complete.cases(age_visit, gender, race))

# Continuous-ESI datasets (add FF_per_0_1 = FEV1_FVC_post/0.1 for scale)
d_cont <- d_b %>% mutate(FF_per_0_1 = FEV1_FVC_post / 0.1)
mort_cont <- d_cont %>%
  inner_join(vs %>% dplyr::select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% dplyr::select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0))
mort_cont_full <- mort_cont %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears))
mort_cont_min  <- mort_cont %>% filter(complete.cases(age_visit, gender, race))
ex_cont <- d_cont %>%
  inner_join(ex_raw %>% dplyr::select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0)
ex_cont_full <- ex_cont %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears))
ex_cont_min  <- ex_cont %>% filter(complete.cases(age_visit, gender, race))

groups3 <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")
discords <- c("Both-COPD","Bhatt-only-COPD","ESI-only-COPD")

# ==== Table 1: mortality (Cox) ============================================
cox_bhatt_all_F  <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_esi_all_F    <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_bhatt_resp_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_esi_resp_F   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_bhatt_all_M  <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race, data = mort_min)
cox_esi_all_M    <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race, data = mort_min)
cox_bhatt_resp_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race, data = mort_min)
cox_esi_resp_M   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race, data = mort_min)
for (g in groups3) {
  add("Table 1","all-cause CT",g, cox_row(cox_bhatt_all_F, paste0("bhatt_grp",g)), cox_row(cox_bhatt_all_M, paste0("bhatt_grp",g)))
  add("Table 1","all-cause ESI",g, cox_row(cox_esi_all_F,  paste0("esi_grp",  g)), cox_row(cox_esi_all_M,  paste0("esi_grp",  g)))
  add("Table 1","respiratory CT",g, cox_row(cox_bhatt_resp_F, paste0("bhatt_grp",g)), cox_row(cox_bhatt_resp_M, paste0("bhatt_grp",g)))
  add("Table 1","respiratory ESI",g, cox_row(cox_esi_resp_F,  paste0("esi_grp",  g)), cox_row(cox_esi_resp_M,  paste0("esi_grp",  g)))
}

# ==== Table 1: exacerbations (NB) =========================================
nb_bhatt_F <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_full)
nb_esi_F   <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_full)
nb_bhatt_M <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + offset(log(Years_Followed)), data = ex_min)
nb_esi_M   <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + offset(log(Years_Followed)), data = ex_min)
for (g in groups3) {
  add("Table 1","exacerbations CT", g, nb_row(nb_bhatt_F, paste0("bhatt_grp",g)), nb_row(nb_bhatt_M, paste0("bhatt_grp",g)), scale="IRR")
  add("Table 1","exacerbations ESI",g, nb_row(nb_esi_F,   paste0("esi_grp",  g)), nb_row(nb_esi_M,   paste0("esi_grp",  g)), scale="IRR")
}

# ==== Table 2: mortality + exac by cross-classification ===================
cox_disc_all_F  <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_disc_resp_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_disc_all_M  <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race, data = mort_min)
cox_disc_resp_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race, data = mort_min)
nb_disc_F <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_full)
nb_disc_M <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + offset(log(Years_Followed)), data = ex_min)
for (g in discords) {
  add("Table 2","all-cause",  g, cox_row(cox_disc_all_F,  paste0("discord",g)), cox_row(cox_disc_all_M,  paste0("discord",g)))
  add("Table 2","respiratory",g, cox_row(cox_disc_resp_F, paste0("discord",g)), cox_row(cox_disc_resp_M, paste0("discord",g)))
  add("Table 2","exacerbations",g, nb_row(nb_disc_F, paste0("discord",g)), nb_row(nb_disc_M, paste0("discord",g)), scale="IRR")
}

# ==== S3a: ESI=10 excluded sensitivity ====================================
mort_ne  <- mort_full %>% filter(ESI_v1post < 10); mort_ne_min <- mort_min %>% filter(ESI_v1post < 10)
ex_ne    <- ex_full   %>% filter(ESI_v1post < 10); ex_ne_min   <- ex_min   %>% filter(ESI_v1post < 10)
cB_all_F <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_ne)
cE_all_F <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_ne)
cB_re_F  <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_ne)
cE_re_F  <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_ne)
cB_all_M <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race, data = mort_ne_min)
cE_all_M <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race, data = mort_ne_min)
cB_re_M  <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race, data = mort_ne_min)
cE_re_M  <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race, data = mort_ne_min)
nB_ex_F  <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_ne)
nE_ex_F  <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_ne)
nB_ex_M  <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + offset(log(Years_Followed)), data = ex_ne_min)
nE_ex_M  <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + offset(log(Years_Followed)), data = ex_ne_min)
for (g in groups3) {
  add("S3a","all-cause CT",g,   cox_row(cB_all_F, paste0("bhatt_grp",g)), cox_row(cB_all_M, paste0("bhatt_grp",g)))
  add("S3a","all-cause ESI",g,  cox_row(cE_all_F, paste0("esi_grp",  g)), cox_row(cE_all_M, paste0("esi_grp",  g)))
  add("S3a","respiratory CT",g,  cox_row(cB_re_F,  paste0("bhatt_grp",g)), cox_row(cB_re_M,  paste0("bhatt_grp",g)))
  add("S3a","respiratory ESI",g, cox_row(cE_re_F,  paste0("esi_grp",  g)), cox_row(cE_re_M,  paste0("esi_grp",  g)))
  add("S3a","exacerbations CT", g, nb_row(nB_ex_F, paste0("bhatt_grp",g)), nb_row(nB_ex_M, paste0("bhatt_grp",g)), scale="IRR")
  add("S3a","exacerbations ESI",g, nb_row(nE_ex_F, paste0("esi_grp",  g)), nb_row(nE_ex_M, paste0("esi_grp",  g)), scale="IRR")
}

# ==== S4a/b/c: cause-specific mortality by Bhatt category =================
causes <- c("CCOD_CVD","CCOD_Cancer","CCOD_Other")
cause_labels <- c("S4a CVD","S4b Cancer","S4c Other")
for (i in seq_along(causes)) {
  ev_F <- mk_event(mort_full, causes[i]); ev_M <- mk_event(mort_min, causes[i])
  fB_F <- coxph(Surv(days_followed/365.25, ev_F) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
  fE_F <- coxph(Surv(days_followed/365.25, ev_F) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
  fB_M <- coxph(Surv(days_followed/365.25, ev_M) ~ bhatt_grp + age_visit + gender + race, data = mort_min)
  fE_M <- coxph(Surv(days_followed/365.25, ev_M) ~ esi_grp   + age_visit + gender + race, data = mort_min)
  for (g in groups3) {
    add(cause_labels[i],"cause-spec CT", g, cox_row(fB_F, paste0("bhatt_grp",g)), cox_row(fB_M, paste0("bhatt_grp",g)))
    add(cause_labels[i],"cause-spec ESI",g, cox_row(fE_F, paste0("esi_grp",  g)), cox_row(fE_M, paste0("esi_grp",  g)))
  }
}

# ==== S6a/b/c: continuous ESI (alone + joint with FEV1/FVC) ===============
# Full = age+sex+race+smk+py+stratum; Min = age+sex+race
add_s6 <- function(table, model, term_est_F, term_est_M) add(table, model, term_est_F$term, term_est_F$v, term_est_M$v, term_est_F$scale)
# S6a all-cause
f1 <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_cont_full)
f2 <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race, data = mort_cont_min)
add("S6a","cont ESI alone","ESI_v1post", cox_row(f1,"ESI_v1post"), cox_row(f2,"ESI_v1post"))
f1 <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_cont_full)
f2 <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race, data = mort_cont_min)
add("S6a","cont ESI + FEV1/FVC","ESI_v1post", cox_row(f1,"ESI_v1post"), cox_row(f2,"ESI_v1post"))
# S6b respiratory
f1 <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_cont_full)
f2 <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + age_visit + gender + race, data = mort_cont_min)
add("S6b","cont ESI alone","ESI_v1post", cox_row(f1,"ESI_v1post"), cox_row(f2,"ESI_v1post"))
f1 <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_cont_full)
f2 <- coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race, data = mort_cont_min)
add("S6b","cont ESI + FEV1/FVC","ESI_v1post", cox_row(f1,"ESI_v1post"), cox_row(f2,"ESI_v1post"))
# S6c exacerbations
f1 <- glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont_full)
f2 <- glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + offset(log(Years_Followed)), data = ex_cont_min)
add("S6c","cont ESI alone","ESI_v1post", nb_row(f1,"ESI_v1post"), nb_row(f2,"ESI_v1post"), scale="IRR")
f1 <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont_full)
f2 <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + offset(log(Years_Followed)), data = ex_cont_min)
add("S6c","cont ESI + FEV1/FVC","ESI_v1post", nb_row(f1,"ESI_v1post"), nb_row(f2,"ESI_v1post"), scale="IRR")

# ==== S5: FEV1 decline by category (LMM) =================================
fev1_long <- phe_raw %>%
  filter(visitnum %in% c(1,2,3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline, FEV1_post_mL = FEV1_post * 1000,
            age_visit = as.numeric(age_visit), ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow = factor(SmokCigNow))
base_b <- d_b %>% transmute(rand_id, bhatt_grp = factor(bhatt_cls, levels=ord),
                              esi_grp = factor(esi_cls, levels=ord),
                              ESI_v1post, FEV1_FVC_baseline = FEV1_FVC_post,
                              Height_CM = as.numeric(Height_CM),
                              gender_baseline = factor(gender),
                              race_baseline = factor(race),
                              stratum_baseline = stratum)
decline_F <- fev1_long %>% inner_join(base_b, by = "rand_id") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))
decline_M <- fev1_long %>% inner_join(base_b, by = "rand_id") %>%
  filter(!is.na(age_visit))
lB_F <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1|rand_id), data = decline_F, REML = TRUE)
lE_F <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp   + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1|rand_id), data = decline_F, REML = TRUE)
lB_M <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + gender_baseline + race_baseline + age_visit + (1|rand_id), data = decline_M, REML = TRUE)
lE_M <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp   + gender_baseline + race_baseline + age_visit + (1|rand_id), data = decline_M, REML = TRUE)
for (g in groups3) {
  add("S5","FEV1 decline CT", g, lmm_row(lB_F, paste0("years_from_baseline:bhatt_grp",g)), lmm_row(lB_M, paste0("years_from_baseline:bhatt_grp",g)), scale="mL/yr")
  add("S5","FEV1 decline ESI",g, lmm_row(lE_F, paste0("years_from_baseline:esi_grp",  g)), lmm_row(lE_M, paste0("years_from_baseline:esi_grp",  g)), scale="mL/yr")
}

# ==== S6d: continuous ESI FEV1 decline, GOLD 0 subgroup ===================
g0_F <- decline_F %>% filter(stratum_baseline == "GOLD0", !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))
g0_M <- decline_M %>% filter(stratum_baseline == "GOLD0", !is.na(ESI_v1post), !is.na(FEV1_FVC_baseline))
l6d_a_F <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post + Height_CM + age_visit + ATS_PackYears + SmokCigNow + gender_baseline + race_baseline + (1|rand_id), data = g0_F, REML = TRUE)
l6d_a_M <- lmer(FEV1_post_mL ~ years_from_baseline * ESI_v1post + age_visit + gender_baseline + race_baseline + (1|rand_id), data = g0_M, REML = TRUE)
l6d_j_F <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) + Height_CM + age_visit + ATS_PackYears + SmokCigNow + gender_baseline + race_baseline + (1|rand_id), data = g0_F, REML = TRUE)
l6d_j_M <- lmer(FEV1_post_mL ~ years_from_baseline * (ESI_v1post + FEV1_FVC_baseline) + age_visit + gender_baseline + race_baseline + (1|rand_id), data = g0_M, REML = TRUE)
add("S6d","cont ESI alone (GOLD 0)","ESI_v1post", lmm_row(l6d_a_F,"years_from_baseline:ESI_v1post"), lmm_row(l6d_a_M,"years_from_baseline:ESI_v1post"), scale="mL/yr")
add("S6d","cont ESI + FEV1/FVC (GOLD 0)","ESI_v1post", lmm_row(l6d_j_F,"years_from_baseline:ESI_v1post"), lmm_row(l6d_j_M,"years_from_baseline:ESI_v1post"), scale="mL/yr")

# ---- Assemble ------------------------------------------------------------
out <- do.call(rbind, results); rownames(out) <- NULL
num_cols <- c("est_full","LCI_full","UCI_full","est_min","LCI_min","UCI_min")
out[, num_cols] <- round(out[, num_cols], 3)
out$p_full <- signif(out$p_full, 3); out$p_min <- signif(out$p_min, 3)
write.csv(out, OUT, row.names = FALSE)

cat(sprintf("\nWrote %s (%d rows)\n", OUT, nrow(out)))
n_sens <- sum(out$sensitive)
n_cross <- sum(out$p_crosses_05)
n_dir   <- sum(out$direction_change)
cat(sprintf("Summary: %d/%d estimates sensitive to covariate choice\n", n_sens, nrow(out)))
cat(sprintf("         (%d cross the p=0.05 boundary, %d change direction)\n", n_cross, n_dir))

if (n_sens > 0) {
  cat("\n=== Sensitive estimates ===\n")
  sens <- out[out$sensitive, ]
  for (i in seq_len(nrow(sens))) {
    r <- sens[i, ]
    what <- paste(c(if (r$p_crosses_05) "p05" else NULL,
                    if (r$direction_change) "dir" else NULL), collapse = "+")
    cat(sprintf("  [%s] %-8s %-30s %-30s : %s %-6.2f (p=%s) -> %-6.2f (p=%s)\n",
                what, r$table, r$model, r$term, r$scale,
                r$est_full, formatC(r$p_full, digits=2, format="g"),
                r$est_min,  formatC(r$p_min,  digits=2, format="g")))
  }
}
