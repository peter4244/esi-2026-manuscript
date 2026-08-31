#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# EXPLORATORY ONLY. Writes nothing the manuscript reads.
#
# Question: the published ESI thresholds (T_low = 1.0, T_high = 2.5) agree with
# the CT-based MD-COPD classification in 91% of participants overall, but only
# 50.5% within COPD-minor and 12.4% within AFL-only-noCOPD. Can a different
# threshold pair do better on the two categories that MD-COPD invented?
#
# Why there is room to look. Neither selection step in the manuscript targeted
# category agreement. The rpart step fits ESI cut-points to
# struct_score = emph_yn + wall_yn, and the ten-candidate grid scores each
# variant on BINARY COPD-versus-noCOPD sensitivity, specificity and kappa. The
# binary objective is dominated by noCOPD and COPD-major, which are 86.6% of
# the cohort and already agree at 97.8% and 98.4%.
#
# Structure worth exploiting. Airflow limitation is defined identically in both
# frameworks, so nobody changes pathway and the 4x4 confusion matrix is block
# diagonal by construction:
#   * AFL pathway: AFL-only-noCOPD iff n_minor_e == 0, which requires
#     esi_score == 0. Depends on T_low ONLY; T_high cannot reach it.
#   * Preserved pathway: COPD-minor iff n_minor_e >= 3. Depends on both, and
#     T_high bites hard because scoring 2 leaves only one criterion to find.
# The current errors point in opposite directions through T_low (ESI yields 84
# AFL-only against CT's 170, wanting T_low up; 642 COPD-minor against 1,086,
# wanting it down), so the interesting region is high T_low with low T_high,
# which none of the ten published candidates visits.
#
# Usage:  Rscript explore_thresholds.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr)})

OUT <- file.path("exploration", "thresholds")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
source("config_paths.R")

CATS <- c("noCOPD", "AFL-only-NoCOPD", "COPD-minor", "COPD-major")
PUBLISHED <- c(low = 1.0, high = 2.5)
CV_REPEATS <- 5L
CV_FOLDS   <- 5L
CV_SEED    <- 20260901L

# ---------------------------------------------------------------------------
# Data prep. Mirrors the `ingest` and `cohort` chunks of the analysis, reduced
# to the columns a classification-agreement question needs: no vital status,
# no cause of death, no exacerbations. The published cohort size and agreement
# metrics are asserted below, so a divergence from the manuscript's data prep
# fails here rather than quietly producing a different cohort.
# ---------------------------------------------------------------------------
read_any <- function(path, ...) {
  hdr <- readLines(path, n = 1, warn = FALSE)
  sep <- if (grepl("\t", hdr)) "\t" else ","
  read.delim(path, sep = sep, stringsAsFactors = FALSE, ...)
}
bind_pid <- function(df, label) {
  cand <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit  <- cand[cand %in% names(df)]
  if (!length(hit)) stop("No identifier column in ", label)
  df$pid <- as.character(df[[hit[1]]])
  df
}

esi_raw <- bind_pid(read_any(ESI_PATH), "ESI_PATH")
phe_raw <- bind_pid(read_any(PHE_PATH, na.strings = c("", "NA")), "PHE_PATH")

is_ild  <- !is.na(phe_raw$cohort) & trimws(phe_raw$cohort) == "ILD/Brnch"
stopifnot(any(is_ild))
phe_raw <- phe_raw[!is_ild, ]

esi_v1 <- esi_raw %>%
  filter(visitnum == 1, PrePost == 1) %>%
  group_by(pid) %>%
  summarise(ESI_v1post = mean(ESI, na.rm = TRUE), .groups = "drop")

d_b <- esi_v1 %>%
  inner_join(phe_raw %>% filter(visitnum == 1), by = "pid") %>%
  mutate(major_criterion = FEV1_FVC_post < 0.70,
         emph_yn = CT_Visual_Emph_Severity >= 1,
         wall_yn = CT_Visual_Wall_Thickening == 2,
         dysp_yn = MMRCDyspneaScor >= 2,
         qol_yn  = SGRQ_scoreTotal >= 25,
         cb_yn   = Chronic_Bronchitis == 1) %>%
  filter(!is.na(major_criterion), !is.na(emph_yn), !is.na(wall_yn),
         !is.na(dysp_yn), !is.na(qol_yn), !is.na(cb_yn), !is.na(ESI_v1post))

n_minor_b <- d_b$emph_yn + d_b$wall_yn + d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn
d_b$bhatt_cls <- ifelse(d_b$major_criterion & n_minor_b >= 1, "COPD-major",
                 ifelse(!d_b$major_criterion & n_minor_b >= 3, "COPD-minor",
                 ifelse(d_b$major_criterion & n_minor_b == 0, "AFL-only-NoCOPD",
                        "noCOPD")))
d_b$bhatt_cls  <- factor(d_b$bhatt_cls, levels = CATS)
d_b$bhatt_copd <- d_b$bhatt_cls %in% c("COPD-major", "COPD-minor")
# The 0/1/2 structural count the ESI score was designed to stand in for.
d_b$struct_score <- as.integer(d_b$emph_yn) + as.integer(d_b$wall_yn)
# Everything the ESI classification needs except the ESI term itself.
d_b$other_minor <- d_b$dysp_yn + d_b$qol_yn + d_b$cb_yn

# ---------------------------------------------------------------------------
# Classification and metrics
# ---------------------------------------------------------------------------
esi_class <- function(df, t_low, t_high) {
  s <- ifelse(df$ESI_v1post >= t_high, 2L,
       ifelse(df$ESI_v1post >= t_low,  1L, 0L))
  n <- s + df$other_minor
  factor(ifelse(df$major_criterion & n >= 1, "COPD-major",
         ifelse(!df$major_criterion & n >= 3, "COPD-minor",
         ifelse(df$major_criterion & n == 0, "AFL-only-NoCOPD", "noCOPD"))),
         levels = CATS)
}

kappa_tab <- function(tab) {
  n  <- sum(tab)
  po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (pe == 1) return(NA_real_)
  (po - pe) / (1 - pe)
}

# Two-by-two kappa for one category against everything else.
kappa_ovr <- function(ref, est, cat) {
  kappa_tab(table(factor(ref == cat, c(FALSE, TRUE)),
                  factor(est == cat, c(FALSE, TRUE))))
}

score_pair <- function(df, t_low, t_high) {
  est <- esi_class(df, t_low, t_high)
  ref <- df$bhatt_cls
  tab <- table(ref, est)

  pres <- !df$major_criterion       # preserved-ratio pathway
  afl  <- df$major_criterion        # airflow-limitation pathway

  est_copd <- est %in% c("COPD-major", "COPD-minor")
  bin <- table(factor(df$bhatt_copd, c(FALSE, TRUE)),
               factor(est_copd,      c(FALSE, TRUE)))

  recall <- vapply(CATS, function(c) {
    d <- sum(ref == c)
    if (d == 0) NA_real_ else sum(ref == c & est == c) / d
  }, numeric(1))

  data.frame(
    t_low = t_low, t_high = t_high,
    kappa4 = kappa_tab(tab),
    agree4 = sum(diag(tab)) / sum(tab),
    # The two pathways are independent classification problems.
    kappa_preserved = kappa_ovr(ref[pres], est[pres], "COPD-minor"),
    kappa_afl       = kappa_ovr(ref[afl],  est[afl],  "AFL-only-NoCOPD"),
    recall_noCOPD     = recall[["noCOPD"]],
    recall_aflonly    = recall[["AFL-only-NoCOPD"]],
    recall_minor      = recall[["COPD-minor"]],
    recall_major      = recall[["COPD-major"]],
    n_minor_est = sum(est == "COPD-minor"),
    n_aflonly_est = sum(est == "AFL-only-NoCOPD"),
    # Reported for continuity with the published selection objective.
    bin_sens  = bin[2, 2] / sum(bin[2, ]),
    bin_spec  = bin[1, 1] / sum(bin[1, ]),
    bin_kappa = kappa_tab(bin),
    stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------
# 0. Validate the probe against the published numbers before trusting anything
# ---------------------------------------------------------------------------
pub <- score_pair(d_b, PUBLISHED[["low"]], PUBLISHED[["high"]])
cat(sprintf("cohort n = %d\n", nrow(d_b)))
cat(sprintf("published pair (%.1f, %.1f): agreement %.4f  kappa(binary) %.4f  sens %.4f  spec %.4f\n",
            PUBLISHED[["low"]], PUBLISHED[["high"]],
            pub$bin_sens * 0 + (sum(diag(table(d_b$bhatt_cls,
                                 esi_class(d_b, 1.0, 2.5)))) / nrow(d_b)),
            pub$bin_kappa, pub$bin_sens, pub$bin_spec))
stopifnot(nrow(d_b) == 9402L)
stopifnot(abs(pub$bin_kappa - 0.8205) < 5e-4)
stopifnot(abs(pub$bin_sens  - 0.8805) < 5e-4)
stopifnot(abs(pub$bin_spec  - 0.9444) < 5e-4)
stopifnot(abs(pub$agree4    - 0.9102) < 5e-4)
cat("probe validated against Table_Agreement_stats.txt\n\n")

# ---------------------------------------------------------------------------
# 1. Does esi_score reproduce the structural count it replaces?
# ---------------------------------------------------------------------------
esi_score_pub <- ifelse(d_b$ESI_v1post >= PUBLISHED[["high"]], 2L,
                 ifelse(d_b$ESI_v1post >= PUBLISHED[["low"]],  1L, 0L))
m1 <- table(struct_score = d_b$struct_score, esi_score = esi_score_pub)
cat("esi_score (published thresholds) against struct_score = emph_yn + wall_yn\n")
print(m1)
cat(sprintf("exact agreement %.3f   weighted kappa (linear) %.3f\n\n",
            sum(diag(m1)) / sum(m1),
            {w <- outer(0:2, 0:2, function(i, j) 1 - abs(i - j) / 2)
             n <- sum(m1); po <- sum(w * m1) / n
             pe <- sum(w * outer(rowSums(m1), colSums(m1)) / n^2); (po - pe) / (1 - pe)}))
write.csv(as.data.frame.matrix(m1), file.path(OUT, "01_esi_vs_struct_score.csv"))

# ---------------------------------------------------------------------------
# 2. Two-dimensional sweep
# ---------------------------------------------------------------------------
qs <- quantile(d_b$ESI_v1post, c(0.01, 0.995), na.rm = TRUE)
grid_t <- seq(floor(qs[1] * 4) / 4, ceiling(qs[2] * 4) / 4, by = 0.25)
cat(sprintf("ESI range %.2f to %.2f; sweeping %d cut-points from %.2f to %.2f\n",
            min(d_b$ESI_v1post), max(d_b$ESI_v1post),
            length(grid_t), min(grid_t), max(grid_t)))

pairs <- expand.grid(t_low = grid_t, t_high = grid_t)
pairs <- pairs[pairs$t_high >= pairs$t_low, ]
cat(sprintf("evaluating %d threshold pairs\n", nrow(pairs)))
sweep <- do.call(rbind, Map(function(a, b) score_pair(d_b, a, b),
                            pairs$t_low, pairs$t_high))
# A pair is only interesting if it is not worse than published on the two
# categories that already work.
sweep$holds_easy <- sweep$recall_noCOPD >= 0.95 & sweep$recall_major >= 0.95
sweep$balanced   <- pmin(sweep$kappa_preserved, sweep$kappa_afl)
write.csv(sweep, file.path(OUT, "02_threshold_sweep.csv"), row.names = FALSE)

show <- function(df, by, n = 8, label) {
  o <- df[order(-df[[by]]), ][seq_len(min(n, nrow(df))), ]
  cat("\n", label, "\n", sep = "")
  print(o[, c("t_low", "t_high", "kappa4", "agree4", "kappa_preserved",
              "kappa_afl", "recall_minor", "recall_aflonly",
              "recall_noCOPD", "recall_major")], row.names = FALSE, digits = 3)
}
cat("\npublished pair for reference:\n")
print(pub[, c("t_low", "t_high", "kappa4", "agree4", "kappa_preserved",
              "kappa_afl", "recall_minor", "recall_aflonly",
              "recall_noCOPD", "recall_major")], row.names = FALSE, digits = 3)
show(sweep, "kappa4", 8, "best by 4-category kappa")
show(sweep[sweep$holds_easy, ], "kappa_preserved", 8,
     "best by preserved-pathway kappa, holding noCOPD and COPD-major >= 0.95")
show(sweep[sweep$holds_easy, ], "balanced", 8,
     "best by min(preserved, AFL) kappa, holding the easy categories")

# ---------------------------------------------------------------------------
# 3. T_low alone governs the AFL pathway
# ---------------------------------------------------------------------------
afl_only <- sweep[sweep$t_high == max(grid_t), c("t_low", "kappa_afl",
                                                 "recall_aflonly", "n_aflonly_est")]
cat("\nAFL pathway as a function of T_low alone (T_high cannot reach it):\n")
print(afl_only[order(afl_only$t_low), ], row.names = FALSE, digits = 3)
write.csv(afl_only, file.path(OUT, "03_afl_pathway_by_tlow.csv"), row.names = FALSE)

# ---------------------------------------------------------------------------
# 4. Repeated stratified cross-validation
#
# The in-sample winner of a 2-D search over a 170-person category will be
# optimistic. Each fold re-selects thresholds on its training part and scores
# them on its held-out part, and the published pair is scored on the SAME held
# out part, so the comparison is paired and the difference is what matters.
# ---------------------------------------------------------------------------
set.seed(CV_SEED)
strata <- d_b$bhatt_cls
cv <- list()
for (rep in seq_len(CV_REPEATS)) {
  fold <- integer(nrow(d_b))
  for (lv in levels(strata)) {
    idx <- which(strata == lv)
    fold[idx] <- sample(rep_len(seq_len(CV_FOLDS), length(idx)))
  }
  for (k in seq_len(CV_FOLDS)) {
    tr <- d_b[fold != k, ]; te <- d_b[fold == k, ]
    trs <- do.call(rbind, Map(function(a, b) score_pair(tr, a, b),
                              pairs$t_low, pairs$t_high))
    for (obj in c("kappa4", "kappa_preserved")) {
      best <- trs[which.max(trs[[obj]]), ]
      sel  <- score_pair(te, best$t_low, best$t_high)
      ref  <- score_pair(te, PUBLISHED[["low"]], PUBLISHED[["high"]])
      cv[[length(cv) + 1]] <- data.frame(
        rep = rep, fold = k, objective = obj,
        t_low = best$t_low, t_high = best$t_high,
        test_kappa4 = sel$kappa4, pub_kappa4 = ref$kappa4,
        test_kappa_pres = sel$kappa_preserved, pub_kappa_pres = ref$kappa_preserved,
        test_kappa_afl = sel$kappa_afl, pub_kappa_afl = ref$kappa_afl,
        stringsAsFactors = FALSE)
    }
  }
}
cv <- do.call(rbind, cv)
write.csv(cv, file.path(OUT, "04_cv_folds.csv"), row.names = FALSE)

cat(sprintf("\nRepeated stratified CV: %d repeats x %d folds\n", CV_REPEATS, CV_FOLDS))
for (obj in unique(cv$objective)) {
  s <- cv[cv$objective == obj, ]
  d4 <- s$test_kappa4 - s$pub_kappa4
  dp <- s$test_kappa_pres - s$pub_kappa_pres
  da <- s$test_kappa_afl  - s$pub_kappa_afl
  cat(sprintf("\n  selection objective: %s\n", obj))
  cat(sprintf("    thresholds chosen: T_low %s | T_high %s\n",
              paste(names(sort(table(s$t_low), decreasing = TRUE))[1:3],
                    collapse = "/"),
              paste(names(sort(table(s$t_high), decreasing = TRUE))[1:3],
                    collapse = "/")))
  cat(sprintf("    held-out kappa4        retuned %.3f vs published %.3f  diff %+.3f (%+.3f to %+.3f)\n",
              mean(s$test_kappa4), mean(s$pub_kappa4), mean(d4),
              quantile(d4, .025), quantile(d4, .975)))
  cat(sprintf("    held-out kappa preserved retuned %.3f vs published %.3f  diff %+.3f (%+.3f to %+.3f)\n",
              mean(s$test_kappa_pres), mean(s$pub_kappa_pres), mean(dp),
              quantile(dp, .025), quantile(dp, .975)))
  cat(sprintf("    held-out kappa AFL       retuned %.3f vs published %.3f  diff %+.3f (%+.3f to %+.3f)\n",
              mean(s$test_kappa_afl), mean(s$pub_kappa_afl), mean(da),
              quantile(da, .025), quantile(da, .975)))
}
cat(sprintf("\nwrote %s\n", normalizePath(OUT)))
