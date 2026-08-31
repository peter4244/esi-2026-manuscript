#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# GO / NO-GO GATE for the CT-free reframe.
#
# The reframe argues that when CT is unavailable, an ESI-based MD-COPD
# classification preserves MD-COPD's advantage over the fixed ratio. That
# presupposes MD-COPD HAS an advantage over the fixed ratio in this cohort,
# which the manuscript has never shown: every comparison in it is CT-based
# framework against ESI-based framework, with no fixed-ratio arm.
#
# The fixed-ratio definition is a strict coarsening of the MD-COPD categories:
#   fixed-ratio COPD  ==  AFL-only-noCOPD or COPD-major
# so the MD-COPD model nests the fixed-ratio model and the two can be compared
# by likelihood ratio test on 2 degrees of freedom, not just by eyeballing
# C-indices. Both are reported.
#
# Writes only to exploration/. Changes nothing.
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(survival); library(MASS)})
OUT <- file.path("exploration", "ctfree_gate")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
source("config_paths.R")

read_any <- function(p, ...) {
  h <- readLines(p, n = 1, warn = FALSE)
  read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE, ...)
}
bind_pid <- function(df, lab) {
  cand <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit <- cand[cand %in% names(df)]
  if (!length(hit)) stop("no id column in ", lab)
  df$pid <- as.character(df[[hit[1]]]); df
}

esi_raw <- bind_pid(read_any(ESI_PATH), "ESI")
phe_raw <- bind_pid(read_any(PHE_PATH, na.strings = c("", "NA")), "PHE")
phe_raw <- phe_raw[!(!is.na(phe_raw$cohort) & trimws(phe_raw$cohort) == "ILD/Brnch"), ]
vs  <- bind_pid(read_any(VS_PATH),  "VS")
cod <- bind_pid(read_any(COD_PATH), "COD")
ex_raw <- bind_pid(read_any(EX_PATH), "EX")
ucd <- suppressWarnings(as.integer(cod$Torch_Group_Basic))
cod$UCD_Resp <- as.integer(!is.na(ucd) & ucd == 1L)

esi_v1 <- esi_raw %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

d_b <- esi_v1 %>% inner_join(phe_raw %>% filter(visitnum == 1), by = "pid") %>%
  mutate(gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
         major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2,
         qol_yn  = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn), !is.na(ESI_v1post))
nb <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
ORD <- c("noCOPD", "AFL-only-NoCOPD", "COPD-minor", "COPD-major")
d_b$bhatt_grp <- factor(
  ifelse(d_b$major_criterion & nb >= 1, "COPD-major",
  ifelse(!d_b$major_criterion & nb >= 3, "COPD-minor",
  ifelse(d_b$major_criterion & nb == 0, "AFL-only-NoCOPD", "noCOPD"))), levels = ORD)
# S0: the fixed ratio, exactly the major criterion on its own.
d_b$fixed_ratio <- factor(ifelse(d_b$major_criterion, "COPD", "noCOPD"),
                          levels = c("noCOPD", "COPD"))
stopifnot(nrow(d_b) == 9402L)
# The coarsening that makes the two models nested.
stopifnot(all((d_b$fixed_ratio == "COPD") ==
              (d_b$bhatt_grp %in% c("AFL-only-NoCOPD", "COPD-major"))))
cat(sprintf("cohort n = %d; fixed-ratio COPD n = %d; MD-COPD any-COPD n = %d\n\n",
            nrow(d_b), sum(d_b$fixed_ratio == "COPD"),
            sum(d_b$bhatt_grp %in% c("COPD-minor", "COPD-major"))))

COV <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"

mort <- d_b %>%
  inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp), by = "pid") %>%
  mutate(event_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
prior <- phe_raw %>% filter(visitnum == 1) %>%
  transmute(pid, prior_exac = suppressWarnings(as.numeric(Exacerbation_Frequency))) %>%
  distinct(pid, .keep_all = TRUE)
exac <- d_b %>%
  inner_join(ex_raw %>% dplyr::select(pid, Total_Exacerbations, Years_Followed), by = "pid") %>%
  left_join(prior, by = "pid") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0, !is.na(prior_exac),
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
cat(sprintf("mortality n = %d (%d deaths, %d respiratory); exacerbation n = %d\n\n",
            nrow(mort), sum(mort$vital_status), sum(mort$event_resp), nrow(exac)))

cox_pair <- function(ev, label) {
  f0 <- as.formula(sprintf("Surv(days_followed/365.25, %s) ~ fixed_ratio + %s", ev, COV))
  f1 <- as.formula(sprintf("Surv(days_followed/365.25, %s) ~ bhatt_grp + %s", ev, COV))
  m0 <- coxph(f0, data = mort); m1 <- coxph(f1, data = mort)
  lr <- 2 * (m1$loglik[2] - m0$loglik[2])
  df <- length(coef(m1)) - length(coef(m0))
  c0 <- summary(m0)$concordance; c1 <- summary(m1)$concordance
  cat(sprintf("--- %s ---\n", label))
  cat(sprintf("  S0 fixed ratio : C = %.4f (SE %.4f)\n", c0[1], c0[2]))
  cat(sprintf("  S1 MD-COPD     : C = %.4f (SE %.4f)   gain %+.4f\n", c1[1], c1[2], c1[1] - c0[1]))
  cat(sprintf("  likelihood ratio test, MD-COPD over fixed ratio: chisq = %.1f on %d df, p = %s\n",
              lr, df, format.pval(pchisq(lr, df, lower.tail = FALSE), digits = 3, eps = 1e-16)))
  s <- summary(m1)$conf.int
  for (g in ORD[-1]) {
    r <- paste0("bhatt_grp", g)
    if (r %in% rownames(s))
      cat(sprintf("    %-16s HR %5.2f (%.2f-%.2f)\n", g, s[r, 1], s[r, 3], s[r, 4]))
  }
  s0 <- summary(m0)$conf.int
  cat(sprintf("    %-16s HR %5.2f (%.2f-%.2f)  [fixed-ratio model]\n\n",
              "COPD", s0["fixed_ratioCOPD", 1], s0["fixed_ratioCOPD", 3], s0["fixed_ratioCOPD", 4]))
  invisible(NULL)
}
cox_pair("vital_status", "ALL-CAUSE MORTALITY")
cox_pair("event_resp",   "RESPIRATORY MORTALITY")

cat("--- EXACERBATIONS ---\n")
n0 <- glm.nb(as.formula(paste("Total_Exacerbations ~ fixed_ratio +", COV,
                              "+ prior_exac + offset(log(Years_Followed))")), data = exac)
n1 <- glm.nb(as.formula(paste("Total_Exacerbations ~ bhatt_grp +", COV,
                              "+ prior_exac + offset(log(Years_Followed))")), data = exac)
lr <- 2 * (logLik(n1) - logLik(n0)); df <- length(coef(n1)) - length(coef(n0))
cat(sprintf("  S0 fixed ratio : AIC %.1f\n  S1 MD-COPD     : AIC %.1f   improvement %.1f\n",
            AIC(n0), AIC(n1), AIC(n0) - AIC(n1)))
cat(sprintf("  likelihood ratio test, MD-COPD over fixed ratio: chisq = %.1f on %d df, p = %s\n",
            as.numeric(lr), df,
            format.pval(pchisq(as.numeric(lr), df, lower.tail = FALSE), digits = 3, eps = 1e-16)))
s <- summary(n1)$coef
for (g in ORD[-1]) {
  r <- paste0("bhatt_grp", g)
  if (r %in% rownames(s))
    cat(sprintf("    %-16s IRR %5.2f (%.2f-%.2f)\n", g, exp(s[r, 1]),
                exp(s[r, 1] - 1.96 * s[r, 2]), exp(s[r, 1] + 1.96 * s[r, 2])))
}
s0 <- summary(n0)$coef
cat(sprintf("    %-16s IRR %5.2f (%.2f-%.2f)  [fixed-ratio model]\n", "COPD",
            exp(s0["fixed_ratioCOPD", 1]),
            exp(s0["fixed_ratioCOPD", 1] - 1.96 * s0["fixed_ratioCOPD", 2]),
            exp(s0["fixed_ratioCOPD", 1] + 1.96 * s0["fixed_ratioCOPD", 2])))
cat(sprintf("\nwrote %s\n", normalizePath(OUT)))
