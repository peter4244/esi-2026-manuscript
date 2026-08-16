#!/usr/bin/env Rscript
# Generate 4 paper-quality figures + dump table data for the manuscript doc.
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(scales)
  library(survival); library(lme4); library(lmerTest); library(patchwork)
})

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
dir.create(OUT_DIR, showWarnings = FALSE)

# Paths
esi_path <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv"
phe_path <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv"
vs_path  <- "/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv"

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

# --- Load and merge -----------------------------------------------------------
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
  mutate(stratum = case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    stratum = factor(stratum, levels = stratum_levels))

vs <- read.csv(vs_path, stringsAsFactors = FALSE)
vs$rand_id <- as.character(vs$rand_id)
mort <- d %>% inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id")
mort$gender     <- factor(mort$gender)
mort$race       <- factor(mort$race)
mort$SmokCigNow <- factor(mort$SmokCigNow)

# --- Figure 1: spectrum overview ----------------------------------------------
d_f <- d %>% filter(!is.na(stratum))

pA <- ggplot(d_f, aes(x = stratum, y = ESI_v1post, fill = stratum)) +
  geom_boxplot(outlier.size = 0.3, outlier.alpha = 0.4, color = "grey30", width = 0.7) +
  scale_fill_manual(values = stratum_pal, guide = "none") +
  scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, 2)) +
  labs(x = NULL, y = "ESI (post-BD)", title = "A. ESI distribution by spectrum stratum")

pB <- ggplot(d_f, aes(x = FEV1_FVC_post, y = ESI_v1post, color = stratum)) +
  geom_point(alpha = 0.30, size = 0.35) +
  scale_color_manual(values = stratum_pal, name = "Stratum") +
  scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, 2)) +
  scale_x_continuous(limits = c(0.2, 1.0), breaks = seq(0.2, 1.0, 0.2)) +
  labs(x = "FEV1/FVC (post-BD)", y = "ESI",
       title = "B. ESI vs FEV1/FVC, colored by stratum") +
  guides(color = guide_legend(override.aes = list(alpha = 1, size = 2)))

cor_plot <- d_f %>% group_by(stratum) %>%
  summarise(r = cor(ESI_v1post, FEV1_FVC_post, use = "pairwise.complete.obs"), .groups = "drop")

pC <- ggplot(cor_plot, aes(x = stratum, y = r, fill = stratum)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%+.2f", r),
                vjust = ifelse(r < 0, 1.4, -0.4)), size = 3) +
  scale_fill_manual(values = stratum_pal, guide = "none") +
  scale_y_continuous(limits = c(-1, 0.05), breaks = seq(-1, 0, 0.25)) +
  labs(x = NULL, y = "Pearson r (ESI vs FEV1/FVC)",
       title = "C. Within-stratum ESI–FEV1/FVC correlation")

fig1 <- (pA | pB | pC) + plot_layout(widths = c(1, 1.2, 1))
ggsave(file.path(OUT_DIR, "Figure_1.png"), fig1, width = 13, height = 5.2, dpi = 300)

# --- Figure 2: KM survival ----------------------------------------------------
sf <- survfit(Surv(days_followed/365.25, vital_status) ~ stratum,
              data = mort %>% filter(!is.na(stratum)))
km_df <- data.frame(time = sf$time, surv = sf$surv,
                    strata = rep(names(sf$strata), sf$strata))
km_df$baseline_stratum <- factor(sub(".*=", "", km_df$strata), levels = stratum_levels)

fig2 <- ggplot(km_df, aes(x = time, y = surv, color = baseline_stratum)) +
  geom_step(linewidth = 0.7) +
  scale_color_manual(values = stratum_pal, name = "Baseline\nstratum") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_x_continuous(breaks = seq(0, 15, 2.5)) +
  labs(x = "Years from baseline", y = "Survival probability",
       title = "All-cause survival by baseline spectrum stratum")
ggsave(file.path(OUT_DIR, "Figure_2.png"), fig2, width = 8.5, height = 5.5, dpi = 300)

# --- Figure 3: FEV1 by ESI tertile within stratum -----------------------------
fev1_long <- phe_all %>%
  filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit    = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow   = factor(SmokCigNow))
v1_baseline <- d %>% transmute(rand_id, ESI_baseline = ESI_v1post,
                               FEV1_FVC_baseline = FEV1_FVC_post,
                               stratum_baseline = stratum) %>%
  left_join(
    phe_all %>% filter(visitnum == 1) %>%
      transmute(rand_id, Height_CM = as.numeric(Height_CM),
                gender_baseline = factor(gender),
                race_baseline   = factor(race)),
    by = "rand_id"
  )
decline_d <- fev1_long %>% inner_join(v1_baseline, by = "rand_id") %>%
  filter(!is.na(ESI_baseline), !is.na(FEV1_FVC_baseline),
         !is.na(stratum_baseline), !is.na(Height_CM),
         !is.na(age_visit), !is.na(SmokCigNow))

# Per-stratum coefficients (estimate + 95% CI) for the forest plot.
# Same model spec as Table 5b — mutually adjusted ESI and FEV1/FVC interactions
# with time, plus the standard covariate block.
forest_strata <- c("GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
get_int_ci <- function(fit, term) {
  co <- summary(fit)$coef
  if (!term %in% rownames(co)) return(c(est=NA, lci=NA, uci=NA, p=NA))
  e <- co[term,"Estimate"]; s <- co[term,"Std. Error"]
  c(est = e, lci = e - 1.96*s, uci = e + 1.96*s, p = co[term,"Pr(>|t|)"])
}

forest_rows <- do.call(rbind, lapply(forest_strata, function(s) {
  df <- decline_d %>% filter(stratum_baseline == s)
  n_subj <- length(unique(df$rand_id))
  if (n_subj < 50) return(NULL)
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
    data.frame(stratum=s, n_subj=n_subj, predictor="ESI",
               est=e["est"], lci=e["lci"], uci=e["uci"], p=e["p"]),
    data.frame(stratum=s, n_subj=n_subj, predictor="FEV1/FVC",
               est=f["est"], lci=f["lci"], uci=f["uci"], p=f["p"])
  )
}))
forest_rows$stratum   <- factor(forest_rows$stratum, levels = rev(forest_strata))
forest_rows$predictor <- factor(forest_rows$predictor, levels = c("ESI","FEV1/FVC"))

# Panel A: forest plot (two facets — ESI on left, FEV1/FVC on right)
panelA <- ggplot(forest_rows, aes(x = est, y = stratum, color = stratum)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = lci, xmax = uci), height = 0.25, linewidth = 0.6) +
  geom_point(size = 2.5) +
  facet_wrap(~ predictor, scales = "free_x", ncol = 2) +
  scale_color_manual(values = stratum_pal, guide = "none") +
  labs(x = "Coefficient (mL/yr per 1-unit higher baseline predictor)",
       y = NULL,
       title = "A. Per-stratum × time interaction coefficients (95% CI)")

# Panel B: GOLD 0 trajectory only — clean LOESS by tertile
tert_g0 <- quantile(decline_d$ESI_baseline[decline_d$stratum_baseline == "GOLD0"],
                    c(1/3, 2/3), na.rm = TRUE)
tert_labels <- c("Low", "Mid", "High")
g0 <- decline_d %>% filter(stratum_baseline == "GOLD0") %>%
  mutate(ESI_tertile = cut(ESI_baseline,
                           breaks = c(-Inf, tert_g0[1], tert_g0[2], Inf),
                           labels = tert_labels))

tert_pal <- setNames(c("#1F77B4","#FFB000","#D62728"), tert_labels)

panelB <- ggplot(g0, aes(x = years_from_baseline, y = FEV1_post_mL,
                         color = ESI_tertile, fill = ESI_tertile)) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 0.9, alpha = 0.15,
              span = 1, formula = y ~ x) +
  scale_color_manual(values = tert_pal, name = "Baseline ESI tertile") +
  scale_fill_manual(values = tert_pal, guide = "none") +
  scale_x_continuous(limits = c(0, 11), breaks = seq(0, 10, 2)) +
  labs(x = "Years from baseline", y = "FEV1 (mL), post-BD",
       title = "B. GOLD 0 (smokers without obstruction)") +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 9),
        legend.text  = element_text(size = 9))

fig3 <- panelA + panelB + plot_layout(widths = c(1.4, 1))
ggsave(file.path(OUT_DIR, "Figure_3.png"), fig3, width = 12, height = 5, dpi = 300)

# --- Figure 4: ESI trajectory by baseline stratum -----------------------------
esi_long_post <- esi_raw %>% filter(PrePost == 1) %>%
  group_by(rand_id, visitnum) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
baseline_stratum <- d %>% select(rand_id, baseline_stratum = stratum)
long <- esi_long_post %>% inner_join(baseline_stratum, by = "rand_id")
traj_summary <- long %>%
  filter(!is.na(baseline_stratum), !is.na(ESI)) %>%
  group_by(baseline_stratum, visitnum) %>%
  summarise(n = n(), mean_ESI = mean(ESI), se_ESI = sd(ESI)/sqrt(n()), .groups = "drop")

fig4 <- ggplot(traj_summary,
       aes(x = factor(visitnum), y = mean_ESI,
           color = baseline_stratum, group = baseline_stratum)) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  geom_errorbar(aes(ymin = mean_ESI - 1.96*se_ESI,
                    ymax = mean_ESI + 1.96*se_ESI), width = 0.1) +
  scale_color_manual(values = stratum_pal, name = "Baseline\nstratum") +
  labs(x = "Visit (V1 = baseline, V2 ≈ 5 y, V3 ≈ 10 y)",
       y = "Mean ESI (post-BD)",
       title = "ESI trajectory by baseline spectrum stratum")
ggsave(file.path(OUT_DIR, "Figure_4.png"), fig4, width = 9, height = 5, dpi = 300)

# --- Dump table data ----------------------------------------------------------
# Table 1: cohort characteristics by stratum
t1 <- d %>% filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(
    n        = n(),
    age      = sprintf("%.1f (%.1f)", mean(age_visit, na.rm=TRUE), sd(age_visit, na.rm=TRUE)),
    bmi      = sprintf("%.1f (%.1f)", mean(BMI, na.rm=TRUE),       sd(BMI, na.rm=TRUE)),
    pack_yr  = sprintf("%.1f (%.1f)", mean(ATS_PackYears, na.rm=TRUE), sd(ATS_PackYears, na.rm=TRUE)),
    fev1pp   = sprintf("%.1f (%.1f)", mean(FEV1pp_post, na.rm=TRUE), sd(FEV1pp_post, na.rm=TRUE)),
    ff       = sprintf("%.2f (%.2f)", mean(FEV1_FVC_post, na.rm=TRUE), sd(FEV1_FVC_post, na.rm=TRUE)),
    esi      = sprintf("%.2f (%.2f)", mean(ESI_v1post, na.rm=TRUE), sd(ESI_v1post, na.rm=TRUE)),
    .groups = "drop"
  )
write.csv(t1, file.path(OUT_DIR, "Table_1.csv"), row.names = FALSE)

# Table 2: per-stratum correlations
t2 <- d %>% filter(!is.na(stratum)) %>%
  group_by(stratum) %>%
  summarise(
    n_FF       = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
    r_FF       = cor(ESI_v1post, FEV1_FVC_post,              use="pairwise.complete.obs"),
    n_LAA      = sum(complete.cases(ESI_v1post, Insp_LAA950_total_Thirona)),
    r_LAA      = cor(ESI_v1post, Insp_LAA950_total_Thirona,  use="pairwise.complete.obs"),
    .groups = "drop"
  )
overall <- d %>% summarise(
  stratum = "All strata",
  n_FF    = sum(complete.cases(ESI_v1post, FEV1_FVC_post)),
  r_FF    = cor(ESI_v1post, FEV1_FVC_post,              use="pairwise.complete.obs"),
  n_LAA   = sum(complete.cases(ESI_v1post, Insp_LAA950_total_Thirona)),
  r_LAA   = cor(ESI_v1post, Insp_LAA950_total_Thirona,  use="pairwise.complete.obs"))
t2 <- bind_rows(t2 %>% mutate(stratum = as.character(stratum)), overall)
write.csv(t2, file.path(OUT_DIR, "Table_2.csv"), row.names = FALSE)

# Cox models for Tables 3 and 4
cox_input <- mort %>% filter(!is.na(stratum), !is.na(FEV1_FVC_post),
                             !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
cox_input$stratum <- relevel(cox_input$stratum, ref = "GOLD0")

m_no  <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post                 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_ff  <- coxph(Surv(days_followed/365.25, vital_status) ~                FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_bo  <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post +   FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input)
m_se  <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post +   FEV1_FVC_post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = cox_input %>% filter(ESI_v1post < 9.999))
lr_cox <- anova(m_ff, m_bo)

cox_row <- function(fit, var) {
  s <- summary(fit)
  if (!var %in% rownames(s$coef)) return(c(HR=NA, LCI=NA, UCI=NA, p=NA))
  c(HR  = s$conf.int[var,"exp(coef)"],
    LCI = s$conf.int[var,"lower .95"],
    UCI = s$conf.int[var,"upper .95"],
    p   = s$coef[var,"Pr(>|z|)"])
}
get <- function(fit, var) {
  v <- cox_row(fit, var)
  list(HR=v["HR"], LCI=v["LCI"], UCI=v["UCI"], p=v["p"])
}

t3 <- data.frame(
  model = c("ESI only", "FEV1/FVC only", "ESI + FEV1/FVC", "ESI + FEV1/FVC (ESI<10 sensitivity)"),
  esi_HR  = c(get(m_no,"ESI_v1post")$HR, NA, get(m_bo,"ESI_v1post")$HR, get(m_se,"ESI_v1post")$HR),
  esi_LCI = c(get(m_no,"ESI_v1post")$LCI, NA, get(m_bo,"ESI_v1post")$LCI, get(m_se,"ESI_v1post")$LCI),
  esi_UCI = c(get(m_no,"ESI_v1post")$UCI, NA, get(m_bo,"ESI_v1post")$UCI, get(m_se,"ESI_v1post")$UCI),
  esi_p   = c(get(m_no,"ESI_v1post")$p, NA, get(m_bo,"ESI_v1post")$p, get(m_se,"ESI_v1post")$p),
  ff_HR   = c(NA, get(m_ff,"FEV1_FVC_post")$HR,  get(m_bo,"FEV1_FVC_post")$HR,  get(m_se,"FEV1_FVC_post")$HR),
  ff_LCI  = c(NA, get(m_ff,"FEV1_FVC_post")$LCI, get(m_bo,"FEV1_FVC_post")$LCI, get(m_se,"FEV1_FVC_post")$LCI),
  ff_UCI  = c(NA, get(m_ff,"FEV1_FVC_post")$UCI, get(m_bo,"FEV1_FVC_post")$UCI, get(m_se,"FEV1_FVC_post")$UCI),
  ff_p    = c(NA, get(m_ff,"FEV1_FVC_post")$p,  get(m_bo,"FEV1_FVC_post")$p,  get(m_se,"FEV1_FVC_post")$p)
)
write.csv(t3, file.path(OUT_DIR, "Table_3.csv"), row.names = FALSE)
writeLines(c(sprintf("LR_chisq=%.2f", lr_cox$Chisq[2]),
             sprintf("LR_p=%.3e",     lr_cox$`Pr(>|Chi|)`[2]),
             sprintf("cox_n=%d", nrow(cox_input)),
             sprintf("cox_deaths=%d", sum(cox_input$vital_status == 1))),
           file.path(OUT_DIR, "Table_3_stats.txt"))

# Table 4: per-stratum Cox HR for ESI
strata_to_test <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
t4 <- do.call(rbind, lapply(strata_to_test, function(s) {
  df <- cox_input %>% filter(stratum == s)
  if (sum(df$vital_status == 1) < 10 || nrow(df) < 50) {
    return(data.frame(stratum=s, n=nrow(df), deaths=sum(df$vital_status==1),
                      HR=NA, LCI=NA, UCI=NA, p=NA))
  }
  fit <- coxph(Surv(days_followed/365.25, vital_status) ~ ESI_v1post + FEV1_FVC_post +
                 age_visit + gender + race + SmokCigNow + ATS_PackYears, data = df)
  v <- cox_row(fit, "ESI_v1post")
  data.frame(stratum=s, n=nrow(df), deaths=sum(df$vital_status==1),
             HR=v["HR"], LCI=v["LCI"], UCI=v["UCI"], p=v["p"])
}))
write.csv(t4, file.path(OUT_DIR, "Table_4.csv"), row.names = FALSE)

# Table 5a / 5b: FEV1 decline head-to-head
cov_block <- "+ stratum_baseline + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id)"
m_base <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline + ESI_baseline + FEV1_FVC_baseline", cov_block)), data = decline_d)
m_ESI  <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * ESI_baseline + FEV1_FVC_baseline", cov_block)), data = decline_d)
m_FF   <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * FEV1_FVC_baseline + ESI_baseline", cov_block)), data = decline_d)
m_BOT  <- lmer(as.formula(paste("FEV1_post_mL ~ years_from_baseline * (ESI_baseline + FEV1_FVC_baseline)", cov_block)), data = decline_d)
lr_addESI <- anova(m_FF, m_BOT)
lr_addFF  <- anova(m_ESI, m_BOT)

get_int <- function(fit, term) {
  co <- summary(fit)$coef
  if (!term %in% rownames(co)) return(c(est=NA, se=NA, p=NA))
  c(est = co[term,"Estimate"], se = co[term,"Std. Error"], p = co[term,"Pr(>|t|)"])
}

t5a <- data.frame(
  model = c("years × ESI only", "years × FEV1/FVC only", "years × both"),
  esi_est = c(get_int(m_ESI,"years_from_baseline:ESI_baseline")["est"], NA,
              get_int(m_BOT,"years_from_baseline:ESI_baseline")["est"]),
  esi_se  = c(get_int(m_ESI,"years_from_baseline:ESI_baseline")["se"], NA,
              get_int(m_BOT,"years_from_baseline:ESI_baseline")["se"]),
  esi_p   = c(get_int(m_ESI,"years_from_baseline:ESI_baseline")["p"], NA,
              get_int(m_BOT,"years_from_baseline:ESI_baseline")["p"]),
  ff_est  = c(NA, get_int(m_FF,"years_from_baseline:FEV1_FVC_baseline")["est"],
              get_int(m_BOT,"years_from_baseline:FEV1_FVC_baseline")["est"]),
  ff_se   = c(NA, get_int(m_FF,"years_from_baseline:FEV1_FVC_baseline")["se"],
              get_int(m_BOT,"years_from_baseline:FEV1_FVC_baseline")["se"]),
  ff_p    = c(NA, get_int(m_FF,"years_from_baseline:FEV1_FVC_baseline")["p"],
              get_int(m_BOT,"years_from_baseline:FEV1_FVC_baseline")["p"])
)
write.csv(t5a, file.path(OUT_DIR, "Table_5a.csv"), row.names = FALSE)
writeLines(c(sprintf("LR_addESI_chisq=%.2f", lr_addESI$Chisq[2]),
             sprintf("LR_addESI_p=%.3e",     lr_addESI$`Pr(>Chisq)`[2]),
             sprintf("LR_addFF_chisq=%.2f",  lr_addFF$Chisq[2]),
             sprintf("LR_addFF_p=%.3e",      lr_addFF$`Pr(>Chisq)`[2]),
             sprintf("lmm_rows=%d",          nrow(decline_d)),
             sprintf("lmm_subj=%d",          length(unique(decline_d$rand_id)))),
           file.path(OUT_DIR, "Table_5a_stats.txt"))

# Table 5b: per-stratum LMM
t5b_rows <- list()
for (s in stratum_levels) {
  df <- decline_d %>% filter(stratum_baseline == s)
  n_subj <- length(unique(df$rand_id))
  if (n_subj < 50) {
    t5b_rows[[s]] <- data.frame(stratum=s, n_subj=n_subj,
                                esi_est=NA, esi_p=NA, ff_est=NA, ff_p=NA)
    next
  }
  safe_covs <- c()
  if (length(unique(df$SmokCigNow))      > 1) safe_covs <- c(safe_covs, "SmokCigNow")
  if (length(unique(df$gender_baseline)) > 1) safe_covs <- c(safe_covs, "gender_baseline")
  if (length(unique(df$race_baseline))   > 1) safe_covs <- c(safe_covs, "race_baseline")
  rhs <- paste("years_from_baseline*(ESI_baseline + FEV1_FVC_baseline)",
               "+ Height_CM + age_visit + ATS_PackYears",
               if (length(safe_covs)) paste("+", paste(safe_covs, collapse=" + ")) else "",
               "+ (1 | rand_id)")
  fit <- try(lmer(as.formula(paste("FEV1_post_mL ~", rhs)), data = df), silent = TRUE)
  if (inherits(fit, "try-error")) {
    t5b_rows[[s]] <- data.frame(stratum=s, n_subj=n_subj,
                                esi_est=NA, esi_p=NA, ff_est=NA, ff_p=NA)
    next
  }
  co <- summary(fit)$coef
  e <- co["years_from_baseline:ESI_baseline", , drop = FALSE]
  f <- co["years_from_baseline:FEV1_FVC_baseline", , drop = FALSE]
  t5b_rows[[s]] <- data.frame(stratum=s, n_subj=n_subj,
                              esi_est=e[,"Estimate"], esi_p=e[,"Pr(>|t|)"],
                              ff_est=f[,"Estimate"], ff_p=f[,"Pr(>|t|)"])
}
t5b <- do.call(rbind, t5b_rows)
write.csv(t5b, file.path(OUT_DIR, "Table_5b.csv"), row.names = FALSE)

# ==============================================================================
# Section 3.5 / Bhatt 2025 substitution analysis assets
# ==============================================================================

# Add Bhatt-criteria columns to V1 cohort `d`
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

n_minor_b   <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                  ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                  ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD",
                                                                "noCOPD")))

esi_score   <- ifelse(d_b$ESI_v1post >= 2.5, 2, ifelse(d_b$ESI_v1post >= 1.0, 1, 0))
n_minor_e   <- esi_score + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
                ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
                ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD",
                                                              "noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major","COPD-minor")
d_b$esi_copd   <- d_b$esi_cls   %in% c("COPD-major","COPD-minor")

# Table 6: 4-way cross-tab
ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
t6_mat <- table(factor(d_b$bhatt_cls, levels = ord), factor(d_b$esi_cls, levels = ord))
t6 <- data.frame(Bhatt = ord,
                 noCOPD          = as.vector(t6_mat[,"noCOPD"]),
                 AFL_only_NoCOPD = as.vector(t6_mat[,"AFL-only-NoCOPD"]),
                 COPD_minor      = as.vector(t6_mat[,"COPD-minor"]),
                 COPD_major      = as.vector(t6_mat[,"COPD-major"]))
write.csv(t6, file.path(OUT_DIR, "Table_6.csv"), row.names = FALSE)

# Table 7: per-stratum preserved-spirometry agreement
preserved <- d_b %>% filter(!major_criterion, !is.na(stratum))
t7 <- preserved %>%
  filter(stratum %in% c("Never","GOLD0","PRISm")) %>%
  group_by(stratum) %>%
  summarise(
    n         = n(),
    bhatt_copd_n = sum(bhatt_copd),
    esi_copd_n   = sum(esi_copd),
    both         = sum(bhatt_copd & esi_copd),
    bhatt_only   = sum(bhatt_copd & !esi_copd),
    esi_only     = sum(!bhatt_copd & esi_copd),
    sens         = ifelse(sum(bhatt_copd) > 0, both/sum(bhatt_copd), NA),
    spec         = ifelse(sum(!bhatt_copd) > 0, sum(!bhatt_copd & !esi_copd)/sum(!bhatt_copd), NA),
    .groups = "drop"
  )
write.csv(t7, file.path(OUT_DIR, "Table_7.csv"), row.names = FALSE)

# Table 8: mortality HRs head-to-head
mort_b <- d_b %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  mutate(bhatt_grp = factor(bhatt_cls, levels = ord),
         esi_grp   = factor(esi_cls,   levels = ord),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

cox_b <- coxph(Surv(days_followed/365.25, vital_status) ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)
cox_e <- coxph(Surv(days_followed/365.25, vital_status) ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_b)

get_hr <- function(fit, term) {
  s <- summary(fit); c <- s$conf.int; co <- s$coef
  if (!term %in% rownames(c)) return(c(HR=NA, LCI=NA, UCI=NA, p=NA))
  c(HR = c[term,"exp(coef)"], LCI = c[term,"lower .95"],
    UCI = c[term,"upper .95"], p = co[term,"Pr(>|z|)"])
}

t8 <- data.frame(
  group = c("AFL-only-NoCOPD","COPD-minor","COPD-major"),
  bhatt_HR=NA_real_, bhatt_LCI=NA_real_, bhatt_UCI=NA_real_, bhatt_p=NA_real_,
  esi_HR=NA_real_,   esi_LCI=NA_real_,   esi_UCI=NA_real_,   esi_p=NA_real_
)
for (i in seq_along(t8$group)) {
  bh <- get_hr(cox_b, paste0("bhatt_grp", t8$group[i]))
  eh <- get_hr(cox_e, paste0("esi_grp",   t8$group[i]))
  t8$bhatt_HR[i] <- bh["HR"]; t8$bhatt_LCI[i] <- bh["LCI"]; t8$bhatt_UCI[i] <- bh["UCI"]; t8$bhatt_p[i] <- bh["p"]
  t8$esi_HR[i]   <- eh["HR"]; t8$esi_LCI[i]   <- eh["LCI"]; t8$esi_UCI[i]   <- eh["UCI"]; t8$esi_p[i]   <- eh["p"]
}
write.csv(t8, file.path(OUT_DIR, "Table_8.csv"), row.names = FALSE)

writeLines(c(sprintf("bhatt_cindex=%.3f", concordance(cox_b)$concordance),
             sprintf("esi_cindex=%.3f",   concordance(cox_e)$concordance),
             sprintf("n_cohort=%d",       nrow(d_b)),
             sprintf("n_mort=%d",         nrow(mort_b))),
           file.path(OUT_DIR, "Table_8_stats.txt"))

# Figure 5: forest plot of mortality HRs (Bhatt vs ESI-variant)
forest_df <- bind_rows(
  data.frame(Group = t8$group, schema = "Bhatt (with CT)",
             HR = t8$bhatt_HR, LCI = t8$bhatt_LCI, UCI = t8$bhatt_UCI),
  data.frame(Group = t8$group, schema = "ESI-substituted (no CT)",
             HR = t8$esi_HR,   LCI = t8$esi_LCI,   UCI = t8$esi_UCI)
)
forest_df$Group <- factor(forest_df$Group,
                          levels = rev(c("AFL-only-NoCOPD","COPD-minor","COPD-major")))

fig5 <- ggplot(forest_df, aes(x = HR, y = Group, color = schema)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = LCI, xmax = UCI),
                 position = position_dodge(width = 0.4),
                 height = 0.22, linewidth = 0.7) +
  geom_point(position = position_dodge(width = 0.4), size = 2.8) +
  scale_x_log10(breaks = c(0.5, 1, 1.5, 2, 3, 4),
                limits = c(0.4, 4.5)) +
  scale_color_manual(values = c("Bhatt (with CT)" = "#1F77B4",
                                "ESI-substituted (no CT)" = "#D62728"),
                     name = NULL) +
  labs(x = "Adjusted all-cause mortality HR (95% CI)", y = NULL,
       title = "Prognostic equivalence of the Bhatt and ESI-substituted classifications") +
  theme(legend.position = "bottom")
ggsave(file.path(OUT_DIR, "Figure_5.png"), fig5, width = 9, height = 4, dpi = 300)

cat("\nAssets written to:", OUT_DIR, "\n")
list.files(OUT_DIR)
