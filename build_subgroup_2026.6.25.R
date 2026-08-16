#!/usr/bin/env Rscript
# Subgroup-specific outcome analyses for the restructured manuscript.
# A: outcomes by Bhatt category (head-to-head vs ESI-Bhatt category)
# B: outcomes by cross-tab cell (Both-COPD, Bhatt-only-COPD, ESI-only-COPD)
# Outcomes: cause-specific mortality (CVD, Cancer, Other), FEV1 decline (decline by discord).

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(survival); library(lme4); library(lmerTest)
})
select <- dplyr::select

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv", stringsAsFactors=FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv", stringsAsFactors=FALSE, na.strings=c("","NA")); phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)
vs <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE); vs$rand_id <- as.character(vs$rand_id)
cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE); cod$rand_id <- as.character(cod$rand_id.x)

# Build Bhatt cohort
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_CVD, CCOD_Cancer, CCOD_Other, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2,
         qol_yn  = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1,
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow))
d <- d %>% filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
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

ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
d$bhatt_grp <- factor(d$bhatt,   levels = ord)
d$esi_grp   <- factor(d$esi_cls, levels = ord)
d$bhatt_copd <- d$bhatt   %in% c("COPD-major","COPD-minor")
d$esi_copd   <- d$esi_cls %in% c("COPD-major","COPD-minor")
d$discord <- with(d, case_when(
  bhatt_copd & esi_copd ~ "Both-COPD",
  bhatt_copd & !esi_copd ~ "Bhatt-only-COPD",
  !bhatt_copd & esi_copd ~ "ESI-only-COPD",
  TRUE ~ "Both-noCOPD"))
d$discord <- factor(d$discord,
                    levels = c("Both-noCOPD","Both-COPD","Bhatt-only-COPD","ESI-only-COPD"))

# Helper: Cox HR + 95% CI for a given event indicator and grouping var
get_hr_all <- function(fit, term) {
  s <- summary(fit)
  if (!term %in% rownames(s$conf.int)) return(c(HR=NA,LCI=NA,UCI=NA,p=NA))
  c(HR  = unname(s$conf.int[term,"exp(coef)"]),
    LCI = unname(s$conf.int[term,"lower .95"]),
    UCI = unname(s$conf.int[term,"upper .95"]),
    p   = unname(s$coef[term,"Pr(>|z|)"]))
}

# Standard covariates: age, sex, race, smoking, pack-years, BMI (no stratum — group is the predictor)
covs <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"

mk_event <- function(d, c) ifelse(d$vital_status == 1 & !is.na(d[[c]]) & d[[c]] == 1, 1, 0)

# =====================================================================
# A) By Bhatt category (vs noCOPD reference) — cause-specific
# =====================================================================
causes <- c("CCOD_CVD","CCOD_Cancer","CCOD_Other")
cause_labels <- c("CVD","Cancer","Other")
groups_to_test <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")

t_by_bhatt <- list()
t_by_esi   <- list()
for (i in seq_along(causes)) {
  c <- causes[i]; lab <- cause_labels[i]
  ev <- mk_event(d, c)
  fit_b <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ bhatt_grp +", covs)), data = d)
  fit_e <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ esi_grp +", covs)), data = d)

  for (g in groups_to_test) {
    bh <- get_hr_all(fit_b, paste0("bhatt_grp", g))
    eh <- get_hr_all(fit_e, paste0("esi_grp", g))
    bn_events <- sum(ev[d$bhatt_grp == g] == 1)
    en_events <- sum(ev[d$esi_grp == g] == 1)
    t_by_bhatt[[length(t_by_bhatt)+1]] <- data.frame(
      cause = lab, group = g, n_events_bhatt = bn_events,
      bhatt_HR=bh["HR"], bhatt_LCI=bh["LCI"], bhatt_UCI=bh["UCI"], bhatt_p=bh["p"]
    )
    t_by_esi[[length(t_by_esi)+1]] <- data.frame(
      cause = lab, group = g, n_events_esi = en_events,
      esi_HR=eh["HR"], esi_LCI=eh["LCI"], esi_UCI=eh["UCI"], esi_p=eh["p"]
    )
  }
}
t_cs_class <- do.call(rbind, t_by_bhatt) %>%
  inner_join(do.call(rbind, t_by_esi), by = c("cause","group"))
write.csv(t_cs_class, file.path(OUT_DIR, "Table_CauseSpecific_byClass.csv"), row.names = FALSE)

# =====================================================================
# B) By discordance cell (preserved-spirometry only) — cause-specific
# =====================================================================
d_pres <- d %>% filter(!major_criterion)  # preserved spirometry
# Reference = Both-noCOPD; predictors = Both-COPD, Bhatt-only-COPD, ESI-only-COPD
t_cs_disc <- list()
for (i in seq_along(causes)) {
  c <- causes[i]; lab <- cause_labels[i]
  ev <- mk_event(d_pres, c)
  fit <- coxph(as.formula(paste("Surv(days_followed/365.25, ev) ~ discord +", covs)), data = d_pres)
  for (g in c("Both-COPD","Bhatt-only-COPD","ESI-only-COPD")) {
    hr <- get_hr_all(fit, paste0("discord", g))
    n_events <- sum(ev[d_pres$discord == g] == 1)
    t_cs_disc[[length(t_cs_disc)+1]] <- data.frame(
      cause = lab, group = g, n_events = n_events,
      HR = hr["HR"], LCI = hr["LCI"], UCI = hr["UCI"], p = hr["p"]
    )
  }
}
t_cs_disc <- do.call(rbind, t_cs_disc)
write.csv(t_cs_disc, file.path(OUT_DIR, "Table_CauseSpecific_byDiscord.csv"), row.names = FALSE)

# =====================================================================
# C) FEV1 decline by discordance cell (preserved-spirometry only)
# =====================================================================
fev1_long <- phe %>% filter(visitnum %in% c(1, 2, 3),
                            !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow = factor(SmokCigNow))

base_pres <- d_pres %>% transmute(rand_id,
                                  discord = factor(discord,
                                                   levels = c("Both-noCOPD","Both-COPD",
                                                              "Bhatt-only-COPD","ESI-only-COPD")),
                                  Height_CM = as.numeric(Height_CM),
                                  gender_baseline = factor(gender),
                                  race_baseline   = factor(race))

decline_d <- fev1_long %>% inner_join(base_pres, by = "rand_id") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))

lmm_disc <- lmer(FEV1_post_mL ~ years_from_baseline * discord +
                   Height_CM + gender_baseline + race_baseline +
                   age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id),
                 data = decline_d)
co <- summary(lmm_disc)$coef

get_int <- function(term) {
  if (!term %in% rownames(co)) return(c(est=NA, se=NA, p=NA))
  c(est = co[term,"Estimate"], se = co[term,"Std. Error"], p = co[term,"Pr(>|t|)"])
}

t_dec_disc <- data.frame(
  group = c("Both-COPD","Bhatt-only-COPD","ESI-only-COPD"),
  n_subj = c(sum(decline_d$discord == "Both-COPD" & !duplicated(decline_d$rand_id)),
             sum(decline_d$discord == "Bhatt-only-COPD" & !duplicated(decline_d$rand_id)),
             sum(decline_d$discord == "ESI-only-COPD" & !duplicated(decline_d$rand_id)))
)
for (g in t_dec_disc$group) {
  v <- get_int(paste0("years_from_baseline:discord", g))
  i <- match(g, t_dec_disc$group)
  t_dec_disc$est[i] <- v["est"]; t_dec_disc$se[i] <- v["se"]; t_dec_disc$p[i] <- v["p"]
}
write.csv(t_dec_disc, file.path(OUT_DIR, "Table_FEV1Decline_byDiscord.csv"), row.names = FALSE)

cat("\nDone.  Tables saved.\n")
cat("\n=== By classification (cause-specific HR vs noCOPD) — Bhatt + ESI side by side ===\n")
print(t_cs_class %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))) %>%
        select(cause, group,
               n_b = n_events_bhatt, bhatt_HR, bhatt_p,
               n_e = n_events_esi,   esi_HR,   esi_p))
cat("\n=== By discordance (cause-specific HR vs Both-noCOPD) ===\n")
print(t_cs_disc %>% mutate(across(where(is.numeric), ~ round(.x, 3))))
cat("\n=== FEV1 decline by discordance ===\n")
print(t_dec_disc %>% mutate(across(where(is.numeric), ~ round(.x, 3))))
