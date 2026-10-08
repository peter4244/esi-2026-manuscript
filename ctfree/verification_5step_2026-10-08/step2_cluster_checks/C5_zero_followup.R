# C5. Participants in the mortality analysis with zero follow-up time (C4 found 469).
# Who are they, are any of them deaths, and do they differ by classification?
# Prints aggregate counts only.
source("verification_5step_2026-10-08/step2_cluster_checks/00_load_objects.R")
z <- mort$py <= 0
cat("participants in mort:", nrow(mort), " with py <= 0:", sum(z), "\n")
cat("  of whom deaths (vital_status 1):", sum(mort$vital_status[z] == 1), "\n")
cat("  of whom respiratory events:", sum(mort$ev_resp[z] == 1), "\n")
cat("  days_followed NA among them:", sum(is.na(mort$days_followed[z])), "\n")
if ("py_resp" %in% names(mort)) cat("  with py_resp > 0:", sum(mort$py_resp[z] > 0), "\n")
cat("\nby MD-COPD-CT category (n, zero-follow-up n, %):\n")
tb <- table(mort$S2, z)
print(cbind(n = rowSums(tb), zero = tb[, "TRUE"], pct = round(100 * tb[, "TRUE"] / rowSums(tb), 1)))
cat("\nin the exacerbation analysis as well:", sum(mort$pid[z] %in% exa$pid), "\n")
cat("median follow-up, all-cause: all", round(median(mort$py), 2), " excluding zero", round(median(mort$py[!z]), 2), "\n")
