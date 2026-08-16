#!/usr/bin/env Rscript
# Exacerbation analyses for §3.2, §3.5, and Tables 10, 11 (2026-06-25).
# Outcome: Total_Exacerbations (count) with log(Years_Followed) offset.
# Model: negative binomial.  FEV1/FVC scaled per 0.1-unit.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(MASS); library(ggplot2)
})
select <- dplyr::select

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
ex_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/LFU_SidLevel_Comorbd_randid.csv"

esi <- read.csv(esi_path, stringsAsFactors = FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)

ex <- read.csv(ex_path, stringsAsFactors = FALSE); ex$rand_id <- as.character(ex$rand_id)
# Need positive person-time and non-missing outcome
ex <- ex %>% filter(!is.na(Total_Exacerbations), !is.na(Years_Followed), Years_Followed > 0)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels))

merge_ex <- d %>%
  inner_join(ex %>% select(rand_id, Total_Exacerbations, Total_Severe_Exacer, Years_Followed),
             by = "rand_id") %>%
  mutate(gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
         FF_per_0_1 = FEV1_FVC_post / 0.1)

ex_in <- merge_ex %>% filter(!is.na(stratum), !is.na(FEV1_FVC_post),
                             !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
ex_in$stratum <- relevel(ex_in$stratum, ref = "GOLD0")

cat(sprintf("Exacerbation merge: n = %d, with %d total exacerbations over median %.1f y of follow-up\n",
            nrow(ex_in), sum(ex_in$Total_Exacerbations),
            median(ex_in$Years_Followed)))

# Helper: pull IRR with 95% CI and p
get_irr <- function(fit, var) {
  s <- summary(fit)$coef
  if (!var %in% rownames(s)) return(c(IRR = NA, LCI = NA, UCI = NA, p = NA))
  est <- s[var, "Estimate"]; se <- s[var, "Std. Error"]; p <- s[var, "Pr(>|z|)"]
  c(IRR = exp(est), LCI = exp(est - 1.96*se), UCI = exp(est + 1.96*se), p = p)
}

# ----- §3.2 extension — three pooled models + sensitivity -----
m_esi   <- glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
m_ff    <- glm.nb(Total_Exacerbations ~ FF_per_0_1   + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
m_both  <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
m_ceil  <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)),
                  data = ex_in %>% filter(ESI_v1post < 9.999))

# Severe (sensitivity)
m_both_sev <- glm.nb(Total_Severe_Exacer ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)

build_t_ex <- function() {
  rows <- list(
    list(label = "ESI only",                fit_esi = m_esi,  fit_ff = NULL),
    list(label = "FEV1/FVC only",           fit_esi = NULL,   fit_ff = m_ff),
    list(label = "ESI + FEV1/FVC",          fit_esi = m_both, fit_ff = m_both),
    list(label = "ESI + FEV1/FVC, ESI<10",  fit_esi = m_ceil, fit_ff = m_ceil)
  )
  do.call(rbind, lapply(rows, function(r) {
    e <- if (is.null(r$fit_esi)) c(IRR=NA,LCI=NA,UCI=NA,p=NA) else get_irr(r$fit_esi, "ESI_v1post")
    f <- if (is.null(r$fit_ff))  c(IRR=NA,LCI=NA,UCI=NA,p=NA) else get_irr(r$fit_ff,  "FF_per_0_1")
    data.frame(model = r$label,
               esi_IRR = e["IRR"], esi_LCI = e["LCI"], esi_UCI = e["UCI"], esi_p = e["p"],
               ff_IRR  = f["IRR"], ff_LCI  = f["LCI"], ff_UCI  = f["UCI"], ff_p  = f["p"])
  }))
}
t_ex <- build_t_ex()
write.csv(t_ex, file.path(OUT_DIR, "Table_Exacerbations_Pooled.csv"), row.names = FALSE)

# LR test ESI added to FF+covariates
lr_ex <- anova(m_ff, m_both, test = "Chisq")
writeLines(c(sprintf("LR_chisq=%.2f", lr_ex$`LR stat.`[2]),
             sprintf("LR_p=%.3e",     lr_ex$`Pr(Chi)`[2]),
             sprintf("n_cohort=%d",   nrow(ex_in)),
             sprintf("n_total_exac=%d", sum(ex_in$Total_Exacerbations)),
             sprintf("med_yr=%.1f",    median(ex_in$Years_Followed)),
             # Severe exacerbation key effect — for narrative use
             sprintf("sev_ESI_IRR=%.3f",  exp(coef(m_both_sev)["ESI_v1post"])),
             sprintf("sev_ESI_p=%.3e",   summary(m_both_sev)$coef["ESI_v1post","Pr(>|z|)"])),
           file.path(OUT_DIR, "Table_Exacerbations_Pooled_stats.txt"))

# ----- Per-stratum IRR (parallel to Table 4) -----
strata_to_test <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
t_ex_strat <- do.call(rbind, lapply(strata_to_test, function(s) {
  df <- ex_in %>% filter(stratum == s)
  n_exac <- sum(df$Total_Exacerbations)
  if (nrow(df) < 50 || n_exac < 10)
    return(data.frame(stratum=s, n=nrow(df), total_exac=n_exac,
                      IRR=NA, LCI=NA, UCI=NA, p=NA))
  fit <- try(glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 +
                      age_visit + gender + race + SmokCigNow + ATS_PackYears +
                      offset(log(Years_Followed)), data = df), silent = TRUE)
  if (inherits(fit, "try-error"))
    return(data.frame(stratum=s, n=nrow(df), total_exac=n_exac, IRR=NA, LCI=NA, UCI=NA, p=NA))
  v <- get_irr(fit, "ESI_v1post")
  data.frame(stratum=s, n=nrow(df), total_exac=n_exac,
             IRR=v["IRR"], LCI=v["LCI"], UCI=v["UCI"], p=v["p"])
}))
write.csv(t_ex_strat, file.path(OUT_DIR, "Table_Exacerbations_PerStratum.csv"), row.names = FALSE)

# ----- §3.5 extension: Bhatt vs ESI-variant exacerbation IRRs -----
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
esi_s <- ifelse(d_b$ESI_v1post >= 2.5, 2, ifelse(d_b$ESI_v1post >= 1.0, 1, 0))
n_minor_e <- esi_s + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
                ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
                ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD",
                                                              "noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major","COPD-minor")
d_b$esi_copd   <- d_b$esi_cls   %in% c("COPD-major","COPD-minor")

ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
ex_b <- d_b %>% inner_join(ex %>% select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0) %>%
  mutate(bhatt_grp = factor(bhatt_cls, levels = ord),
         esi_grp   = factor(esi_cls,   levels = ord),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

nb_b <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
nb_e <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)

groups <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")
build_bhatt_ex <- function() {
  do.call(rbind, lapply(groups, function(g) {
    b <- get_irr(nb_b, paste0("bhatt_grp", g))
    e <- get_irr(nb_e, paste0("esi_grp",   g))
    data.frame(group = g,
               bhatt_IRR=b["IRR"], bhatt_LCI=b["LCI"], bhatt_UCI=b["UCI"], bhatt_p=b["p"],
               esi_IRR=e["IRR"],   esi_LCI=e["LCI"],   esi_UCI=e["UCI"],   esi_p=e["p"])
  }))
}
t_bhatt_ex <- build_bhatt_ex()
write.csv(t_bhatt_ex, file.path(OUT_DIR, "Table_Exacerbations_Bhatt.csv"), row.names = FALSE)
writeLines(c(sprintf("n_cohort=%d",      nrow(ex_b)),
             sprintf("n_total_exac=%d",  sum(ex_b$Total_Exacerbations))),
           file.path(OUT_DIR, "Table_Exacerbations_Bhatt_stats.txt"))

# ----- Discordance subgroups (Table 10 extension) -----
categorize <- function(b, e) {
  case_when(
    b  &  e ~ "Both-COPD",
    b  & !e ~ "Bhatt-only-COPD (ESI missed)",
    !b &  e ~ "ESI-only-COPD (Bhatt missed)",
    !b & !e ~ "Both-noCOPD"
  )
}
ex_b$grp <- factor(categorize(ex_b$bhatt_copd, ex_b$esi_copd),
                   levels = c("Both-noCOPD","Both-COPD",
                              "Bhatt-only-COPD (ESI missed)",
                              "ESI-only-COPD (Bhatt missed)"))
ex_pres <- ex_b %>% filter(!major_criterion)

nb_grp <- glm.nb(Total_Exacerbations ~ grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_pres)
t_disc_ex <- data.frame(
  group = c("Both-COPD", "Bhatt-only-COPD (ESI missed)", "ESI-only-COPD (Bhatt missed)"),
  n          = c(sum(ex_pres$grp == "Both-COPD"),
                 sum(ex_pres$grp == "Bhatt-only-COPD (ESI missed)"),
                 sum(ex_pres$grp == "ESI-only-COPD (Bhatt missed)"))
)
for (g in t_disc_ex$group) {
  v <- get_irr(nb_grp, paste0("grp", g))
  i <- match(g, t_disc_ex$group)
  t_disc_ex$IRR[i] <- v["IRR"]; t_disc_ex$LCI[i] <- v["LCI"]; t_disc_ex$UCI[i] <- v["UCI"]; t_disc_ex$p[i] <- v["p"]
}
write.csv(t_disc_ex, file.path(OUT_DIR, "Table_Exacerbations_Discordance.csv"), row.names = FALSE)

cat("\nAssets written:\n")
print(c("Table_Exacerbations_Pooled.csv",
        "Table_Exacerbations_Pooled_stats.txt",
        "Table_Exacerbations_PerStratum.csv",
        "Table_Exacerbations_Bhatt.csv",
        "Table_Exacerbations_Bhatt_stats.txt",
        "Table_Exacerbations_Discordance.csv"))
