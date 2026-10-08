# C1. Is respiratory death under-ascertained, and differentially by group?
# Background: an earlier analysis noted 2,101 adjudicated deaths in the COD file,
# whereas this cohort has 2,581 deaths in the vital-status file. Deaths with no
# adjudicated cause (or Torch code 5) are counted as non-respiratory.
# CONFIRMS the published respiratory estimates if: unadjudicated share is small
# (<10%) OR similar across S2 groups and the restricted-window sensitivity gives
# HRs within ~15% of Table S5. REFUTES if the unadjudicated share differs by group
# or the sensitivity HRs move materially.
source("verification_5step_2026-10-08/step2_cluster_checks/00_load_objects.R")
library(dplyr); library(survival)
torch <- cod %>% transmute(pid, torch = suppressWarnings(as.integer(Torch_Group_Basic))) %>%
  distinct(pid, .keep_all = TRUE)
cat("duplicate pids in cod:", anyDuplicated(cod$pid) > 0, "\n")
dd <- mort %>% left_join(torch, by = "pid") %>% filter(vital_status == 1)
dd$cause <- ifelse(is.na(dd$torch), "no COD record",
            c("resp", "cvd", "cancer", "other", "unknown")[pmin(dd$torch, 5)])
print(table(dd$S2, dd$cause))
print(round(100 * prop.table(table(dd$S2, dd$cause), 1), 1))
# when did unadjudicated deaths occur? (years from visit 1)
print(tapply(dd$py, dd$cause, quantile, probs = c(.1, .5, .9)))
# Sensitivity: censor all follow-up at the latest adjudicated death time.
t_max <- max(dd$py[!is.na(dd$torch)])
ms <- mort; ms$py2 <- pmin(ms$py, t_max)
ms$ev2 <- ifelse(ms$py <= t_max, ms$ev_resp, 0)
ms <- merge(ms, d_b[, c("pid", "cons")], by = "pid")
for (s in c("S2", "S3", "S4")) {
  m <- ms[ms$cons | ms[[s]] %in% OTHER[[s]], ]
  m$g <- factor(ifelse(m$cons, "REF", as.character(m[[s]])), c("REF", OTHER[[s]]))
  f <- coxph(as.formula(paste("Surv(py2, ev2) ~ g +", COV)), data = m)
  cat(s, "\n"); print(round(summary(f)$conf.int[grep("^g", rownames(summary(f)$conf.int)), c(1, 3, 4)], 2))
}
cat("latest adjudicated death (years from V1):", round(t_max, 2), "\n")
