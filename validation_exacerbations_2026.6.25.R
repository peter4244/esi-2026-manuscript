#!/usr/bin/env Rscript
# Validation of the exacerbation analyses (2026-06-25).

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(MASS)
})
select <- dplyr::select

OUT <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/validation_exacerbations_2026.6.25.md"
LOG <- character(); n_pass <- 0L; n_fail <- 0L
emit  <- function(...) LOG[[length(LOG)+1L]] <<- paste0(...)
check <- function(label, expected, actual, tol = 0.005, fmt = "%.3f") {
  if (is.logical(expected) || is.logical(actual)) {
    expected <- unname(as.logical(expected)); actual <- unname(as.logical(actual))
  }
  ok <- if (is.numeric(expected) && is.numeric(actual)) {
    abs(expected - actual) <= tol
  } else identical(expected, actual)
  status <- if (ok) "PASS" else "**FAIL**"
  emit(sprintf("- [%s] %s — expected %s, recomputed %s", status, label,
               if (is.numeric(expected)) sprintf(fmt, expected) else expected,
               if (is.numeric(actual))   sprintf(fmt, actual)   else actual))
  if (ok) n_pass <<- n_pass + 1L else n_fail <<- n_fail + 1L
}

# Independent re-load and rebuild
esi <- read.csv("/Users/petecastaldi/claude_projects/projects/ESI_2024/copdgene_esi_randid_2026.5.17.csv", stringsAsFactors=FALSE); esi$rand_id <- as.character(esi$rand_id)
esi_v1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(rand_id) %>% summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")
phe <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/COPDGene_P1P2P3_SM_NS_ILDBR_Long_Sep24_randid.csv", stringsAsFactors=FALSE, na.strings=c("","NA")); phe$rand_id <- as.character(phe$rand_id)
v1 <- phe %>% filter(visitnum == 1)
ex <- read.csv("/Users/petecastaldi/claude_projects/copdgene/deidentified/LFU_SidLevel_Comorbd_randid.csv", stringsAsFactors=FALSE); ex$rand_id <- as.character(ex$rand_id)

stratum_levels <- c("Never","GOLD0","PRISm","GOLD1","GOLD2","GOLD3","GOLD4")
d <- esi_v1 %>% inner_join(v1, by = "rand_id") %>%
  mutate(stratum = factor(case_when(
    finalgold_visit == -2 ~ "Never", finalgold_visit == -1 ~ "PRISm",
    finalgold_visit ==  0 ~ "GOLD0", finalgold_visit ==  1 ~ "GOLD1",
    finalgold_visit ==  2 ~ "GOLD2", finalgold_visit ==  3 ~ "GOLD3",
    finalgold_visit ==  4 ~ "GOLD4", TRUE                  ~ NA_character_),
    levels = stratum_levels))

merge_ex <- d %>%
  inner_join(ex %>% select(rand_id, Total_Exacerbations, Total_Severe_Exacer, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0) %>%
  mutate(gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
         FF_per_0_1 = FEV1_FVC_post / 0.1)
ex_in <- merge_ex %>% filter(!is.na(stratum), !is.na(FEV1_FVC_post),
                             !is.na(age_visit), !is.na(ATS_PackYears), !is.na(BMI))
ex_in$stratum <- relevel(ex_in$stratum, ref = "GOLD0")

emit("# Validation log — Exacerbation analyses (2026-06-25)\n")
emit("Each line: `[PASS|FAIL] label — expected <reported> recomputed <independent>`.\n")

# ----- Step 1 — Factual accuracy -----
emit("\n## Step 1 — Factual accuracy\n")
check("Exacerbation merge cohort size", 8898, nrow(ex_in), tol = 0, fmt = "%d")
check("Total exacerbations in cohort",  24454, sum(ex_in$Total_Exacerbations), tol = 0, fmt = "%d")
check("Median follow-up years",         10.3, median(ex_in$Years_Followed), tol = 0.05)

# Re-fit headline models
m_esi  <- glm.nb(Total_Exacerbations ~ ESI_v1post + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
m_ff   <- glm.nb(Total_Exacerbations ~ FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
m_both <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)

check("ESI-only IRR(ESI)",      1.114, exp(coef(m_esi)["ESI_v1post"]),    tol = 0.01)
check("ESI+FF IRR(ESI)",        1.010, exp(coef(m_both)["ESI_v1post"]),   tol = 0.01)
check("ESI+FF IRR(FF per 0.1)", 0.797, exp(coef(m_both)["FF_per_0_1"]),   tol = 0.01)
check("FF-only IRR(FF per 0.1)", 0.787, exp(coef(m_ff)["FF_per_0_1"]),    tol = 0.01)

lr <- anova(m_ff, m_both, test = "Chisq")
check("LR chi-sq (ESI added beyond FF)",  0.14, lr$`LR stat.`[2], tol = 0.1)
check("LR p-value > 0.5 (ESI not adding)", TRUE, lr$`Pr(Chi)`[2] > 0.5)

# Severe exacerbations
m_sev <- glm.nb(Total_Severe_Exacer ~ ESI_v1post + FF_per_0_1 + age_visit + gender + race + SmokCigNow + ATS_PackYears + stratum + offset(log(Years_Followed)), data = ex_in)
check("Severe ESI+FF IRR(ESI) ≈ 0.99 (null)", 0.988, exp(coef(m_sev)["ESI_v1post"]), tol = 0.02)
check("Severe ESI p > 0.5",                   TRUE, summary(m_sev)$coef["ESI_v1post","Pr(>|z|)"] > 0.5)

# Bhatt vs ESI-variant exacerbations
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
                  ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD", "noCOPD")))
esi_s <- ifelse(d_b$ESI_v1post >= 2.5, 2, ifelse(d_b$ESI_v1post >= 1.0, 1, 0))
n_minor_e <- esi_s + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$esi_cls <- ifelse(d_b$major_criterion & n_minor_e >= 1, "COPD-major",
                ifelse(!d_b$major_criterion & n_minor_e >= 3, "COPD-minor",
                ifelse(d_b$major_criterion & n_minor_e == 0, "AFL-only-NoCOPD", "noCOPD")))
ord <- c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
ex_b <- d_b %>% inner_join(ex %>% select(rand_id, Total_Exacerbations, Years_Followed), by = "rand_id") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0) %>%
  mutate(bhatt_grp = factor(bhatt_cls, levels = ord), esi_grp = factor(esi_cls, levels = ord),
         gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow)) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))

nb_b <- glm.nb(Total_Exacerbations ~ bhatt_grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
nb_e <- glm.nb(Total_Exacerbations ~ esi_grp   + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_b)
check("Bhatt COPD-minor IRR",  2.728, exp(coef(nb_b)["bhatt_grpCOPD-minor"]), tol = 0.05)
check("Bhatt COPD-major IRR",  5.068, exp(coef(nb_b)["bhatt_grpCOPD-major"]), tol = 0.10)
check("ESI-variant COPD-minor IRR",  2.781, exp(coef(nb_e)["esi_grpCOPD-minor"]), tol = 0.05)
check("ESI-variant COPD-major IRR",  4.473, exp(coef(nb_e)["esi_grpCOPD-major"]), tol = 0.10)

# Discordance subgroups
categorize <- function(b, e) {
  case_when(b & e ~ "Both-COPD", b & !e ~ "Bhatt-only-COPD (ESI missed)",
            !b & e ~ "ESI-only-COPD (Bhatt missed)", !b & !e ~ "Both-noCOPD")
}
ex_b$bhatt_copd <- d_b$bhatt_cls[match(ex_b$rand_id, d_b$rand_id)] %in% c("COPD-major","COPD-minor")
ex_b$esi_copd   <- d_b$esi_cls[match(ex_b$rand_id, d_b$rand_id)] %in% c("COPD-major","COPD-minor")
ex_b$grp <- factor(categorize(ex_b$bhatt_copd, ex_b$esi_copd),
                   levels = c("Both-noCOPD","Both-COPD",
                              "Bhatt-only-COPD (ESI missed)", "ESI-only-COPD (Bhatt missed)"))
ex_pres <- ex_b %>% filter(!major_criterion)
nb_grp <- glm.nb(Total_Exacerbations ~ grp + age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI + offset(log(Years_Followed)), data = ex_pres)
check("Both-COPD discord IRR",      3.17, exp(coef(nb_grp)["grpBoth-COPD"]), tol = 0.05)
check("Bhatt-only-COPD discord IRR", 2.01, exp(coef(nb_grp)["grpBhatt-only-COPD (ESI missed)"]), tol = 0.05)

# ----- Step 2 — Adversarial sanity -----
emit("\n## Step 2 — Adversarial sanity checks\n")

# Sanity: severe exacerbations are a subset of total
n_sev_gt_tot <- sum(ex_in$Total_Severe_Exacer > ex_in$Total_Exacerbations)
check("Severe exacerbations never exceed total", 0, n_sev_gt_tot, tol = 0, fmt = "%d")

# Sanity: subjects with positive person-time only
check("All subjects have Years_Followed > 0", TRUE, all(ex_in$Years_Followed > 0))

# Sanity: ESI 'effect' should disappear after FF — also true with simpler covariate set?
m_simple_both <- glm.nb(Total_Exacerbations ~ ESI_v1post + FF_per_0_1 + age_visit + offset(log(Years_Followed)), data = ex_in)
emit(sprintf("- Simpler model (no stratum, no smoking, no PY): ESI IRR = %.3f, p = %.3g",
             exp(coef(m_simple_both)["ESI_v1post"]),
             summary(m_simple_both)$coef["ESI_v1post","Pr(>|z|)"]))

# Sanity: pattern direction makes sense — lower FF (more obstruction) should mean more exacerbations
# IRR(FF per 0.1) < 1 means per 0.1 INCREASE in FF, exacerbations decrease — i.e., lower FF = more exac (correct direction)
check("Direction: lower FEV1/FVC → more exacerbations (IRR per 0.1-unit < 1)",
      TRUE, exp(coef(m_ff)["FF_per_0_1"]) < 1)

# Sanity: Both-COPD subjects have higher IRR than Both-noCOPD (positive coefficient)
check("Both-COPD > reference (positive coefficient)",
      TRUE, coef(nb_grp)["grpBoth-COPD"] > 0)

# Pattern comparison — ESI loses its signal after FF adjustment same as in respiratory mortality
emit("- Pattern: ESI signal disappears after FEV1/FVC adjustment (same as respiratory mortality, opposite of all-cause mortality).")

# ----- Step 3 — Documentation accuracy -----
emit("\n## Step 3 — Documentation accuracy\n")
check("Prose: '8,898 subjects in exacerbation cohort'",  8898, nrow(ex_in), tol = 0, fmt = "%d")
check("Prose: '24,454 total exacerbations'",             24454, sum(ex_in$Total_Exacerbations), tol = 0, fmt = "%d")
check("Prose: 'median 10.3 yr follow-up'",               10.3, median(ex_in$Years_Followed), tol = 0.05)
check("Prose: 'ESI IRR ≈ 1.11 alone (p < 0.001)'",       TRUE, exp(coef(m_esi)["ESI_v1post"]) > 1.10 && summary(m_esi)$coef["ESI_v1post","Pr(>|z|)"] < 0.001)
check("Prose: 'ESI IRR ≈ 1.01 after FF (null)'",         TRUE, abs(exp(coef(m_both)["ESI_v1post"]) - 1.0) < 0.02 && summary(m_both)$coef["ESI_v1post","Pr(>|z|)"] > 0.5)
check("Prose: 'Bhatt COPD-major IRR ~5; ESI-var COPD-major IRR ~4.5; similar'",
      TRUE, abs(exp(coef(nb_b)["bhatt_grpCOPD-major"]) - exp(coef(nb_e)["esi_grpCOPD-major"])) < 1)

# Summary
LOG <- c("# Validation log — Exacerbation analyses (2026-06-25)",
         "",
         sprintf("**Result: %d checks PASS, %d checks FAIL.**", n_pass, n_fail),
         "", LOG[-(1:2)])
writeLines(LOG, OUT)
cat(sprintf("\nPASS: %d   FAIL: %d   →  %s\n", n_pass, n_fail, OUT))
