#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# EXPLORATORY ONLY. Writes nothing the manuscript reads.
#
# explore_thresholds.R showed that no (T_low, T_high) pair improves agreement
# without destroying a category, because T_low does two unrelated jobs at once.
# In the preserved-ratio pathway a participant is COPD-minor when
# esi_score + other_minor >= 3, so:
#
#   other_minor = 3  ->  COPD-minor regardless of ESI
#   other_minor = 2  ->  needs esi_score >= 1   (governed by T_low)
#   other_minor = 1  ->  needs esi_score == 2   (governed by T_high)
#   other_minor = 0  ->  unreachable
#
# while in the airflow-limitation pathway AFL-only requires esi_score == 0,
# also governed by T_low. So T_low sets the bar for the other_minor = 2 group
# AND decides the AFL pathway, and the two want it to move in opposite
# directions. The published rule is therefore already a conditional-threshold
# rule; it just ties two unrelated conditions to one number.
#
# Model here: three free thresholds instead of two.
#
#   T_afl : AFL-only iff other_minor == 0 and ESI <  T_afl
#   T2    : COPD-minor iff other_minor == 2 and ESI >= T2
#   T1    : COPD-minor iff other_minor == 1 and ESI >= T1
#
# This is a strict generalization: the published rule is the special case
# T_afl = T2 = T_low, T1 = T_high, which is asserted below. Because the two
# pathways are disjoint sets of participants, the search separates into an
# independent 1-D problem (T_afl) and 2-D problem (T2, T1).
#
# Part 2 tests whether letting the preserved-pathway thresholds shift with
# FEV1 percent predicted adds anything on top.
#
# Usage:  Rscript explore_conditional_thresholds.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr)})

OUT <- file.path("exploration", "thresholds")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
source("config_paths.R")

CATS       <- c("noCOPD", "AFL-only-NoCOPD", "COPD-minor", "COPD-major")
PUB_LOW    <- 1.0
PUB_HIGH   <- 2.5
CV_REPEATS <- 5L
CV_FOLDS   <- 5L
CV_SEED    <- 20260901L

read_any <- function(p, ...) {
  h <- readLines(p, n = 1, warn = FALSE)
  read.delim(p, sep = if (grepl("\t", h)) "\t" else ",",
             stringsAsFactors = FALSE, ...)
}
bind_pid <- function(df, label) {
  cand <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit  <- cand[cand %in% names(df)]
  if (!length(hit)) stop("No identifier column in ", label)
  df$pid <- as.character(df[[hit[1]]]); df
}

esi_raw <- bind_pid(read_any(ESI_PATH), "ESI_PATH")
phe_raw <- bind_pid(read_any(PHE_PATH, na.strings = c("", "NA")), "PHE_PATH")
phe_raw <- phe_raw[!(!is.na(phe_raw$cohort) & trimws(phe_raw$cohort) == "ILD/Brnch"), ]

esi_v1 <- esi_raw %>%
  filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>%
  summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

d <- esi_v1 %>%
  inner_join(phe_raw %>% filter(visitnum == 1), by = "pid") %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2,
         qol_yn  = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn), !is.na(ESI_v1post))

nb <- d$emph_yn + d$wall_yn + d$dysp_yn + d$qol_yn + d$cb_yn
d$bhatt_cls <- factor(
  ifelse(d$major_criterion & nb >= 1, "COPD-major",
  ifelse(!d$major_criterion & nb >= 3, "COPD-minor",
  ifelse(d$major_criterion & nb == 0, "AFL-only-NoCOPD", "noCOPD"))), levels = CATS)
d$other_minor <- d$dysp_yn + d$qol_yn + d$cb_yn
stopifnot(nrow(d) == 9402L)

# ---------------------------------------------------------------------------
# Classification under the 3-threshold rule. `shift` lets a covariate move the
# preserved-pathway thresholds (Part 2); it is zero for the fixed-threshold
# model, in which case this reduces exactly to the published family.
# ---------------------------------------------------------------------------
classify3 <- function(df, t_afl, t2, t1, shift = 0) {
  e   <- df$ESI_v1post
  om  <- df$other_minor
  maj <- df$major_criterion
  minor <- (!maj) & ((om >= 3) |
                     (om == 2 & e >= (t2 + shift)) |
                     (om == 1 & e >= (t1 + shift)))
  aflo  <- maj & om == 0 & e < t_afl
  factor(ifelse(maj & !aflo, "COPD-major",
         ifelse(aflo, "AFL-only-NoCOPD",
         ifelse(minor, "COPD-minor", "noCOPD"))), levels = CATS)
}

kappa_tab <- function(tab) {
  n <- sum(tab); po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (pe == 1) NA_real_ else (po - pe) / (1 - pe)
}
kappa_ovr <- function(ref, est, cat)
  kappa_tab(table(factor(ref == cat, c(FALSE, TRUE)),
                  factor(est == cat, c(FALSE, TRUE))))

# ---- probe validation: the generalization must contain the published rule --
pub_cls <- {
  s <- ifelse(d$ESI_v1post >= PUB_HIGH, 2L, ifelse(d$ESI_v1post >= PUB_LOW, 1L, 0L))
  n <- s + d$other_minor
  factor(ifelse(d$major_criterion & n >= 1, "COPD-major",
         ifelse(!d$major_criterion & n >= 3, "COPD-minor",
         ifelse(d$major_criterion & n == 0, "AFL-only-NoCOPD", "noCOPD"))), levels = CATS)
}
stopifnot(identical(classify3(d, PUB_LOW, PUB_LOW, PUB_HIGH), pub_cls))
stopifnot(abs(sum(pub_cls == d$bhatt_cls) / nrow(d) - 0.9102) < 5e-4)
cat("probe validated: the 3-threshold family reproduces the published rule exactly\n")
cat(sprintf("cohort n = %d; published 4-category agreement %.4f\n\n",
            nrow(d), sum(pub_cls == d$bhatt_cls) / nrow(d)))

pub_k_afl  <- kappa_ovr(d$bhatt_cls[d$major_criterion],
                        pub_cls[d$major_criterion], "AFL-only-NoCOPD")
pub_k_pres <- kappa_ovr(d$bhatt_cls[!d$major_criterion],
                        pub_cls[!d$major_criterion], "COPD-minor")

# ---------------------------------------------------------------------------
# Part 1a: the AFL pathway, a 1-D problem in T_afl alone
# ---------------------------------------------------------------------------
grid_t <- seq(0.5, 10.0, by = 0.25)
afl <- d[d$major_criterion, ]
afl_res <- do.call(rbind, lapply(grid_t, function(t) {
  est <- classify3(afl, t, 0, 0)
  data.frame(t_afl = t,
             kappa_afl = kappa_ovr(afl$bhatt_cls, est, "AFL-only-NoCOPD"),
             n_est = sum(est == "AFL-only-NoCOPD"),
             n_ref = sum(afl$bhatt_cls == "AFL-only-NoCOPD"))
}))
best_afl <- afl_res[which.max(afl_res$kappa_afl), ]
cat(sprintf("AFL pathway (n=%d): best T_afl = %.2f, kappa %.3f (published %.3f)\n",
            nrow(afl), best_afl$t_afl, best_afl$kappa_afl, pub_k_afl))
write.csv(afl_res, file.path(OUT, "05_afl_pathway_3param.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# Part 1b: the preserved pathway, a 2-D problem in (T2, T1)
# ---------------------------------------------------------------------------
pres <- d[!d$major_criterion, ]
pg <- expand.grid(t2 = grid_t, t1 = grid_t)
pres_res <- do.call(rbind, Map(function(a, b) {
  est <- classify3(pres, 0, a, b)
  data.frame(t2 = a, t1 = b,
             kappa_pres = kappa_ovr(pres$bhatt_cls, est, "COPD-minor"),
             n_est = sum(est == "COPD-minor"))
}, pg$t2, pg$t1))
best_pres <- pres_res[which.max(pres_res$kappa_pres), ]
cat(sprintf("Preserved pathway (n=%d): best (T2, T1) = (%.2f, %.2f), kappa %.3f (published %.3f)\n",
            nrow(pres), best_pres$t2, best_pres$t1, best_pres$kappa_pres, pub_k_pres))
cat(sprintf("   COPD-minor n: fitted %d, published %d, CT reference %d\n\n",
            best_pres$n_est, sum(pub_cls[!d$major_criterion] == "COPD-minor"),
            sum(pres$bhatt_cls == "COPD-minor")))
write.csv(pres_res, file.path(OUT, "06_preserved_pathway_3param.csv"), row.names = FALSE)

full <- classify3(d, best_afl$t_afl, best_pres$t2, best_pres$t1)
cat(sprintf("Combined in-sample: 4-category kappa %.3f (published %.3f), agreement %.4f (published %.4f)\n\n",
            kappa_tab(table(d$bhatt_cls, full)), kappa_tab(table(d$bhatt_cls, pub_cls)),
            mean(full == d$bhatt_cls), mean(pub_cls == d$bhatt_cls)))

# ---------------------------------------------------------------------------
# Part 2: does an FEV1 percent-predicted shift add anything?
# ---------------------------------------------------------------------------
has_fev1 <- !is.na(d$FEV1pp_post)
cat(sprintf("FEV1pp available on %d of %d (%.1f%%)\n", sum(has_fev1), nrow(d),
            100 * mean(has_fev1)))
betas <- seq(-0.6, 0.6, by = 0.05)
dp <- d[!d$major_criterion & has_fev1, ]
dp$fshift <- (dp$FEV1pp_post - 100) / 10
fev_res <- do.call(rbind, lapply(betas, function(b) {
  est <- classify3(dp, 0, best_pres$t2, best_pres$t1, shift = b * dp$fshift)
  data.frame(beta = b, kappa_pres = kappa_ovr(dp$bhatt_cls, est, "COPD-minor"))
}))
best_fev <- fev_res[which.max(fev_res$kappa_pres), ]
base_fev <- fev_res[abs(fev_res$beta) < 1e-9, ]
cat(sprintf("FEV1pp threshold shift: best beta %+.2f gives kappa %.3f vs %.3f at beta = 0 (gain %+.3f)\n\n",
            best_fev$beta, best_fev$kappa_pres, base_fev$kappa_pres,
            best_fev$kappa_pres - base_fev$kappa_pres))
write.csv(fev_res, file.path(OUT, "07_fev1_shift.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# Part 3: repeated stratified CV. Every threshold is re-selected inside each
# training fold and scored on the held-out fold, against the published rule
# scored on the same fold, so the comparison is paired.
#
# The naive sweep re-classifies the whole fold for each of 1,521 (T2, T1)
# pairs and is far too slow. The three other_minor groups that the preserved
# rule touches are disjoint, so the confusion matrix is additive over them:
# other_minor >= 3 is always COPD-minor, other_minor == 0 never is, and the
# == 2 and == 1 groups are governed by T2 and T1 separately. Tabulating each
# group once against the threshold grid turns the 2-D sweep into arithmetic.
# ---------------------------------------------------------------------------
pres_tables <- function(df) {
  ref <- df$bhatt_cls == "COPD-minor"
  om  <- df$other_minor
  e   <- df$ESI_v1post
  cnt <- function(sel) {
    # counts of reference-positive and reference-negative at ESI >= t
    list(a = vapply(grid_t, function(t) sum(ref[sel] & e[sel] >= t), numeric(1)),
         b = vapply(grid_t, function(t) sum(!ref[sel] & e[sel] >= t), numeric(1)),
         R = sum(ref[sel]), N = sum(!ref[sel]))
  }
  list(g3 = c(a = sum(ref & om >= 3), b = sum(!ref & om >= 3)),
       g0 = c(a = sum(ref & om == 0), b = sum(!ref & om == 0)),
       g2 = cnt(om == 2), g1 = cnt(om == 1))
}

pres_kappa_grid <- function(tb) {
  # outer over the T2 and T1 indices; every quantity is already tabulated
  TP <- outer(tb$g2$a, tb$g1$a, "+") + tb$g3[["a"]]
  FP <- outer(tb$g2$b, tb$g1$b, "+") + tb$g3[["b"]]
  FN <- outer(tb$g2$R - tb$g2$a, tb$g1$R - tb$g1$a, "+") + tb$g0[["a"]]
  TN <- outer(tb$g2$N - tb$g2$b, tb$g1$N - tb$g1$b, "+") + tb$g0[["b"]]
  n  <- TP + FP + FN + TN
  po <- (TP + TN) / n
  pe <- ((TP + FN) * (TP + FP) + (FP + TN) * (FN + TN)) / n^2
  (po - pe) / (1 - pe)
}

afl_kappa_grid <- function(df) {
  a <- df[df$major_criterion, ]
  ref <- a$bhatt_cls == "AFL-only-NoCOPD"
  sel <- a$other_minor == 0
  e <- a$ESI_v1post
  vapply(grid_t, function(t) {
    est <- sel & e < t
    kappa_tab(table(factor(ref, c(FALSE, TRUE)), factor(est, c(FALSE, TRUE))))
  }, numeric(1))
}

# The fast grid must agree with the direct classifier it replaces.
.chk_t <- pres_kappa_grid(pres_tables(pres))
.i <- which(abs(grid_t - 2.0) < 1e-9); .j <- which(abs(grid_t - 3.5) < 1e-9)
.direct <- kappa_ovr(pres$bhatt_cls, classify3(pres, 0, 2.0, 3.5), "COPD-minor")
stopifnot(abs(.chk_t[.i, .j] - .direct) < 1e-12)
stopifnot(abs(max(.chk_t) - best_pres$kappa_pres) < 1e-12)
cat("fast grid validated against the direct classifier\n\n")

set.seed(CV_SEED)
rows <- list()
for (rep in seq_len(CV_REPEATS)) {
  fold <- integer(nrow(d))
  for (lv in levels(d$bhatt_cls)) {
    ix <- which(d$bhatt_cls == lv)
    fold[ix] <- sample(rep_len(seq_len(CV_FOLDS), length(ix)))
  }
  for (k in seq_len(CV_FOLDS)) {
    tr <- d[fold != k, ]; te <- d[fold == k, ]

    ta <- grid_t[which.max(afl_kappa_grid(tr))]
    kg <- pres_kappa_grid(pres_tables(tr[!tr$major_criterion, ]))
    bi <- which(kg == max(kg, na.rm = TRUE), arr.ind = TRUE)[1, ]
    t2 <- grid_t[bi[1]]; t1 <- grid_t[bi[2]]

    est <- classify3(te, ta, t2, t1)
    ref <- classify3(te, PUB_LOW, PUB_LOW, PUB_HIGH)
    tem <- te$major_criterion
    rows[[length(rows) + 1]] <- data.frame(
      rep = rep, fold = k, t_afl = ta, t2 = t2, t1 = t1,
      k4        = kappa_tab(table(te$bhatt_cls, est)),
      k4_pub    = kappa_tab(table(te$bhatt_cls, ref)),
      kpres     = kappa_ovr(te$bhatt_cls[!tem], est[!tem], "COPD-minor"),
      kpres_pub = kappa_ovr(te$bhatt_cls[!tem], ref[!tem], "COPD-minor"),
      kafl      = kappa_ovr(te$bhatt_cls[tem], est[tem], "AFL-only-NoCOPD"),
      kafl_pub  = kappa_ovr(te$bhatt_cls[tem], ref[tem], "AFL-only-NoCOPD"),
      n_aflonly = sum(est == "AFL-only-NoCOPD"),
      n_minor   = sum(est == "COPD-minor"),
      stringsAsFactors = FALSE)
  }
}
cv <- do.call(rbind, rows)
write.csv(cv, file.path(OUT, "08_cv_3param.csv"), row.names = FALSE)

cat(sprintf("Repeated stratified CV: %d repeats x %d folds\n", CV_REPEATS, CV_FOLDS))
cat(sprintf("  thresholds chosen: T_afl %s | T2 %s | T1 %s\n",
            paste(names(sort(table(cv$t_afl), decreasing = TRUE))[1:2], collapse = "/"),
            paste(names(sort(table(cv$t2),    decreasing = TRUE))[1:2], collapse = "/"),
            paste(names(sort(table(cv$t1),    decreasing = TRUE))[1:2], collapse = "/")))
for (m in list(c("k4", "k4_pub", "4-category kappa"),
               c("kpres", "kpres_pub", "preserved-pathway kappa"),
               c("kafl", "kafl_pub", "AFL-pathway kappa"))) {
  dd <- cv[[m[1]]] - cv[[m[2]]]
  cat(sprintf("  %-26s retuned %.3f vs published %.3f  diff %+.3f (%+.3f to %+.3f)\n",
              m[3], mean(cv[[m[1]]]), mean(cv[[m[2]]]), mean(dd),
              quantile(dd, .025), quantile(dd, .975)))
}
cat(sprintf("\n  held-out category counts, summed over folds within a repeat:\n"))
cat(sprintf("    AFL-only   fitted %.0f vs CT reference %d\n",
            sum(cv$n_aflonly) / CV_REPEATS, sum(d$bhatt_cls == "AFL-only-NoCOPD")))
cat(sprintf("    COPD-minor fitted %.0f vs CT reference %d\n",
            sum(cv$n_minor) / CV_REPEATS, sum(d$bhatt_cls == "COPD-minor")))

cat(sprintf("\nwrote %s\n", normalizePath(OUT)))
