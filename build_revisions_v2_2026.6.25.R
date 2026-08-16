#!/usr/bin/env Rscript
# Round-2 revisions to §3.5 of the outline (2026-06-25).
#  C1 — Transparent threshold selection table
#  C2 — Sensitivity variant: ESI replaces ONLY emphysema (wall thickening dropped)
#  C3 — Sankey-style reclassification visualization
#  C4 — Discordant-subject characterization (FP, FN, Both)
#  C5 — Bhatt categories tested against FEV1 decline (mortality already done)
#  C6 — Both-caught vs Bhatt-only characterization

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(scales)
  library(survival); library(lme4); library(lmerTest); library(patchwork)
})

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

# Load data --------------------------------------------------------------------
esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv",
                stringsAsFactors = FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv",
                stringsAsFactors = FALSE, na.strings = c("","NA"))
phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)

vs  <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE); vs$rand_id <- as.character(vs$rand_id)
cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE); cod$rand_id <- as.character(cod$rand_id.x)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels))

# Bhatt cohort with complete criteria ------------------------------------------
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

# Bhatt classification
n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                  ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                  ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD",
                                                                "noCOPD")))
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major","COPD-minor")

# =====================================================================
# C1 — Threshold selection sensitivity (transparency table)
# =====================================================================
classify_4crit <- function(df, T, min_count) {
  esi <- df$ESI_v1post >= T
  n_minor <- esi + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_minor >= 1, "COPD-major",
   ifelse(!df$major_criterion & n_minor >= min_count, "COPD-minor",
   ifelse(df$major_criterion & n_minor == 0, "AFL-only-NoCOPD", "noCOPD")))
}
classify_5crit_dc <- function(df, T_low, T_high) {
  esi_s <- ifelse(df$ESI_v1post >= T_high, 2,
            ifelse(df$ESI_v1post >= T_low, 1, 0))
  n_minor <- esi_s + df$dysp_yn + df$qol_yn + df$cb_yn
  ifelse(df$major_criterion & n_minor >= 1, "COPD-major",
   ifelse(!df$major_criterion & n_minor >= 3, "COPD-minor",
   ifelse(df$major_criterion & n_minor == 0, "AFL-only-NoCOPD", "noCOPD")))
}

kappa_fn <- function(a, b) {
  tab <- table(a, b); po <- sum(diag(tab))/sum(tab)
  pe <- sum(rowSums(tab)*colSums(tab))/sum(tab)^2
  (po - pe)/(1 - pe)
}

# Grid of candidates explored
candidates <- list(
  list(type="4-crit, ESI cutoff 1.0, threshold ≥2-of-4", fn=function(x) classify_4crit(x, 1.0, 2)),
  list(type="4-crit, ESI cutoff 1.5, threshold ≥2-of-4", fn=function(x) classify_4crit(x, 1.5, 2)),
  list(type="4-crit, ESI cutoff 2.0, threshold ≥2-of-4", fn=function(x) classify_4crit(x, 2.0, 2)),
  list(type="4-crit, ESI cutoff 2.5, threshold ≥2-of-4", fn=function(x) classify_4crit(x, 2.5, 2)),
  list(type="4-crit, ESI cutoff 1.5, threshold ≥3-of-4", fn=function(x) classify_4crit(x, 1.5, 3)),
  list(type="4-crit, ESI cutoff 2.0, threshold ≥3-of-4", fn=function(x) classify_4crit(x, 2.0, 3)),
  list(type="5-crit, T_low=0.5 / T_high=2.0",              fn=function(x) classify_5crit_dc(x, 0.5, 2.0)),
  list(type="5-crit, T_low=1.0 / T_high=2.5 [SELECTED]",   fn=function(x) classify_5crit_dc(x, 1.0, 2.5)),
  list(type="5-crit, T_low=1.5 / T_high=3.0",              fn=function(x) classify_5crit_dc(x, 1.5, 3.0)),
  list(type="5-crit, T_low=2.0 / T_high=3.5",              fn=function(x) classify_5crit_dc(x, 2.0, 3.5))
)

sens_rows <- list()
for (c in candidates) {
  cls  <- c$fn(d_b)
  copd <- cls %in% c("COPD-major","COPD-minor")
  tp <- sum(d_b$bhatt_copd &  copd); fp <- sum(!d_b$bhatt_copd & copd)
  fn <- sum(d_b$bhatt_copd & !copd); tn <- sum(!d_b$bhatt_copd & !copd)
  sens <- tp/(tp+fn); spec <- tn/(tn+fp); k <- kappa_fn(d_b$bhatt_copd, copd)
  sens_rows[[length(sens_rows)+1]] <- data.frame(
    variant = c$type, n_COPD = sum(copd),
    sens = sens, spec = spec, kappa = k
  )
}
supp_thresh <- do.call(rbind, sens_rows)
write.csv(supp_thresh, file.path(OUT_DIR, "Supp_Table_Thresholds.csv"), row.names = FALSE)

# =====================================================================
# C2 — Sensitivity variant: ESI replaces ONLY emphysema (4-criterion)
# Best 4-criterion variant: ESI ≥ 1.5, ≥2-of-4 (best κ of the 4-crit family)
# =====================================================================
# Selected best 4-criterion variant
d_b$esi_cls_5     <- classify_5crit_dc(d_b, 1.0, 2.5)      # main (selected)
d_b$esi_cls_4     <- classify_4crit(d_b, 1.5, 2)            # alternative
d_b$esi_copd_5    <- d_b$esi_cls_5 %in% c("COPD-major","COPD-minor")
d_b$esi_copd_4    <- d_b$esi_cls_4 %in% c("COPD-major","COPD-minor")

# =====================================================================
# C4 + C6 — Characterize discordant and concordant subjects
# Subset: preserved-spirometry subjects (the only zone where Bhatt picks
# up additional cases via CT+symptoms)
# =====================================================================
preserved <- d_b %>% filter(!major_criterion)

categorize <- function(b, e) {
  case_when(
    b  &  e ~ "Both-COPD",
    b  & !e ~ "Bhatt-only-COPD (ESI missed)",
    !b &  e ~ "ESI-only-COPD (Bhatt missed)",
    !b & !e ~ "Both-noCOPD"
  )
}
preserved$grp_5 <- categorize(preserved$bhatt_copd, preserved$esi_copd_5)

# Discordance table — preserved spirometry, using main (5-criterion) variant
disc_summary <- preserved %>%
  filter(grp_5 != "Both-noCOPD") %>%
  group_by(grp_5) %>%
  summarise(
    n           = n(),
    age         = sprintf("%.1f (%.1f)", mean(age_visit, na.rm=TRUE), sd(age_visit, na.rm=TRUE)),
    pct_F       = sprintf("%.0f%%", 100*mean(gender == 2, na.rm=TRUE)),
    BMI         = sprintf("%.1f (%.1f)", mean(BMI, na.rm=TRUE), sd(BMI, na.rm=TRUE)),
    pack_yr     = sprintf("%.0f (%.0f)", mean(ATS_PackYears, na.rm=TRUE), sd(ATS_PackYears, na.rm=TRUE)),
    ESI         = sprintf("%.2f (%.2f)", mean(ESI_v1post, na.rm=TRUE), sd(ESI_v1post, na.rm=TRUE)),
    FEV1_pp     = sprintf("%.0f (%.0f)", mean(FEV1pp_post, na.rm=TRUE), sd(FEV1pp_post, na.rm=TRUE)),
    FEV1_FVC    = sprintf("%.2f (%.2f)", mean(FEV1_FVC_post, na.rm=TRUE), sd(FEV1_FVC_post, na.rm=TRUE)),
    LAA950      = sprintf("%.1f (%.1f)", mean(Insp_LAA950_total_Thirona, na.rm=TRUE),
                                          sd(Insp_LAA950_total_Thirona, na.rm=TRUE)),
    pct_emph    = sprintf("%.0f%%", 100*mean(emph_yn, na.rm=TRUE)),
    pct_wall    = sprintf("%.0f%%", 100*mean(wall_yn, na.rm=TRUE)),
    pct_mMRC2p  = sprintf("%.0f%%", 100*mean(dysp_yn, na.rm=TRUE)),
    pct_SGRQ25p = sprintf("%.0f%%", 100*mean(qol_yn, na.rm=TRUE)),
    pct_CB      = sprintf("%.0f%%", 100*mean(cb_yn, na.rm=TRUE)),
    .groups = "drop"
  )
write.csv(disc_summary, file.path(OUT_DIR, "Table_Discordance.csv"), row.names = FALSE)

# =====================================================================
# C5 — Bhatt categories tested against FEV1 decline (all-cause + resp
# mortality already in Tables 8 and Figure 5)
# =====================================================================
fev1_long <- phe %>%
  filter(visitnum %in% c(1, 2, 3), !is.na(FEV1_post), !is.na(years_from_baseline)) %>%
  transmute(rand_id, visitnum, years_from_baseline,
            FEV1_post_mL = FEV1_post * 1000,
            age_visit    = as.numeric(age_visit),
            ATS_PackYears = as.numeric(ATS_PackYears),
            SmokCigNow   = factor(SmokCigNow))

base_b <- d_b %>% transmute(
  rand_id,
  bhatt_grp = factor(bhatt_cls, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
  esi_grp_5 = factor(esi_cls_5, levels = c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")),
  Height_CM = as.numeric(Height_CM),
  gender_baseline = factor(gender), race_baseline = factor(race)
)

decline_b <- fev1_long %>% inner_join(base_b, by = "rand_id") %>%
  filter(!is.na(Height_CM), !is.na(age_visit), !is.na(SmokCigNow))

lmm_bhatt <- lmer(FEV1_post_mL ~ years_from_baseline * bhatt_grp +
                    Height_CM + gender_baseline + race_baseline +
                    age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id),
                  data = decline_b)
lmm_esi   <- lmer(FEV1_post_mL ~ years_from_baseline * esi_grp_5 +
                    Height_CM + gender_baseline + race_baseline +
                    age_visit + SmokCigNow + ATS_PackYears + (1 | rand_id),
                  data = decline_b)

get_int <- function(fit, term) {
  co <- summary(fit)$coef
  if (!term %in% rownames(co)) return(c(est=NA, se=NA, p=NA))
  c(est = co[term,"Estimate"], se = co[term,"Std. Error"], p = co[term,"Pr(>|t|)"])
}

groups <- c("AFL-only-NoCOPD","COPD-minor","COPD-major")
t_decline <- data.frame(group = groups,
                        bhatt_est=NA_real_, bhatt_se=NA_real_, bhatt_p=NA_real_,
                        esi_est=NA_real_,   esi_se=NA_real_,   esi_p=NA_real_)
for (i in seq_along(groups)) {
  b <- get_int(lmm_bhatt, paste0("years_from_baseline:bhatt_grp", groups[i]))
  e <- get_int(lmm_esi,   paste0("years_from_baseline:esi_grp_5", groups[i]))
  t_decline$bhatt_est[i] <- b["est"]; t_decline$bhatt_se[i] <- b["se"]; t_decline$bhatt_p[i] <- b["p"]
  t_decline$esi_est[i]   <- e["est"]; t_decline$esi_se[i]   <- e["se"]; t_decline$esi_p[i]   <- e["p"]
}
write.csv(t_decline, file.path(OUT_DIR, "Table_BhattDecline.csv"), row.names = FALSE)

# Outcome comparison: Bhatt-only vs Both-COPD vs ESI-only — mortality
mort_compare <- d_b %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, CCOD_COPD_resp), by = "rand_id") %>%
  mutate(
    event_resp = ifelse(vital_status == 1 & !is.na(CCOD_COPD_resp) & CCOD_COPD_resp == 1, 1, 0),
    gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
    grp_5 = categorize(bhatt_copd, esi_copd_5)
  ) %>%
  filter(!major_criterion,    # preserved spirometry only
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

mort_compare$grp_5 <- factor(mort_compare$grp_5,
                             levels = c("Both-noCOPD","Both-COPD",
                                        "Bhatt-only-COPD (ESI missed)",
                                        "ESI-only-COPD (Bhatt missed)"))

cox_grp_all  <- coxph(Surv(days_followed/365.25, vital_status) ~ grp_5 + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_compare)
cox_grp_resp <- coxph(Surv(days_followed/365.25, event_resp)   ~ grp_5 + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI, data = mort_compare)

get_hr <- function(fit, term) {
  s <- summary(fit)
  if (!term %in% rownames(s$conf.int)) return(c(HR=NA,LCI=NA,UCI=NA,p=NA))
  c(HR=s$conf.int[term,"exp(coef)"], LCI=s$conf.int[term,"lower .95"],
    UCI=s$conf.int[term,"upper .95"], p=s$coef[term,"Pr(>|z|)"])
}

t_grp_mort <- data.frame(
  group = c("Both-COPD", "Bhatt-only-COPD (ESI missed)", "ESI-only-COPD (Bhatt missed)"),
  n          = c(sum(mort_compare$grp_5 == "Both-COPD"),
                 sum(mort_compare$grp_5 == "Bhatt-only-COPD (ESI missed)"),
                 sum(mort_compare$grp_5 == "ESI-only-COPD (Bhatt missed)")),
  n_deaths_all = c(sum(mort_compare$grp_5 == "Both-COPD" & mort_compare$vital_status == 1),
                   sum(mort_compare$grp_5 == "Bhatt-only-COPD (ESI missed)" & mort_compare$vital_status == 1),
                   sum(mort_compare$grp_5 == "ESI-only-COPD (Bhatt missed)" & mort_compare$vital_status == 1))
)
for (g in t_grp_mort$group) {
  hra <- get_hr(cox_grp_all,  paste0("grp_5", g))
  hrr <- get_hr(cox_grp_resp, paste0("grp_5", g))
  i <- match(g, t_grp_mort$group)
  t_grp_mort$all_HR[i]  <- hra["HR"]; t_grp_mort$all_LCI[i] <- hra["LCI"]; t_grp_mort$all_UCI[i] <- hra["UCI"]; t_grp_mort$all_p[i] <- hra["p"]
  t_grp_mort$resp_HR[i] <- hrr["HR"]; t_grp_mort$resp_LCI[i] <- hrr["LCI"]; t_grp_mort$resp_UCI[i] <- hrr["UCI"]; t_grp_mort$resp_p[i] <- hrr["p"]
}
write.csv(t_grp_mort, file.path(OUT_DIR, "Table_BhattOnly_vs_Both.csv"), row.names = FALSE)

# =====================================================================
# C3 — Visualization of Table 6 reclassification as a flow plot
# (Sankey-style without requiring an extra package — use ggalluvial if
# installed, else fall back to grouped bars)
# =====================================================================
ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
flow <- d_b %>% count(bhatt = factor(bhatt_cls, levels = ord),
                      esi   = factor(esi_cls_5, levels = ord))

# Stacked-bar fallback (works without ggalluvial)
flow_long <- bind_rows(
  d_b %>% transmute(schema = "Bhatt (full)",   cls = factor(bhatt_cls, levels = ord)),
  d_b %>% transmute(schema = "ESI-substituted (no CT)", cls = factor(esi_cls_5, levels = ord))
)
fig_bars <- ggplot(flow_long, aes(x = schema, fill = cls)) +
  geom_bar(position = position_stack(reverse = TRUE), width = 0.55, color = "white") +
  geom_text(stat = "count",
            aes(label = sprintf("%s\n(%.1f%%)", after_stat(count),
                                100*after_stat(count)/sum(after_stat(count)))),
            position = position_stack(vjust = 0.5, reverse = TRUE),
            size = 3, color = "white") +
  scale_fill_manual(values = c(
    "noCOPD"          = "#7F7F7F",
    "AFL-only-NoCOPD" = "#9467BD",
    "COPD-minor"      = "#FFB000",
    "COPD-major"      = "#D62728"
  ), name = "Classification") +
  labs(x = NULL, y = "Number of subjects",
       title = "Bhatt 2025 vs ESI-substituted classification") +
  theme_bw(base_family = "Arial", base_size = 10) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "right")
ggsave(file.path(OUT_DIR, "Figure_Bhatt_StackedBars.png"), fig_bars,
       width = 8, height = 5, dpi = 300)

# Try ggalluvial for true reclassification flow if package installed
have_alluvial <- requireNamespace("ggalluvial", quietly = TRUE)
if (have_alluvial) {
  library(ggalluvial)
  fig_alluv <- ggplot(flow,
                      aes(axis1 = bhatt, axis2 = esi, y = n)) +
    geom_alluvium(aes(fill = bhatt), width = 0.3, alpha = 0.8) +
    geom_stratum(width = 0.3, fill = "grey95", color = "grey30") +
    geom_text(stat = "stratum", aes(label = paste0(after_stat(stratum),
                                                   "\n(", after_stat(count), ")")),
              size = 3) +
    scale_x_discrete(limits = c("Bhatt (with CT)","ESI-substituted (no CT)"),
                     expand = c(0.1, 0.05)) +
    scale_fill_manual(values = c(
      "noCOPD"          = "#7F7F7F",
      "AFL-only-NoCOPD" = "#9467BD",
      "COPD-minor"      = "#FFB000",
      "COPD-major"      = "#D62728"
    ), guide = "none") +
    labs(y = "Number of subjects",
         title = "Reclassification flow: Bhatt 2025 → ESI-substituted classification") +
    theme_bw(base_family = "Arial", base_size = 10) +
    theme(panel.grid = element_blank())
  ggsave(file.path(OUT_DIR, "Figure_Bhatt_Sankey.png"), fig_alluv,
         width = 9, height = 5.5, dpi = 300)
}

cat("\nAssets written. New files:\n")
print(c("Supp_Table_Thresholds.csv","Table_Discordance.csv",
        "Table_BhattDecline.csv","Table_BhattOnly_vs_Both.csv",
        "Figure_Bhatt_StackedBars.png",
        if (have_alluvial) "Figure_Bhatt_Sankey.png"))
