# compare_recompute.R -- laptop-side comparison of the cluster recomputation
# (recompute_ctfree.R output) against the analysis's aggregate tables.
#
#   Rscript compare_recompute.R <rc_outdir> [assets_dir ...] [--write <file.csv>]
#
# <rc_outdir>   the folder of rc_*.csv files returned from Channing
# assets_dir    one or more folders of analysis tables. Default: ctfree/assets
#               and, if present, the cluster run's copy
#               notes/from_cluster/esi_ctfree/cluster_assets_6116301
#               (paths relative to the repository root, found from this
#               script's location).
# --write f     also write every compared value to f (never overwrites).
#
# Reads only aggregate CSVs. Prints, per table, every value whose difference
# exceeds its tolerance, then a summary. Tolerances:
#   counts                      exact
#   deterministic real numbers  relative 1e-6 (rates, means, AUC, medians)
#   model estimates             relative 1e-4 (Cox, negative binomial: the
#                               iterative fits can differ in late digits)
#   Table S1 strings            half a unit of the last printed digit

options(stringsAsFactors = FALSE, warn = 1)
a <- commandArgs(trailingOnly = TRUE)
wi <- which(a == "--write"); WRITE <- NULL
if (length(wi)) { WRITE <- a[wi + 1]; a <- a[-c(wi, wi + 1)] }
if (!length(a)) stop("usage: Rscript compare_recompute.R <rc_outdir> [assets_dir ...] [--write f.csv]")
RC <- a[1]
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
HERE <- if (!is.na(.f)) dirname(normalizePath(.f)) else getwd()
ROOT <- normalizePath(file.path(HERE, "..", "..", ".."))
ASSETS <- if (length(a) > 1) a[-1] else {
  c(file.path(ROOT, "ctfree", "assets"),
    Filter(dir.exists, file.path(ROOT, "notes", "from_cluster", "esi_ctfree", "cluster_assets_6116301")))
}

rc <- function(n) {
  p <- file.path(RC, paste0("rc_", n, ".csv"))
  if (!file.exists(p)) { cat("  (missing ", basename(p), ")\n", sep = ""); return(NULL) }
  read.csv(p, check.names = FALSE)
}

ALL <- list()
# Compare value columns of two data frames joined on keys.
# pairs: named character, names = rc column, values = asset column.
# kind: "count" | "real" | "model"
cmp <- function(table, R, A, keys, pairs, kind, adir) {
  if (is.null(R) || is.null(A)) return(invisible(NULL))
  M <- merge(R, A, by = keys, suffixes = c(".rc", ".asset"), all = TRUE)
  out <- list()
  for (rcn in names(pairs)) {
    asn <- pairs[[rcn]]
    rv <- if (paste0(rcn, ".rc") %in% names(M)) M[[paste0(rcn, ".rc")]] else M[[rcn]]
    av <- if (paste0(asn, ".asset") %in% names(M)) M[[paste0(asn, ".asset")]] else M[[asn]]
    rv <- suppressWarnings(as.numeric(rv)); av <- suppressWarnings(as.numeric(av))
    k <- kind[[min(length(kind), match(rcn, names(pairs)))]]
    tol <- switch(k, count = 0, real = 1e-6, model = 1e-4)
    diff <- rv - av
    rel <- abs(diff) / pmax(abs(av), 1e-12)
    ok <- if (k == "count") (!is.na(diff) & diff == 0) else
      (!is.na(diff) & (abs(diff) < 1e-12 | rel <= tol)) | (is.na(rv) & is.na(av))
    ok[is.infinite(rv) & is.infinite(av)] <- TRUE
    out[[length(out) + 1]] <- data.frame(
      assets = basename(adir), table = table,
      key = do.call(paste, c(lapply(keys, function(z) M[[z]]), sep = " | ")),
      field = rcn, recomputed = rv, analysis = av, diff = diff, tolerance = k, ok = ok)
  }
  out <- do.call(rbind, out)
  ALL[[length(ALL) + 1]] <<- out
  bad <- out[!out$ok, ]
  cat(sprintf("%-28s %4d values, %3d beyond tolerance\n", table, nrow(out), nrow(bad)))
  if (nrow(bad)) print(bad[, c("key", "field", "recomputed", "analysis", "diff")],
                       row.names = FALSE, digits = 8)
  invisible(out)
}

# "57.2 (8.3)" -> c(57.2, 8.3); "54%" -> 54
parse_msd <- function(s, i) as.numeric(sub("^\\s*([-0-9.]+)\\s*\\(([-0-9.]+)\\).*$", paste0("\\", i), s))
parse_pct <- function(s) as.numeric(sub("%", "", s))
cmp_rounded <- function(table, R, A, key, pairs, adir) {
  M <- merge(R, A, by = key, suffixes = c(".rc", ".asset"))
  col <- function(nm, suf) if (paste0(nm, suf) %in% names(M)) M[[paste0(nm, suf)]] else M[[nm]]
  out <- list()
  for (p in pairs) {
    rv <- as.numeric(col(p$rc, ".rc")); av <- p$parse(col(p$asset, ".asset")); half <- 0.5 * 10^(-p$dp) + 1e-9
    out[[length(out) + 1]] <- data.frame(
      assets = basename(adir), table = table, key = M[[key]], field = p$rc,
      recomputed = rv, analysis = av, diff = rv - av, tolerance = paste0("printed ", p$dp, " dp"),
      ok = !is.na(rv) & !is.na(av) & abs(rv - av) <= half)
  }
  out <- do.call(rbind, out); ALL[[length(ALL) + 1]] <<- out
  bad <- out[!out$ok, ]
  cat(sprintf("%-28s %4d values, %3d beyond tolerance\n", table, nrow(out), nrow(bad)))
  if (nrow(bad)) print(bad[, c("key", "field", "recomputed", "analysis", "diff")], row.names = FALSE)
}

for (AD in ASSETS) {
  cat("\n================================================================\n")
  cat("Recomputed:", normalizePath(RC), "\nAgainst:   ", normalizePath(AD), "\n")
  cat("================================================================\n")
  as <- function(n) { p <- file.path(AD, paste0(n, ".csv"))
    if (!file.exists(p)) { cat("  (no ", basename(p), ")\n", sep = ""); return(NULL) }
    read.csv(p, check.names = FALSE) }

  cmp("cohort_flow", rc("cohort_flow"), as("cohort_flow"), "step", c(n = "n"), "count", AD)
  cmp("mdcopd_validation", rc("mdcopd_validation"), as("mdcopd_validation"), "category",
      c(ours = "ours"), "count", AD)
  cmp("schema_labels", rc("schema_labels"), as("schema_labels"), c("schema", "category"),
      c(n = "n"), "count", AD)
  cmp("crossclass", rc("crossclass"), as("crossclass"), c("schema", "row_cat", "col_cat"),
      c(n = "n"), "count", AD)

  ag <- as("agreement_by_group")
  if (!is.null(ag)) {
    L <- rbind(data.frame(schema = "S3", category = ag$category, n_ref = ag$n_md,
                          n_assigned = ag$n_noct, n_agree = ag$agree_noct,
                          sensitivity_pct = ag$recall_noct, ppv_pct = ag$pct_noct),
               data.frame(schema = "S4", category = ag$category, n_ref = ag$n_md,
                          n_assigned = ag$n_esi, n_agree = ag$agree_esi,
                          sensitivity_pct = ag$recall_esi, ppv_pct = ag$pct_esi))
    R <- rc("agreement"); R <- R[R$category != "overall", ]
    cmp("agreement_by_group", R, L, c("schema", "category"),
        c(n_ref = "n_ref", n_assigned = "n_assigned", n_agree = "n_agree",
          sensitivity_pct = "sensitivity_pct", ppv_pct = "ppv_pct"),
        c("count", "count", "count", "real", "real"), AD)
  }
  f1 <- as("f1_by_category")
  if (!is.null(f1)) {
    L <- rbind(data.frame(schema = "S3", category = f1$category, f1 = f1$f1_noct),
               data.frame(schema = "S4", category = f1$category, f1 = f1$f1_esi))
    R <- rc("agreement"); R <- R[R$category != "overall", c("schema", "category", "f1")]
    cmp("f1_by_category", R, L, c("schema", "category"), c(f1 = "f1"), "real", AD)
  }
  at <- as("accuracy_test")
  if (!is.null(at)) {
    R <- rc("accuracy_test"); R$k <- 1; at$k <- 1
    cmp("accuracy_test", R, at, "k",
        c(n = "n", correct_noct = "correct_noct", correct_esi = "correct_esi",
          only_esi_correct = "only_esi_correct", only_noct_correct = "only_noct_correct",
          mcnemar_chisq_uncorrected = "chisq"),
        c("count", "count", "count", "count", "count", "real"), AD)
  }
  cmp("reclassification", rc("reclassification"), as("reclassification"), "schema",
      c(major_to_aflonly = "major_to_aflonly", minor_to_nocopd = "minor_to_nocopd",
        nocopd_to_minor = "nocopd_to_minor"), "count", AD)
  sf <- as("schema_fit")
  if (!is.null(sf)) {
    R <- rc("fit_selected")
    cmp("schema_fit (selected)", R, sf[sf$schema %in% c("S3", "S4"), ], "schema",
        c(k = "k", t_low = "t_low", macroF1 = "macroF1_insample"),
        c("count", "real", "real"), AD)
  }
  cmp("bronchodilator_delta_esi", transform(rc("bronchodilator_delta_esi"), k = 1),
      transform(as("bronchodilator_delta_esi"), k = 1), "k",
      c(n_paired = "n_paired", mean_delta = "mean_delta", sd_delta = "sd_delta"),
      c("count", "real", "real"), AD)

  sb <- as("supp_baseline"); R <- rc("supp_baseline")
  if (!is.null(sb) && !is.null(R)) {
    m1 <- function(i) function(s) parse_msd(s, i)
    P <- list(
      list(rc = "n", asset = "n", parse = as.numeric, dp = 0),
      list(rc = "age_mean", asset = "age", parse = m1(1), dp = 1),
      list(rc = "age_sd", asset = "age", parse = m1(2), dp = 1),
      list(rc = "pct_female", asset = "pct_female", parse = parse_pct, dp = 0),
      list(rc = "pct_current", asset = "pct_current", parse = parse_pct, dp = 0),
      list(rc = "packyears_mean", asset = "pack_years", parse = m1(1), dp = 1),
      list(rc = "packyears_sd", asset = "pack_years", parse = m1(2), dp = 1),
      list(rc = "BMI_mean", asset = "BMI", parse = m1(1), dp = 1),
      list(rc = "BMI_sd", asset = "BMI", parse = m1(2), dp = 1),
      list(rc = "FEV1pp_mean", asset = "FEV1_pp", parse = m1(1), dp = 1),
      list(rc = "FEV1pp_sd", asset = "FEV1_pp", parse = m1(2), dp = 1),
      list(rc = "FEV1FVC_mean", asset = "FEV1_FVC", parse = m1(1), dp = 2),
      list(rc = "FEV1FVC_sd", asset = "FEV1_FVC", parse = m1(2), dp = 2),
      list(rc = "ESI_mean", asset = "ESI", parse = m1(1), dp = 2),
      list(rc = "ESI_sd", asset = "ESI", parse = m1(2), dp = 2),
      list(rc = "pct_mMRC2", asset = "pct_mMRC2p", parse = parse_pct, dp = 0),
      list(rc = "pct_SGRQ25", asset = "pct_SGRQ25p", parse = parse_pct, dp = 0),
      list(rc = "pct_CB", asset = "pct_CB", parse = parse_pct, dp = 0))
    cmp_rounded("supp_baseline (Table S1)", R, sb, "stratum", P, AD)
  }

  R <- rc("esi_ct_levels"); if (!is.null(R)) R <- R[!is.na(R$level), ]
  cmp("esi_ct_levels", R, as("esi_ct_levels"), c("criterion", "level"),
      c(n = "n", mean_ESI = "mean_ESI"), c("count", "real"), AD)
  R <- rc("esi_ct_auc")
  if (!is.null(R)) {
    cmp("esi_ct_auc (missing=neg)", R[R$missing_handling == "missing_as_negative", ],
        as("esi_ct_auc"), c("stratum", "criterion"),
        c(n = "n", prevalence = "prevalence", auc_ESI = "auc_ESI", auc_FEV1FVC = "auc_FEV1FVC"),
        c("count", "real", "real", "real"), AD)
  }

  cmp("consensus_ref_group", transform(rc("consensus_ref_group"), k = 1),
      transform(as("consensus_ref_group"), k = 1), "k",
      c(n_cohort = "n_cohort", n_mort = "n_mort", n_exac = "n_exac", deaths = "deaths",
        resp_deaths = "resp_deaths", exac_events = "exac_events",
        person_yrs = "person_yrs", fu_yrs = "fu_yrs"),
      c(rep("count", 6), "real", "real"), AD)
  R <- rc("consensus_ref_crude")
  if (!is.null(R)) {
    R$lo[R$outcome == "exac"] <- NA; R$hi[R$outcome == "exac"] <- NA
    A <- as("consensus_ref_crude")
    if (!is.null(A)) { A$lo[A$outcome == "exac"] <- NA; A$hi[A$outcome == "exac"] <- NA }
    cmp("consensus_ref_crude", R, A, c("schema", "category", "outcome"),
        c(events = "events", rate_100py = "rate_100py", rr = "rr", lo = "lo", hi = "hi"),
        c("count", "real", "real", "real", "real"), AD)
  }
  cmp("consensus_ref_risk", rc("consensus_ref_risk"), as("consensus_ref_risk"),
      c("schema", "category"),
      c(n_mort = "n_mort", n_exac = "n_exac", deaths = "deaths", resp_deaths = "resp_deaths",
        all_HR = "all_HR", all_LCI = "all_LCI", all_UCI = "all_UCI",
        resp_HR = "resp_HR", resp_LCI = "resp_LCI", resp_UCI = "resp_UCI",
        exac_IRR = "exac_IRR", exac_LCI = "exac_LCI", exac_UCI = "exac_UCI"),
      c(rep("count", 4), rep("model", 9)), AD)
  cmp("followup_medians", rc("followup_medians"), as("followup_medians"), "outcome",
      c(n = "n", median_yr = "median_yr", q1_yr = "q1_yr", q3_yr = "q3_yr"),
      c("count", "real", "real", "real"), AD)
}

# Counts stated in METHODS.md prose (fixed values, not read from assets).
cat("\n---- METHODS.md stated counts ----\n")
D <- rc("diagnostics"); L <- rc("schema_labels"); G <- rc("consensus_ref_group")
if (!is.null(D) && !is.null(L) && !is.null(G)) {
  dv <- function(k) as.numeric(D$value[D$key == k])
  st <- data.frame(
    statement = c("analysis included 9,240", "mortality analyses 9,238",
                  "exacerbation analyses 8,177", "common reference n 3,856"),
    stated = c(9240, 9238, 8177, 3856),
    recomputed = c(sum(L$n[L$schema == "S2"]), dv("mort_n"), dv("exac_n"), G$n_cohort))
  st$ok <- st$stated == st$recomputed
  print(st, row.names = FALSE)
  ALL[[length(ALL) + 1]] <- data.frame(assets = "METHODS.md", table = "stated counts",
    key = st$statement, field = "n", recomputed = st$recomputed, analysis = st$stated,
    diff = st$recomputed - st$stated, tolerance = "count", ok = st$ok)
}

res <- do.call(rbind, ALL)
cat("\n==== SUMMARY ====\n")
sm <- aggregate(cbind(values = 1, beyond = !res$ok) ~ assets + table, data = res, FUN = sum)
print(sm, row.names = FALSE)
cat(sprintf("\nTotal: %d values compared, %d beyond tolerance\n", nrow(res), sum(!res$ok)))
cat("\nInformational (not compared): rc_diagnostics.csv, rc_mdcopd_rebuilt_vs_file.csv,\n",
    "rc_consensus_ref_risk_pairwise.csv, rc_esi_ct_auc.csv complete-case rows, rc_torch_codes_among_deaths.csv\n")
if (!is.null(WRITE)) {
  if (file.exists(WRITE)) stop("refusing to overwrite ", WRITE)
  write.csv(res, WRITE, row.names = FALSE); cat("wrote", WRITE, "\n")
}
