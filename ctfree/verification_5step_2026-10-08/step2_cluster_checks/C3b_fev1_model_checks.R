# C3. FEV1 decline: (a) random-slope sensitivity; (b) where the COPD-minor
# difference comes from.
# (a) The published model has a random intercept only. Most participants have one visit, so
# lme4's default count check refuses a random slope; it is switched off (check.nobs.vs.nRE),
# since the slope variance is identified by the participants with two or more visits.
# Group-by-time SEs from such
# a model are typically too small when slopes vary between people.
# CONFIRMS Table S6 if (1 + years | pid) gives similar estimates and SEs no more
# than ~25% wider, with the same significance pattern. REFUTES the Table S6
# significance pattern (and the Results/Discussion sentences built on it) if
# AFL-only under MD-COPD-ESI or COPD-minor under MD-COPD-CT lose significance.
# (b) S2 COPD-minor is -4.5 mL/yr, S4 COPD-minor -0.1, yet 714 of S4's 1,215 are
# S2 COPD-minor. This splits the preserved-spirometry participants into the
# discordance groups and estimates each against the common reference.
# Expect either the 85 CT-only to decline very fast or the 501 ESI-only to
# decline slower than the reference; either way the Discussion sentence on
# COPD-minor needs to say which.
source("verification_5step_2026-10-08/step2_cluster_checks/00_load_objects.R")
suppressPackageStartupMessages({ library(lme4); library(lmerTest); library(dplyr) })
rhs <- " + Height_CM + gender_baseline + race_baseline + age_visit + SmokCigNow + ATS_PackYears + years_from_baseline:FEV1_base_mL"
for (sname in SCHEMAS) {
  dd <- decline[decline$cons | decline[[sname]] %in% OTHER[[sname]], ]
  dd$g <- factor(ifelse(dd$cons, "REF", as.character(dd[[sname]])), c("REF", OTHER[[sname]]))
  f_ri <- lmer(as.formula(paste0("FEV1_post_mL ~ years_from_baseline * g", rhs, " + (1 | pid)")), data = dd)
  f_rs <- lmer(as.formula(paste0("FEV1_post_mL ~ years_from_baseline * g", rhs, " + (1 + years_from_baseline | pid)")),
               data = dd, control = lmerControl(optimizer = "bobyqa", check.nobs.vs.nRE = "ignore"))
  k <- grep("^years_from_baseline:g", rownames(coef(summary(f_ri))))
  cat("\n", sname, "\n")
  print(round(cbind(RI = coef(summary(f_ri))[k, c(1, 2, 5)], RS = coef(summary(f_rs))[k, c(1, 2, 5)]), 3))
}
# (b) discordance groups, preserved spirometry, against the common reference
dec <- decline %>% left_join(d_b %>% transmute(pid, afl, discord = as.character(discord)), by = "pid")
dp <- dec[dec$cons | (!dec$afl & dec$discord %in% c("CT-only-COPD", "ESI-only-COPD", "Both-COPD")), ]
dp$g <- factor(ifelse(dp$cons, "REF", dp$discord), c("REF", "Both-COPD", "CT-only-COPD", "ESI-only-COPD"))
fb <- lmer(as.formula(paste0("FEV1_post_mL ~ years_from_baseline * g", rhs, " + (1 | pid)")), data = dp)
co <- coef(summary(fb)); print(round(co[grep("^years_from_baseline:g", rownames(co)), c(1, 2, 5)], 2))
print(table(dp$g[!duplicated(dp$pid)]))
