#!/usr/bin/env Rscript
# Implement items 2-6 of the Massimo response action plan (2026-06-22).
#   2. Supplementary CT correlations (LAA-856/LAA-950/PRM table + PRM-substituted Table 2)
#   3. Figure 3 redesign — Panel B as within-subject ΔFEV1 by ESI tertile in GOLD 0
#   4. New PRISm-vs-GOLD-0 trajectory figure (Figure 6)
#   6. Respiratory-cause mortality Cox analyses (all the Cox tables/figures, parallel)

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(scales)
  library(survival); library(lme4); library(lmerTest); library(patchwork)
})

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
vs_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"
cod_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv"

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
stratum_pal <- c(
  Never="#7F7F7F", GOLD0="#1F77B4", PRISm="#9467BD",
  GOLD1="#2CA02C", GOLD2="#FFB000", GOLD3="#D62728", GOLD4="#8B0000"
)

theme_paper <- function(base_size = 10) {
  theme_bw(base_family = "Arial", base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey92", linewidth = 0.3),
      strip.background = element_blank(),
      strip.text       = element_text(face = "plain", size = base_size),
      plot.title       = element_text(face = "plain", size = base_size + 1),
      plot.subtitle    = element_text(size = base_size - 1, color = "grey30"),
      axis.title       = element_text(face = "plain"),
      legend.title     = element_text(face = "plain"),
      legend.background = element_blank()
    )
}
theme_set(theme_paper())

# --- Load ---------------------------------------------------------------------
esi_raw <- read.csv(esi_path, stringsAsFactors = FALSE)
esi_raw <- esi_raw[, c("rand_id","visitnum","PrePost","FVC","PEF","FEF25","FEF50","FEF75","ESI")]
esi_raw$rand_id  <- as.character(esi_raw$rand_id)
esi_raw$visitnum <- as.integer(esi_raw$visitnum)
esi_raw$PrePost  <- as.integer(esi_raw$PrePost)

esi_v1 <- esi_raw %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe_all <- read.csv(phe_path, stringsAsFactors = FALSE, na.strings = c("","NA"))
phe_all$rand_id <- as.character(phe_all$rand_id)
phe_v1 <- phe_all %>% filter(visitnum == 1)

d <- esi_v1 %>% inner_join(phe_v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels))

vs  <- read.csv(vs_path,  stringsAsFactors = FALSE); vs$rand_id  <- as.character(vs$rand_id)
cod <- read.csv(cod_path, stringsAsFactors = FALSE)
cod$rand_id <- as.character(cod$rand_id.x)

# Build a mortality table with both all-cause and respiratory event flags.
# Respiratory event = death AND CCOD_COPD_resp == 1.  Death-of-unknown-cause is
# treated as a competing-risk censor (event_resp = 0).
mort <- d %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(
    event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
    gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)
  )

cat(sprintf("Mortality merge: n = %d; deaths (all-cause) = %d; deaths (respiratory) = %d\n",
            nrow(mort), sum(mort$vital_status == 1), sum(mort$event_resp == 1)))

# --- Item 2a: LAA-856 / LAA-950 / PRM emphysema correlations -------------------
ct_cols <- c("Exp_LAA856_total_Thirona","Insp_LAA950_total_Thirona",
             "PRM_pct_emphysema_Thirona","PRM_pct_airtrapping_Thirona","pctEmph_Thirona")
ct_df <- d[, ct_cols]
ct_cor <- cor(ct_df, use = "pairwise.complete.obs")
write.csv(round(ct_cor, 3), file.path(OUT_DIR, "Supp_Table_CT_correlations.csv"))

# --- Item 2b: per-stratum correlation table with PRM emphysema -----------------
t2_prm <- d %>% filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(
    n_FF       = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
    r_FF       = cor(ESI_v1post, FEV1_FVC_post,              use="pairwise.complete.obs"),
    n_PRM      = sum(complete.cases(ESI_v1post, PRM_pct_emphysema_Thirona)),
    r_PRM      = cor(ESI_v1post, PRM_pct_emphysema_Thirona,  use="pairwise.complete.obs"),
    .groups = "drop"
  )
overall <- d %>% summarise(
  stratum = "All strata",
  n_FF    = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
  r_FF    = cor(ESI_v1post, FEV1_FVC_post,              use="pairwise.complete.obs"),
  n_PRM   = sum(complete.cases(ESI_v1post, PRM_pct_emphysema_Thirona)),
  r_PRM   = cor(ESI_v1post, PRM_pct_emphysema_Thirona,  use="pairwise.complete.obs")) %>%
  mutate(stratum = "All strata")
t2_prm <- bind_rows(t2_prm %>% mutate(stratum = as.character(stratum)), overall)
write.csv(t2_prm, file.path(OUT_DIR, "Table_2_PRMversion.csv"), row.names = FALSE)

# --- Item 3: Figure 3 Panel B redesign — within-subject ΔFEV1 in GOLD 0 -------
fev1_long <- phe_all %>%
  filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
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
      transmute(rand_id, Height_CM = as.numeric(Height_CM),
                gender_baseline = factor(gender),
                race_baseline   = factor(race),
                FEV1_post_V1    = FEV1_post * 1000),
    by = "rand_id"
  )
decline_d <- fev1_long %>% inner_join(v1_baseline, by = "rand_id") %>%
  filter(!is.na(ESI_baseline), !is.na(FEV1_FVC_baseline),
         !is.na(stratum_baseline), !is.na(Height_CM),
         !is.na(age_visit), !is.na(SmokCigNow), !is.na(FEV1_post_V1)) %>%
  mutate(deltaFEV1_mL = FEV1_post_mL - FEV1_post_V1)

# Forest plot (Panel A) — unchanged from previous Figure 3
forest_strata <- c("GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
get_int_ci <- function(fit, term) {
  co <- summary(fit)$coef
  if (!term %in% rownames(co)) return(c(est=NA, lci=NA, uci=NA, p=NA))
  e <- co[term,"Estimate"]; s <- co[term,"Std. Error"]
  c(est = e, lci = e - 1.96*s, uci = e + 1.96*s, p = co[term,"Pr(>|t|)"])
}
forest_rows <- do.call(rbind, lapply(forest_strata, function(s) {
  df <- decline_d %>% filter(stratum_baseline == s)
  if (length(unique(df$rand_id)) < 50) return(NULL)
  safe_covs <- c()
  if (length(unique(df$SmokCigNow))      > 1) safe_covs <- c(safe_covs, "SmokCigNow")
  if (length(unique(df$gender_baseline)) > 1) safe_covs <- c(safe_covs, "gender_baseline")
  if (length(unique(df$race_baseline))   > 1) safe_covs <- c(safe_covs, "race_baseline")
  rhs <- paste("years_from_baseline*(ESI_baseline + FEV1_FVC_baseline)",
               "+ Height_CM + age_visit + ATS_PackYears",
               if (length(safe_covs)) paste("+", paste(safe_covs, collapse=" + ")) else "",
               "+ (1 | rand_id)")
  fit <- try(lmer(as.formula(paste("FEV1_post_mL ~", rhs)), data = df), silent = TRUE)
  if (inherits(fit, "try-error")) return(NULL)
  e <- get_int_ci(fit, "years_from_baseline:ESI_baseline")
  f <- get_int_ci(fit, "years_from_baseline:FEV1_FVC_baseline")
  rbind(
    data.frame(stratum=s, predictor="ESI",
               est=e["est"], lci=e["lci"], uci=e["uci"], p=e["p"]),
    data.frame(stratum=s, predictor="FEV1/FVC",
               est=f["est"], lci=f["lci"], uci=f["uci"], p=f["p"])
  )
}))
forest_rows$stratum   <- factor(forest_rows$stratum, levels = rev(forest_strata))
forest_rows$predictor <- factor(forest_rows$predictor, levels = c("ESI","FEV1/FVC"))

panelA <- ggplot(forest_rows, aes(x = est, y = stratum, color = stratum)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = lci, xmax = uci), height = 0.25, linewidth = 0.6) +
  geom_point(size = 2.5) +
  facet_wrap(~ predictor, scales = "free_x", ncol = 2) +
  scale_color_manual(values = stratum_pal, guide = "none") +
  labs(x = "Coefficient (mL/yr per 1-unit higher baseline predictor)",
       y = NULL,
       title = "A. Per-stratum × time interaction coefficients (95% CI)")

# Panel B: within-subject ΔFEV1 in GOLD 0 by ESI tertile
tert_g0 <- quantile(decline_d$ESI_baseline[decline_d$stratum_baseline == "GOLD0"],
                    c(1/3, 2/3), na.rm = TRUE)
g0 <- decline_d %>% filter(stratum_baseline == "GOLD0") %>%
  mutate(ESI_tertile = cut(ESI_baseline,
                           breaks = c(-Inf, tert_g0[1], tert_g0[2], Inf),
                           labels = c("Low","Mid","High")))

tert_pal <- setNames(c("#1F77B4","#FFB000","#D62728"), c("Low","Mid","High"))

panelB <- ggplot(g0, aes(x = years_from_baseline, y = deltaFEV1_mL,
                         color = ESI_tertile, fill = ESI_tertile)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_smooth(method = "loess", se = TRUE, linewidth = 0.9, alpha = 0.15,
              span = 1, formula = y ~ x) +
  scale_color_manual(values = tert_pal, name = "Baseline ESI tertile") +
  scale_fill_manual(values = tert_pal, guide = "none") +
  scale_x_continuous(limits = c(0, 11), breaks = seq(0, 10, 2)) +
  labs(x = "Years from baseline",
       y = "Change in FEV1 from baseline (mL), post-BD",
       title = "B. GOLD 0 — within-subject FEV1 change by baseline ESI tertile") +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 9),
        legend.text  = element_text(size = 9))

fig3 <- panelA + panelB + plot_layout(widths = c(1.4, 1))
ggsave(file.path(OUT_DIR, "Figure_3.png"), fig3, width = 12, height = 5, dpi = 300)

# --- Item 4: Figure 6 — PRISm vs GOLD 0 within-subject ΔESI -------------------
esi_long_post <- esi_raw %>% filter(PrePost == 1) %>%
  group_by(rand_id, visitnum) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
baseline_stratum <- d %>% select(rand_id, baseline_stratum = stratum, ESI_v1post)
long_esi <- esi_long_post %>% inner_join(baseline_stratum, by = "rand_id") %>%
  mutate(deltaESI = ESI - ESI_v1post)

f6_summary <- long_esi %>%
  filter(baseline_stratum %in% c("GOLD0","PRISm"), !is.na(ESI)) %>%
  group_by(baseline_stratum, visitnum) %>%
  summarise(
    n          = n(),
    mean_delta = mean(deltaESI),
    se_delta   = sd(deltaESI)/sqrt(n()),
    median_delta = median(deltaESI),
    .groups = "drop"
  )

# Two-panel: mean (left) and median (right)
f6_long <- bind_rows(
  f6_summary %>% transmute(baseline_stratum, visitnum, stat = "Mean (95% CI)",
                           est = mean_delta,
                           lci = mean_delta - 1.96*se_delta,
                           uci = mean_delta + 1.96*se_delta),
  f6_summary %>% transmute(baseline_stratum, visitnum, stat = "Median",
                           est = median_delta, lci = NA_real_, uci = NA_real_)
)
f6_long$stat <- factor(f6_long$stat, levels = c("Mean (95% CI)","Median"))

fig6 <- ggplot(f6_long, aes(x = factor(visitnum), y = est,
                            color = baseline_stratum, group = baseline_stratum)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_line(linewidth = 0.8) + geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = lci, ymax = uci), width = 0.1, linewidth = 0.6, na.rm = TRUE) +
  facet_wrap(~ stat, ncol = 2) +
  scale_color_manual(values = stratum_pal[c("GOLD0","PRISm")],
                     name = "Baseline stratum") +
  labs(x = "Visit (V1 = baseline, V2 ≈ 5 y, V3 ≈ 10 y)",
       y = "Within-subject change in ESI from baseline",
       title = "Within-subject ΔESI trajectory: PRISm vs GOLD 0")
ggsave(file.path(OUT_DIR, "Figure_6.png"), fig6, width = 9, height = 4.5, dpi = 300)

# --- Item 6: Respiratory mortality Cox analyses ------------------------------
mort_in <- mort %>%
  filter(!is.na(stratum), !is.na(FEV1_FVC_post),
         !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
mort_in$stratum <- relevel(mort_in$stratum, ref = "GOLD0")

# All-cause models (we already computed for Tables 3 and 4; recompute here for parallelism)
make_models <- function(event_col, label) {
  dat  <- mort_in;       dat$event_ <- dat[[event_col]]
  dat2 <- dat %>% filter(ESI_v1post < 9.999)
  m_no  <- coxph(Surv(days_followed/365.25, event_) ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = dat)
  m_ff  <- coxph(Surv(days_followed/365.25, event_) ~ FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = dat)
  m_bo  <- coxph(Surv(days_followed/365.25, event_) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = dat)
  m_se  <- coxph(Surv(days_followed/365.25, event_) ~ ESI_v1post + FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = dat2)
  list(no = m_no, ff = m_ff, bo = m_bo, se = m_se, label = label)
}

mod_all  <- make_models(event_col = "vital_status",  label = "all-cause")
mod_resp <- make_models(event_col = "event_resp",    label = "respiratory")

cox_row <- function(fit, var) {
  s <- summary(fit)
  if (!var %in% rownames(s$coef)) return(c(HR=NA, LCI=NA, UCI=NA, p=NA))
  c(HR = s$conf.int[var,"exp(coef)"], LCI = s$conf.int[var,"lower .95"],
    UCI = s$conf.int[var,"upper .95"], p = s$coef[var,"Pr(>|z|)"])
}

# Table 3-resp: same structure as Table 3
build_t3 <- function(mod) {
  rows <- list(
    list(model="ESI only",                  fit_esi=mod$no, fit_ff=NULL),
    list(model="FEV1/FVC only",             fit_esi=NULL,   fit_ff=mod$ff),
    list(model="ESI + FEV1/FVC",            fit_esi=mod$bo, fit_ff=mod$bo),
    list(model="ESI + FEV1/FVC (ESI<10)",   fit_esi=mod$se, fit_ff=mod$se)
  )
  out <- lapply(rows, function(r) {
    e <- if (is.null(r$fit_esi)) c(HR=NA,LCI=NA,UCI=NA,p=NA) else cox_row(r$fit_esi, "ESI_v1post")
    f <- if (is.null(r$fit_ff))  c(HR=NA,LCI=NA,UCI=NA,p=NA) else cox_row(r$fit_ff,  "FEV1_FVC_post")
    data.frame(model=r$model,
               esi_HR=e["HR"], esi_LCI=e["LCI"], esi_UCI=e["UCI"], esi_p=e["p"],
               ff_HR=f["HR"], ff_LCI=f["LCI"], ff_UCI=f["UCI"], ff_p=f["p"])
  })
  do.call(rbind, out)
}

t3_all  <- build_t3(mod_all);  write.csv(t3_all,  file.path(OUT_DIR, "Table_3_allcause.csv"), row.names = FALSE)
t3_resp <- build_t3(mod_resp); write.csv(t3_resp, file.path(OUT_DIR, "Table_3_resp.csv"),     row.names = FALSE)

lr_all  <- anova(mod_all$ff,  mod_all$bo)
lr_resp <- anova(mod_resp$ff, mod_resp$bo)
writeLines(c(sprintf("LR_chisq_all=%.2f",  lr_all$Chisq[2]),
             sprintf("LR_p_all=%.3e",      lr_all$`Pr(>|Chi|)`[2]),
             sprintf("LR_chisq_resp=%.2f", lr_resp$Chisq[2]),
             sprintf("LR_p_resp=%.3e",     lr_resp$`Pr(>|Chi|)`[2]),
             sprintf("n_cohort=%d",        nrow(mort_in)),
             sprintf("n_deaths_all=%d",    sum(mort_in$vital_status == 1)),
             sprintf("n_deaths_resp=%d",   sum(mort_in$event_resp == 1))),
           file.path(OUT_DIR, "Table_3_stats.txt"))

# Table 4 (per-stratum) — for both outcomes
build_t4 <- function(event_col) {
  strata_to_test <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
  do.call(rbind, lapply(strata_to_test, function(s) {
    df <- mort_in %>% filter(stratum == s)
    deaths <- sum(df[[event_col]] == 1)
    if (deaths < 5 || nrow(df) < 50)
      return(data.frame(stratum=s, n=nrow(df), deaths=deaths,
                        HR=NA, LCI=NA, UCI=NA, p=NA))
    fit <- try(coxph(
      Surv(days_followed/365.25, df[[event_col]]) ~ ESI_v1post + FEV1_FVC_post +
        age_visit + gender + race + SmokCigNow + ATS_PackYears, data = df), silent = TRUE)
    if (inherits(fit, "try-error")) return(data.frame(stratum=s, n=nrow(df), deaths=deaths,
                                                       HR=NA, LCI=NA, UCI=NA, p=NA))
    v <- cox_row(fit, "ESI_v1post")
    data.frame(stratum=s, n=nrow(df), deaths=deaths,
               HR=v["HR"], LCI=v["LCI"], UCI=v["UCI"], p=v["p"])
  }))
}
t4_all  <- build_t4("vital_status"); write.csv(t4_all,  file.path(OUT_DIR, "Table_4_allcause.csv"), row.names = FALSE)
t4_resp <- build_t4("event_resp");   write.csv(t4_resp, file.path(OUT_DIR, "Table_4_resp.csv"),     row.names = FALSE)

# Bhatt vs ESI-variant for respiratory mortality (Table 8 + Figure 5 parallel)
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
esi_score <- ifelse(d_b$ESI_v1post >= 2.5, 2, ifelse(d_b$ESI_v1post >= 1.0, 1, 0))
n_minor_e <- esi_score + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
                ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
                ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD",
                                                              "noCOPD")))

ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
mort_b <- d_b %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
         bhatt_grp = factor(bhatt_cls, levels = ord),
         esi_grp   = factor(esi_cls,   levels = ord),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

cox_bhatt_all <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_esi_all   <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_bhatt_resp <- coxph(Surv(days_followed/365.25, event_resp)   ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_esi_resp   <- coxph(Surv(days_followed/365.25, event_resp)   ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)

build_t8 <- function(cox_b, cox_e) {
  groups <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")
  do.call(rbind, lapply(groups, function(g) {
    bh <- cox_row(cox_b, paste0("bhatt_grp", g))
    eh <- cox_row(cox_e, paste0("esi_grp",   g))
    data.frame(group=g,
               bhatt_HR=bh["HR"], bhatt_LCI=bh["LCI"], bhatt_UCI=bh["UCI"], bhatt_p=bh["p"],
               esi_HR=eh["HR"], esi_LCI=eh["LCI"], esi_UCI=eh["UCI"], esi_p=eh["p"])
  }))
}
t8_all  <- build_t8(cox_bhatt_all,  cox_esi_all);  write.csv(t8_all,  file.path(OUT_DIR, "Table_8_allcause.csv"), row.names = FALSE)
t8_resp <- build_t8(cox_bhatt_resp, cox_esi_resp); write.csv(t8_resp, file.path(OUT_DIR, "Table_8_resp.csv"),     row.names = FALSE)

writeLines(c(sprintf("bhatt_cindex_all=%.3f",   concordance(cox_bhatt_all)$concordance),
             sprintf("esi_cindex_all=%.3f",     concordance(cox_esi_all)$concordance),
             sprintf("bhatt_cindex_resp=%.3f",  concordance(cox_bhatt_resp)$concordance),
             sprintf("esi_cindex_resp=%.3f",    concordance(cox_esi_resp)$concordance),
             sprintf("n_cohort=%d",             nrow(mort_b)),
             sprintf("n_deaths_all=%d",         sum(mort_b$vital_status == 1)),
             sprintf("n_deaths_resp=%d",        sum(mort_b$event_resp == 1))),
           file.path(OUT_DIR, "Table_8_stats.txt"))

# Figure 5 — forest plot now with all-cause AND respiratory
forest5 <- bind_rows(
  data.frame(Group=t8_all$group, schema="Bhatt (with CT)",      outcome="All-cause",
             HR=t8_all$bhatt_HR, LCI=t8_all$bhatt_LCI, UCI=t8_all$bhatt_UCI),
  data.frame(Group=t8_all$group, schema="ESI-substituted (no CT)", outcome="All-cause",
             HR=t8_all$esi_HR,   LCI=t8_all$esi_LCI,   UCI=t8_all$esi_UCI),
  data.frame(Group=t8_resp$group, schema="Bhatt (with CT)",      outcome="Respiratory",
             HR=t8_resp$bhatt_HR, LCI=t8_resp$bhatt_LCI, UCI=t8_resp$bhatt_UCI),
  data.frame(Group=t8_resp$group, schema="ESI-substituted (no CT)", outcome="Respiratory",
             HR=t8_resp$esi_HR,   LCI=t8_resp$esi_LCI,   UCI=t8_resp$esi_UCI)
)
forest5$Group <- factor(forest5$Group,
                        levels = rev(c("AFL-only-NoCOPD","COPD-minor","COPD-major")))
forest5$outcome <- factor(forest5$outcome, levels = c("All-cause","Respiratory"))

fig5 <- ggplot(forest5, aes(x = HR, y = Group, color = schema)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = LCI, xmax = UCI),
                 position = position_dodge(width = 0.4),
                 height = 0.22, linewidth = 0.7) +
  geom_point(position = position_dodge(width = 0.4), size = 2.8) +
  facet_wrap(~ outcome, ncol = 2, scales = "free_x") +
  scale_x_log10(breaks = c(0.5, 1, 2, 5, 10),
                labels = c("0.5","1","2","5","10")) +
  scale_color_manual(values = c("Bhatt (with CT)" = "#1F77B4",
                                "ESI-substituted (no CT)" = "#D62728"),
                     name = NULL) +
  labs(x = "Adjusted mortality HR (95% CI, log scale)", y = NULL,
       title = "Prognostic equivalence — all-cause and respiratory mortality") +
  theme(legend.position = "bottom")
ggsave(file.path(OUT_DIR, "Figure_5.png"), fig5, width = 12, height = 5, dpi = 300)

# Figure 2 — KM all-cause + respiratory side by side
sf_all  <- survfit(Surv(days_followed/365.25, vital_status) ~ stratum, data = mort_in %>% filter(!is.na(stratum)))
sf_resp <- survfit(Surv(days_followed/365.25, event_resp)   ~ stratum, data = mort_in %>% filter(!is.na(stratum)))
km_df <- function(sf, outcome) {
  data.frame(time = sf$time, surv = sf$surv,
             strata = rep(names(sf$strata), sf$strata),
             outcome = outcome) %>%
    mutate(baseline_stratum = factor(sub(".*=", "", strata), levels = stratum_levels))
}
km2 <- bind_rows(km_df(sf_all, "All-cause"), km_df(sf_resp, "Respiratory"))
km2$outcome <- factor(km2$outcome, levels = c("All-cause","Respiratory"))

fig2 <- ggplot(km2, aes(x = time, y = surv, color = baseline_stratum)) +
  geom_step(linewidth = 0.7) +
  facet_wrap(~ outcome, ncol = 2) +
  scale_color_manual(values = stratum_pal, name = "Baseline\nstratum") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_x_continuous(breaks = seq(0, 15, 2.5)) +
  labs(x = "Years from baseline", y = "Survival probability",
       title = "Kaplan–Meier survival by baseline spectrum stratum")
ggsave(file.path(OUT_DIR, "Figure_2.png"), fig2, width = 12, height = 5, dpi = 300)

cat("\nAssets written to:", OUT_DIR, "\n")
list.files(OUT_DIR)
