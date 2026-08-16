#!/usr/bin/env Rscript
# Cause-specific mortality Cox analyses: which causes does ESI add prognostic
# value for, beyond FEV1/FVC?
# Cause-specific Cox; non-target deaths censored at death date.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(survival); library(ggplot2)
})
OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv", stringsAsFactors=FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv", stringsAsFactors=FALSE, na.strings=c("","NA")); phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)
vs <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_VitalStatus_SM_NS_Sep23_randid.csv", stringsAsFactors=FALSE); vs$rand_id <- as.character(vs$rand_id)
cod <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_Mort_COD_Adj_randid.csv", stringsAsFactors=FALSE); cod$rand_id <- as.character(cod$rand_id.x)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
mort <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  inner_join(vs %>% select(rand_id, vital_status, days_followed), by = "rand_id") %>%
  left_join(cod %>% select(rand_id, starts_with("CCOD_")), by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels),
    gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
    FF_per_0_1 = FEV1_FVC_post / 0.1)
mort_in <- mort %>% filter(!is.na(stratum), !is.na(FEV1_FVC_post),
                           !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
mort_in$stratum <- relevel(mort_in$stratum, ref = "GOLD0")

# Helper to build event indicator: 1 if dead AND cause flag == 1; 0 otherwise
mk_event <- function(df, cause_col) {
  ifelse(df$vital_status == 1 & !is.na(df[[cause_col]]) & df[[cause_col]] == 1, 1, 0)
}

# Causes to analyze with at least 100 events
causes <- c("CCOD_CVD","CCOD_Cancer","CCOD_Other",                # broad categories
            "CCOD_OthCardiac","CCOD_MI",                          # within CVD
            "CCOD_LungCancer","CCOD_OthCancer",                   # within Cancer
            "CCOD_OthDis","CCOD_Accdnt_suicd","CCOD_Sepsis","CCOD_Renal")
labels <- c("CVD (all)","Cancer (all)","Other (all)",
            "Other cardiac","Myocardial infarction",
            "Lung cancer","Other cancer",
            "Other disease","Accident/suicide","Sepsis","Renal failure")

get_hr <- function(fit, var) {
  s <- summary(fit)
  if (!var %in% rownames(s$conf.int)) return(c(HR=NA, LCI=NA, UCI=NA, p=NA))
  c(HR  = s$conf.int[var,"exp(coef)"], LCI = s$conf.int[var,"lower .95"],
    UCI = s$conf.int[var,"upper .95"], p   = s$coef[var,"Pr(>|z|)"])
}

cs_rows <- list()
for (i in seq_along(causes)) {
  c <- causes[i]; lab <- labels[i]
  ev <- mk_event(mort_in, c)
  n_events <- sum(ev)
  S <- Surv(mort_in$days_followed/365.25, ev)
  m_esi <- coxph(S ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
  m_bo  <- coxph(S ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
  m_ff  <- coxph(S ~                FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum, data = mort_in)
  lr <- anova(m_ff, m_bo)
  ea <- get_hr(m_esi, "ESI_v1post")
  eb <- get_hr(m_bo,  "ESI_v1post")
  fb <- get_hr(m_bo,  "FF_per_0_1")
  cs_rows[[i]] <- data.frame(
    cause       = lab,
    n_events    = n_events,
    ESI_alone_HR = ea["HR"], ESI_alone_LCI = ea["LCI"], ESI_alone_UCI = ea["UCI"], ESI_alone_p = ea["p"],
    ESI_FF_HR    = eb["HR"], ESI_FF_LCI    = eb["LCI"], ESI_FF_UCI    = eb["UCI"], ESI_FF_p    = eb["p"],
    FF_HR        = fb["HR"], FF_LCI        = fb["LCI"], FF_UCI        = fb["UCI"], FF_p        = fb["p"],
    LR_chisq     = lr$Chisq[2],
    LR_p         = lr$`Pr(>|Chi|)`[2]
  )
}
cs_tab <- do.call(rbind, cs_rows)
write.csv(cs_tab, file.path(OUT_DIR, "Table_CauseSpecific.csv"), row.names = FALSE)

writeLines(c(sprintf("n_cohort=%d",       nrow(mort_in)),
             sprintf("n_all_cause_deaths=%d", sum(mort_in$vital_status == 1))),
           file.path(OUT_DIR, "Table_CauseSpecific_stats.txt"))

# Figure: forest plot of HR(ESI) after FF adjustment, by cause
# Order broad categories then subcategories within
ord_levels <- rev(labels)
cs_tab$cause <- factor(cs_tab$cause, levels = ord_levels)

# Color: blue for "ESI adds" (p<0.05 in ESI+FF model), red for "ESI does not add" (p>=0.05)
cs_tab$color <- ifelse(cs_tab$ESI_FF_p < 0.05, "ESI adds beyond FEV1/FVC", "ESI null beyond FEV1/FVC")

fig <- ggplot(cs_tab, aes(x = ESI_FF_HR, y = cause, color = color)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = ESI_FF_LCI, xmax = ESI_FF_UCI), height = 0.25, linewidth = 0.6) +
  geom_point(size = 3) +
  geom_text(aes(x = 1.55, label = sprintf("n=%d", n_events)),
            color = "grey30", size = 3.2, hjust = 0) +
  scale_x_log10(breaks = c(0.7, 0.85, 1, 1.15, 1.3, 1.5),
                limits = c(0.65, 2.0)) +
  scale_color_manual(values = c("ESI adds beyond FEV1/FVC" = "#D62728",
                                "ESI null beyond FEV1/FVC" = "#7F7F7F"),
                     name = NULL) +
  labs(x = "Hazard ratio for ESI (per 1-unit), adjusted for FEV1/FVC and covariates",
       y = NULL,
       title = "Cause-specific mortality: where does ESI add value beyond FEV1/FVC?",
       subtitle = "Each row is a cause category; colour reflects whether ESI is statistically significant after FEV1/FVC adjustment") +
  theme_bw(base_family = "Arial", base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom")
ggsave(file.path(OUT_DIR, "Figure_CauseSpecific.png"), fig, width = 10, height = 6, dpi = 300)

cat("\nDone.\n")
print(cs_tab[, c("cause","n_events","ESI_alone_HR","ESI_alone_p","ESI_FF_HR","ESI_FF_p","LR_p")])
