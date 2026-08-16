#!/usr/bin/env Rscript
# v2: re-frame the question.  Setting: CT is unavailable; we have spirometry
# (FEV1/FVC, ESI) plus the 3 Bhatt symptom criteria.  Does the resulting
# classification approximate Bhatt's full schema, and does it predict outcomes
# (mortality, FEV1 decline) as well?

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(pROC);
  library(survival); library(lme4); library(lmerTest)
})

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/exploration_esi_vs_bhatt_v2_2026.5.17.md"
LOG <- character()
emit <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)

esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
vs_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"

esi <- read.csv(esi_path, stringsAsFactors = FALSE)
esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)

v1 <- phe %>% filter(visitnum == 1) %>%
  select(rand_id, finalgold_visit, FEV1_FVC_post, FEV1pp_post,
         CT_Visual_Emph_Severity, CT_Visual_Wall_Thickening,
         MMRCDyspneaScor, SGRQ_scoreTotal, Chronic_Bronchitis,
         age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI,
         FEV1_post, Height_CM)

vs <- read.csv(vs_path, stringsAsFactors = FALSE); vs$rand_id <- as.character(vs$rand_id)

d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(
    major_criterion = FEV1_FVC_post < 0.70,
    emph_yn = CT_Visual_Emph_Severity >= 1,
    wall_yn = CT_Visual_Wall_Thickening == 2,
    dysp_yn = MMRCDyspneaScor >= 2,
    qol_yn  = SGRQ_scoreTotal >= 25,
    cb_yn   = Chronic_Bronchitis == 1
  )
complete_ix <- with(d, !is.na(major_criterion) & !is.na(emph_yn) & !is.na(wall_yn) &
                       !is.na(dysp_yn) & !is.na(qol_yn) & !is.na(cb_yn))
d <- d %>% filter(complete_ix)

# Stratum
stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d$stratum <- factor(with(d, case_when(
  finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
  finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
  finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
  finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_)),
  levels = stratum_levels)

# Bhatt classification (gold standard for this exploration)
n_minor_bhatt <- d$emph_yn + d$wall_yn + d$dysp_yn + d$qol_yn + d$cb_yn
d$bhatt_cls <- ifelse(d$major_criterion & n_minor_bhatt >= 1, "COPD-major",
               ifelse(!d$major_criterion & n_minor_bhatt >= 3, "COPD-minor",
               ifelse(d$major_criterion & n_minor_bhatt == 0, "AFL-only-NoCOPD",
                                                              "noCOPD")))
d$bhatt_copd <- d$bhatt_cls %in% c("COPD-major","COPD-minor")

# --- ESI substitution variants -----------------------------------------------
# Variant A: 4-criterion (ESI replaces both imaging), ≥2 of 4 minor
# Variant B: 4-criterion, ≥3 of 4 minor (more conservative)
# Variant C: 5-criterion ESI double-counted (ESI≥T_high = 2, T_low ≤ ESI < T_high = 1, else 0)
#            preserves ≥3 of 5 threshold

classify_4crit <- function(df, T, min_count) {
  esi <- df$ESI >= T
  n_minor <- esi + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_minor >= 1,         "COPD-major",
  ifelse(!df$major_criterion & n_minor >= min_count, "COPD-minor",
  ifelse(df$major_criterion & n_minor == 0,         "AFL-only-NoCOPD",
                                                    "noCOPD")))
}
classify_5crit_dc <- function(df, T_low, T_high) {
  esi_score <- ifelse(df$ESI >= T_high, 2,
              ifelse(df$ESI >= T_low,  1, 0))
  n_minor <- esi_score + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_minor >= 1, "COPD-major",
  ifelse(!df$major_criterion & n_minor >= 3, "COPD-minor",
  ifelse(df$major_criterion & n_minor == 0, "AFL-only-NoCOPD",
                                            "noCOPD")))
}

emit("# ESI as a substitute for imaging in the Bhatt 2025 schema — v2")
emit("")
emit(sprintf("Setting: CT is unavailable; we have **spirometry (FEV1/FVC, ESI) + the 3 Bhatt symptom criteria** (mMRC ≥ 2; SGRQ ≥ 25; chronic bronchitis).  Does the resulting classification match Bhatt's full schema (which uses CT visual emphysema + wall thickening), and does it predict outcomes similarly?"))
emit("")
emit(sprintf("Cohort: n = %d V1 subjects with valid ESI and all Bhatt criteria.", nrow(d)))
emit("")
emit("Bhatt distribution: COPD-major %d, COPD-minor %d, AFL-only-NoCOPD %d, noCOPD %d.",
     sum(d$bhatt_cls=="COPD-major"), sum(d$bhatt_cls=="COPD-minor"),
     sum(d$bhatt_cls=="AFL-only-NoCOPD"), sum(d$bhatt_cls=="noCOPD"))
emit("")

# --- Variant comparison ------------------------------------------------------
kappa_fn <- function(a, b) {
  tab <- table(a, b); po <- sum(diag(tab))/sum(tab)
  pe <- sum(rowSums(tab)*colSums(tab))/sum(tab)^2
  (po - pe)/(1 - pe)
}

emit("## Agreement of ESI-substituted variants vs Bhatt — binary COPD vs noCOPD")
emit("")
emit("| Variant | n COPD | Sens | Spec | κ |")
emit("|---|---:|---:|---:|---:|")

variants <- list(
  list(name="4-crit, ESI≥1.5, ≥2-of-4", fn=function(x) classify_4crit(x, 1.5, 2)),
  list(name="4-crit, ESI≥2.0, ≥2-of-4", fn=function(x) classify_4crit(x, 2.0, 2)),
  list(name="4-crit, ESI≥2.5, ≥2-of-4", fn=function(x) classify_4crit(x, 2.5, 2)),
  list(name="4-crit, ESI≥1.5, ≥3-of-4", fn=function(x) classify_4crit(x, 1.5, 3)),
  list(name="4-crit, ESI≥2.0, ≥3-of-4", fn=function(x) classify_4crit(x, 2.0, 3)),
  list(name="5-crit double, T_low=1.0/T_high=2.5", fn=function(x) classify_5crit_dc(x, 1.0, 2.5)),
  list(name="5-crit double, T_low=1.5/T_high=3.0", fn=function(x) classify_5crit_dc(x, 1.5, 3.0)),
  list(name="5-crit double, T_low=2.0/T_high=3.5", fn=function(x) classify_5crit_dc(x, 2.0, 3.5))
)
variant_cls <- list()
for (v in variants) {
  cls  <- v$fn(d); copd <- cls %in% c("COPD-major","COPD-minor")
  variant_cls[[v$name]] <- list(cls = cls, copd = copd)
  tp <- sum(d$bhatt_copd & copd);  fp <- sum(!d$bhatt_copd & copd)
  fn <- sum(d$bhatt_copd & !copd); tn <- sum(!d$bhatt_copd & !copd)
  sens <- tp/(tp+fn); spec <- tn/(tn+fp); k <- kappa_fn(d$bhatt_copd, copd)
  emit(sprintf("| %s | %d | %.3f | %.3f | %.3f |",
               v$name, sum(copd), sens, spec, k))
}

# Pick a working variant for downstream analysis (the highest-κ)
best_name <- names(variant_cls)[which.max(sapply(variant_cls, function(x) kappa_fn(d$bhatt_copd, x$copd)))]
best_copd <- variant_cls[[best_name]]$copd
best_cls  <- variant_cls[[best_name]]$cls
d$esi_cls  <- best_cls
d$esi_copd <- best_copd
emit(sprintf("\nBest κ variant: **%s**\n", best_name))

# --- Per-stratum agreement among preserved-spirometry --------------------------
emit("## Per-stratum agreement among preserved-spirometry subjects")
emit("")
emit("Within preserved spirometry (FEV1/FVC ≥ 0.70), the Bhatt minor-category COPD subset is the question that matters.  How well does the symptoms + ESI classification recover it?")
emit("")
emit("| Stratum | n | Bhatt-COPD | ESI-variant COPD | Both | Bhatt-only | ESI-only | Sens | Spec |")
emit("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
preserved <- d %>% filter(!major_criterion, !is.na(stratum))
for (s in c("Never","GOLD0","PRISm")) {
  sub <- preserved %>% filter(stratum == s)
  if (nrow(sub) == 0) next
  bcopd <- sub$bhatt_copd; ecopd <- sub$esi_copd
  both <- sum(bcopd & ecopd); bonly <- sum(bcopd & !ecopd); eonly <- sum(!bcopd & ecopd)
  neither <- sum(!bcopd & !ecopd)
  sens <- if (sum(bcopd) > 0) both/sum(bcopd) else NA
  spec <- if (sum(!bcopd) > 0) neither/sum(!bcopd) else NA
  emit(sprintf("| %s | %d | %d | %d | %d | %d | %d | %.2f | %.2f |",
               s, nrow(sub), sum(bcopd), sum(ecopd),
               both, bonly, eonly, sens, spec))
}

# --- 4-way classification cross-tab (full cohort) -----------------------------
emit("\n## Full 4-way classification cross-tab (best variant)")
emit("")
emit("```")
tab4 <- table(Bhatt = d$bhatt_cls, ESI_variant = d$esi_cls)
emit(paste(capture.output(print(tab4)), collapse = "\n"))
emit("```")

# --- Outcome prediction: mortality and FEV1 decline --------------------------
emit("\n## Outcome prediction: does the ESI-substituted classification predict outcomes as well as Bhatt?")
emit("")
emit("Compare three classifications head-to-head for predicting (a) all-cause mortality and (b) FEV1 decline.  All models adjusted for age, sex, race, current smoking, pack-years, BMI.  Reference category: Bhatt noCOPD (or ESI noCOPD for the ESI-variant model).")
emit("")

# Mortality merge
mort <- d %>% inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id")
mort$gender     <- factor(mort$gender)
mort$race       <- factor(mort$race)
mort$SmokCigNow <- factor(mort$SmokCigNow)
mort$bhatt_grp <- factor(mort$bhatt_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"))
mort$esi_grp   <- factor(mort$esi_cls,   levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major"))
mort_in <- mort %>% filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

# Cox models — categorical predictors (4-level)
cox_bhatt <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_in)
cox_esi   <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_in)

emit("### Mortality HRs (vs noCOPD reference) — adjusted Cox models")
emit("")
emit("| Group | Bhatt HR (95% CI) | ESI-variant HR (95% CI) |")
emit("|---|---|---|")
for (g in c("AFL-only-NoCOPD","COPD-minor","COPD-major")) {
  term <- paste0(c("bhatt_grp","esi_grp"), g)
  bs <- summary(cox_bhatt)$conf.int; bcoef <- summary(cox_bhatt)$coef
  es <- summary(cox_esi)$conf.int;   ecoef <- summary(cox_esi)$coef
  bhr <- if (term[1] %in% rownames(bs)) sprintf("%.2f (%.2f–%.2f), p=%.3g",
            bs[term[1],"exp(coef)"], bs[term[1],"lower .95"], bs[term[1],"upper .95"],
            bcoef[term[1],"Pr(>|z|)"]) else "—"
  ehr <- if (term[2] %in% rownames(es)) sprintf("%.2f (%.2f–%.2f), p=%.3g",
            es[term[2],"exp(coef)"], es[term[2],"lower .95"], es[term[2],"upper .95"],
            ecoef[term[2],"Pr(>|z|)"]) else "—"
  emit(sprintf("| %s | %s | %s |", g, bhr, ehr))
}
emit(sprintf("\nC-index — Bhatt model: %.3f; ESI-variant model: %.3f.",
             concordance(cox_bhatt)$concordance, concordance(cox_esi)$concordance))

# FEV1 decline (LMM)
fev1_long <- phe %>% filter(visitnum %in% c(1,2,3),
                            !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit    = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow   = factor(SmokCigNow))
v1_baseline <- d %>% transmute(rand_id, bhatt_grp = factor(bhatt_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
                               esi_grp   = factor(esi_cls,   levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
                               Height_CM = as.numeric(Height_CM),
                               gender_baseline = factor(gender),
                               race_baseline   = factor(race))
decline_d <- fev1_long %>% inner_join(v1_baseline, by = "rand_id") %>%
  filter(!is.na(bhatt_grp), !is.na(esi_grp),
         !is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))

# Years × group interaction
lmm_b <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id), data = decline_d)
lmm_e <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp   + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id), data = decline_d)

emit("\n### FEV1 decline slope (vs noCOPD reference) — interaction term, mL/yr per group")
emit("")
emit("| Group | Bhatt slope (mL/yr, p) | ESI-variant slope (mL/yr, p) |")
emit("|---|---|---|")
for (g in c("AFL-only-NoCOPD","COPD-minor","COPD-major")) {
  tb <- paste0("years_from_baseline:bhatt_grp", g)
  te <- paste0("years_from_baseline:esi_grp", g)
  cb <- summary(lmm_b)$coef; ce <- summary(lmm_e)$coef
  bv <- if (tb %in% rownames(cb)) sprintf("%+.2f, p=%.3g", cb[tb,"Estimate"], cb[tb,"Pr(>|t|)"]) else "—"
  ev <- if (te %in% rownames(ce)) sprintf("%+.2f, p=%.3g", ce[te,"Estimate"], ce[te,"Pr(>|t|)"]) else "—"
  emit(sprintf("| %s | %s | %s |", g, bv, ev))
}
emit(sprintf("\nLMM AIC — Bhatt: %.1f; ESI-variant: %.1f.", AIC(lmm_b), AIC(lmm_e)))

writeLines(unlist(LOG), OUT)
cat(sprintf("Wrote: %s\n", OUT))
