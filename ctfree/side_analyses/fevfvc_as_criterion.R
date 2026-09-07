#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# SIDE ANALYSIS. Not part of the manuscript pipeline: nothing here is read by
# the analysis report, the claims registry or the document builders.
#
# Question: ESI never out-discriminates FEV1/FVC for either visual CT
# criterion, so why not use FEV1/FVC itself as the replacement minor
# criterion instead of ESI?
#
# The objection has a structural answer and an empirical one, and this script
# supplies the empirical one. Structurally, FEV1/FVC < 0.70 is already the
# MAJOR criterion, so a minor criterion built on a threshold above 0.70 fires
# for every participant with airflow limitation, collapsing AFL-only to zero
# and destroying the correction the framework exists to make. A threshold
# below 0.70 avoids that but can only ever act within the airflow-limitation
# group, since nobody with preserved spirometry meets it.
#
# This sweeps the threshold across both regimes, fits by the same objective
# (macro-averaged F1 over the four MD-COPD categories) and the same count
# grid used in the paper, and reports what the best FEV1/FVC-based rule
# achieves against the ESI-based one.
#
# Usage:  Rscript ctfree/side_analyses/fevfvc_as_criterion.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr)})

.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- dirname(normalizePath(sub("^--file=", "", .b[1])))
ROOT <- dirname(dirname(HERE))
source(file.path(ROOT, "config_paths.R"))

read_any <- function(p, ...) { h <- readLines(p, n = 1, warn = FALSE)
  read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE, ...) }
bp <- function(d) { d$pid <- as.character(
  d[[intersect(c(ID_COL, paste0(ID_COL, ".x")), names(d))[1]]]); d }

phe <- bp(read_any(PHE_PATH, na.strings = c("", "NA")))
mdc <- bp(read_any(MDCOPD_PATH))
esi <- bp(read_any(ESI_PATH))

v1 <- phe[phe$visitnum == 1, ]
b  <- v1[is.na(v1$ExclusionaryDisease), ]
b  <- b[trimws(b$cohort) != "Never smoked", ]
b  <- b[!is.na(b$FEV1_FVC_post), ]
b  <- merge(b, mdc[!is.na(mdc$MultiDim_COPD_score), c("pid", "MultiDim_COPD_score")], by = "pid")
ev <- esi %>% filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>% summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
d  <- merge(b, ev, by = "pid"); d <- d[!is.na(d$ESI), ]

f <- function(x) { x[is.na(x)] <- FALSE; x }
d$om  <- f(d$MMRCDyspneaScor >= 2) + f(d$SGRQ_scoreTotal >= 25) + f(d$Chronic_Bronchitis == 1)
d$afl <- d$FEV1_FVC_post < 0.70

O <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")
ref <- factor(ifelse(d$MultiDim_COPD_score == 1, "COPD-major",
              ifelse(d$MultiDim_COPD_score == 2, "COPD-minor",
              ifelse(d$afl, "AFL-only", "noCOPD"))), levels = O)
lab <- function(minor, aflo) factor(
  ifelse(d$afl & !aflo, "COPD-major", ifelse(d$afl & aflo, "AFL-only",
  ifelse(!d$afl & minor, "COPD-minor", "noCOPD"))), levels = O)
macroF1 <- function(est) mean(vapply(O, function(g) {
  tp <- sum(ref == g & est == g); if (tp == 0) return(0)
  2 * tp / (sum(est == g) + sum(ref == g)) }, numeric(1)))

# A criterion built on a continuous measure m, met at or below threshold t
# (for FEV1/FVC, lower is worse) or at or above t (for ESI).
rule <- function(score, t, k, higher_is_worse) {
  s <- as.integer(if (higher_is_worse) score >= t else score <= t)
  lab((s + d$om) >= k, (s + d$om) == 0)
}

cat(sprintf("cohort n = %d   reference: noCOPD %d, AFL-only %d, COPD-minor %d, COPD-major %d\n\n",
            nrow(d), sum(ref == "noCOPD"), sum(ref == "AFL-only"),
            sum(ref == "COPD-minor"), sum(ref == "COPD-major")))

row <- function(tag, est) data.frame(
  rule = tag, noCOPD = sum(est == "noCOPD"), AFL_only = sum(est == "AFL-only"),
  COPD_minor = sum(est == "COPD-minor"), COPD_major = sum(est == "COPD-major"),
  macroF1 = macroF1(est), stringsAsFactors = FALSE)

out <- list()
for (k in 1:3) for (t in seq(0.50, 0.85, by = 0.05))
  out[[length(out) + 1]] <- cbind(k = k, threshold = t,
    row(sprintf("FEV1/FVC <= %.2f, k=%d", t, k), rule(d$FEV1_FVC_post, t, k, FALSE)))
ff <- do.call(rbind, out)

cat("--- FEV1/FVC as the replacement minor criterion ---\n")
cat("Thresholds at or above 0.70 fire for everyone with airflow limitation:\n")
print(ff[ff$threshold >= 0.70 & ff$k == 2,
         c("threshold", "noCOPD", "AFL_only", "COPD_minor", "COPD_major", "macroF1")],
      row.names = FALSE, digits = 3)
cat("\nBest FEV1/FVC-based rule over the whole grid:\n")
best_ff <- ff[which.max(ff$macroF1), ]
print(best_ff[, c("k", "threshold", "noCOPD", "AFL_only", "COPD_minor", "COPD_major", "macroF1")],
      row.names = FALSE, digits = 3)

cat("\n--- comparators, same objective and count grid ---\n")
esi_best <- NULL
for (k in 1:3) for (t in seq(0.50, 4.00, by = 0.25)) {
  r <- cbind(k = k, threshold = t, row("esi", rule(d$ESI, t, k, TRUE)))
  if (is.null(esi_best) || r$macroF1 > esi_best$macroF1) esi_best <- r
}
noct <- NULL
for (k in 1:3) {
  r <- cbind(k = k, threshold = NA_real_, row("noct", lab(d$om >= k, d$om == 0)))
  if (is.null(noct) || r$macroF1 > noct$macroF1) noct <- r
}
cmp <- rbind(
  transform(noct,     rule = sprintf("NoCT-MD-COPD, k=%d", k)),
  transform(best_ff,  rule = sprintf("FEV1/FVC <= %.2f, k=%d", threshold, k)),
  transform(esi_best, rule = sprintf("ESI >= %.2f, k=%d", threshold, k)))
print(cmp[, c("rule", "noCOPD", "AFL_only", "COPD_minor", "COPD_major", "macroF1")],
      row.names = FALSE, digits = 3)

cat("\n--- how many participants can an FEV1/FVC minor criterion reach? ---\n")
cat(sprintf("  preserved spirometry (FEV1/FVC >= 0.70): %d\n", sum(!d$afl)))
cat(sprintf("  of those, FEV1/FVC <= %.2f (best threshold): %d\n",
            best_ff$threshold, sum(!d$afl & d$FEV1_FVC_post <= best_ff$threshold)))
cat(sprintf("  of those, ESI >= 1.50: %d\n", sum(!d$afl & d$ESI >= 1.50)))

# ---------------------------------------------------------------------------
# Label agreement is not the paper's criterion. The AFL-only category has to be
# genuinely low risk, so compare the three rules on that, not on macro-F1.
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(survival)})
vs  <- bp(read_any(VS_PATH)); cod <- bp(read_any(COD_PATH))
u <- suppressWarnings(as.integer(cod$Torch_Group_Basic))
cod$UCD_Resp <- as.integer(!is.na(u) & u == 1L)

d$S_noct <- lab(d$om >= 2, d$om == 0)
d$S_ff   <- rule(d$FEV1_FVC_post, 0.65, 2, FALSE)
d$S_esi  <- rule(d$ESI, 1.50, 2, TRUE)

m <- d %>%
  inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp), by = "pid") %>%
  mutate(ev_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0),
         py = days_followed / 365.25) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
COV <- "age_visit + factor(gender) + factor(race) + factor(SmokCigNow) + ATS_PackYears + BMI"

cat("\n--- AFL-only: is the label true under each rule? ---\n")
cat("    (adjusted HR against that rule's own noCOPD group)\n\n")
for (nm in c("S2ref", "S_noct", "S_ff", "S_esi")) {
  m$g <- if (nm == "S2ref") factor(ref[match(m$pid, d$pid)], levels = O) else
         factor(m[[nm]], levels = O)
  fit  <- coxph(as.formula(paste("Surv(py, vital_status) ~ g +", COV)), data = m)
  fitr <- coxph(as.formula(paste("Surv(py, ev_resp) ~ g +", COV)), data = m)
  ci <- summary(fit)$conf.int; cr <- summary(fitr)$conf.int
  r <- "gAFL-only"
  lbl <- c(S2ref = "MD-COPD (reference)", S_noct = "NoCT-MD-COPD",
           S_ff = "FEV1/FVC <= 0.65", S_esi = "ESI >= 1.50")[[nm]]
  cat(sprintf("  %-20s n=%4d  all-cause %.2f (%.2f-%.2f)   respiratory %.2f (%.2f-%.2f)\n",
      lbl, sum(m$g == "AFL-only"),
      ci[r,1], ci[r,3], ci[r,4], cr[r,1], cr[r,3], cr[r,4]))
}

# ---------------------------------------------------------------------------
# The decisive question: does ESI contribute anything once a second FEV1/FVC
# threshold is already available as a minor criterion?
# ---------------------------------------------------------------------------
cat("\n--- does ESI add beyond a second FEV1/FVC threshold? ---\n")
best <- list(f1 = -Inf)
for (k in 2:4) for (tf in seq(0.50, 0.69, by = 0.01)) for (te in seq(0.50, 4.00, by = 0.25)) {
  s <- as.integer(d$FEV1_FVC_post <= tf) + as.integer(d$ESI >= te)
  est <- lab((s + d$om) >= k, (s + d$om) == 0)
  f1 <- macroF1(est)
  if (f1 > best$f1) best <- list(f1 = f1, k = k, tf = tf, te = te, est = est)
}
cat(sprintf("  FEV1/FVC alone, best        : macro-F1 %.4f\n", max(ff$macroF1)))
cat(sprintf("  ESI alone, best             : macro-F1 %.4f\n", esi_best$macroF1))
cat(sprintf("  both together, best         : macro-F1 %.4f  (FEV1/FVC <= %.2f, ESI >= %.2f, k=%d)\n",
            best$f1, best$tf, best$te, best$k))
cat(sprintf("  gain from adding ESI        : %+.4f\n", best$f1 - max(ff$macroF1)))
