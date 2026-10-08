# C2. Does ESI add anything that a conventional spirometric index does not?
# The paper concludes the flow-volume curve carries structural information
# "beyond conventional spirometric indices", but in esi_ct_auc.csv FEV1/FVC
# discriminates both visual CT criteria at least as well as ESI in every stratum.
# Here the ESI criterion is replaced by (a) FEV1/FVC <= t and (b) FEV1 %pred <= t,
# each fitted by the SAME outcome-blind macro-F1 grid search, then scored on the
# same quantities the paper reports for ESI.
# CONFIRMS an ESI-specific benefit if the ESI rule beats both comparators on
# macro-F1 / agreement and on the AFL-only crude mortality and exacerbation ratio
# versus MD-COPD-CT. REFUTES it if a comparator matches or beats ESI.
source("verification_5step_2026-10-08/step2_cluster_checks/00_load_objects.R")
library(dplyr)
s_alt <- function(df, k, crit) label(df, (crit + df$om) >= k & (!df$card | crit == 1), (crit + df$om) == 0)
grid_fit <- function(x, thr, dir) {
  best <- NULL
  for (k in 2:4) for (t in thr) {
    crit <- as.integer(if (dir == "ge") x >= t else x <= t); crit[is.na(crit)] <- 0L
    sc <- macroF1(d_b$S2, s_alt(d_b, k, crit))
    if (is.null(best) || sc > best$score) best <- list(k = k, t = t, score = sc)
  }
  best
}
alts <- list(
  ESI      = list(x = d_b$ESI,           thr = seq(0.50, 4.00, 0.25), dir = "ge"),
  FEV1FVC  = list(x = d_b$FEV1_FVC_post, thr = seq(0.30, 0.80, 0.01), dir = "le"),
  FEV1pp   = list(x = d_b$FEV1pp_utah,   thr = seq(20, 110, 2.5),     dir = "le"))
rows <- list(); lab_list <- list()
for (nm in names(alts)) {
  a <- alts[[nm]]; cat(nm, "missing:", sum(is.na(a$x)), "(treated as criterion not met)\n")
  b <- grid_fit(a$x, a$thr, a$dir)
  crit <- as.integer(if (a$dir == "ge") a$x >= b$t else a$x <= b$t); crit[is.na(crit)] <- 0L
  est <- s_alt(d_b, b$k, crit); lab_list[[nm]] <- est
  rows[[nm]] <- data.frame(rule = nm, k = b$k, t = b$t, macroF1 = b$score,
    agreement = mean(est == d_b$S2),
    n_aflonly = sum(est == "AFL-only"), major_to_aflonly = sum(d_b$S2 == "COPD-major" & est == "AFL-only"))
}
print(do.call(rbind, rows), digits = 4)
stopifnot(all(lab_list$ESI == d_b$S4))   # the ESI arm must reproduce S4
# AFL-only risk vs MD-COPD-CT AFL-only (crude ratio of rates, paired bootstrap)
mm <- mort; ee <- exa
for (nm in names(lab_list)) {
  mm[[nm]] <- lab_list[[nm]][match(mm$pid, d_b$pid)]
  ee[[nm]] <- lab_list[[nm]][match(ee$pid, d_b$pid)]
}
rr <- function(d, s, ev, py) {
  a <- d[[s]] == "AFL-only"; r <- d$S2 == "AFL-only"
  (sum(d[[ev]][a]) / sum(d[[py]][a])) / (sum(d[[ev]][r]) / sum(d[[py]][r]))
}
set.seed(20260901)
for (o in list(c("vital_status", "py", "m"), c("Total_Exacerbations", "Years_Followed", "e"))) {
  dat <- if (o[3] == "m") mm else ee
  pt <- sapply(names(lab_list), function(s) rr(dat, s, o[1], o[2]))
  bs <- replicate(1000, { d <- dat[sample.int(nrow(dat), replace = TRUE), ]
                          sapply(names(lab_list), function(s) rr(d, s, o[1], o[2])) })
  cat("\n", o[1], ": AFL-only rate ratio vs MD-COPD-CT AFL-only\n")
  print(round(cbind(est = pt, lo = apply(bs, 1, quantile, .025), hi = apply(bs, 1, quantile, .975)), 3))
}
