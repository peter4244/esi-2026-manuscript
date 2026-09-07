#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# SIDE ANALYSIS. Not part of the manuscript pipeline.
#
# If the two CT criteria are removed, what should replace them? This compares
# every candidate on the same footing: each is fitted by the same objective
# (macro-averaged F1 over the four MD-COPD categories) over its own threshold
# grid and the same count grid, then judged on what the paper actually cares
# about, which is not label agreement alone but whether the AFL-only category
# stays low risk.
#
# Candidates:
#   none        no replacement (NoCT-MD-COPD as published here)
#   FEV1/FVC    a second threshold on the diagnostic variable itself
#   FEV1pp      FEV1 percent predicted, the conventional severity measure
#   ESI         the Emphysema Severity Index
#   LAA-950     quantitative CT emphysema; not CT-free, included as the
#               ceiling a genuine structural measure achieves
#   FEV1/FVC+ESI  both, to test whether ESI adds beyond the simpler rule
#
# Held-out performance is reported alongside in-sample, because a rule with a
# free threshold can fit the reference labels better without generalizing.
#
# Usage:  Rscript ctfree/side_analyses/replacement_criteria_comparison.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(survival)})
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- dirname(normalizePath(sub("^--file=", "", .b[1])))
ROOT <- dirname(dirname(HERE))
source(file.path(ROOT, "config_paths.R"))
read_any <- function(p, ...) { h <- readLines(p, n = 1, warn = FALSE)
  read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE, ...) }
bp <- function(d) { d$pid <- as.character(
  d[[intersect(c(ID_COL, paste0(ID_COL, ".x")), names(d))[1]]]); d }

phe <- bp(read_any(PHE_PATH, na.strings = c("", "NA")))
mdc <- bp(read_any(MDCOPD_PATH)); esi <- bp(read_any(ESI_PATH))
vs  <- bp(read_any(VS_PATH));     cod <- bp(read_any(COD_PATH))
u <- suppressWarnings(as.integer(cod$Torch_Group_Basic))
cod$UCD_Resp <- as.integer(!is.na(u) & u == 1L)

v1 <- phe[phe$visitnum == 1, ]
b <- v1[is.na(v1$ExclusionaryDisease), ]
b <- b[trimws(b$cohort) != "Never smoked", ]
b <- b[!is.na(b$FEV1_FVC_post), ]
b <- merge(b, mdc[!is.na(mdc$MultiDim_COPD_score), c("pid","MultiDim_COPD_score")], by = "pid")
ev <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
d <- merge(b, ev, by = "pid"); d <- d[!is.na(d$ESI), ]
f <- function(x) { x[is.na(x)] <- FALSE; x }
d$om  <- f(d$MMRCDyspneaScor >= 2) + f(d$SGRQ_scoreTotal >= 25) + f(d$Chronic_Bronchitis == 1)
d$afl <- d$FEV1_FVC_post < 0.70
O <- c("noCOPD","AFL-only","COPD-minor","COPD-major")
d$ref <- factor(ifelse(d$MultiDim_COPD_score == 1, "COPD-major",
                ifelse(d$MultiDim_COPD_score == 2, "COPD-minor",
                ifelse(d$afl, "AFL-only", "noCOPD"))), levels = O)
# CT-only-major: the 833 that a CT-free rule has to recover.
d$ct_only <- d$ref == "COPD-major" & d$om == 0

mk <- function(dd, s, k) {
  tot <- s + dd$om
  factor(ifelse(dd$afl & tot > 0, "COPD-major", ifelse(dd$afl & tot == 0, "AFL-only",
         ifelse(!dd$afl & tot >= k, "COPD-minor", "noCOPD"))), levels = O)
}
mF1 <- function(ref, est) mean(vapply(O, function(g) {
  tp <- sum(ref == g & est == g); if (tp == 0) return(0)
  2 * tp / (sum(est == g) + sum(ref == g)) }, numeric(1)))

# Each candidate: the score, its direction, and the grid to search.
CAND <- list(
  none       = list(var = NULL,                        grid = NA),
  `FEV1/FVC` = list(var = "FEV1_FVC_post", dir = "le", grid = seq(0.50, 0.69, by = 0.01)),
  FEV1pp     = list(var = "FEV1pp_utah",   dir = "le", grid = seq(30, 100, by = 2.5)),
  ESI        = list(var = "ESI",           dir = "ge", grid = seq(0.50, 4.00, by = 0.25)),
  `LAA-950`  = list(var = "Insp_LAA950_total_Thirona", dir = "ge",
                    grid = seq(1, 20, by = 0.5)))
score_of <- function(dd, cn, t) {
  cd <- CAND[[cn]]
  if (is.null(cd$var)) return(rep(0L, nrow(dd)))
  v <- dd[[cd$var]]; v[is.na(v)] <- if (cd$dir == "ge") -Inf else Inf
  as.integer(if (cd$dir == "ge") v >= t else v <= t)
}
fit_one <- function(dd, cn) {
  g <- if (is.null(CAND[[cn]]$var)) NA else CAND[[cn]]$grid
  best <- list(f1 = -Inf)
  for (k in 1:3) for (t in g) {
    est <- mk(dd, score_of(dd, cn, t), k)
    v <- mF1(dd$ref, est)
    if (v > best$f1) best <- list(f1 = v, k = k, t = t)
  }
  best
}
# The combined rule needs its own two-dimensional search.
fit_both <- function(dd) {
  best <- list(f1 = -Inf)
  for (k in 1:3) for (tf in seq(0.50, 0.69, by = 0.01)) for (te in seq(0.50, 4.00, by = 0.25)) {
    s <- as.integer(dd$FEV1_FVC_post <= tf) + as.integer(dd$ESI >= te)
    v <- mF1(dd$ref, mk(dd, s, k))
    if (v > best$f1) best <- list(f1 = v, k = k, tf = tf, te = te)
  }
  best
}
lab_both <- function(dd, p) mk(dd, as.integer(dd$FEV1_FVC_post <= p$tf) +
                                  as.integer(dd$ESI >= p$te), p$k)

# ---- fit each candidate on the full cohort -------------------------------
FITS <- lapply(setdiff(names(CAND), character(0)), function(cn) fit_one(d, cn))
names(FITS) <- names(CAND)
FB <- fit_both(d)
LAB <- lapply(names(CAND), function(cn) mk(d, score_of(d, cn, FITS[[cn]]$t), FITS[[cn]]$k))
names(LAB) <- names(CAND)
LAB[["FEV1/FVC+ESI"]] <- lab_both(d, FB)

# ---- held-out macro-F1, thresholds refitted inside every training fold ---
set.seed(20260901L); REP <- 3L; K <- 5L
held <- setNames(numeric(length(LAB)), names(LAB))
for (r in seq_len(REP)) {
  fold <- integer(nrow(d))
  for (lv in O) { i <- which(d$ref == lv); fold[i] <- sample(rep_len(seq_len(K), length(i))) }
  for (kf in seq_len(K)) {
    tr <- d[fold != kf, ]; te <- d[fold == kf, ]
    for (cn in names(CAND)) {
      p <- fit_one(tr, cn)
      held[cn] <- held[cn] + mF1(te$ref, mk(te, score_of(te, cn, p$t), p$k))
    }
    p <- fit_both(tr)
    held["FEV1/FVC+ESI"] <- held["FEV1/FVC+ESI"] + mF1(te$ref, lab_both(te, p))
  }
}
held <- held / (REP * K)

# ---- outcome models ------------------------------------------------------
m <- d %>% inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp), by = "pid") %>%
  mutate(ev_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0),
         py = days_followed / 365.25) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
COV <- "age_visit + factor(gender) + factor(race) + factor(SmokCigNow) + ATS_PackYears + BMI"
hr_afl <- function(lv, ev) {
  m$g <- factor(lv[match(m$pid, d$pid)], levels = O)
  if (sum(m$g == "AFL-only") < 5) return(rep(NA_real_, 3))
  s <- summary(coxph(as.formula(sprintf("Surv(py, %s) ~ g + %s", ev, COV)), data = m))$conf.int
  if (!"gAFL-only" %in% rownames(s)) return(rep(NA_real_, 3))
  unname(s["gAFL-only", c(1,3,4)])
}
cidx <- function(lv) {
  m$g <- factor(lv[match(m$pid, d$pid)], levels = O)
  summary(coxph(as.formula(paste("Surv(py, vital_status) ~ g +", COV)), data = m))$concordance[1]
}

# ---- assemble ------------------------------------------------------------
rows <- lapply(names(LAB), function(cn) {
  lv <- LAB[[cn]]
  a <- hr_afl(lv, "vital_status"); rr <- hr_afl(lv, "ev_resp")
  p <- if (cn == "FEV1/FVC+ESI") FB else FITS[[cn]]
  data.frame(
    criterion = cn,
    rule = if (cn == "none") "no replacement"
           else if (cn == "FEV1/FVC+ESI") sprintf("FEV1/FVC<=%.2f & ESI>=%.2f, k=%d", p$tf, p$te, p$k)
           else sprintf("%s %s %s, k=%d", cn, ifelse(CAND[[cn]]$dir == "ge", ">=", "<="),
                        format(p$t), p$k),
    n_aflonly = sum(lv == "AFL-only"), n_minor = sum(lv == "COPD-minor"),
    n_major = sum(lv == "COPD-major"),
    ct_only_recovered = sum(d$ct_only & lv == "COPD-major"),
    macroF1_insample = mF1(d$ref, lv), macroF1_heldout = held[[cn]],
    afl_all_HR = a[1], afl_all_lo = a[2], afl_all_hi = a[3],
    afl_resp_HR = rr[1], afl_resp_lo = rr[2], afl_resp_hi = rr[3],
    c_index = cidx(lv),
    reach_preserved = if (cn == "none") 0L else
      sum(!d$afl & score_of(d, if (cn == "FEV1/FVC+ESI") "ESI" else cn,
          if (cn == "FEV1/FVC+ESI") FB$te else FITS[[cn]]$t) == 1L),
    stringsAsFactors = FALSE)
})
res <- do.call(rbind, rows)
ref_row <- data.frame(criterion = "MD-COPD", rule = "reference (CT available)",
  n_aflonly = sum(d$ref == "AFL-only"), n_minor = sum(d$ref == "COPD-minor"),
  n_major = sum(d$ref == "COPD-major"), ct_only_recovered = sum(d$ct_only),
  macroF1_insample = 1, macroF1_heldout = NA,
  afl_all_HR = hr_afl(d$ref,"vital_status")[1], afl_all_lo = hr_afl(d$ref,"vital_status")[2],
  afl_all_hi = hr_afl(d$ref,"vital_status")[3],
  afl_resp_HR = hr_afl(d$ref,"ev_resp")[1], afl_resp_lo = hr_afl(d$ref,"ev_resp")[2],
  afl_resp_hi = hr_afl(d$ref,"ev_resp")[3],
  c_index = cidx(d$ref), reach_preserved = NA, stringsAsFactors = FALSE)
res <- rbind(ref_row, res)
write.csv(res, file.path(HERE, "replacement_criteria_comparison.csv"), row.names = FALSE)

cat(sprintf("cohort n = %d; CT-only COPD-major (the group a CT-free rule must recover) = %d\n\n",
            nrow(d), sum(d$ct_only)))
cat("=== label reproduction ===\n")
print(res[, c("criterion","rule","n_aflonly","n_minor","n_major",
              "ct_only_recovered","macroF1_insample","macroF1_heldout")],
      row.names = FALSE, digits = 4)
cat("\n=== is the AFL-only label true? (adjusted, vs that rule's own noCOPD) ===\n")
for (i in seq_len(nrow(res))) cat(sprintf("  %-14s n=%4d  all-cause %.2f (%.2f-%.2f)  respiratory %5.2f (%.2f-%.2f)\n",
  res$criterion[i], res$n_aflonly[i], res$afl_all_HR[i], res$afl_all_lo[i], res$afl_all_hi[i],
  res$afl_resp_HR[i], res$afl_resp_lo[i], res$afl_resp_hi[i]))
cat("\n=== reach in preserved spirometry, and discrimination ===\n")
print(res[, c("criterion","reach_preserved","c_index")], row.names = FALSE, digits = 4)
