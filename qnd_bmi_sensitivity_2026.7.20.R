#!/usr/bin/env Rscript
# Quick-and-dirty exploratory analysis (2026-07-20):
# how much do the key manuscript results change if the adjustment set is
# reduced to just age + sex + race (dropping smoking, pack-years, BMI, and
# Height_CM / GOLD-stratum where applicable)?
#
# Rationale (Pete): BMI in COPD is confounded with cachexia/muscle wasting,
# so BMI adjustment may absorb real COPD-associated risk and bias effect
# estimates toward the null. This script probes how sensitive Table 1,
# Table 2, and the continuous-ESI supp tables are to the choice of
# covariate set.
#
# Output: qnd_bmi_sensitivity_2026.7.20.csv — one row per estimand, columns:
#   table, model, term, HR_full, LCI_full, UCI_full, p_full,
#                          HR_min,  LCI_min,  UCI_min,  p_min,
#                          pct_change_HR
# where "full" = age+sex+race+smoker+pack-years+BMI (mortality/exac categorical),
# or age+sex+race+smoker+pack-years+stratum (continuous ESI), or
# age+sex+race+smoker+pack-years+height (LMM),
# and "min" = age+sex+race for every model.

suppressPackageStartupMessages({
  library(dplyr); library(survival); library(MASS); library(lme4); library(lmerTest)
})

ROOT   <- "/Users/petecastaldi/claude_projects/projects/ESI_2024"
OUT    <- file.path(ROOT, "qnd_bmi_sensitivity_2026.7.20.csv")

# ---- Paths (mirror the Rmd) ----------------------------------------------
ESI_PATH <- file.path(ROOT, "copdgene_esi_randid_2026.5.17.csv")
PHE_PATH <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
VS_PATH  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"
COD_PATH <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv"
EX_PATH  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/LFU_SidLevel_Comorbd_randid.csv"

ESI_T_LOW  <- 1.0
ESI_T_HIGH <- 2.5

# ---- Data ingest (mirrors Rmd L137–228) ----------------------------------
esi_raw <- read.csv(ESI_PATH, stringsAsFactors = FALSE); esi_raw$rand_id <- as.character(esi_raw$rand_id)
phe_raw <- read.csv(PHE_PATH, stringsAsFactors = FALSE, na.strings = c("", "NA")); phe_raw$rand_id <- as.character(phe_raw$rand_id)
vs      <- read.csv(VS_PATH, stringsAsFactors = FALSE); vs$rand_id <- as.character(vs$rand_id)
cod     <- read.csv(COD_PATH, stringsAsFactors = FALSE); cod$rand_id <- as.character(cod$rand_id.x)
ex_raw  <- read.csv(EX_PATH, stringsAsFactors = FALSE); ex_raw$rand_id <- as.character(ex_raw$rand_id)

esi_v1 <- esi_raw %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
v1 <- phe_raw %>% filter(visitnum == 1)

stratum_levels <- c("Never", "GOLD0", "PRISm", "GOLD1", "GOLD2", "GOLD3", "GOLD4")
d <- esi_v1 %>%
  inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
      finalgold_visit == -2 ~ "Never",
      finalgold_visit == -1 ~ "PRISm",
      finalgold_visit ==  0 ~ "GOLD0",
      finalgold_visit ==  1 ~ "GOLD1",
      finalgold_visit ==  2 ~ "GOLD2",
      finalgold_visit ==  3 ~ "GOLD3",
      finalgold_visit ==  4 ~ "GOLD4",
      TRUE ~ NA_character_), levels = stratum_levels),
    gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow))

d_b <- d %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2,
         qol_yn  = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn), !is.na(ESI_v1post))

n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                 ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                 ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD", "noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major", "COPD-minor")

esi_score <- ifelse(d_b$ESI_v1post >= ESI_T_HIGH, 2,
             ifelse(d_b$ESI_v1post >= ESI_T_LOW, 1, 0))
n_minor_e <- esi_score + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
               ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
               ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD", "noCOPD")))
d_b$esi_copd <- d_b$esi_cls %in% c("COPD-major", "COPD-minor")

d_b$discord <- with(d_b, case_when(
  bhatt_copd  &  esi_copd ~ "Both-COPD",
  bhatt_copd  & !esi_copd ~ "Bhatt-only-COPD",
  !bhatt_copd &  esi_copd ~ "ESI-only-COPD",
  TRUE                    ~ "Both-noCOPD"))
d_b$discord <- factor(d_b$discord, levels = c("Both-noCOPD","Both-COPD","Bhatt-only-COPD","ESI-only-COPD"))

ord <- c("noCOPD", "AFL-only-NoCOPD", "COPD-minor", "COPD-major")
d_b$bhatt_grp <- factor(d_b$bhatt_cls, levels = ord)
d_b$esi_grp   <- factor(d_b$esi_cls,   levels = ord)

cat(sprintf("Analytic cohort: n = %d\n", nrow(d_b)))

# ---- Helpers -------------------------------------------------------------
cox_row <- function(fit, term) {
  s <- summary(fit); r <- s$coefficients[term, ]; ci <- s$conf.int[term, ]
  c(HR  = unname(ci["exp(coef)"]),
    LCI = unname(ci["lower .95"]),
    UCI = unname(ci["upper .95"]),
    p   = unname(r["Pr(>|z|)"]))
}
nb_row <- function(fit, term) {
  s <- summary(fit); est <- coef(fit)[term]; se <- s$coefficients[term, "Std. Error"]; p <- s$coefficients[term, "Pr(>|z|)"]
  c(IRR = unname(exp(est)),
    LCI = unname(exp(est - 1.96*se)),
    UCI = unname(exp(est + 1.96*se)),
    p   = unname(p))
}

# ---- Datasets for models -------------------------------------------------
mort_b <- d_b %>%
  inner_join(vs %>% dplyr::select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% dplyr::select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0))

# Common filter for full-model (drops rows missing any full-model covariate)
mort_full <- mort_b %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
mort_min  <- mort_b %>% filter(complete.cases(age_visit, gender, race))

ex_b <- d_b %>%
  inner_join(ex_raw %>% dplyr::select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), !is.na(Years_Followed), Years_Followed > 0)
ex_full <- ex_b %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
ex_min  <- ex_b %>% filter(complete.cases(age_visit, gender, race))

cat(sprintf("Mortality analysis: full-covariate n = %d, min-covariate n = %d\n",
            nrow(mort_full), nrow(mort_min)))
cat(sprintf("Exacerbation analysis: full-covariate n = %d, min-covariate n = %d\n",
            nrow(ex_full), nrow(ex_min)))

# ---- Collector -----------------------------------------------------------
results <- list()

add <- function(table, model, term, full, min_) {
  ch <- ifelse(is.finite(full["HR"]) && is.finite(min_["HR"]) && full["HR"] > 0,
               100 * (min_["HR"] - full["HR"]) / full["HR"], NA_real_)
  results[[length(results)+1]] <<- data.frame(
    table = table, model = model, term = term,
    est_full = unname(full["HR"]), LCI_full = unname(full["LCI"]),
    UCI_full = unname(full["UCI"]), p_full = unname(full["p"]),
    est_min  = unname(min_["HR"]), LCI_min  = unname(min_["LCI"]),
    UCI_min  = unname(min_["UCI"]), p_min  = unname(min_["p"]),
    pct_change = unname(ch),
    stringsAsFactors = FALSE)
}

# ---- Table 1: mortality by Bhatt category (both frameworks) --------------
cox_bhatt_all_F  <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_esi_all_F    <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_bhatt_resp_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)
cox_esi_resp_F   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_full)

cox_bhatt_all_M  <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race, data = mort_min)
cox_esi_all_M    <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race, data = mort_min)
cox_bhatt_resp_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race, data = mort_min)
cox_esi_resp_M   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race, data = mort_min)

for (cat in c("AFL-only-NoCOPD", "COPD-minor", "COPD-major")) {
  add("Table 1", "all-cause CT",  cat, cox_row(cox_bhatt_all_F,  paste0("bhatt_grp", cat)), cox_row(cox_bhatt_all_M,  paste0("bhatt_grp", cat)))
  add("Table 1", "all-cause ESI", cat, cox_row(cox_esi_all_F,    paste0("esi_grp",   cat)), cox_row(cox_esi_all_M,    paste0("esi_grp",   cat)))
  add("Table 1", "respiratory CT",  cat, cox_row(cox_bhatt_resp_F, paste0("bhatt_grp", cat)), cox_row(cox_bhatt_resp_M, paste0("bhatt_grp", cat)))
  add("Table 1", "respiratory ESI", cat, cox_row(cox_esi_resp_F,   paste0("esi_grp",   cat)), cox_row(cox_esi_resp_M,   paste0("esi_grp",   cat)))
}

# ---- Table 1 exacerbations (NB) ------------------------------------------
nb_bhatt_F <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_full)
nb_esi_F   <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_full)
nb_bhatt_M <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + offset(log(Years_Followed)), data = ex_min)
nb_esi_M   <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + offset(log(Years_Followed)), data = ex_min)

for (cat in c("AFL-only-NoCOPD", "COPD-minor", "COPD-major")) {
  full <- nb_row(nb_bhatt_F, paste0("bhatt_grp", cat)); names(full)[1] <- "HR"
  minm <- nb_row(nb_bhatt_M, paste0("bhatt_grp", cat)); names(minm)[1] <- "HR"
  add("Table 1", "exacerbations CT",  cat, full, minm)
  full <- nb_row(nb_esi_F,   paste0("esi_grp",   cat)); names(full)[1] <- "HR"
  minm <- nb_row(nb_esi_M,   paste0("esi_grp",   cat)); names(minm)[1] <- "HR"
  add("Table 1", "exacerbations ESI", cat, full, minm)
}

# ---- Table 2: mortality + exac by cross-classification --------------------
mort_disc <- mort_b %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
mort_disc_min <- mort_b %>% filter(complete.cases(age_visit, gender, race))

cox_disc_all_F  <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_disc)
cox_disc_resp_F <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_disc)
cox_disc_all_M  <- coxph(Surv(days_followed/365.25, vital_status) ~ discord + age_visit + gender + race, data = mort_disc_min)
cox_disc_resp_M <- coxph(Surv(days_followed/365.25, event_resp)   ~ discord + age_visit + gender + race, data = mort_disc_min)

ex_disc <- ex_b %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
ex_disc_min <- ex_b %>% filter(complete.cases(age_visit, gender, race))
nb_disc_F <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_disc)
nb_disc_M <- glm.nb(Total_Exacerbations ~ discord + age_visit + gender + race + offset(log(Years_Followed)), data = ex_disc_min)

for (g in c("Both-COPD", "Bhatt-only-COPD", "ESI-only-COPD")) {
  add("Table 2", "all-cause",   g, cox_row(cox_disc_all_F,  paste0("discord", g)), cox_row(cox_disc_all_M,  paste0("discord", g)))
  add("Table 2", "respiratory", g, cox_row(cox_disc_resp_F, paste0("discord", g)), cox_row(cox_disc_resp_M, paste0("discord", g)))
  full <- nb_row(nb_disc_F, paste0("discord", g)); names(full)[1] <- "HR"
  minm <- nb_row(nb_disc_M, paste0("discord", g)); names(minm)[1] <- "HR"
  add("Table 2", "exacerbations", g, full, minm)
}

# ---- S6a/b/c continuous ESI (full = +stratum; min = age+sex+race) --------
d_cont <- d_b %>% mutate(FF_per_0_1 = FEV1_FVC_post / 0.1)
mort_cont <- d_cont %>%
  inner_join(vs %>% dplyr::select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% dplyr::select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0))

cont_full <- mort_cont %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, ESI_v1post, FF_per_0_1))
cont_min  <- mort_cont %>% filter(complete.cases(age_visit, gender, race, ESI_v1post, FF_per_0_1))

# S6a: continuous ESI, all-cause
add("S6a", "cont ESI, all-cause",
    "ESI_v1post (ESI alone)",
    cox_row(coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cont_full), "ESI_v1post"),
    cox_row(coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + age_visit + gender + race, data = cont_min), "ESI_v1post"))

# S6a joint model (ESI + FEV1/FVC)
add("S6a", "cont ESI + FEV1/FVC, all-cause",
    "ESI_v1post (joint)",
    cox_row(coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cont_full), "ESI_v1post"),
    cox_row(coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race, data = cont_min), "ESI_v1post"))

# S6b: respiratory
add("S6b", "cont ESI, resp",
    "ESI_v1post (ESI alone)",
    cox_row(coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cont_full), "ESI_v1post"),
    cox_row(coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + age_visit + gender + race, data = cont_min), "ESI_v1post"))
add("S6b", "cont ESI + FEV1/FVC, resp",
    "ESI_v1post (joint)",
    cox_row(coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cont_full), "ESI_v1post"),
    cox_row(coxph(Surv(days_followed/365.25, event_resp) ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race, data = cont_min), "ESI_v1post"))

# S6c: exacerbations (NB)
ex_cont <- d_cont %>%
  inner_join(ex_raw %>% dplyr::select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0)
ex_cont_full <- ex_cont %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, ESI_v1post, FF_per_0_1))
ex_cont_min  <- ex_cont %>% filter(complete.cases(age_visit, gender, race, ESI_v1post, FF_per_0_1))

full <- nb_row(glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont_full), "ESI_v1post"); names(full)[1] <- "HR"
minm <- nb_row(glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + offset(log(Years_Followed)), data = ex_cont_min), "ESI_v1post"); names(minm)[1] <- "HR"
add("S6c", "cont ESI, exac", "ESI_v1post (ESI alone)", full, minm)

full <- nb_row(glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_cont_full), "ESI_v1post"); names(full)[1] <- "HR"
minm <- nb_row(glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + offset(log(Years_Followed)), data = ex_cont_min), "ESI_v1post"); names(minm)[1] <- "HR"
add("S6c", "cont ESI + FEV1/FVC, exac", "ESI_v1post (joint)", full, minm)

# ---- Assemble + write ----------------------------------------------------
out <- do.call(rbind, results)
rownames(out) <- NULL
out[, c("est_full","LCI_full","UCI_full","est_min","LCI_min","UCI_min","pct_change")] <-
  round(out[, c("est_full","LCI_full","UCI_full","est_min","LCI_min","UCI_min","pct_change")], 3)
out$p_full <- signif(out$p_full, 3); out$p_min <- signif(out$p_min, 3)

write.csv(out, OUT, row.names = FALSE)
cat(sprintf("\nWrote %s (%d rows)\n\n", OUT, nrow(out)))

# Compact console summary
cat(sprintf("%-8s %-30s %-30s | %-12s %-12s %-6s\n",
            "table", "model", "term", "HR_full", "HR_min", "Δ%"))
cat(strrep("-", 130), "\n", sep = "")
for (i in seq_len(nrow(out))) {
  r <- out[i, ]
  cat(sprintf("%-8s %-30s %-30s | %-6.2f (%.2f-%.2f) %-6.2f (%.2f-%.2f) %+.1f\n",
              r$table, r$model, r$term,
              r$est_full, r$LCI_full, r$UCI_full,
              r$est_min,  r$LCI_min,  r$UCI_min,
              r$pct_change))
}
