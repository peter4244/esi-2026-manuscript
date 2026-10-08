# C4. Row-level integrity the Rmd does not assert: one row per participant in
# every outcome table, so that the participant bootstrap resamples participants.
# CONFIRMS if every line prints FALSE / 0.
source("verification_5step_2026-10-08/step2_cluster_checks/00_load_objects.R")
cat("dup pid d_b  :", anyDuplicated(d_b$pid) > 0, "\n")
cat("dup pid mort :", anyDuplicated(mort$pid) > 0, "\n")
cat("dup pid exa  :", anyDuplicated(exa$pid) > 0, "\n")
cat("dup pid vs   :", anyDuplicated(vs$pid) > 0, "\n")
cat("dup pid ex_raw:", anyDuplicated(ex_raw$pid) > 0, "\n")
cat("dup pid cod  :", anyDuplicated(cod$pid) > 0, "\n")
cat("dup pid x visit in decline:", anyDuplicated(decline[, c("pid", "visitnum")]) > 0, "\n")
cat("deaths with py <= 0:", sum(mort$py <= 0), "\n")
cat("resp deaths with vital_status 0:", sum(mort$ev_resp == 1 & mort$vital_status == 0), "\n")
cat("prior_exac range:", range(exa$prior_exac), "\n")
